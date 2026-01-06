import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Realtime subscription handle
  RealtimeChannel? _subscription;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  // 1. Subscribe to Room
  void subscribeToRoom(String serverId) {
    _messages = [];
    _isLoading = true;
    notifyListeners();

    // Initial Load
    _fetchMessages(serverId);

    // Live Subscription
    // Note: Supabase Realtime usually just sends the raw record. 
    // We might need to refetch to get the joined 'content_library' data if an attachment is added,
    // or we content with just having the ID initially.
    // simpler approach for MVP: listen to INSERT, then fetch that single row with JOIN.
    _subscription = _supabase
      .channel('public:chat_messages:server_id=eq.$serverId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chat_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'server_id',
          value: serverId,
        ),
        callback: (payload) {
          _handleNewMessage(payload.newRecord['id']);
        }
      )
      .subscribe();
  }

  void unsubscribe() {
    _supabase.removeChannel(_subscription!);
    _subscription = null;
  }

  Future<void> _fetchMessages(String serverId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('*, content_library(*), profiles!sender_id(*)') // JOIN both content and sender profile
          .eq('server_id', serverId)
          .order('created_at', ascending: true);

      _messages = (response as List).map((e) => ChatMessage.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleNewMessage(String msgId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('*, content_library(*), profiles!sender_id(*)')
          .eq('id', msgId)
          .single();
      
      final msg = ChatMessage.fromJson(response);
      _messages.add(msg);
      notifyListeners();
    } catch (e) {
      debugPrint('Realtime fetch error: $e');
    }
  }

  // 2. Send Text Message
  Future<void> sendText(String serverId, String text) async {
    final user = _supabase.auth.currentUser;
    if (user == null || text.trim().isEmpty) return;

    try {
      await _supabase.from('chat_messages').insert({
        'server_id': serverId,
        'sender_id': user.id,
        'message_text': text.trim(),
      });
    } catch (e) {
      debugPrint('Send text error: $e');
      rethrow;
    }
  }

  // 3. Send File (The Option A Core Logic)
  // This performs the Transaction: Upload -> Content Library -> Chat Message
  Future<void> sendFile(String serverId, PlatformFile file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // A. Upload to Storage
      final fileBytes = file.bytes; // Web
      final filePath = file.path;   // Mobile/Desktop
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storagePath = '$serverId/$fileName'; // Organization strategy

      if (fileBytes != null) {
        await _supabase.storage.from('chat-attachments').uploadBinary(
          storagePath,
          fileBytes,
        );
      } else if (filePath != null) {
        await _supabase.storage.from('chat-attachments').upload(
          storagePath,
          File(filePath),
        );
      } else {
        throw 'No file data';
      }

      final publicUrl = _supabase.storage.from('chat-attachments').getPublicUrl(storagePath);

      // B. Insert to Content Library
      // Note: We need course_id. For now, we assume the Server is linked to a course, 
      // or we leave it null. If we had the server object, we'd grab its course_id.
      // We will do a quick fetch of the server to check for course_id context if needed, 
      // or just insert simplistic data for now.
      
      // Let's get server info to see if it has course_id
      final serverInfo = await _supabase.from('chat_servers').select('course_id, semester').eq('id', serverId).single();
      
      final contentRes = await _supabase.from('content_library').insert({
        'title': file.name,
        'file_url': publicUrl,
        'file_type': file.extension ?? 'unknown',
        'file_size_bytes': file.size,
        'uploader_id': user.id,
        'server_id': serverId,
        'course_id': serverInfo['course_id'], // Automatically categorize!
        'semester': serverInfo['semester'],
      }).select().single();

      // C. Insert Chat Message referencing Content
      await _supabase.from('chat_messages').insert({
        'server_id': serverId,
        'sender_id': user.id,
        'attachment_id': contentRes['id'], // THE LINK
        'message_text': null, // Pure attachment message
      });

    } catch (e) {
      debugPrint('File upload error: $e');
      rethrow;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_server.dart';
import 'dart:math';

class ServerProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<ChatServer> _myServers = [];
  bool _isLoading = false;
  Map<String, int> _unreadCounts = {}; // serverId -> unread count

  List<ChatServer> get myServers => _myServers;
  bool get isLoading => _isLoading;
  
  int getUnreadCount(String serverId) => _unreadCounts[serverId] ?? 0;

  // Fetch servers the user is part of (Owner or Member)
  Future<void> fetchServers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Logic: Get servers where I am owner OR I am a member
      
      // 1. Owned Servers (For teachers)
      final ownedResponse = await _supabase
          .from('chat_servers')
          .select()
          .eq('owner_id', userId);
          
      // 2. Member Servers (For students/teachers)
      // This requires a join. Supabase syntax:
      final memberResponse = await _supabase
          .from('server_members')
          .select('server:chat_servers(*)') // INNER JOIN
          .eq('user_id', userId);
      
      final List<ChatServer> loadedServers = [];

      // Parse Owned
      for (var s in ownedResponse) {
        loadedServers.add(ChatServer.fromJson(s));
      }

      // Parse Member (Deduplicating if necessary, though logic separates them slightly)
      for (var m in memberResponse) {
        if (m['server'] != null) {
          final srv = ChatServer.fromJson(m['server']);
          // Avoid duplicates if I own it AND am a member (unlikely unique constraint blocked it, but good to be safe)
          if (!loadedServers.any((existing) => existing.id == srv.id)) {
            loadedServers.add(srv);
          }
        }
      }

      _myServers = loadedServers;

    } catch (e) {
      debugPrint('Error fetching servers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Teacher Action: Create Server
  Future<bool> createServer(String name, String description) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    // Generate specific invite code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    final String code = String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

    try {
      final res = await _supabase.from('chat_servers').insert({
        'owner_id': user.id,
        'name': name,
        'description': description,
        'invite_code': code,
      }).select().single();

      // Add self as member too? Often good practice so chat queries work uniformly.
      await _supabase.from('server_members').insert({
        'server_id': res['id'],
        'user_id': user.id,
      });

      await fetchServers(); // Refresh
      return true;
    } catch (e) {
      debugPrint('Error creating server: $e');
      return false;
    }
  }

  // Student Action: Join Server (Request Flow)
  Future<String?> joinServer(String inviteCode) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'Not logged in';

    try {
      // 1. Find Server
      final server = await _supabase
          .from('chat_servers')
          .select()
          .eq('invite_code', inviteCode)
          .maybeSingle();

      if (server == null) return 'Invalid Invite Code';

      // 2. Check overlap in members
      final existing = await _supabase
          .from('server_members')
          .select()
          .eq('server_id', server['id'])
          .eq('user_id', user.id)
          .maybeSingle();

      if (existing != null) return 'Already a member';

      // 3. Check for pending request
      final pending = await _supabase
          .from('teacher_requests')
          .select()
          .eq('server_id', server['id'])
          .eq('student_email', user.email!)
          .eq('status', 'pending')
          .maybeSingle();
      
      if (pending != null) return 'Join request already pending approval.';

      // 4. Send Request
      await _supabase.from('teacher_requests').insert({
        'server_id': server['id'],
        'teacher_id': server['owner_id'],
        'student_email': user.email,
        'type': 'join',
        'status': 'pending',
      });

      return 'Join request sent. Waiting for approval.';
    } catch (e) {
      debugPrint('Error joining server: $e');
      return 'Error sending join request';
    }
  }
  
  // Member Management
  Future<List<Map<String, dynamic>>> fetchMembers(String serverId) async {
    try {
      final res = await _supabase
          .from('server_members')
          .select('*, profiles(*)')
          .eq('server_id', serverId);
          
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Fetch members error: $e');
      return [];
    }
  }

  // Teacher Action: Add Member (Request Flow)
  Future<String?> addMemberByEmail(String serverId, String email) async {
    final teacherId = _supabase.auth.currentUser?.id;
    if (teacherId == null) return 'Not logged in';

    try {
      // 1. Check if already member (via email lookup in profiles)
      final userRes = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (userRes != null) {
        final userId = userRes['id'];
        final existing = await _supabase
            .from('server_members')
            .select()
            .eq('server_id', serverId)
            .eq('user_id', userId)
            .maybeSingle();
        
        if (existing != null) return 'User is already a member.';
      }

      // 2. Check for pending request
      final pending = await _supabase
          .from('teacher_requests')
          .select()
          .eq('server_id', serverId)
          .eq('student_email', email)
          .eq('status', 'pending')
          .maybeSingle();
      
      if (pending != null) return 'Request already pending for this email.';

      // 3. Send Request/Invitation
      await _supabase.from('teacher_requests').insert({
        'server_id': serverId,
        'teacher_id': teacherId,
        'student_email': email,
        'type': 'add',
        'status': 'pending',
      });

      return null; // Success (Request sent)
    } catch (e) {
      debugPrint('Add member error: $e');
      return 'Failed to send add request: $e';
    }
  }

  Future<String?> removeMember(String serverId, String userId) async {
    try {
      await _supabase
          .from('server_members')
          .delete()
          .eq('server_id', serverId)
          .eq('user_id', userId);
      return null;
    } catch (e) {
      return 'Failed to remove member: $e';
    }
  }

  // Toggle chat permissions
  Future<String?> toggleStudentMessaging(String serverId, bool allow) async {
    try {
      await _supabase
          .from('chat_servers')
          .update({'allow_student_messages': allow})
          .eq('id', serverId);
      
      // Update local cache
      final index = _myServers.indexWhere((s) => s.id == serverId);
      if (index != -1) {
        final server = _myServers[index];
        _myServers[index] = ChatServer(
          id: server.id,
          name: server.name,
          inviteCode: server.inviteCode,
          ownerId: server.ownerId,
          description: server.description,
          bannerUrl: server.bannerUrl,
          allowStudentMessages: allow,
        );
        notifyListeners();
      }
      
      return null;
    } catch (e) {
      debugPrint('Toggle messaging error: $e');
      return 'Failed to update permissions: $e';
    }
  }

  // Get server details
  Future<ChatServer?> getServerDetails(String serverId) async {
    try {
      final res = await _supabase
          .from('chat_servers')
          .select()
          .eq('id', serverId)
          .single();
      return ChatServer.fromJson(res);
    } catch (e) {
      debugPrint('Get server error: $e');
      return null;
    }
  }

  // Broadcast a notification to all members of a server
  Future<void> notifyMembers(String serverId, String title, String body, String type, String relatedId) async {
    try {
      final members = await _supabase
          .from('server_members')
          .select('user_id')
          .eq('server_id', serverId);

      final List<Map<String, dynamic>> notifications = (members as List).map((m) {
        return {
          'user_id': m['user_id'],
          'title': title,
          'body': body,
          'is_read': false,
          'related_entity_type': type,
          'related_entity_id': relatedId,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      if (notifications.isNotEmpty) {
        await _supabase.from('notifications').insert(notifications);
      }
    } catch (e) {
      debugPrint('Error broadcasting notifications: $e');
    }
  }
}

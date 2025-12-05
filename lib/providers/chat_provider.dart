import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';

class ChatProvider with ChangeNotifier {
  final List<ChatRoom> _rooms = [];
  final Uuid _uuid = const Uuid();

  List<ChatRoom> get rooms => _rooms;

  ChatProvider() {
    // Mock Data
    _rooms.add(ChatRoom(
      id: 'r1',
      name: 'CS101 Discussion',
      createdBy: 't1',
      participants: ['u1', 't1'],
      messages: [
        ChatMessage(
          id: 'm1',
          senderId: 't1',
          senderName: 'Dr. Smith',
          text: 'Welcome to the course!',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
      sharedContent: [
        SharedContent(id: 's1', title: 'Syllabus', url: 'syllabus.pdf', type: 'file'),
      ],
    ));
  }

  void createRoom(String name, String teacherId) {
    final newRoom = ChatRoom(
      id: _uuid.v4(),
      name: name,
      createdBy: teacherId,
      participants: [teacherId], // Teacher is auto-added
    );
    _rooms.add(newRoom);
    notifyListeners();
  }

  void sendMessage(String roomId, String senderId, String senderName, String text) {
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      final newMessage = ChatMessage(
        id: _uuid.v4(),
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: DateTime.now(),
      );
      
      // Since ChatRoom is immutable, we need to replace it or make it mutable.
      // For simplicity in this mock, let's assume we can modify the list if it was mutable,
      // but here I defined it as final List. So I should create a new ChatRoom or make lists mutable.
      // Let's cheat a bit and cast to mutable list or just recreate the room.
      
      final room = _rooms[roomIndex];
      final updatedMessages = List<ChatMessage>.from(room.messages)..add(newMessage);
      
      _rooms[roomIndex] = ChatRoom(
        id: room.id,
        name: room.name,
        createdBy: room.createdBy,
        participants: room.participants,
        messages: updatedMessages,
        sharedContent: room.sharedContent,
      );
      
      notifyListeners();
    }
  }

  void addSharedContent(String roomId, String title, String url, String type) {
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      final newContent = SharedContent(
        id: _uuid.v4(),
        title: title,
        url: url,
        type: type,
      );
      
      final room = _rooms[roomIndex];
      final updatedContent = List<SharedContent>.from(room.sharedContent)..add(newContent);
      
      _rooms[roomIndex] = ChatRoom(
        id: room.id,
        name: room.name,
        createdBy: room.createdBy,
        participants: room.participants,
        messages: room.messages,
        sharedContent: updatedContent,
      );
      
      notifyListeners();
    }
  }
}

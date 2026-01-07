import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat Rooms')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatProvider.rooms.length,
              itemBuilder: (context, index) {
                final room = chatProvider.rooms[index];
                return ListTile(
                  leading: const Icon(Icons.group),
                  title: Text(room.name),
                  subtitle: Text('Created by: ${room.createdBy == user?.id ? "You" : "Teacher"}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(roomId: room.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? MediaQuery.of(context).viewInsets.bottom : 16),
        ],
      ),
      floatingActionButton: user?.role == UserRole.teacher
          ? FloatingActionButton(
              onPressed: () {
                _showCreateRoomDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Chat Room'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Room Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                Provider.of<ChatProvider>(context, listen: false)
                    .createRoom(nameController.text, auth.user!.id);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

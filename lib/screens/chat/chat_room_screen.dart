import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_models.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;

  const ChatRoomScreen({super.key, required this.roomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    // Find room safely
    final room = chatProvider.rooms.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () => ChatRoom(id: '', name: 'Error', createdBy: '', participants: []),
    );

    if (room.id.isEmpty) return const Scaffold(body: Center(child: Text('Room not found')));

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(room.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chat'),
            Tab(text: 'Shared Content'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chat Tab
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true, // To show latest at bottom if we reversed list, but here we append.
                  // Better to reverse list or use reverse: true and insert at 0.
                  // For simplicity, let's just show as is, but scroll to bottom.
                  // Or use reverse: true and reverse the list in builder.
                  itemCount: room.messages.length,
                  itemBuilder: (context, index) {
                    // Show latest at bottom
                    final msg = room.messages[index];
                    final isMe = msg.senderId == user?.id;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg.senderName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            Text(msg.text),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(hintText: 'Type a message...'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_messageController.text.isNotEmpty) {
                          chatProvider.sendMessage(
                            room.id,
                            user!.id,
                            user.name,
                            _messageController.text,
                          );
                          _messageController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Shared Content Tab
          Column(
            children: [
              if (user?.role.toString() == 'UserRole.teacher') // Check role properly
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Add content dialog
                      _showAddContentDialog(context, room.id);
                    },
                    child: const Text('Share Content'),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: room.sharedContent.length,
                  itemBuilder: (context, index) {
                    final content = room.sharedContent[index];
                    return ListTile(
                      leading: Icon(content.type == 'file' ? Icons.attach_file : Icons.link),
                      title: Text(content.title),
                      subtitle: Text(content.url),
                      onTap: () {
                        // Open content
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddContentDialog(BuildContext context, String roomId) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL/Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                Provider.of<ChatProvider>(context, listen: false).addSharedContent(
                  roomId,
                  titleController.text,
                  urlController.text,
                  'link',
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

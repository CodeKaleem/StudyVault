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

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    final room = chatProvider.rooms.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () =>
          ChatRoom(id: '', name: 'Error', createdBy: '', participants: []),
    );

    if (room.id.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Room not found')),
      );
    }

    final bottomSystemPadding = MediaQuery.of(context).viewPadding.bottom;

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
      body: SafeArea(
        bottom: true,
        child: TabBarView(
          controller: _tabController,
          children: [
            /// CHAT TAB
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: room.messages.length,
                    itemBuilder: (context, index) {
                      final msg = room.messages[index];
                      final isMe = msg.senderId == user?.id;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                isMe ? Colors.blue[100] : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.senderName,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(msg.text),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// MESSAGE INPUT
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    bottomSystemPadding + 12, // 👈 Android nav bar fix
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send,
                            color: Color(0xFF6366F1)),
                        onPressed: () {
                          if (_messageController.text.trim().isEmpty) return;

                          chatProvider.sendMessage(
                            room.id,
                            user!.id,
                            user.name,
                            _messageController.text.trim(),
                          );
                          _messageController.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            /// SHARED CONTENT TAB
            Column(
              children: [
                if (user?.role.toString() == 'UserRole.teacher')
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () =>
                          _showAddContentDialog(context, room.id),
                      child: const Text('Share Content'),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      8,
                      8,
                      bottomSystemPadding + 12,
                    ),
                    itemCount: room.sharedContent.length,
                    itemBuilder: (context, index) {
                      final content = room.sharedContent[index];
                      return ListTile(
                        leading: Icon(
                          content.type == 'file'
                              ? Icons.attach_file
                              : Icons.link,
                        ),
                        title: Text(content.title),
                        subtitle: Text(content.url),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ADD CONTENT DIALOG
  void _showAddContentDialog(BuildContext context, String roomId) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Share Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: urlController,
              decoration:
                  const InputDecoration(labelText: 'URL / Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;

              context.read<ChatProvider>().addSharedContent(
                    roomId,
                    titleController.text.trim(),
                    urlController.text.trim(),
                    'link',
                  );
              Navigator.pop(context);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

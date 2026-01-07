import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final String serverId;
  final String serverName;

  const ChatScreen({super.key, required this.serverId, required this.serverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isUploading = false; // Local UI state

  @override
  void initState() {
    super.initState();
    // Subscribe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().subscribeToRoom(widget.serverId);
    });
  }

  @override
  void dispose() {
    // Unsubscribe handled by Provider? No, Provider is singleton-ish or scoped.
    // Ideally we call unsubscribe when leaving.
    // For now, simpler to let new subscription overwrite old one or add a method.
    // context.read<ChatProvider>().unsubscribe(); 
    // ^ Avoiding logic issues if provider is reused.
    super.dispose();
  }

  void _sendMessage() {
    if (_inputCtrl.text.trim().isEmpty) return;
    context.read<ChatProvider>().sendText(widget.serverId, _inputCtrl.text);
    _inputCtrl.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final res = await FilePicker.platform.pickFiles();
      if (res != null && res.files.isNotEmpty) {
        setState(() => _isUploading = true);
        await context.read<ChatProvider>().sendFile(widget.serverId, res.files.first);
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      // Delay slightly to allow list to render new item
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    final authProv = context.read<AuthProvider>();
    final myId = authProv.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serverName),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            tooltip: 'Announcements',
            onPressed: () {
              context.push(
                '/server/${widget.serverId}/announcements',
                extra: {
                  'name': widget.serverName,
                  'isTeacher': authProv.role == AppRole.teacher,
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_shared),
            tooltip: 'Content Library',
            onPressed: () {
              context.push('/server/${widget.serverId}/content', extra: {'name': widget.serverName});
            },
          ),
          // Check if teacher? Or just show settings and handle permission inside
          // Better UX: Show only if teacher?
          // We can check role from auth provider
          if (authProv.role == AppRole.teacher)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Server Settings',
              onPressed: () {
                context.push('/server/${widget.serverId}/settings', extra: {'name': widget.serverName});
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProv.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProv.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatProv.messages[index];
                    final isMe = msg.senderId == myId;
                    return _MessageBubble(message: msg, isMe: isMe);
                  },
                ),
          ),
          if (_isUploading)
            const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _isUploading ? null : _pickAndUploadFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  void _showProfileDialog(BuildContext context) {
    final senderData = message.senderData;
    if (senderData == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Text(
                (senderData['full_name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                senderData['full_name'] ?? 'Unknown User',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Email', value: senderData['email'] ?? 'N/A'),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Role', 
              value: (senderData['role'] ?? 'student').toString().toUpperCase()
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final senderData = message.senderData;
    final senderName = senderData?['full_name'] ?? 'Unknown';
    final senderInitial = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

    // Determine content
    Widget content;
    if (message.attachmentData != null) {
      final fileData = message.attachmentData!;
      final fileUrl = fileData['file_url'];
      
      content = GestureDetector(
        onTap: () async {
          if (fileUrl != null) {
            try {
              final uri = Uri.parse(fileUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open file: $e')),
                );
              }
            }
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileData['title'] ?? 'File',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    (fileData['file_type'] ?? '').toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.touch_app, size: 12, color: Colors.white70),
                      SizedBox(width: 4),
                      Text(
                        'Tap to open',
                        style: TextStyle(fontSize: 10, color: Colors.white70, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      );
    } else {
      content = Text(
        message.messageText ?? '',
        style: const TextStyle(color: Colors.white),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              GestureDetector(
                onTap: () => _showProfileDialog(context),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.indigo,
                  child: Text(
                    senderInitial,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    GestureDetector(
                      onTap: () => _showProfileDialog(context),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          senderName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isMe 
                        ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]) 
                        : null,
                      color: isMe ? null : const Color(0xFF334155),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: content,
                  ),
                ],
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.pink,
                child: Text(
                  senderInitial,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}

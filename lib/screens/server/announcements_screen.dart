import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/announcement.dart';

import 'package:provider/provider.dart';
import '../../providers/server_provider.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String serverId;
  final String serverName;
  final bool isTeacher;

  const AnnouncementsScreen({
    super.key,
    required this.serverId,
    required this.serverName,
    this.isTeacher = false,
  });

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Announcement> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('announcements')
          .select('*, profiles!author_id(*)')
          .eq('server_id', widget.serverId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _announcements = (res as List).map((e) => Announcement.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch announcements error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    bool isImportant = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Create Announcement', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'e.g., Midterm Exam Schedule',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'Announcement details...',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Mark as Important', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Will be highlighted', style: TextStyle(color: Colors.white60)),
                  value: isImportant,
                  activeColor: Colors.indigo,
                  onChanged: (val) {
                    setDialogState(() => isImportant = val ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                
                Navigator.pop(ctx);
                await _createAnnouncement(titleCtrl.text.trim(), contentCtrl.text.trim(), isImportant);
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAnnouncement(String title, String content, bool isImportant) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final res = await _supabase.from('announcements').insert({
        'server_id': widget.serverId,
        'author_id': user.id,
        'title': title,
        'content': content,
        'is_important': isImportant,
      }).select().single();

      // Broadcast notifications to all members of this class
      if (mounted) {
        context.read<ServerProvider>().notifyMembers(
          widget.serverId,
          'New Announcement: $title',
          content,
          'announcement',
          res['id'],
        );
      }

      await _fetchAnnouncements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement posted & students notified!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    try {
      await _supabase.from('announcements').delete().eq('id', id);
      await _fetchAnnouncements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.serverName} - Announcements'),
      ),
      floatingActionButton: widget.isTeacher
          ? FloatingActionButton.extended(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.campaign),
              label: const Text('New Announcement'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No announcements yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _announcements.length,
                  itemBuilder: (ctx, i) {
                    final announcement = _announcements[i];
                    final authorName = announcement.authorData?['full_name'] ?? 'Unknown';
                    final isCurrentUser = announcement.authorId == _supabase.auth.currentUser?.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: announcement.isImportant
                          ? Colors.red.withOpacity(0.1)
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: announcement.isImportant
                                    ? Colors.red.withOpacity(0.2)
                                    : Colors.indigo.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                announcement.isImportant
                                    ? Icons.priority_high
                                    : Icons.campaign,
                                color: announcement.isImportant ? Colors.red : Colors.indigo,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    announcement.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (announcement.isImportant)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'IMPORTANT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              'By $authorName • ${_formatDate(announcement.createdAt)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: isCurrentUser
                                ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete Announcement'),
                                          content: const Text('Are you sure?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _deleteAnnouncement(announcement.id);
                                              },
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              announcement.content,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

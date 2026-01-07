import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ServerContentScreen extends StatefulWidget {
  final String serverId;
  final String serverName;

  const ServerContentScreen({super.key, required this.serverId, required this.serverName});

  @override
  State<ServerContentScreen> createState() => _ServerContentScreenState();
}

class _ServerContentScreenState extends State<ServerContentScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    try {
      final res = await _supabase
          .from('content_library')
          .select()
          .eq('server_id', widget.serverId)
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _files = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching server content: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.serverName} - Library'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _files.isEmpty 
            ? const Center(child: Text('No files shared yet.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _files.length,
                itemBuilder: (ctx, i) {
                  final f = _files[i];
                  final ext = f['file_type'] ?? 'file';
                  final title = f['title'] ?? 'Untitled';
                  final fileUrl = f['file_url'];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForType(ext), 
                          size: 28, 
                          color: Colors.indigo,
                        ),
                      ),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            ext.toUpperCase(),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (f['file_size_bytes'] != null) ...[
                            const Text(' • ', style: TextStyle(color: Colors.grey)),
                            Text(
                              _formatFileSize(f['file_size_bytes']),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new, color: Colors.indigo),
                        onPressed: () async {
                          if (fileUrl != null) {
                            final url = Uri.parse(fileUrl);
                            try {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not open file: $e')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getIconForType(String type) {
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('jpg') || type.contains('png')) return Icons.image;
    if (type.contains('doc')) return Icons.description;
    return Icons.insert_drive_file;
  }
}

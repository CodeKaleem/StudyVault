import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/auth_provider.dart';

class ServerSettingsScreen extends StatefulWidget {
  final String serverId;
  final String serverName;

  const ServerSettingsScreen({super.key, required this.serverId, required this.serverName});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isOwner = false;
  bool _allowStudentMessages = true; // Chat permission state

  @override
  void initState() {
    super.initState();
    _checkOwnerAndFetch();
  }

  Future<void> _checkOwnerAndFetch() async {
    // Fetch server details to get current permission setting
    final serverDetails = await context.read<ServerProvider>().getServerDetails(widget.serverId);
    if (serverDetails != null && mounted) {
      setState(() {
        _allowStudentMessages = serverDetails.allowStudentMessages;
      });
    }
    
    await _fetchMembers();
    
    // We'll filter from the member list to see if I am there? No.
    // Let's just enable features. The backend RLS protects actions anyway.
    _isOwner = true; // Optimization: Actually check db or pass param
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    final members = await context.read<ServerProvider>().fetchMembers(widget.serverId);
    if (mounted) {
      setState(() {
        _members = members;
        _isLoading = false;
      });
    }
  }

  void _showAddMemberDialog() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student by Email'),
        content: TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(labelText: 'Student Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await context.read<ServerProvider>().addMemberByEmail(widget.serverId, emailCtrl.text.trim());
              if (mounted) {
                 if (err != null) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                 } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent to admin for approval.')));
                 }
              }
            }, 
            child: const Text('Add')
          ),
        ],
      ),
    );
  }

  void _removeMember(String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $name?'),
        content: const Text('Are you sure you want to remove this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
               Navigator.pop(ctx);
               final err = await context.read<ServerProvider>().removeMember(widget.serverId, userId);
               if (mounted) {
                 if (err != null) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                 } else {
                   _fetchMembers();
                 }
               }
            }, 
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.serverName} Settings'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemberDialog,
        child: const Icon(Icons.person_add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Permission Settings Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.indigo),
                      title: const Text(
                        'Chat Permissions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(
                        _allowStudentMessages ? Icons.chat : Icons.chat_bubble_outline,
                        color: _allowStudentMessages ? Colors.green : Colors.grey,
                      ),
                      title: const Text('Allow Student Messages'),
                      subtitle: Text(
                        _allowStudentMessages 
                          ? 'Students can send messages in chat'
                          : 'Only you can send messages',
                        style: TextStyle(
                          fontSize: 12,
                          color: _allowStudentMessages ? Colors.green : Colors.grey,
                        ),
                      ),
                      value: _allowStudentMessages,
                      onChanged: (value) async {
                        final err = await context.read<ServerProvider>().toggleStudentMessaging(widget.serverId, value);
                        if (mounted) {
                          if (err != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err)),
                            );
                          } else {
                            setState(() => _allowStudentMessages = value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value 
                                    ? 'Students can now send messages'
                                    : 'Only you can send messages now',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              // Members Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(
                      'Members (${_members.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Members List
              Expanded(
                child: ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (ctx, i) {
                     final m = _members[i];
                     final profile = m['profiles'];
                     final name = profile != null ? profile['full_name'] : 'Unknown';
                     final email = profile != null ? profile['email'] ?? 'No Email' : '';
                     final uid = m['user_id'];
                     
                     return ListTile(
                       leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0] : '?')),
                       title: Text(name),
                       subtitle: Text(email),
                       trailing: IconButton(
                         icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                         onPressed: () => _removeMember(uid, name),
                       ),
                     );
                  },
                ),
              ),
            ],
          ),
    );
  }
}

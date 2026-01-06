import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/server_provider.dart';

class RegisteredStudentsScreen extends StatefulWidget {
  const RegisteredStudentsScreen({super.key});

  @override
  State<RegisteredStudentsScreen> createState() => _RegisteredStudentsScreenState();
}

class _RegisteredStudentsScreenState extends State<RegisteredStudentsScreen> {
  final Map<String, List<Map<String, dynamic>>> _serverMembers = {};
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final serverProv = context.read<ServerProvider>();
    await serverProv.fetchServers();
    
    for (var server in serverProv.myServers) {
      final members = await serverProv.fetchMembers(server.id);
      _serverMembers[server.id] = members;
    }

    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _reloadData() async {
    setState(() => _isInitialLoading = true);
    await _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    final serverProv = context.watch<ServerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('CLASS REGISTERS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reloadData,
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : serverProv.myServers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: serverProv.myServers.length,
                  itemBuilder: (context, index) {
                    final server = serverProv.myServers[index];
                    final members = _serverMembers[server.id] ?? [];
                    
                    return _ClassExpansionTile(
                      serverId: server.id,
                      serverName: server.name,
                      memberCount: members.length,
                      members: members,
                      onMembersChanged: _reloadData,
                    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            'No active classes found',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ClassExpansionTile extends StatelessWidget {
  final String serverId;
  final String serverName;
  final int memberCount;
  final List<Map<String, dynamic>> members;
  final VoidCallback onMembersChanged;

  const _ClassExpansionTile({
    required this.serverId,
    required this.serverName,
    required this.memberCount,
    required this.members,
    required this.onMembersChanged,
  });

  void _showAddStudentDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Add Student by Email', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: emailCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Student Email',
            labelStyle: TextStyle(color: Colors.white70),
            hintText: 'student@example.com',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              
              final error = await context.read<ServerProvider>().addMemberByEmail(serverId, email);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent to admin for approval.')));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Remove Student', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove $userName from $serverName?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            onPressed: () async {
              final error = await context.read<ServerProvider>().removeMember(serverId, userId);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student removed.')));
                  onMembersChanged();
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.class_rounded, color: Colors.indigoAccent),
          ),
          title: Text(
            serverName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            '$memberCount Students Registered',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.indigoAccent),
            onPressed: () => _showAddStudentDialog(context),
          ),
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white54,
          children: [
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No students joined yet', style: TextStyle(color: Colors.white24, fontSize: 13)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: members.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final profile = members[index]['profiles'] as Map<String, dynamic>?;
                  final userId = profile?['id'] ?? '';
                  final name = profile?['full_name'] ?? 'Unknown Student';
                  final email = profile?['email'] ?? '';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.pink.withOpacity(0.1),
                          child: Text(
                            initial,
                            style: const TextStyle(color: Colors.pinkAccent, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.pinkAccent, size: 20),
                          onPressed: () => _showRemoveConfirmation(context, userId, name),
                        ),
                      ],
                    ).animate().fadeIn(delay: (index * 50).ms),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

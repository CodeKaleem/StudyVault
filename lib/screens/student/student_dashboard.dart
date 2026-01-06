import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notification_sheet.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServerProvider>().fetchServers();
      _checkAnnouncements();
    });
  }

  Future<void> _checkAnnouncements() async {
    final notifProv = context.read<NotificationProvider>();
    // Wait a bit for notifications to load if needed
    await Future.delayed(const Duration(milliseconds: 800));
    
    final unreadAnnouncements = notifProv.notifications.where(
      (n) => !n.isRead && n.relatedEntityType == 'announcement'
    ).toList();

    if (unreadAnnouncements.isNotEmpty && mounted) {
      _showAnnouncementPopup(unreadAnnouncements.first);
    }
  }

  void _showAnnouncementPopup(dynamic announcement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Center(
                    child: Icon(Icons.campaign_rounded, size: 48, color: Colors.white),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () {
                      context.read<NotificationProvider>().markAsRead(announcement.id);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    announcement.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    announcement.body,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<NotificationProvider>().markAsRead(announcement.id);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final notifProv = context.watch<NotificationProvider>();
    final serverProv = context.watch<ServerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('STUDY VAULT'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.indigo.withOpacity(0.2),
            child: const Icon(Icons.school, color: Colors.indigo, size: 20),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(onPressed: _showNotifications, icon: const Icon(Icons.notifications_none_rounded)),
              if (notifProv.unreadCount > 0)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                  ),
                )
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => authProv.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
            ).animate().fadeIn(delay: 100.ms).slideX(),
            Text(
              authProv.fullName,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 200.ms).slideX(),
            const SizedBox(height: 30),
            
            // Pinterest Style Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 20) / 2;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Column(
                      children: [
                        _DashboardTile(
                          title: 'Class',
                          subtitle: '${serverProv.myServers.length} Joined Classes',
                          icon: Icons.groups_rounded,
                          color: const Color(0xFF6366F1), // Indigo
                          width: width,
                          height: 240,
                          onTap: () => _showClassesModal(context),
                        ).animate().fadeIn(delay: 300.ms).scale(),
                        const SizedBox(height: 20),
                        _DashboardTile(
                          title: 'GPA Calc',
                          subtitle: 'Calculate your grades',
                          icon: Icons.calculate_rounded,
                          color: const Color(0xFF10B981), // Emerald
                          width: width,
                          height: 180,
                          onTap: () => context.push('/gpa-calculator'),
                        ).animate().fadeIn(delay: 500.ms).scale(),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Right Column
                    Column(
                      children: [
                        _DashboardTile(
                          title: 'Past Papers',
                          subtitle: 'Previous Exam Records',
                          icon: Icons.description_rounded,
                          color: const Color(0xFFEC4899), // Pink
                          width: width,
                          height: 180,
                          onTap: () => context.push('/past-papers'),
                        ).animate().fadeIn(delay: 400.ms).scale(),
                        const SizedBox(height: 20),
                        _DashboardTile(
                          title: 'Profile',
                          subtitle: 'Your Account Details',
                          icon: Icons.person_rounded,
                          color: const Color(0xFFF59E0B), // Amber
                          width: width,
                          height: 240,
                          onTap: () => context.push('/profile'),
                        ).animate().fadeIn(delay: 600.ms).scale(),
                      ],
                    ),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  void _showClassesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ClassesSheet(),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ClassesSheet extends StatelessWidget {
  const ClassesSheet({super.key});

  void _showJoinDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Class Server'),
        content: TextField(
          controller: codeCtrl, 
          decoration: const InputDecoration(labelText: 'Invite Code', hintText: 'e.g. A1B2C3')
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
               final error = await context.read<ServerProvider>().joinServer(codeCtrl.text.trim().toUpperCase());
               if (context.mounted) {
                 Navigator.pop(ctx);
                 if (error != null) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                     content: Text(error),
                     backgroundColor: error.contains('sent') ? Colors.green : Colors.red,
                   ));
                 }
               }
            }, 
            child: const Text('Join')
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serverProv = context.watch<ServerProvider>();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Classes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ElevatedButton.icon(
                onPressed: () => _showJoinDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Join'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: serverProv.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : serverProv.myServers.isEmpty
                ? const Center(child: Text('No classes joined yet', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: serverProv.myServers.length,
                    itemBuilder: (context, index) {
                      final server = serverProv.myServers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white.withOpacity(0.05),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.withOpacity(0.2),
                            child: Text(server.name.isNotEmpty ? server.name[0] : '?', style: const TextStyle(color: Colors.indigo)),
                          ),
                          title: Text(server.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(server.description ?? 'Study Group', style: const TextStyle(color: Colors.white60)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/server/${server.id}', extra: {'name': server.name});
                          },
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}


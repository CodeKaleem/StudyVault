import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notification_sheet.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServerProvider>().fetchServers();
    });
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
              'Professor ${authProv.fullName}',
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
                          subtitle: '${serverProv.myServers.length} Active Servers',
                          icon: Icons.dashboard_customize_rounded,
                          color: const Color(0xFF6366F1), // Indigo
                          width: width,
                          height: 240,
                          onTap: () => _showServersModal(context),
                        ).animate().fadeIn(delay: 300.ms).scale(),
                        const SizedBox(height: 20),
                        _DashboardTile(
                          title: 'Add Papers',
                          subtitle: 'Upload Resources',
                          icon: Icons.upload_file_rounded,
                          color: const Color(0xFF10B981), // Emerald
                          width: width,
                          height: 180,
                          onTap: () => context.push('/past-papers'),
                        ).animate().fadeIn(delay: 500.ms).scale(),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Right Column
                    Column(
                      children: [
                        _DashboardTile(
                          title: 'Students',
                          subtitle: 'Class Registers',
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFFEC4899), // Pink
                          width: width,
                          height: 180,
                          onTap: () => context.push('/registered-students'),
                        ).animate().fadeIn(delay: 400.ms).scale(),
                        const SizedBox(height: 20),
                        _DashboardTile(
                          title: 'Profile',
                          subtitle: 'Instructor Account',
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

  void _showServersModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TeacherServersSheet(),
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

class TeacherServersSheet extends StatelessWidget {
  const TeacherServersSheet({super.key});

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
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: serverProv.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : serverProv.myServers.isEmpty
                ? const Center(child: Text('No servers created yet.', style: TextStyle(color: Colors.white54)))
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
                          subtitle: Text('Code: ${server.inviteCode}', style: const TextStyle(color: Colors.white60)),
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


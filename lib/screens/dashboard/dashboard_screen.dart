import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../academic/course_selection_screen.dart';
import '../academic/gpa_calculator_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${user?.role == UserRole.teacher ? "Teacher" : "Student"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Welcome, ${user?.name}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _DashboardItem(
                    icon: Icons.school,
                    label: 'Courses',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CourseSelectionScreen()),
                    ),
                  ),
                  _DashboardItem(
                    icon: Icons.calculate,
                    label: 'GPA Calculator',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GPACalculatorScreen()),
                    ),
                  ),
                  _DashboardItem(
                    icon: Icons.chat,
                    label: 'Chat Rooms',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatListScreen()),
                    ),
                  ),
                  _DashboardItem(
                    icon: Icons.person,
                    label: 'Profile',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProfileScreen()),
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
}

class _DashboardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

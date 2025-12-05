import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final data = Provider.of<DataProvider>(context);
    final user = auth.user;
    final records = data.studentRecords;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 10),
            Text(user?.name ?? '', style: Theme.of(context).textTheme.headlineSmall),
            Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
            Text('Role: ${user?.role.toString().split('.').last.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (user?.role.toString() == 'UserRole.student') ...[
              const Divider(),
              const Text('Academic Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // Badges (Mock)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Chip(label: Text('Top Scorer'), avatar: Icon(Icons.star, color: Colors.yellow)),
                  Chip(label: Text('Consistent'), avatar: Icon(Icons.check_circle, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return Card(
                    child: ListTile(
                      title: Text(record.courseName),
                      subtitle: Text('Semester: ${record.semester}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Marks: ${record.marks}'),
                          Text('GPA: ${record.gpa}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const Divider(),
            const ListTile(
              leading: Icon(Icons.book),
              title: Text('Additional Content'),
              subtitle: Text('Extra reading materials and resources'),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          ],
        ),
      ),
    );
  }
}

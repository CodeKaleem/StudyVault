import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import 'subject_details_screen.dart';

class CourseSelectionScreen extends StatelessWidget {
  const CourseSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final semesters = dataProvider.semesters;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Course')),
      body: ListView.builder(
        itemCount: semesters.length,
        itemBuilder: (context, index) {
          final semester = semesters[index];
          return ExpansionTile(
            title: Text(semester.name),
            children: semester.courses.map((course) {
              return ListTile(
                title: Text(course.name),
                subtitle: Text(course.code),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectDetailsScreen(course: course),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

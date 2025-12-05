import 'package:flutter/material.dart';
import '../../models/academic_models.dart';

class SubjectDetailsScreen extends StatelessWidget {
  final Course course;

  const SubjectDetailsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(course.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${course.code}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text('Instructor: ${course.teacherName}'),
                subtitle: Text('Rating: ${course.teacherRating} ⭐'),
              ),
            ),
            const SizedBox(height: 20),
            Text('Past Papers', style: Theme.of(context).textTheme.titleLarge),
            ...course.pastPapers.map((paper) => ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(paper),
                  onTap: () {
                    // Open paper logic
                  },
                )),
            const SizedBox(height: 20),
            Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
            ...course.reviews.map((review) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${review.rating} ⭐'),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(review.comment),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add review dialog
              },
              child: const Text('Write a Review'),
            ),
          ],
        ),
      ),
    );
  }
}

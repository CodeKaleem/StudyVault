import 'package:flutter/material.dart';
import '../models/academic_models.dart';

class DataProvider with ChangeNotifier {
  List<Semester> _semesters = [];
  List<StudentCourseRecord> _studentRecords = [];

  List<Semester> get semesters => _semesters;
  List<StudentCourseRecord> get studentRecords => _studentRecords;

  DataProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    // Mock Semesters and Courses
    _semesters = [
      Semester(
        id: '1',
        name: 'Semester 1',
        courses: [
          Course(
            id: 'c1',
            name: 'Introduction to Programming',
            code: 'CS101',
            teacherId: 't1',
            teacherName: 'Dr. Smith',
            teacherRating: 4.5,
            pastPapers: ['Midterm 2023', 'Final 2023'],
            reviews: [
              Review(
                userId: 'u1',
                userName: 'Alice',
                comment: 'Great course!',
                rating: 5.0,
                date: DateTime.now(),
              ),
            ],
          ),
          Course(
            id: 'c2',
            name: 'Calculus I',
            code: 'MATH101',
            teacherId: 't2',
            teacherName: 'Prof. Johnson',
            teacherRating: 3.8,
            pastPapers: ['Quiz 1', 'Midterm 2022'],
          ),
        ],
      ),
      Semester(
        id: '2',
        name: 'Semester 2',
        courses: [
          Course(
            id: 'c3',
            name: 'Data Structures',
            code: 'CS102',
            teacherId: 't1',
            teacherName: 'Dr. Smith',
            teacherRating: 4.6,
          ),
        ],
      ),
    ];

    // Mock Student Records (Passed courses)
    _studentRecords = [
      StudentCourseRecord(
        courseId: 'c1',
        courseName: 'Introduction to Programming',
        marks: 85,
        gpa: 4.0,
        semester: 'Semester 1',
      ),
    ];
    
    notifyListeners();
  }

  void addReview(String courseId, Review review) {
    // In a real app, we'd find the course and add the review.
    // Since our models are immutable-ish or nested deep, we might need to update the list.
    // For mock, let's just print.
    print('Review added for $courseId: ${review.comment}');
    notifyListeners();
  }

  double calculateGPA(List<Map<String, dynamic>> grades) {
    // grades: [{credit: 3, gpa: 4.0}, ...]
    if (grades.isEmpty) return 0.0;
    
    double totalPoints = 0;
    double totalCredits = 0;

    for (var grade in grades) {
      double credit = grade['credit'];
      double gpa = grade['gpa'];
      totalPoints += (credit * gpa);
      totalCredits += credit;
    }

    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }
}

class Semester {
  final String id;
  final String name;
  final List<Course> courses;

  Semester({required this.id, required this.name, required this.courses});
}

class Course {
  final String id;
  final String name;
  final String code;
  final String teacherId;
  final String teacherName;
  final double teacherRating;
  final List<String> pastPapers; // URLs or descriptions
  final List<Review> reviews;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.teacherId,
    required this.teacherName,
    required this.teacherRating,
    this.pastPapers = const [],
    this.reviews = const [],
  });
}

class Review {
  final String userId;
  final String userName;
  final String comment;
  final double rating;
  final DateTime date;

  Review({
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.date,
  });
}

class StudentCourseRecord {
  final String courseId;
  final String courseName;
  final double marks;
  final double gpa;
  final String semester;

  StudentCourseRecord({
    required this.courseId,
    required this.courseName,
    required this.marks,
    required this.gpa,
    required this.semester,
  });
}

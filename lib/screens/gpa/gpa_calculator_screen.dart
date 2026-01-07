import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GpaCalculatorScreen extends StatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  State<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _CourseInput {
  TextEditingController name = TextEditingController();
  TextEditingController credit = TextEditingController();
  TextEditingController gpa = TextEditingController(); // 0.0 - 4.0
}

class _GpaCalculatorScreenState extends State<GpaCalculatorScreen> {
  final List<_CourseInput> _courses = [_CourseInput()]; // Start with 1 row
  double _finalGpa = 0.0;

  void _addCourse() {
    setState(() {
      _courses.add(_CourseInput());
    });
  }

  void _removeCourse(int index) {
    if (_courses.length > 1) {
      setState(() {
        _courses.removeAt(index);
      });
      _calculate();
    }
  }

  void _calculate() {
    double totalPoints = 0;
    double totalCredits = 0;

    for (var c in _courses) {
      final cr = double.tryParse(c.credit.text);
      final gp = double.tryParse(c.gpa.text);

      if (cr != null && gp != null) {
        totalPoints += (cr * gp);
        totalCredits += cr;
      }
    }

    if (totalCredits > 0) {
      setState(() {
        _finalGpa = totalPoints / totalCredits;
      });
    } else {
      setState(() => _finalGpa = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('GPA CALCULATOR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildGpaCard(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              itemCount: _courses.length,
              itemBuilder: (ctx, i) {
                return _buildCourseCard(i)
                    .animate()
                    .fadeIn(delay: (i * 100).ms)
                    .slideX(begin: 0.1, end: 0);
              },
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildGpaCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1), // Indigo
            const Color(0xFF818CF8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'CUMULATIVE GPA',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _finalGpa.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ).animate(target: _finalGpa).shimmer(),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getGpaStatus(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  String _getGpaStatus() {
    if (_finalGpa >= 3.7) return 'EXCELLENT';
    if (_finalGpa >= 3.3) return 'VERY GOOD';
    if (_finalGpa >= 3.0) return 'GOOD';
    if (_finalGpa >= 2.0) return 'PASS';
    if (_finalGpa == 0.0) return 'START CALCULATING';
    return 'NEED IMPROVEMENT';
  }

  Widget _buildCourseCard(int index) {
    final c = _courses[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildTextField(
              controller: c.name,
              label: 'Course Name',
              hint: 'e.g. Physics',
              icon: Icons.book_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: _buildTextField(
              controller: c.credit,
              label: 'Cr',
              hint: '3',
              isNumber: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: _buildTextField(
              controller: c.gpa,
              label: 'GPA',
              hint: '4.0',
              isNumber: true,
            ),
          ),
          if (_courses.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.pinkAccent),
              onPressed: () => _removeCourse(index),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumber = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          onChanged: (_) => _calculate(),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addCourse,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ADD COURSE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                ),
              ),
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('CALCULATE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

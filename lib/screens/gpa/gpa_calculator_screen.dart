import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

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
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  _buildGpaCard(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Courses',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...List.generate(
                          _courses.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildCourseCard(i)
                                .animate()
                                .fadeIn(delay: (i * 100).ms)
                                .slideX(begin: 0.1, end: 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _addCourse,
                                icon: const Icon(Icons.add_rounded, size: 21),
                                label: const Text(
                                  'ADD COURSE',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withOpacity(0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _calculate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text(
                                    'CALCULATE',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpaCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'CUMULATIVE GPA',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _finalGpa.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 68,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
            ),
          ).animate(target: _finalGpa).shimmer(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Text(
              _getGpaStatus(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1,
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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
              const SizedBox(width: 14),
              Expanded(
                flex: 1,
                child: _buildTextField(
                  controller: c.credit,
                  label: 'Credits',
                  hint: '3',
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 1,
                child: _buildTextField(
                  controller: c.gpa,
                  label: 'GPA',
                  hint: '4.0',
                  isNumber: true,
                ),
              ),
              if (_courses.length > 1) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
                    onPressed: () => _removeCourse(index),
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                  ),
                ),
              ],
            ],
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
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white.withOpacity(0.6)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          onChanged: (_) => _calculate(),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
          ),
        ),
      ],
    );
  }
}


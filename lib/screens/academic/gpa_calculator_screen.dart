import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';

class GPACalculatorScreen extends StatefulWidget {
  const GPACalculatorScreen({super.key});

  @override
  State<GPACalculatorScreen> createState() => _GPACalculatorScreenState();
}

class _GPACalculatorScreenState extends State<GPACalculatorScreen> {
  final List<Map<String, dynamic>> _courses = [];
  final _creditController = TextEditingController();
  final _gpaController = TextEditingController();

  void _addCourse() {
    final credit = double.tryParse(_creditController.text);
    final gpa = double.tryParse(_gpaController.text);

    if (credit != null && gpa != null) {
      setState(() {
        _courses.add({'credit': credit, 'gpa': gpa});
        _creditController.clear();
        _gpaController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final currentGPA = dataProvider.calculateGPA(_courses);

    return Scaffold(
      appBar: AppBar(title: const Text('GPA Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _creditController,
                    decoration: const InputDecoration(labelText: 'Credit Hours'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _gpaController,
                    decoration: const InputDecoration(labelText: 'Grade Points (e.g. 4.0)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(onPressed: _addCourse, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 20),
            Text('Courses Added: ${_courses.length}'),
            Expanded(
              child: ListView.builder(
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  return ListTile(
                    title: Text('Credit: ${course['credit']}, GPA: ${course['gpa']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _courses.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Text(
              'Calculated GPA: ${currentGPA.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/students.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class StudentManagementScreen extends StatefulWidget {
  final Isar isar;

  const StudentManagementScreen({Key? key, required this.isar})
    : super(key: key);

  @override
  _StudentManagementScreenState createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final List<Student> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await widget.isar.students.where().findAll();
      setState(() {
        _students.clear();
        _students.addAll(students);
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading students: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: ${e.toString()}')),
        );
      }
    }
  }

  List<Student> get _filteredStudents =>
      _searchQuery.isEmpty
          ? _students
          : _students.where((student) {
            final query = _searchQuery.toLowerCase();
            return student.lrn.toLowerCase().contains(query) ||
                '${student.lastName}, ${student.firstName}'
                    .toLowerCase()
                    .contains(query) ||
                student.studentYear.toLowerCase().contains(query) ||
                student.studentSection.toLowerCase().contains(query);
          }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        centerTitle: true,
      ),
      body: _buildStudentsList(),
    );
  }

  Widget _buildStudentsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child:
              _filteredStudents.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        if (_searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _searchQuery = ''),
                            child: const Text('Clear search'),
                          ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: ListTile(
                          title: Text(
                            '${student.lastName}, ${student.firstName}',
                          ),
                          subtitle: Text('LRN: ${student.lrn}'),
                          trailing: Text(
                            '${student.studentYear} - ${student.studentSection}',
                          ),
                          onTap: () {
                            // TODO: Implement student details/edit screen
                          },
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

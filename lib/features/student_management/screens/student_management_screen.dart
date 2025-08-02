import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/students.dart';
import '../widgets/excel_upload_widget.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class StudentManagementScreen extends StatefulWidget {
  final Isar isar;
  
  const StudentManagementScreen({Key? key, required this.isar}) : super(key: key);

  @override
  _StudentManagementScreenState createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Student> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  List<Student> get _filteredStudents => _searchQuery.isEmpty
      ? _students
      : _students.where((student) {
          final query = _searchQuery.toLowerCase();
          return student.lrn.toLowerCase().contains(query) ||
              '${student.lastName}, ${student.firstName}'.toLowerCase().contains(query) ||
              student.studentYear.toLowerCase().contains(query) ||
              student.studentSection.toLowerCase().contains(query);
        }).toList();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Students'),
            Tab(icon: Icon(Icons.upload_file), text: 'Import'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Students List Tab
          _buildStudentsList(),
          // Import Tab
          _buildImportTab(),
        ],
      ),
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
          child: _filteredStudents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No students found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
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
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        title: Text('${student.lastName}, ${student.firstName}'),
                        subtitle: Text('LRN: ${student.lrn}'),
                        trailing: Text('${student.studentYear} - ${student.studentSection}'),
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

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Import Students',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Prepare an Excel file (.xlsx or .xls) with the following columns in order:',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: const Text(
                      'LRN | Last Name | First Name | Year Level | Section | Adviser Name',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('2. The first row should contain the column headers.'),
                  const Text('3. Click the button below to select your file.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ExcelUploadWidget(
            isar: widget.isar,
            onStudentsImported: _loadStudents,
          ),
        ],
      ),
    );
  }
}

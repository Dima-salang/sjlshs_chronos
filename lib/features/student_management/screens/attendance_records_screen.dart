import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:sjlshs_chronos/features/student_management/models/attendance_record.dart';
import 'package:sjlshs_chronos/features/student_management/models/students.dart';
import 'package:sjlshs_chronos/widgets/app_scaffold.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

class AttendanceRecordsScreen extends StatefulWidget {
  final Isar isar;
  
  const AttendanceRecordsScreen({
    Key? key,
    required this.isar,
  }) : super(key: key);

  @override
  State<AttendanceRecordsScreen> createState() => _AttendanceRecordsScreenState();
}

class _AttendanceRecordsScreenState extends State<AttendanceRecordsScreen> {
  DateTime _selectedDate = DateTime.now();
  List<AttendanceRecord> _records = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get records for the selected date
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final records = await widget.isar.attendanceRecords
          .where()
          .timestampBetween(startOfDay, endOfDay)
          .findAll();

      // Sort by timestamp (newest first)
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      setState(() {
        _records = records;
      });
    } catch (e) {
      debugPrint('Error loading records: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load attendance records')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
      _loadRecords();
    }
  }

  List<AttendanceRecord> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    
    final query = _searchQuery.toLowerCase();
    return _records.where((record) {
      return record.firstName.toLowerCase().contains(query) ||
          record.lastName.toLowerCase().contains(query) ||
          record.studentSection.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Attendance Records',
      body: Column(
        children: [
          // Date selector and search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Date selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        });
                        _loadRecords();
                      },
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text(
                        DateFormat('MMMM d, y').format(_selectedDate),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                        });
                        _loadRecords();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, LRN, or section',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Records list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No attendance records found\nfor ${DateFormat('MMMM d, y').format(_selectedDate)}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = _filteredRecords[index];
                          return _buildRecordItem(record);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(AttendanceRecord record) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(record.firstName[0].toUpperCase()),
        ),
        title: Text(
          '${record.firstName} ${record.lastName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LRN: ${record.lrn}'),
            Text('${record.studentSection} • ${record.studentYear}'),
            const SizedBox(height: 4),
            Text(
              'Time: ${DateFormat('h:mm a').format(record.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Icon(
          record.isPresent ? Icons.check_circle : Icons.cancel,
          color: record.isPresent ? Colors.green : Colors.red,
        ),
        onTap: () {
          // Show record details
          _showRecordDetails(record);
        },
      ),
    );
  }

  void _showRecordDetails(AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Student', '${record.firstName} ${record.lastName}'),
              _buildDetailRow('LRN', record.lrn),
              _buildDetailRow('Grade & Section', '${record.studentYear} - ${record.studentSection}'),
              _buildDetailRow('Status', record.isPresent ? 'Present' : 'Absent'),
              _buildDetailRow('Date', DateFormat('MMMM d, y').format(record.timestamp)),
              _buildDetailRow('Time', DateFormat('h:mm a').format(record.timestamp)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

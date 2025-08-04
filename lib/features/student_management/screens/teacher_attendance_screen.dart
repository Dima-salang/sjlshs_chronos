import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:sjlshs_chronos/features/attendance_tracking/record_manager.dart';
import 'package:sjlshs_chronos/features/auth/auth_providers.dart';
import 'package:sjlshs_chronos/features/student_management/models/attendance_record.dart';

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  final Isar isar;
  
  const TeacherAttendanceScreen({
    Key? key,
    required this.isar,
  }) : super(key: key);

  @override
  TeacherAttendanceScreenState createState() => TeacherAttendanceScreenState();
}

class TeacherAttendanceScreenState extends ConsumerState<TeacherAttendanceScreen> {
  late final RecordManager _recordManager;
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Set initial date range to today
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    _endDate = _startDate.add(const Duration(days: 1));
    _recordManager = RecordManager(
      firestore: FirebaseFirestore.instance,
      isar: widget.isar,
    );
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not logged in';
        _isLoading = false;
      });
      return;
    }

    try {
      // Get teacher's section from user metadata
      final userMetadata = await ref.read(userMetadataProvider.future);
      if (userMetadata == null) {
        setState(() {
          _errorMessage = 'User metadata not found';
          _isLoading = false;
        });
        return;
      }

      // Ensure user is a teacher
      if (userMetadata.role != 'teacher') {
        setState(() {
          _errorMessage = 'This account is not authorized as a teacher';
          _isLoading = false;
        });
        return;
      }

      // Get the section (non-null due to UserMetadata constraints)
      final section = userMetadata.section;

      // Use the selected date range
      final startOfDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      // Get attendance records for the section
      final records = await _recordManager.getAbsencesFromFirestore(
        section: section!,
        start: startOfDay,
        end: endOfDay,
      );

      // Sort by student name for better readability
      records.sort((a, b) => '${a.lastName}${a.firstName}'.compareTo('${b.lastName}${b.firstName}'));

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading attendance: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If start date is after end date, update end date to match
          if (_startDate.isAfter(_endDate)) {
            _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          }
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          // If end date is before start date, update start date to match
          if (_endDate.isBefore(_startDate)) {
            _startDate = DateTime(picked.year, picked.month, picked.day);
          }
        }
        _isLoading = true;
      });
      await _loadAttendance();
    }
  }

  List<AttendanceRecord> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    
    final query = _searchQuery.toLowerCase();
    return _records.where((record) {
      return '${record.firstName} ${record.lastName}'.toLowerCase().contains(query) ||
          record.studentSection.toLowerCase().contains(query);
    }).toList();
  }
  
  String get _dateRangeText {
    final startFormat = DateFormat('MMM d, yyyy');
    final endFormat = DateFormat('MMM d, yyyy');
    
    if (_startDate.year == _endDate.year && 
        _startDate.month == _endDate.month && 
        _startDate.day == _endDate.day) {
      return startFormat.format(_startDate);
    }
    
    return '${startFormat.format(_startDate)} - ${endFormat.format(_endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Attendance'),
      ),
      body: Column(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: $_dateRangeText',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: () => _selectDate(context, isStartDate: true),
                      tooltip: 'Select start date',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text('to', style: TextStyle(fontSize: 14)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: () => _selectDate(context, isStartDate: false),
                      tooltip: 'Select end date',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _loadAttendance,
                      tooltip: 'Refresh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (_startDate.isAfter(DateTime.now()) || _endDate.isAfter(DateTime.now()))
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Note: Showing future dates',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _filteredRecords.isEmpty
                        ? const Center(child: Text('No attendance records found'))
                        : ListView.builder(
                            itemCount: _filteredRecords.length,
                            itemBuilder: (context, index) {
                              final record = _filteredRecords[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  title: Text('${record.lastName}, ${record.firstName}'),
                                  subtitle: Text(record.studentSection),
                                  trailing: record.isPresent
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : const Icon(Icons.cancel, color: Colors.red),
                                  onTap: () {
                                    // Show more details if needed
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

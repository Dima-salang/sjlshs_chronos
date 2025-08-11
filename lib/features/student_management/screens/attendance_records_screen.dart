import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:sjlshs_chronos/features/device_management/device_management.dart' as DeviceManagement;
import 'package:sjlshs_chronos/features/student_management/models/attendance_record.dart';
import 'package:sjlshs_chronos/widgets/app_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sjlshs_chronos/features/attendance_tracking/record_manager.dart';
import 'package:sjlshs_chronos/features/attendance_tracking/report_manager.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';


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
  bool _isSyncing = false;
  String _searchQuery = '';
  String? _syncMessage;
  bool _syncSuccess = false;
  int _selectedTabIndex = 0;
  DateTimeRange _reportDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  bool _isGeneratingReport = false;
  List<Map<String, dynamic>> _syncStatusList = [];
  bool _isLoadingSyncStatus = false;

  late final RecordManager _recordManager;

  @override
  void initState() {
    super.initState();
    _recordManager = RecordManager(
      firestore: FirebaseFirestore.instance,
      isar: widget.isar,
    );
    _loadRecords();    
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedTabIndex == 1) {
      _loadSyncStatus();
    }
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
      print(records);
      
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

  Future<void> _syncAbsences() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _syncMessage = 'Syncing absences...';
      _syncSuccess = false;
    });

    try {
      await _recordManager.syncAbsences();
      setState(() {
        _syncMessage = 'Absences synced successfully!';
        _syncSuccess = true;
      });
    } catch (e) {
      debugPrint('Error syncing absences: $e');
      setState(() {
        _syncMessage = 'Failed to sync absences: ${e.toString()}';
        _syncSuccess = false;
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
      
      // Clear the message after 5 seconds
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _syncMessage = null;
        });
      }
    }
  }

  Future<void> _syncPresences() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _syncMessage = 'Syncing attendance records...';
      _syncSuccess = false;
    });

    try {
      await _recordManager.syncPresences();
      setState(() {
        _syncMessage = 'Attendance records synced successfully!';
        _syncSuccess = true;
      });
    } catch (e) {
      debugPrint('Error syncing attendance records: $e');
      setState(() {
        _syncMessage = 'Failed to sync attendance records: ${e.toString()}';
        _syncSuccess = false;
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
      
      // Clear the message after 5 seconds
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _syncMessage = null;
        });
      }
    }
  }

  Future<void> _loadSyncStatus() async {
    if (_isLoadingSyncStatus) return;
    
    setState(() {
      _isLoadingSyncStatus = true;
    });

    try {
      final statusList = await DeviceManagement.getSyncStatus();
      setState(() {
        _syncStatusList = statusList;
      });
    } catch (e) {
      debugPrint('Error loading sync status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sync status: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSyncStatus = false;
        });
      }
    }
  }

  Future<void> _generateReport() async {
    if (_isGeneratingReport) return;

    // 1. Select Directory
    String? outputDirectory;
    try {
      outputDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Output Directory',
      );

      if (outputDirectory == null) {
        // User canceled the picker
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Directory selection canceled.')),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting directory: $e')),
        );
      }
      return;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      final logger = Logger();
      final reportManager = ReportManager(
        isar: widget.isar,
        firestore: FirebaseFirestore.instance,
        logger: logger,
      );

      final fileName = 'attendance_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '$outputDirectory/$fileName';

      // 2. Generate the report
      await reportManager.writeReport(
        _reportDateRange.start,
        _reportDateRange.end,
        filePath,
      );

      // 3. Show success message and option to open
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to $filePath'),
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                final result = await OpenFile.open(filePath);
                if (result.type != ResultType.done && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open file: ${result.message}')),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  Future<void> _selectReportDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _reportDateRange,
    );
    
    if (picked != null && picked != _reportDateRange) {
      setState(() {
        _reportDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          return AppScaffold(
            title: 'Attendance Records',
            body: Column(
              children: [
                TabBar(
                  onTap: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                      if (index == 1) {
                        _loadSyncStatus();
                      }
                    });
                  },
                  tabs: const [
                    Tab(icon: Icon(Icons.list), text: 'Records'),
                    Tab(icon: Icon(Icons.sync), text: 'Sync Status'),
                    Tab(icon: Icon(Icons.assessment), text: 'Reports'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Records Tab
                      _buildRecordsTab(),
                      // Sync Status Tab
                      _buildSyncStatusTab(),
                      // Reports Tab
                      _buildReportsTab(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildSyncStatusTab() {
    return Column(
      children: [
        // Sync Instructions Card
        Card(
          margin: const EdgeInsets.all(12),
          elevation: 2,
          child: ExpansionTile(
            title: const Text(
              'Sync Instructions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sync Instructions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Sync attendance records first. Ensure \n2. Then sync absences\n3. Ensure stable internet connection',
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.8),
                ),
                const SizedBox(height: 16),
                // Sync Records Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isSyncing && _syncMessage != null && _syncMessage!.contains('records')
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync, size: 20),
                    label: Text(_isSyncing && _syncMessage != null && _syncMessage!.contains('records') ? 'Syncing...' : 'Sync Records'),
                    onPressed: _isSyncing && _syncMessage != null && _syncMessage!.contains('records') ? null : _syncPresences,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Sync Absences Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isSyncing && _syncMessage != null && _syncMessage!.contains('absences')
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync, size: 20),
                    label: Text(_isSyncing && _syncMessage != null && _syncMessage!.contains('absences') ? 'Syncing...' : 'Sync Absences'),
                    onPressed: _isSyncing && _syncMessage != null && _syncMessage!.contains('absences') ? null : _syncAbsences,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[800],
                    ),
                  ),
                ),
              ],  
            ) ,
      ]),
        ),
        // Sync button and status
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Sync button
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync, size: 20),
                      label: Text(_isSyncing ? 'Syncing...' : 'Sync Records'),
                      onPressed: _isSyncing ? null : _syncAbsences,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Refresh button
                  IconButton(
                    icon: _isLoadingSyncStatus
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 24),
                    onPressed: _isLoadingSyncStatus ? null : _loadSyncStatus,
                    tooltip: 'Refresh sync status',
                  ),
                ],
              ),
              if (_syncMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _syncMessage!,
                  style: TextStyle(
                    color: _syncSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        
        // Devices sync status list
        Expanded(
          child: _isLoadingSyncStatus
              ? const Center(child: CircularProgressIndicator())
              : _syncStatusList.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sync_problem, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No sync data available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _syncStatusList.length,
                      itemBuilder: (context, index) {
                        final device = _syncStatusList[index];
                        final lastSync = device['lastSync'] as DateTime?;
                        final isThisDevice = device['isThisDevice'] as bool;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          color: isThisDevice ? Theme.of(context).colorScheme.primaryContainer : null,
                          child: ListTile(
                            leading: Icon(
                              isThisDevice ? Icons.phone_android : Icons.device_unknown,
                              color: isThisDevice ? Theme.of(context).colorScheme.primary : null,
                            ),
                            title: Text(
                              '${device['deviceId']} ${isThisDevice ? '(This Device)' : ''}',
                              style: TextStyle(
                                fontWeight: isThisDevice ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              lastSync != null
                                  ? 'Last sync: ${DateFormat('MMM d, y hh:mm a').format(lastSync)}'
                                  : 'Never synced',
                            ),
                            trailing: lastSync != null
                                ? Text(
                                    '${DateTime.now().difference(lastSync).inHours < 24 ? 'Today' : '${DateTime.now().difference(lastSync).inDays} days ago'}',
                                    style: TextStyle(
                                      color: DateTime.now().difference(lastSync).inDays > 7
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildRecordsTab() {
    return Column(
      children: [
        
        // Date selector and search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Date selector and sync button row
              Row(
                children: [
                  // Date selector
                  Expanded(
                    child: Row(
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
                  ),
                ],
              ),
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
            onPressed: () => context.pop(),
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
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Report Generation Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generate Attendance Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date Range Selection
                  _buildDateRangeSelector(),
                  const SizedBox(height: 24),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isGeneratingReport
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(_isGeneratingReport ? 'Generating...' : 'Generate & Save Report'),
                      onPressed: _isGeneratingReport ? null : _generateReport,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  if (_isGeneratingReport) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text(
                      'Generating report. This may take a moment...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Instructions Card
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it Works',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Select the date range for the report.\n'
                    '2. Click \'Generate & Save Report\'.\n'
                    '3. Choose a directory to save the Excel file to.\n'
                    '4. The report will be generated and you will be notified upon completion.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date Range',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectReportDateRange(context),
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      '${DateFormat('MMM d, y').format(_reportDateRange.start)} - ${DateFormat('MMM d, y').format(_reportDateRange.end)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

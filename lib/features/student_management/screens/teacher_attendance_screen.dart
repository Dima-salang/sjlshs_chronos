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
import 'package:sjlshs_chronos/widgets/app_scaffold.dart';

enum DateRangePreset { today, yesterday, thisWeek, lastWeek, thisMonth, custom }
enum SortOption { nameAsc, nameDesc, statusFirst }

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  final Isar isar;
  
  const TeacherAttendanceScreen({
    super.key,
    required this.isar,
  });

  @override
  TeacherAttendanceScreenState createState() => TeacherAttendanceScreenState();
}

class TeacherAttendanceScreenState extends ConsumerState<TeacherAttendanceScreen>
    with TickerProviderStateMixin {
  late final RecordManager _recordManager;
  late final AnimationController _refreshController;
  
  // State variables
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>>? _cachedFilteredRecords;
  String _cachedSearchQuery = '';
  SortOption _cachedSort = SortOption.nameAsc;
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  
  late DateTime _startDate;
  late DateTime _endDate;
  DateRangePreset _selectedPreset = DateRangePreset.today;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.nameAsc;
  
  // Date formatters
  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _dayFormat = DateFormat('EEEE');
  static final _shortDateFormat = DateFormat('MMM d');
  
  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _initializeDates();
    _recordManager = RecordManager(
      firestore: FirebaseFirestore.instance,
      isar: widget.isar,
    );
    _loadAttendance();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Future<void> _loadAttendance() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _setError('Please log in to continue', showRetry: false);
        return;
      }

      final userMetadata = await ref.read(userMetadataProvider.future);
      if (userMetadata == null) {
        _setError('Unable to load your profile. Please try again.', showRetry: true);
        return;
      }

      if (userMetadata.role != 'teacher') {
        _setError('This feature is only available for teachers.', showRetry: false);
        return;
      }

      final section = userMetadata.section;
      if (section == null) {
        _setError('No class section assigned to your account.', showRetry: false);
        return;
      }

      final dateRange = _createDateRange();
      
      final records = await _recordManager.getAbsencesFromFirestore(
        section: section,
        start: dateRange.start,
        end: dateRange.end,
      );

      if (!mounted) return;

      final sortedRecords = _sortRecordsByName(records);
      
      setState(() {
        _records = sortedRecords;
        _isLoading = false;
        _invalidateFilterCache();
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading attendance: $e\n$stackTrace');
      _setError('Unable to load attendance data. Please check your connection.', showRetry: true);
    }
  }

  Future<void> _refreshAttendance() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    _refreshController.repeat();
    
    await _loadAttendance();
    
    if (mounted) {
      setState(() => _isRefreshing = false);
      _refreshController.stop();
      _refreshController.reset();
    }
  }

  void _setError(String message, {required bool showRetry}) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  ({DateTime start, DateTime end}) _createDateRange() {
    return (
      start: DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0),
      end: DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
    );
  }

  List<Map<String, dynamic>> _sortRecordsByName(List<Map<String, dynamic>> records) {
    final recordsWithNames = records.map((record) => (
      record: record,
      fullName: '${record['lastName']}, ${record['firstName']}'.toLowerCase(),
    )).toList();
    
    recordsWithNames.sort((a, b) => a.fullName.compareTo(b.fullName));
    return recordsWithNames.map((item) => item.record).toList();
  }

  void _setDatePreset(DateRangePreset preset) async {
    if (preset == DateRangePreset.custom) {
      await _showCustomDatePicker();
      return;
    }

    final now = DateTime.now();
    DateTime start, end;
    
    switch (preset) {
      case DateRangePreset.today:
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DateRangePreset.yesterday:
        start = DateTime(now.year, now.month, now.day - 1, 0, 0, 0);
        end = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
        break;
      case DateRangePreset.thisWeek:
        final weekday = now.weekday;
        start = DateTime(now.year, now.month, now.day - weekday + 1, 0, 0, 0);
        end = start.add(const Duration(days: 7));
        break;
      case DateRangePreset.lastWeek:
        final weekday = now.weekday;
        start = DateTime(now.year, now.month, now.day - weekday - 6, 0, 0, 0);
        end = start.add(const Duration(days: 7));
        break;
      case DateRangePreset.thisMonth:
        start = DateTime(now.year, now.month, 1, 0, 0, 0);
        end = DateTime(now.year, now.month + 1, 1, 23, 59, 59);
        break;
      case DateRangePreset.custom:
        return; // Handled above
    }
    
    setState(() {
      _selectedPreset = preset;
      _startDate = start;
      _endDate = end;
      _invalidateFilterCache();
    });
    
    _loadAttendance();
  }

  Future<void> _showCustomDatePicker() async {
    final result = await showDialog<({DateTime start, DateTime end})?>(
      context: context,
      builder: (context) => _CustomDateRangeDialog(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPreset = DateRangePreset.custom;
        _startDate = result.start;
        _endDate = result.end;
        _invalidateFilterCache();
      });
      _loadAttendance();
    }
  }

  void _invalidateFilterCache() {
    _cachedFilteredRecords = null;
    _cachedSearchQuery = '';
    _cachedSort = SortOption.nameAsc;
  }

  List<Map<String, dynamic>> get _filteredRecords {
    // Check if we can use cached results
    if (_cachedFilteredRecords != null && 
        _cachedSearchQuery == _searchQuery &&
        _cachedSort == _sortOption) {
      return _cachedFilteredRecords!;
    }

    List<Map<String, dynamic>> filtered = _records;
    
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((record) {
        final fullName = '${record['firstName']} ${record['lastName']}'.toLowerCase();
        final section = record['studentSection'].toLowerCase();
        return fullName.contains(query) || section.contains(query);
      }).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortOption) {
        case SortOption.nameAsc:
          return '${a['lastName']}, ${a['firstName']}'.compareTo('${b['lastName']}, ${b['firstName']}');
        case SortOption.nameDesc:
          return '${b['lastName']}, ${b['firstName']}'.compareTo('${a['lastName']}, ${b['firstName']}');
        case SortOption.statusFirst:
          if (a['isAbsent'] != b['isAbsent']) {
            return a['isAbsent'] ? 1 : -1; // Absent students first
          }
          return '${a['lastName']}, ${a['firstName']}'.compareTo('${b['lastName']}, ${b['firstName']}');
      }
    });

    // Cache the results
    _cachedFilteredRecords = filtered;
    _cachedSearchQuery = _searchQuery;
    _cachedSort = _sortOption;
    
    return filtered;
  }

  // Statistics calculations
  int get _totalStudents => _records.length;
  int get _presentCount => _records.where((r) => r['isAbsent'] == false).length;
  int get _absentCount => _records.where((r) => r['isAbsent'] == true).length;
  double get _attendanceRate => _totalStudents > 0 ? (_presentCount / _totalStudents) * 100 : 0;

  String get _dateRangeText {
    final isSameDay = _startDate.year == _endDate.year &&
        _startDate.month == _endDate.month &&
        _startDate.day == _endDate.day;
    
    if (isSameDay) {
      return _dateFormat.format(_startDate);
    }
    
    return '${_shortDateFormat.format(_startDate)} - ${_shortDateFormat.format(_endDate)}';
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Single card layout for absent students only
          return _StatCard(
            title: 'Absent',
            value: _absentCount.toString(),
            subtitle: 'Students',
            color: Colors.red,
            icon: Icons.cancel_outlined,
          );
        },
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DateRangePreset.values.map((preset) {
                final isSelected = _selectedPreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      _getPresetLabel(preset),
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: isSelected,
                    onSelected: (_) => _setDatePreset(preset),
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Current date range display
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _dateRangeText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: RotationTransition(
                  turns: _refreshController,
                  child: const Icon(Icons.refresh, size: 20),
                ),
                onPressed: _isRefreshing ? null : _refreshAttendance,
                tooltip: 'Refresh data',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPresetLabel(DateRangePreset preset) {
    switch (preset) {
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.yesterday:
        return 'Yesterday';
      case DateRangePreset.thisWeek:
        return 'This Week';
      case DateRangePreset.lastWeek:
        return 'Last Week';
      case DateRangePreset.thisMonth:
        return 'This Month';
      case DateRangePreset.custom:
        return 'Custom';
    }
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by student name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _invalidateFilterCache();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _invalidateFilterCache();
              });
            },
          ),
          const SizedBox(height: 12),
          // Filter and sort options
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                // Stack vertically on small screens
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildSortDropdown(),
                  ],
                );
              } else {
                // Side by side on larger screens
                return Row(
                  children: [
                    const SizedBox(width: 12),
                    Flexible(child: _buildSortDropdown()),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }


  Widget _buildSortDropdown() {
    return DropdownButtonFormField<SortOption>(
      value: _sortOption,
      decoration: InputDecoration(
        labelText: 'Sort',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: SortOption.values.map((sort) {
        return DropdownMenuItem(
          value: sort,
          child: Text(
            _getSortLabel(sort),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _sortOption = value;
            _invalidateFilterCache();
          });
        }
      },
    );
  }


  String _getSortLabel(SortOption sort) {
    switch (sort) {
      case SortOption.nameAsc:
        return 'Name A-Z';
      case SortOption.nameDesc:
        return 'Name Z-A';
      case SortOption.statusFirst:
        return 'Absent First';
    }
  }

  Widget _buildStudentList() {
    final filteredRecords = _filteredRecords;

    if (filteredRecords.isEmpty) {
      return _buildEmptyState();
    }

    // Using a Column instead of ListView to avoid nesting issues inside the main ListView.
    return Column(
      children: List.generate(filteredRecords.length, (index) {
        final record = filteredRecords[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _StudentCard(
            record: record,
            onTap: () => _showStudentDetails(record),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    if (_searchQuery.isNotEmpty) {
      message = 'No students found matching "$_searchQuery"';
      icon = Icons.search_off;
    } else {
      message = 'No attendance records found for this date range';
      icon = Icons.event_busy;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or date range',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _StudentDetailsSheet(record: record),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading attendance data...'),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadAttendance,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refreshAttendance,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16.0),
        children: [
          _buildStatisticsCards(),
          _buildDateRangeSelector(),
          _buildSearchAndFilters(),
          _buildStudentList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Class Attendance',
      body: _buildContent(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isCompact;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: isCompact ? 16 : 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: isCompact ? 11 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 4 : 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 20 : null,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              fontSize: isCompact ? 10 : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String,dynamic> record;
  final VoidCallback onTap;

  const _StudentCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = record['isAbsent'] == false;
    final statusColor = isPresent ? Colors.green : Colors.red;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              // Student info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record['lastName']}, ${record['firstName']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, y').format(
                        (record['timestamp'] as Timestamp).toDate(),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPresent ? Icons.check_circle : Icons.cancel,
                      color: statusColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPresent ? 'Present' : 'Absent',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentDetailsSheet extends StatelessWidget {
  final Map<String,dynamic> record;

  const _StudentDetailsSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Student name
          Text(
            '${record['firstName']} ${record['lastName']}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Section: ${record['studentSection']}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          // Status
          Row(
            children: [
              Expanded(
                child: Text(
                  record['isAbsent'] ? 'Absent' : 'Present',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: record['isAbsent'] ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _CustomDateRangeDialog extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;

  const _CustomDateRangeDialog({
    required this.initialStartDate,
    required this.initialEndDate,
  });

  @override
  State<_CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<_CustomDateRangeDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  static final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Ensure end date is not before start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Date Range'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Start Date'),
            subtitle: Text(_dateFormat.format(_startDate)),
            onTap: _selectStartDate,
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('End Date'),
            subtitle: Text(_dateFormat.format(_endDate)),
            onTap: _selectEndDate,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop((start: _startDate, end: _endDate));
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
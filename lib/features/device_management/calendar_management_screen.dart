
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sjlshs_chronos/features/device_management/calendar_management.dart';

class CalendarManagementScreen extends StatefulWidget {
  static const routeName = '/calendar-management';

  const CalendarManagementScreen({super.key});

  @override
  State<CalendarManagementScreen> createState() => _CalendarManagementScreenState();
}

class _CalendarManagementScreenState extends State<CalendarManagementScreen> {
  late final CalendarManager _calendarManager;
  late final ValueNotifier<List<Map<String, dynamic>>> _dayExceptions;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _calendarManager = CalendarManager(firestore: FirebaseFirestore.instance);
    _dayExceptions = ValueNotifier([]);
    _selectedDay = _focusedDay;
    _loadDayExceptions();
  }

  void _loadDayExceptions() async {
    final exceptions = await _calendarManager.getAllDayExceptions();
    setState(() {
      _dayExceptions.value = exceptions;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _dayExceptions.value.where((exception) {
      final exceptionDate = DateTime.fromMillisecondsSinceEpoch(exception['date']);
      return isSameDay(exceptionDate, day);
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _addDayExceptionDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Day Exception'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Exception Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && _selectedDay != null) {
                  await _calendarManager.addDayException(
                    name: nameController.text,
                    date: _selectedDay!,
                  );
                  _loadDayExceptions();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeDayException(DateTime date) async {
    await _calendarManager.removeDayException(date: date);
    _loadDayExceptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Management'),
      ),
      body: Column(
        children: [
          TableCalendar<Map<String, dynamic>>(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
            ),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      width: 6.0,
                      height: 6.0,
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _dayExceptions,
              builder: (context, value, _) {
                final selectedDayEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];
                if (selectedDayEvents.isEmpty) {
                  return const Center(child: Text('No exceptions for this day.'));
                }
                return ListView.builder(
                  itemCount: selectedDayEvents.length,
                  itemBuilder: (context, index) {
                    final event = selectedDayEvents[index];
                    final eventDate = DateTime.fromMillisecondsSinceEpoch(event['date']);
                    return ListTile(
                      title: Text(event['name']),
                      subtitle: Text('${eventDate.toLocal()}'.split(' ')[0]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeDayException(eventDate),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDayExceptionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sjlshs_chronos/features/device_management/device_management.dart';
import 'package:sjlshs_chronos/features/student_management/models/attendance_record.dart';
import 'package:isar/isar.dart';
import 'package:sjlshs_chronos/features/student_management/models/students.dart';
import 'package:sjlshs_chronos/features/logging/chronos_logger.dart';

class RecordManager {
  final FirebaseFirestore firestore;
  final Isar isar;
  final logger = getLogger();
  RecordManager({required this.firestore, required this.isar});

  Future<void> addRecordToIsar(AttendanceRecord record) async {
    // check if record for a particular lrn already exists for the same day
    final existingRecord = await isar.attendanceRecords
        .filter()
        .lrnEqualTo(record.lrn)
        .timestampBetween(
          DateTime(record.timestamp.year, record.timestamp.month, record.timestamp.day),
          DateTime(record.timestamp.year, record.timestamp.month, record.timestamp.day, 23, 59, 59),
        )
        .findFirst();

    // propagate error to ui
    if (existingRecord != null) {
      throw Exception('Record already exists for this student on this day');
    }

    try {
      await isar.writeTxn(() async {
        await isar.attendanceRecords.put(record);
      });
    } catch (e) {
      logger.e('Error adding record to Isar: $e');
      throw Exception('Error adding record to Isar: $e');
    }

  }

  // syncs absences to firestore based on the present records of students
  Future<void> syncAbsences() async {
    final now = DateTime.now();
    final lastSync = await getLastSyncDate() ?? now.subtract(Duration(days: 1)); // fallback
    
    // check if last sync is in the past
    if (lastSync.isAfter(now)) {
      throw Exception('Last sync is in the future');
    }

    // for every student in isar, get their lrn
    final students = await isar.students.where().findAll();
    for (var student in students) {
      // get absences of the student
      final absences = await getAbsentDaysForStudent(
        lrn: student.lrn,
        start: DateTime(lastSync.year, lastSync.month, lastSync.day),
        end: DateTime(now.year, now.month, now.day),
      );
      print(absences);
      try {
        await writeAbsencesToFirestore(absences, student);
      } catch (e) {
        logger.e('Error writing absences to Firestore: $e');
        throw Exception('Error writing absences to Firestore: $e');
      }
    }
    await setLastSyncDate(now); // ✅ Set last sync
  }

  // write absences to firestore
  Future<void> writeAbsencesToFirestore(List<DateTime> absences, Student student) async {
    final batch = firestore.batch();
    for (var i = 0; i < absences.length; i += 500) {
      final chunk = absences.sublist(i, (i + 500).clamp(0, absences.length));
      for (DateTime absence in chunk) {
        final docID = '${student.lrn}_${absence.toIso8601String().substring(0,10)}';
        final docRef = firestore.collection('attendance').doc(docID);
        final data = {
        'lrn': student.lrn,
        'firstName': student.firstName,
        'lastName': student.lastName,
        'studentYear': student.studentYear,
        'studentSection': student.studentSection,
        'timestamp': absence,
        'isAbsent': true,
      };
      batch.set(docRef, data, SetOptions(merge: true));
    }
    await batch.commit();
  }

  }

  Future<DateTime?> getLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('last_sync_timestamp');
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  Future<void> setLastSyncDate(DateTime date) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_sync_timestamp', date.millisecondsSinceEpoch);

      // commit sync to firestore
      final deviceID = await getDeviceID();
      await firestore.collection('devices').doc(deviceID).set(
        {
        'lastSync': date,
      }, SetOptions(merge: true));
  }

  // get all student records from firestore for report generation
  Future<QuerySnapshot<Map<String, dynamic>>> getStudentRecords(String reportDuration) async {
    try {
      if (reportDuration == 'today') {
        return await firestore.collection('attendance').where('timestamp', isGreaterThanOrEqualTo: DateTime.now().subtract(Duration(days: 1)), isLessThanOrEqualTo: DateTime.now()).get();
      } else if (reportDuration == 'month') {
        return await firestore.collection('attendance').where('timestamp', isGreaterThanOrEqualTo: DateTime.now().subtract(Duration(days: 30)), isLessThanOrEqualTo: DateTime.now()).get();
      } else if (reportDuration == 'year') {
      return await firestore.collection('attendance').where('timestamp', isGreaterThanOrEqualTo: DateTime.now().subtract(Duration(days: 365)), isLessThanOrEqualTo: DateTime.now()).get();
    } else {
      return await firestore.collection('attendance').get();
    }
    } catch (e) {
      logger.e('Error getting student records: $e');
      throw Exception('Error getting student records: $e');
    }
  }



  /* UTIL FUNCTIONS */


  /// fetches normalized days where the student was present.
  Future<Set<DateTime>> getPresentDays({
    required String lrn,
    required DateTime start,
    required DateTime end,
  }) async {
    final records = await isar.attendanceRecords
        .filter()
        .lrnEqualTo(lrn)
        .timestampBetween(
          DateTime(start.year, start.month, start.day),
          DateTime(end.year, end.month, end.day, 23, 59, 59),
        )
        .findAll();

    return records
        .map((r) =>
            DateTime(r.timestamp.year, r.timestamp.month, r.timestamp.day))
        .toSet();
  }

  /// Computes absent days by comparing present days with valid class days.
  Future<List<DateTime>> getAbsentDaysForStudent({
    required String lrn,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final validDays = getWeekdaysBetween(start, end);
      final presentDays =
          await getPresentDays(lrn: lrn, start: start, end: end);

      return validDays.where((day) => !presentDays.contains(day)).toList();
    } catch (e) {
      logger.e('Error getting absent days for $lrn: $e');
      throw Exception('Error getting absent days for $lrn: $e');
    }
  }
  




  List<DateTime> getWeekdaysBetween(DateTime start, DateTime end) {
    final dates = <DateTime>[];

    for (var d = start; d.isBefore(end) || d.isAtSameMomentAs(end); d = d.add(Duration(days: 1))) {
      // 1 = Monday, 7 = Sunday
      if (d.weekday >= DateTime.monday && d.weekday <= DateTime.friday) {
        dates.add(DateTime(d.year, d.month, d.day)); // normalized
      }
    }

    return dates;
  }
}
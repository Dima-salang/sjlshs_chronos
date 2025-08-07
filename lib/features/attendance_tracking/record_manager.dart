
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sjlshs_chronos/features/device_management/device_management.dart';
import 'package:sjlshs_chronos/features/student_management/models/attendance_record.dart';
import 'package:isar/isar.dart';
import 'package:sjlshs_chronos/features/student_management/models/students.dart';
import 'package:sjlshs_chronos/features/logging/chronos_logger.dart';

class RecordManager {
  final FirebaseFirestore? firestore;
  final Isar isar;
  final logger = getLogger();
  RecordManager({this.firestore, required this.isar});

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
  Future<void> syncPresences() async {
    final now = DateTime.now();
    final lastSync = await getLastSyncDate('presences') ?? now.subtract(Duration(days: 1)); // fallback
    
    // check if last sync is in the past
    if (lastSync.isAfter(now)) {
      throw Exception('Last sync is in the future');
    }


    final attendance_records = await isar.attendanceRecords
        .filter()
        .timestampBetween(
          DateTime(lastSync.year, lastSync.month, lastSync.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        )
        .findAll();

    await writePresencesToFirestore(attendance_records);

    

    

    
    await setLastSyncDate(now, 'presences'); // ✅ Set last sync
  }

  // write presences to firestore
  Future<void> writePresencesToFirestore(List<AttendanceRecord> records) async {
    final batch = firestore?.batch();
    for (var i = 0; i < records.length; i += 500) {
      final chunk = records.sublist(i, (i + 500).clamp(0, records.length));
      for (AttendanceRecord record in chunk) {
        final docID = '${record.lrn}_${record.timestamp.toIso8601String().substring(0,10)}';
        final docRef = firestore?.collection('attendance').doc(docID);
        final data = {
        'lrn': record.lrn,
        'firstName': record.firstName,
        'lastName': record.lastName,
        'studentYear': record.studentYear,
        'studentSection': record.studentSection,
        'timestamp': record.timestamp,
        'isAbsent': false,
      };
      batch?.set(docRef!, data, SetOptions(merge: true));
    }
    await batch?.commit();
}

}

  // write absences to firestore
  Future<void> writeAbsencesToFirestore(List<DateTime> absences, Student student) async {
    final batch = firestore?.batch();
    for (var i = 0; i < absences.length; i += 500) {
      final chunk = absences.sublist(i, (i + 500).clamp(0, absences.length));
      for (DateTime absence in chunk) {
        final docID = '${student.lrn}_${absence.toIso8601String().substring(0,10)}';
        final docRef = firestore?.collection('attendance').doc(docID);
        final data = {
        'lrn': student.lrn,
        'firstName': student.firstName,
        'lastName': student.lastName,
        'studentYear': student.studentYear,
        'studentSection': student.studentSection,
        'timestamp': absence,
        'isAbsent': true,
      };
      batch?.set(docRef!, data, SetOptions(merge: true));
    }
    await batch?.commit();
  }

  }

  // sync present records to firestore
  Future<void> syncAbsences() async {
    final now = DateTime.now();
    final lastSync = await getLastSyncDate('absences') ?? now.subtract(Duration(days: 1)); // fallback
    
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
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
      print(absences);
      try {
        await writeAbsencesToFirestore(absences, student);
      } catch (e) {
        logger.e('Error writing absences to Firestore: $e');
        throw Exception('Error writing absences to Firestore: $e');
      }
    }
    await setLastSyncDate(now, 'absences'); // ✅ Set last sync
  }



  Future<DateTime?> getLastSyncDate(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('last_sync_timestamp_$type');
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  Future<void> setLastSyncDate(DateTime date, String type) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_sync_timestamp_$type', date.millisecondsSinceEpoch);

      // commit sync to firestore
      final deviceID = await getDeviceID();
      await firestore?.collection('devices').doc(deviceID).set(
        {
        'lastSync': date,
        'type': type,
      }, SetOptions(merge: true));
  }



  // get absences from firestore for a specific section
Future<List<Map<String, dynamic>>> getAbsencesFromFirestore({
  String? section,
  required DateTime start,
  required DateTime end,
}) async {
  try {
    print(section);
    var query = firestore
        ?.collection('attendance')
        .where('timestamp', isGreaterThanOrEqualTo: start, isLessThanOrEqualTo: end).where('isAbsent', isEqualTo: true);
    
    // Only add the section filter if it's not null
    if (section != null) {
      query = query?.where('studentSection', isEqualTo: section);
    }
    
    // Add the order by
    query = query?.orderBy('timestamp', descending: true);
    
    final absences = await query?.get();

    // ensure that absences are unique per student per day
    final uniqueAbsences = <String, Map<String, dynamic>>{};
    for (final absence in absences?.docs ?? []) {
      final lrn = absence.data()['lrn'];
      final date = absence.data()['timestamp'].toDate();
      final key = '${lrn}_${date.toIso8601String().substring(0, 10)}';
      if (!uniqueAbsences.containsKey(key)) {
        uniqueAbsences[key] = absence.data();
      }
    }

    return uniqueAbsences.values.toList();
  } catch (e) {
    logger.e('Error getting absences from Firestore: $e');
    throw Exception('Error getting absences from Firestore: $e');
  }
}


// get associated image of student from a folder
Future<String?> getStudentImagePath(String lrn) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final folderPath = prefs.getString('student_images_path');
    if (folderPath == null) {
      return null;
    }
    final file = File('$folderPath/$lrn.jpg');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  } catch (e) {
    logger.e('Error getting student image path: $e');
    return null;
  }
}




  /* UTIL FUNCTIONS */


  /// fetches normalized days where the student was present.
  Future<Set<DateTime>> getPresentDays({
    required String lrn,
    required DateTime start,
    required DateTime end,
  }) async {
    final records = await firestore?.collection('attendance').where('lrn', isEqualTo: lrn).where('timestamp', isGreaterThanOrEqualTo: start, isLessThanOrEqualTo: end).where('isAbsent', isEqualTo: false).get();
    
    return records!.docs
        .map((r) =>
            DateTime(r.data()['timestamp'].toDate().year, r.data()['timestamp'].toDate().month, r.data()['timestamp'].toDate().day))
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

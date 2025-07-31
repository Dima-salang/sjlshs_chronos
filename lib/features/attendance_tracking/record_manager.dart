
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sjlshs_chronos/features/attendance_tracking/attendance_tracker.dart';

class RecordManager {
  final FirebaseFirestore firestore;
  RecordManager({required this.firestore});

  Future<void> addRecord(AttendanceRecord record) async {

    final data = {
      'lrn': record.lrn,
      'firstName': record.firstName,
      'lastName': record.lastName,
      'studentYear': record.studentYear,
      'studentSection': record.studentSection,
      'timestamp': record.timestamp,
    };
    await firestore.collection('attendance').add(data);
  } 


  // resolve absences from presences in isar
  
}
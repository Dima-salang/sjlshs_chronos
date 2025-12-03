import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sjlshs_chronos/features/logging/chronos_logger.dart';
import 'package:sjlshs_chronos/features/student_management/models/students.dart';
import 'package:isar/isar.dart';

class FirestoreImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Isar _isar;
  final logger = getLogger();

  FirestoreImportService(this._isar);

  Stream<double> importMasterList() async* {
    try {
      final collection = _firestore.collection('master_list');
      final snapshot = await collection.get();
      final totalDocs = snapshot.docs.length;
      int processedDocs = 0;

      if (totalDocs == 0) {
        yield 1.0;
        return;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Map Firestore data (snake_case) to Student model
        final student = Student()
          ..lrn = data['lrn']?.toString() ?? ''
          ..firstName = data['first_name']?.toString() ?? ''
          ..lastName = data['last_name']?.toString() ?? ''
          ..studentYear = data['student_year']?.toString() ?? ''
          ..studentSection = data['student_section']?.toString() ?? ''
          ..adviserName = data['adviser_name']?.toString() ?? '';

        // Save to Isar
        await _isar.writeTxn(() async {
          // Check if student exists to avoid duplicates or update existing
          final existingStudent = await _isar.students.filter().lrnEqualTo(student.lrn).findFirst();
          if (existingStudent != null) {
            student.id = existingStudent.id; // Maintain ID for update
            await _isar.students.put(student);
          } else {
            await _isar.students.put(student);
          }
        });

        processedDocs++;
        yield processedDocs / totalDocs;
      }
    } catch (e) {
      logger.e('Error importing master list: $e');
      throw Exception('Failed to import master list: $e');
    }
  }
}

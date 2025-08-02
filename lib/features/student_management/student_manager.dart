

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sjlshs_chronos/features/student_management/models/students.dart';
import 'package:sjlshs_chronos/features/logging/chronos_logger.dart';
// base student class
class StudentModel {
  String lrn;
  String lastName;
  String firstName;
  String studentYear;
  String studentSection;
  String adviserName;

  StudentModel({
    required this.lrn,
    required this.lastName,
    required this.firstName,
    required this.studentYear,
    required this.studentSection,
    required this.adviserName,
  });
}


// student management strategy
abstract class StudentManagementStrategy {
  final logger = getLogger();
  Future<Student> addStudent(StudentModel student);
  Future<Student> removeStudent(StudentModel student);
  Future<Student> updateStudent(StudentModel student);
}

// student management strategy implementation
class StudentManagementExcelStrategy implements StudentManagementStrategy {
  // excel file path
  final String excelFilePath;
  final Isar isar;
  final logger = getLogger();

  // constructor
  StudentManagementExcelStrategy(this.excelFilePath, this.isar);

  @override
  Future<Student> addStudent(StudentModel student) async {


    // check if the student already exists
    final existingStudent = await isar.students.filter().lrnEqualTo(student.lrn).findFirst();
    if (existingStudent != null) {
      throw Exception('${student.lrn} already exists');
    }

    try {
      // if the user does not exist, add the user to the database
      final newStudent = Student()
      ..lrn = student.lrn
      ..lastName = student.lastName
      ..firstName = student.firstName
      ..studentYear = student.studentYear
      ..studentSection = student.studentSection
      ..adviserName = student.adviserName;

      await isar.writeTxn(() async {
        await isar.students.put(newStudent);
      });

      return newStudent;
    } catch (e) {
      logger.e('Error adding student ${student.lrn}: $e');
      throw Exception('Error adding student ${student.lrn}: $e');
    }
  }

  @override
  Future<Student> removeStudent(StudentModel student) async {
    final existingStudent = await isar.students.filter().lrnEqualTo(student.lrn).findFirst();
    if (existingStudent == null) {
      throw Exception('${student.lrn} does not exist');
    }

    try {
      await isar.writeTxn(() async {
        await isar.students.delete(existingStudent.id);
      });
      return existingStudent;
    } catch (e) {
      throw Exception('Error removing student: $e');
    }
  }

  @override
  Future<Student> updateStudent(StudentModel student) async {
    final existingStudent = await isar.students.filter().lrnEqualTo(student.lrn).findFirst();
    if (existingStudent == null) {
      throw Exception('${student.lrn} does not exist');
    }

    // compare 
    if (existingStudent.lastName != student.lastName ||
        existingStudent.firstName != student.firstName ||
        existingStudent.studentYear != student.studentYear ||
        existingStudent.studentSection != student.studentSection ||
        existingStudent.adviserName != student.adviserName) {
      throw Exception('${student.lrn} has been updated');
    }

    try {
      await isar.writeTxn(() async {
        await isar.students.put(existingStudent);
      });
      return existingStudent;
    } catch (e) {
      throw Exception('Error updating student: $e');
    }
  }


  // read excel file
  Excel _readExcelFile() {
    try {
      final file = File(excelFilePath);
      if (!file.existsSync()) {
        throw Exception('File does not exist');
      }
      final bytes = file.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      return excel;
    
    } catch (e) {
      throw Exception('Error reading excel file: $e');
    }
  }

  // get student data
  List<StudentModel> getStudentData() {
    try {
      final excel = _readExcelFile();
      final Sheet sheet = excel.sheets.values.first;

      final students = <StudentModel>[];

      for (int i=1; i<sheet.maxRows; i++) {
        final row = sheet.row(i);
        students.add(StudentModel(
          lrn: row[0]?.value.toString() ?? '',
          lastName: row[1]?.value.toString() ?? '',
          firstName: row[2]?.value.toString() ?? '',
          studentYear: row[3]?.value.toString() ?? '',
          studentSection: row[4]?.value.toString() ?? '',
          adviserName: row[5]?.value.toString() ?? '',
        ));
      }

      return students;
    } catch (e) {
      throw Exception('Error getting student data: $e');
    }
  }
}

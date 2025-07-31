

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:isar/isar.dart';

// base student class
class Student {
  String lrn;
  String lastName;
  String firstName;
  String studentYear;
  String studentSection;
  String adviserName;

  Student({
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
  void addStudent(Student student);
  void removeStudent(Student student);
  void updateStudent(Student student);
}

// student management strategy implementation
class StudentManagementExcelStrategy implements StudentManagementStrategy {
  // excel file path
  final String excelFilePath;

  // constructor
  StudentManagementExcelStrategy(this.excelFilePath);

  @override
  void addStudent(Student student) {
    final workbook = _readExcelFile();
    final sheet = workbook.sheets.values.first;

    // check if lrn already exists

    

    
    
    
    
  }

  @override
  void removeStudent(Student student) {
    // TODO: implement removeStudent
  }

  @override
  void updateStudent(Student student) {
    // TODO: implement updateStudent
  }


  // read excel file
  Excel _readExcelFile() {
    try {
      final file = File(excelFilePath);
      final bytes = file.readAsBytesSync();
      final data = bytes.buffer.asUint8List();
      final workbook = Excel.decodeBytes(data);
      return workbook;
    
    } catch (e) {
      throw Exception('Error reading excel file: $e');
    }
  }
}

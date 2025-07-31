import 'package:isar/isar.dart';
part 'attendance_record.g.dart';

@collection
class AttendanceRecord {
  Id id = Isar.autoIncrement;
  late String lrn;
  late String firstName;
  late String lastName;
  late String studentYear;
  late String studentSection;
  late DateTime timestamp;
  late bool isPresent;
  late bool isLate;
  
}
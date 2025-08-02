import 'package:isar/isar.dart';
part 'attendance_record.g.dart';

@collection
class AttendanceRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late String lrn;
  late String firstName;
  late String lastName;
  late String studentYear;
  late String studentSection;

  @Index()
  late DateTime timestamp;
  late bool isPresent;
  late bool isLate;
  
}
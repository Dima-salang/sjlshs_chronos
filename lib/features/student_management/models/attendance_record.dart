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
  late bool? isLate;

  AttendanceRecord({
    required this.lrn,
    required this.firstName,
    required this.lastName,
    required this.studentYear,
    required this.studentSection,
    required this.timestamp,
    required this.isPresent,
    this.isLate,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      lrn: map['lrn'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      studentYear: map['studentYear'],
      studentSection: map['studentSection'],
      timestamp: map['timestamp'].toDate(),
      isPresent: map['isPresent'],
      isLate: map['isLate'],
    );
  }
  
}
import 'package:isar/isar.dart';

part 'students.g.dart';

@collection
class Student {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String lrn;
  late String lastName;
  late String firstName;
  late String studentYear;
  late String studentSection;
  late String adviserName;
}
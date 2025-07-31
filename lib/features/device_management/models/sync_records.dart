import 'package:isar/isar.dart';

part 'sync_records.g.dart';

@collection
class SyncRecords {
  Id id = Isar.autoIncrement;
  late DateTime timestamp;
  late String deviceID;
}
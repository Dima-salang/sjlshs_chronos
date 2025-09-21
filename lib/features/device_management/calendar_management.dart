// Calendar Management
// includes the management of holidays

import 'package:cloud_firestore/cloud_firestore.dart';
class CalendarManager {

  final FirebaseFirestore firestore;


  CalendarManager({required this.firestore});

  Future<void> addDayException({required String name, required DateTime date}) async {
    // transform date to unix
    int unixDate = date.millisecondsSinceEpoch;
    await firestore.collection('day_exceptions').add({
      'name': name,
      'date': unixDate,
    });
  }


  Future<void> removeDayException({required DateTime date}) async {
    await firestore.collection('day_exceptions').where('date', isEqualTo: date.millisecondsSinceEpoch).get().then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        doc.reference.delete();
      }
    });
  } 


  // get all day exception
  Future<List<Map<String, dynamic>>> getAllDayExceptions() async {
    return await firestore.collection('day_exceptions').get().then((querySnapshot) {
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}
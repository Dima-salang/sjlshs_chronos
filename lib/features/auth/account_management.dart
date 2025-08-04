

import 'package:cloud_firestore/cloud_firestore.dart';

class AccountManagement {

  // get all verified accounts
  Future<List<Map<String, dynamic>>> getVerifiedAccounts() async {
    final users = await FirebaseFirestore.instance.collection('accounts').where('is_verified', isEqualTo: true).orderBy('created_at', descending: true).get();
    return users.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getUnverifiedAccounts() async {
    final users = await FirebaseFirestore.instance.collection('accounts').where('is_verified', isEqualTo: false).orderBy('created_at', descending: true).get();
    return users.docs.map((doc) => doc.data()).toList();
  }

  Future<void> verifyAccount(String uid) async {
    await FirebaseFirestore.instance.collection('accounts').doc(uid).update({'is_verified': true});
  }

  Future<void> unverifyAccount(String uid) async {
    await FirebaseFirestore.instance.collection('accounts').doc(uid).update({'is_verified': false});
  }

  Future<void> deleteAccount(String uid) async {
    await FirebaseFirestore.instance.collection('accounts').doc(uid).delete();
  }

  // set the section that the teacher holds
  Future<void> setSection(String uid, String section) async {
    print(section);
    await FirebaseFirestore.instance.collection('accounts').doc(uid).set({'section': section}, SetOptions(merge: true));
  }

}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sjlshs_chronos/features/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sjlshs_chronos/features/auth/user_metadata.dart' as user_metadata;
import 'package:isar/isar.dart';
import 'package:sjlshs_chronos/features/student_management/models/attendance_record.dart';
import 'package:sjlshs_chronos/features/student_management/models/students.dart';


final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userMetadataProvider = FutureProvider<user_metadata.UserMetadata?>((ref) async {
  try {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      print('No authenticated user found');
      return null;
    }

    print('🔄 Fetching user metadata for UID: ${user.uid}');
    
    // Add a timeout to prevent hanging
    final doc = await FirebaseFirestore.instance
        .collection('accounts')
        .doc(user.uid)
        .get()
        .timeout(const Duration(seconds: 10));

    if (!doc.exists) {
      print('❌ No document found for user ${user.uid} in accounts collection');
      return null;
    }

    final data = doc.data();
    if (data == null) {
      print('❌ Document exists but has no data');
      return null;
    }

    print('📋 Retrieved user data: $data');
    
    try {
      final userMetadata = user_metadata.UserMetadata.fromMap(data);


      print('✅ Successfully created UserMetadata: ${userMetadata.toMap()}');
      return userMetadata;
    } catch (e, stackTrace) {
      print('❌ Error creating UserMetadata from data: $e');
      print('Stack trace: $stackTrace');
      print('Data that caused the error: $data');
      return null;
    }
  } on FirebaseException catch (e) {
    print('🔥 Firebase error: ${e.code} - ${e.message}');
    return null;
  } on TimeoutException {
    print('⏱️  Timeout while fetching user metadata');
    return null;
  } catch (e, stackTrace) {
    print('❌ Unexpected error in userMetadataProvider: $e');
    print('Stack trace: $stackTrace');
    return null;
  }
});

// isar provider
final isarProvider = FutureProvider<Isar>((ref) async  {
  final isar = await Isar.open(
    [AttendanceRecordSchema, StudentSchema],
    directory: await getApplicationDocumentsDirectory().then((dir) => dir.path),
  );
  return isar;
});






import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sjlshs_chronos/features/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sjlshs_chronos/features/auth/user_metadata.dart' as user_metadata;


final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userMetadataProvider = FutureProvider<user_metadata.UserMetadata?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  try {
    final doc = await FirebaseFirestore.instance.collection('accounts').doc(user.uid).get();

    if (!doc.exists) throw Exception('User not found');

    final data = doc.data()!;

    return user_metadata.UserMetadata.fromMap(data);

  } catch (e) {
    print(e);
    return null;
  }
});


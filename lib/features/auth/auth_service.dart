import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService  {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);



  // user state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // current user
  User? get currentUser => _auth.currentUser;

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e);
    }
  }

  // register new user
  Future<User?> register(String email, String password, String role) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await createAccountRecord(userCredential.user!, role);
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }


  // create account record for newly registered accounts
  Future<void> createAccountRecord(User user, String role) async {
    try {
      await _firestore.collection('accounts').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'role': role,
        'is_verified': false,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print(e);
    }
  }

  // log out user 
  Future<void> logOutUser() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e);
    }
  }


  // get the user's role
  Future<String?> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final userDoc = await _firestore.collection('accounts').doc(user.uid).get();
      if (!userDoc.exists) return null;
      return userDoc.data()?['role'];
    } catch (e) {
      print(e);
      return null;
    }
  }
}
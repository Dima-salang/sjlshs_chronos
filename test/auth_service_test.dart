import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sjlshs_chronos/features/auth/auth_service.dart';
import 'mocks.mocks.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseFirestore mockFirebaseFirestore;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseFirestore = MockFirebaseFirestore();
      authService = AuthService(mockFirebaseAuth, mockFirebaseFirestore);
    });

    group('signIn', () {
      test('should return User on successful login', () async {
        // Arrange
        final mockUser = MockUser();
        final mockUserCredential = MockUserCredential();
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.signIn(
          'test@example.com',
          'password123',
        );

        // Assert
        expect(result, mockUser);
      });

      test('should return null on failed login', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'wrong@example.com',
          password: 'wrongpassword',
        )).thenThrow(FirebaseAuthException(code: 'user-not-found'));

        // Act
        final result = await authService.signIn(
          'wrong@example.com',
          'wrongpassword',
        );

        // Assert
        expect(result, isNull);
      });
    });

    group('signOut', () {
      test('should complete successfully when sign out is successful', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async => null);

        // Act & Assert
        expect(authService.signOut(), completes);
      });
    });
  });
}

class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
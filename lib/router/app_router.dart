import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sjlshs_chronos/features/student_management/screens/student_management_screen.dart';
import 'package:sjlshs_chronos/features/student_management/screens/attendance_records_screen.dart';
import 'package:sjlshs_chronos/widgets/app_scaffold.dart';
import 'package:sjlshs_chronos/features/auth/screens/login_screen.dart';
import 'package:sjlshs_chronos/features/auth/screens/register_screen.dart';
import 'package:sjlshs_chronos/features/auth/screens/account_verification_screen.dart';
import 'package:sjlshs_chronos/features/auth/screens/verification_info_screen.dart';
import 'package:sjlshs_chronos/features/auth/user_metadata.dart' as user_metadata;
import 'package:sjlshs_chronos/main.dart';



class AppRouter {
  final Isar isar;
  final FirebaseFirestore firestore;
  final bool isUserLoggedIn;
  final user_metadata.UserMetadata? userMetadata;

  AppRouter({
    required this.isar,
    required this.firestore,
    required this.isUserLoggedIn,
    required this.userMetadata,
  });

  late final router = GoRouter(
    initialLocation: isUserLoggedIn ? '/scanner' : '/login',
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register';
      final isVerificationScreen = state.uri.path == '/verification-screen';
      
      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }
      
      // If user is logged in, check verification status
      final isVerified = userMetadata?.isVerified ?? false;
      
      // If user is not verified and not already on verification screen, redirect
      if (!isVerified && !isVerificationScreen && !isAuthRoute) {
        return '/verification-screen';
      }
      
      // If user is verified and on verification screen, redirect to home
      if (isVerified && isVerificationScreen) {
        return '/scanner';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/scanner';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Verification info screen
      GoRoute(
        path: '/verification-screen',
        name: 'verification-info',
        builder: (context, state) => const VerificationInfoScreen(),
      ),
      
      // Main app routes
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const QRScannerScreen(),
        routes: [
          // Nested routes can be added here
        ],
      ),
      
      // Scanner route
      GoRoute(
        path: '/scanner',
        name: 'scanner',
        builder: (context, state) => const QRScannerScreen(),
      ),
      
      // Students management route
      GoRoute(
        path: '/students',
        name: 'students',
        builder: (context, state) => StudentManagementScreen(isar: isar),
      ),
      
      // Attendance records route
      GoRoute(
        path: '/attendance',
        name: 'attendance',
        builder: (context, state) => AttendanceRecordsScreen(isar: isar),
      ),
      
      // Account verification route
      GoRoute(
        path: '/admin/accounts',
        name: 'account-verification',
        builder: (context, state) => const AccountVerificationScreen(),
      ),
    ],
    errorBuilder: (context, state) => const AppScaffold(
      title: 'Page Not Found',
      body: Center(
        child: Text('The requested page could not be found.'),
      ),
    ),
  );
}

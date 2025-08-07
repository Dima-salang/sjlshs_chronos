import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sjlshs_chronos/features/device_management/device_configuration_screen.dart';
import 'package:sjlshs_chronos/features/device_management/pin_entry_screen.dart';
import 'package:sjlshs_chronos/features/student_management/screens/student_management_screen.dart';
import 'package:sjlshs_chronos/features/student_management/screens/attendance_records_screen.dart';
import 'package:sjlshs_chronos/features/auth/screens/login_screen.dart';
import 'package:sjlshs_chronos/features/auth/screens/register_screen.dart';
import 'package:sjlshs_chronos/features/auth/screens/account_verification_screen.dart';
import 'package:sjlshs_chronos/features/auth/screens/verification_info_screen.dart';
import 'package:sjlshs_chronos/features/student_management/screens/teacher_attendance_screen.dart';
import 'package:sjlshs_chronos/features/attendance_tracking/attendance_tracker.dart';
import 'package:sjlshs_chronos/main.dart';
import 'package:sjlshs_chronos/widgets/app_scaffold.dart';
import 'package:sjlshs_chronos/features/auth/auth_providers.dart';
import 'package:sjlshs_chronos/features/device_management/key_management.dart';


import 'package:sjlshs_chronos/features/auth/offline_auth_provider.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final isarAsync = ref.watch(isarProvider);
  final userAsync = ref.watch(currentUserProvider);
  final userMetadataAsync = ref.watch(userMetadataProvider);
  final isOffline = ref.watch(isOfflineProvider);
  
  // Show loading screen while checking auth state
  if (userAsync.isLoading || isarAsync.isLoading) {
    return GoRouter(
      routes: [
        GoRoute(
          path: '/loading',
          pageBuilder: (context, state) => MaterialPage(
            child: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
      initialLocation: '/loading',
    );
  }

  final isar = isarAsync.value!;
  final user = userAsync.value;
  final userMetadata = userMetadataAsync.value;
  
  final bool isUserLoggedIn = user != null;

  return GoRouter(
    initialLocation: isUserLoggedIn ? '/scanner' : '/login',
    redirect: (context, state) {
      // Handle loading state
      if (userAsync.isLoading || isarAsync.isLoading) {
        return '/loading';
      }
      
      final isLoggedIn = user != null;
      final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register' || state.uri.path == '/pin-entry';
      final isVerificationScreen = state.uri.path == '/verification-screen';
      final isError = userAsync.hasError || isarAsync.hasError;

      print("Current state: ${state.uri.path}");
      print("Is offline: $isOffline");
      print("Extra: ${state.extra}");


      if (isOffline) {
        return null;
      }

      if (state.uri.path == '/scanner' && state.extra == true) {
        return '/scanner';
      }

      
      if (isError) {
        print('Error in router state:');
        if (userAsync.hasError) print('User error: ${userAsync.error}');
        if (isarAsync.hasError) print('Isar error: ${isarAsync.error}');
        return '/error';
      }
      
      if (!isLoggedIn && !isOffline) {
        return isAuthRoute ? null : '/login';
      }
      
      // If user is logged in, check verification status
      final isVerified = userMetadata?.isVerified ?? false;
      
      // If user is not verified and not already on verification screen, redirect
      if (!isOffline && !isVerified && !isVerificationScreen && !isAuthRoute) {
        return '/verification-screen';
      }
      
      // If user is verified and on verification screen, redirect to appropriate dashboard
      if (isVerified && isVerificationScreen) {
        // Redirect teachers to their attendance dashboard
        if (userMetadata?.role == 'teacher') {
          return '/teacher-attendance';
        }
        // Default redirect for other roles
        return '/scanner';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/scanner';
      }

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
      
      // Teacher attendance dashboard
      GoRoute(
        path: '/teacher-attendance',
        name: 'teacher-attendance',
        builder: (context, state) => TeacherAttendanceScreen(
          isar: isar,
        ),
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
        builder: (context, state) => QRScannerScreen(fromPinEntry: state.extra as bool?),
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

      // Device management route
      GoRoute(
        path: '/pin-entry',
        name: 'pin-entry',
        builder: (context, state) => const PinEntryScreen(),
      ),
      GoRoute(
        path: '/device-configuration',
        name: 'device-configuration',
        builder: (context, state) => const DeviceConfigurationScreen(),
      )
    ],
    errorBuilder: (context, state) => const AppScaffold(
      title: 'Page Not Found',
      body: Center(
        child: Text('The requested page could not be found.'),
      ),
    ),
  );
}
);

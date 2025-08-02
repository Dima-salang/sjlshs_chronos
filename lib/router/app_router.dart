import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sjlshs_chronos/features/attendance_tracking/attendance_tracker.dart';
import 'package:sjlshs_chronos/features/student_management/screens/student_management_screen.dart';
import 'package:sjlshs_chronos/features/student_management/screens/attendance_records_screen.dart';
import 'package:sjlshs_chronos/widgets/app_scaffold.dart';
import 'package:sjlshs_chronos/main.dart';

class AppRouter {
  final Isar isar;
  final FirebaseFirestore firestore;
  
  AppRouter({
    required this.isar,
    required this.firestore,
  });

  late final router = GoRouter(
    initialLocation: '/scanner',
    routes: [
      // Home/Scanner route
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
    ],
    errorBuilder: (context, state) => const AppScaffold(
      title: 'Page Not Found',
      body: Center(
        child: Text('The requested page could not be found.'),
      ),
    ),
  );
}

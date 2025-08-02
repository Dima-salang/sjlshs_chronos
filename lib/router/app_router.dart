import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:sjlshs_chronos/features/attendance_tracking/attendance_tracker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      GoRoute(
        path: '/scanner',
        name: 'scanner',
        builder: (context, state) => QRScanner(
          isar: isar,
        ),
      ),
      // Add more routes here as needed
      // Example:
      // GoRoute(
      //   path: '/details',
      //   name: 'details',
      //   builder: (context, state) => const DetailsScreen(),
      // ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}

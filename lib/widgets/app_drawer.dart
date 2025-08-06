import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sjlshs_chronos/features/auth/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'SJLSHS Chronos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Attendance Management System',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildListTile(
            context: context,
            icon: Icons.home,
            title: 'Home',
            route: '/',
            currentRoute: currentRoute,
            onTap: () {
              context.push('/');
            },
          ),
          _buildListTile(
            context: context,
            icon: Icons.qr_code_scanner,
            title: 'QR Scanner',
            route: '/scanner',
            currentRoute: currentRoute,
            onTap: () {
              context.push('/scanner');
            },
          ),
          _buildListTile(
            context: context,
            icon: Icons.people,
            title: 'Student Management',
            route: '/students',
            currentRoute: currentRoute,
            onTap: () {
              context.push('/students');
            },
          ),
          _buildListTile(
            context: context,
            icon: Icons.assignment,
            title: 'Attendance Records',
            route: '/attendance',
            currentRoute: currentRoute,
            onTap: () {
              context.push('/attendance');
            },
          ),
          _buildListTile(
            context: context,
            icon: Icons.assignment,
            title: 'Teacher Attendance',
            route: '/teacher-attendance',
            currentRoute: currentRoute,
            onTap: () {
              context.push('/teacher-attendance');
            },
          ),
          
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Admin',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            _buildListTile(
              context: context,
              icon: Icons.verified_user,
              title: 'Account Verification',
              route: '/admin/accounts',
              currentRoute: currentRoute,
              onTap: () {
                context.push('/admin/accounts');
              },
            ),
            _buildListTile(
              context: context,
              icon: Icons.lock,
              title: 'Device Configuration',
              route: '/device-configuration',
              currentRoute: currentRoute,
              onTap: () {
                context.push('/device-configuration');
              },
            ),
          
          const Divider(),
          _buildListTile(
            context: context,
            icon: Icons.settings,
            title: 'Settings',
            route: '/settings',
            currentRoute: currentRoute,
            onTap: () {
              context.push('/settings');
            },
          ),
          _buildListTile(
            context: context,
            icon: Icons.logout,
            title: 'Logout',
            route: '/login',
            currentRoute: currentRoute,
            onTap: () async {
              await AuthService(FirebaseAuth.instance, FirebaseFirestore.instance).logOutUser();
              context.push('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required String currentRoute,
    required VoidCallback onTap,
  }) {
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      onTap: () {
        if (!isSelected) {
          onTap();
        }
        context.pop(context); // Close the drawer
      },
    );
  }
}

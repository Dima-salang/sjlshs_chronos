import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          ),
          _buildListTile(
            context: context,
            icon: Icons.qr_code_scanner,
            title: 'QR Scanner',
            route: '/scanner',
            currentRoute: currentRoute,
          ),
          _buildListTile(
            context: context,
            icon: Icons.people,
            title: 'Student Management',
            route: '/students',
            currentRoute: currentRoute,
          ),
          _buildListTile(
            context: context,
            icon: Icons.assignment,
            title: 'Attendance Records',
            route: '/attendance',
            currentRoute: currentRoute,
          ),
          const Divider(),
          _buildListTile(
            context: context,
            icon: Icons.settings,
            title: 'Settings',
            route: '/settings',
            currentRoute: currentRoute,
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
          context.push(route);
        }
        context.pop(context); // Close the drawer
      },
    );
  }
}

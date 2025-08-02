import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final bool showDrawer;
  final bool showAppBar;
  final bool showBottomNavBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final int currentIndex;
  final ValueChanged<int>? onBottomNavTap;

  const AppScaffold({
    Key? key,
    required this.body,
    this.title,
    this.actions,
    this.showDrawer = true,
    this.showAppBar = true,
    this.showBottomNavBar = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.currentIndex = 0,
    this.onBottomNavTap,
  }) : super(key: key);

  static const List<NavigationDestination> navDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.qr_code_scanner_outlined),
      selectedIcon: Icon(Icons.qr_code_scanner),
      label: 'Scan',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Students',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appBar = showAppBar
        ? AppBar(
            title: Text(title ?? 'SJLSHS Chronos'),
            centerTitle: true,
            actions: actions,
            automaticallyImplyLeading: showDrawer,
          )
        : null;

    return Scaffold(
      appBar: appBar,
      drawer: showDrawer ? const AppDrawer() : null,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: showBottomNavBar
          ? NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onBottomNavTap ?? _defaultOnItemTapped(context),
              destinations: navDestinations,
            )
          : null,
    );
  }

  static void Function(int) _defaultOnItemTapped(BuildContext context) {
    return (index) {
      switch (index) {
        case 0:
          GoRouter.of(context).push('/');
          break;
        case 1:
          GoRouter.of(context).push('/scanner');
          break;
        case 2:
          GoRouter.of(context).push('/students');
          break;
      }
    };
  }

  static int getSelectedIndex(String location) {
    if (location.startsWith('/scan')) {
      return 1;
    } else if (location.startsWith('/students')) {
      return 2;
    } else {
      return 0;
    }
  }
}

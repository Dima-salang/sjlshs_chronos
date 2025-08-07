import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sjlshs_chronos/features/auth/offline_auth_provider.dart';
import 'app_drawer.dart';
import 'package:sjlshs_chronos/features/device_management/key_management.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppScaffold extends ConsumerWidget {
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
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const AppScaffold({
    this.scaffoldKey,
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

  Future<bool> _verifyPin() async {
    final pinController = TextEditingController();
    final secretsManager = SecretsManager();
    bool isValidPin = false;

    await showDialog(
      context: scaffoldKey!.currentContext!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN to Continue'),
        content: TextField(
          controller: pinController,
          decoration: const InputDecoration(
            labelText: 'PIN',
            hintText: 'Enter your PIN',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          keyboardType: TextInputType.text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, letterSpacing: 2.0),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.isNotEmpty) {
                final isValid = await secretsManager.checkPin(pinController.text);
                if (isValid) {
                  isValidPin = true;
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid PIN')),
                  );
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    return isValidPin;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = this.scaffoldKey ?? GlobalKey<ScaffoldState>();
    final isOffline = ref.watch(isOfflineProvider);
    
    final appBar = showAppBar
        ? AppBar(
            title: Text(title ?? 'SJLSHS Chronos'),
            centerTitle: true,
            actions: actions,
            automaticallyImplyLeading: false,
            leading: showDrawer
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () async {
                      if (isOffline) {
                        final isVerified = await _verifyPin();
                        if (isVerified && scaffoldKey.currentState != null) {
                          scaffoldKey.currentState!.openDrawer();
                        }
                      } else if (scaffoldKey.currentState != null) {
                        scaffoldKey.currentState!.openDrawer();
                      }
                    },
                  )
                : null,
          )
        : null;

    return Scaffold(
      key: scaffoldKey,
      appBar: appBar,
      drawer: showDrawer ? const AppDrawer() : null,
      drawerEnableOpenDragGesture: false,
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

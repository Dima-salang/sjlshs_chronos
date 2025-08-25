import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sjlshs_chronos/features/attendance_tracking/attendance_tracker.dart';
import 'package:sjlshs_chronos/features/auth/offline_auth_provider.dart';
import 'package:sjlshs_chronos/features/device_management/device_management.dart' as DeviceManagement;
import 'package:sjlshs_chronos/features/device_management/key_management.dart';
import 'package:sjlshs_chronos/features/student_management/models/attendance_record.dart';
import 'package:sjlshs_chronos/features/student_management/models/students.dart';
import 'package:sjlshs_chronos/utils/encryption_utils.dart';
import 'package:sjlshs_chronos/widgets/app_scaffold.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'package:isar/isar.dart';
import 'package:sjlshs_chronos/features/auth/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:sjlshs_chronos/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // read device id
  await DeviceManagement.getOrCreateDeviceId();

  // check if the device is connected to the internet
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult != ConnectivityResult.none) {
    // show error message
    debugPrint('Internet connection detected');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  
  const MyApp({
    super.key, 
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeNotifier = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      title: 'SJLSHS Chronos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      themeMode: themeNotifier.themeMode,
      routerConfig: router,
    );
  }
}

class QRScannerScreen extends ConsumerStatefulWidget {
  final bool? fromPinEntry;
  const QRScannerScreen({Key? key, this.fromPinEntry = false}) : super(key: key);

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  late final Future<String?> _encryptionKeyFuture;
  late final SecretsManager secretsManager;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void initState() {
    super.initState();
    secretsManager = SecretsManager();
    _encryptionKeyFuture = secretsManager.getEncryptionKey();
  }


  void _handleError(String error) {
    debugPrint('QR Scan Error: $error');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);

    return AppScaffold(
      scaffoldKey: _scaffoldKey,
      title: 'QR Scanner',
      showBottomNavBar: false,
      body: FutureBuilder<String?>(
        future: _encryptionKeyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Encryption key not available.'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: QRScanner(
                encryptionKey: snapshot.data!,
                onError: _handleError,
              ),
            );
          }
        },
      ),
    );
  }
}

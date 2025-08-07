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

  Future<void> _showPinVerification(BuildContext context) async {
    final pinController = TextEditingController();
    final secretsManager = SecretsManager();
    bool isValidPin = false;

    await showDialog(
      context: context,
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
                if (isValid && mounted) {
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

    if (isValidPin && mounted) {
      GoRouter.of(context).go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);
    
    return Stack(
      children: [
        AppScaffold(
          title: 'QR Scanner',
          showAppBar: !isOffline,
          showBottomNavBar: false,
          body: Column(
            children: [
              Expanded(
                child: FutureBuilder<String?>(
                  future: _encryptionKeyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error loading encryption key: ${snapshot.error}'));
                    } else if (snapshot.data == null) {
                      return const Center(child: Text('No encryption key found'));
                    } else {
                      return QRScanner(
                        encryptionKey: snapshot.data!,
                        onError: _handleError,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        if (isOffline)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded),
                onPressed: () => _showPinVerification(context),
                tooltip: 'Back to Login',
              ),
            ),
          ),
      ],
    );
  }
}

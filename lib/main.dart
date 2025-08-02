import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sjlshs_chronos/features/device_management/device_management.dart' as DeviceManagement;
import 'package:sjlshs_chronos/features/student_management/models/attendance_record.dart';
import 'firebase_options.dart';
import 'features/attendance_tracking/attendance_tracker.dart';
import 'package:isar/isar.dart';
import 'utils/encryption_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // read device id
  String? deviceID = await DeviceManagement.getDeviceID();

  if (deviceID == null) {
    await DeviceManagement.setDeviceId();
    deviceID = await DeviceManagement.getDeviceID();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SJLSHS Chronos',
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
      home: const QRScannerScreen(),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final List<AttendanceRecord> _recentScans = [];
  late Future<String> _encryptionKeyFuture;
  late Isar? _isar;
  
  @override
  void initState() {
    super.initState();
    _encryptionKeyFuture = EncryptionUtils.loadEncryptionKeyAsString();
    _isar = Isar.getInstance();
  }

  void _handleScanSuccess(AttendanceRecord record) {
    setState(() {
      _recentScans.insert(0, record);
      if (_recentScans.length > 5) {
        _recentScans.removeLast();
      }
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<String>(
              future: _encryptionKeyFuture,
              builder: (context, snapshot) {
                print(snapshot.data);
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading encryption key: ${snapshot.error}'));
                } else {
                  return QRScanner(
                    encryptionKey: snapshot.data!,
                    onScanSuccess: _handleScanSuccess,
                    onError: _handleError,
                    isar: _isar!,
                  );
                }
              },
            ),
          ),
          if (_recentScans.isNotEmpty)
            Container(
              height: 200,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Scans:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _recentScans.length,
                      itemBuilder: (context, index) {
                        final record = _recentScans[index];
                        return ListTile(
                          title: Text(record.firstName + ' ' + record.lastName),
                          subtitle: Text('LRN: ${record.lrn}'),
                          trailing: Text(
                            '${record.timestamp.hour}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

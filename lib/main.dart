import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
void main() async {
  // Ensure that Flutter binding is initialized before using platform channels.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SJLSHS Chronos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const QRScannerScreen(),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _scanStatus = 'Scanning...';
  String _scannedValue = '';
  Timestamp? _timestamp;

  late MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionTimeoutMs: 2000,
      formats: [BarcodeFormat.qrCode]
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (barcode) {
          final String? scannedData = barcode.barcodes.first.rawValue;
          if (scannedData != null) {
            _timestamp = Timestamp.now();
            // Save data to Firestore
            _firestore.collection('attendance').add({
              'studentId': scannedData,
              'timestamp': _timestamp,
            }).then((_) {
              setState(() {
                _scanStatus = 'Scan successful!';
                _scannedValue = scannedData; // Update scanned value
              });
            }).catchError((error) {
              setState(() {
                _scanStatus = 'Error saving data: $error';
                _scannedValue = ''; // Clear scanned value on error
              });
              debugPrint('Error adding document: $error');
            });
          }
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Scanned Value: $_scannedValue $_timestamp',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

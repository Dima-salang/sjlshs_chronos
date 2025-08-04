import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:pointycastle/export.dart' as pointycastle;
import 'package:sjlshs_chronos/features/auth/auth_providers.dart';
import 'package:sjlshs_chronos/utils/encryption_utils.dart';
import 'package:sjlshs_chronos/features/student_management/models/attendance_record.dart';
import 'package:isar/isar.dart';
import 'package:sjlshs_chronos/features/student_management/models/students.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:sjlshs_chronos/features/attendance_tracking/record_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ScanState {
  scanning,
  processing,
  success,
  error,
}

class AttendanceRecordIsar {
  final String lrn;
  final String firstName;
  final String lastName;
  final String studentYear;
  final String studentSection;
  final DateTime timestamp;
  final bool isPresent;
  final bool isLate;

  AttendanceRecordIsar({
    required this.lrn,
    required this.firstName,
    required this.lastName,
    required this.studentYear,
    required this.studentSection,
    required this.timestamp,
    required this.isPresent,
    required this.isLate,
  });
}

class QRScanner extends ConsumerStatefulWidget {
  final Function(AttendanceRecord)? onScanSuccess;
  final Function(String)? onError;
  
  const QRScanner({
    Key? key,
    this.onScanSuccess,
    this.onError,
  }) : super(key: key);

  @override
  ConsumerState<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends ConsumerState<QRScanner> with TickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _scanAnimationController;
  late AnimationController _successAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _successAnimation;
  late RecordManager recordManager;

  ScanState _scanState = ScanState.scanning;
  String _scannedValue = '';
  String _lastScannedId = '';
  String _errorMessage = '';
  DateTime? _lastScanTime;
  List<AttendanceRecord> _recentScans = [];
  late final Isar isar;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeAnimations();
    _requestPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isar = ref.watch(isarProvider).value!;
    recordManager = RecordManager(firestore: FirebaseFirestore.instance, isar: isar);
  }


  void _initializeController() {
    _controller = MobileScannerController(
      detectionTimeoutMs: 1500,
      formats: [BarcodeFormat.qrCode],
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    ));

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    ));

    _scanAnimationController.repeat();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text('Please grant camera permission to scan QR codes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBarcodeScan(BarcodeCapture capture) async {
    // Check if we have any barcodes
    if (capture.barcodes.isEmpty) {
      debugPrint('No barcodes found in scan');
      return;
    }
    
    final barcode = capture.barcodes.first;
    final scannedData = barcode.rawValue;

    if (scannedData == null || scannedData.isEmpty) {
      debugPrint('Scanned barcode has no data');
      return;
    }

    // Prevent duplicate scans within 3 seconds
    if (_lastScannedId == scannedData && 
        _lastScanTime != null && 
        DateTime.now().difference(_lastScanTime!).inSeconds < 3) {
      return;
    }

    setState(() {
      _scanState = ScanState.processing;
      _scannedValue = scannedData;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    try {
      final timestamp = DateTime.now();
      // decrypt scanned data asynchronously
      final scannedDataMap = await _decryptData(scannedData);
      print(scannedDataMap);

      final lrn = scannedDataMap['student_id'];

      // get student from isar
      final student = await isar.students.filter().lrnEqualTo(lrn).findFirst();
      
      if (student == null) {
        setState(() {
          _scanState = ScanState.error;
          _errorMessage = 'Student with LRN $lrn not found';
        });
        return;
      }
      
      // create new record
      final record = AttendanceRecord(
        lrn: lrn,
        firstName: student.firstName,
        lastName: student.lastName,
        studentYear: student.studentYear,
        studentSection: student.studentSection,
        timestamp: timestamp,
        isPresent: true,
      );

      await recordManager.addRecordToIsar(record);

      // Add to recent scans
      setState(() {
        _recentScans.insert(0, record);
        _scanState = ScanState.success;
      });

      // Show success feedback
      _successAnimationController.reset();
      _successAnimationController.forward();

      // Reset after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _scanState = ScanState.scanning;
        });
      }
    } catch (e) {
      debugPrint('Error processing QR code: $e');
      setState(() {
        _scanState = ScanState.error;
        _errorMessage = 'Error processing QR code: $e';
      });
      // Show error feedback
      HapticFeedback.heavyImpact();
      // Reset after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _scanState = ScanState.scanning;
        });
      }
    }
  }


  Future<Map<String, dynamic>> _decryptData(String encryptedData) async {
    try {
      // Decode the base64 string
      final encryptedBytes = base64Decode(encryptedData);
      
      // Extract nonce (first 12 bytes), tag (next 16 bytes), and ciphertext (the rest)
      final nonce = encryptedBytes.sublist(0, 12);
      final tag = encryptedBytes.sublist(12, 28);
      final ciphertext = encryptedBytes.sublist(28);
      
      // Load the encryption key
      final key = await EncryptionUtils.loadEncryptionKey();
      
      // Create AES-GCM cipher
      final cipher = pointycastle.GCMBlockCipher(pointycastle.AESEngine())
        ..init(false, pointycastle.AEADParameters(pointycastle.KeyParameter(key), 128, nonce, Uint8List(0)));
      
      // Process the ciphertext and tag
      final paddedCiphertext = Uint8List(ciphertext.length + tag.length)
        ..setAll(0, ciphertext)
        ..setAll(ciphertext.length, tag);
      
      final decrypted = cipher.process(paddedCiphertext);
      
      // Convert the decrypted bytes to a string and then to JSON
      final jsonString = utf8.decode(decrypted);
      return jsonDecode(jsonString);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    _scanAnimationController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('qr_scanner'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction < 0.5) {
          _controller.stop();
        } else {
          _controller.start();
        }
      },
      child: Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _handleBarcodeScan,
        ),
        if (_scanState == ScanState.processing)
          const Center(
            child: CircularProgressIndicator(),
          ),
        if (_scanState == ScanState.success)
          Center(
            child: ScaleTransition(
              scale: _successAnimation,
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
            ),
          ),
        if (_scanState == ScanState.error)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 80),
                const SizedBox(height: 10),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  }
}
import 'dart:io';
import 'dart:ui';

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
import 'package:shared_preferences/shared_preferences.dart';

enum ScanState {
  scanning,
  processing,
  success,
  error,
}

class QRScanner extends ConsumerStatefulWidget {
  final Function(AttendanceRecord)? onScanSuccess;
  final Function(String)? onError;
  final String? encryptionKey;

  const QRScanner({
    Key? key,
    this.encryptionKey,
    this.onScanSuccess,
    this.onError,
  }) : super(key: key);

  @override
  ConsumerState<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends ConsumerState<QRScanner> with TickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _borderAnimationController;
  late AnimationController _feedbackAnimationController;
  late RecordManager recordManager;

  ScanState _scanState = ScanState.scanning;
  String _errorMessage = '';
  String _lastScannedId = '';
  DateTime? _lastScanTime;
  Student? _scannedStudent;
  String? _studentImagePath;
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
    _borderAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
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
    if (_scanState != ScanState.scanning || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final scannedData = barcode.rawValue;

    if (scannedData == null || scannedData.isEmpty) return;

    if (_lastScannedId == scannedData &&
        _lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!).inSeconds < 3) {
      return;
    }

    setState(() {
      _scanState = ScanState.processing;
      _lastScannedId = scannedData;
      _lastScanTime = DateTime.now();
    });

    HapticFeedback.mediumImpact();

    try {
      final timestamp = DateTime.now();
      final scannedDataMap = await _decryptData(scannedData);
      final lrn = scannedDataMap['student_id'];

      final student = await isar.students.filter().lrnEqualTo(lrn).findFirst();

      if (student == null) {
        throw 'Student with LRN $lrn not found';
      }

      final imagePath = await recordManager.getStudentImagePath(lrn);

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
      widget.onScanSuccess?.call(record);

      setState(() {
        _scanState = ScanState.success;
        _scannedStudent = student;
        _studentImagePath = imagePath;
      });

      _feedbackAnimationController.forward();

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        _feedbackAnimationController.reverse().then((_) {
          setState(() {
            _scanState = ScanState.scanning;
            _scannedStudent = null;
            _studentImagePath = null;
          });
        });
      }
    } catch (e) {
      setState(() {
        _scanState = ScanState.error;
        _errorMessage = e.toString();
      });
      _feedbackAnimationController.forward();
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        _feedbackAnimationController.reverse().then((_) {
          setState(() {
            _scanState = ScanState.scanning;
          });
        });
      }
    }
  }

  Future<Map<String, dynamic>> _decryptData(String encryptedData) async {
    try {
      final encryptedBytes = base64Decode(encryptedData);
      final nonce = encryptedBytes.sublist(0, 12);
      final tag = encryptedBytes.sublist(12, 28);
      final ciphertext = encryptedBytes.sublist(28);
      final key = await EncryptionUtils.loadEncryptionKey();
      final cipher = pointycastle.GCMBlockCipher(pointycastle.AESEngine())
        ..init(false, pointycastle.AEADParameters(pointycastle.KeyParameter(key), 128, nonce, Uint8List(0)));
      final paddedCiphertext = Uint8List(ciphertext.length + tag.length)
        ..setAll(0, ciphertext)
        ..setAll(ciphertext.length, tag);
      final decrypted = cipher.process(paddedCiphertext);
      final jsonString = utf8.decode(decrypted);
      return jsonDecode(jsonString);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _borderAnimationController.dispose();
    _feedbackAnimationController.dispose();
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
          if (_scanState == ScanState.scanning) {
            _controller.start();
          }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _handleBarcodeScan,
            ),
            _buildScannerOverlay(context),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildFeedbackOverlay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 250,
    );
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: ScannerOverlayPainter(scanWindow: scanWindow, animation: _borderAnimationController),
    );
  }

  Widget _buildFeedbackOverlay() {
    if (_scanState == ScanState.scanning || _scanState == ScanState.processing) {
      return const SizedBox.shrink();
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: FadeTransition(
        opacity: _feedbackAnimationController,
        child: ScaleTransition(
          scale: _feedbackAnimationController,
          child: Container(
            decoration: BoxDecoration(
              color: _scanState == ScanState.success
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: _scanState == ScanState.success
                  ? StudentInfoCard(
                      student: _scannedStudent!,
                      imagePath: _studentImagePath,
                    )
                  : ErrorInfoCard(message: _errorMessage),
            ),
          ),
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Animation<double> animation;

  ScannerOverlayPainter({required this.scanWindow, required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(RRect.fromRectAndCorners(scanWindow, topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)));
    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndCorners(scanWindow, topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)), borderPaint);

    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Color.lerp(Colors.green, Colors.white, animation.value)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Top-left corner
    canvas.drawLine(scanWindow.topLeft, scanWindow.topLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanWindow.topLeft, scanWindow.topLeft + Offset(0, cornerLength), cornerPaint);

    // Top-right corner
    canvas.drawLine(scanWindow.topRight, scanWindow.topRight - Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanWindow.topRight, scanWindow.topRight + Offset(0, cornerLength), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(scanWindow.bottomLeft, scanWindow.bottomLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanWindow.bottomLeft, scanWindow.bottomLeft - Offset(0, cornerLength), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(scanWindow.bottomRight, scanWindow.bottomRight - Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(scanWindow.bottomRight, scanWindow.bottomRight - Offset(0, cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StudentInfoCard extends StatelessWidget {
  final Student student;
  final String? imagePath;

  const StudentInfoCard({Key? key, required this.student, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: imagePath != null ? FileImage(File(imagePath!)) : null,
            child: imagePath == null ? const Icon(Icons.person, size: 50) : null,
          ),
          const SizedBox(height: 16),
          Text(
            '${student.firstName} ${student.lastName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'LRN: ${student.lrn}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${student.studentYear} - ${student.studentSection}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const Icon(Icons.check_circle, color: Colors.green, size: 40),
        ],
      ),
    );
  }
}

class ErrorInfoCard extends StatelessWidget {
  final String message;

  const ErrorInfoCard({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text(
            'Scan Error',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

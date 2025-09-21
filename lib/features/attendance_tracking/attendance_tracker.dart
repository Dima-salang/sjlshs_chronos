import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:pointycastle/export.dart' as pointycastle;
import 'package:sjlshs_chronos/features/auth/auth_providers.dart';
import 'package:sjlshs_chronos/features/auth/offline_auth_provider.dart';
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
  Uint8List? key;

  ScanState _scanState = ScanState.scanning;
  String _errorMessage = '';
  Student? _scannedStudent;
  String? _studentImagePath;
  bool _isProcessingScan = false;

  late final Isar? isar;
  late final bool _isLateMode;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeAnimations();
    _requestPermissions();
    key = EncryptionUtils.loadEncryptionKey(widget.encryptionKey!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isar = ref.watch(isarProvider).value;
    recordManager = RecordManager(firestore: FirebaseFirestore.instance, isar: isar!);
    _isLateMode = ref.watch(isLateModeProvider);
  }

  void _initializeController() {
    _controller = MobileScannerController(
      detectionTimeoutMs: 1000,
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
    if (_isProcessingScan || _scanState != ScanState.scanning || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final scannedData = barcode.rawBytes;

    if (scannedData == null || scannedData.isEmpty) return;

    _isProcessingScan = true;

    setState(() {
      _scanState = ScanState.processing;
    });

    HapticFeedback.mediumImpact();

    try {
      final timestamp = DateTime.now();
      final lrn = await _decryptData(scannedData);

      final student = await isar!.students.filter().lrnEqualTo(lrn).findFirst();

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
        isLate: _isLateMode,
      );

      await recordManager.addRecordToIsar(record);
      widget.onScanSuccess?.call(record);

      setState(() {
        _scanState = ScanState.success;
        _scannedStudent = student;
        _studentImagePath = imagePath;
      });

      _feedbackAnimationController.forward();

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _feedbackAnimationController.reverse().then((_) {
          setState(() {
            _scanState = ScanState.scanning;
            _scannedStudent = null;
            _studentImagePath = null;
            _isProcessingScan = false;
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
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _feedbackAnimationController.reverse().then((_) {
          setState(() {
            _scanState = ScanState.scanning;
            _isProcessingScan = false;
          });
        });
      }
    }
  }

  Future<String> _decryptData(Uint8List encryptedBytes) async {
    try {
      final nonce = encryptedBytes.sublist(0, 12);
      final tag = encryptedBytes.sublist(12, 28);
      final ciphertext = encryptedBytes.sublist(28);
      final cipher = pointycastle.GCMBlockCipher(pointycastle.AESEngine())
        ..init(false, pointycastle.AEADParameters(pointycastle.KeyParameter(key!), 128, nonce, Uint8List(0)));
      final paddedCiphertext = Uint8List(ciphertext.length + tag.length)
        ..setAll(0, ciphertext)
        ..setAll(ciphertext.length, tag);
      final decrypted = cipher.process(paddedCiphertext);
      final decryptedString = utf8.decode(decrypted);
      return decryptedString;
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
    final theme = Theme.of(context);
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
        child: LayoutBuilder(builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final smallestDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
          final scanWindowSize = smallestDimension * 0.7;
          final scanWindow = Rect.fromCenter(
            center: Offset(screenWidth / 2, screenHeight / 2),
            width: scanWindowSize,
            height: scanWindowSize,
          );

          return Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _handleBarcodeScan,
              ),
              CustomPaint(
                size: constraints.biggest,
                painter: ScannerOverlayPainter(
                  scanWindow: scanWindow,
                  animation: _borderAnimationController,
                  primaryColor: theme.colorScheme.primary,
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text(
                      'Align QR code within the frame to scan',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _controller.toggleTorch(),
                            icon: const Icon(Icons.flash_on, color: Colors.white),
                            tooltip: 'Toggle Flash',
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _controller.switchCamera(),
                            icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white),
                            tooltip: 'Switch Camera',
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildFeedbackOverlay(),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFeedbackOverlay() {
    if (_scanState == ScanState.scanning || _scanState == ScanState.processing) {
      return const SizedBox.shrink();
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: FadeTransition(
        opacity: _feedbackAnimationController,
        child: ScaleTransition(
          scale: _feedbackAnimationController,
          child: Container(
            color: _scanState == ScanState.success ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
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
  final Color primaryColor;

  ScannerOverlayPainter({
    required this.scanWindow,
    required this.animation,
    required this.primaryColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(RRect.fromRectAndCorners(scanWindow, topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: const Radius.circular(20), bottomRight: const Radius.circular(20)));
    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndCorners(scanWindow, topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: const Radius.circular(20), bottomRight: const Radius.circular(20)), borderPaint);

    final cornerLength = scanWindow.width * 0.1;
    final cornerPaint = Paint()
      ..color = Color.lerp(primaryColor, Colors.white, animation.value)!
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    final cornerRect = RRect.fromRectAndCorners(scanWindow, topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: const Radius.circular(20), bottomRight: const Radius.circular(20));

    // Top-left corner
    canvas.drawLine(
      Offset(cornerRect.left, cornerRect.top + cornerLength),
      Offset(cornerRect.left, cornerRect.top),
      cornerPaint
    );
    canvas.drawLine(
      Offset(cornerRect.left, cornerRect.top),
      Offset(cornerRect.left + cornerLength, cornerRect.top),
      cornerPaint
    );

    // Top-right corner
    canvas.drawLine(
      Offset(cornerRect.right - cornerLength, cornerRect.top),
      Offset(cornerRect.right, cornerRect.top),
      cornerPaint
    );
    canvas.drawLine(
      Offset(cornerRect.right, cornerRect.top),
      Offset(cornerRect.right, cornerRect.top + cornerLength),
      cornerPaint
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cornerRect.left, cornerRect.bottom - cornerLength),
      Offset(cornerRect.left, cornerRect.bottom),
      cornerPaint
    );
    canvas.drawLine(
      Offset(cornerRect.left, cornerRect.bottom),
      Offset(cornerRect.left + cornerLength, cornerRect.bottom),
      cornerPaint
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(cornerRect.right - cornerLength, cornerRect.bottom),
      Offset(cornerRect.right, cornerRect.bottom),
      cornerPaint
    );
    canvas.drawLine(
      Offset(cornerRect.right, cornerRect.bottom - cornerLength),
      Offset(cornerRect.right, cornerRect.bottom),
      cornerPaint
    );
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final studentAvatar = CircleAvatar(
      radius: 40,
      backgroundImage: imagePath != null ? FileImage(File(imagePath!)) : null,
      child: imagePath == null ? const Icon(Icons.person, size: 40) : null,
    );

    final studentDetails = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${student.firstName} ${student.lastName}',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 4),
        Text(
          'LRN: ${student.lrn}',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(
          '${student.studentYear} - ${student.studentSection}',
          style: textTheme.bodySmall,
        ),
      ],
    );

    return OrientationBuilder(
      builder: (context, orientation) {
        final isPortrait = orientation == Orientation.portrait;
        return Container(
          width: isPortrait ? null : 450,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: isPortrait
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      studentAvatar,
                      const SizedBox(height: 16),
                      studentDetails,
                      const SizedBox(height: 24),
                      const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      studentAvatar,
                      const SizedBox(width: 24),
                      Expanded(child: studentDetails),
                      const SizedBox(width: 24),
                      const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class ErrorInfoCard extends StatelessWidget {
  final String message;

  const ErrorInfoCard({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              'Scan Error',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

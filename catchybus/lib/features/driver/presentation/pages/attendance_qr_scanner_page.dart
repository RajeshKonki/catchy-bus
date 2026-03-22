import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../config/theme/app_theme.dart';

/// Result model returned when a QR code is successfully scanned
class QrScanResult {
  final String studentId;
  final String studentName;
  final String? phone;
  final String rawCode;

  QrScanResult({
    required this.studentId,
    required this.studentName,
    this.phone,
    required this.rawCode,
  });
}

class AttendanceQrScannerPage extends StatefulWidget {
  const AttendanceQrScannerPage({super.key});

  @override
  State<AttendanceQrScannerPage> createState() =>
      _AttendanceQrScannerPageState();
}

class _AttendanceQrScannerPageState
    extends State<AttendanceQrScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Parses MECARD-formatted QR code to extract student data
  /// MECARD format: MECARD:N:Name;ORG:College;EMAIL:...;TEL:...;NOTE:Student ID: XXX;;
  QrScanResult? _parseQrCode(String code) {
    try {
      if (!code.startsWith('MECARD:')) return null;

      String? name;
      String? phone;
      String? studentId;

      // Split by ';' and parse each field
      final parts = code.replaceFirst('MECARD:', '').split(';');
      for (final part in parts) {
        if (part.startsWith('N:')) {
          name = part.substring(2).trim();
        } else if (part.startsWith('TEL:')) {
          phone = part.substring(4).trim();
        } else if (part.startsWith('NOTE:')) {
          // Format: "Student ID: <id>"
          final note = part.substring(5).trim();
          if (note.startsWith('Student ID:')) {
            studentId = note.substring('Student ID:'.length).trim();
          }
        }
      }

      if (studentId == null || studentId.isEmpty || studentId == 'N/A') {
        return null;
      }

      return QrScanResult(
        studentId: studentId,
        studentName: name ?? 'Unknown',
        phone: phone,
        rawCode: code,
      );
    } catch (e) {
      return null;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null) {
        setState(() => _isProcessing = true);

        final result = _parseQrCode(code);

        if (result != null) {
          // Successfully parsed — return structured result
          controller.stop();
          context.pop(result);
        } else {
          // Show error if QR is not a valid student QR
          _showInvalidQrError();
        }
      }
    }
  }

  void _showInvalidQrError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid QR code. Please scan a student attendance QR.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Feed
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Overlay Scrim with cut-out
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 250,
                          width: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // UI Layer
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.brightOrange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.brightOrange,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Scan Student QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask the student to show their\nattendance QR code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Scanner Frame corners
                SizedBox(
                  height: 290,
                  width: 290,
                  child: Stack(
                    children: [
                      // Corner lines — top left
                      Positioned(
                        top: 20,
                        left: 20,
                        child: _buildCorner(top: true, left: true),
                      ),
                      // Corner lines — top right
                      Positioned(
                        top: 20,
                        right: 20,
                        child: _buildCorner(top: true, left: false),
                      ),
                      // Corner lines — bottom left
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: _buildCorner(top: false, left: true),
                      ),
                      // Corner lines — bottom right
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: _buildCorner(top: false, left: false),
                      ),
                      // Animated scan line
                      if (!_isProcessing)
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: -100, end: 100),
                            duration: const Duration(seconds: 2),
                            builder: (context, value, child) => Transform.translate(
                              offset: Offset(0, value),
                              child: Container(
                                width: 230,
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.brightOrange,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            onEnd: () => setState(() {}),
                          ),
                        ),
                      if (_isProcessing)
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brightOrange,
                          ),
                        ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Instruction
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Text(
                    _isProcessing
                        ? 'Processing...'
                        : 'Position the QR code within the frame',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(
        painter: _CornerPainter(top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;

  _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brightOrange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;

    if (top && left) {
      canvas.drawLine(Offset(0, h), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
    } else if (top && !left) {
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    } else if (!top && left) {
      canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    } else {
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class QrScannerTab extends StatelessWidget {
  final MobileScannerController scannerController;
  final Function(BarcodeCapture) onDetectQR;
  final VoidCallback onBack;
  final Function(String) onError;

  const QrScannerTab({
    Key? key,
    required this.scannerController,
    required this.onDetectQR,
    required this.onBack,
    required this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.light, // White icons for dark camera screen
      ),
      child: Stack(
        children: [
          MobileScanner(controller: scannerController, onDetect: onDetectQR),

          // Khung quét (chỉ có 4 góc)
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: _ScannerCornerPainter(),
              ),
            ),
          ),

          // Thanh Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => onBack(),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Quét mã',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: ValueListenableBuilder(
                          valueListenable: scannerController,
                          builder: (context, state, child) {
                            return Icon(
                              state.torchState == TorchState.on
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              color: Colors.white,
                            );
                          },
                        ),
                        onPressed: () => scannerController.toggleTorch(),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.photo_library_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              final BarcodeCapture? capture =
                                  await scannerController.analyzeImage(
                                    image.path,
                                  );
                              if (capture != null &&
                                  capture.barcodes.isNotEmpty) {
                                onDetectQR(capture);
                              } else {
                                if (context.mounted)
                                  onError('Không tìm thấy mã QR trong ảnh.');
                              }
                            }
                          } catch (e) {
                            if (context.mounted) onError('Lỗi khi đọc ảnh.');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Text(
              'Di chuyển Camera đến vùng chứa mã QR',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final double cornerLength = 30.0;
    final path = Path();

    // Top Left
    path.moveTo(0, cornerLength);
    path.lineTo(0, 0);
    path.lineTo(cornerLength, 0);

    // Top Right
    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerLength);

    // Bottom Right
    path.moveTo(size.width, size.height - cornerLength);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - cornerLength, size.height);

    // Bottom Left
    path.moveTo(cornerLength, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

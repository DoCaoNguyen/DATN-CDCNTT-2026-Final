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

          // Tạo lớp mờ đen đục lỗ ở giữa
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Viền trắng của khung quét
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(16),
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

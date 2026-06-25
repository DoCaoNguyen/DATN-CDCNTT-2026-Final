import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../kyc/widgets/camera_overlay_painter.dart';
import 'forgot_password_otp_screen.dart';

class ForgotPasswordFaceAuthScreen extends StatefulWidget {
  final String phone;
  const ForgotPasswordFaceAuthScreen({Key? key, required this.phone})
    : super(key: key);

  @override
  State<ForgotPasswordFaceAuthScreen> createState() =>
      _ForgotPasswordFaceAuthScreenState();
}

class _ForgotPasswordFaceAuthScreenState
    extends State<ForgotPasswordFaceAuthScreen> {
  bool _isLoading = false;

  // Camera & Face Verification variables
  bool _isScanningFace = false;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  int _livenessTask = 0;
  bool _hasBlinked = false;
  bool _isProcessingFrame = false;

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _handleFaceAuth() async {
    setState(() {
      _isScanningFace = true;
      _livenessTask = 0;
      _hasBlinked = false;
      _isProcessingFrame = false;
    });

    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      CameraDescription frontCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startLivenessStream();
      }
    }
  }

  void _startLivenessStream() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessingFrame || !_isScanningFace) return;
      _isProcessingFrame = true;

      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: Platform.isAndroid
              ? InputImageFormat.nv21
              : InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      try {
        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isNotEmpty && _isScanningFace) {
          final face = faces.first;
          double leftEye = face.leftEyeOpenProbability ?? 1.0;
          double rightEye = face.rightEyeOpenProbability ?? 1.0;
          double headY = face.headEulerAngleY ?? 0.0;
          double faceRatio =
              face.boundingBox.width /
              (image.width < image.height ? image.width : image.height);

          if (_livenessTask == 0 && faceRatio < 0.45) {
            setState(() => _livenessTask = 1); // Move closer
          } else if (_livenessTask == 1 && faceRatio > 0.55) {
            setState(() => _livenessTask = 2); // Look left
          } else if (_livenessTask == 2 && headY < -20) {
            setState(() => _livenessTask = 3); // Look right
          } else if (_livenessTask == 3 && headY > 20) {
            setState(() => _livenessTask = 4); // Blink eyes
          } else if (_livenessTask == 4) {
            if (leftEye < 0.2 && rightEye < 0.2) {
              _hasBlinked = true;
            } else if (_hasBlinked && leftEye > 0.8 && rightEye > 0.8) {
              setState(() => _livenessTask = 5);

              // Liveness success
              await _cameraController?.stopImageStream();

              if (mounted) {
                setState(() {
                  _isScanningFace = false;
                  _isCameraInitialized = false;
                });
              }

              await _cameraController?.dispose();
              _cameraController = null;

              // Navigate to Forgot Password OTP
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ForgotPasswordOtpScreen(phone: widget.phone),
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint("ML Kit Liveness Error: $e");
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  String _getLivenessInstruction() {
    switch (_livenessTask) {
      case 0:
        return "Vui lòng đưa điện thoại RA XA";
      case 1:
        return "Vui lòng đưa điện thoại LẠI GẦN";
      case 2:
        return "Vui lòng QUAY ĐẦU SANG TRÁI";
      case 3:
        return "Vui lòng QUAY ĐẦU SANG PHẢI";
      case 4:
        return "Vui lòng CHỚP MẮT";
      case 5:
        return "Xác thực thành công!";
      default:
        return "Đang phân tích...";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanningFace) {
      if (!_isCameraInitialized || _cameraController == null) {
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.pink)),
        );
      }

      final size = MediaQuery.of(context).size;
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SizedBox(
              width: size.width,
              height: size.height,
              child: CameraPreview(_cameraController!),
            ),
            CustomPaint(
              size: size,
              painter: CameraOverlayPainter(isSelfie: true),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    setState(() {
                      _isScanningFace = false;
                      _isCameraInitialized = false;
                    });
                    try {
                      await _cameraController?.stopImageStream();
                      await _cameraController?.dispose();
                    } catch (e) {
                      debugPrint("Error disposing camera: $e");
                    }
                    _cameraController = null;
                  },
                ),
              ),
            ),
            Positioned(
              top: 100,
              width: size.width,
              child: Column(
                children: [
                  const Text(
                    "XÁC THỰC KHUÔN MẶT ĐỂ ĐẶT LẠI MẬT KHẨU",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getLivenessInstruction(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFE4EE), Color(0xFFF5F5F9)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryPink,
                                    width: 4,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.face_rounded,
                                    size: 60,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Xác thực khuôn mặt',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Chỉ 5 giây',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          _buildCheckItem('Đảm bảo chính xác bạn là chủ Ví'),
                          const SizedBox(height: 12),
                          _buildCheckItem(
                            'Bảo vệ tài khoản của bạn khỏi rủi ro',
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleFaceAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Xác thực ngay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, color: Colors.green, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../auth/kyc/widgets/camera_overlay_painter.dart';

class FaceLivenessScannerScreen extends StatefulWidget {
  const FaceLivenessScannerScreen({Key? key}) : super(key: key);

  @override
  State<FaceLivenessScannerScreen> createState() =>
      _FaceLivenessScannerScreenState();
}

class _FaceLivenessScannerScreenState extends State<FaceLivenessScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableTracking: true,
    ),
  );

  int _livenessTask = 0;
  bool _hasBlinked = false;
  bool _isProcessingFrame = false;
  bool _isScanningFace = true;

  @override
  void initState() {
    super.initState();
    _initFaceCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _initFaceCamera() async {
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

              await _cameraController?.stopImageStream();
              final photo = await _cameraController!.takePicture();

              if (mounted) {
                setState(() {
                  _isScanningFace = false;
                  _isCameraInitialized = false;
                });
              }

              await _cameraController?.dispose();
              _cameraController = null;

              if (mounted) {
                Navigator.pop(context, File(photo.path));
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
        return "Đang xác nhận khuôn mặt...";
      default:
        return "Đang phân tích...";
    }
  }

  @override
  Widget build(BuildContext context) {
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
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'Xác thực khuôn mặt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

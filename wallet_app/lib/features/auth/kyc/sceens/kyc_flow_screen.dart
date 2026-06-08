import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../utils/ocr_helper.dart';
import '../widgets/camera_overlay_painter.dart';
import '../widgets/ocr_confirm_form.dart';
import '../widgets/camera_action_buttons.dart';
import '../widgets/kyc_dialogs.dart';

class KycFlowScreen extends StatefulWidget {
  final String userId;
  const KycFlowScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<KycFlowScreen> createState() => _KycFlowScreenState();
}

class _KycFlowScreenState extends State<KycFlowScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final FaceDetector _faceDetector = FaceDetector(options: FaceDetectorOptions(enableClassification: true, enableTracking: true, performanceMode: FaceDetectorMode.fast));

  int _currentStep = 1;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _isCapturing = false;
  bool _isPreviewing = false;

  File? _tempImage;
  File? _idFrontImage;
  File? _idBackImage;
  File? _faceImage;

  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isProcessingFrame = false;
  int _livenessTask = 0;
  bool _hasBlinked = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      CameraDescription selectedCamera = _currentStep == 4
          ? _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.front)
          : _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

      _cameraController = CameraController(selectedCamera, ResolutionPreset.high, enableAudio: false, imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888);
      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          if (_currentStep == 4) _startLivenessDetection();
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _idNumberController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (!_cameraController!.value.isInitialized || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      await Future.delayed(const Duration(milliseconds: 500));
      final XFile photo = await _cameraController!.takePicture();
      setState(() { _tempImage = File(photo.path); _isPreviewing = true; });
    } catch (e) { print("Lỗi chụp ảnh: $e"); } finally { setState(() => _isCapturing = false); }
  }

  void _retakePhoto() => setState(() { _tempImage = null; _isPreviewing = false; });

  Future<void> _confirmPhoto() async {
    setState(() => _isLoading = true);
    bool isValid = await OcrHelper.validateIdCardQuality(_tempImage!, _currentStep == 1);

    if (!isValid) {
      setState(() => _isLoading = false);
      KycDialogs.showWarning(context);
      return;
    }

    if (_currentStep == 1) {
      setState(() { _idFrontImage = _tempImage; _currentStep = 2; _tempImage = null; _isPreviewing = false; _isCameraInitialized = false; _isLoading = false; });
      _initializeCamera();
    } else if (_currentStep == 2) {
      setState(() { _idBackImage = _tempImage; _tempImage = null; _isPreviewing = false; _isCameraInitialized = false; });
      await _processOCRAndCheckConditions();
    }
  }

  Future<void> _processOCRAndCheckConditions() async {
    try {
      var data = await OcrHelper.extractInfo(_idFrontImage!);

      if (data["id"]!.isEmpty || data["dob"]!.isEmpty) {
         setState(() => _isLoading = false);
         KycDialogs.showError(context, "Ảnh bị mờ. Không thể đọc được Số CCCD và Ngày sinh.", _resetFlow);
         return;
      }

      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/kyc/check-id?id=${data["id"]}'));
      if (response.statusCode == 200 && jsonDecode(response.body)['is_used'] == true) {
        setState(() => _isLoading = false);
        KycDialogs.showError(context, "Số CCCD này đã được sử dụng. Vui lòng liên hệ CSKH.", _resetFlow);
        return;
      }

      if (!OcrHelper.isOver18(data["dob"]!)) {
        setState(() => _isLoading = false);
        KycDialogs.showError(context, "Rất tiếc, bạn phải đủ 18 tuổi để sử dụng dịch vụ.", _resetFlow);
        return;
      }

      setState(() {
        _idNumberController.text = data["id"]!; _dobController.text = data["dob"]!; _fullNameController.text = data["name"]!;
        _genderController.text = data["gender"]!; _addressController.text = data["address"]!;
        _isLoading = false; _currentStep = 3;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      KycDialogs.showError(context, "Lỗi quét dữ liệu: Vui lòng chụp lại ảnh.", _resetFlow);
    }
  }

  void _startLivenessDetection() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessingFrame) return;
      _isProcessingFrame = true;
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) { allBytes.putUint8List(plane.bytes); }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      try {
        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isNotEmpty) {
          final face = faces.first;
          double leftEye = face.leftEyeOpenProbability ?? 1.0;
          double rightEye = face.rightEyeOpenProbability ?? 1.0;
          double headY = face.headEulerAngleY ?? 0.0;
          double faceRatio = face.boundingBox.width / (image.width < image.height ? image.width : image.height);

          if (_livenessTask == 0 && faceRatio < 0.45) setState(() => _livenessTask = 1);
          else if (_livenessTask == 1 && faceRatio > 0.55) setState(() => _livenessTask = 2);
          else if (_livenessTask == 2 && headY < -20) setState(() => _livenessTask = 3);
          else if (_livenessTask == 3 && headY > 20) setState(() => _livenessTask = 4);
          else if (_livenessTask == 4) {
            if (leftEye < 0.2 && rightEye < 0.2) _hasBlinked = true;
            else if (_hasBlinked && leftEye > 0.8 && rightEye > 0.8) {
              setState(() => _livenessTask = 5);
              await _cameraController?.stopImageStream();
              final photo = await _cameraController!.takePicture();
              setState(() { _faceImage = File(photo.path); _isCameraInitialized = false; });
              _submitKycAPI();
            }
          }
        }
      } catch (e) { print("Lỗi AI: $e"); }
      _isProcessingFrame = false;
    });
  }

  Future<void> _submitKycAPI() async {
    setState(() => _isLoading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.verifyKyc));
      request.fields['user_id'] = widget.userId;
      request.fields['ocr_data'] = jsonEncode({"id_number": _idNumberController.text.trim(), "full_name": _fullNameController.text.trim(), "dob": _dobController.text.trim(), "gender": _genderController.text.trim(), "address": _addressController.text.trim()});
      request.files.add(await http.MultipartFile.fromPath('face_image', _faceImage!.path));
      request.files.add(await http.MultipartFile.fromPath('id_front', _idFrontImage!.path));
      request.files.add(await http.MultipartFile.fromPath('id_back', _idBackImage!.path));

      var response = await http.Response.fromStream(await request.send());
      setState(() => _isLoading = false);

      if (response.statusCode == 200) KycDialogs.showSuccess(context, widget.userId);
      else KycDialogs.showError(context, jsonDecode(response.body)['error'] ?? 'Lỗi xác thực', _resetFlow);
    } catch (e) {
      setState(() => _isLoading = false);
      KycDialogs.showError(context, 'Không thể kết nối đến máy chủ.', _resetFlow);
    }
  }

  void _resetFlow() {
    Navigator.pop(context);
    setState(() {
      _currentStep = 1; _faceImage = null; _idFrontImage = null; _idBackImage = null;
      _tempImage = null; _isPreviewing = false; _livenessTask = 0; _hasBlinked = false;
      _initializeCamera();
    });
  }

  String getLivenessInstruction() {
    if (_currentStep != 4) return _isPreviewing ? "Kiểm tra ảnh có bị mờ hoặc lóa sáng không" : "Vui lòng đặt CCCD vừa khít vào khung hình chữ nhật";
    switch (_livenessTask) {
      case 0: return "1/5. Vui lòng đưa điện thoại RA XA";
      case 1: return "2/5. Vui lòng đưa điện thoại LẠI GẦN";
      case 2: return "3/5. Vui lòng QUAY ĐẦU SANG TRÁI";
      case 3: return "4/5. Vui lòng QUAY ĐẦU SANG PHẢI";
      case 4: return "5/5. Vui lòng CHỚP MẮT";
      case 5: return "Xác thực thành công!";
      default: return "Đang phân tích...";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 3) {
      return OcrConfirmForm(idNumberController: _idNumberController, fullNameController: _fullNameController, dobController: _dobController, genderController: _genderController, addressController: _addressController, onSubmit: () { setState(() { _currentStep = 4; _isLoading = true; }); Future.delayed(const Duration(milliseconds: 500), () { setState(() => _isLoading = false); _initializeCamera(); }); });
    }

    if (_isLoading || !_isCameraInitialized || _cameraController == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppColors.primaryPink)));
    }

    final size = MediaQuery.of(context).size;
    final isSelfieStep = _currentStep == 4;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(width: size.width, height: size.height, child: _isPreviewing && _tempImage != null ? Image.file(_tempImage!, fit: BoxFit.cover) : CameraPreview(_cameraController!)),
          CustomPaint(size: size, painter: CameraOverlayPainter(isSelfie: isSelfieStep)),
          SafeArea(child: Align(alignment: Alignment.topLeft, child: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)))),
          Positioned(
            top: 100, width: size.width,
            child: Column(
              children: [
                Text(isSelfieStep ? "XÁC THỰC KHUÔN MẶT" : "CHỤP MẶT ${(_currentStep == 1 ? "TRƯỚC" : "SAU")} CCCD", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isSelfieStep ? Colors.red.withOpacity(0.8) : Colors.black54, borderRadius: BorderRadius.circular(20)), child: Text(getLivenessInstruction(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          if (!isSelfieStep)
            Positioned(
              bottom: 60, width: size.width,
              child: CameraActionButtons(isPreviewing: _isPreviewing, isCapturing: _isCapturing, onTake: _takePhoto, onRetake: _retakePhoto, onConfirm: _confirmPhoto),
            )
        ],
      ),
    );
  }
}
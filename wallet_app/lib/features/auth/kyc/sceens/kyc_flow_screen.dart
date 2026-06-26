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
import '../services/nfc_kyc_service.dart';

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
  String? _kycSessionId;

  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  bool _isProcessingFrame = false;
  int _livenessTask = 0;
  bool _hasBlinked = false;

  // Biến phục vụ đọc chip NFC
  bool _isNfcLoading = false;
  String _nfcStatusMessage = '';
  String? _nfcErrorMessage;
  CccdKycResult? _nfcResult;

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
    _expiryDateController.dispose();
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

    if (_currentStep == 1) {
      bool isValid = await OcrHelper.validateIdCardQuality(_tempImage!, true);
      if (!isValid) {
        setState(() => _isLoading = false);
        KycDialogs.showWarning(context);
        return;
      }
      
      // Gọi FPT.AI ngay sau khi chụp xong mặt trước để lấy Data đối soát cho mặt sau
      bool ocrSuccess = await _processOCRFront(_tempImage!);
      if (!ocrSuccess) return;

      setState(() { _idFrontImage = _tempImage; _currentStep = 2; _tempImage = null; _isPreviewing = false; _isCameraInitialized = false; _isLoading = false; });
      _initializeCamera();

    } else if (_currentStep == 2) {
      // Đối soát mặt sau bằng dữ liệu OCR của mặt trước
      bool isValidBack = await OcrHelper.validateIdCardQuality(
        _tempImage!, false, 
        expectedId: _idNumberController.text, 
        expectedName: _fullNameController.text
      );
      if (!isValidBack) {
        setState(() => _isLoading = false);
        KycDialogs.showWarning(context, message: "Mặt sau không hợp lệ hoặc không khớp với thẻ mặt trước. Vui lòng chụp cho khớp khung hình.");
        _retakePhoto();
        return;
      }

      setState(() { _idBackImage = _tempImage; _tempImage = null; _isPreviewing = false; _isCameraInitialized = false; _isLoading = false; _currentStep = 3; });
    }
  }

  Future<bool> _processOCRFront(File idFrontImage) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/kyc/ocr-front'));
      request.files.add(await http.MultipartFile.fromPath('id_front', idFrontImage.path));
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var json = jsonDecode(responseData);
      
      if (response.statusCode != 200) {
        setState(() => _isLoading = false);
        KycDialogs.showError(context, json['error'] ?? "Lỗi phân tích thẻ CCCD", _resetFlow);
        return false;
      }

      var ocrData = json['ocr_data'];
      _kycSessionId = json['session_id'];

      Map<String, String> data = {
        "id": ocrData['id_number']?.toString() ?? "",
        "name": ocrData['full_name']?.toString() ?? "",
        "dob": ocrData['dob']?.toString() ?? "",
        "gender": ocrData['gender']?.toString() ?? "",
        "address": ocrData['address']?.toString() ?? ""
      };

      if (data["id"]!.isEmpty || data["dob"]!.isEmpty) {
         setState(() => _isLoading = false);
         KycDialogs.showError(context, "Ảnh bị mờ. Không thể đọc được Số CCCD và Ngày sinh.", _resetFlow);
         return false;
      }

      final checkResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/kyc/check-id?id=${data["id"]}'));
      if (checkResponse.statusCode == 200 && jsonDecode(checkResponse.body)['is_used'] == true) {
        setState(() => _isLoading = false);
        KycDialogs.showError(context, "Số CCCD này đã được sử dụng. Vui lòng liên hệ CSKH.", _resetFlow);
        return false;
      }

      if (!OcrHelper.isOver18(data["dob"]!)) {
        setState(() => _isLoading = false);
        KycDialogs.showError(context, "Rất tiếc, bạn phải đủ 18 tuổi để sử dụng dịch vụ.", _resetFlow);
        return false;
      }

      final calculatedExpiry = NfcKycService.calculateExpiryDate(data["dob"]!);
      if (calculatedExpiry.length == 6) {
        final yy = int.parse(calculatedExpiry.substring(0, 2));
        final mm = int.parse(calculatedExpiry.substring(2, 4));
        final dd = int.parse(calculatedExpiry.substring(4, 6));
        final year = yy < 50 ? 2000 + yy : 1900 + yy;
        final expiryDate = DateTime(year, mm, dd);
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        if (expiryDate.isBefore(todayStart)) {
          setState(() => _isLoading = false);
          KycDialogs.showError(context, "CCCD của bạn đã hết hạn sử dụng. Vui lòng sử dụng thẻ còn hạn.", _resetFlow);
          return false;
        }
      }
      String formattedExpiry = "";
      if (calculatedExpiry.length == 6) {
        final yy = calculatedExpiry.substring(0, 2);
        final mm = calculatedExpiry.substring(2, 4);
        final dd = calculatedExpiry.substring(4, 6);
        final year = int.parse(yy) < 50 ? "20$yy" : "19$yy";
        formattedExpiry = "$dd/$mm/$year";
      }

      _idNumberController.text = data["id"]!; _dobController.text = data["dob"]!; _fullNameController.text = data["name"]!;
      _genderController.text = data["gender"]!; _addressController.text = data["address"]!;
      _expiryDateController.text = formattedExpiry;
      return true;
    } catch (e) {
      setState(() => _isLoading = false);
      KycDialogs.showError(context, "Lỗi quét dữ liệu: Vui lòng kiểm tra lại mạng hoặc chụp lại ảnh.", _resetFlow);
      return false;
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
      if (_kycSessionId != null) request.fields['session_id'] = _kycSessionId!;
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
      _currentStep = 1; _faceImage = null; _idFrontImage = null; _idBackImage = null; _kycSessionId = null;
      _idNumberController.clear(); _fullNameController.clear(); _dobController.clear();
      _genderController.clear(); _addressController.clear(); _expiryDateController.clear();
      _livenessTask = 0; _hasBlinked = false; _nfcResult = null;
      _isCameraInitialized = false;
    });
    _initializeCamera();
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
      return OcrConfirmForm(
        idNumberController: _idNumberController,
        fullNameController: _fullNameController,
        dobController: _dobController,
        genderController: _genderController,
        addressController: _addressController,
        expiryDateController: _expiryDateController,
        onSubmit: () async {
          setState(() {
            _currentStep = 4;
            _isLoading = true;
          });
          await _initializeCamera();
          setState(() => _isLoading = false);
        },
      );
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
          SafeArea(child: Align(alignment: Alignment.topLeft, child: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)))),
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

  // Giao diện đọc NFC ngay trong luồng KYC
  Widget _buildNfcReadingView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Xác thực thẻ chip NFC', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            setState(() {
              _currentStep = 3;
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contactless_rounded,
                size: 80,
                color: AppColors.primaryPink,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Đọc chip NFC trên thẻ CCCD',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              _isNfcLoading 
                  ? _nfcStatusMessage 
                  : 'Đặt phần mặt sau CCCD (nơi có con chip vàng) áp sát vào mặt lưng điện thoại.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_nfcErrorMessage != null) ...[
              Text(
                _nfcErrorMessage!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
            if (_isNfcLoading)
              const CircularProgressIndicator(color: AppColors.primaryPink)
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _startNfcReading,
                  icon: const Icon(Icons.nfc_rounded, color: Colors.white),
                  label: const Text(
                    'Bắt đầu đọc NFC',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Thực thi kết nối và đọc chip NFC
  Future<void> _startNfcReading() async {
    setState(() {
      _isNfcLoading = true;
      _nfcStatusMessage = 'Vui lòng áp thẻ CCCD vào lưng điện thoại...';
      _nfcErrorMessage = null;
    });

    try {
      final rawDob = _dobController.text.trim();
      final rawDoe = _expiryDateController.text.trim();
      final dobYYMMDD = NfcKycService.formatDobToYYMMDD(rawDob);
      final doeYYMMDD = NfcKycService.formatDobToYYMMDD(rawDoe);

      final result = await NfcKycService.readCCCDChip(
        documentNumber: _idNumberController.text.trim(),
        dobYYMMDD: dobYYMMDD,
        doeYYMMDD: doeYYMMDD,
      );

      // Lưu kết quả đọc nfc thành công
      setState(() {
        _nfcResult = result;
        _isNfcLoading = false;
        _currentStep = 5;
        _isLoading = true;
      });

      // Khởi tạo camera để quét mặt ở Bước 5
      await _initializeCamera();
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      debugPrint("LỐI ĐỌC CHIP NFC CHI TIẾT: $e");
      debugPrint(stackTrace.toString());
      
      String userFriendlyError = 'Đọc NFC thất bại. Vui lòng thử lại!';
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('timeout')) {
        userFriendlyError = 'Thời gian kết nối quá hạn. Vui lòng áp thẻ sát hơn.';
      } else if (errStr.contains('session') || errStr.contains('bac') || errStr.contains('security')) {
        userFriendlyError = 'Thông tin BAC không khớp (Số CCCD hoặc Ngày sinh không đúng).';
      } else if (errStr.contains('not supported')) {
        userFriendlyError = 'Thiết bị không hỗ trợ đọc NFC.';
      } else if (errStr.contains('nfc finish') || errStr.contains('disconnected')) {
        userFriendlyError = 'Thẻ bị ngắt kết nối. Vui lòng giữ yên thẻ khi đọc.';
      }

      setState(() {
        _isNfcLoading = false;
        _nfcErrorMessage = "$userFriendlyError\n(Chi tiết lỗi: $e)";
      });
    }
  }
}
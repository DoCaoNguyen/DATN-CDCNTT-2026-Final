import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/screens/home_screen.dart';

class KycFlowScreen extends StatefulWidget {
  final String userId;
  const KycFlowScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<KycFlowScreen> createState() => _KycFlowScreenState();
}

class _KycFlowScreenState extends State<KycFlowScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  // 1: CCCD Trước, 2: CCCD Sau, 3: Form Xác nhận OCR, 4: Selfie Liveness
  int _currentStep = 1;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _isCapturing = false;

  bool _isPreviewing = false;
  File? _tempImage;

  File? _idFrontImage;
  File? _idBackImage;
  File? _faceImage;

  // --- CONTROLLER CHO FORM XÁC NHẬN OCR ---
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
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
          ? _cameras!.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
            )
          : _cameras!.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
            );

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset
            .high, // ĐÃ HẠ XUỐNG HIGH ĐỂ TRỊ BỆNH TRÀN BUFFER (maxImages buffers)
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          if (_currentStep == 4) {
            _startLivenessDetection();
          }
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
      // Ép lấy nét (Bọc Try Catch phòng hờ máy không hỗ trợ)
      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (e) {
        print("Camera không hỗ trợ ép lấy nét: $e");
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _tempImage = File(photo.path);
        _isPreviewing = true;
      });
    } catch (e) {
      print("Lỗi chụp ảnh: $e");
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  void _retakePhoto() {
    setState(() {
      _tempImage = null;
      _isPreviewing = false;
    });
  }

  // ====================================================================
  // KIỂM TRA CHẤT LƯỢNG ẢNH THẺ
  // ====================================================================
  Future<bool> _validateIdCardQuality(File imageFile, bool isFront) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      textRecognizer.close();

      String text = recognizedText.text.toUpperCase();

      if (text.trim().isEmpty || recognizedText.blocks.length < 4) return false;

      if (isFront) {
        bool hasTop = text.contains("CỘNG HÒA") || text.contains("VIỆT NAM");
        bool hasTitle =
            text.contains("CĂN CƯỚC") ||
            text.contains("CÔNG DÂN") ||
            text.contains("CHỨNG MINH");
        bool hasId = RegExp(r'\d{9,12}').hasMatch(text);
        bool hasBottom =
            text.contains("QUÊ QUÁN") ||
            text.contains("THƯỜNG TRÚ") ||
            text.contains("RESIDENCE") ||
            text.contains("GIÁ TRỊ");

        return hasTop && hasTitle && hasId && hasBottom;
      } else {
        bool hasBackKeywords =
            text.contains("ĐẶC ĐIỂM") ||
            text.contains("NHẬN DẠNG") ||
            text.contains("CỤC TRƯỞNG") ||
            text.contains("GIÁM ĐỐC") ||
            text.contains("CÔNG AN") ||
            text.contains("NGÀY") ||
            text.contains("THÁNG") ||
            text.contains("NĂM");

        return hasBackKeywords && recognizedText.blocks.length >= 2;
      }
    } catch (e) {
      return false;
    }
  }

  void _showQualityWarningDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              "Ảnh không đạt chuẩn",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Hệ thống không nhận diện được đầy đủ thẻ. Nguyên nhân có thể do:\n\n"
          "• Thẻ bị chụp QUÁ GẦN làm mất góc/cạnh.\n"
          "• Ảnh bị mờ, rung tay hoặc chói sáng.\n"
          "• Thẻ nằm lệch ra khỏi khung hình.\n\n"
          "Vui lòng lùi điện thoại lại, đặt thẻ lọt thỏm vào giữa khung hình chữ nhật và chụp lại.",
          style: TextStyle(height: 1.5, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Chụp lại",
              style: TextStyle(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- XÁC NHẬN ẢNH THẺ VÀ CHẠY OCR ---
  Future<void> _confirmPhoto() async {
    setState(() => _isLoading = true);

    bool isValid = await _validateIdCardQuality(_tempImage!, _currentStep == 1);

    if (!isValid) {
      setState(() => _isLoading = false);
      _showQualityWarningDialog();
      return;
    }

    if (_currentStep == 1) {
      setState(() {
        _idFrontImage = _tempImage;
        _currentStep = 2;
        _tempImage = null;
        _isPreviewing = false;
        _isCameraInitialized = false;
        _isLoading = false;
      });
      _initializeCamera();
    } else if (_currentStep == 2) {
      setState(() {
        _idBackImage = _tempImage;
        _tempImage = null;
        _isPreviewing = false;
        _isCameraInitialized = false;
      });

      await _processOCR(_idFrontImage!);

      setState(() {
        _isLoading = false;
        _currentStep = 3;
      });
    }
  }

  // ====================================================================
  // BỘ NÃO ĐỌC CHỮ OCR CHI TIẾT
  // ====================================================================
  Future<void> _processOCR(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String fullText = recognizedText.text;
      textRecognizer.close();

      // ======== HIỂN THỊ KẾT QUẢ THẲNG LÊN MÀN HÌNH BẰNG DIALOG ========
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              "🔍 RAW TEXT TỪ AI",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: SelectableText(
                fullText,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "ĐÓNG",
                  style: TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      // =================================================================

      String idNumber = "";
      String dob = "";
      String fullName = "";
      String gender = "";
      String address = "";

      // 1. LẤY SỐ CCCD
      String cleanTextForId = fullText
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll('-', '');
      idNumber = RegExp(r'\d{12}').stringMatch(cleanTextForId) ?? "";

      List<String> lines = fullText
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        String upperLine = line.toUpperCase();

        // 2. LẤY NGÀY SINH (Tìm đích danh dòng có chữ SINH hoặc BIRTH)
        if (dob.isEmpty && RegExp(r'(SINH|BIRTH)').hasMatch(upperLine)) {
          dob = RegExp(r'\d{2}[-/]\d{2}[-/]\d{4}').stringMatch(line) ?? "";
        }

        // 3. LẤY HỌ TÊN (Dựa vào chữ TÊN hoặc NAME hoặc NARNE bị sai chính tả)
        if (fullName.isEmpty &&
            RegExp(r'(TÊN|NAME|NARNE)').hasMatch(upperLine)) {
          String val = line
              .replaceAll(
                RegExp(r'.*(TÊN|NAME|NARNE)[\s:/*]*', caseSensitive: false),
                '',
              )
              .trim();
          if (val.length > 4 && !RegExp(r'\d').hasMatch(val)) {
            fullName = val.toUpperCase();
          } else if (i + 1 < lines.length) {
            fullName = lines[i + 1].toUpperCase();
          }
        }

        // 4. LẤY GIỚI TÍNH (Chống dính chữ Quốc tịch Việt Nam)
        if (gender.isEmpty && RegExp(r'(TÍNH|TINH|SEX)').hasMatch(upperLine)) {
          // Bỏ chữ Viet Nam đi để tránh nhận nhầm Nam trong Việt Nam
          String cleanGenderLine = line.replaceAll(
            RegExp(r'(VIỆT NAM|VIET NAM)', caseSensitive: false),
            '',
          );
          var gMatch = RegExp(
            r'(Nam|Nữ|Nu)',
            caseSensitive: false,
          ).firstMatch(cleanGenderLine);
          if (gMatch != null) {
            gender = gMatch.group(1)!.toLowerCase() == 'nam' ? 'Nam' : 'Nữ';
          }
        }

        // 5. LẤY NƠI THƯỜNG TRÚ (Bắt chữ TRÚ hoặc TRÙ sai chính tả)
        if (address.isEmpty &&
            RegExp(r'(TRÚ|TRÙ|RESIDENCE)').hasMatch(upperLine)) {
          String val = line
              .replaceAll(
                RegExp(r'.*(TRÚ|TRÙ|RESIDENCE)[\s:/*]*', caseSensitive: false),
                '',
              )
              .trim();
          address = val;
          // Vét thêm dòng dưới (đề phòng địa chỉ bị cắt làm 2)
          if (i + 1 < lines.length) {
            String nextLine = lines[i + 1];
            // Bỏ qua nếu dòng dưới chỉ là 1 số rác (VD: số 2, số 6 trong ảnh của bạn)
            if (nextLine.length > 4 &&
                !RegExp(r'^[0-9]+$').hasMatch(nextLine)) {
              if (address.isNotEmpty) address += ", ";
              address += nextLine;
            }
          }
          address = address.replaceFirst(RegExp(r'^,\s*'), '').trim();
        }
      }

      // Cập nhật lên Giao diện Form
      setState(() {
        _idNumberController.text = idNumber;
        _dobController.text = dob;
        _fullNameController.text = fullName;
        _genderController.text = gender;
        _addressController.text = address;
      });
    } catch (e) {
      print("Lỗi OCR Offline: $e");
    }
  }

  // ====================================================================
  // BỘ NÃO LIVENESS DETECTION
  // ====================================================================
  void _startLivenessDetection() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessingFrame) return;
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

        if (faces.isNotEmpty) {
          final face = faces.first;

          double leftEye = face.leftEyeOpenProbability ?? 1.0;
          double rightEye = face.rightEyeOpenProbability ?? 1.0;
          double headY = face.headEulerAngleY ?? 0.0;

          double actualImageWidth = image.width < image.height
              ? image.width.toDouble()
              : image.height.toDouble();
          double faceRatio = face.boundingBox.width / actualImageWidth;

          if (_livenessTask == 0) {
            if (faceRatio < 0.45) setState(() => _livenessTask = 1);
          } else if (_livenessTask == 1) {
            if (faceRatio > 0.55) setState(() => _livenessTask = 2);
          } else if (_livenessTask == 2) {
            if (headY < -20) setState(() => _livenessTask = 3);
          } else if (_livenessTask == 3) {
            if (headY > 20) setState(() => _livenessTask = 4);
          } else if (_livenessTask == 4) {
            if (leftEye < 0.2 && rightEye < 0.2) {
              _hasBlinked = true;
            } else if (_hasBlinked && leftEye > 0.8 && rightEye > 0.8) {
              setState(() => _livenessTask = 5);
              await _finishLivenessAndTakeFacePhoto();
            }
          }
        }
      } catch (e) {
        print("Lỗi AI: $e");
      }
      _isProcessingFrame = false;
    });
  }

  Future<void> _finishLivenessAndTakeFacePhoto() async {
    await _cameraController?.stopImageStream();
    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _faceImage = File(photo.path);
        _isCameraInitialized = false;
      });
      _submitKycAPI();
    } catch (e) {
      print("Lỗi tự động chụp selfie: $e");
    }
  }

  // ====================================================================
  // API GỌI LÊN NODE.JS
  // ====================================================================
  Future<void> _submitKycAPI() async {
    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.verifyKyc),
      );
      request.fields['user_id'] = widget.userId;

      request.fields['ocr_data'] = jsonEncode({
        "id_number": _idNumberController.text.trim(),
        "full_name": _fullNameController.text.trim(),
        "dob": _dobController.text.trim(),
        "gender": _genderController.text.trim(),
        "address": _addressController.text.trim(),
      });

      request.files.add(
        await http.MultipartFile.fromPath('face_image', _faceImage!.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('id_front', _idFrontImage!.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('id_back', _idBackImage!.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        try {
          var responseData = jsonDecode(response.body);
          _showErrorDialog(
            responseData['error'] ?? 'Lỗi xác thực: ${response.statusCode}',
          );
        } catch (e) {
          _showErrorDialog('Lỗi máy chủ: ${response.statusCode}');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Không thể kết nối đến máy chủ.');
    }
  }

  // ====================================================================
  // CÁC DIALOG THÔNG BÁO
  // ====================================================================
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Xác thực thành công',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Khuôn mặt và CCCD hoàn toàn trùng khớp. Hồ sơ của bạn đã được duyệt.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      // ĐÃ SỬA: Bỏ chữ const, truyền userId và isVerified = true
                      builder: (_) =>
                          HomeScreen(userId: widget.userId, isVerified: true),
                    ),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Về trang chủ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Xác thực thất bại',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentStep = 1;
                    _faceImage = null;
                    _idFrontImage = null;
                    _idBackImage = null;
                    _tempImage = null;
                    _isPreviewing = false;
                    _livenessTask = 0;
                    _hasBlinked = false;
                    _initializeCamera();
                  });
                },
                child: const Text(
                  'Thử lại từ đầu',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getLivenessInstruction() {
    if (_currentStep != 4) {
      return _isPreviewing
          ? "Kiểm tra ảnh có bị mờ hoặc lóa sáng không"
          : "Vui lòng đặt CCCD vừa khít vào khung hình chữ nhật";
    }
    switch (_livenessTask) {
      case 0:
        return "1/5. Vui lòng đưa điện thoại RA XA";
      case 1:
        return "2/5. Vui lòng đưa điện thoại LẠI GẦN";
      case 2:
        return "3/5. Vui lòng QUAY ĐẦU SANG TRÁI";
      case 3:
        return "4/5. Vui lòng QUAY ĐẦU SANG PHẢI";
      case 4:
        return "5/5. Vui lòng CHỚP MẮT";
      case 5:
        return "Xác thực thành công!";
      default:
        return "Đang phân tích...";
    }
  }

  // ====================================================================
  // GIAO DIỆN MÀN HÌNH FORM XÁC NHẬN OCR (BƯỚC 3)
  // ====================================================================
  Widget _buildOcrFormScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Xác nhận thông tin',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hệ thống đã trích xuất thông tin từ CCCD. Vui lòng kiểm tra và điền các thông tin còn thiếu.",
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _idNumberController,
              decoration: const InputDecoration(
                labelText: "Số CCCD",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: "Họ và Tên (In hoa)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      labelText: "Ngày sinh",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _genderController,
                    decoration: const InputDecoration(
                      labelText: "Giới tính",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Quê quán / Nơi thường trú",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                ),
                onPressed: () {
                  if (_idNumberController.text.isEmpty ||
                      _fullNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Vui lòng nhập đủ Số CCCD và Họ tên"),
                      ),
                    );
                    return;
                  }
                  // Chuyển sang bước quét khuôn mặt
                  setState(() {
                    _currentStep = 4;
                    _isLoading = true;
                  });
                  Future.delayed(const Duration(milliseconds: 500), () {
                    setState(() => _isLoading = false);
                    _initializeCamera();
                  });
                },
                child: const Text(
                  'Xác nhận & Tiến hành quét khuôn mặt',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // BUILD CHÍNH
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    if (_currentStep == 3) {
      return _buildOcrFormScreen();
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryPink),
              SizedBox(height: 16),
              Text(
                'Đang phân tích dữ liệu...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final isSelfieStep = _currentStep == 4;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(
            width: size.width,
            height: size.height,
            child: _isPreviewing && _tempImage != null
                ? Image.file(_tempImage!, fit: BoxFit.cover)
                : CameraPreview(_cameraController!),
          ),

          CustomPaint(
            size: size,
            painter: CameraOverlayPainter(isSelfie: isSelfieStep),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            top: 100,
            width: size.width,
            child: Column(
              children: [
                Text(
                  isSelfieStep
                      ? "XÁC THỰC KHUÔN MẶT"
                      : "CHỤP MẶT ${(_currentStep == 1 ? "TRƯỚC" : "SAU")} CCCD",
                  style: const TextStyle(
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
                    color: isSelfieStep
                        ? Colors.red.withOpacity(0.8)
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getLivenessInstruction(),
                    textAlign: TextAlign.center,
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

          if (!isSelfieStep)
            Positioned(
              bottom: 40,
              width: size.width,
              child: _isPreviewing
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _retakePhoto,
                              child: const Text(
                                'Chụp lại',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPink,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isCapturing ? null : _confirmPhoto,
                              child: _isCapturing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Tiếp tục',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: GestureDetector(
                        onTap: _takePhoto,
                        child: _isCapturing
                            ? const CircularProgressIndicator(
                                color: AppColors.primaryPink,
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryPink,
                                    width: 4,
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

class CameraOverlayPainter extends CustomPainter {
  final bool isSelfie;
  CameraOverlayPainter({required this.isSelfie});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    Path cutoutPath = Path();

    if (isSelfie) {
      final double width = size.width * 0.7;
      final double height = width * 1.3;
      cutoutPath.addOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: width,
          height: height,
        ),
      );
    } else {
      final double width = size.width * 0.85;
      final double height = width * 0.63;
      cutoutPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: width,
            height: height,
          ),
          const Radius.circular(16),
        ),
      );
    }

    final backgroundPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(screenRect),
      cutoutPath,
    );
    canvas.drawPath(backgroundPath, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(cutoutPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

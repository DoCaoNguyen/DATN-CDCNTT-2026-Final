import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/custom_http_client.dart';
import '../../../../core/constants/api_config.dart';
import '../../auth/kyc/widgets/camera_overlay_painter.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import 'bank_transfer_success_screen.dart';
import '../widgets/transaction_details_card.dart';
import '../widgets/payment_source_card.dart';

class BankTransferConfirmScreen extends StatefulWidget {
  final String token;
  final String bankName;
  final String bankCode;
  final String accountNumber;
  final String amount;
  final String note;
  final String senderName;
  final String? cardHolderName;

  const BankTransferConfirmScreen({
    Key? key,
    required this.token,
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
    required this.amount,
    required this.note,
    required this.senderName,
    this.cardHolderName,
  }) : super(key: key);

  @override
  State<BankTransferConfirmScreen> createState() =>
      _BankTransferConfirmScreenState();
}

class _BankTransferConfirmScreenState extends State<BankTransferConfirmScreen> {
  final _client = CustomHttpClient();
  final String _refCode =
      "${Random().nextInt(900000) + 100000}${Random().nextInt(900000) + 100000}";
  bool _isLoading = false;
  String _mioBalance = "0đ";

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
  void initState() {
    super.initState();
    _fetchMioBalance();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _fetchMioBalance() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getWalletBalance));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawBalance =
            data['data']?['available_balance']?.toString() ?? "0";
        if (mounted) {
          setState(() {
            _mioBalance = _formatAmount(rawBalance);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching Mio balance: $e");
    }
  }

  String _formatAmount(String value) {
    final number = int.tryParse(value);
    if (number == null) return "0đ";
    return "${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }

  String getNickname(String name) {
    if (name.isEmpty) return 'ThoongCT';
    final parts = name.trim().split(' ');
    final last = parts.last;
    if (last.isEmpty) return 'ThoongCT';
    String cap = last[0].toUpperCase() + last.substring(1).toLowerCase();
    return '${cap}CT';
  }

  int get _parsedAmount {
    return int.tryParse(widget.amount) ?? 0;
  }

  void _handleConfirmClick() {
    if (_parsedAmount < 30000000) {
      // PIN verification
      _showPinBottomSheet();
    } else {
      // Face Verification flow
      _initFaceCamera();
    }
  }

  void _showPinBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          return await _executeTransactionWithPIN(pin);
        },
      ),
    );
  }

  // --- CAMERA AND LIVENESS DETECTION ---
  Future<void> _initFaceCamera() async {
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

              // 1. Capture the photo first
              await _cameraController?.stopImageStream();
              final photo = await _cameraController!.takePicture();

              // 2. Remove preview from widget tree
              if (mounted) {
                setState(() {
                  _isScanningFace = false;
                  _isCameraInitialized = false;
                });
              }

              // 3. Dispose camera safely
              await _cameraController?.dispose();
              _cameraController = null;

              _executeTransactionWithFace(File(photo.path));
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

  Future<String?> _executeTransactionWithPIN(String pin) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.bankTransfer),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': widget.amount,
          'pin': pin,
          'bank_code': widget.bankCode,
          'bank_name': widget.bankName,
          'account_number': widget.accountNumber,
          'external_reference': _refCode,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return null;
        Navigator.pop(context); // Close PIN Sheet

        final now = DateTime.now();
        final formattedTime =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BankTransferSuccessScreen(
              token: widget.token,
              bankName: widget.bankName,
              bankCode: widget.bankCode,
              accountNumber: widget.accountNumber,
              amount: widget.amount,
              note: widget.note,
              referenceCode: _refCode,
              paymentTime: formattedTime,
              cardHolderName: widget.cardHolderName,
            ),
          ),
        );
        return null;
      } else {
        final data = jsonDecode(response.body);
        final String errorMessage =
            data['error'] ?? 'Giao dịch thất bại. Vui lòng thử lại.';

        if (errorMessage.contains('Mã PIN') || errorMessage.contains('khóa')) {
          return errorMessage;
        } else {
          if (!mounted) return null;
          Navigator.pop(context); // Close PIN Sheet
          _showBeautifulErrorDialog(errorMessage);
          return null;
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar("Không thể kết nối đến máy chủ.");
      }
      return null;
    }
  }

  Future<void> _executeTransactionWithFace(File selfieFile) async {
    setState(() => _isLoading = true);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.bankTransfer),
      );

      // Auto token will be added by CustomHttpClient interceptor if we use it, but for MultipartRequest we should just pass it to _client.send
      final prefs = await SharedPreferences.getInstance();
      final String? authToken = prefs.getString('auth_token');
      if (authToken != null && authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.headers['ngrok-skip-browser-warning'] = 'true';

      request.fields['amount'] = widget.amount;
      request.fields['bank_code'] = widget.bankCode;
      request.fields['bank_name'] = widget.bankName;
      request.fields['account_number'] = widget.accountNumber;
      request.fields['external_reference'] = _refCode;

      request.files.add(
        await http.MultipartFile.fromPath('face_image', selfieFile.path),
      );

      var responseStream = await _client.send(request);
      var response = await http.Response.fromStream(responseStream);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final now = DateTime.now();
        final formattedTime =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BankTransferSuccessScreen(
              token: widget.token,
              bankName: widget.bankName,
              bankCode: widget.bankCode,
              accountNumber: widget.accountNumber,
              amount: widget.amount,
              note: widget.note,
              referenceCode: _refCode,
              paymentTime: formattedTime,
              cardHolderName: widget.cardHolderName,
            ),
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        _showBeautifulErrorDialog(
          data['error'] ?? "Xác thực khuôn mặt thất bại.",
        );
      }
    } catch (e) {
      _showErrorSnackBar("Lỗi kết nối máy chủ khi xác thực khuôn mặt.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBeautifulErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Giao dịch không thành công',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Đã hiểu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
                    "XÁC THỰC KHUÔN MẶT GIAO DỊCH",
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
          'Thanh toán an toàn',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : Column(
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
                          child: Column(
                            children: [
                              TransactionDetailsCard(
                                bankCode: widget.bankCode,
                                cardHolderName: widget.cardHolderName,
                                bankName: widget.bankName,
                                accountNumber: widget.accountNumber,
                                amountFormatted: _formatAmount(widget.amount),
                                note: widget.note,
                                nickname: getNickname(
                                  widget.cardHolderName ?? 'PHAN VAN THONG',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Text(
                                          'Trả ngay',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.visibility_rounded,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.pink,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.pink.shade50.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.pink,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Text(
                                              'mio',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Ví Mio',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  _mioBalance,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.radio_button_checked_rounded,
                                            color: Colors.pink,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng tiền',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formatAmount(widget.amount),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _handleConfirmClick,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Xác nhận',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

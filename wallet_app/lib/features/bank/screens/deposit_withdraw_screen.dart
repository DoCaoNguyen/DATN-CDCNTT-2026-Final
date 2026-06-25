import '../services/bank_service.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/custom_http_client.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import '../../auth/kyc/widgets/camera_overlay_painter.dart';
import 'deposit_withdraw_success_screen.dart';
import 'bank_link_screen.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../widgets/deposit_withdraw_input.dart';
import '../widgets/deposit_withdraw_confirm.dart';

class DepositWithdrawScreen extends StatefulWidget {
  final String token;
  final int initialTab;
  final String? initialAmount;
  const DepositWithdrawScreen({
    Key? key,
    required this.token,
    this.initialTab = 0,
    this.initialAmount,
  }) : super(key: key);

  @override
  State<DepositWithdrawScreen> createState() => _DepositWithdrawScreenState();
}

class _DepositWithdrawScreenState extends State<DepositWithdrawScreen> {
  final BankService _bankService = BankService();
  final _client = CustomHttpClient();
  late int _activeTab; // 0 = Nạp tiền, 1 = Rút tiền
  bool _isLoading = false;
  bool _isConfirming = false; // "Thanh toán an toàn" step
  List<dynamic> _linkedBanks = [];
  Map<String, dynamic>? _selectedBank;
  String? _currentTxRefCode;

  final TextEditingController _amountController = TextEditingController();
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
    _activeTab = widget.initialTab;
    if (widget.initialAmount != null && widget.initialAmount!.isNotEmpty) {
      _amountController.text = _formatAmountValue(widget.initialAmount!);
    }
    _fetchLinkedBanks();
    _fetchMioBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _fetchMioBalance() async {
    final balance = await _bankService.fetchMioBalance();
    if (balance != null && mounted) {
      setState(() {
        _mioBalance = _formatAmountValue(balance);
      });
    }
  }

  Future<void> _fetchLinkedBanks() async {
    setState(() => _isLoading = true);
    final banks = await _bankService.fetchLinkedBanks();
    if (mounted) {
      setState(() {
        if (banks != null) {
          _linkedBanks = banks;
          if (_linkedBanks.isNotEmpty) {
            _selectedBank = _linkedBanks.first;
          }
        }
        _isLoading = false;
      });
    }
  }

  String _formatAmountValue(String value) {
    final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (number == null) return "0đ";
    return "${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }

  void _onAmountChanged(String val) {
    // Keep numbers only
    String clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      setState(() {
        _amountController.text = "";
      });
      return;
    }
    final number = int.tryParse(clean);
    if (number != null) {
      String formatted = _formatAmountValue(clean);
      setState(() {
        _amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length - 1),
        );
      });
    }
  }

  void _selectQuickAmount(int amount) {
    setState(() {
      _amountController.text = _formatAmountValue(amount.toString());
    });
  }

  int get _parsedAmount {
    String clean = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
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

  String _generateRefCode() {
    final random = Random();
    String code = "";
    for (int i = 0; i < 12; i++) {
      code += random.nextInt(10).toString();
    }
    return code;
  }

  // --- TRANSCTION API CALLS ---
  Future<String?> _executeTransactionWithPIN(String pin) async {
    setState(() => _isLoading = true);
    try {
      final isDeposit = _activeTab == 0;
      final url = isDeposit ? ApiConfig.deposit : ApiConfig.withdraw;
      final amountVal = _parsedAmount;

      final body = {
        'amount': amountVal.toString(),
        'pin': pin,
        'external_reference': _currentTxRefCode,
      };

      if (!isDeposit && _selectedBank != null) {
        body['linked_bank_id'] = _selectedBank!['id'];
      }

      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final refId =
            data['data']?['id'] ?? _currentTxRefCode ?? '132554346688';
        final now = DateTime.now();
        final formattedTime =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

        if (!mounted) return null;
        Navigator.pop(context); // Close PIN bottom sheet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DepositWithdrawSuccessScreen(
              token: widget.token,
              amount: amountVal.toString(),
              isDeposit: isDeposit,
              referenceCode: refId,
              paymentTime: formattedTime,
            ),
          ),
        ).then((_) {
          _amountController.clear();
          setState(() {
            _isConfirming = false;
          });
          _fetchMioBalance();
        });
        return null;
      } else {
        final data = jsonDecode(response.body);
        final String errorMessage =
            data['error'] ?? "Giao dịch không thành công.";

        if (errorMessage.contains('Mã PIN') ||
            errorMessage.contains('khóa') ||
            errorMessage.contains('PIN')) {
          return errorMessage;
        } else {
          if (!mounted) return null;
          Navigator.pop(context); // Close PIN bottom sheet
          _showErrorSnackBar(errorMessage);
          return null;
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar("Lỗi kết nối máy chủ.");
      }
      return null;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _executeTransactionWithFace(File selfieFile) async {
    setState(() => _isLoading = true);

    final isDeposit = _activeTab == 0;
    final amountVal = _parsedAmount;

    final result = await _bankService.executeTransactionWithFace(
      token: widget.token,
      selfieFile: selfieFile,
      isDeposit: isDeposit,
      amount: amountVal,
      externalReference: _currentTxRefCode ?? '',
      linkedBankId: (!isDeposit && _selectedBank != null)
          ? _selectedBank!['id']
          : null,
    );

    if (mounted) setState(() => _isLoading = false);

    if (result['success'] == true) {
      final refId =
          result['data']?['id'] ?? _currentTxRefCode ?? '132554346688';
      final now = DateTime.now();
      final formattedTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepositWithdrawSuccessScreen(
            token: widget.token,
            amount: amountVal.toString(),
            isDeposit: isDeposit,
            referenceCode: refId,
            paymentTime: formattedTime,
          ),
        ),
      ).then((_) {
        _amountController.clear();
        setState(() {
          _isConfirming = false;
        });
        _fetchMioBalance();
      });
    } else {
      _showErrorSnackBar(result['error'] ?? "Xác thực khuôn mặt thất bại.");
    }
  }

  void _showErrorSnackBar(String message) {
    SnackbarUtils.showError(context, message);
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

  void _handleConfirmClick() {
    final amountVal = _parsedAmount;
    if (amountVal <= 0) {
      _showErrorSnackBar("Vui lòng nhập số tiền giao dịch");
      return;
    }

    // Generate unique 12-digit transaction reference on the app side
    _currentTxRefCode = _generateRefCode();

    if (amountVal < 50000000) {
      // PIN verification
      _showPinBottomSheet();
    } else {
      // Face Verification flow
      _initFaceCamera();
    }
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

  void _showBankSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn tài khoản liên kết',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_linkedBanks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text('Chưa có ngân hàng liên kết'),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _linkedBanks.length,
                        itemBuilder: (context, index) {
                          final bank = _linkedBanks[index];
                          final isSelected =
                              _selectedBank != null &&
                              _selectedBank!['id'] == bank['id'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Colors.pink
                                    : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? Colors.pink.shade50.withValues(alpha: 0.1)
                                  : Colors.white,
                            ),
                            child: ListTile(
                              leading: _buildBankIcon(bank, 36),
                              title: Text(
                                bank['bank_name'] ?? 'Ngân hàng',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(bank['card_number'] ?? ''),
                              trailing: Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: isSelected ? Colors.pink : Colors.grey,
                              ),
                              onTap: () {
                                setBottomSheetState(() {
                                  _selectedBank = bank;
                                });
                                setState(() {
                                  _selectedBank = bank;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- UI WIDGET BUILDERS ---

  Widget _buildHomeOrConfirmScreen() {
    if (_isConfirming) {
      return DepositWithdrawConfirmLayout(
        activeTab: _activeTab,
        parsedAmount: _parsedAmount,
        selectedBank: _selectedBank,
        token: widget.token,
        onConfirmTransaction: _handleConfirmClick,
        onCancel: () => setState(() => _isConfirming = false),
        onSelectBank: () => _showBankSelectionBottomSheet(),
      );
    }
    return DepositWithdrawInputLayout(
      activeTab: _activeTab,
      onTabChanged: (val) => setState(() => _activeTab = val),
      selectedBank: _selectedBank,
      mioBalance: _mioBalance,
      amountController: _amountController,
      onAmountChanged: _onAmountChanged,
      onQuickAmountSelected: _selectQuickAmount,
      onConfirmPressed: () => setState(() => _isConfirming = true),
      parsedAmount: _parsedAmount,
    );
  }

  // Helper xây dựng icon ngân hàng (dùng trong bottom sheet chọn ngân hàng)
  Widget _buildBankIcon(Map<String, dynamic>? bank, double size) {
    final logoUrl = bank?['logo_url'];
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          logoUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.account_balance, size: size, color: Colors.grey),
        ),
      );
    }
    return Icon(Icons.account_balance, size: size, color: Colors.grey);
  }

  // Dòng hiển thị thông tin giao dịch (label: value)
  Widget _buildDetailRow(String title, String value, {bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: isBlue ? Colors.blue.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
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
                      debugPrint("Error disposing camera on back: $e");
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
        backgroundColor: _isConfirming ? const Color(0xFFFFE4EE) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () {
            if (_isConfirming) {
              setState(() => _isConfirming = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _isConfirming ? 'Thanh toán an toàn' : 'Nạp/Rút',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _buildHomeOrConfirmScreen(),
    );
  }
}

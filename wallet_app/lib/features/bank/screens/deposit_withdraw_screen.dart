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
import '../../transfer/screens/transfer_confirm_screen.dart';
import '../../auth/kyc/widgets/camera_overlay_painter.dart';
import 'deposit_withdraw_success_screen.dart';
import 'bank_link_screen.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';

class DepositWithdrawScreen extends StatefulWidget {
  final String token;
  final int initialTab;
  final String? initialAmount;
  const DepositWithdrawScreen({Key? key, required this.token, this.initialTab = 0, this.initialAmount}) : super(key: key);

  @override
  State<DepositWithdrawScreen> createState() => _DepositWithdrawScreenState();
}

class _DepositWithdrawScreenState extends State<DepositWithdrawScreen> {
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
  String? _amountError;

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
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getWalletBalance),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawBalance = data['data']?['available_balance']?.toString() ?? "0";
        if (mounted) {
          setState(() {
            _mioBalance = _formatAmountValue(rawBalance);
            _validateAmount(_amountController.text);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching Mio balance: $e");
    }
  }

  Future<void> _fetchLinkedBanks() async {
    setState(() => _isLoading = true);
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getLinkedBanks),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _linkedBanks = data['data'] ?? [];
        if (_linkedBanks.isNotEmpty) {
          _selectedBank = _linkedBanks.first;
        }
      }
    } catch (e) {
      debugPrint("Error fetching linked banks: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatAmountValue(String value) {
    final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (number == null) return "0đ";
    return "${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }

  void _validateAmount(String val) {
    String clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      setState(() => _amountError = null);
      return;
    }
    final parsed = int.tryParse(clean) ?? 0;
    final isDeposit = _activeTab == 0;
    setState(() {
       if (parsed < 10000) {
          _amountError = 'Số tiền ${isDeposit ? 'nạp' : 'rút'} tối thiểu là 10.000đ';
       } else if (parsed > 50000000) {
          _amountError = 'Số tiền ${isDeposit ? 'nạp' : 'rút'} tối đa là 50.000.000đ/ngày';
       } else {
          if (!isDeposit) {
             int currentBalance = int.tryParse(_mioBalance.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
             if (parsed > currentBalance) {
                _amountError = 'Số dư không đủ để thực hiện giao dịch này';
             } else {
                _amountError = null;
             }
          } else {
             _amountError = null;
          }
       }
    });
  }

  void _onAmountChanged(String val) {
    // Keep numbers only
    String clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      _amountController.text = "";
      setState(() => _amountError = null);
      return;
    }
    if (clean.length > 8) {
      clean = clean.substring(0, 8); // Giới hạn độ dài số lượng chữ số
    }
    final number = int.tryParse(clean);
    if (number != null) {
      String formatted = _formatAmountValue(clean);
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length - 1),
      );
      _validateAmount(clean);
    }
  }

  void _selectQuickAmount(int amount) {
    setState(() {
      _amountController.text = _formatAmountValue(amount.toString());
      _validateAmount(amount.toString());
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
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
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
          format: Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888,
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
          double faceRatio = face.boundingBox.width / (image.width < image.height ? image.width : image.height);

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
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final refId = data['data']?['id'] ?? _currentTxRefCode ?? '132554346688';
        final now = DateTime.now();
        final formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

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
        final String errorMessage = data['message'] ?? data['error'] ?? "Giao dịch không thành công.";

        if (errorMessage.contains('Mã PIN') || errorMessage.contains('khóa') || errorMessage.contains('PIN')) {
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
    try {
      final isDeposit = _activeTab == 0;
      final url = isDeposit ? ApiConfig.deposit : ApiConfig.withdraw;
      final amountVal = _parsedAmount;

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.fields['amount'] = amountVal.toString();
      request.fields['external_reference'] = _currentTxRefCode ?? '';
      
      if (!isDeposit && _selectedBank != null) {
        request.fields['linked_bank_id'] = _selectedBank!['id'];
      }
      
      request.files.add(
        await http.MultipartFile.fromPath('face_image', selfieFile.path),
      );

      var responseStream = await request.send();
      var response = await http.Response.fromStream(responseStream);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final refId = data['data']?['id'] ?? _currentTxRefCode ?? '132554346688';
        final now = DateTime.now();
        final formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

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
        final data = jsonDecode(response.body);
        final String errorMessage = data['message'] ?? data['error'] ?? "Xác thực khuôn mặt thất bại.";
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      _showErrorSnackBar("Lỗi kết nối máy chủ khi xác thực khuôn mặt.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    final isDeposit = _activeTab == 0;
    
    if (amountVal < 10000) {
      _showErrorSnackBar("Số tiền ${isDeposit ? 'nạp' : 'rút'} tối thiểu là 10.000đ");
      return;
    }
    
    if (amountVal > 50000000) {
      _showErrorSnackBar("Số tiền ${isDeposit ? 'nạp' : 'rút'} vượt quá hạn mức 50.000.000đ/ngày");
      return;
    }

    if (!isDeposit) {
      int currentBalance = int.tryParse(_mioBalance.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (amountVal > currentBalance) {
        _showErrorSnackBar("Số dư không đủ để thực hiện giao dịch này");
        return;
      }
    }

    // Generate unique 12-digit transaction reference on the app side
    _currentTxRefCode = _generateRefCode();

    if (amountVal < 30000000) {
      // PIN verification
      _showPinBottomSheet();
    } else {
      // Face Verification flow
      _initFaceCamera();
    }
  }

  String _getLivenessInstruction() {
    switch (_livenessTask) {
      case 0: return "Vui lòng đưa điện thoại RA XA";
      case 1: return "Vui lòng đưa điện thoại LẠI GẦN";
      case 2: return "Vui lòng QUAY ĐẦU SANG TRÁI";
      case 3: return "Vui lòng QUAY ĐẦU SANG PHẢI";
      case 4: return "Vui lòng CHỚP MẮT";
      case 5: return "Đang xác nhận khuôn mặt...";
      default: return "Đang phân tích...";
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                          final isSelected = _selectedBank != null && _selectedBank!['id'] == bank['id'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.pink : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected ? Colors.pink.shade50.withOpacity(0.1) : Colors.white,
                            ),
                            child: ListTile(
                              leading: _buildBankIcon(bank, 36),
                              title: Text(
                                bank['bank_name'] ?? 'Ngân hàng',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(bank['card_number'] ?? ''),
                              trailing: Icon(
                                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
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
          }
        );
      },
    );
  }

  // --- UI WIDGET BUILDERS ---
  Widget _buildBankIcon(Map<String, dynamic>? bank, double size) {
    if (bank != null && bank['bank_code'] != null && bank['bank_code'].toString().isNotEmpty) {
      String bCode = bank['bank_code'].toString();
      if (bCode.toUpperCase() == 'AGR' || bCode.toUpperCase() == 'AGRIBANK') {
        bCode = 'VBA';
      }
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.2),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Image.network(
          'https://api.vietqr.io/img/$bCode.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.account_balance_rounded, color: Colors.pink, size: size * 0.7);
          },
        ),
      );
    }
    return Icon(Icons.account_balance_rounded, color: Colors.pink, size: size);
  }

  Widget _buildHomeOrConfirmScreen() {
    if (_isConfirming) {
      return _buildConfirmLayout();
    }
    return _buildInputLayout();
  }

  Widget _buildInputLayout() {
    final isDeposit = _activeTab == 0;
    final bankName = _selectedBank != null ? _selectedBank!['bank_name'] : "Không xác định";
    final bankDetails = _selectedBank != null ? "${_selectedBank!['bank_name']} - ${_selectedBank!['card_number']}" : "Chưa liên kết ngân hàng";

    return Column(
      children: [
        // TabBar
        Container(
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeTab == 0 ? Colors.pink : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.input_rounded, color: _activeTab == 0 ? Colors.pink : Colors.grey, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Nạp tiền',
                          style: TextStyle(
                            color: _activeTab == 0 ? Colors.pink : Colors.grey,
                            fontWeight: _activeTab == 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeTab == 1 ? Colors.pink : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.output_rounded, color: _activeTab == 1 ? Colors.pink : Colors.grey, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Rút tiền',
                          style: TextStyle(
                            color: _activeTab == 1 ? Colors.pink : Colors.grey,
                            fontWeight: _activeTab == 1 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source / Target bank card
                Text(
                  isDeposit ? 'Nạp tiền vào' : 'Rút tiền từ',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.pink.shade100, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                              child: const Text('mio', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500, height: 1)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ví Mio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(_mioBalance, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isDeposit) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.monetization_on_rounded, color: Colors.orange, size: 28),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Túi Thần Tài', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text('Đến 4%/năm', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Amount input field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _amountError != null ? Colors.red : Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDeposit ? 'Số tiền cần nạp' : 'Số tiền cần rút',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      TextField(
                        controller: _amountController,
                        onChanged: _onAmountChanged,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _amountError != null ? Colors.red : Colors.black),
                        decoration: const InputDecoration(
                          hintText: '0đ',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_amountError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      _amountError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),

                // Quick selector buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => _selectQuickAmount(50000), child: const Text('50.000'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => _selectQuickAmount(100000), child: const Text('100.000'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => _selectQuickAmount(200000), child: const Text('200.000'))),
                  ],
                ),
                
                if (!isDeposit) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Chuyển tiền ngân hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('Miễn phí chuyển tiền với Túi và Quỹ', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Thử ngay', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.w600)),
                        )
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                
                // Security warning
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Colors.pink, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'An toàn tài sản & Bảo mật thông tin của bạn là ưu tiên hàng đầu của Mio.',
                              style: TextStyle(color: Colors.pink.shade900, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 4),
                            const Text('Tìm hiểu thêm >', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600)),
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

        // Action Button
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_amountError == null && _parsedAmount > 0) ? () {
                  setState(() => _isConfirming = true);
                } : null,
                child: Text(
                  isDeposit ? 'Nạp tiền' : 'Rút tiền',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmLayout() {
    final isDeposit = _activeTab == 0;
    final bankName = _selectedBank != null ? _selectedBank!['bank_name'] : "MBBank";
    final cardNo = _selectedBank != null ? _selectedBank!['card_number'] : "";
    final bankNameDetails = _selectedBank != null ? "$bankName - $cardNo" : "Chưa chọn ngân hàng";
    final formattedVal = _amountController.text;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFE4EE), Color(0xFFF5F5F9)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payment_rounded, color: Colors.pink.shade400, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isDeposit ? 'Nạp tiền vào ví Mio' : 'Rút tiền về ngân hàng',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(isDeposit ? 'Nguồn tiền' : 'Rút về NH liên kết', bankNameDetails, isBlue: true),
                            _buildDetailRow('Số tiền', formattedVal, isBlue: true),
                            if (!isDeposit) _buildDetailRow('Phí giao dịch', 'Miễn phí'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDeposit ? 'Nạp từ tài khoản/thẻ' : 'Rút về tài khoản/thẻ',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _showBankSelectionBottomSheet,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.pink, width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.pink.shade50.withOpacity(0.3)
                                ),
                                child: Row(
                                  children: [
                                    _buildBankIcon(_selectedBank, 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(bankNameDetails, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                                          const Text('Miễn phí', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.pink),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BankLinkScreen(token: widget.token),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.add_rounded, color: Colors.pink.shade400, size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(child: Text('Ngân hàng liên kết', style: TextStyle(fontSize: 14, color: Colors.black87))),
                                  const Text('+37', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
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
            border: Border(top: BorderSide(color: Colors.grey.shade200))
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng tiền', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text(formattedVal, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _handleConfirmClick, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Xác nhận', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

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
              color: isBlue ? Colors.blue.shade700 : Colors.black87
            )
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
            CustomPaint(size: size, painter: CameraOverlayPainter(isSelfie: true)),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
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
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getLivenessInstruction(),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _buildHomeOrConfirmScreen(),
    );
  }
}

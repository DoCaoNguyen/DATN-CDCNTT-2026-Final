import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../../core/services/custom_http_client.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../transfer/screens/transfer_amount_screen.dart';
import '../../transfer/screens/transfer_confirm_screen.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';



class QrMainScreen extends StatefulWidget {
  final String token;
  final int initialIndex;

  const QrMainScreen({Key? key, required this.token, this.initialIndex = 0}) : super(key: key);

  @override
  State<QrMainScreen> createState() => _QrMainScreenState();
}

class _QrMainScreenState extends State<QrMainScreen> {
  final _client = CustomHttpClient();
  int _currentIndex = 0; // 0: Tab Quét mã QR, 1: Tab QR Nhận tiền

  bool _isLoading = true;
  String _fullName = "ĐANG TẢI...";
  String _phone = "ĐANG TẢI...";

  // Trạng thái QR tuỳ chỉnh số tiền
  String? _customQrContent;
  int? _customAmount;
  String _customDescription = '';
  bool _isGeneratingQR = false;

  // Scanner Controller điều khiển bật/tắt flash, quét mã
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScannerActive = true;
  
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fetchMyProfile();
    _listenToLoyaltyPoints();
  }

  void _listenToLoyaltyPoints() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'LOYALTY_POINTS') {
        final earnedPoints = message.data['earned_points'] ?? '0';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bạn vừa tích lũy thành công +$earnedPoints điểm!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.primaryPink,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              duration: const Duration(seconds: 4),
              elevation: 6,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  // Gọi API lấy thông tin Profile (Họ tên, SĐT) để vẽ mã QR
  Future<void> _fetchMyProfile() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getMyProfile),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _fullName =
              data['full_name']?.toString().toUpperCase() ??
              "CHƯA CẬP NHẬT TÊN";
          _phone = data['phone'] ?? "CHƯA CẬP NHẬT SĐT";
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onDetectQR(BarcodeCapture capture) {
    if (!_isScannerActive) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      _isScannerActive = false;

      // --- Loại 1: QR chuyển tiền thường (JSON) ---
      if (raw.trimLeft().startsWith('{')) {
        try {
          final qrData = jsonDecode(raw);
          if (qrData['action'] == 'TRANSFER') {
            if (qrData['phone'] == _phone) {
              _showErrorDialog('Bạn không thể quét mã QR của chính mình.');
              return;
            }
            _scannerController.stop();

            final String? qrAmt = qrData['amount']?.toString();
            final String? qrNote = qrData['description']?.toString() ?? qrData['note']?.toString();

            // Nếu QR có amount thì lock, không cho chỉnh sửa
            final bool shouldLock = qrAmt != null && qrAmt.isNotEmpty;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TransferAmountScreen(
                  token: widget.token,
                  receiverPhone: qrData['phone'],
                  receiverName: qrData['name'],
                  amount: qrAmt,
                  note: qrNote,
                  isFixed: shouldLock,
                ),
              ),
            );
          } else {
            _showErrorDialog('Mã QR không hợp lệ.');
          }
        } catch (_) {
          _showErrorDialog('Mã QR không thuộc hệ thống Ví của chúng ta.');
        }
        return;
      }

      // --- Loại 2: QR thanh toán có số tiền (mio://) ---
      final cleaned = raw.trim();
      if (cleaned.toLowerCase().startsWith('mio://pay')) {
        try {
          final uri = Uri.tryParse(cleaned);
          if (uri == null) {
            _showErrorDialog('Mã QR thanh toán không hợp lệ.');
            return;
          }
          final token = uri.queryParameters['token'];
          final amount = int.tryParse(uri.queryParameters['amount'] ?? '');
          final desc = uri.queryParameters['description'] ?? '';
          final phone = uri.queryParameters['phone'];
          final name = uri.queryParameters['name'];

          if (token == null || token.isEmpty || amount == null) {
            _showErrorDialog('Mã QR thanh toán không hợp lệ.');
            return;
          }

          // Nếu có thông tin người nhận (SĐT và Tên) thì điều hướng sang trang chuyển tiền thông thường
          if (phone != null && phone.isNotEmpty && name != null && name.isNotEmpty) {
            if (phone == _phone) {
              _showErrorDialog('Bạn không thể quét mã QR của chính mình.');
              return;
            }
            _scannerController.stop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TransferAmountScreen(
                  token: widget.token,
                  receiverPhone: phone,
                  receiverName: name,
                  amount: amount.toString(),
                  note: desc,
                  isFixed: true,
                ),
              ),
            );
            return;
          }

          // Ngược lại (QR thanh toán hóa đơn / merchant) thì mở Bottom Sheet xác nhận thanh toán trực tiếp
          _scannerController.stop();
          _fetchPaymentPreviewAndShowConfirm(token, amount, desc);
        } catch (e) {
          debugPrint('Lỗi quét mã QR thanh toán: $e');
          _showErrorDialog('Không đọc được mã QR thanh toán.');
        }
        return;
      }

      // --- Không xác định được loại QR ---
      _showErrorDialog('Mã QR không thuộc hệ thống Ví của chúng ta.');
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Future.delayed(
                const Duration(milliseconds: 800),
                () {
                  _isScannerActive = true;
                  _scannerController.start();
                },
              );
            },
            child: const Text('Quét lại', style: TextStyle(color: AppColors.primaryPink)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LẤY THÔNG TIN ĐƠN HÀNG TRƯỚC KHI THANH TOÁN (PREVIEW)
  // ============================================================
  Future<void> _fetchPaymentPreviewAndShowConfirm(String token, int fallbackAmount, String fallbackDesc) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryPink)),
      );

      final response = await _client.get(
        Uri.parse('${ApiConfig.paymentPreview}?qr_token=$token'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        
        if (data['is_expired'] == true || data['can_pay'] == false) {
           _showErrorDialog('Mã QR thanh toán đã hết hạn hoặc đã được xử lý.');
           return;
        }

        final amount = int.tryParse(data['amount'].toString()) ?? fallbackAmount;
        final description = data['description'] ?? fallbackDesc;
        final merchantName = data['merchant_name'] ?? 'Cửa hàng / Đối tác';
        
        _showPaymentConfirmSheet(token, amount, description, merchantName);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Không lấy được thông tin đơn hàng.';
        _showErrorDialog(error);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Đóng loading
      _showErrorDialog('Lỗi kết nối khi lấy thông tin đơn hàng.');
    }
  }

  // ============================================================
  // BOTTOM SHEET XÁC NHẬN THANH TOÁN QR
  // ============================================================
  void _showPaymentConfirmSheet(String qrToken, int amount, String description, String merchantName) {
    String fmtAmt(int v) => v
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    bool isPaying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryPink, size: 36),
              ),
              const SizedBox(height: 16),

              const Text(
                'Xác nhận thanh toán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn sắp thanh toán số tiền sau:',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // Amount card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: Column(
                  children: [
                    Text(
                      merchantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${fmtAmt(amount)}đ',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPink,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isPaying ? null : () {
                        Navigator.pop(sheetCtx);
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          () {
                            _isScannerActive = true;
                            _scannerController.start();
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Hủy', style: TextStyle(color: Colors.black54, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isPaying ? null : () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (pinSheetCtx) => PinConfirmBottomSheet(
                            onPinEntered: (pin) async {
                              try {
                                final verifyResp = await _client.post(
                                  Uri.parse(ApiConfig.verifyPin),
                                  headers: {
                                    'Content-Type': 'application/json',
                                  },
                                  body: jsonEncode({'pin': pin}),
                                );
                                if (verifyResp.statusCode == 200) {
                                  if (!mounted) return null;
                                  Navigator.pop(pinSheetCtx); // Đóng Bottom Sheet nhập PIN
                                  setSheetState(() => isPaying = true);
                                  await _processQrPayment(sheetCtx, qrToken, amount);
                                  return null;
                                } else {
                                  final data = jsonDecode(verifyResp.body);
                                  return data['error'] ?? "Mã PIN không chính xác";
                                }
                              } catch (e) {
                                return "Lỗi kết nối máy chủ";
                              }
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isPaying
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Thanh toán ngay',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GỌI API THANH TOÁN QR
  // ============================================================
  Future<void> _processQrPayment(BuildContext sheetCtx, String qrToken, int amount) async {
    // Tạo idempotency key ngẫu nhiên để tránh thanh toán 2 lần
    final idempotencyKey = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.processPayment),
        headers: {
          'Content-Type': 'application/json',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode({'qr_token': qrToken}),
      );

      if (!mounted) return;
      Navigator.pop(sheetCtx); // Đóng bottom sheet

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        _showSuccessDialog(amount, data['balance_remaining']);
      } else {
        final errMsg = jsonDecode(response.body)['error'] ?? 'Thanh toán thất bại';
        _showErrorDialog(errMsg);
      }
    } catch (e) {
      if (mounted) Navigator.pop(sheetCtx);
      _showErrorDialog('Lỗi kết nối. Vui lòng thử lại.');
    }
  }

  void _showSuccessDialog(int amount, dynamic remaining) {
    String fmt(num v) => v
        .toInt()
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thanh toán thành công!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('${fmt(amount)}đ',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
              const SizedBox(height: 6),
              Text('Số dư còn lại: ${fmt(num.tryParse(remaining.toString()) ?? 0)}đ',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _isScannerActive = true;
                    _scannerController.start();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Xong',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // IndexedStack giúp giữ nguyên trạng thái Camera khi bạn nhảy qua Tab Nhận tiền
      body: IndexedStack(
        index: _currentIndex,
        children: [_buildScannerTab(), _buildReceiveQrTab()],
      ),

      // Bottom Navigation cho QR
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
          ),
          child: Row(
            children: [
              _buildBottomTabItem(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Quét mã QR',
                index: 0,
              ),
              _buildBottomTabItem(
                icon: Icons.qr_code_2_rounded,
                title: 'QR Nhận tiền',
                index: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTabItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.pink : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.pink : Colors.grey,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: GIAO DIỆN QUÉT MÃ QR (MOBILE SCANNER)
  // ==========================================
  Widget _buildScannerTab() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White icons for dark camera screen
      ),
      child: Stack(
        children: [
        MobileScanner(controller: _scannerController, onDetect: _onDetectQR),

        // Tạo lớp mờ đen đục lỗ ở giữa
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
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
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
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
                        valueListenable:
                            _scannerController,
                        builder: (context, state, child) {
                          return Icon(
                            state.torchState == TorchState.on
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: Colors.white,
                          );
                        },
                      ),
                      onPressed: () => _scannerController.toggleTorch(),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          final picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final BarcodeCapture? capture = await _scannerController.analyzeImage(image.path);
                            if (capture != null && capture.barcodes.isNotEmpty) {
                              _onDetectQR(capture);
                            } else {
                              if (mounted) _showErrorDialog('Không tìm thấy mã QR trong ảnh.');
                            }
                          }
                        } catch (e) {
                          if (mounted) _showErrorDialog('Lỗi khi đọc ảnh.');
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

  // ==========================================
  // TAB 2: GIAO DIỆN QR NHẬN TIỀN
  // ==========================================
  Widget _buildReceiveQrTab() {
    return Container(
      color: const Color(0xFFFFF0F5),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Nhận tiền',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.pink),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Khung trắng chứa mã QR
                          Container(
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'mio',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.pink.shade700,
                                        fontWeight: FontWeight.bold,
                                        height: 1,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'VietQR',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'napas 247',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // QR: Hiển thị QR tuỳ chỉnh (nhận tiền) hoặc QR chuyển tiền mặc định
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    QrImageView(
                                      data: _customQrContent ?? jsonEncode({
                                        "action": "TRANSFER",
                                        "phone": _phone,
                                        "name": _fullName,
                                      }),
                                      version: QrVersions.auto,
                                      size: 220.0,
                                      backgroundColor: Colors.white,
                                    ),
                                    if (_isGeneratingQR)
                                      Container(
                                        width: 220,
                                        height: 220,
                                        color: Colors.white.withOpacity(0.8),
                                        child: const Center(
                                          child: CircularProgressIndicator(color: Colors.pink),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                if (_customAmount != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.pink.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.pink.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${_formatAmount(_customAmount!)}đ',
                                          style: const TextStyle(
                                            color: Colors.pink,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _customAmount = null;
                                            _customQrContent = null;
                                            _customDescription = '';
                                          }),
                                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.pink),
                                        ),
                                      ],
                                    ),
                                  ),

                                GestureDetector(
                                  onTap: _showAmountBottomSheet,
                                  child: Text(
                                    _customAmount == null ? '+ Thêm số tiền' : 'Sửa số tiền',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Thẻ thông tin tài khoản bên dưới
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tên người nhận',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      _fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ngân hàng',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      'Mio',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Số tài khoản',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      _phone,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(height: 1),
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Sao chép thông tin tài khoản nhận tiền của bạn',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        /* Logic Copy SĐT */
                                      },
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        size: 16,
                                        color: Colors.pink,
                                      ),
                                      label: const Text(
                                        'Sao chép',
                                        style: TextStyle(color: Colors.pink),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // FORMAT SỐ TIỀN
  // ============================================
  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  // ============================================
  // BOTTOM SHEET NHẬP SỐ TIỀN
  // ============================================
  void _showAmountBottomSheet() {
    final amountController = TextEditingController(
      text: _customAmount != null ? _formatAmount(_customAmount!) : '',
    );
    final noteController = TextEditingController(text: _customDescription);
    String? sheetAmountError;
    int noteLength = _customDescription.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tuỳ chỉnh số tiền',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          onPressed: () => Navigator.pop(sheetCtx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount field
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Số tiền',
                            labelStyle: TextStyle(
                              color: sheetAmountError != null ? Colors.red : Colors.pink,
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: '0đ',
                            suffix: amountController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      amountController.clear();
                                      setSheetState(() => sheetAmountError = null);
                                    },
                                    child: const Icon(Icons.cancel_rounded, size: 18, color: Colors.grey),
                                  )
                                : null,
                            errorText: sheetAmountError,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.pink, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (val) {
                            final digits = val.replaceAll('.', '');
                            final formatted = digits.isEmpty ? '' : int.tryParse(digits)?.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (m) => '${m[1]}.',
                            ) ?? val;
                            amountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                            final raw = int.tryParse(formatted.replaceAll('.', '')) ?? 0;
                            setSheetState(() {
                              if (formatted.isNotEmpty && raw < 1000) {
                                sheetAmountError = 'Số tiền tối thiểu 1.000đ';
                              } else if (formatted.isNotEmpty && raw > 50000000) {
                                sheetAmountError = 'Số tiền tối đa 50.000.000đ';
                              } else {
                                sheetAmountError = null;
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Note field
                        TextField(
                          controller: noteController,
                          maxLength: 50,
                          decoration: InputDecoration(
                            labelText: 'Lời nhắn-Slogan (${noteLength}/50)',
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            hintText: 'Nhập lời nhắn',
                            hintStyle: const TextStyle(color: Colors.grey),
                            counterText: '',
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.pink, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (val) => setSheetState(() => noteLength = val.length),
                        ),

                        const SizedBox(height: 12),

                        // Quick note chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            'Chuyển tiền cho mình nhé',
                            'Tiền nước',
                            'Tiền cơm trưa',
                          ].map((label) => GestureDetector(
                            onTap: () {
                              noteController.text = label;
                              setSheetState(() => noteLength = label.length);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey.shade50,
                              ),
                              child: Text(label, style: const TextStyle(fontSize: 13)),
                            ),
                          )).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  amountController.clear();
                                  noteController.clear();
                                  setSheetState(() {
                                    sheetAmountError = null;
                                    noteLength = 0;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Xóa tất cả', style: TextStyle(color: Colors.black54)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: sheetAmountError != null || amountController.text.isEmpty
                                    ? null
                                    : () async {
                                        final rawAmount = int.parse(
                                          amountController.text.replaceAll('.', ''),
                                        );
                                        final note = noteController.text;
                                        Navigator.pop(sheetCtx);
                                        await _createRequestMoneyQR(rawAmount, note);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Lưu',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
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

  // ============================================
  // GỌI API TẠO QR NHẬN TIỀN
  // ============================================
  Future<void> _createRequestMoneyQR(int amount, String description) async {
    setState(() => _isGeneratingQR = true);

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.requestMoneyQR),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'amount': amount, 'description': description}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _customQrContent = data['qr_content'];
          _customAmount = amount;
          _customDescription = description;
          _isGeneratingQR = false;
        });
      } else {
        setState(() => _isGeneratingQR = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonDecode(response.body)['error'] ?? 'Tạo QR thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isGeneratingQR = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi kết nối. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

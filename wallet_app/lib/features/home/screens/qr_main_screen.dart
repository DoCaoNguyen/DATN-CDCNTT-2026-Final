import '../widgets/qr_payment_confirm_sheet.dart';
import '../widgets/qr_receive_tab.dart';
import '../widgets/qr_scanner_tab.dart';
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
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import 'package:flutter/services.dart';

class QrMainScreen extends StatefulWidget {
  final String token;
  final int initialIndex;

  const QrMainScreen({Key? key, required this.token, this.initialIndex = 0})
    : super(key: key);

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
    _fcmSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
      final response = await _client.get(Uri.parse(ApiConfig.getMyProfile));

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
            final String? qrNote =
                qrData['description']?.toString() ?? qrData['note']?.toString();

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
          if (phone != null &&
              phone.isNotEmpty &&
              name != null &&
              name.isNotEmpty) {
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
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Future.delayed(
                const Duration(milliseconds: 800),
                () => _isScannerActive = true,
              );
            },
            child: const Text(
              'Quét lại',
              style: TextStyle(color: AppColors.primaryPink),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LẤY THÔNG TIN ĐƠN HÀNG TRƯỚC KHI THANH TOÁN (PREVIEW)
  // ============================================================
  Future<void> _fetchPaymentPreviewAndShowConfirm(
    String token,
    int fallbackAmount,
    String fallbackDesc,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
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

        final amount =
            int.tryParse(data['amount'].toString()) ?? fallbackAmount;
        final description = data['description'] ?? fallbackDesc;
        final merchantName = data['merchant_name'] ?? 'Cửa hàng / Đối tác';

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          builder: (sheetCtx) => QrPaymentConfirmSheet(
            qrToken: token,
            amount: amount,
            description: description,
            merchantName: merchantName,
            onComplete: () => setState(() => _isScannerActive = true),
            onError: _showErrorDialog,
          ),
        );
      } else {
        final error =
            jsonDecode(response.body)['error'] ??
            'Không lấy được thông tin đơn hàng.';
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

  // ============================================================
  // GỌI API THANH TOÁN QR
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // IndexedStack giúp giữ nguyên trạng thái Camera khi bạn nhảy qua Tab Nhận tiền
      body: IndexedStack(
        index: _currentIndex,
        children: [
          QrScannerTab(
            scannerController: _scannerController,
            onDetectQR: _onDetectQR,
            onBack: () => Navigator.pop(context),
            onError: _showErrorDialog,
          ),
          QrReceiveTab(
            isLoading: _isLoading,
            fullName: _fullName,
            phone: _phone,
          ),
        ],
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
}

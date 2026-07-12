import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class DeepLinkPaymentConfirmScreen extends StatefulWidget {
  final String qrToken;

  const DeepLinkPaymentConfirmScreen({super.key, required this.qrToken});

  @override
  State<DeepLinkPaymentConfirmScreen> createState() =>
      _DeepLinkPaymentConfirmScreenState();
}

class _DeepLinkPaymentConfirmScreenState
    extends State<DeepLinkPaymentConfirmScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _orderData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderPreview();
  }

  Future<void> _fetchOrderPreview() async {
    try {
      final client = CustomHttpClient();
      final response = await client.get(
        Uri.parse('${ApiConfig.paymentPreview}?qr_token=${widget.qrToken}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _orderData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              jsonDecode(response.body)['error'] ??
              'Không thể lấy thông tin đơn hàng';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối mạng';
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment(String pin) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final client = CustomHttpClient();
      final response = await client.post(
        Uri.parse(ApiConfig.processPayment),
        body: jsonEncode({'qr_token': widget.qrToken, 'pin': pin}),
      );

      if (response.statusCode == 200) {
        _showSuccessAndReturn();
      } else {
        final error =
            jsonDecode(response.body)['error'] ?? 'Thanh toán thất bại';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lỗi kết nối mạng')));
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPinAndPay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (pinSheetCtx) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          try {
            if (!mounted) return null;
            Navigator.pop(pinSheetCtx);
            await _processPayment(pin);
            return null;
          } catch (e) {
            return "Lỗi kết nối máy chủ";
          }
        },
      ),
    );
  }

  void _showSuccessAndReturn() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Thanh toán thành công!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đang quay lại ứng dụng mua sắm...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () async {
      final orderCode = _orderData?['order_code'] ?? '';
      final merchantOrderId = _orderData?['merchant_order_id'] ?? '';
      // Ưu tiên merchant_order_id nếu có
      final idToReturn = merchantOrderId.isNotEmpty
          ? merchantOrderId
          : orderCode;

      final returnUrl = Uri.parse(
        'tiktokshop://payment-result?status=success&order_code=$idToReturn',
      );

      if (await canLaunchUrl(returnUrl)) {
        await launchUrl(returnUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback or just pop to home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  void _cancelPayment() async {
    final orderCode = _orderData?['order_code'] ?? '';
    final returnUrl = Uri.parse(
      'tiktokshop://payment-result?status=cancelled&order_code=$orderCode',
    );

    if (await canLaunchUrl(returnUrl)) {
      await launchUrl(returnUrl, mode: LaunchMode.externalApplication);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi thanh toán')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      );
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final double amount =
        double.tryParse(_orderData?['amount']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Xác nhận thanh toán',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancelPayment,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.store,
                      color: AppColors.primaryPink,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _orderData?['merchant_name'] ?? 'TikTok Shop',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _orderData?['description'] ?? 'Thanh toán đơn hàng',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(amount),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPink,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _showPinAndPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Xác nhận thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _cancelPayment,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Hủy giao dịch',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

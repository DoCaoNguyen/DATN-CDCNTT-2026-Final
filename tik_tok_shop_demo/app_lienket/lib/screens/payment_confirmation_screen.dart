import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart.dart';
import '../config/api_config.dart';
import '../services/mio_payment_service.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final double amount;
  final String orderId;

  const PaymentConfirmationScreen({
    Key? key,
    required this.amount,
    required this.orderId,
  }) : super(key: key);

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  bool _isLoading = false;

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Bạn có chắc chắn muốn thanh toán ${currencyFormatter.format(widget.amount)} bằng Ví Mio không?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Đóng dialog
              },
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Đóng dialog
                _processPayment(); // Gọi hàm thanh toán
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFfe2c55),
              ),
              child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true'
        },
        body: jsonEncode({
          'user_id': 1,
          'amount': widget.amount.toInt(),
          'order_id': widget.orderId,
          'api_key': MioPaymentService.merchantApiKey,
          'api_secret': MioPaymentService.apiSecret,
        }),
      );
      
      void showMessageDialog(String title, String message, {bool isSuccess = false}) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
              ],
            ),
            content: Text(message, style: const TextStyle(fontSize: 16)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Đóng dialog
                  if (isSuccess) {
                    CartProvider.clear(); 
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFfe2c55)),
                child: const Text('Đóng', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }

      final jsonResp = jsonDecode(response.body);
      if (response.statusCode == 200 && jsonResp['success'] == true) {
        if (!mounted) return;
        showMessageDialog('Thành công', 'Thanh toán Auto-Debit qua Ví Mio thành công!', isSuccess: true);
      } else {
        if (!mounted) return;
        showMessageDialog('Thanh toán thất bại', jsonResp['message'] ?? 'Thanh toán thất bại');
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lỗi kết nối', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text('Không thể kết nối đến máy chủ thanh toán.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            )
          ],
        )
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Thanh toán đơn hàng', style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Tổng số tiền',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormatter.format(widget.amount),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFfe2c55),
                        ),
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nguồn tiền', style: TextStyle(color: Colors.black87)),
                          Row(
                            children: [
                              Image.network(
                                'https://cdn-icons-png.flaticon.com/512/2875/2875364.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text('Ví Mio liên kết', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mã đơn hàng', style: TextStyle(color: Colors.black87)),
                          Text(widget.orderId, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _showConfirmationDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfe2c55),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text(
                          'Xác nhận thanh toán',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFfe2c55)),
              ),
            ),
        ],
      ),
    );
  }
}

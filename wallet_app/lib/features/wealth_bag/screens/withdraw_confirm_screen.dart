import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import 'transaction_result_screen.dart';

class WithdrawConfirmScreen extends StatefulWidget {
  final int amount;
  final String method; // 'wallet' or 'bank'

  const WithdrawConfirmScreen({
    super.key,
    required this.amount,
    required this.method,
  });

  @override
  State<WithdrawConfirmScreen> createState() => _WithdrawConfirmScreenState();
}

class _WithdrawConfirmScreenState extends State<WithdrawConfirmScreen> {
  String _formatAmount(int amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.') + 'đ';
  }

  void _handleConfirm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          Navigator.pop(ctx);
          await _processWithdraw();
          return null;
        },
      ),
    );
  }

  Future<void> _processWithdraw() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await CustomHttpClient().post(
        Uri.parse(ApiConfig.wealthBagWithdraw),
        headers: {
          'Idempotency-Key': DateTime.now().millisecondsSinceEpoch.toString(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': widget.amount,
          'destination': widget.method == 'wallet' ? 'wallet' : 'linked_bank',
        }),
      );

      Navigator.pop(context); // close loading

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionResultScreen(
              amount: widget.amount,
              isWithdraw: true,
              methodName: widget.method == 'wallet' ? 'Ví Mio' : 'Ngân hàng',
            ),
          ),
        );
      } else {
        SnackbarUtils.showError(context, data['message'] ?? 'Lỗi không xác định');
      }
    } catch (e) {
      Navigator.pop(context); // close loading
      SnackbarUtils.showError(context, "Không thể kết nối máy chủ");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF), // Light background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Xác nhận giao dịch",
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Rút tiền về", style: TextStyle(color: Colors.black54, fontSize: 14)),
                            Text(
                              widget.method == 'wallet' ? "Ví Mio" : "Ngân hàng",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Phí giao dịch", style: TextStyle(color: Colors.black54, fontSize: 14)),
                            Text("Miễn phí", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  // SSL Secure fake text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 32),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Bảo mật chuẩn SSL/TLS, mọi thông tin giao dịch đều được mã hoá an toàn.",
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom button
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Số tiền rút từ Túi Thần Tài", style: TextStyle(color: Colors.black54, fontSize: 14)),
                    Text(
                      _formatAmount(widget.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _handleConfirm,
                    icon: const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                    label: const Text(
                      "Xác nhận",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                      ),
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
}

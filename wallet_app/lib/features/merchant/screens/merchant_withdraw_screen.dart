import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import 'package:flutter/services.dart';

class MerchantWithdrawScreen extends StatefulWidget {
  final String token;
  final String availableBalance;
  
  const MerchantWithdrawScreen({
    Key? key,
    required this.token,
    required this.availableBalance,
  }) : super(key: key);

  @override
  State<MerchantWithdrawScreen> createState() => _MerchantWithdrawScreenState();
}

class _MerchantWithdrawScreenState extends State<MerchantWithdrawScreen> {
  final _amountController = TextEditingController();
  final _client = CustomHttpClient();
  bool _isWithdrawing = false;

  void _withdraw() {
    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountStr.isEmpty) {
      SnackbarUtils.showError(context, "Vui lòng nhập số tiền hợp lệ");
      return;
    }
    
    final amount = int.tryParse(amountStr) ?? 0;
    if (amount < 10000) {
      SnackbarUtils.showError(context, "Số tiền rút tối thiểu là 10.000đ");
      return;
    }
    if (amount > 50000000) {
      SnackbarUtils.showError(context, "Số tiền rút tối đa là 50.000.000đ/ngày");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          try {
            final pinRes = await _client.post(
              Uri.parse(ApiConfig.verifyPin),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'pin': pin}),
            );

            if (pinRes.statusCode == 200) {
              Navigator.pop(ctx);
              await _processWithdraw(amount);
              return null;
            } else {
              final data = jsonDecode(pinRes.body);
              return data['error'] ?? "Mã PIN không chính xác";
            }
          } catch (e) {
            return "Không thể kết nối máy chủ";
          }
        },
      ),
    );
  }

  Future<void> _processWithdraw(int amount) async {
    setState(() {
      _isWithdrawing = true;
    });

    try {
      final res = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/merchant/withdraw-to-wallet'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"amount": amount}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        SnackbarUtils.showSuccess(context, "Rút tiền về ví cá nhân thành công!");
        Navigator.pop(context, true); // Return true to refresh dashboard
      } else {
        final err = jsonDecode(res.body)['error'] ?? "Rút tiền thất bại";
        SnackbarUtils.showError(context, err);
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, "Lỗi kết nối máy chủ");
    } finally {
      if (mounted) {
        setState(() {
          _isWithdrawing = false;
        });
      }
    }
  }

  void _withdrawAll() {
    // Chỉ lấy số từ availableBalance (bỏ 'đ', ',', '.')
    final numStr = widget.availableBalance.replaceAll(RegExp(r'[^0-9]'), '');
    int value = int.tryParse(numStr) ?? 0;
    if (value > 50000000) value = 50000000;
    
    String formatted = value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    _amountController.text = formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rút Doanh Thu', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Column(
                children: [
                  const Text("Số dư khả dụng", style: TextStyle(color: Colors.black54, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    widget.availableBalance,
                    style: const TextStyle(color: Colors.pink, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text("Nhập số tiền muốn rút", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              decoration: InputDecoration(
                prefixText: "đ ",
                prefixStyle: const TextStyle(fontSize: 24, color: Colors.black87),
                hintText: "0",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.pink, width: 2)),
                suffixIcon: TextButton(
                  onPressed: _withdrawAll,
                  child: const Text("Tất cả", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.black54),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Tiền sẽ được chuyển ngay lập tức về Ví cá nhân của bạn.",
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isWithdrawing ? null : _withdraw,
                child: _isWithdrawing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Xác nhận rút tiền", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');
    
    // Giới hạn 12 số
    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }
    
    int value = int.parse(digitsOnly);
    String newText = value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

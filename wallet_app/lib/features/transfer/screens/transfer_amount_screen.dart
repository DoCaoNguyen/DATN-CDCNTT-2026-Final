import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';

class TransferAmountScreen extends StatefulWidget {
  final String token;
  final String receiverName;
  final String receiverPhone;

  const TransferAmountScreen({
    Key? key,
    required this.token,
    required this.receiverName,
    required this.receiverPhone,
  }) : super(key: key);

  @override
  State<TransferAmountScreen> createState() => _TransferAmountScreenState();
}

class _TransferAmountScreenState extends State<TransferAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;
  
  // --- MỚI THÊM: Biến lưu lỗi số tiền ---
  String? _amountError;

  // Format Text khi người dùng gõ
  String _formatAmount(String value) {
    if (value.isEmpty) return "";
    final number = int.tryParse(value.replaceAll('.', ''));
    if (number == null) return "";
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  Future<void> _handleTransfer() async {
    if (_amountController.text.isEmpty) return;
    
    final rawAmount = _amountController.text.replaceAll('.', '');
    final intAmount = int.parse(rawAmount);

    if (intAmount < 1000) return; // Đã chặn ở giao diện, chốt chặn thêm ở đây cho an toàn

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.transfer),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'receiver_identifier': widget.receiverPhone,
          'amount': rawAmount,
          'note': _noteController.text.isNotEmpty ? _noteController.text : 'Chuyển tiền',
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Giao dịch thất bại';
        _showBeautifulErrorDialog(errorMessage);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Lỗi kết nối máy chủ");
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
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
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
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
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
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Chuyển tiền thành công!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Về màn hình chính', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    bool hasAmount = _amountController.text.isNotEmpty;
    // Nút chỉ sáng lên khi có nhập số tiền, không load, và KHÔNG có lỗi (tiền >= 1000)
    bool isButtonEnabled = hasAmount && !_isLoading && _amountError == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.receiverPhone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F5), Color(0xFFF5F5F9)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Ô nhập số tiền (Hình 3)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ]),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40, 
                      fontWeight: FontWeight.bold, 
                      color: _amountError != null ? const Color(0xFFD32F2F) : (hasAmount ? Colors.black : Colors.grey)
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0đ',
                      hintStyle: TextStyle(fontSize: 40, color: Colors.grey),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      String formatted = _formatAmount(val);
                      _amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                      
                      // --- ĐÃ THÊM: Kiểm tra realtime khi người dùng vừa gõ ---
                      setState(() {
                        final rawAmount = formatted.replaceAll('.', '');
                        final intAmount = int.tryParse(rawAmount) ?? 0;
                        if (rawAmount.isNotEmpty && intAmount < 1000) {
                          _amountError = 'Số tiền chuyển tối thiểu là 1.000đ';
                        } else {
                          _amountError = null;
                        }
                      });
                    },
                  ),
                  
                  // --- MỚI THÊM: Dòng thông báo lỗi căn giữa giống trang OTP ---
                  if (_amountError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                      child: Text(
                        _amountError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD32F2F), // Màu đỏ lỗi
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Ô Lời nhắn
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Nhập hoặc chọn bên dưới',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      labelText: 'Lời nhắn',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8, runSpacing: 8,
                      children: [
                        _buildQuickNote('Mình chuyển tiền nhé 💵'),
                        _buildQuickNote('Em cảm ơn ạ! 💰'),
                        _buildQuickNote('Em chuyển tiền nha 😻'),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const Spacer(),
            // Bàn phím số tiền nhanh (Góc dưới)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAmountBtn('50.000'),
                      _buildQuickAmountBtn('100.000'),
                      _buildQuickAmountBtn('200.000'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isButtonEnabled ? _handleTransfer : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isButtonEnabled ? Colors.pink : Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Chuyển tiền', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNote(String text) {
    return GestureDetector(
      onTap: () => setState(() => _noteController.text = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ),
    );
  }

  Widget _buildQuickAmountBtn(String amount) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        setState(() {
          _amountController.text = amount;
          _amountError = null; // Chọn gợi ý >1000đ thì chắc chắn xóa lỗi
        });
      },
      child: Text('$amountđ'),
    );
  }
}
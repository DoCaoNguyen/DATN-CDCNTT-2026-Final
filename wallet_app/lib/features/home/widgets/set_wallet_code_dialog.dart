import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';

class SetWalletCodeDialog extends StatefulWidget {
  final String token;
  final Function(String) onSuccess;

  const SetWalletCodeDialog({
    Key? key,
    required this.token,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<SetWalletCodeDialog> createState() => _SetWalletCodeDialogState();
}

class _SetWalletCodeDialogState extends State<SetWalletCodeDialog> {
  final TextEditingController codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final _client = CustomHttpClient();

  bool isSubmitting = false;
  String? errorText;

  @override
  void dispose() {
    codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    if (codeController.text.trim().length != 6) return;

    setState(() {
      isSubmitting = true;
      errorText = null;
    });

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.setWalletCode),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'wallet_code': codeController.text.trim()}),
      );

      if (response.statusCode == 200) {
        widget.onSuccess(codeController.text.trim());
        if (mounted) Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          isSubmitting = false;
          errorText =
              data['error'] ?? 'Mã PIN này không hợp lệ hoặc đã tồn tại.';
          codeController.clear(); // Xóa trắng để người dùng nhập lại
          _focusNode.requestFocus(); // Tự động bật lại bàn phím
        });
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
        errorText = 'Lỗi kết nối máy chủ';
        codeController.clear();
        _focusNode.requestFocus();
      });
    }
  }

  Widget _buildPinDots() {
    String pin = codeController.text;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          bool isFilled = index < pin.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? Colors.grey.shade500 : Colors.grey.shade300,
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.bottomCenter,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 32,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh gạch ngang (Drag handle)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Tiêu đề và nút Đóng (X)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // Cân bằng không gian với nút X
                const Text(
                  'Tạo mã Pin xác thực',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Khối nhập mã PIN (Sử dụng Stack để ẩn TextField thật đi)
            Stack(
              alignment: Alignment.center,
              children: [
                // TextField thật (Được ẩn đi bằng Opacity)
                Opacity(
                  opacity: 0.0,
                  child: TextField(
                    controller: codeController,
                    focusNode: _focusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(counterText: ""),
                    onChanged: (val) {
                      setState(() {
                        if (errorText != null) errorText = null;
                      });
                      if (val.length == 6) {
                        _submitCode(); // Tự động gọi API khi đủ 6 số
                      }
                    },
                  ),
                ),

                // Giao diện 6 dấu chấm (Đè lên TextField)
                GestureDetector(
                  onTap: () => _focusNode
                      .requestFocus(), // Bấm vào để hiện lại bàn phím nếu lỡ tắt
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    child: _buildPinDots(),
                  ),
                ),
              ],
            ),

            // Hiển thị vòng xoay loading hoặc lỗi
            const SizedBox(height: 24),
            if (isSubmitting)
              const CircularProgressIndicator(color: Colors.pink)
            else if (errorText != null)
              Text(
                errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              )
            else
              const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

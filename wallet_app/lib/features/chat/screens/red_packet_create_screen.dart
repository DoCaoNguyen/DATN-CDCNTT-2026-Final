import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'contact_selector_screen.dart';

class RedPacketCreateScreen extends StatefulWidget {
  final String token;
  final String? counterpartyPhone; // Nếu truyền vào, sẽ tự động gửi qua chat

  const RedPacketCreateScreen({
    Key? key,
    required this.token,
    this.counterpartyPhone,
  }) : super(key: key);

  @override
  State<RedPacketCreateScreen> createState() => _RedPacketCreateScreenState();
}

class _RedPacketCreateScreenState extends State<RedPacketCreateScreen> {
  final _client = CustomHttpClient();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _countController = TextEditingController(
    text: '1',
  );
  final TextEditingController _messageController = TextEditingController(
    text: 'Cung hỉ phát tài',
  );

  bool _isRandom = false; // false = EQUAL, true = RANDOM
  bool _isLoading = false;

  void _createRedPacket() async {
    final amountStr = _amountController.text.replaceAll('.', '');
    if (amountStr.isEmpty) {
      SnackbarUtils.showError(context, 'Vui lòng nhập số tiền');
      return;
    }

    final amount = int.tryParse(amountStr);
    final count = int.tryParse(_countController.text);

    if (amount == null || amount < 1000) {
      SnackbarUtils.showError(context, 'Số tiền tối thiểu 1000đ');
      return;
    }
    if (count == null || count < 1) {
      SnackbarUtils.showError(context, 'Số lượng tối thiểu 1 người');
      return;
    }
    if (amount / count < 1000) {
      SnackbarUtils.showError(
        context,
        'Trung bình mỗi người nhận tối thiểu 1000đ',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.createRedPacket),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'total_amount': amount,
          'total_count': count,
          'type': _isRandom ? 'RANDOM' : 'EQUAL',
          'message': _messageController.text.isEmpty
              ? 'Cung hỉ phát tài'
              : _messageController.text,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rpId = data['data']['id'];

        if (widget.counterpartyPhone == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ContactSelectorScreen(token: widget.token, redPacketId: rpId),
            ),
          );
        } else {
          Navigator.pop(context, rpId);
        }
      } else {
        final err = jsonDecode(response.body);
        SnackbarUtils.showError(context, err['error'] ?? 'Lỗi tạo lì xì');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      SnackbarUtils.showError(context, 'Lỗi kết nối mạng');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935), // Màu đỏ may mắn
        elevation: 0,
        title: const Text(
          'Phát Lì Xì',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Container Số lượng
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Số phong bì',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Nhập số lượng',
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Cái', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lựa chọn chia tiền
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.casino_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isRandom
                          ? 'Chia tiền ngẫu nhiên'
                          : 'Chia tiền bằng nhau',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRandom = !_isRandom;
                      });
                    },
                    child: Text(
                      'Đổi sang ${_isRandom ? 'Chia đều' : 'Ngẫu nhiên'}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),

            // Container Số tiền
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    _isRandom ? 'Tổng tiền' : 'Số tiền mỗi bao',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                      ),
                      onChanged: (val) {
                        final text = val.replaceAll('.', '');
                        if (text.isNotEmpty) {
                          final number = int.tryParse(text);
                          if (number != null) {
                            setState(() {
                              _amountController.value = TextEditingValue(
                                text: NumberFormat(
                                  '#,###',
                                ).format(number).replaceAll(',', '.'),
                                selection: TextSelection.collapsed(
                                  offset: NumberFormat(
                                    '#,###',
                                  ).format(number).replaceAll(',', '.').length,
                                ),
                              );
                            });
                          }
                        } else {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('VNĐ', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lời chúc
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _messageController,
                maxLength: 50,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Lời chúc',
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) {
                  final amountStr = _amountController.text.replaceAll('.', '');
                  final amount = int.tryParse(amountStr) ?? 0;
                  final count = int.tryParse(_countController.text) ?? 1;
                  final total = _isRandom ? amount : amount * count;

                  return Text(
                    total == 0
                        ? '0 đ'
                        : '${NumberFormat('#,###').format(total).replaceAll(',', '.')} đ',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRedPacket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Nhét tiền vào Bao lì xì',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

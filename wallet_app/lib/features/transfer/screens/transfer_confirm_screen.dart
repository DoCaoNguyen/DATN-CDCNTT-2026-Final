import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';

class TransferConfirmScreen extends StatefulWidget {
  final String token;
  final String receiverName;
  final String receiverPhone;
  final String amount;
  final String note;

  const TransferConfirmScreen({
    Key? key,
    required this.token,
    required this.receiverName,
    required this.receiverPhone,
    required this.amount,
    required this.note,
  }) : super(key: key);

  @override
  State<TransferConfirmScreen> createState() => _TransferConfirmScreenState();
}

class _TransferConfirmScreenState extends State<TransferConfirmScreen> {
  bool _isLoading = false;
  // Tạo mã tham chiếu ảo ngẫu nhiên cho giống giao diện
  final String _refCode = "${Random().nextInt(900000) + 100000}${Random().nextInt(900000) + 100000}";

  String _formatAmount(String value) {
    final number = int.tryParse(value);
    if (number == null) return "0đ";
    return "${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }

  // HÀM HIỂN THỊ BOTTOM SHEET NHẬP MÃ PIN
  void _showPinBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) {
          Navigator.pop(context); // Đóng Bottom sheet sau khi nhập xong 6 số
          _handleConfirmTransfer(pin); // Gọi hàm chuyển tiền
        },
      ),
    );
  }

  // HÀM GỌI API CHUYỂN TIỀN
  Future<void> _handleConfirmTransfer(String pinCode) async {
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
          'amount': widget.amount,
          'note': widget.note,
          'reference_code': _refCode, // Gửi mã tham chiếu
          // 'pin': pinCode // Trong thực tế Backend sẽ yêu cầu mã PIN này
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
              decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Giao dịch không thành công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Chuyển tiền thành công!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  // Đóng toàn bộ popup và màn hình phụ, quay thẳng về màn hình gốc (Home)
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
              fontWeight: FontWeight.bold, 
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4EE), // Màu hồng nhạt gradient
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Thanh toán an toàn', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Phần nội dung cuộn được
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  // Lớp nền Gradient hồng ảo diệu phía trên
                  Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFE4EE), Color(0xFFF5F5F9)],
                      ),
                    ),
                  ),
                  
                  // Các Card nội dung
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Card 1: Thông tin giao dịch
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.history_toggle_off, color: Colors.red.shade400, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Chuyển tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow('Số tiền', _formatAmount(widget.amount), isBlue: true),
                              _buildDetailRow('Người nhận', widget.receiverName, isBlue: true),
                              _buildDetailRow('Số điện thoại', widget.receiverPhone),
                              _buildDetailRow('Lời nhắn', widget.note.isNotEmpty ? widget.note : 'Chuyển tiền'),
                              _buildDetailRow('Mã tham chiếu', _refCode),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Card 2: Nguồn tiền
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text('Trả ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  SizedBox(width: 4),
                                  Icon(Icons.visibility_outlined, size: 16, color: Colors.grey),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Dòng Ví MoMo (Đang chọn)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.pink, width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.pink.shade50.withOpacity(0.3)
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                                      child: const Text('mo\nmo', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold, height: 1)),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Ví MoMo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.radio_button_checked, color: Colors.pink),
                                  ],
                                ),
                              )
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
          
          // Phần TỔNG TIỀN và NÚT XÁC NHẬN ghim dưới đáy
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
                      Text(_formatAmount(widget.amount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      // SỬA Ở ĐÂY: Bấm nút gọi bảng nhập PIN thay vì chạy API luôn
                      onPressed: _isLoading ? null : _showPinBottomSheet, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_outline, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Xác nhận', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// =========================================================
// WIDGET BOTTOM SHEET NHẬP MÃ PIN CỦA MOMO
// =========================================================
class PinConfirmBottomSheet extends StatefulWidget {
  final Function(String) onPinEntered;
  const PinConfirmBottomSheet({Key? key, required this.onPinEntered}) : super(key: key);

  @override
  State<PinConfirmBottomSheet> createState() => _PinConfirmBottomSheetState();
}

class _PinConfirmBottomSheetState extends State<PinConfirmBottomSheet> {
  final TextEditingController pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildPinDots() {
    String pin = pinController.text;
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
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding viewInsets giúp bảng bị đẩy lên trên bàn phím số
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 24, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                const Text('Nhập mã PIN xác thực', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.0,
                  child: TextField(
                    controller: pinController,
                    focusNode: _focusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(counterText: ""),
                    onChanged: (val) {
                      setState(() {});
                      if (val.length == 6) {
                        widget.onPinEntered(val); // Truyền dữ liệu ra ngoài khi gõ xong 6 số
                      }
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () => _focusNode.requestFocus(),
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    child: _buildPinDots(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {}, // Nơi thêm logic Quên mã PIN sau này nếu cần
              child: const Text('Quên mã PIN?', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
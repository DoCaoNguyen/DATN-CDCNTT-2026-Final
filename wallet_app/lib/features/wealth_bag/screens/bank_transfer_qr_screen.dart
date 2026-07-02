import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';

class BankTransferQrScreen extends StatefulWidget {
  final int amount;

  const BankTransferQrScreen({super.key, required this.amount});

  @override
  State<BankTransferQrScreen> createState() => _BankTransferQrScreenState();
}

class _BankTransferQrScreenState extends State<BankTransferQrScreen> {
  bool _isLoading = true;
  String? _qrDataURL;
  String? _qrCode;
  String? _error;
  String _receiverName = "MOMO - TÀI KHOẢN TÍCH LŨY";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchQrCode();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await CustomHttpClient().get(Uri.parse(ApiConfig.getMyProfile));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['full_name'] != null) {
          setState(() {
            _receiverName = "MOMO - TKTH ${data['data']['full_name'].toString().toUpperCase()}";
          });
        }
      }
    } catch (e) {
      // Bỏ qua lỗi, giữ nguyên tên mặc định
    }
  }

  Future<void> _fetchQrCode() async {
    try {
      final response = await CustomHttpClient().post(
        Uri.parse('${ApiConfig.baseUrl}/wealth-bag/generate-qr'),
        body: jsonEncode({'amount': widget.amount}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        setState(() {
          _qrDataURL = data['data']['qrDataURL'];
          _qrCode = data['data']['qrCode'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['message'] ?? 'Lỗi không xác định';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể kết nối máy chủ';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã sao chép vào bộ nhớ tạm")),
    );
  }

  String _formatAmount(int amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.') + 'đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chuyển khoản vào Túi",
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline, color: Colors.black87), onPressed: () {}),
          IconButton(icon: const Icon(Icons.headset_mic_outlined, color: Colors.black87), onPressed: () {}),
          IconButton(icon: const Icon(Icons.home_outlined, color: Colors.black87), onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          }),
        ],
      ),
      body: Column(
        children: [
          // Stepper
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStep(1, "Tải mã hoặc sao\nchép STK", true),
                _buildStep(2, "Chọn ứng dụng\nngân hàng", false),
                _buildStep(3, "Chuyển khoản vào\nTúi", false),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Mã chuyển khoản vào Túi Thần Tài",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.deepOrange)
                            : _error != null 
                              ? Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)
                              : _qrDataURL != null 
                                ? Image.memory(
                                    base64Decode(_qrDataURL!.split(',').last),
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.qr_code_2, size: 100, color: Colors.black87),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoRow("Ngân hàng:", "VPBank", valueColor: Colors.green.shade700, isBold: true),
                        const SizedBox(height: 12),
                        _buildInfoRow("Tên người nhận:", _receiverName, isBold: true),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 110,
                              child: Text("Số tài khoản:", style: TextStyle(color: Colors.grey, fontSize: 14)),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () => _copyToClipboard("01MMTTT0076501864"),
                                    child: const Icon(Icons.copy, size: 16, color: Colors.deepOrange),
                                  ),
                                  const SizedBox(width: 4),
                                  const Flexible(
                                    child: Text(
                                      "01MMTTT0076501864", 
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow("Số tiền nạp:", _formatAmount(widget.amount), isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionIcon(Icons.menu_book, "Hướng dẫn\nchuyển khoản"),
                        _buildActionIcon(Icons.info_outline, "Chi tiết hạn mức"),
                        _buildActionIcon(Icons.support_agent, "Yêu cầu hỗ trợ"),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      // Handle save QR and open bank
                    },
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                    label: const Text("Tải mã QR và mở ứng dụng ngân hàng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.deepOrange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      // Handle copy and open bank
                      _copyToClipboard("01MMTTT0076501864");
                    },
                    icon: const Icon(Icons.copy, color: Colors.deepOrange, size: 20),
                    label: const Text("Sao chép và mở ứng dụng ngân hàng", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? Colors.deepOrange : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(step.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.deepOrange : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.black54, size: 24),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}

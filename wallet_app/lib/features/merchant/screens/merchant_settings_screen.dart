import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';

class MerchantSettingsScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> merchantData;

  const MerchantSettingsScreen({
    Key? key,
    required this.token,
    required this.merchantData,
  }) : super(key: key);

  @override
  State<MerchantSettingsScreen> createState() => _MerchantSettingsScreenState();
}

class _MerchantSettingsScreenState extends State<MerchantSettingsScreen> {
  final _client = CustomHttpClient();
  final _webhookController = TextEditingController();
  bool _keysVisible = false;

  @override
  void initState() {
    super.initState();
    _webhookController.text = widget.merchantData['callback_url'] ?? '';
  }

  Future<void> _updateWebhook() async {
    final url = _webhookController.text.trim();
    if (url.isEmpty) {
      SnackbarUtils.showError(context, 'Vui lòng nhập Webhook URL');
      return;
    }

    try {
      final res = await _client.patch(
        Uri.parse('${ApiConfig.baseUrl}/merchant/profile/callback'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"default_callback_url": url}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        SnackbarUtils.showSuccess(context, "Cập nhật Webhook thành công");
      } else {
        SnackbarUtils.showError(context, "Cập nhật Webhook thất bại");
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, "Lỗi kết nối máy chủ");
    }
  }

  void _toggleKeysVisibility() {
      setState(() {
        _keysVisible = !_keysVisible;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt Cửa hàng', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cấu hình Webhook", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField("Callback URL", _webhookController, Icons.link_rounded),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _updateWebhook,
                  child: const Text("Lưu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("API Keys", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _toggleKeysVisibility,
                  icon: Icon(_keysVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                  label: Text(_keysVisible ? "Ẩn Keys" : "Xem Keys"),
                  style: TextButton.styleFrom(foregroundColor: Colors.pink),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildKeyItem("Merchant ID (Partner Code)", widget.merchantData['merchant_id']),
            const SizedBox(height: 16),
            _buildKeyItem("API Key", widget.merchantData['api_key']),
            const SizedBox(height: 16),
            _buildKeyItem("Secret Key", widget.merchantData['secret_key']),
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: _showIntegrationGuide,
                icon: const Icon(Icons.integration_instructions_rounded, size: 20),
                label: const Text("Hướng dẫn tích hợp API"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.pink,
                  side: const BorderSide(color: Colors.pink),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showIntegrationGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const Text(
              "Hướng dẫn tích hợp API",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  _buildGuideSection("1. Xác thực (Authentication)", "Mọi request gọi tới API của Mio Wallet đều phải gửi kèm API Key trong Header."),
                  _buildCodeBlock("Headers:\n  x-api-key: <API_KEY>\n  Content-Type: application/json"),
                  const SizedBox(height: 20),
                  _buildGuideSection("2. Tạo Link Thanh Toán", "Gọi API POST để tạo một phiên thanh toán mới cho khách hàng."),
                  _buildCodeBlock("POST ${ApiConfig.baseUrl}/payment/create\n\n{\n  \"amount\": 50000,\n  \"description\": \"Thanh toan don hang #123\",\n  \"merchant_order_id\": \"123\"\n}"),
                  const SizedBox(height: 20),
                  _buildGuideSection("3. Nhận Webhook", "Sau khi khách hàng thanh toán thành công, hệ thống sẽ gửi một POST request về Callback URL của bạn."),
                  _buildCodeBlock("POST <Webhook URL>\n\n{\n  \"merchant_order_id\": \"123\",\n  \"status\": \"SUCCESS\",\n  \"amount\": 50000,\n  \"signature\": \"...\"\n}"),
                  const SizedBox(height: 8),
                  const Text("Sử dụng Secret Key để giải mã hoặc đối chiếu chữ ký (Signature) nhằm đảm bảo tính toàn vẹn của dữ liệu webhook.", style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 20),
                  _buildGuideSection("4. Kiểm tra Trạng thái (Pull API)", "Gọi API GET để chủ động kiểm tra trạng thái đơn hàng (Dùng khi rớt mạng hoặc Cronjob)."),
                  _buildCodeBlock("GET ${ApiConfig.baseUrl}/payment/status?merchant_order_id=123\n\nHeaders:\n  x-api-key: <API_KEY>"),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.pink)),
        const SizedBox(height: 6),
        Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCodeBlock(String code) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            code,
            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12, height: 1.5),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              SnackbarUtils.showSuccess(context, "Đã sao chép đoạn code");
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeyItem(String label, String? value) {
    final displayValue = value ?? 'N/A';
    final isHidden = !_keysVisible;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  isHidden ? '********************************' : displayValue,
                  style: TextStyle(
                    fontFamily: isHidden ? null : 'monospace',
                    fontSize: isHidden ? 16 : 13,
                    color: Colors.black87,
                    fontWeight: isHidden ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (!isHidden)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: displayValue));
                    SnackbarUtils.showSuccess(context, "Đã sao chép $label");
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.pink, width: 1.5)),
      ),
    );
  }
}

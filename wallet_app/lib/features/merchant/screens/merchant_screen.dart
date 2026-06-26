import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import '../../../core/widgets/otp_input_widget.dart';
import '../../profile/screens/personal_profile_screen.dart';

class MerchantScreen extends StatefulWidget {
  final String token;

  const MerchantScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends State<MerchantScreen> {
  final _client = CustomHttpClient();
  bool _isLoading = true;

  bool _isEmailVerified = false;
  String _userEmail = '';
  String _userFullName = '';
  String _userPhone = '';

  bool _isMerchant = false;
  Map<String, dynamic> _merchantData = {};

  // Registration Form
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _webhookController = TextEditingController();

  bool _isRegistering = false;
  bool _keysVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch User Profile
      final userRes = await _client.get(Uri.parse(ApiConfig.getMyProfile));
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _userEmail = userData['data']['email'] ?? '';
        _isEmailVerified = _userEmail.isNotEmpty;
        _userFullName = userData['data']['full_name'] ?? '';
        _userPhone = userData['data']['phone'] ?? '';
      }

      // Fetch Merchant Info
      final merchantRes = await _client.get(Uri.parse('${ApiConfig.baseUrl}/merchant/me'));
      if (merchantRes.statusCode == 200) {
        final merchantData = jsonDecode(merchantRes.body);
        _merchantData = merchantData['data'];
        _isMerchant = true;
      } else if (merchantRes.statusCode == 404) {
        _isMerchant = false;
      }
    } catch (e) {
      debugPrint('Error fetching merchant data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final webhook = _webhookController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      SnackbarUtils.showError(context, 'Vui lòng nhập Tên và SĐT doanh nghiệp');
      return;
    }

    setState(() => _isRegistering = true);

    try {
      // Yêu cầu OTP
      final otpRes = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/users/email/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": _userEmail}),
      );

      if (otpRes.statusCode != 200) {
        SnackbarUtils.showError(context, 'Lỗi gửi mã OTP');
        setState(() => _isRegistering = false);
        return;
      }

      // Hiển thị hộp thoại OTP
      _showOtpDialog(name, phone, webhook);
    } catch (e) {
      SnackbarUtils.showError(context, 'Lỗi kết nối máy chủ');
    } finally {
      setState(() => _isRegistering = false);
    }
  }

  void _showOtpDialog(String name, String phone, String webhook) {
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Xác thực OTP", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Mã OTP gồm 6 chữ số đã được gửi tới:\n$_userEmail",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  OtpInputWidget(
                    length: 6,
                    onChanged: (val) {
                      otpController.text = val;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final otp = otpController.text.trim();
                          if (otp.length != 6) {
                            SnackbarUtils.showError(context, "Mã OTP phải gồm 6 số");
                            return;
                          }

                          setStateDialog(() => isVerifying = true);

                          try {
                            final verifyRes = await _client.post(
                              Uri.parse('${ApiConfig.baseUrl}/users/email/verify-otp'),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({"email": _userEmail, "otp": otp}),
                            );

                            if (verifyRes.statusCode == 200) {
                              // OTP đúng, tiến hành đăng ký Merchant
                              final regRes = await _client.post(
                                Uri.parse('${ApiConfig.baseUrl}/merchant/register'),
                                headers: {"Content-Type": "application/json"},
                                body: jsonEncode({
                                  "merchant_name": name,
                                  "contact_phone": phone,
                                  "callback_url": webhook,
                                }),
                              );

                              if (regRes.statusCode == 201) {
                                if (mounted) {
                                  Navigator.pop(context); // Đóng dialog
                                  SnackbarUtils.showSuccess(context, "Đăng ký Merchant thành công!");
                                  _fetchData(); // Load lại dữ liệu
                                }
                              } else {
                                final err = jsonDecode(regRes.body)['error'] ?? "Đăng ký thất bại";
                                if (mounted) SnackbarUtils.showError(context, err);
                              }
                            } else {
                              final err = jsonDecode(verifyRes.body)['error'] ?? "Mã OTP không hợp lệ";
                              if (mounted) SnackbarUtils.showError(context, err);
                            }
                          } catch (e) {
                            if (mounted) SnackbarUtils.showError(context, "Lỗi kết nối máy chủ");
                          } finally {
                            setStateDialog(() => isVerifying = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isVerifying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Xác nhận", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPinBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          try {
            // Xác thực PIN qua API
            final response = await _client.post(
              Uri.parse(ApiConfig.verifyPin),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'pin': pin}),
            );

            if (response.statusCode == 200) {
              if (mounted) {
                Navigator.pop(context);
                setState(() => _keysVisible = true);
              }
              return null; // Thành công
            } else {
              return 'Mã PIN không chính xác';
            }
          } catch (e) {
            return 'Lỗi kết nối máy chủ';
          }
        },
      ),
    );
  }

  Future<void> _updateWebhook() async {
    final webhook = _webhookController.text.trim();
    if (webhook.isEmpty) {
      SnackbarUtils.showError(context, "Vui lòng nhập Webhook URL");
      return;
    }
    try {
      final res = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/merchant/webhook'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"callback_url": webhook}),
      );
      if (res.statusCode == 200) {
        SnackbarUtils.showSuccess(context, "Cập nhật Webhook thành công");
      } else {
        SnackbarUtils.showError(context, "Cập nhật thất bại");
      }
    } catch (e) {
      SnackbarUtils.showError(context, "Lỗi kết nối");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Đối tác kinh doanh', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _isMerchant
              ? _buildMerchantInfo()
              : _isEmailVerified
                  ? _buildRegistrationForm()
                  : _buildRequireEmail(),
    );
  }

  Widget _buildRequireEmail() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              "Xác thực Email",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Để đăng ký trở thành Đối tác kinh doanh, bạn cần cung cấp và xác thực địa chỉ email.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersonalProfileScreen(
                        token: widget.token,
                        email: null,
                        fullName: _userFullName,
                        phone: _userPhone,
                      ),
                    ),
                  ).then((_) => _fetchData());
                },
                child: const Text('Cập nhật Email ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Đăng ký Merchant",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            "Điền thông tin doanh nghiệp của bạn để bắt đầu tích hợp thanh toán qua API.",
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildTextField("Tên doanh nghiệp / Cửa hàng", _nameController, Icons.storefront_rounded),
          const SizedBox(height: 20),
          _buildTextField("Số điện thoại liên hệ", _phoneController, Icons.phone_rounded, isNumber: true),
          const SizedBox(height: 20),
          _buildTextField("Webhook URL (Tùy chọn)", _webhookController, Icons.link_rounded),
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
              onPressed: _isRegistering ? null : _handleRegister,
              child: _isRegistering
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Đăng ký ngay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMerchantInfo() {
    if (_webhookController.text.isEmpty) {
      _webhookController.text = _merchantData['callback_url'] ?? '';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFF06292)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.pink.withAlpha(76), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 25, backgroundColor: Colors.white24, child: Icon(Icons.store, color: Colors.white, size: 30)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_merchantData['merchant_name'] ?? 'Merchant', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("SĐT: ${_merchantData['contact_phone']}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
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
              if (!_keysVisible)
                TextButton.icon(
                  onPressed: _showPinBottomSheet,
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text("Xem Keys"),
                  style: TextButton.styleFrom(foregroundColor: Colors.pink),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildKeyItem("Merchant ID (Partner Code)", _merchantData['merchant_id']),
          const SizedBox(height: 16),
          _buildKeyItem("API Key", _merchantData['api_key']),
          const SizedBox(height: 16),
          _buildKeyItem("Secret Key", _merchantData['secret_key']),
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

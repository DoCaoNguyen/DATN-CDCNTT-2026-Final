import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import '../../../core/widgets/otp_input_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/screens/personal_profile_screen.dart';
import '../../../core/utils/currency_formatter.dart';
import 'merchant_settings_screen.dart';
import 'merchant_withdraw_screen.dart';

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
    
    // Đăng ký nhận sự kiện cập nhật số dư merchant qua Socket
    SocketService().onMerchantBalanceUpdate((data) {
      if (mounted && _isMerchant) {
        setState(() {
          _merchantData['available_balance'] = data['newBalance']?.toString() ?? _merchantData['available_balance'];
        });
        debugPrint('Merchant balance updated via Socket: ${data['newBalance']}');
      }
    });
  }

  @override
  void dispose() {
    SocketService().offMerchantBalanceUpdate();
    _nameController.dispose();
    _phoneController.dispose();
    _webhookController.dispose();
    super.dispose();
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
        
        if (_phoneController.text.isEmpty) {
          _phoneController.text = _userPhone;
        }
      }

      // Fetch Merchant Info
      final merchantRes = await _client.get(Uri.parse('${ApiConfig.baseUrl}/merchant/me'));
      if (merchantRes.statusCode == 200) {
        final merchantData = jsonDecode(merchantRes.body);
        _merchantData = merchantData['data'];
        _isMerchant = true;

        // Fetch Balance
        final balanceRes = await _client.get(Uri.parse('${ApiConfig.baseUrl}/merchant/balance'));
        if (balanceRes.statusCode == 200) {
          final balanceData = jsonDecode(balanceRes.body);
          _merchantData['available_balance'] = balanceData['data']['available_balance'];
        }
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
    String currentOtp = "";
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Xác thực OTP",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Mã OTP gồm 6 chữ số đã được gửi tới:\n$_userEmail",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    OtpInputWidget(
                      length: 6,
                      onChanged: (val) {
                        currentOtp = val;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isVerifying
                            ? null
                            : () async {
                                if (currentOtp.length != 6) {
                                  SnackbarUtils.showError(context, "Mã OTP phải gồm 6 số");
                                  return;
                                }

                                setSheetState(() => isVerifying = true);

                                try {
                                  final verifyRes = await _client.post(
                                    Uri.parse('${ApiConfig.baseUrl}/users/email/verify-otp'),
                                    headers: {"Content-Type": "application/json"},
                                    body: jsonEncode({"email": _userEmail, "otp": currentOtp}),
                                  );

                                  if (!mounted) return;

                                  if (verifyRes.statusCode == 200) {
                                    final regRes = await _client.post(
                                      Uri.parse('${ApiConfig.baseUrl}/merchant/register'),
                                      headers: {"Content-Type": "application/json"},
                                      body: jsonEncode({
                                        "merchant_name": name,
                                        "contact_phone": phone,
                                        "callback_url": webhook,
                                      }),
                                    );
                                    
                                    if (!mounted) return;

                                    if (regRes.statusCode == 201) {
                                      Navigator.pop(context); // Đóng bottom sheet
                                      SnackbarUtils.showSuccess(context, "Đăng ký Merchant thành công!");
                                      _fetchData(); // Load lại dữ liệu
                                    } else {
                                      final err = jsonDecode(regRes.body)['error'] ?? "Đăng ký thất bại";
                                      SnackbarUtils.showError(context, err);
                                    }
                                  } else {
                                    final err = jsonDecode(verifyRes.body)['error'] ?? "Mã OTP không hợp lệ";
                                    SnackbarUtils.showError(context, err);
                                  }
                                } catch (e) {
                                  if (mounted) SnackbarUtils.showError(context, "Lỗi kết nối máy chủ");
                                } finally {
                                  if (mounted) setSheetState(() => isVerifying = false);
                                }
                              },
                        child: isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Xác nhận",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
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
    final balanceStr = _merchantData['available_balance'] ?? '0';
    final formattedBalance = CurrencyFormatter.format(balanceStr);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_merchantData['merchant_name'] ?? 'Merchant', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text("SĐT: ${_merchantData['contact_phone']}", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: Colors.pink, size: 28),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => PinConfirmBottomSheet(
                      onPinEntered: (pin) async {
                        try {
                          final response = await _client.post(
                            Uri.parse(ApiConfig.verifyPin),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'pin': pin}),
                          );

                          if (response.statusCode == 200) {
                            Navigator.pop(ctx); // Đóng bottom sheet
                            if (!mounted) return null;
                            
                            // Điều hướng qua màn hình settings
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MerchantSettingsScreen(
                                  token: widget.token,
                                  merchantData: _merchantData,
                                ),
                              ),
                            ).then((_) => _fetchData());
                            
                            return null; // Return null = success
                          } else {
                            final data = jsonDecode(response.body);
                            return data['error'] ?? "Mã PIN không chính xác";
                          }
                        } catch (e) {
                          return "Không thể kết nối máy chủ";
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFF06292)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.pink.withAlpha(76), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                const Text("SỐ DƯ DOANH THU", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Text(
                  formattedBalance,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                    label: const Text("Rút Doanh Thu", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MerchantWithdrawScreen(
                            token: widget.token,
                            availableBalance: formattedBalance,
                          ),
                        ),
                      ).then((changed) {
                        if (changed == true) {
                          _fetchData();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
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

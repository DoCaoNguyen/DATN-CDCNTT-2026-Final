import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/widgets/pin_confirm_bottom_sheet.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wallet_app/core/services/custom_http_client.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';

class WalletLinkConfirmScreen extends StatefulWidget {
  final String merchantName;

  const WalletLinkConfirmScreen({Key? key, required this.merchantName}) : super(key: key);

  @override
  State<WalletLinkConfirmScreen> createState() => _WalletLinkConfirmScreenState();
}

class _WalletLinkConfirmScreenState extends State<WalletLinkConfirmScreen> {
  bool _isLoading = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<String> _getAuthCode() async {
    try {
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'access_token');
      if (token == null) return 'DEMO-AUTH-CODE';

      final response = await CustomHttpClient().post(
        Uri.parse(ApiConfig.generateAuthCode),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        if (jsonResp['success'] == true && jsonResp['auth_code'] != null) {
          return jsonResp['auth_code'];
        }
      }
    } catch (e) {
      debugPrint('Error getting auth code: $e');
    }
    return 'DEMO-AUTH-CODE';
  }

  Future<void> _authenticateAndLink() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          try {
            // 1. Xác minh mã PIN trước
            const secureStorage = FlutterSecureStorage();
            final token = await secureStorage.read(key: 'access_token');
            if (token == null) return "Lỗi: Không tìm thấy phiên đăng nhập";

            final pinRes = await CustomHttpClient().post(
              Uri.parse(ApiConfig.verifyPin),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'ngrok-skip-browser-warning': 'true',
              },
              body: jsonEncode({'pin': pin}),
            );

            if (pinRes.statusCode != 200) {
              final data = jsonDecode(pinRes.body);
              return data['error'] ?? "Mã PIN không chính xác";
            }

            // 2. Lấy mã Auth_Code từ Backend nếu PIN đúng
            String authCode = await _getAuthCode();
            
            // 3. Trả về app merchant với auth_code thông qua Deep Link
            final uri = Uri.parse('tiktokshop://link-result?status=success&auth_code=$authCode');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            
            if (mounted) {
              Navigator.pop(context); // Đóng màn hình liên kết
            }
            return null; // null nghĩa là thành công
          } catch (e) {
            return "Có lỗi xảy ra: $e";
          }
        },
      ),
    );
  }

  Future<void> _cancelLink() async {
    final uri = Uri.parse('tiktokshop://link-result?status=failed');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: _cancelLink,
        ),
        title: const Text('Xác nhận liên kết dịch vụ', style: TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Icon merchants and Mio
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.link, color: Colors.grey, size: 30),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Liên kết Ví Mio với ${widget.merchantName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Bằng việc xác nhận, bạn cho phép nền tảng đối tác tự động thanh toán các giao dịch từ nguồn tiền của Ví Mio mà không cần nhập lại OTP hay Mật khẩu cho các lần sau.',
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateAndLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Xác nhận liên kết', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: _isLoading ? null : _cancelLink,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('Hủy bỏ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

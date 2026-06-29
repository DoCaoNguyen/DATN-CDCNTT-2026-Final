import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/custom_http_client.dart';
import 'dart:convert';
import '../../../core/constants/api_config.dart';
import 'package:url_launcher/url_launcher.dart';

class DeepLinkAccountLinkScreen extends StatefulWidget {
  final String merchantName;

  const DeepLinkAccountLinkScreen({
    super.key,
    required this.merchantName,
  });

  @override
  State<DeepLinkAccountLinkScreen> createState() => _DeepLinkAccountLinkScreenState();
}

class _DeepLinkAccountLinkScreenState extends State<DeepLinkAccountLinkScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _passwordController = TextEditingController();
  bool _isAuthenticating = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateBiometric();
    });
  }

  Future<void> _authenticateBiometric() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Xác thực để liên kết tài khoản',
      );
    } catch (e) {
      debugPrint("Biometric auth error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }

    if (authenticated) {
      _returnToMerchant(true);
    }
  }

  Future<void> _authenticatePassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mật khẩu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone') ?? '';

      final client = CustomHttpClient();
      final response = await client.post(
        Uri.parse(ApiConfig.login),
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        _returnToMerchant(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu không chính xác')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã có lỗi xảy ra')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _returnToMerchant(bool success) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone') ?? '';
    // Xử lý che số điện thoại (ví dụ: *******089)
    String maskedPhone = phone.length >= 4 
      ? '*******${phone.substring(phone.length - 3)}' 
      : '*******';

    final status = success ? 'success' : 'failed';
    final url = Uri.parse('tiktokshop://link-result?status=$status&phone=$maskedPhone');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) {
        Navigator.pop(context); // Quay lại hoặc đóng
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở lại ứng dụng đối tác.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực liên kết'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _returnToMerchant(false), // Hủy liên kết
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.link, size: 64, color: AppColors.primaryPink),
            ),
            const SizedBox(height: 24),
            Text(
              'Yêu cầu liên kết tài khoản từ ${widget.merchantName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu ví Mio',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _authenticatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Xác nhận mật khẩu', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _isAuthenticating ? null : _authenticateBiometric,
              icon: const Icon(Icons.fingerprint, size: 24),
              label: const Text('Sử dụng vân tay / FaceID'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryPink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

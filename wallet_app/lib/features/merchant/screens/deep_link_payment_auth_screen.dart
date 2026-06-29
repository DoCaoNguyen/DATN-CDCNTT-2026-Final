import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'deep_link_payment_confirm_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/custom_http_client.dart';
import 'dart:convert';
import '../../../core/constants/api_config.dart';

class DeepLinkPaymentAuthScreen extends StatefulWidget {
  final String qrToken;
  final String? amount;
  final String? description;

  const DeepLinkPaymentAuthScreen({
    super.key,
    required this.qrToken,
    this.amount,
    this.description,
  });

  @override
  State<DeepLinkPaymentAuthScreen> createState() => _DeepLinkPaymentAuthScreenState();
}

class _DeepLinkPaymentAuthScreenState extends State<DeepLinkPaymentAuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _passwordController = TextEditingController();
  bool _isAuthenticating = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Tự động yêu cầu sinh trắc học khi mở màn hình
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
        localizedReason: 'Xác thực để tiếp tục thanh toán',
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
      _navigateToConfirm();
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
        _navigateToConfirm();
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

  void _navigateToConfirm() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DeepLinkPaymentConfirmScreen(
          qrToken: widget.qrToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực thanh toán'),
        backgroundColor: Colors.white,
        elevation: 0,
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
              child: Icon(Icons.security, size: 64, color: AppColors.primaryPink),
            ),
            const SizedBox(height: 24),
            const Text(
              'Yêu cầu thanh toán từ TikTok Shop',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

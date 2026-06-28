import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_state.dart';
import '../../../../core/constants/api_config.dart';
import '../../../home/screens/home_screen.dart';
import '../../../../core/services/socket_service.dart';
import '../../forgot_password/screens/forgot_password_face_auth_screen.dart';

class LoginPasswordScreen extends StatefulWidget {
  final String phoneNumber;

  const LoginPasswordScreen({Key? key, required this.phoneNumber})
    : super(key: key);

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  late final TextEditingController _passwordController;

  bool _isPasswordComplete = false;
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _passwordController.addListener(() {
      setState(() {
        _isPasswordComplete = _passwordController.text.length >= 6;
        if (_errorMessage != null && _passwordController.text.isNotEmpty) {
          _errorMessage = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': widget.phoneNumber,
          'password': _passwordController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = jsonDecode(response.body);

      // 1. ĐĂNG NHẬP THÀNH CÔNG -> VÀO TRANG HOME
      if (response.statusCode == 200) {
        var userInfo =
            responseData['user_info'] ?? responseData['data']['user_info'];

        // --- BỔ SUNG: Lấy token do Backend trả về ---
        String token =
            responseData['access_token'] ??
            responseData['data']['access_token'] ??
            '';
        String refreshToken =
            responseData['refresh_token'] ??
            responseData['data']['refresh_token'] ??
            '';

        String userId = userInfo['id'] ?? '';
        bool isVerified = userInfo['is_kyc_verified'] == true;

        // Lưu thông tin đăng nhập tự động
        final secureStorage = const FlutterSecureStorage();
        await secureStorage.write(key: 'access_token', value: token);
        if (refreshToken.isNotEmpty) {
          await secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        await prefs.setBool('is_verified', isVerified);

        // Kết nối Socket.io
        SocketService().connectSocket(token);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userId: userId,
                isVerified: isVerified,
                token: token, // <--- TRUYỀN TOKEN SANG TRANG HOME
              ),
            ),
            (route) => false,
          );
        }
      } else if (response.statusCode == 403) {
        String errorMsg =
            responseData['error'] ??
            'Tài khoản đã bị khóa 30 phút do nhập sai quá nhiều lần.';
        _showLockDialog(errorMsg);
      } else {
        setState(() {
          _errorMessage = responseData['error'] ?? 'Mật khẩu không chính xác';
          _passwordController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi kết nối máy chủ. Vui lòng kiểm tra lại mạng!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLockDialog(String message) {
    String activeLang = AppState.currentLanguage.value;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  activeLang == 'VIE' ? 'Tài khoản bị khóa' : 'Account Locked',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      activeLang == 'VIE' ? 'Đã hiểu' : 'Understood',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.currentLanguage,
      builder: (context, activeLang, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Center(
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textDark,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              activeLang == 'VIE' ? 'Nhập mật khẩu' : 'Enter Password',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            titleSpacing: 12,
          ),
          body: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: activeLang == 'VIE'
                                        ? 'Mật khẩu '
                                        : 'Password ',
                                    style: const TextStyle(
                                      color: AppColors.primaryPink,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 34,
                                      fontFamily: 'cursive',
                                    ),
                                  ),
                                  TextSpan(
                                    text: activeLang == 'VIE'
                                        ? 'của bạn'
                                        : 'of yours',
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
                                children: [
                                  TextSpan(
                                    text: activeLang == 'VIE'
                                        ? 'Số ví: '
                                        : 'Wallet: ',
                                  ),
                                  TextSpan(
                                    text: widget
                                        .phoneNumber, // ĐÃ SỬA: CHỈ HIỆN SĐT
                                    style: const TextStyle(
                                      color: AppColors.primaryPink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _errorMessage != null
                                      ? Colors.red
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscureText,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  maxLength: 6,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _errorMessage != null
                                        ? Colors.red
                                        : AppColors.textDark,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                    hintText: activeLang == 'VIE'
                                        ? 'Mật khẩu 6 số'
                                        : '6-digit password',
                                    hintStyle: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 16,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: AppColors.textLight,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),

                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ForgotPasswordFaceAuthScreen(
                                            phone: widget.phoneNumber,
                                          ),
                                    ),
                                  );
                                },
                                child: Text(
                                  activeLang == 'VIE'
                                      ? 'Quên mật khẩu?'
                                      : 'Forgot password?',
                                  style: const TextStyle(
                                    color: Color(0xFF1E88E5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.support_agent_rounded,
                                  color: AppColors.primaryPink,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  activeLang == 'VIE' ? 'Hỗ trợ' : 'Support',
                                  style: const TextStyle(
                                    color: AppColors.primaryPink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (_isPasswordComplete && !_isLoading)
                                  ? _handleConfirm
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isPasswordComplete
                                    ? AppColors.primaryPink
                                    : const Color(0xFFE0E0E0),
                                disabledBackgroundColor: const Color(
                                  0xFFE0E0E0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      activeLang == 'VIE'
                                          ? 'Xác nhận'
                                          : 'Confirm',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _isPasswordComplete
                                            ? Colors.white
                                            : AppColors.textLight,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

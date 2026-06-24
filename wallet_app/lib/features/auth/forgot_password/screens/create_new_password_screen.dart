import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_state.dart';
import '../../../../core/constants/api_config.dart';
import '../../login/screens/login_phone_screen.dart';
import '../../../../core/utils/snackbar_utils.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String phoneNumber;
  final String registerToken;

  const CreateNewPasswordScreen({
    Key? key,
    required this.phoneNumber,
    required this.registerToken,
  }) : super(key: key);

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validateInputs);
    _confirmPasswordController.addListener(_validateInputs);
  }

  void _validateInputs() {
    setState(() {
      _isButtonEnabled =
          _passwordController.text.length == 6 &&
          _confirmPasswordController.text.length == 6 &&
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitPassword() async {
    setState(() {
      _isLoading = true;
    });

    String newPassword = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'register_token': widget.registerToken,
          'new_password': newPassword,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        SnackbarUtils.showSuccess(
          context,
          'Đặt lại mật khẩu thành công! Vui lòng đăng nhập.',
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LoginPhoneScreen(initialPhoneNumber: widget.phoneNumber),
          ),
          (route) => false,
        );
      } else {
        String errorMsg =
            responseData['error'] ?? 'Có lỗi xảy ra, vui lòng thử lại';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi kết nối máy chủ. Vui lòng thử lại!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.currentLanguage,
      builder: (context, activeLang, child) {
        return Scaffold(
          backgroundColor: Colors
              .white, // Chuyển nền tổng thành trắng để gradient nổi bật hơn
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
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
              activeLang == 'VIE' ? 'Đặt lại mật khẩu' : 'Reset Password',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            titleSpacing: 12,
          ),
          // Bọc body để AppBar đè lên phần nền Gradient
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // 1. HIỆU ỨNG GRADIENT XANH NHẠT Ở TRÊN CÙNG
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 280, // Độ dài của dải màu đổ xuống
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFD6F0FF), // Màu xanh dương nhạt ở đỉnh
                        Colors.white.withValues(
                          alpha: 0.0,
                        ), // Mờ dần thành trong suốt ở dưới
                      ],
                    ),
                  ),
                ),
              ),

              // 2. BACKGROUND MÀU XANH LÁ BÊN DƯỚI CÙNG
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

              // 3. NỘI DUNG CHÍNH
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),

                              // CHỮ "TẠO MẬT KHẨU" MÀU HỒNG & IN NGHIÊNG
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: activeLang == 'VIE'
                                          ? 'Mật khẩu mới '
                                          : 'New password ',
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
                                          : 'setup',
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
                                          : 'Wallet number: ',
                                    ),
                                    TextSpan(
                                      text: widget.phoneNumber,
                                      style: const TextStyle(
                                        color: AppColors.primaryPink,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Ô NHẬP MẬT KHẨU
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    letterSpacing: 8.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    hintText: activeLang == 'VIE'
                                        ? 'Nhập mật khẩu mới 6 số'
                                        : 'Enter 6-digit new password',
                                    hintStyle: const TextStyle(
                                      fontSize: 16,
                                      letterSpacing: 0,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Ô XÁC NHẬN MẬT KHẨU
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    letterSpacing: 8.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    hintText: activeLang == 'VIE'
                                        ? 'Xác nhận mật khẩu'
                                        : 'Confirm password',
                                    hintStyle: const TextStyle(
                                      fontSize: 16,
                                      letterSpacing: 0,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),

                              if (_confirmPasswordController.text.length == 6 &&
                                  _passwordController.text !=
                                      _confirmPasswordController.text)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    activeLang == 'VIE'
                                        ? 'Mật khẩu không khớp'
                                        : 'Passwords do not match',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                              onPressed: (_isButtonEnabled && !_isLoading)
                                  ? _submitPassword
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isButtonEnabled
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
                                        color: _isButtonEnabled
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

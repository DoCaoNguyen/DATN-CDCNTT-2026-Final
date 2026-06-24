import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_state.dart';
import '../widgets/phone_input_field.dart';
import '../../register/screens/otp_verification_screen.dart';
import 'login_password_screen.dart';

class LoginPhoneScreen extends StatefulWidget {
  final String? initialPhoneNumber;

  const LoginPhoneScreen({Key? key, this.initialPhoneNumber}) : super(key: key);

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhoneNumber != null) {
      _phoneController.text = widget.initialPhoneNumber!;
    }
    _phoneController.addListener(() {
      if (_hasError) {
        setState(() {
          _hasError = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkAndProcessPhone(String phone, String lang) async {
    bool isDialogClosed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      ),
    ).then((_) => isDialogClosed = true);

    try {
      final String apiUrl = ApiConfig.checkPhone;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      if (!isDialogClosed && mounted) {
        Navigator.pop(context);
        isDialogClosed = true;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isExist'] == true) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPasswordScreen(phoneNumber: phone),
              ),
            );
          }
        } else {
          _showConfirmationDialog(phone, lang);
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorSnackBar(
          errorData['error'] ??
              (lang == 'VIE' ? 'Có lỗi xảy ra!' : 'An error occurred!'),
        );
      }
    } catch (e) {
      if (!isDialogClosed && mounted) {
        Navigator.pop(context);
        isDialogClosed = true;
      }
      _showErrorSnackBar(
        lang == 'VIE'
            ? 'Không thể kết nối đến Server'
            : 'Cannot connect to Server',
      );
      debugPrint('Lỗi gọi API: $e');
    }
  }

  Future<void> _sendOtpForRegistration(String phone, String lang) async {
    bool isDialogClosed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      ),
    ).then((_) => isDialogClosed = true);

    try {
      final String apiUrl = ApiConfig.sendOtp;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': '$phone@wallet.com', 'phone': phone}),
      );

      if (!isDialogClosed && mounted) {
        Navigator.pop(context);
        isDialogClosed = true;
      }

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(phoneNumber: phone),
            ),
          );
        }
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        _showLockDialog(
          errorData['error'] ??
              (lang == 'VIE'
                  ? 'Số điện thoại này đang bị khóa. Vui lòng thử lại sau.'
                  : 'This phone number is locked. Please try again later.'),
        );
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorSnackBar(
          errorData['error'] ??
              (lang == 'VIE' ? 'Có lỗi xảy ra!' : 'An error occurred!'),
        );
      }
    } catch (e) {
      if (!isDialogClosed && mounted) {
        Navigator.pop(context);
        isDialogClosed = true;
      }
      _showErrorSnackBar(
        lang == 'VIE'
            ? 'Không thể kết nối đến Server'
            : 'Cannot connect to Server',
      );
      debugPrint('Lỗi gọi API sendOtp: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLockDialog(String message) {
    String activeLang = AppState.currentLanguage.value;

    showDialog(
      context: context,
      barrierDismissible: true,
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

  void _showConfirmationDialog(String phone, String activeLang) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      color: Colors.pink.shade50,
                      child: const Center(
                        child: Icon(
                          Icons.security_rounded,
                          size: 60,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          activeLang == 'VIE'
                              ? 'Đăng ký với $phone'
                              : 'Register with $phone',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activeLang == 'VIE'
                              ? 'Mã xác thực để đăng ký đã được gửi về số điện thoại trên qua tin nhắn SMS.'
                              : 'The verification code for registration has been sent to the above phone number via SMS.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  activeLang == 'VIE' ? 'Đổi SĐT' : 'Change',
                                  style: const TextStyle(
                                    color: AppColors.primaryPink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _sendOtpForRegistration(phone, activeLang);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPink,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  activeLang == 'VIE' ? 'Xác nhận' : 'Confirm',
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
                      ],
                    ),
                  ),
                ],
              ),

              Positioned(
                top: -10,
                right: -10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.textDark,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleContinue(String activeLang) {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    _checkAndProcessPhone(phone, activeLang);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: ValueListenableBuilder<String>(
        valueListenable: AppState.currentLanguage,
        builder: (context, activeLang, child) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                activeLang == 'VIE' ? 'Nhập SĐT' : 'Enter Phone',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
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
                        child: Padding(
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
                                          ? 'Số điện thoại '
                                          : 'Phone number ',
                                      // ĐÃ SỬA: ĐỒNG BỘ FONT CURSIVE SIZE 34
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
                              const SizedBox(height: 30),
                              PhoneInputField(
                                controller: _phoneController,
                                hasError: _hasError,
                                activeLang: activeLang,
                              ),
                              if (_hasError) ...[
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        activeLang == 'VIE'
                                            ? 'Số điện thoại bạn vừa nhập không hợp lệ. Vui lòng kiểm tra lại'
                                            : 'The phone number you entered is invalid. Please check again.',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Expanded(child: SizedBox()),

                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildLangBtn('VIE', activeLang == 'VIE'),
                                      _buildLangBtn('ENG', activeLang == 'ENG'),
                                    ],
                                  ),
                                ),

                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: Column(
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
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            activeLang == 'VIE'
                                                ? 'Hỗ trợ'
                                                : 'Support',
                                            style: const TextStyle(
                                              color: AppColors.primaryPink,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
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
                                onPressed: () => _handleContinue(activeLang),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPink,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  activeLang == 'VIE' ? 'Tiếp tục' : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
      ),
    );
  }

  Widget _buildLangBtn(String text, bool isActive) {
    return GestureDetector(
      onTap: () {
        AppState.currentLanguage.value = text;
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryPink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

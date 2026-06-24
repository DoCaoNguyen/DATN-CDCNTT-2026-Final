import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_state.dart';
import '../../../../core/constants/api_config.dart';
import 'create_password_screen.dart';
import '../../../../core/utils/snackbar_utils.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({Key? key, required this.phoneNumber})
    : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  int _start = 30;
  Timer? _timer;

  // --- BIẾN ĐẾM NGƯỢC KHÓA TÀI KHOẢN (1 PHÚT) ---
  int _lockCountdown = 0;
  Timer? _lockTimer;

  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  int _remainingAttempts = 5;
  bool _hasError = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    for (var controller in _controllers) {
      controller.addListener(() {
        if (_hasError && controller.text.isNotEmpty) {
          setState(() {
            _hasError = false;
          });
        }
      });
    }
  }

  // Timer cho nút Gửi lại mã
  void startTimer() {
    _start = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // --- HÀM BẮT ĐẦU ĐẾM NGƯỢC KHÓA 1 PHÚT ---
  void _startLockCountdown() {
    setState(() {
      _lockCountdown = 60; // 60 giây = 1 phút
      _hasError = false; // Ẩn cái lỗi "Sai OTP" đi để ưu tiên hiện lỗi Khóa
      for (var c in _controllers) {
        c.clear(); // Xóa sạch chữ khi bị khóa
      }
      FocusScope.of(context).unfocus(); // Hạ bàn phím xuống
    });

    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockCountdown <= 0) {
        timer.cancel();
        setState(() {
          _remainingAttempts = 5; // Reset lại 5 lần thử khi hết hạn khóa
        });
      } else {
        setState(() {
          _lockCountdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lockTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _isOtpComplete {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  // --- HÀM 1: GỌI API XÁC THỰC OTP ---
  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    String otp = _controllers.map((c) => c.text).join();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': widget.phoneNumber, 'otp': otp}),
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        String token = responseData['register_token'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreatePasswordScreen(
              phoneNumber: widget.phoneNumber,
              registerToken: token,
            ),
          ),
        );
      }
      // XỬ LÝ LỖI 403: BẮT ĐẦU ĐẾM NGƯỢC KHÓA MÁY
      else if (response.statusCode == 403) {
        _startLockCountdown();
      } else {
        String errorMsg = responseData['error'] ?? 'Xác thực thất bại';
        int remaining =
            responseData['remainingAttempts'] ?? (_remainingAttempts - 1);

        setState(() {
          _hasError = true;
          _remainingAttempts = remaining;
          for (var c in _controllers) c.clear();
          FocusScope.of(context).requestFocus(_focusNodes[0]);
        });

        if (!errorMsg.contains('không chính xác') &&
            !errorMsg.contains('Invalid')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
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

  // --- HÀM 2: GỌI API GỬI LẠI MÃ ---
  Future<void> _resendOtp() async {
    // Hiện Loading mờ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':
              '${widget.phoneNumber}@wallet.com', // Dùng email giả để qua được Validate như lúc Đăng ký
          'phone': widget.phoneNumber,
        }),
      );

      Navigator.pop(context); // Đóng Loading

      if (response.statusCode == 200) {
        startTimer(); // Khởi động lại đồng hồ 54 giây
        SnackbarUtils.showSuccess(context, 'Đã gửi lại mã OTP mới qua SMS');
      } else if (response.statusCode == 403) {
        // Nếu vừa bấm gửi mà bị báo 403 (tức là đang trong 1 phút khóa) -> Cập nhật UI khóa luôn
        _startLockCountdown();
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['error'] ?? 'Không thể gửi lại mã'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi kết nối. Vui lòng thử lại!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBackDialog(String activeLang) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeLang == 'VIE'
                      ? 'Thay đổi số điện thoại'
                      : 'Change phone number',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  activeLang == 'VIE'
                      ? 'Bạn có chắc muốn thay đổi số điện thoại của bạn?'
                      : 'Are you sure you want to change your phone number?',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          activeLang == 'VIE' ? 'Huỷ' : 'Cancel',
                          style: const TextStyle(
                            color: AppColors.primaryPink,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          activeLang == 'VIE' ? 'Đồng ý' : 'Agree',
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.currentLanguage,
      builder: (context, activeLang, child) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (didPop) return;
            _showBackDialog(activeLang);
          },
          child: Scaffold(
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
                    onTap: () => _showBackDialog(activeLang),
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
                activeLang == 'VIE' ? 'Xác thực OTP' : 'OTP Verification',
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: activeLang == 'VIE'
                                          ? 'Xác thực OTP '
                                          : 'OTP Verification ',
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
                                          : 'for you',
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                    height: 1.5,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: activeLang == 'VIE'
                                          ? 'Hệ thống cung cấp mã OTP sẽ được gọi đến số\n'
                                          : 'An OTP code will be sent via SMS to the number\n',
                                    ),
                                    TextSpan(
                                      text: widget.phoneNumber.isEmpty
                                          ? '0383255941'
                                          : widget.phoneNumber,
                                      style: const TextStyle(
                                        color: AppColors.primaryPink,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (index) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      // Viền đỏ nếu có lỗi sai OTP hoặc đang bị Khóa máy
                                      border: Border.all(
                                        color: (_hasError || _lockCountdown > 0)
                                            ? Colors.red
                                            : AppColors.border,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                    ),
                                    child: TextField(
                                      controller: _controllers[index],
                                      focusNode: _focusNodes[index],
                                      readOnly:
                                          _lockCountdown >
                                          0, // Chặn nhập liệu khi bị khóa
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: (_hasError || _lockCountdown > 0)
                                            ? Colors.red
                                            : AppColors.textDark,
                                      ),
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        border: InputBorder.none,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          if (index < 3)
                                            FocusScope.of(context).requestFocus(
                                              _focusNodes[index + 1],
                                            );
                                          else
                                            FocusScope.of(context).unfocus();
                                        } else {
                                          if (index > 0)
                                            FocusScope.of(context).requestFocus(
                                              _focusNodes[index - 1],
                                            );
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 16),

                              // --- HIỂN THỊ DÒNG LỖI HOẶC ĐẾM NGƯỢC KHÓA MÁY ---
                              if (_lockCountdown > 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    bottom: 8.0,
                                  ),
                                  child: Text(
                                    activeLang == 'VIE'
                                        ? 'Tài khoản bị khóa. Thử lại sau ${_lockCountdown}s'
                                        : 'Account locked. Try again in ${_lockCountdown}s',
                                    style: const TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else if (_hasError)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    bottom: 8.0,
                                  ),
                                  child: Text(
                                    activeLang == 'VIE'
                                        ? 'Mã xác thực không đúng, bạn còn $_remainingAttempts lần thử.'
                                        : 'Invalid OTP, you have $_remainingAttempts attempts left.',
                                    style: const TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Gắn GestureDetector để gọi hàm _resendOtp
                              GestureDetector(
                                onTap: (_start == 0 && _lockCountdown == 0)
                                    ? _resendOtp
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.sync_rounded,
                                        size: 16,
                                        color:
                                            _start == 0 && _lockCountdown == 0
                                            ? AppColors.primaryPink
                                            : AppColors.textLight,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _start > 0
                                            ? (activeLang == 'VIE'
                                                  ? 'Gửi lại mã ($_start)'
                                                  : 'Resend code ($_start)')
                                            : (activeLang == 'VIE'
                                                  ? 'Gửi lại mã'
                                                  : 'Resend code'),
                                        style: TextStyle(
                                          color:
                                              _start == 0 && _lockCountdown == 0
                                              ? AppColors.primaryPink
                                              : AppColors.textLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
                                // Nút xác nhận bị Vô hiệu hóa nếu đang trong thời gian đếm ngược khóa máy
                                onPressed:
                                    (_isOtpComplete &&
                                        !_isLoading &&
                                        _remainingAttempts > 0 &&
                                        _lockCountdown == 0)
                                    ? _verifyOtp
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (_isOtpComplete && _lockCountdown == 0)
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
                                          color:
                                              (_isOtpComplete &&
                                                  _lockCountdown == 0)
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
          ),
        );
      },
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/services/custom_http_client.dart';
import '../../login/screens/login_phone_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/snackbar_utils.dart';

class CreateNewPinScreen extends StatefulWidget {
  const CreateNewPinScreen({Key? key}) : super(key: key);

  @override
  State<CreateNewPinScreen> createState() => _CreateNewPinScreenState();
}

class _CreateNewPinScreenState extends State<CreateNewPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _isButtonEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_validateInputs);
    _confirmPinController.addListener(_validateInputs);
  }

  void _validateInputs() {
    setState(() {
      _isButtonEnabled =
          _pinController.text.length == 6 &&
          _confirmPinController.text.length == 6 &&
          _pinController.text == _confirmPinController.text;
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = CustomHttpClient();
      final response = await client.post(
        Uri.parse(ApiConfig.setWalletCode),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': _pinController.text}),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        SnackbarUtils.showSuccess(
          context,
          'Đặt lại mã PIN thành công! Vui lòng đăng nhập lại.',
        );

        // Log out user
        const storage = FlutterSecureStorage();
        await storage.deleteAll();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
          (route) => false,
        );
      } else {
        final data = jsonDecode(response.body);
        String errorMsg = data['error'] ?? 'Có lỗi xảy ra, vui lòng thử lại';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đặt lại mã PIN',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Tạo mã PIN mới',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mã PIN gồm 6 chữ số dùng để xác thực các giao dịch trên Ví.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 40),

                      // Ô NHẬP PIN
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            hintText: 'Nhập mã PIN 6 số',
                            hintStyle: TextStyle(
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

                      const SizedBox(height: 24),

                      // Ô XÁC NHẬN PIN
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _confirmPinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            hintText: 'Xác nhận mã PIN',
                            hintStyle: TextStyle(
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

                      if (_confirmPinController.text.length == 6 &&
                          _pinController.text != _confirmPinController.text)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Mã PIN không khớp',
                            style: TextStyle(
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isButtonEnabled && !_isLoading)
                        ? _submitPin
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isButtonEnabled
                          ? AppColors.primaryPink
                          : const Color(0xFFE0E0E0),
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
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
                            'Xác nhận',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

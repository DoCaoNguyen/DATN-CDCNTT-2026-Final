import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/services/custom_http_client.dart';
import '../../auth/forgot_pin/screens/forgot_pin_face_auth_screen.dart';
import '../../../core/utils/snackbar_utils.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({Key? key}) : super(key: key);

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  int _step = 1;
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmNewPinController =
      TextEditingController();

  bool _isCurrentPinObscured = true;
  bool _isNewPinObscured = true;
  bool _isConfirmNewPinObscured = true;

  bool _isLoading = false;
  bool _isStep1ButtonEnabled = false;
  bool _isStep2ButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentPinController.addListener(_validateStep1);
    _newPinController.addListener(_validateStep2);
    _confirmNewPinController.addListener(_validateStep2);
  }

  void _validateStep1() {
    setState(() {
      _isStep1ButtonEnabled = _currentPinController.text.length == 6;
    });
  }

  void _validateStep2() {
    setState(() {
      _isStep2ButtonEnabled =
          _newPinController.text.length == 6 &&
          _confirmNewPinController.text.length == 6 &&
          _newPinController.text == _confirmNewPinController.text &&
          _newPinController.text != _currentPinController.text;
    });
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmNewPinController.dispose();
    super.dispose();
  }

  Future<void> _verifyCurrentPin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = CustomHttpClient();
      final response = await client.post(
        Uri.parse(ApiConfig.verifyPin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': _currentPinController.text}),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _step = 2;
        });
      } else {
        final data = jsonDecode(response.body);
        String errorMsg = data['error'] ?? 'Mã PIN hiện tại không chính xác';
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

  Future<void> _changePin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = CustomHttpClient();
      final response = await client.post(
        Uri.parse(ApiConfig.setWalletCode),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'wallet_code': _newPinController.text}),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        SnackbarUtils.showSuccess(context, 'Thay đổi mã PIN thành công!');
        if (!mounted) return;
        Navigator.pop(context);
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () {
            if (_step == 2) {
              setState(() {
                _step = 1;
                _currentPinController.clear();
                _newPinController.clear();
                _confirmNewPinController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Thay đổi mã PIN',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _step == 1 ? _buildStep1() : _buildStep2(),
                ),
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nhập mật khẩu hiện tại',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _currentPinController,
          obscureText: _isCurrentPinObscured,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 16, letterSpacing: 4),
          decoration: InputDecoration(
            labelText: 'Mật khẩu hiện tại',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryPink),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryPink,
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isCurrentPinObscured ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isCurrentPinObscured = !_isCurrentPinObscured;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ForgotPinFaceAuthScreen(),
              ),
            );
          },
          child: const Text(
            'Quên mật khẩu?',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nhập mật khẩu mới',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newPinController,
          obscureText: _isNewPinObscured,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 16, letterSpacing: 4),
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryPink),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryPink,
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isNewPinObscured ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isNewPinObscured = !_isNewPinObscured;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmNewPinController,
          obscureText: _isConfirmNewPinObscured,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 16, letterSpacing: 4),
          decoration: InputDecoration(
            labelText: 'Nhắc lại mật khẩu',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryPink),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryPink,
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmNewPinObscured
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmNewPinObscured = !_isConfirmNewPinObscured;
                });
              },
            ),
          ),
        ),
        if (_confirmNewPinController.text.isNotEmpty &&
            _newPinController.text != _confirmNewPinController.text)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Mật khẩu không khớp',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (_newPinController.text.length == 6 &&
            _newPinController.text == _currentPinController.text)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Mật khẩu mới không được trùng với mật khẩu hiện tại',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomButton() {
    bool isEnabled = _step == 1 ? _isStep1ButtonEnabled : _isStep2ButtonEnabled;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: (isEnabled && !_isLoading)
              ? (_step == 1 ? _verifyCurrentPin : _changePin)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled
                ? AppColors.primaryPink
                : const Color(0xFFE0E0E0),
            disabledBackgroundColor: const Color(0xFFE0E0E0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
                  'Tiếp tục',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? Colors.white : AppColors.textLight,
                  ),
                ),
        ),
      ),
    );
  }
}

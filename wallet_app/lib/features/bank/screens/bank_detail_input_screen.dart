import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart'; // To reuse PinConfirmBottomSheet
import 'bank_link_success_screen.dart';

class BankDetailInputScreen extends StatefulWidget {
  final String token;
  final String bankName;
  final String bankCode;
  final String? prefilledCardNumber;

  const BankDetailInputScreen({
    Key? key,
    required this.token,
    required this.bankName,
    required this.bankCode,
    this.prefilledCardNumber,
  }) : super(key: key);

  @override
  State<BankDetailInputScreen> createState() => _BankDetailInputScreenState();
}

class _BankDetailInputScreenState extends State<BankDetailInputScreen> {
  final _client = CustomHttpClient();
  final TextEditingController _accountNumberController =
      TextEditingController();
  String _cardHolderName = "PHAN VAN THONG";
  String _cccd = "Đang tải...";
  bool _isLoading = false;
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCardNumber != null) {
      _accountNumberController.text = widget.prefilledCardNumber!;
    }
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getMyProfile));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? name = data['data']?['full_name'];
        final String? idNumber = data['data']?['identity_number'];
        setState(() {
          if (name != null && name.isNotEmpty) {
            _cardHolderName = name.toUpperCase();
          }
          if (idNumber != null && idNumber.isNotEmpty) {
            String masked =
                List.generate(
                  idNumber.length > 4 ? idNumber.length - 4 : 0,
                  (index) => '•',
                ).join() +
                (idNumber.length > 4
                    ? idNumber.substring(idNumber.length - 4)
                    : idNumber);
            _cccd = masked;
          } else {
            _cccd = "Chưa cập nhật CCCD";
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile name: $e");
    }
  }

  void _onContinuePressed() {
    setState(() {
      _hasAttemptedSubmit = true;
    });

    if (_accountNumberController.text.trim().isEmpty) {
      return;
    }

    // Show PIN verification bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          return await _executeLinkBank(pin);
        },
      ),
    );
  }

  Future<String?> _executeLinkBank(String pin) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.linkBank),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bank_name': widget.bankName,
          'bank_code': widget.bankCode,
          'card_number': _accountNumberController.text.trim(),
          'card_holder_name': _cardHolderName,
          'pin': pin,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (!mounted) return null;
        Navigator.pop(context); // Close PIN bottom sheet

        // Navigate to Success Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BankLinkSuccessScreen(
              token: widget.token,
              bankName: widget.bankName,
            ),
          ),
        );
        return null;
      } else {
        return responseData['error'] ?? 'Liên kết thất bại. Vui lòng thử lại.';
      }
    } catch (e) {
      debugPrint("Error linking bank: $e");
      return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng!";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAccountEmpty = _accountNumberController.text.trim().isEmpty;
    final bool showError = _hasAttemptedSubmit && isAccountEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.bankName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Section card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Thông tin tại ngân hàng',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'Điều kiện liên kết',
                                    style: TextStyle(
                                      color: Colors.pink,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Field: Số tài khoản
                            const Text(
                              'Số tài khoản',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _accountNumberController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  if (_hasAttemptedSubmit)
                                    _hasAttemptedSubmit = false;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Nhập số tài khoản',
                                errorText: showError
                                    ? 'Quý khách chưa nhập số tài khoản'
                                    : null,
                                errorStyle: const TextStyle(color: Colors.red),
                                suffixIcon: showError
                                    ? const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red,
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: showError
                                        ? Colors.red
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: showError ? Colors.red : Colors.pink,
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Field: Chủ tài khoản
                            const Text(
                              'Chủ tài khoản',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: TextEditingController(
                                text: _cardHolderName,
                              ),
                              enabled: false,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                disabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Field: CCCD
                            const Text(
                              'CCCD',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: TextEditingController(text: _cccd),
                              enabled: false,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                disabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                letterSpacing: 3.0,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info text
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Các thông tin được nhập là thông tin bạn đã đăng ký tại ${widget.bankName} khi mở tài khoản/thẻ.',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Secure label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.security_rounded,
                            color: Colors.pink.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Mọi thông tin của bạn đều được bảo mật theo tiêu chuẩn quốc tế PCI DSS.',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Button Container
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _onContinuePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAccountEmpty
                            ? Colors.grey.shade300
                            : Colors.pink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tiếp tục',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isAccountEmpty
                              ? Colors.grey.shade500
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              ),
            ),
        ],
      ),
    );
  }
}

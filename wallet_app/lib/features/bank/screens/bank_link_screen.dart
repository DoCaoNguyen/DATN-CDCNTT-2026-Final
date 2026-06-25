import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart'; // To reuse PinConfirmBottomSheet
import 'bank_list_screen.dart';
import 'bank_detail_input_screen.dart';
import 'bank_link_success_screen.dart';

class BankLinkScreen extends StatefulWidget {
  final String token;

  const BankLinkScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<BankLinkScreen> createState() => _BankLinkScreenState();
}

class _BankLinkScreenState extends State<BankLinkScreen> {
  final _client = CustomHttpClient();
  bool _isLoading = false;
  Set<String> _linkedBankCodes = {};

  @override
  void initState() {
    super.initState();
    _fetchLinkedBanks();
  }

  Future<void> _fetchLinkedBanks() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getLinkedBanks));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            final banks = data['data'] as List<dynamic>? ?? [];
            _linkedBankCodes = banks
                .map((b) => b['bank_code'].toString())
                .toSet();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching linked banks: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Calls API to fetch current wallet_code to use as the card/account number for quick-linking
  Future<String?> _fetchWalletCode() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getWalletBalance));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['wallet_code'];
      }
    } catch (e) {
      debugPrint("Error fetching wallet code: $e");
    }
    return null;
  }

  Future<void> _checkAndLinkBank(
    String bankName,
    String bankCode,
    String schemeUrl,
  ) async {
    setState(() => _isLoading = true);
    final String? walletCode = await _fetchWalletCode();
    setState(() => _isLoading = false);

    if (walletCode == null || walletCode.isEmpty) {
      _showErrorSnackBar(
        "Vui lòng thiết lập mã ví ở màn hình chính trước khi liên kết ngân hàng!",
      );
      return;
    }

    final Uri scheme = Uri.parse(schemeUrl);
    bool isInstalled = false;
    try {
      isInstalled = await canLaunchUrl(scheme);
    } catch (e) {
      debugPrint("App check failed: $e");
    }

    if (isInstalled) {
      // Case 1: Bank App is installed -> open it
      try {
        await launchUrl(scheme);
      } catch (e) {
        debugPrint("Could not launch scheme: $e");
      }
      // After opening, prompt user to confirm linking in our app
      _showPinPrompt(bankName, bankCode, walletCode);
    } else {
      // Case 2: Bank App is NOT installed -> redirect to input screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BankDetailInputScreen(
            token: widget.token,
            bankName: bankName,
            bankCode: bankCode,
            prefilledCardNumber: walletCode,
          ),
        ),
      );
    }
  }

  void _showPinPrompt(String bankName, String bankCode, String walletCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          return await _executeLinkBank(bankName, bankCode, walletCode, pin);
        },
      ),
    );
  }

  Future<String?> _executeLinkBank(
    String bankName,
    String bankCode,
    String cardNumber,
    String pin,
  ) async {
    try {
      // Mock account holder name (normally fetched from user profile/kyc)
      // Let's call /users/me to get the user's name
      String cardHolderName = "PHAN VAN THONG";
      try {
        final profileRes = await _client.get(Uri.parse(ApiConfig.getMyProfile));
        if (profileRes.statusCode == 200) {
          final profileData = jsonDecode(profileRes.body);
          cardHolderName =
              profileData['data']?['full_name']?.toUpperCase() ??
              cardHolderName;
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
      }

      final response = await _client.post(
        Uri.parse(ApiConfig.linkBank),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bank_name': bankName,
          'bank_code': bankCode,
          'card_number': cardNumber,
          'card_holder_name': cardHolderName,
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
            builder: (_) =>
                BankLinkSuccessScreen(token: widget.token, bankName: bankName),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Liên kết ngân hàng',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Robot & Chat Bubble
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.face_retouching_natural_rounded,
                          color: Colors.pink,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            border: Border.all(
                              color: Colors.pink.shade100,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Liên kết ngân hàng của bạn để thanh toán/chuyển tiền qua Mio.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Featured Bank: Techcombank
                  _buildFeaturedBankCard(
                    bankName: 'Techcombank',
                    bankCode: 'TCB',
                    color: const Color(0xFFE53935),
                    schemeUrl: 'techcombank://',
                  ),
                  const SizedBox(height: 14),

                  // Featured Bank: Vietcombank
                  _buildFeaturedBankCard(
                    bankName: 'Vietcombank',
                    bankCode: 'VCB',
                    color: const Color(0xFF43A047),
                    schemeUrl: 'vietcombankmobile://',
                  ),
                  const SizedBox(height: 24),

                  // Separator "hoặc"
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: Colors.grey, thickness: 0.5),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'hoặc',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: Colors.grey, thickness: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Row: "Tất cả ngân hàng"
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BankListScreen(token: widget.token),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pink.shade50),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.credit_card_rounded,
                              color: Colors.pink,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Tất cả ngân hàng',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          // Small mock bank icons
                          Row(
                            children: [
                              _buildMiniLogo(Colors.blue.shade800, 'M'),
                              const SizedBox(width: 4),
                              _buildMiniLogo(Colors.green, 'V'),
                              const SizedBox(width: 4),
                              _buildMiniLogo(Colors.red, 'T'),
                              const SizedBox(width: 4),
                              _buildMiniLogo(Colors.teal, 'B'),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+3',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.pink,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildMiniLogo(Color color, String letter) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFeaturedBankCard({
    required String bankName,
    required String bankCode,
    required Color color,
    required String schemeUrl,
  }) {
    final isLinked = _linkedBankCodes.contains(bankCode);
    return Opacity(
      opacity: isLinked ? 0.5 : 1.0,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(
                    'https://api.vietqr.io/img/$bankCode.png',
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                bankName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLinked
                  ? null
                  : () => _checkAndLinkBank(bankName, bankCode, schemeUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.grey,
              ),
              child: Text(
                isLinked ? 'Đã liên kết' : 'Liên kết',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

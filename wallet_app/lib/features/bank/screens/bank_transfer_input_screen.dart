import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import 'bank_transfer_confirm_screen.dart';

class BankTransferInputScreen extends StatefulWidget {
  final String token;
  final String bankName;
  final String bankCode;
  final String? prefilledAccountNumber;

  const BankTransferInputScreen({
    Key? key,
    required this.token,
    required this.bankName,
    required this.bankCode,
    this.prefilledAccountNumber,
  }) : super(key: key);

  @override
  State<BankTransferInputScreen> createState() => _BankTransferInputScreenState();
}

class _BankTransferInputScreenState extends State<BankTransferInputScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _senderName = "NGUYEN VAN A"; // fallback default
  bool _isLoadingProfile = false;
  int _rawBalanceInt = 0;
  String _mioBalance = "0đ";

  @override
  void initState() {
    super.initState();
    if (widget.prefilledAccountNumber != null) {
      _accountController.text = widget.prefilledAccountNumber!;
    }
    _fetchSenderProfile();
    _fetchMioBalance();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchMioBalance() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getWalletBalance),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawBalance = data['data']?['available_balance']?.toString() ?? "0";
        if (mounted) {
          setState(() {
            _rawBalanceInt = int.tryParse(rawBalance) ?? 0;
            _mioBalance = _formatAmountValue(rawBalance);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching Mio balance: $e");
    }
  }

  Future<void> _fetchSenderProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getMyProfile),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final name = data['data']?['full_name']?.toString() ?? "NGUYEN VAN A";
        if (mounted) {
          setState(() {
            _senderName = name.toUpperCase();
            // Default note
            _noteController.text = "$_senderName chuyen tien qua MoMo";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _noteController.text = "PHAN VAN THONG chuyen tien qua MoMo";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _noteController.text = "PHAN VAN THONG chuyen tien qua MoMo";
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  String _formatAmountValue(String value) {
    final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (number == null) return "";
    return "${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }

  void _onAmountChanged(String val) {
    String clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      _amountController.text = "";
      setState(() {});
      return;
    }
    final number = int.tryParse(clean);
    if (number != null) {
      String formatted = _formatAmountValue(clean);
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length - 1),
      );
      setState(() {});
    }
  }

  int get _parsedAmount {
    String clean = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  String? get _accountError {
    final text = _accountController.text.trim();
    if (text.isEmpty) return null;
    if (text.length < 10 || text.length > 16) {
      return "Số tài khoản không hợp lệ (Phải từ 10 đến 16 chữ số)";
    }
    return null;
  }

  String? get _amountError {
    if (_amountController.text.isEmpty) return null;
    final amt = _parsedAmount;
    if (amt < 1000) {
      return "Số tiền chuyển tối thiểu là 1.000đ";
    }
    if (amt > _rawBalanceInt) {
      return "Số dư ví không đủ (Số dư hiện tại: $_mioBalance)";
    }
    return null;
  }

  bool get _isValid {
    final text = _accountController.text.trim();
    final isAccountValid = text.length >= 10 && text.length <= 16;
    return isAccountValid && _parsedAmount >= 1000 && _parsedAmount <= _rawBalanceInt;
  }

  void _onContinue() {
    if (!_isValid) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BankTransferConfirmScreen(
          token: widget.token,
          bankName: widget.bankName,
          bankCode: widget.bankCode,
          accountNumber: _accountController.text.trim(),
          amount: _parsedAmount.toString(),
          note: _noteController.text.trim(),
          senderName: _senderName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đến ngân hàng',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Bank information banner (Header in Screen 2)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF006D44),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.bankCode,
                            style: const TextStyle(
                              color: Color(0xFF006D44),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.bankName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Ngân hàng TMCP Ngoại thương Việt Nam',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card/Account Number Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.pink.shade100, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số thẻ/tài khoản *',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _accountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.contact_phone_outlined, color: Colors.pink),
                              onPressed: () {},
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_accountError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _accountError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số tiền chuyển *',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            suffixText: 'đ',
                            suffixStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                          ),
                          onChanged: _onAmountChanged,
                        ),
                      ],
                    ),
                  ),
                  if (_amountError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _amountError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Note Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lời nhắn (${_noteController.text.length}/70)',
                              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _noteController,
                          maxLength: 70,
                          maxLines: null,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            counterText: '',
                          ),
                          onChanged: (val) {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI classification banner
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade50, Colors.pink.shade50],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.purple.shade300, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'AI sẽ tự động phân loại giao dịch này giúp bạn',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.deepPurple, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Terms info text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                        children: [
                          TextSpan(text: 'Dịch vụ thu hộ chi hộ do MoMo hỗ trợ các Ngân hàng đối tác cung cấp. '),
                          TextSpan(
                            text: 'Xem hạn mức và phí',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // Next button container
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isValid ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid ? Colors.pink : Colors.grey.shade200,
                    foregroundColor: _isValid ? Colors.white : Colors.grey.shade400,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tiếp tục',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

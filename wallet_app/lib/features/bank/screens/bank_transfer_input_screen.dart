import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/services/custom_http_client.dart';
import '../../../../core/constants/api_config.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bank_transfer_confirm_screen.dart';

class BankTransferInputScreen extends StatefulWidget {
  final String token;
  final String bankName;
  final String bankCode;
  final String? prefilledAccountNumber;
  final String? cardHolderName;

  const BankTransferInputScreen({
    Key? key,
    required this.token,
    required this.bankName,
    required this.bankCode,
    this.prefilledAccountNumber,
    this.cardHolderName,
  }) : super(key: key);

  @override
  State<BankTransferInputScreen> createState() => _BankTransferInputScreenState();
}

class _BankTransferInputScreenState extends State<BankTransferInputScreen> {
  final _client = CustomHttpClient();
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
    _noteController.text = "${widget.cardHolderName ?? 'PHAN VAN THONG'} chuyen tien qua Mio";
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
      final response = await _client.get(
        Uri.parse(ApiConfig.getWalletBalance),
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
      final response = await _client.get(
        Uri.parse(ApiConfig.getMyProfile),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final name = data['data']?['full_name']?.toString() ?? "NGUYEN VAN A";
        if (mounted) {
          setState(() {
            _senderName = name.toUpperCase();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching sender profile: $e");
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  String _formatAmountValue(String value) {
    final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (number == null) return "";
    return "${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }

  String _convertNumberToVietnameseWords(int number) {
    if (number == 0) return '';
    final units = ['', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'];
    final tens = ['', 'mười', 'hai mươi', 'ba mươi', 'bốn mươi', 'năm mươi', 'sáu mươi', 'bảy mươi', 'tám mươi', 'chín mươi'];
    
    String convertGroup(int n) {
      int h = n ~/ 100;
      int t = (n % 100) ~/ 10;
      int u = n % 10;
      String res = '';
      if (h > 0) {
        res += '${units[h]} trăm ';
      }
      if (t > 0) {
        if (t == 1) {
          res += 'mười ';
        } else {
          res += '${units[t]} mươi ';
        }
      } else if (h > 0 && u > 0) {
        res += 'lẻ ';
      }
      if (u > 0) {
        if (u == 1 && t > 1) {
          res += 'mốt ';
        } else if (u == 5 && t > 0) {
          res += 'lăm ';
        } else {
          res += '${units[u]} ';
        }
      }
      return res.trim();
    }

    final groups = <String>[];
    final scales = ['', 'nghìn', 'triệu', 'tỷ'];
    int temp = number;
    int scaleIdx = 0;
    while (temp > 0) {
      int g = temp % 1000;
      if (g > 0) {
        String gStr = convertGroup(g);
        if (scaleIdx > 0) {
          gStr += ' ${scales[scaleIdx]}';
        }
        groups.insert(0, gStr);
      }
      temp = temp ~/ 1000;
      scaleIdx++;
    }
    
    String result = groups.join(' ').trim();
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1) + ' đồng';
    }
    return result;
  }

  void _onAmountChanged(String val) {
    String clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      _amountController.text = "";
      setState(() {});
      return;
    }
    if (clean.length > 8) {
      clean = clean.substring(0, 8);
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
    if (amt > 50000000) {
      return "Số tiền chuyển tối đa là 50.000.000đ/ngày";
    }
    if (amt > _rawBalanceInt) {
      return "Số dư ví không đủ (Số dư hiện tại: $_mioBalance)";
    }
    return null;
  }

  String getNickname(String name) {
    if (name.isEmpty) return 'ThoongCT';
    final parts = name.trim().split(' ');
    final last = parts.last;
    if (last.isEmpty) return 'ThoongCT';
    String cap = last[0].toUpperCase() + last.substring(1).toLowerCase();
    return '${cap}CT';
  }

  bool get _isValid {
    final text = _accountController.text.trim();
    final isAccountValid = widget.prefilledAccountNumber != null || (text.length >= 8 && text.length <= 19);
    return isAccountValid && _parsedAmount >= 1000 && _parsedAmount <= 50000000 && _parsedAmount <= _rawBalanceInt;
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
          cardHolderName: widget.cardHolderName,
        ),
      ),
    );
  }

  Future<void> _openContacts() async {
    final PermissionStatus permissionStatus = await Permission.contacts.request();
    if (permissionStatus == PermissionStatus.granted) {
      try {
        final Contact? contact = await FlutterContacts.openExternalPick();
        if (contact != null && contact.phones.isNotEmpty) {
          String phone = contact.phones.first.number;
          phone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
          
          setState(() {
            _accountController.text = phone;
          });
        }
      } catch (e) {
        debugPrint("Error picking contact: $e");
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng cấp quyền truy cập danh bạ để sử dụng tính năng này')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.cardHolderName ?? 'PHAN VAN THONG';
    final displayNickname = getNickname(displayName);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đến ngân hàng',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Colors.black87),
            onPressed: () async {
              final Uri phoneUri = Uri(scheme: 'tel', path: '1900545415');
              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFE4EE),
              Color(0xFFFFF0F5),
              Color(0xFFF5F5F9),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Bank information banner (Mockup Blue Card)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3B99),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.network(
                              'https://api.vietqr.io/img/${widget.bankCode}.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Text(
                                widget.bankCode,
                                style: const TextStyle(
                                  color: Color(0xFF0F3B99),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayNickname,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.prefilledAccountNumber ?? _accountController.text} - ${widget.bankName}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                  
                  // Green Shield Check Banner
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Người nhận chưa ghi nhận rủi ro',
                          style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Bảo mật bởi AI',
                            style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card/Account Number Input (Only if not prefilled)
                  if (widget.prefilledAccountNumber == null) ...[
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
                                icon: const Icon(Icons.contact_phone_rounded, color: Colors.pink),
                                onPressed: _openContacts,
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
                            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 14),
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
                  ],

                  // Số tiền chuyển
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số tiền chuyển *',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onChanged: _onAmountChanged,
                              ),
                            ),
                            Container(
                              height: 24,
                              width: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade100,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'đ',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (_amountController.text.isNotEmpty && _parsedAmount > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            _convertNumberToVietnameseWords(_parsedAmount),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_amountError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 14),
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
                        Icon(Icons.auto_awesome_rounded, color: Colors.purple.shade300, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'AI sẽ tự động phân loại giao dịch này giúp bạn',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.deepPurple, size: 18),
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
                          TextSpan(text: 'Dịch vụ thu hộ chi hộ do Mio hỗ trợ các Ngân hàng đối tác cung cấp. '),
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
    ),
  );
  }
}

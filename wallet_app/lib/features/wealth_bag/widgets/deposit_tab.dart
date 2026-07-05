import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/bank_transfer_qr_screen.dart';
import '../screens/secure_payment_screen.dart';
import 'dart:convert';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import 'limit_bottom_sheet.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');
    
    // Giới hạn 12 số
    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }
    
    int value = int.parse(digitsOnly);
    String newText = value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.') + 'đ';
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length - 1),
    );
  }
}

class DepositTab extends StatefulWidget {
  const DepositTab({super.key});

  @override
  State<DepositTab> createState() => _DepositTabState();
}

class _DepositTabState extends State<DepositTab> {
  final TextEditingController _amountController = TextEditingController(text: '100.000đ');
  bool _isAutoDeposit = false;
  String _selectedMethod = 'bank'; 
  int _rawAmount = 100000;
  String? _errorMessage;
  double _wealthBagBalance = 0;
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    try {
      final response = await CustomHttpClient().get(Uri.parse(ApiConfig.wealthBagStatus));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          if (mounted) {
            setState(() {
              _wealthBagBalance = double.tryParse(data['data']['balance']?.toString() ?? '0') ?? 0.0;
              _isLoadingBalance = false;
            });
            _validateAmount();
          }
        } else {
          if (mounted) setState(() => _isLoadingBalance = false);
        }
      } else {
        if (mounted) setState(() => _isLoadingBalance = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  String _formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return "${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
    }
    String formatted = amount.toStringAsFixed(2);
    while (formatted.endsWith('0') && formatted.contains('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    List<String> parts = formatted.split('.');
    String intPart = parts[0].replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    if (parts.length > 1) return "$intPart,${parts[1]}đ";
    return "$intPartđ";
  }

  void _validateAmount() {
    String digitsOnly = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    int val = digitsOnly.isEmpty ? 0 : int.parse(digitsOnly);
    setState(() {
      _rawAmount = val;
      double remaining = 500000000 - _wealthBagBalance;
      if (remaining < 0) remaining = 0;
      
      if (val > remaining) {
        String remainingStr = remaining.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.') + 'đ';
        _errorMessage = "Số tiền còn lại có thể nạp vào Túi là $remainingStr";
      } else if (val > 0 && val < 1000) {
        _errorMessage = "Số tiền nạp tối thiểu là 1.000đ";
      } else {
        _errorMessage = null;
      }
    });
  }

  bool get _isValid => _rawAmount >= 1000 && (_rawAmount + _wealthBagBalance) <= 500000000;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: "Tiền trong Túi: ",
                          style: const TextStyle(color: Colors.black87, fontSize: 15),
                          children: [
                            TextSpan(
                              text: _isLoadingBalance ? "Đang tải..." : _formatAmount(_wealthBagBalance),
                              style: const TextStyle(fontWeight: FontWeight.bold)
                            ),
                          ]
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: _errorMessage != null ? Colors.red : Colors.black87
                        ),
                        decoration: InputDecoration(
                          labelText: "Số tiền nạp",
                          hintText: "100.000đ",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _errorMessage != null ? Colors.red : Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _errorMessage != null ? Colors.red : Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _errorMessage != null ? Colors.red : Colors.deepOrange),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) => _validateAmount(),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F6F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RichText(
                          text: const TextSpan(
                            text: "Sau khi nạp thêm 100.000đ, bạn sẽ nhận ",
                            style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
                            children: [
                              TextSpan(text: "10đ\n", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              TextSpan(text: "tiền lời mỗi ngày bắt đầu từ "),
                              TextSpan(text: "Thứ 7 (04/07/2026)", style: TextStyle(fontWeight: FontWeight.bold)),
                            ]
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.green, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text("Tự động nhận tiền vào Túi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          Switch(
                            value: _isAutoDeposit,
                            activeColor: Colors.deepOrange,
                            onChanged: (val) => setState(() => _isAutoDeposit = val),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: const TextSpan(
                          text: "Tiền chuyển đến Ví Mio của bạn sẽ được tự động nạp vào Túi Thần Tài và sinh lời, giúp bạn tiết kiệm thời gian nạp thủ công. ",
                          style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                          children: [
                            TextSpan(text: "Chi tiết", style: TextStyle(color: Colors.deepOrange)),
                          ]
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text("Chọn cách nạp tiền", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                
                GestureDetector(
                  onTap: () => setState(() => _selectedMethod = 'bank'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedMethod == 'bank' ? Border.all(color: Colors.deepOrange) : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance, color: Colors.orange.shade700, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Chuyển khoản từ ngân hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    const Text("Hạn mức nạp mỗi ngày: 3 giao dịch", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: 'bank',
                                groupValue: _selectedMethod,
                                activeColor: Colors.deepOrange,
                                onChanged: (val) => setState(() => _selectedMethod = val!),
                              )
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                            ),
                            child: const Text("Đề xuất", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                GestureDetector(
                  onTap: () => setState(() => _selectedMethod = 'mio'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedMethod == 'mio' ? Border.all(color: Colors.deepOrange) : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Nạp từ Mio/ngân hàng liên kết", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                const Text("Hạn mức nạp mỗi tháng: 50 triệu", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: 'mio',
                            groupValue: _selectedMethod,
                            activeColor: Colors.deepOrange,
                            onChanged: (val) => setState(() => _selectedMethod = val!),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                GestureDetector(
                  onTap: () => showDepositLimitSheet(context),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.deepOrange, size: 16),
                      SizedBox(width: 4),
                      Text("Xem chi tiết hạn mức", style: TextStyle(color: Colors.deepOrange, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isValid ? Colors.deepOrange : Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isValid ? () {
                if (_selectedMethod == 'bank') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BankTransferQrScreen(amount: _rawAmount)));
                } else if (_selectedMethod == 'mio') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SecurePaymentScreen(amount: _rawAmount)));
                }
              } : null,
              child: Text(
                "Tiếp tục",
                style: TextStyle(
                  color: _isValid ? Colors.white : Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import 'deposit_tab.dart'; // for CurrencyInputFormatter
import 'limit_bottom_sheet.dart';
import '../screens/withdraw_method_screen.dart';

class WithdrawTab extends StatefulWidget {
  const WithdrawTab({super.key});

  @override
  State<WithdrawTab> createState() => _WithdrawTabState();
}

class _WithdrawTabState extends State<WithdrawTab> {
  final TextEditingController _amountController = TextEditingController();
  
  double _wealthBagBalance = 0;
  int _rawAmount = 0;
  String? _errorMessage;
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
            _validateAmount(); // re-validate just in case user typed before balance loaded
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
      if (val > 50000000) {
        _errorMessage = "Số tiền rút tối đa 1 lần là 50.000.000đ";
      } else if (val > _wealthBagBalance) {
        _errorMessage = "Số dư Túi Thần Tài của bạn là ${_formatAmount(_wealthBagBalance)}, bạn không thể rút tiền khỏi Túi.";
      } else if (val > 0 && val < 10000) {
        _errorMessage = "Số tiền rút tối thiểu là 10.000đ";
      } else {
        _errorMessage = null;
      }
    });
  }

  bool get _isValid => _rawAmount >= 10000 && _rawAmount <= 50000000 && _rawAmount <= _wealthBagBalance;

  Widget _buildQuickAmount(int amount) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _amountController.text = NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.');
            _validateAmount();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.') + 'đ',
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ),
      ),
    );
  }

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
                        autofocus: true,
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: _errorMessage != null ? Colors.red : Colors.black87
                        ),
                        decoration: InputDecoration(
                          labelText: "Số tiền cần rút",
                          hintText: "0đ",
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                GestureDetector(
                  onTap: () => showWithdrawLimitSheet(context),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.deepOrange, size: 16),
                      SizedBox(width: 4),
                      Text("Xem chi tiết hạn mức rút", style: TextStyle(color: Colors.deepOrange, fontSize: 13)),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildQuickAmount(100000),
                  const SizedBox(width: 8),
                  _buildQuickAmount(1000000),
                  const SizedBox(width: 8),
                  _buildQuickAmount(10000000),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid ? Colors.deepOrange : Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isValid ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WithdrawMethodScreen(amount: _rawAmount),
                      ),
                    );
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
            ],
          ),
        )
      ],
    );
  }
}

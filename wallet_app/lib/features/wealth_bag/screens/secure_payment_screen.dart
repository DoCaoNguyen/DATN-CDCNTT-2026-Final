import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import 'transaction_result_screen.dart';

class SecurePaymentScreen extends StatefulWidget {
  final int amount;

  const SecurePaymentScreen({super.key, required this.amount});

  @override
  State<SecurePaymentScreen> createState() => _SecurePaymentScreenState();
}

class _SecurePaymentScreenState extends State<SecurePaymentScreen> {
  int _walletBalance = 0;
  bool _isLoading = true;
  String _selectedMethod = 'wallet'; // 'wallet' or 'bank'
  Map<String, dynamic>? _selectedBank;
  List<dynamic> _linkedBanks = [];
  final String _idempotencyKey = const Uuid().v7();

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
    _fetchLinkedBanks();
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final response = await CustomHttpClient().get(
        Uri.parse(ApiConfig.getWalletBalance),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['available_balance'] != null) {
          setState(() {
            _walletBalance =
                int.tryParse(data['data']['available_balance'].toString()) ?? 0;
            _isLoading = false;
            if (_walletBalance < widget.amount) {
              _selectedMethod =
                  'bank'; // Tự động chuyển sang ngân hàng nếu ví không đủ
            }
          });
          return;
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLinkedBanks() async {
    try {
      final response = await CustomHttpClient().get(
        Uri.parse(ApiConfig.getLinkedBanks),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _linkedBanks = data['data'] ?? [];
            if (_linkedBanks.isNotEmpty) {
              _selectedBank = _linkedBanks.first;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching banks: $e");
    }
  }

  Widget _buildBankIcon(Map<String, dynamic>? bank, double size) {
    if (bank != null &&
        bank['bank_code'] != null &&
        bank['bank_code'].toString().isNotEmpty) {
      String bCode = bank['bank_code'].toString();
      if (bCode.toUpperCase() == 'AGR' || bCode.toUpperCase() == 'AGRIBANK') {
        bCode = 'VBA';
      }
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.2),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Image.network(
          'https://api.vietqr.io/img/$bCode.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.account_balance_rounded,
              color: Colors.pink,
              size: size * 0.7,
            );
          },
        ),
      );
    }
    return Icon(Icons.account_balance, color: Colors.blue, size: size);
  }

  String _formatAmount(int amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.') +
        'đ';
  }

  void _showBankSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Chọn Nguồn Tiền",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              if (_linkedBanks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text("Chưa có ngân hàng liên kết"),
                )
              else
                ..._linkedBanks.map((bank) {
                  return ListTile(
                    leading: _buildBankIcon(bank, 36),
                    title: Text(
                      bank['bank_name'] ?? 'Ngân hàng',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(bank['card_number'] ?? ''),
                    onTap: () {
                      setState(() {
                        _selectedBank = bank;
                        _selectedMethod = 'bank';
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _handleConfirm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          Navigator.pop(ctx);
          await _processDeposit();
          return null;
        },
      ),
    );
  }

  Future<void> _processDeposit() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await CustomHttpClient().post(
        Uri.parse(ApiConfig.wealthBagDeposit),
        headers: {
          'Idempotency-Key': _idempotencyKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': widget.amount,
          'source': _selectedMethod == 'wallet' ? 'wallet' : 'linked_bank',
          'bankNumber': _selectedMethod == 'bank'
              ? (_selectedBank != null ? _selectedBank!['card_number'] : null)
              : null,
        }),
      );

      Navigator.pop(context); // close loading

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final txId =
            data['data']?['id']?.toString() ??
            data['data']?['transaction_id']?.toString();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionResultScreen(
              amount: widget.amount,
              transactionId: txId,
            ),
          ),
        );
      } else {
        SnackbarUtils.showError(
          context,
          data['message'] ?? 'Lỗi không xác định',
        );
      }
    } catch (e) {
      Navigator.pop(context); // close loading
      SnackbarUtils.showError(context, "Không thể kết nối máy chủ");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWalletDisabled = _walletBalance < widget.amount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF), // Màu nền tổng thể sáng
      appBar: AppBar(
        backgroundColor: const Color(
          0xFFFDF9F1,
        ), // Gradient giả lập từ trên xuống
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Thanh toán an toàn",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Hộp thông tin giao dịch (Receipt)
                        Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_long,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Nạp tiền Túi Thần Tài",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Số tiền",
                                          style: TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          _formatAmount(widget.amount),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Tạm tính",
                                          style: TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          _formatAmount(widget.amount),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Phần chọn nguồn tiền
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    "Trả ngay",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.visibility,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Nguồn tiền: Ngân hàng
                              GestureDetector(
                                onTap: _showBankSelectionSheet,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _selectedMethod == 'bank'
                                          ? Colors.pink
                                          : Colors.grey.shade300,
                                      width: _selectedMethod == 'bank'
                                          ? 1.5
                                          : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      if (_selectedBank != null)
                                        _buildBankIcon(_selectedBank, 36),
                                      if (_selectedBank == null)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.account_balance,
                                            color: Colors.blue,
                                            size: 24,
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (_selectedBank != null)
                                              Text(
                                                "${_selectedBank!['bank_name']} ${_selectedBank!['card_number']}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            else
                                              const Text(
                                                "Vui lòng chọn ngân hàng",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            const Text(
                                              "Đăng ký xem số dư >",
                                              style: TextStyle(
                                                color: Colors.pink,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Radio<String>(
                                        value: 'bank',
                                        groupValue: _selectedMethod,
                                        activeColor: Colors.pink,
                                        onChanged: (val) => setState(
                                          () => _selectedMethod = val!,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Nguồn tiền: Ví Mio
                              GestureDetector(
                                onTap: isWalletDisabled
                                    ? null
                                    : () => setState(
                                        () => _selectedMethod = 'wallet',
                                      ),
                                child: Opacity(
                                  opacity: isWalletDisabled ? 0.5 : 1.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _selectedMethod == 'wallet'
                                            ? Colors.pink
                                            : Colors.grey.shade300,
                                        width: _selectedMethod == 'wallet'
                                            ? 1.5
                                            : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isWalletDisabled
                                          ? Colors.grey.shade50
                                          : Colors.white,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.pink,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.account_balance_wallet,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Ví Mio",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _formatAmount(_walletBalance),
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Radio<String>(
                                          value: 'wallet',
                                          groupValue: _selectedMethod,
                                          activeColor: Colors.pink,
                                          onChanged: isWalletDisabled
                                              ? null
                                              : (val) => setState(
                                                  () => _selectedMethod = val!,
                                                ),
                                        ),
                                      ],
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
                ),

                // Footer xác nhận
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Tổng tiền",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _formatAmount(widget.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_up),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _handleConfirm,
                          icon: const Icon(
                            Icons.lock_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            "Xác nhận",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

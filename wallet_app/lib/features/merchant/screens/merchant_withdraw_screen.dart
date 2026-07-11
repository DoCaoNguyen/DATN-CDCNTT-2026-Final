import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../bank/screens/deposit_withdraw_success_screen.dart';
import '../../transfer/screens/transfer_success_screen.dart';
import '../../bank/screens/bank_transfer_success_screen.dart';

class MerchantWithdrawScreen extends StatefulWidget {
  final String token;
  final String availableBalance;

  const MerchantWithdrawScreen({
    Key? key,
    required this.token,
    required this.availableBalance,
  }) : super(key: key);

  @override
  State<MerchantWithdrawScreen> createState() => _MerchantWithdrawScreenState();
}

class _MerchantWithdrawScreenState extends State<MerchantWithdrawScreen> {
  final _amountController = TextEditingController();
  final _client = CustomHttpClient();
  bool _isWithdrawing = false;
  bool _isWithdrawingToBank = false;

  // Bank selection state
  List<dynamic> _linkedBanks = [];
  Map<String, dynamic>? _selectedBank;

  String? _amountError;

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
            _linkedBanks = data['data'] ?? [];
            if (_linkedBanks.isNotEmpty) {
              _selectedBank = _linkedBanks.first;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching linked banks: $e");
    }
  }

  void _validateAmount(String val) {
    String clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      setState(() => _amountError = null);
      return;
    }

    int parsed = int.tryParse(clean) ?? 0;
    int currentBalance =
        int.tryParse(
          widget.availableBalance.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    setState(() {
      if (parsed < 10000) {
        _amountError = 'Số tiền rút tối thiểu là 10.000đ';
      } else if (parsed > currentBalance) {
        _amountError = 'Số dư không đủ để thực hiện giao dịch này';
      } else {
        _amountError = null;
      }
    });
  }

  void _onAmountChanged(String val) {
    _validateAmount(val);
  }

  void _selectQuickAmount(int amount) {
    int currentBalance =
        int.tryParse(
          widget.availableBalance.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    if (amount > currentBalance) amount = currentBalance;

    String formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    _amountController.text = formatted;
    _amountController.selection = TextSelection.collapsed(
      offset: formatted.length,
    );
    _validateAmount(formatted);
  }

  void _withdrawAll() {
    final numStr = widget.availableBalance.replaceAll(RegExp(r'[^0-9]'), '');
    int value = int.tryParse(numStr) ?? 0;

    String formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    _amountController.text = formatted;
    _amountController.selection = TextSelection.collapsed(
      offset: formatted.length,
    );
    _validateAmount(formatted);
  }

  void _withdraw() {
    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountStr.isEmpty) {
      SnackbarUtils.showError(context, "Vui lòng nhập số tiền hợp lệ");
      return;
    }

    if (_amountError != null) return;

    final amount = int.tryParse(amountStr) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          try {
            final pinRes = await _client.post(
              Uri.parse(ApiConfig.verifyPin),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'pin': pin}),
            );

            if (pinRes.statusCode == 200) {
              Navigator.pop(ctx);
              await _processWithdraw(amount);
              return null;
            } else {
              final data = jsonDecode(pinRes.body);
              return data['error'] ?? "Mã PIN không chính xác";
            }
          } catch (e) {
            return "Không thể kết nối máy chủ";
          }
        },
      ),
    );
  }

  Future<void> _processWithdraw(int amount) async {
    setState(() {
      _isWithdrawing = true;
    });

    try {
      final res = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/merchant/withdraw-to-wallet'),
        headers: {
          "Content-Type": "application/json",
          "idempotency-key": const Uuid().v4(),
        },
        body: jsonEncode({"amount": amount}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (ctx) => TransferSuccessScreen(
                token: widget.token,
                receiverName: 'Ví cá nhân của tôi',
                receiverPhone: 'Chủ cửa hàng',
                senderName: 'Cửa hàng của tôi',
                note: 'Rút doanh thu về ví',
                amount: amount.toString(),
                referenceCode: data['transactionId'] ?? 'GD${DateTime.now().millisecondsSinceEpoch}',
                paymentTime: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
              ),
            ),
          );
        }
      } else {
        final err = jsonDecode(res.body)['error'] ?? "Rút tiền thất bại";
        SnackbarUtils.showError(context, err);
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, "Lỗi kết nối máy chủ");
    } finally {
      if (mounted) {
        setState(() {
          _isWithdrawing = false;
        });
      }
    }
  }

  void _withdrawToBank() {
    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountStr.isEmpty) {
      SnackbarUtils.showError(context, "Vui lòng nhập số tiền hợp lệ");
      return;
    }

    if (_amountError != null) return;

    final amount = int.tryParse(amountStr) ?? 0;
    if (amount < 50000) {
      setState(() => _amountError = 'Số tiền rút về NH tối thiểu là 50.000đ');
      return;
    }

    if (_selectedBank == null) {
      SnackbarUtils.showError(context, "Vui lòng chọn ngân hàng để rút tiền");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          try {
            final pinRes = await _client.post(
              Uri.parse(ApiConfig.verifyPin),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'pin': pin}),
            );

            if (pinRes.statusCode == 200) {
              Navigator.pop(ctx);
              await _processBankWithdraw(amount, pin);
              return null;
            } else {
              final data = jsonDecode(pinRes.body);
              return data['error'] ?? "Mã PIN không chính xác";
            }
          } catch (e) {
            return "Không thể kết nối máy chủ";
          }
        },
      ),
    );
  }

  Future<void> _processBankWithdraw(int amount, String pin) async {
    setState(() {
      _isWithdrawingToBank = true;
    });

    try {
      final res = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/merchant/withdraw-to-bank'),
        headers: {
          "Content-Type": "application/json",
          "idempotency-key": const Uuid().v4(),
        },
        body: jsonEncode({
          "amount": amount,
          "pin": pin,
          "bank_code": _selectedBank!['bank_code'],
          "account_number": _selectedBank!['card_number'],
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (ctx) => BankTransferSuccessScreen(
                token: widget.token,
                amount: amount.toString(),
                referenceCode: data['transactionId'] ?? 'GD${DateTime.now().millisecondsSinceEpoch}',
                paymentTime: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                receiverName: _selectedBank!['owner_name'] ?? 'Chủ thẻ',
                accountNumber: _selectedBank!['card_number'] ?? '',
                bankName: _selectedBank!['bank_name'] ?? '',
                bankCode: _selectedBank!['bank_code'] ?? '',
                note: 'Rút doanh thu về ngân hàng',
              ),
            ),
          );
        }
      } else {
        final err = jsonDecode(res.body)['error'] ?? "Rút tiền thất bại";
        SnackbarUtils.showError(context, err);
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, "Lỗi kết nối máy chủ");
    } finally {
      if (mounted) {
        setState(() {
          _isWithdrawingToBank = false;
        });
      }
    }
  }

  void _showBankSelection() {
    if (_linkedBanks.isEmpty) {
      SnackbarUtils.showError(context, "Bạn chưa liên kết ngân hàng nào");
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Chọn ngân hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  ..._linkedBanks.map((bank) {
                    final isSelected =
                        _selectedBank != null &&
                        _selectedBank!['id'] == bank['id'];
                    return ListTile(
                      leading: _buildBankIcon(bank, 36),
                      title: Text(
                        bank['bank_name'] ?? 'Ngân hàng',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(bank['card_number'] ?? ''),
                      trailing: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected ? Colors.pink : Colors.grey,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedBank = bank;
                        });
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBankIcon(dynamic bank, double size) {
    if (bank != null && bank['bank_code'] != null && bank['bank_code'].toString().isNotEmpty) {
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
            return Icon(Icons.account_balance_rounded, color: Colors.pink, size: size * 0.7);
          },
        ),
      );
    }
    return Icon(Icons.account_balance_rounded, color: Colors.pink, size: size * 0.7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rút Doanh Thu',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Column(
                children: [
                  const Text(
                    "Số dư khả dụng",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.availableBalance,
                    style: const TextStyle(
                      color: Colors.pink,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bank Selector
            const Text(
              'Ngân hàng thụ hưởng',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _showBankSelection,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    _buildBankIcon(_selectedBank, 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedBank != null
                                ? _selectedBank!['bank_name'] ?? 'Ngân hàng'
                                : 'Chọn ngân hàng',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (_selectedBank != null)
                            Text(
                              _selectedBank!['card_number'] ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Số tiền muốn rút",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _amountError != null
                      ? Colors.red
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _amountController,
                    onChanged: _onAmountChanged,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _amountError != null ? Colors.red : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      prefixText: "đ ",
                      prefixStyle: TextStyle(
                        fontSize: 24,
                        color: _amountError != null
                            ? Colors.red
                            : Colors.black87,
                      ),
                      hintText: "0",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: TextButton(
                        onPressed: _withdrawAll,
                        child: const Text(
                          "Tất cả",
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_amountError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  _amountError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),

            // Quick selector buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectQuickAmount(50000),
                    child: const Text('50.000'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectQuickAmount(100000),
                    child: const Text('100.000'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectQuickAmount(200000),
                    child: const Text('200.000'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.black54),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Rút về ví miễn phí (tối thiểu 10.000đ). Rút về NH tối thiểu 50.000đ.",
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.pink,
                        side: const BorderSide(color: Colors.pink),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isWithdrawing ? null : _withdraw,
                      child: _isWithdrawing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.pink,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Rút về ví",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isWithdrawingToBank ? null : _withdrawToBank,
                      child: _isWithdrawingToBank
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Rút về NH",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');

    // Giới hạn 12 số
    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }

    int value = int.parse(digitsOnly);
    String newText = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

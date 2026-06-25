import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../screens/bank_link_screen.dart';

/// Widget hiển thị màn hình xác nhận giao dịch Nạp/Rút tiền.
/// Nhận toàn bộ dữ liệu từ parent screen thông qua props.
class DepositWithdrawConfirmLayout extends StatelessWidget {
  final int activeTab;
  final int parsedAmount;
  final Map<String, dynamic>? selectedBank;
  final String token;
  final VoidCallback onConfirmTransaction;
  final VoidCallback onCancel;
  final VoidCallback onSelectBank;

  const DepositWithdrawConfirmLayout({
    Key? key,
    required this.activeTab,
    required this.parsedAmount,
    required this.selectedBank,
    required this.token,
    required this.onConfirmTransaction,
    required this.onCancel,
    required this.onSelectBank,
  }) : super(key: key);

  // Xây dựng icon ngân hàng theo bank_code → VietQR logo
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
    return Icon(Icons.account_balance_rounded, color: Colors.pink, size: size);
  }

  // Dòng hiển thị thông tin giao dịch (label: value)
  Widget _buildDetailRow(String title, String value, {bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: isBlue ? Colors.blue.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDeposit = activeTab == 0;
    final bankName = selectedBank != null
        ? selectedBank!['bank_name']
        : "MBBank";
    final cardNo = selectedBank != null ? selectedBank!['card_number'] : "";
    final bankNameDetails = selectedBank != null
        ? "$bankName - $cardNo"
        : "Chưa chọn ngân hàng";
    // Hiển thị số tiền đã format
    final formattedVal = CurrencyFormatter.format(parsedAmount);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFE4EE), Color(0xFFF5F5F9)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    children: [
                      // Card số tiền chính
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              isDeposit
                                  ? 'Xác nhận nạp tiền'
                                  : 'Xác nhận rút tiền',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              formattedVal,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Loại giao dịch',
                              isDeposit
                                  ? 'Nạp tiền vào ví'
                                  : 'Rút tiền về ngân hàng',
                            ),
                            _buildDetailRow(
                              'Phí giao dịch',
                              'Miễn phí',
                              isBlue: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Card ngân hàng
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDeposit
                                  ? 'Nạp từ tài khoản/thẻ'
                                  : 'Rút về tài khoản/thẻ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: onSelectBank,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.pink,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.pink.shade50.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildBankIcon(selectedBank, 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bankNameDetails,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Text(
                                            'Miễn phí',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.pink,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BankLinkScreen(token: token),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: Colors.pink.shade400,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Ngân hàng liên kết',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    '+37',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Nút xác nhận & quay lại
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng tiền',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      formattedVal,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onConfirmTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';

class WalletCard extends StatefulWidget {
  final String activeLang;
  final bool isLoading;
  final String balance;
  final String wealthBagBalance;
  final String fullName;
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onWealthBagTap;
  final VoidCallback? onFinancialCenterTap;

  const WalletCard({
    Key? key,
    required this.activeLang,
    required this.isLoading,
    required this.balance,
    required this.wealthBagBalance,
    required this.fullName,
    this.onToggleVisibility,
    this.onWealthBagTap,
    this.onFinancialCenterTap,
  }) : super(key: key);

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  bool _isBalanceVisible = true;

  String _formatCurrency(String amount) {
    try {
      final value = int.parse(amount);
      return "${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
    } catch (e) {
      return "0đ";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() => _isBalanceVisible = !_isBalanceVisible);
                              if (widget.onToggleVisibility != null) {
                                widget.onToggleVisibility!();
                              }
                            },
                            child: Icon(
                              _isBalanceVisible
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.activeLang == 'VIE' ? "Ví Mio" : "Mio Wallet",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      widget.isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.pink,
                              ),
                            )
                          : Text(
                              _isBalanceVisible
                                  ? CurrencyFormatter.format(widget.balance)
                                  : "******",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onWealthBagTap,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.activeLang == 'VIE' ? "Túi Thần Tài" : "Wealth Bag",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.savings_rounded, color: Colors.orange, size: 14),
                          ],
                        ),
                        const SizedBox(height: 4),
                        widget.isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.pink,
                                ),
                              )
                            : Text(
                                _isBalanceVisible
                                    ? CurrencyFormatter.format(widget.wealthBagBalance)
                                    : "******",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onFinancialCenterTap,
            child: Container(
              margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.activeLang == 'VIE'
                            ? "Trung Tâm Tài Chính của ${widget.fullName}"
                            : "${widget.fullName}'s Financial Center",
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

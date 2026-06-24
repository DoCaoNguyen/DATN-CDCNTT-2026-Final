import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';

class WalletCard extends StatefulWidget {
  final String activeLang;
  final bool isLoading;
  final String balance;
  final VoidCallback? onToggleVisibility;

  const WalletCard({
    Key? key,
    required this.activeLang,
    required this.isLoading,
    required this.balance,
    this.onToggleVisibility,
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
            child: Column(
              children: [
                Text(
                  widget.activeLang == 'VIE' ? "Ví Trả Sau" : "Postpaid Wallet",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.activeLang == 'VIE' ? "Dự phòng 5Tr" : "5M Reserve",
                  style: const TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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

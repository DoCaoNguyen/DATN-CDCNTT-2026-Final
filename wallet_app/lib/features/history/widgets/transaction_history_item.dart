import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../utils/transaction_category_helper.dart';
import '../screens/transaction_detail_screen.dart';

class TransactionHistoryItem extends StatelessWidget {
  final dynamic tx;
  final String token;
  final VoidCallback onRefresh;

  const TransactionHistoryItem({
    Key? key,
    required this.tx,
    required this.token,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String amountRaw = tx['amount']?.toString() ?? '0';
    final String balanceAfterRaw = tx['balance_after']?.toString() ?? '0';
    final String createdTime = tx['created_at'] != null
        ? DateFormatter.format(tx['created_at'])
        : '';
    final String entryType = tx['entry_type'] ?? 'DEBIT';
    final String note = tx['transfer_note'] ?? tx['description'] ?? 'Giao dịch';

    // Format title
    String title = "";
    if (tx['transaction_type'] == 'DEPOSIT') {
      title = "Nạp tiền vào ví từ MBBank";
    } else if (tx['transaction_type'] == 'TRANSFER') {
      if (entryType == 'DEBIT') {
        title =
            "Chuyển đến ${tx['receiver_name'] ?? tx['receiver_phone'] ?? 'Người dùng'}";
      } else {
        title =
            "Nhận tiền từ ${tx['sender_name'] ?? tx['sender_phone'] ?? 'Người dùng'}";
      }
    } else if (tx['transaction_type'] == 'PAYMENT') {
      final bool isTopup = (note.toLowerCase().contains('mã thẻ') || 
        note.toLowerCase().contains('thẻ cào') || 
        note.toLowerCase().contains('nạp tiền điện thoại') || 
        note.toLowerCase().contains('nạp gói data'));
      if (isTopup) {
        title = note.isNotEmpty ? note : "Giao dịch nạp tiền";
      } else {
        final rName = tx['receiver_name'];
        title = "Thanh toán tại ${rName != null && rName.toString().isNotEmpty ? rName : 'Cửa hàng'}";
      }
    } else if (tx['transaction_type'] == 'LOYALTY_REDEEM') {
      title = note.isNotEmpty ? note : "Đổi thẻ cào";
    } else {
      title = note;
    }

    final String tag = TransactionCategoryHelper.determineCategoryTag(tx);
    final bool isCredit = entryType == 'CREDIT';
    final bool isPoint = tx['currency'] == 'POINT';
    
    final String displayAmount = isPoint 
        ? "${CurrencyFormatter.format(amountRaw).replaceAll('đ', '').replaceAll('₫', '').trim()} Xu" 
        : CurrencyFormatter.format(amountRaw);
        
    final String displayBalance = isPoint 
        ? "${CurrencyFormatter.format(balanceAfterRaw).replaceAll('đ', '').replaceAll('₫', '').trim()} Xu" 
        : CurrencyFormatter.format(balanceAfterRaw);

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TransactionDetailScreen(token: token, transaction: tx),
          ),
        );
        if (result == true) {
          onRefresh();
        }
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(
                TransactionCategoryHelper.getTransactionIcon(tx),
                color: TransactionCategoryHelper.getIconColor(tx),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Middle details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    createdTime,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: TransactionCategoryHelper.getTagBgColor(tag),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: TransactionCategoryHelper.getTagColor(tag),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right amount and balance after
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${isCredit ? '+' : '-'}$displayAmount",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCredit ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Số dư: $displayBalance",
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../screens/expense_management_screen.dart';

class TransactionHistoryHeader extends StatelessWidget {
  final int totalExpenseThisMonth;
  final int totalExpenseLastMonth;
  final String token;

  const TransactionHistoryHeader({
    Key? key,
    required this.totalExpenseThisMonth,
    required this.totalExpenseLastMonth,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title Header
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 14,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tổng quan tháng ${DateTime.now().month}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.pink,
                  size: 20,
                ),
              ],
            ),
          ),
          // Summary values
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Spend Box
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ExpenseManagementScreen(token: token),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tổng chi",
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  CurrencyFormatter.format(
                                    totalExpenseThisMonth,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Compare Box
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "So với cùng kỳ",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Render difference with last month
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  int diff =
                                      totalExpenseThisMonth -
                                      totalExpenseLastMonth;
                                  bool isMore = diff > 0;
                                  return Row(
                                    children: [
                                      if (diff != 0)
                                        Icon(
                                          isMore
                                              ? Icons.arrow_upward_rounded
                                              : Icons.arrow_downward_rounded,
                                          color: isMore
                                              ? Colors.red
                                              : Colors.green,
                                          size: 14,
                                        ),
                                      if (diff != 0) const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          diff == 0
                                              ? "Bằng tháng trước"
                                              : CurrencyFormatter.format(
                                                  diff.abs(),
                                                ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: diff == 0
                                                ? Colors.grey
                                                : (isMore
                                                      ? Colors.red
                                                      : Colors.green),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Savings promo banner
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Bạn muốn tiết kiệm tiền hơn?",
                    style: TextStyle(color: Colors.black87, fontSize: 12),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Tính năng Đặt ngân sách đang được phát triển!",
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Đặt ngân sách",
                    style: TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

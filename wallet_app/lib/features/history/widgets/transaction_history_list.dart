import 'package:flutter/material.dart';
import 'transaction_history_item.dart';

class TransactionHistoryList extends StatelessWidget {
  final Map<String, List<dynamic>> groupedTransactions;
  final List<String> sortedMonthKeys;
  final bool isLoading;
  final String errorMsg;
  final bool isFetchingMore;
  final VoidCallback onRetry;
  final VoidCallback onRefresh;
  final String token;

  const TransactionHistoryList({
    Key? key,
    required this.groupedTransactions,
    required this.sortedMonthKeys,
    required this.isLoading,
    required this.errorMsg,
    required this.isFetchingMore,
    required this.onRetry,
    required this.onRefresh,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
    }

    if (errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            children: [
              Text(errorMsg, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: const Text(
                  "Tải lại",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (sortedMonthKeys.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Text(
            "Không tìm thấy lịch sử giao dịch nào.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedMonthKeys.length,
          itemBuilder: (context, mIndex) {
            final monthKey = sortedMonthKeys[mIndex];
            final txList = groupedTransactions[monthKey] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: const Color(0xFFF0F4F8),
                  child: Text(
                    monthKey,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Transactions in this month
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: txList.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 70),
                  itemBuilder: (context, txIndex) {
                    final tx = txList[txIndex];
                    return TransactionHistoryItem(
                      tx: tx,
                      token: token,
                      onRefresh: onRefresh,
                    );
                  },
                ),
              ],
            );
          },
        ),
        if (isFetchingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Colors.pink)),
          ),
        const SizedBox(height: 30),
      ],
    );
  }
}

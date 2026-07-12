import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../history/screens/expense_management_screen.dart';

class HomeMonthlyExpense extends StatefulWidget {
  final String activeLang;
  final String token;

  const HomeMonthlyExpense({
    Key? key,
    required this.activeLang,
    required this.token,
  }) : super(key: key);

  @override
  State<HomeMonthlyExpense> createState() => _HomeMonthlyExpenseState();
}

class _HomeMonthlyExpenseState extends State<HomeMonthlyExpense> {
  final CustomHttpClient _client = CustomHttpClient();
  int _totalExpenseThisMonth = 0;
  int _totalExpenseLastMonth = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    if (widget.token.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getTransactionStats),
      );
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          if (mounted) {
            setState(() {
              _totalExpenseThisMonth =
                  int.tryParse(
                    resData['data']['totalSpendThisMonth']?.toString() ?? '0',
                  ) ??
                  0;
              _totalExpenseLastMonth =
                  int.tryParse(
                    resData['data']['totalSpendLastMonth']?.toString() ?? '0',
                  ) ??
                  0;
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy thống kê: $e");
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int diff = _totalExpenseThisMonth - _totalExpenseLastMonth;
    bool isMore = diff > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseManagementScreen(token: widget.token),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.teal.shade400,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.activeLang == 'VIE'
                          ? "Chi tiêu tháng ${DateTime.now().month}"
                          : "Expense Month ${DateTime.now().month}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
                const Icon(Icons.more_horiz_rounded, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.activeLang == 'VIE'
                  ? "Cập nhật lúc ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} - ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}"
                  : "Updated at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} - ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Cards Row
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Total Expense Card
                  Container(
                    width: 150,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.activeLang == 'VIE'
                                  ? "Tổng chi"
                                  : "Total spend",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.sync_alt_rounded,
                                  color: Colors.pink.shade400,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                _isLoading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.pink,
                                        ),
                                      )
                                    : Expanded(
                                        child: Text(
                                          CurrencyFormatter.format(
                                            _totalExpenseThisMonth,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!_isLoading && diff != 0)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Icon(
                                      isMore
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      color: isMore ? Colors.red : Colors.green,
                                      size: 12,
                                    ),
                                  ),
                                if (!_isLoading && diff != 0)
                                  const SizedBox(width: 4),
                                _isLoading
                                    ? const SizedBox.shrink()
                                    : Text(
                                        diff == 0
                                            ? (widget.activeLang == 'VIE'
                                                  ? "Bằng T${DateTime.now().month - 1 == 0 ? 12 : DateTime.now().month - 1}"
                                                  : "Same as T${DateTime.now().month - 1 == 0 ? 12 : DateTime.now().month - 1}")
                                            : CurrencyFormatter.format(
                                                diff.abs(),
                                              ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: diff == 0
                                              ? Colors.grey
                                              : Colors.grey,
                                        ),
                                      ),
                                const SizedBox(width: 4),
                                if (!_isLoading && diff != 0)
                                  Expanded(
                                    child: Text(
                                      widget.activeLang == 'VIE'
                                          ? "so cùng\nkỳ T${DateTime.now().month - 1 == 0 ? 12 : DateTime.now().month - 1}"
                                          : "vs last\nmonth",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Keep Streak Card
                  Container(
                    width: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.activeLang == 'VIE'
                                  ? "Bạn có"
                                  : "You have",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.orange,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.activeLang == 'VIE'
                              ? "Giữ chuỗi\nChi tiêu hợp lý"
                              : "Keep streak\nGood spend",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
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
    );
  }
}

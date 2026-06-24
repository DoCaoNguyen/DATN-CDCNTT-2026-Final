import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/utils/currency_formatter.dart';
import '../utils/transaction_category_helper.dart';

class ExpenseManagementScreen extends StatefulWidget {
  final String token;

  const ExpenseManagementScreen({Key? key, required this.token})
    : super(key: key);

  @override
  State<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  DateTime _currentDate = DateTime.now();
  int _totalSpend = 0;
  Map<String, int> _categorySpends = {};
  Map<String, int> _lastMonthCategorySpends = {};

  final _client = CustomHttpClient();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMonthData();
  }

  Future<void> _fetchMonthData() async {
    if (widget.token.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      int lastMonth = _currentDate.month == 1 ? 12 : _currentDate.month - 1;
      int yearOfLastMonth = _currentDate.month == 1
          ? _currentDate.year - 1
          : _currentDate.year;

      // Fetch current month
      final currentRes = await _client.get(
        Uri.parse(
          "${ApiConfig.getTransactionsByMonth}?month=${_currentDate.month}&year=${_currentDate.year}",
        ),
      );

      // Fetch last month
      final lastRes = await _client.get(
        Uri.parse(
          "${ApiConfig.getTransactionsByMonth}?month=$lastMonth&year=$yearOfLastMonth",
        ),
      );

      List<dynamic> currentTx = [];
      List<dynamic> lastTx = [];

      if (currentRes.statusCode == 200) {
        final currentData = jsonDecode(currentRes.body);
        if (currentData['success'] == true)
          currentTx = currentData['data'] ?? [];
      }

      if (lastRes.statusCode == 200) {
        final lastData = jsonDecode(lastRes.body);
        if (lastData['success'] == true) lastTx = lastData['data'] ?? [];
      }

      _calculateSpends(currentTx, lastTx);
    } catch (e) {
      debugPrint("Lỗi lấy dữ liệu tháng: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateSpends(
    List<dynamic> currentMonthTx,
    List<dynamic> lastMonthTx,
  ) {
    int total = 0;
    Map<String, int> cats = {};
    Map<String, int> lastCats = {};

    for (var tx in currentMonthTx) {
      if (tx['entry_type'] == 'DEBIT') {
        final int amt = int.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
        final String cat = TransactionCategoryHelper.determineCategoryTag(tx);
        total += amt;
        cats[cat] = (cats[cat] ?? 0) + amt;
      }
    }

    for (var tx in lastMonthTx) {
      if (tx['entry_type'] == 'DEBIT') {
        final int amt = int.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
        final String cat = TransactionCategoryHelper.determineCategoryTag(tx);
        lastCats[cat] = (lastCats[cat] ?? 0) + amt;
      }
    }

    setState(() {
      _totalSpend = total;
      _categorySpends = cats;
      _lastMonthCategorySpends = lastCats;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentDate = DateTime(
        _currentDate.year,
        _currentDate.month + offset,
        1,
      );
    });
    _fetchMonthData();
  }

  void _showMonthPickerBottomSheet() {
    int tempYear = _currentDate.year;
    int tempMonth = _currentDate.month;
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: 20 + MediaQuery.of(context).padding.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      const Text(
                        "Chọn thời gian hiển thị chi tiêu",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 24,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              tempYear--;
                            });
                          },
                        ),
                        Text(
                          "Năm $tempYear",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              tempYear++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final m = index + 1;

                      final differenceInMonths =
                          (now.year - tempYear) * 12 + now.month - m;
                      final bool isSelectable =
                          differenceInMonths >= 0 && differenceInMonths < 12;
                      final bool isSelected =
                          tempMonth == m && tempYear == _currentDate.year;

                      return GestureDetector(
                        onTap: isSelectable
                            ? () {
                                setModalState(() {
                                  tempMonth = m;
                                });
                              }
                            : null,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.pink
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Tháng $m",
                            style: TextStyle(
                              color: isSelectable
                                  ? (isSelected ? Colors.white : Colors.black87)
                                  : Colors.grey.shade400,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempYear = now.year;
                              tempMonth = now.month;
                            });
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Xoá bộ lọc",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _currentDate = DateTime(tempYear, tempMonth, 1);
                            });
                            _fetchMonthData();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Áp dụng",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getMonthLabel() {
    final now = DateTime.now();
    if (_currentDate.month == now.month && _currentDate.year == now.year) {
      return "Tháng này";
    }
    return "Tháng ${_currentDate.month}/${_currentDate.year}";
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case "Ăn uống":
        return Icons.restaurant_menu_rounded;
      case "Giải trí":
        return Icons.movie_creation_rounded;
      case "Chợ, siêu thị":
        return Icons.shopping_basket_rounded;
      case "Hóa đơn":
        return Icons.receipt_long_rounded;
      case "Nạp tiền":
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case "Ăn uống":
        return Colors.orange;
      case "Giải trí":
        return Colors.pink;
      case "Chợ, siêu thị":
        return Colors.deepOrange;
      case "Hóa đơn":
        return Colors.blue;
      case "Nạp tiền":
        return Colors.green;
      default:
        return Colors.pinkAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFE4EE), Color(0xFFFFE4EE)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Quản lý chi tiêu",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE4EE), Color(0xFFFFF0F5), Color(0xFFF5F5F9)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.pink))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Card
                    Container(
                      margin: const EdgeInsets.all(16),
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
                          // Month Selector
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () => _changeMonth(-1),
                                  child: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: Colors.black54,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showMonthPickerBottomSheet,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getMonthLabel(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _changeMonth(1),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Status
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.bar_chart_rounded,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Trạng thái chi tiêu",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text.rich(
                                      const TextSpan(
                                        text: 'Chưa thể đánh giá. ',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Tìm hiểu thêm',
                                            style: TextStyle(
                                              color: Colors.pink,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Total spend
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.visibility_rounded,
                                          size: 16,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "Tổng chi",
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(_totalSpend),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: const [
                                      Text(
                                        "Phân tích ",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                "Thêm giao dịch để nhận đánh giá chính xác",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Category Details
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        "Chi tiết danh mục",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: _categorySpends.keys.map((cat) {
                          final int amt = _categorySpends[cat]!;
                          final int lastAmt =
                              _lastMonthCategorySpends[cat] ?? 0;
                          final int diff = amt - lastAmt;
                          final bool isMore = diff >= 0;

                          return Column(
                            children: [
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(
                                      cat,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(cat),
                                    color: _getCategoryColor(cat),
                                  ),
                                ),
                                title: Text(
                                  cat,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(amt),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (diff != 0 ||
                                            lastAmt ==
                                                0) // showing difference like the image
                                          Row(
                                            children: [
                                              Icon(
                                                isMore
                                                    ? Icons.arrow_upward_rounded
                                                    : Icons
                                                          .arrow_downward_rounded,
                                                color: isMore
                                                    ? Colors.red
                                                    : Colors.green,
                                                size: 10,
                                              ),
                                              Text(
                                                CurrencyFormatter.format(
                                                  diff.abs(),
                                                ),
                                                style: TextStyle(
                                                  color: isMore
                                                      ? Colors.red
                                                      : Colors.green,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.black26,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              if (cat != _categorySpends.keys.last)
                                Divider(
                                  height: 1,
                                  indent: 64,
                                  color: Colors.grey.shade200,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}

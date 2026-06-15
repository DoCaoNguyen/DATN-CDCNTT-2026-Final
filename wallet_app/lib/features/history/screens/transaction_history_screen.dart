import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String token;

  const TransactionHistoryScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<dynamic> _allTransactions = [];
  List<dynamic> _filteredTransactions = [];
  bool _isLoading = true;
  String _errorMsg = "";
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  // Statistics calculation variables
  int _totalSpendThisMonth = 0;
  int _totalReceiveThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    if (widget.token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMsg = "Không tìm thấy token đăng nhập";
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMsg = "";
      });

      final response = await http.get(
        Uri.parse(ApiConfig.getTransactionHistory),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          final List<dynamic> fetchedList = resData['data'];
          if (mounted) {
            setState(() {
              _allTransactions = fetchedList;
              _isLoading = false;
              _calculateMonthlyStats();
              _applyFilters();
            });
          }
        } else {
          setState(() {
            _errorMsg = "Lấy dữ liệu lịch sử thất bại";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMsg = "Lỗi kết nối máy chủ: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi lấy lịch sử: $e");
      if (mounted) {
        setState(() {
          _errorMsg = "Lỗi hệ thống khi tải lịch sử";
          _isLoading = false;
        });
      }
    }
  }

  void _calculateMonthlyStats() {
    final now = DateTime.now();
    int totalDebit = 0;
    int totalCredit = 0;

    for (var tx in _allTransactions) {
      if (tx['created_at'] != null) {
        try {
          final txDate = DateTime.parse(tx['created_at']);
          // Check if transaction is in the current month and year
          if (txDate.month == now.month && txDate.year == now.year) {
            final int amt = int.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
            if (tx['entry_type'] == 'DEBIT') {
              totalDebit += amt;
            } else if (tx['entry_type'] == 'CREDIT') {
              totalCredit += amt;
            }
          }
        } catch (e) {
          // Ignore parse errors
        }
      }
    }

    setState(() {
      _totalSpendThisMonth = totalDebit;
      _totalReceiveThisMonth = totalCredit;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredTransactions = _allTransactions.where((tx) {
        // 1. Text Search Filter
        bool matchesSearch = true;
        if (query.isNotEmpty) {
          final description = (tx['description'] ?? '').toString().toLowerCase();
          final transferNote = (tx['transfer_note'] ?? '').toString().toLowerCase();
          final senderName = (tx['sender_name'] ?? '').toString().toLowerCase();
          final receiverName = (tx['receiver_name'] ?? '').toString().toLowerCase();
          final amount = (tx['amount'] ?? '').toString();

          matchesSearch = description.contains(query) ||
              transferNote.contains(query) ||
              senderName.contains(query) ||
              receiverName.contains(query) ||
              amount.contains(query);
        }

        // 2. Date Range Filter
        bool matchesDate = true;
        if (_selectedDateRange != null && tx['created_at'] != null) {
          try {
            final txDate = DateTime.parse(tx['created_at']).toLocal();
            // Start of start day to end of end day
            final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
            final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
            matchesDate = txDate.isAfter(start) && txDate.isBefore(end);
          } catch (_) {
            matchesDate = false;
          }
        }

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pink,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFilters();
    }
  }

  String _formatCurrency(dynamic amountVal) {
    try {
      final value = int.parse(amountVal.toString());
      return "${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
    } catch (e) {
      return "0đ";
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      return "$hour:$minute - $day/$month/$year";
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthYearGroup(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return "Tháng ${dateTime.month}/${dateTime.year}";
    } catch (e) {
      return "Khác";
    }
  }

  Map<String, List<dynamic>> _groupTransactionsByMonth(List<dynamic> list) {
    final Map<String, List<dynamic>> groups = {};
    for (var tx in list) {
      final key = tx['created_at'] != null ? _getMonthYearGroup(tx['created_at']) : "Khác";
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(tx);
    }
    return groups;
  }

  // Determine Tag Category based on note content or transaction details
  String _determineCategoryTag(dynamic tx) {
    if (tx['category_name'] != null && tx['category_name'].toString().isNotEmpty) {
      return tx['category_name'].toString();
    }
    final note = (tx['transfer_note'] ?? tx['description'] ?? '').toString().toLowerCase();
    if (tx['transaction_type'] == 'DEPOSIT') {
      return "Nạp tiền";
    }
    if (note.contains('ăn') || note.contains('uống') || note.contains('lẩu') || note.contains('cafe') || note.contains('cơm') || note.contains('bánh')) {
      return "Ăn uống";
    }
    if (note.contains('chơi') || note.contains('game') || note.contains('nhạc') || note.contains('phim') || note.contains('giải trí') || note.contains('netflix')) {
      return "Giải trí";
    }
    if (note.contains('điện') || note.contains('nước') || note.contains('internet') || note.contains('học phí') || note.contains('hoá đơn')) {
      return "Hóa đơn";
    }
    return "Mua sắm";
  }

  Color _getTagColor(String tag) {
    if (tag == "Nạp tiền") return Colors.blue.shade600;
    if (["Chợ, siêu thị", "Ăn uống", "Di chuyển"].contains(tag)) {
      return Colors.orange.shade700;
    }
    if (["Mua sắm", "Giải trí", "Làm đẹp", "Sức khỏe", "Từ thiện"].contains(tag)) {
      return Colors.pink.shade600;
    }
    if (["Hóa đơn", "Nhà cửa", "Người thân"].contains(tag)) {
      return Colors.blue.shade600;
    }
    if (["Đầu tư", "Học tập"].contains(tag)) {
      return Colors.teal.shade600;
    }
    switch (tag) {
      case "Ăn uống":
        return Colors.orange.shade700;
      case "Giải trí":
        return Colors.pink.shade600;
      case "Hóa đơn":
        return Colors.teal.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getTagBgColor(String tag) {
    if (tag == "Nạp tiền") return Colors.blue.shade50;
    if (["Chợ, siêu thị", "Ăn uống", "Di chuyển"].contains(tag)) {
      return Colors.orange.shade50;
    }
    if (["Mua sắm", "Giải trí", "Làm đẹp", "Sức khỏe", "Từ thiện"].contains(tag)) {
      return Colors.pink.shade50;
    }
    if (["Hóa đơn", "Nhà cửa", "Người thân"].contains(tag)) {
      return Colors.blue.shade50;
    }
    if (["Đầu tư", "Học tập"].contains(tag)) {
      return Colors.teal.shade50;
    }
    switch (tag) {
      case "Ăn uống":
        return Colors.orange.shade50;
      case "Giải trí":
        return Colors.pink.shade50;
      case "Hóa đơn":
        return Colors.teal.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData _getTransactionIcon(dynamic tx) {
    if (tx['transaction_type'] == 'DEPOSIT') {
      return Icons.account_balance_wallet_outlined;
    }
    // Check entry_type for Debit vs Credit
    if (tx['entry_type'] == 'CREDIT') {
      return Icons.call_received_outlined;
    }
    return Icons.send_outlined;
  }

  Color _getIconColor(dynamic tx) {
    if (tx['transaction_type'] == 'DEPOSIT') {
      return Colors.blue;
    }
    if (tx['entry_type'] == 'CREDIT') {
      return Colors.green;
    }
    return Colors.pink;
  }

  void _showTransactionDetailSheet(dynamic tx) {
    final String amountRaw = tx['amount']?.toString() ?? '0';
    final String balanceAfterRaw = tx['balance_after']?.toString() ?? '0';
    final String createdTime = tx['created_at'] != null ? _formatDate(tx['created_at']) : '';
    final String entryType = tx['entry_type'] ?? 'DEBIT';
    final String note = tx['transfer_note'] ?? tx['description'] ?? 'Giao dịch';
    final String extRef = tx['external_reference']?.toString() ?? tx['transaction_id']?.toString() ?? 'Không có';
    final bool isCredit = entryType == 'CREDIT';

    String typeLabel = "Giao dịch";
    if (tx['transaction_type'] == 'DEPOSIT') {
      typeLabel = "Nạp tiền vào ví";
    } else if (tx['transaction_type'] == 'WITHDRAW') {
      typeLabel = "Rút tiền về ngân hàng";
    } else if (tx['transaction_type'] == 'TRANSFER') {
      if (isCredit) {
        typeLabel = "Nhận tiền từ bạn bè";
      } else {
        typeLabel = "Chuyển tiền";
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "${isCredit ? '+' : '-'}${_formatCurrency(amountRaw)}",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isCredit ? Colors.green[700] : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                _buildSheetRow("Trạng thái", "Thành công", isStatus: true),
                _buildSheetRow("Thời gian", createdTime),
                _buildSheetRow("Mã giao dịch", extRef, isRef: true),
                if (tx['transaction_type'] == 'TRANSFER') ...[
                  if (isCredit)
                    _buildSheetRow("Người gửi", "${tx['sender_name'] ?? 'Người dùng'} (${tx['sender_phone'] ?? ''})")
                  else
                    _buildSheetRow("Người nhận", "${tx['receiver_name'] ?? 'Người dùng'} (${tx['receiver_phone'] ?? ''})"),
                ],
                _buildSheetRow("Số dư sau giao dịch", _formatCurrency(balanceAfterRaw)),
                _buildSheetRow("Nội dung", note),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Đóng",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetRow(String label, String value, {bool isStatus = false, bool isRef = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: isStatus
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          "Thành công",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isRef ? const Color(0xFFE91E63) : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupTransactionsByMonth(_filteredTransactions);
    // Sort month keys in descending order (assuming transactions are already chronologically sorted)
    final sortedMonthKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Lịch sử giao dịch",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        color: Colors.pink,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar Area
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            hintText: "Tìm kiếm giao dịch",
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _selectDateRange,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedDateRange != null ? Colors.pink.shade50 : const Color(0xFFF5F5F5),
                          shape: BoxShape.circle,
                          border: _selectedDateRange != null ? Border.all(color: Colors.pink.shade200) : null,
                        ),
                        child: Icon(
                          Icons.tune, 
                          color: _selectedDateRange != null ? Colors.pink : Colors.black54, 
                          size: 20
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.grid_view_outlined, color: Colors.black54, size: 20),
                    ),
                  ],
                ),
              ),
              if (_selectedDateRange != null)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: Row(
                    children: [
                      InputChip(
                        label: Text(
                          "Từ: ${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - Đến: ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}",
                          style: const TextStyle(color: Colors.pink, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.pink.shade50,
                        deleteIconColor: Colors.pink,
                        onDeleted: () {
                          setState(() {
                            _selectedDateRange = null;
                          });
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),

              // Monthly Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Title Header
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tổng quan tháng ${DateTime.now().month}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.pink, size: 20),
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
                                  const Text("Tổng chi", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _formatCurrency(_totalSpendThisMonth),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                                    ],
                                  ),
                                ],
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
                                  const Text("So với cùng kỳ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Render a dynamic look alike value
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              _totalSpendThisMonth > 0 ? Icons.arrow_downward : Icons.trending_flat,
                                              color: Colors.green,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                _totalSpendThisMonth > 0
                                                    ? _formatCurrency((_totalSpendThisMonth * 0.05).round())
                                                    : "0đ",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
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
                                const SnackBar(content: Text("Tính năng Đặt ngân sách đang được phát triển!")),
                              );
                            },
                            child: const Text(
                              "Đặt ngân sách",
                              style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction List section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Giao dịch gần đây",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
              ),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: Colors.pink),
                  ),
                )
              else if (_errorMsg.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Column(
                      children: [
                        Text(_errorMsg, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _fetchHistory,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                          child: const Text("Tải lại", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredTransactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Text(
                      "Không tìm thấy lịch sử giao dịch nào.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedMonthKeys.length,
                  itemBuilder: (context, mIndex) {
                    final monthKey = sortedMonthKeys[mIndex];
                    final txList = grouped[monthKey] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: const Color(0xFFF0F4F8),
                          child: Text(
                            monthKey,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                        ),
                        // Transactions in this month
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: txList.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                          itemBuilder: (context, txIndex) {
                            final tx = txList[txIndex];
                            final String amountRaw = tx['amount']?.toString() ?? '0';
                            final String balanceAfterRaw = tx['balance_after']?.toString() ?? '0';
                            final String createdTime = tx['created_at'] != null ? _formatDate(tx['created_at']) : '';
                            final String entryType = tx['entry_type'] ?? 'DEBIT';
                            final String note = tx['transfer_note'] ?? tx['description'] ?? 'Giao dịch';

                            // Format title
                            String title = "";
                            if (tx['transaction_type'] == 'DEPOSIT') {
                              title = "Nạp tiền vào ví từ MBBank";
                            } else if (tx['transaction_type'] == 'TRANSFER') {
                              if (entryType == 'DEBIT') {
                                title = "Chuyển đến ${tx['receiver_name'] ?? tx['receiver_phone'] ?? 'Người dùng'}";
                              } else {
                                title = "Nhận tiền từ ${tx['sender_name'] ?? tx['sender_phone'] ?? 'Người dùng'}";
                              }
                            } else {
                              title = note;
                            }

                            final String tag = _determineCategoryTag(tx);
                            final bool isCredit = entryType == 'CREDIT';

                            return InkWell(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransactionDetailScreen(
                                      token: widget.token,
                                      transaction: tx,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _fetchHistory();
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
                                        _getTransactionIcon(tx),
                                        color: _getIconColor(tx),
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
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
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
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getTagBgColor(tag),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              tag,
                                              style: TextStyle(
                                                color: _getTagColor(tag),
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
                                          "${isCredit ? '+' : '-'}${_formatCurrency(amountRaw)}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isCredit ? Colors.green.shade700 : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Số dư ví: ${_formatCurrency(balanceAfterRaw)}",
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/transaction_category_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import 'transaction_history_filter_screen.dart';
import 'export_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'expense_management_screen.dart';
import '../../ai/screens/ai_chat_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String token;

  const TransactionHistoryScreen({Key? key, required this.token})
    : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _client = CustomHttpClient();
  List<dynamic> _allTransactions = [];
  List<dynamic> _filteredTransactions = [];
  bool _isLoading = true;
  String _errorMsg = "";
  final TextEditingController _searchController = TextEditingController();

  // Pagination
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  // Statistics calculation variables
  int _totalExpenseThisMonth = 0;
  int _totalExpenseLastMonth = 0;

  TransactionFilterConfig _currentFilter = TransactionFilterConfig();

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchHistory();
    _searchController.addListener(_applyFilters);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _hasActiveFilter() {
    return _currentFilter.time != "Tất cả" ||
        _currentFilter.account != "Tất cả" ||
        _currentFilter.service != null;
  }

  Future<void> _fetchStats() async {
    if (widget.token.isEmpty) return;
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
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy thống kê: $e");
    }
  }

  String _buildHistoryUrl(int page) {
    String url = "${ApiConfig.getTransactionHistory}?page=$page&limit=20";

    // Convert time -> startDate, endDate
    if (_currentFilter.time != "Tất cả") {
      final timeStr = _currentFilter.time.replaceAll("Tháng ", "");
      final parts = timeStr.split("/");
      if (parts.length == 2) {
        final month = int.tryParse(parts[0]) ?? 1;
        final year = int.tryParse(parts[1]) ?? 2026;
        final startStr = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(year, month, 1));
        final endStr = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(year, month + 1, 0));
        url += "&startDate=$startStr&endDate=$endStr";
      }
    }

    // Convert service -> type
    if (_currentFilter.service != null) {
      String? type;
      if (_currentFilter.service == "Nạp tiền")
        type = "DEPOSIT";
      else if (_currentFilter.service == "Rút tiền")
        type = "WITHDRAW";
      else if (_currentFilter.service == "Nhận tiền" ||
          _currentFilter.service == "Chuyển tiền")
        type = "TRANSFER";
      else if ([
        "Chi tiêu sinh hoạt",
        "Hóa đơn & Tiện ích",
        "Giải trí & Mua sắm",
        "Chi phí phát sinh",
      ].contains(_currentFilter.service))
        type = "PAYMENT";

      if (type != null) {
        url += "&type=$type";
      }
    }
    return url;
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
        _currentPage = 1;
        _hasMore = true;
      });

      final response = await _client.get(Uri.parse(_buildHistoryUrl(1)));

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          final List<dynamic> fetchedList = resData['data'];
          if (mounted) {
            setState(() {
              _allTransactions = fetchedList;
              if (fetchedList.length < 20) {
                _hasMore = false;
              }
              _isLoading = false;
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
      debugPrint("Lỗi lấy lịch sử: $e");
      if (mounted) {
        setState(() {
          _errorMsg = "Lỗi hệ thống khi tải lịch sử";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMore() async {
    if (_isFetchingMore || !_hasMore || _isLoading) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await _client.get(Uri.parse(_buildHistoryUrl(nextPage)));

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          final List<dynamic> fetchedList = resData['data'];
          if (mounted) {
            setState(() {
              _currentPage = nextPage;
              _allTransactions.addAll(fetchedList);
              if (fetchedList.length < 20) {
                _hasMore = false;
              }
              _isFetchingMore = false;
              _applyFilters();
            });
          }
        } else {
          setState(() {
            _isFetchingMore = false;
          });
        }
      } else {
        setState(() {
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải thêm: $e");
      setState(() {
        _isFetchingMore = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredTransactions = _allTransactions.where((tx) {
        // 1. Text Search Filter
        bool matchesSearch = true;
        if (query.isNotEmpty) {
          final description = (tx['description'] ?? '')
              .toString()
              .toLowerCase();
          final transferNote = (tx['transfer_note'] ?? '')
              .toString()
              .toLowerCase();
          final senderName = (tx['sender_name'] ?? '').toString().toLowerCase();
          final receiverName = (tx['receiver_name'] ?? '')
              .toString()
              .toLowerCase();
          final amount = (tx['amount'] ?? '').toString();

          matchesSearch =
              description.contains(query) ||
              transferNote.contains(query) ||
              senderName.contains(query) ||
              receiverName.contains(query) ||
              amount.contains(query);
        }

        // 2. Time Filter
        bool matchesTime = true;
        if (_currentFilter.time != "Tất cả" && tx['created_at'] != null) {
          try {
            final txDate = DateTime.parse(tx['created_at']).toLocal();
            // "Tháng 6/2026"
            final timeStr = _currentFilter.time.replaceAll("Tháng ", "");
            final parts = timeStr.split("/");
            if (parts.length == 2) {
              final month = int.parse(parts[0]);
              final year = int.parse(parts[1]);
              matchesTime = txDate.month == month && txDate.year == year;
            }
          } catch (_) {}
        }

        // 3. Account Filter
        bool matchesAccount = true;
        if (_currentFilter.account != "Tất cả") {
          final desc = (tx['description'] ?? '').toString().toLowerCase();
          final note = (tx['transfer_note'] ?? '').toString().toLowerCase();
          final isBank =
              desc.contains('ngân hàng') ||
              desc.contains('bank') ||
              note.contains('ngân hàng') ||
              note.contains('bank');

          if (_currentFilter.account == "Tài khoản ngân hàng") {
            matchesAccount = isBank;
          } else if (_currentFilter.account == "Ví Mio") {
            matchesAccount = !isBank;
          }
        }

        // 4. Service Filter
        bool matchesService = true;
        if (_currentFilter.service != null) {
          final category = TransactionCategoryHelper.determineCategoryTag(tx);
          // Special case mapping for filter options
          if (_currentFilter.service == "Nhận tiền") {
            matchesService = tx['entry_type'] == 'CREDIT';
          } else if (_currentFilter.service == "Rút tiền") {
            matchesService = tx['transaction_type'] == 'WITHDRAW';
          } else if (_currentFilter.service == "Chuyển tiền") {
            matchesService =
                tx['transaction_type'] == 'TRANSFER' &&
                tx['entry_type'] == 'DEBIT';
          } else if (_currentFilter.service == "Nạp tiền") {
            matchesService = tx['transaction_type'] == 'DEPOSIT';
          } else if (_currentFilter.service == "Chi tiêu sinh hoạt") {
            matchesService = [
              "Ăn uống",
              "Chợ, siêu thị",
              "Di chuyển",
              "Mua sắm",
            ].contains(category);
          } else if (_currentFilter.service == "Hóa đơn & Tiện ích") {
            matchesService = [
              "Hóa đơn",
              "Nhà cửa",
              "Học tập",
            ].contains(category);
          } else if (_currentFilter.service == "Giải trí & Mua sắm") {
            matchesService = [
              "Giải trí",
              "Làm đẹp",
              "Mua sắm",
            ].contains(category);
          } else if (_currentFilter.service == "Chi phí phát sinh") {
            matchesService = [
              "Sức khỏe",
              "Từ thiện",
              "Người thân",
            ].contains(category);
          } else if (_currentFilter.service == "Khác") {
            matchesService = category == "Khác";
          } else {
            matchesService = category == _currentFilter.service;
          }
        }

        return matchesSearch && matchesTime && matchesAccount && matchesService;
      }).toList();
    });
  }

  Future<void> _openFilterScreen() async {
    final result = await Navigator.push<TransactionFilterConfig>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransactionHistoryFilterScreen(initialConfig: _currentFilter),
      ),
    );

    if (result != null) {
      setState(() {
        _currentFilter = result;
      });
      _fetchHistory(); // Fetch new data from server with filters
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
      final key = tx['created_at'] != null
          ? _getMonthYearGroup(tx['created_at'])
          : "Khác";
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(tx);
    }
    return groups;
  }

  String _determineCategoryTag(dynamic tx) {
    if (tx['category_name'] != null &&
        tx['category_name'].toString().isNotEmpty) {
      return tx['category_name'].toString();
    }
    final note = (tx['transfer_note'] ?? tx['description'] ?? '')
        .toString()
        .toLowerCase();
    if (tx['transaction_type'] == 'DEPOSIT') {
      return "Nạp tiền";
    }
    if (note.contains('ăn') ||
        note.contains('uống') ||
        note.contains('lẩu') ||
        note.contains('cafe') ||
        note.contains('cơm') ||
        note.contains('bánh')) {
      return "Ăn uống";
    }
    if (note.contains('chơi') ||
        note.contains('game') ||
        note.contains('nhạc') ||
        note.contains('phim') ||
        note.contains('giải trí') ||
        note.contains('netflix')) {
      return "Giải trí";
    }
    if (note.contains('điện') ||
        note.contains('nước') ||
        note.contains('internet') ||
        note.contains('học phí') ||
        note.contains('hoá đơn')) {
      return "Hóa đơn";
    }
    return "Chưa phân loại";
  }

  Color _getTagColor(String tag) {
    if (tag == "Nạp tiền") return Colors.blue.shade600;
    if (["Chợ, siêu thị", "Ăn uống", "Di chuyển"].contains(tag)) {
      return Colors.orange.shade700;
    }
    if ([
      "Mua sắm",
      "Giải trí",
      "Làm đẹp",
      "Sức khỏe",
      "Từ thiện",
    ].contains(tag)) {
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
    if ([
      "Mua sắm",
      "Giải trí",
      "Làm đẹp",
      "Sức khỏe",
      "Từ thiện",
    ].contains(tag)) {
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
      return Icons.account_balance_wallet_rounded;
    }
    if (tx['entry_type'] == 'CREDIT') {
      return Icons.call_received_rounded;
    }
    return Icons.send_rounded;
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
    final String createdTime = tx['created_at'] != null
        ? DateFormatter.format(tx['created_at'])
        : '';
    final String entryType = tx['entry_type'] ?? 'DEBIT';
    final String note = tx['transfer_note'] ?? tx['description'] ?? 'Giao dịch';
    final String extRef =
        tx['external_reference']?.toString() ??
        tx['transaction_id']?.toString() ??
        'Không có';
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
    } else if (tx['transaction_type'] == 'PAYMENT') {
      final bool isTopup = (note.toLowerCase().contains('mã thẻ') || 
        note.toLowerCase().contains('thẻ cào') || 
        note.toLowerCase().contains('nạp tiền điện thoại') || 
        note.toLowerCase().contains('nạp gói data'));
      if (isTopup) {
        typeLabel = note.isNotEmpty ? note : "Giao dịch nạp tiền";
      } else {
        typeLabel = "Thanh toán ${tx['receiver_name'] ?? ''}";
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
                    "${isCredit ? '+' : '-'}${CurrencyFormatter.format(amountRaw)}",
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
                    _buildSheetRow(
                      "Người gửi",
                      "${tx['sender_name'] ?? 'Người dùng'} (${tx['sender_phone'] ?? ''})",
                    )
                  else
                    _buildSheetRow(
                      "Người nhận",
                      "${tx['receiver_name'] ?? 'Người dùng'} (${tx['receiver_phone'] ?? ''})",
                    ),
                ] else if (tx['transaction_type'] == 'PAYMENT') ...[
                  _buildSheetRow(
                    "Đơn vị nhận",
                    "${tx['receiver_name'] ?? 'Cửa hàng/Dịch vụ'}",
                  ),
                ],
                _buildSheetRow(
                  "Số dư sau giao dịch",
                  CurrencyFormatter.format(balanceAfterRaw),
                ),
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

  Widget _buildSheetRow(
    String label,
    String value, {
    bool isStatus = false,
    bool isRef = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: isStatus
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 16,
                        ),
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

  void _showUtilityBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text(
                    'Tiện ích',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.black54,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(
                  Icons.visibility_off_rounded,
                  color: Colors.black87,
                ),
                title: const Text('Ẩn số dư', style: TextStyle(fontSize: 15)),
                onTap: () {
                  Navigator.pop(ctx);
                  // Future implementation
                },
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(
                  Icons.download_rounded,
                  color: Colors.black87,
                ),
                title: const Text(
                  'Tải dữ liệu giao dịch',
                  style: TextStyle(fontSize: 15),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ExportTransactionScreen(token: widget.token),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.black87,
                ),
                title: const Text(
                  'Chat với Trợ thủ AI - Mo247',
                  style: TextStyle(fontSize: 15),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiChatScreen(token: widget.token),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupTransactionsByMonth(_filteredTransactions);
    final sortedMonthKeys = grouped.keys.toList();

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
        title: const Text(
          "Lịch sử giao dịch",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
        child: RefreshIndicator(
          onRefresh: () async {
            _fetchStats();
            await _fetchHistory();
          },
          color: Colors.pink,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: "Tìm kiếm giao dịch",
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _openFilterScreen,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _hasActiveFilter()
                                ? Colors.pink.shade50
                                : const Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                            border: _hasActiveFilter()
                                ? Border.all(color: Colors.pink.shade200)
                                : null,
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: _hasActiveFilter()
                                ? Colors.pink
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showUtilityBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            color: Colors.black54,
                            size: 20,
                          ),
                        ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
                                          ExpenseManagementScreen(
                                            token: widget.token,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Tổng chi",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              CurrencyFormatter.format(
                                                _totalExpenseThisMonth,
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
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "So với cùng kỳ",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Render difference with last month
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              int diff =
                                                  _totalExpenseThisMonth -
                                                  _totalExpenseLastMonth;
                                              bool isMore = diff > 0;
                                              bool isLess = diff < 0;
                                              return Row(
                                                children: [
                                                  if (diff != 0)
                                                    Icon(
                                                      isMore
                                                          ? Icons
                                                                .arrow_upward_rounded
                                                          : Icons
                                                                .arrow_downward_rounded,
                                                      color: isMore
                                                          ? Colors.red
                                                          : Colors.green,
                                                      size: 14,
                                                    ),
                                                  if (diff != 0)
                                                    const SizedBox(width: 2),
                                                  Expanded(
                                                    child: Text(
                                                      diff == 0
                                                          ? "Bằng tháng trước"
                                                          : CurrencyFormatter.format(
                                                              diff.abs(),
                                                            ),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: diff == 0
                                                            ? Colors.grey
                                                            : (isMore
                                                                  ? Colors.red
                                                                  : Colors
                                                                        .green),
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                ),
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
                ),

                // Transaction List section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "Giao dịch gần đây",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Text(
                            _errorMsg,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchHistory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                            ),
                            child: const Text(
                              "Tải lại",
                              style: TextStyle(color: Colors.white),
                            ),
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
                              final String amountRaw =
                                  tx['amount']?.toString() ?? '0';
                              final String balanceAfterRaw =
                                  tx['balance_after']?.toString() ?? '0';
                              final String createdTime =
                                  tx['created_at'] != null
                                  ? DateFormatter.format(tx['created_at'])
                                  : '';
                              final String entryType =
                                  tx['entry_type'] ?? 'DEBIT';
                              final String note =
                                  tx['transfer_note'] ??
                                  tx['description'] ??
                                  'Giao dịch';

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
                                  title =
                                      "Thanh toán tại ${tx['receiver_name'] ?? 'Cửa hàng'}";
                                }
                              } else {
                                title = note;
                              }

                              final String tag =
                                  TransactionCategoryHelper.determineCategoryTag(
                                    tx,
                                  );
                              final bool isCredit = entryType == 'CREDIT';
                              final bool isPoint = tx['currency'] == 'POINT';
                              
                              final String displayAmount = isPoint 
                                  ? "${CurrencyFormatter.format(amountRaw).replaceAll('đ', '').replaceAll('₫', '').trim()} Xu" 
                                  : "${CurrencyFormatter.format(amountRaw)}";
                                  
                              final String displayBalance = isPoint 
                                  ? "Số dư Xu: ${CurrencyFormatter.format(balanceAfterRaw).replaceAll('đ', '').replaceAll('₫', '').trim()} Xu" 
                                  : "Số dư ví: ${CurrencyFormatter.format(balanceAfterRaw)}";

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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Icon circle
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            // Category tag
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getTagBgColor(tag),
                                                borderRadius:
                                                    BorderRadius.circular(10),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "${isCredit ? '+' : '-'}$displayAmount",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isCredit
                                                  ? Colors.green.shade700
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            displayBalance,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11,
                                            ),
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

                if (_isFetchingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.pink),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

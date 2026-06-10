import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import '../../transfer/screens/transfer_amount_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({
    Key? key,
    required this.token,
    required this.transaction,
  }) : super(key: key);

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Map<String, dynamic> _tx;
  String? _categoryName;
  late bool _isExpenseCounted;
  bool _isUpdating = false;
  bool _isUpdated = false;

  @override
  void initState() {
    super.initState();
    _tx = Map<String, dynamic>.from(widget.transaction);
    _categoryName = _tx['category_name'];
    _isExpenseCounted = _tx['is_expense_counted'] ?? true;
  }

  IconData? _getCategoryIcon(String? name) {
    if (name == null) return null;
    switch (name) {
      case 'Chợ, siêu thị': return Icons.shopping_basket_outlined;
      case 'Ăn uống': return Icons.restaurant_outlined;
      case 'Di chuyển': return Icons.directions_car_filled_outlined;
      case 'Mua sắm': return Icons.shopping_bag_outlined;
      case 'Giải trí': return Icons.movie_creation_outlined;
      case 'Làm đẹp': return Icons.face_retouching_natural_outlined;
      case 'Sức khỏe': return Icons.health_and_safety_outlined;
      case 'Từ thiện': return Icons.favorite_border_outlined;
      case 'Hóa đơn': return Icons.receipt_outlined;
      case 'Nhà cửa': return Icons.home_work_outlined;
      case 'Người thân': return Icons.people_outline;
      case 'Đầu tư': return Icons.account_balance_outlined;
      case 'Học tập': return Icons.school_outlined;
      default: return null;
    }
  }

  Color _getCategoryColor(String? name) {
    if (name == null) return Colors.grey;
    if (['Chợ, siêu thị', 'Ăn uống', 'Di chuyển'].contains(name)) return Colors.orange;
    if (['Mua sắm', 'Giải trí', 'Làm đẹp', 'Sức khỏe', 'Từ thiện'].contains(name)) return const Color(0xFFE91E63);
    if (['Hóa đơn', 'Nhà cửa', 'Người thân'].contains(name)) return Colors.blue;
    if (['Đầu tư', 'Học tập'].contains(name)) return Colors.teal;
    return Colors.grey;
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

  String _getShortName(String fullName) {
    if (fullName.isEmpty) return "";
    final parts = fullName.trim().split(' ');
    if (parts.length > 1) {
      return "${parts[parts.length - 2]} ${parts[parts.length - 1]}";
    }
    return fullName;
  }

  Future<bool> updateTransactionCategory(String transId, String categoryName, bool isCounted) async {
    try {
      print("Sending PUT category request for transId: $transId, category: $categoryName, counted: $isCounted");
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/transaction/$transId/category"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'category_name': categoryName,
          'is_expense_counted': isCounted,
        }),
      );

      print("PUT category response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        return resData['success'] == true;
      }
      return false;
    } catch (e) {
      print("Error updating transaction category: $e");
      return false;
    }
  }

  void _showCategoryBottomSheet() {
    bool localIsCounted = _isExpenseCounted;
    final List<Map<String, dynamic>> categories = [
      // Chi tiêu - sinh hoạt
      {'name': 'Chợ, siêu thị', 'group': 'Chi tiêu - sinh hoạt', 'icon': Icons.shopping_basket_outlined, 'color': Colors.orange},
      {'name': 'Ăn uống', 'group': 'Chi tiêu - sinh hoạt', 'icon': Icons.restaurant_outlined, 'color': Colors.orange},
      {'name': 'Di chuyển', 'group': 'Chi tiêu - sinh hoạt', 'icon': Icons.directions_car_filled_outlined, 'color': Colors.orange},
      // Chi phí phát sinh
      {'name': 'Mua sắm', 'group': 'Chi phí phát sinh', 'icon': Icons.shopping_bag_outlined, 'color': Colors.pink},
      {'name': 'Giải trí', 'group': 'Chi phí phát sinh', 'icon': Icons.movie_creation_outlined, 'color': Colors.pink},
      {'name': 'Làm đẹp', 'group': 'Chi phí phát sinh', 'icon': Icons.face_retouching_natural_outlined, 'color': Colors.pink},
      {'name': 'Sức khỏe', 'group': 'Chi phí phát sinh', 'icon': Icons.health_and_safety_outlined, 'color': Colors.pink},
      {'name': 'Từ thiện', 'group': 'Chi phí phát sinh', 'icon': Icons.favorite_border_outlined, 'color': Colors.pink},
      // Chi phí cố định
      {'name': 'Hóa đơn', 'group': 'Chi phí cố định', 'icon': Icons.receipt_outlined, 'color': Colors.blue},
      {'name': 'Nhà cửa', 'group': 'Chi phí cố định', 'icon': Icons.home_work_outlined, 'color': Colors.blue},
      {'name': 'Người thân', 'group': 'Chi phí cố định', 'icon': Icons.people_outline, 'color': Colors.blue},
      // Đầu tư - tiết kiệm
      {'name': 'Đầu tư', 'group': 'Đầu tư - tiết kiệm', 'icon': Icons.account_balance_outlined, 'color': Colors.teal},
      {'name': 'Học tập', 'group': 'Đầu tư - tiết kiệm', 'icon': Icons.school_outlined, 'color': Colors.teal},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final Map<String, List<Map<String, dynamic>>> grouped = {};
            for (var cat in categories) {
              final g = cat['group'] as String;
              if (!grouped.containsKey(g)) {
                grouped[g] = [];
              }
              grouped[g]!.add(cat);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Title Bar
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 8, top: 12, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Chọn danh mục",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Search & Add Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: const [
                                Icon(Icons.search, color: Colors.grey, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Tìm kiếm",
                                      border: InputBorder.none,
                                      isDense: true,
                                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_circle_outline, color: Colors.black87, size: 20),
                          label: const Text(
                            "Tạo mới",
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Switch Banner
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.bar_chart, color: Colors.teal),
                            SizedBox(width: 8),
                            Text(
                              "Tính khoản này vào Chi tiêu",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: localIsCounted,
                          activeColor: Colors.green,
                          onChanged: (val) {
                            setModalState(() {
                              localIsCounted = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Grid list of categories
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: grouped.keys.map((groupName) {
                          final items = grouped[groupName]!;

                          Color groupColor = Colors.orange;
                          if (groupName.contains("phát sinh")) groupColor = Colors.pink;
                          if (groupName.contains("cố định")) groupColor = Colors.blue;
                          if (groupName.contains("tiết kiệm")) groupColor = Colors.teal;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.bookmark, color: groupColor, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      groupName,
                                      style: TextStyle(
                                        color: groupColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.2,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, idx) {
                                    final cat = items[idx];
                                    final catName = cat['name'] as String;
                                    final catIcon = cat['icon'] as IconData;
                                    final isSelected = _categoryName == catName;

                                    return GestureDetector(
                                      onTap: () async {
                                        Navigator.pop(context);
                                        setState(() {
                                          _isUpdating = true;
                                        });

                                        final transId = _tx['transaction_id']?.toString() ?? '';
                                        final success = await updateTransactionCategory(transId, catName, localIsCounted);

                                        setState(() {
                                          _isUpdating = false;
                                          if (success) {
                                            _categoryName = catName;
                                            _isExpenseCounted = localIsCounted;
                                            _isUpdated = true;
                                          }
                                        });

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(success 
                                                  ? "Đã phân loại danh mục thành công!" 
                                                  : "Phân loại danh mục thất bại"),
                                              backgroundColor: success ? Colors.green : Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFFFF0F5) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          border: isSelected 
                                              ? Border.all(color: const Color(0xFFFFC0CB), width: 1.5)
                                              : null,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(catIcon, color: isSelected ? const Color(0xFFE91E63) : groupColor, size: 28),
                                            const SizedBox(height: 6),
                                            Text(
                                              catName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isSelected ? const Color(0xFFE91E63) : Colors.black87,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String amountRaw = _tx['amount']?.toString() ?? '0';
    final String createdTime = _tx['created_at'] != null 
        ? _formatDate(_tx['created_at']) 
        : '';
    final String entryType = _tx['entry_type'] ?? 'DEBIT';
    final String note = _tx['transfer_note'] ?? _tx['description'] ?? 'Giao dịch';
    final String extRef = _tx['external_reference']?.toString() ?? _tx['transaction_id']?.toString() ?? '';
    final bool isCredit = entryType == 'CREDIT';
    final String txType = _tx['transaction_type'] ?? 'TRANSFER';

    String typeLabelHeader = "GIAO DỊCH";
    String typeLabelText = "Giao dịch";
    if (txType == 'DEPOSIT') {
      typeLabelHeader = "NẠP TIỀN";
      typeLabelText = "Nạp tiền vào ví";
    } else if (txType == 'WITHDRAW') {
      typeLabelHeader = "RÚT TIỀN";
      typeLabelText = "Rút tiền về ngân hàng";
    } else if (txType == 'TRANSFER') {
      if (isCredit) {
        typeLabelHeader = "NHẬN TIỀN";
        typeLabelText = "Nhận tiền";
      } else {
        typeLabelHeader = "CHUYỂN TIỀN";
        typeLabelText = "Chuyển tiền";
      }
    }

    final String displayAmount = "${isCredit ? '+' : '-'}${_formatCurrency(amountRaw)}";

    // Receiver info if transfer
    final String receiverName = _tx['receiver_name'] ?? '';
    final String receiverPhone = _tx['receiver_phone'] ?? '';
    final String senderName = _tx['sender_name'] ?? '';
    final String senderPhone = _tx['sender_phone'] ?? '';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _isUpdated);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFE4E1), // Light pink gradient top
                Color(0xFFF7F8FA), // fade into background
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context, _isUpdated),
            ),
            title: const Text(
              "Chi Tiết Giao Dịch",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined, color: Colors.black54),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.black54),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Main Transaction card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top header block inside the card
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isCredit ? Icons.call_received : Icons.send,
                                  color: const Color(0xFFE91E63),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      typeLabelHeader,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      displayAmount,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        // Transaction details lines
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                "Trạng thái",
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "Thành công",
                                    style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              _buildDetailRow("Thời gian", child: Text(createdTime, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))),
                              _buildDetailRow(
                                "Mã giao dịch",
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(extRef, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: extRef));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Đã sao chép mã giao dịch"),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.copy,
                                        size: 14,
                                        color: Color(0xFFE91E63),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildDetailRow(
                                "Tài khoản/thẻ",
                                child: const Text("Ví MoMo", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                              ),
                              _buildDetailRow(
                                "Tổng",
                                child: const Text("Miễn phí", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                              ),
                              _buildDetailRow(
                                "Danh mục",
                                child: GestureDetector(
                                  onTap: _showCategoryBottomSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _categoryName == null 
                                          ? Colors.grey.shade100 
                                          : _getCategoryColor(_categoryName).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _categoryName == null 
                                            ? Colors.grey.shade300 
                                            : _getCategoryColor(_categoryName).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_categoryName != null && _getCategoryIcon(_categoryName) != null) ...[
                                          Icon(
                                            _getCategoryIcon(_categoryName),
                                            size: 14,
                                            color: _getCategoryColor(_categoryName),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          _categoryName ?? "Chưa phân loại",
                                          style: TextStyle(
                                            color: _categoryName == null ? Colors.grey.shade600 : _getCategoryColor(_categoryName),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.keyboard_arrow_down, 
                                          size: 14, 
                                          color: _categoryName == null ? Colors.grey.shade600 : _getCategoryColor(_categoryName),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Receiver/Sender info card
                  if (txType == 'TRANSFER')
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            isCredit ? "Tên người gửi" : "Tên Ví MoMo",
                            child: Text(
                              isCredit ? senderName : receiverName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildDetailRow(
                            "Tên danh bạ",
                            child: Text(
                              _getShortName(isCredit ? senderName : receiverName),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          _buildDetailRow(
                            "Số điện thoại",
                            child: Text(
                              isCredit ? senderPhone : receiverPhone,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isUpdating)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFE91E63)),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Tính năng Liên hệ CSKH đang được phát triển")),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE91E63), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Liên hệ CSKH",
                      style: TextStyle(
                        color: Color(0xFFE91E63),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final targetName = isCredit ? senderName : receiverName;
                      final targetPhone = isCredit ? senderPhone : receiverPhone;
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransferAmountScreen(
                            token: widget.token,
                            receiverName: targetName,
                            receiverPhone: targetPhone,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Chuyển thêm",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildDetailRow(String label, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

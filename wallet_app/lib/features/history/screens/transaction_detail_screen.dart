import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/transaction_category_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../widgets/category_bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import '../../transfer/screens/transfer_amount_screen.dart';
import '../../bank/screens/bank_transfer_input_screen.dart';
import '../../bank/screens/deposit_withdraw_screen.dart';
import '../../split_bill/screens/split_bill_select_people_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({
    Key? key,
    required this.token,
    required this.transaction,
  }) : super(key: key);

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Map<String, dynamic> _tx;
  String? _categoryName;
  late bool _isExpenseCounted;
  bool _isUpdating = false;
  bool _isUpdated = false;

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
    if (note.contains('chợ') ||
        note.contains('siêu thị') ||
        note.contains('mua sắm') ||
        note.contains('quần áo') ||
        note.contains('shopee')) {
      return "Chợ, siêu thị";
    }
    if (note.contains('điện') ||
        note.contains('nước') ||
        note.contains('internet') ||
        note.contains('mạng') ||
        note.contains('tiền nhà') ||
        note.contains('học phí') ||
        note.contains('hoá đơn')) {
      return "Hóa đơn";
    }
    return "Chưa phân loại";
  }

  @override
  void initState() {
    super.initState();
    _tx = Map<String, dynamic>.from(widget.transaction);

    final String? originalCategory = _tx['category_name'];
    if (originalCategory != null && originalCategory.isNotEmpty) {
      _categoryName = originalCategory;
    } else {
      final autoCat = TransactionCategoryHelper.determineCategoryTag(_tx);
      _categoryName = autoCat == "Chưa phân loại" ? null : autoCat;
    }

    _isExpenseCounted = _tx['is_expense_counted'] ?? true;
  }

  IconData? _getCategoryIcon(String? name) {
    if (name == null) return null;
    switch (name) {
      case 'Chợ, siêu thị':
        return Icons.shopping_basket_outlined;
      case 'Ăn uống':
        return Icons.restaurant_outlined;
      case 'Di chuyển':
        return Icons.directions_car_filled_outlined;
      case 'Mua sắm':
        return Icons.shopping_bag_outlined;
      case 'Giải trí':
        return Icons.movie_creation_outlined;
      case 'Làm đẹp':
        return Icons.face_retouching_natural_outlined;
      case 'Sức khỏe':
        return Icons.health_and_safety_outlined;
      case 'Từ thiện':
        return Icons.favorite_border_outlined;
      case 'Hóa đơn':
        return Icons.receipt_outlined;
      case 'Nhà cửa':
        return Icons.home_work_outlined;
      case 'Người thân':
        return Icons.people_outline;
      case 'Đầu tư':
        return Icons.account_balance_outlined;
      case 'Học tập':
        return Icons.school_outlined;
      case 'Nạp tiền':
        return Icons.account_balance_wallet_outlined;
      default:
        return null;
    }
  }

  Color _getCategoryColor(String? name) {
    if (name == null) return Colors.grey;
    if (name == 'Nạp tiền') return Colors.green;
    if (['Chợ, siêu thị', 'Ăn uống', 'Di chuyển'].contains(name))
      return Colors.orange;
    if ([
      'Mua sắm',
      'Giải trí',
      'Làm đẹp',
      'Sức khỏe',
      'Từ thiện',
    ].contains(name))
      return const Color(0xFFE91E63);
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

  String _formatTransactionId(String txId) {
    String digitsOnly = txId.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 12) {
      return digitsOnly.substring(0, 12);
    }
    return digitsOnly.padRight(12, '0');
  }

  Future<bool> updateTransactionCategory(
    String transId,
    String categoryName,
    bool isCounted,
  ) async {
    try {
      debugPrint(
        "Sending PUT category request for transId: $transId, category: $categoryName, counted: $isCounted",
      );
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

      debugPrint(
        "PUT category response: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        return resData['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint("Error updating transaction category: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String amountRaw = _tx['amount']?.toString() ?? '0';
    final String createdTime = _tx['created_at'] != null
        ? DateFormatter.format(_tx['created_at'])
        : '';
    final String entryType = _tx['entry_type'] ?? 'DEBIT';
    final String note =
        _tx['transfer_note'] ?? _tx['description'] ?? 'Giao dịch';
    final String extRef = _formatTransactionId(
        _tx['external_reference']?.toString() ??
        _tx['transaction_id']?.toString() ??
        '');
    final bool isCredit = entryType == 'CREDIT';
    final String txType = _tx['transaction_type'] ?? 'TRANSFER';

    final metadataRaw = _tx['metadata'];
    Map<String, dynamic>? metadata;
    if (metadataRaw != null) {
      if (metadataRaw is String) {
        try {
          metadata = jsonDecode(metadataRaw);
        } catch (e) {}
      } else if (metadataRaw is Map) {
        metadata = Map<String, dynamic>.from(metadataRaw);
      }
    }
    final bool isCardTopup = metadata != null && metadata.containsKey('card_code');
    final bool isTopup = txType == 'PAYMENT' && (
      note.toLowerCase().contains('mã thẻ') || 
      note.toLowerCase().contains('thẻ cào') || 
      note.toLowerCase().contains('nạp tiền điện thoại') || 
      note.toLowerCase().contains('nạp gói data')
    );
    
    String topupShortTitle = "Nạp tiền điện thoại";
    if (note.toLowerCase().contains('mã thẻ') || note.toLowerCase().contains('thẻ cào')) {
      topupShortTitle = "Mua thẻ cào";
    } else if (note.toLowerCase().contains('nạp gói data')) {
      topupShortTitle = "Nạp data 3G/4G";
    }
    final bool isRedPacket = note.toLowerCase().contains('lì xì') || 
      (_tx['receiver_name'] ?? '').toString().toLowerCase().contains('lì xì');

    // Receiver info if transfer or payment
    final String receiverName = _tx['receiver_name'] ?? '';
    final String receiverPhone = _tx['receiver_phone'] ?? '';
    final String senderName = _tx['sender_name'] ?? '';
    final String senderPhone = _tx['sender_phone'] ?? '';

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
    } else if (txType == 'PAYMENT') {
      if (isTopup) {
        typeLabelHeader = "MUA THẺ CÀO / NẠP ĐIỆN THOẠI";
        typeLabelText = note.isNotEmpty ? note : "Giao dịch nạp tiền";
      } else {
        typeLabelHeader = "THANH TOÁN ${receiverName.toUpperCase()}".trim();
        typeLabelText = "Thanh toán ${receiverName.isNotEmpty ? receiverName : 'cửa hàng'}";
      }
    } else if (txType == 'RECEIVE') {
      typeLabelHeader = "NHẬN LÌ XÌ";
      typeLabelText = note;
    } else if (txType == 'LOYALTY_REDEEM') {
      typeLabelHeader = "ĐỔI THẺ CÀO";
      typeLabelText = note.isNotEmpty ? note : "Đổi thẻ cào";
    }

    String btnText = "Chuyển thêm";
    if (txType == 'DEPOSIT') {
      btnText = "Nạp thêm";
    } else if (txType == 'WITHDRAW') {
      btnText = "Rút thêm";
    } else if (txType == 'PAYMENT') {
      btnText = "Chia tiền";
    }

    final bool isPoint = _tx['currency'] == 'POINT';
    final String formattedAmt = isPoint 
        ? "${CurrencyFormatter.format(amountRaw).replaceAll('đ', '').replaceAll('₫', '').trim()} Xu" 
        : CurrencyFormatter.format(amountRaw);
        
    final String displayAmount =
        "${isCredit ? '+' : '-'}$formattedAmt";

    final String cardCode = metadata?['card_code']?.toString() ?? '';
    final String serial = metadata?['serial']?.toString() ?? '';

    // Receiver info variables moved up

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
                  icon: const Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.black54,
                  ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    // Main Transaction card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
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
                                    color: txType == 'PAYMENT'
                                        ? Colors.orange.shade50
                                        : const Color(0xFFFFF0F2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    txType == 'PAYMENT'
                                        ? Icons.storefront
                                        : (isCredit
                                              ? Icons.call_received
                                              : Icons.send),
                                    color: txType == 'PAYMENT'
                                        ? Colors.orange
                                        : const Color(0xFFE91E63),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (txType == 'PAYMENT' && !isTopup)
                                            ? receiverName
                                            : (isTopup ? topupShortTitle : typeLabelHeader),
                                        style: TextStyle(
                                          fontSize: (txType == 'PAYMENT' && !isTopup)
                                              ? 16
                                              : 14,
                                          fontWeight: (txType == 'PAYMENT' && !isTopup)
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: (txType == 'PAYMENT' && !isTopup)
                                              ? Colors.black87
                                              : Colors.grey[600],
                                          letterSpacing: (txType == 'PAYMENT' && !isTopup)
                                              ? 0
                                              : 0.5,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
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
                                _buildDetailRow(
                                  "Thời gian",
                                  child: Text(
                                    createdTime,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                _buildDetailRow(
                                  "Mã giao dịch",
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        extRef,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(
                                            ClipboardData(text: extRef),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Đã sao chép mã giao dịch",
                                              ),
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
                                  child: Text(
                                    isPoint ? "Số dư Xu" : "Ví Mio",
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                _buildDetailRow(
                                  "Tổng",
                                  child: const Text(
                                    "Miễn phí",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if ((txType == 'LOYALTY_REDEEM' || isCardTopup) && cardCode.isNotEmpty) ...[
                                  _buildDetailRow(
                                    "Mã thẻ",
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          cardCode,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: cardCode));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Đã sao chép mã thẻ"), duration: Duration(seconds: 1)),
                                            );
                                          },
                                          child: const Icon(Icons.copy, size: 14, color: Colors.blue),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildDetailRow(
                                    "Số Serial",
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          serial,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: serial));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Đã sao chép số Serial"), duration: Duration(seconds: 1)),
                                            );
                                          },
                                          child: const Icon(Icons.copy, size: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (note.isNotEmpty && note != 'Giao dịch')
                                  _buildDetailRow(
                                    "Nội dung",
                                    child: Text(
                                      note,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (!isPoint)
                                  _buildDetailRow(
                                    "Danh mục",
                                  child: GestureDetector(
                                    onTap: () {
                                      CategoryBottomSheet.show(
                                        context,
                                        currentCategory: _categoryName,
                                        initialIsCounted: _isExpenseCounted,
                                        onCategorySelected:
                                            (categoryName, isCounted) async {
                                              final transId =
                                                  _tx['transaction_id']
                                                      ?.toString() ??
                                                  '';
                                              final success =
                                                  await updateTransactionCategory(
                                                    transId,
                                                    categoryName,
                                                    isCounted,
                                                  );
                                              if (success && mounted) {
                                                setState(() {
                                                  _categoryName = categoryName;
                                                  _isExpenseCounted = isCounted;
                                                  _isUpdated = true;
                                                });
                                              }
                                              return success;
                                            },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _categoryName == null
                                            ? Colors.grey.shade100
                                            : _getCategoryColor(
                                                _categoryName,
                                              ).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _categoryName == null
                                              ? Colors.grey.shade300
                                              : _getCategoryColor(
                                                  _categoryName,
                                                ).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_categoryName != null &&
                                              _getCategoryIcon(_categoryName) !=
                                                  null) ...[
                                            Icon(
                                              _getCategoryIcon(_categoryName),
                                              size: 14,
                                              color: _getCategoryColor(
                                                _categoryName,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            _categoryName ?? "Chưa phân loại",
                                            style: TextStyle(
                                              color: _categoryName == null
                                                  ? Colors.grey.shade600
                                                  : _getCategoryColor(
                                                      _categoryName,
                                                    ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 14,
                                            color: _categoryName == null
                                                ? Colors.grey.shade600
                                                : _getCategoryColor(
                                                    _categoryName,
                                                  ),
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
                    if ((txType == 'TRANSFER' ||
                        txType == 'PAYMENT' ||
                        txType == 'RECEIVE') && !isTopup && !isCardTopup && !isRedPacket)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: txType == 'PAYMENT'
                              ? [
                                  _buildDetailRow(
                                    "Dịch vụ",
                                    child: Text(
                                      receiverName,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _buildDetailRow(
                                    "Cửa hàng",
                                    child: Text(
                                      receiverName.isNotEmpty
                                          ? receiverName
                                                .toUpperCase()
                                                .replaceAll(' ', '')
                                          : "STORE",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  _buildDetailRow(
                                    "Nội dung",
                                    child: Text(
                                      note,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  _buildDetailRow(
                                    "Mã đơn hàng",
                                    child: Text(
                                      extRef,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  _buildDetailRow(
                                    isCredit ? "Tên người gửi" : "Tên Ví Mio",
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
                                      _getShortName(
                                        isCredit ? senderName : receiverName,
                                      ),
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
                color: Colors.black.withValues(alpha: 0.15),
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
                          const SnackBar(
                            content: Text(
                              "Tính năng Liên hệ CSKH đang được phát triển",
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFE91E63),
                          width: 1.5,
                        ),
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
                        final String entryType = _tx['entry_type'] ?? 'DEBIT';
                        final String txType =
                            _tx['transaction_type'] ?? 'TRANSFER';
                        final bool isCredit = entryType == 'CREDIT';
                        final String noteStr =
                            _tx['transfer_note'] ?? _tx['description'] ?? '';

                        if (txType == 'WITHDRAW' &&
                            noteStr.contains('Chuyển tiền đến tài khoản')) {
                          String accNum = "";
                          String bName = "Ngân hàng";
                          RegExp exp = RegExp(r'tài khoản (\d+) - (.+)');
                          Match? match = exp.firstMatch(noteStr);
                          if (match != null) {
                            accNum = match.group(1) ?? "";
                            bName = match.group(2) ?? "Ngân hàng";
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BankTransferInputScreen(
                                token: widget.token,
                                bankName: bName,
                                bankCode: "OTHER",
                                prefilledAccountNumber: accNum,
                              ),
                            ),
                          );
                          return;
                        }

                        if (txType == 'DEPOSIT') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DepositWithdrawScreen(
                                token: widget.token,
                                initialTab: 0,
                              ),
                            ),
                          );
                          return;
                        }

                        if (txType == 'WITHDRAW') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DepositWithdrawScreen(
                                token: widget.token,
                                initialTab: 1,
                              ),
                            ),
                          );
                          return;
                        }

                        if (txType == 'PAYMENT') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SplitBillSelectPeopleScreen(
                                token: widget.token,
                                transactionData: _tx,
                              ),
                            ),
                          );
                          return;
                        }

                        final targetName = isCredit ? senderName : receiverName;
                        final targetPhone = isCredit
                            ? senderPhone
                            : receiverPhone;

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
                      child: Text(
                        btnText,
                        style: const TextStyle(
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
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          child,
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import 'split_bill_select_people_screen.dart';

class SplitBillManagementScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> me;

  const SplitBillManagementScreen({
    Key? key,
    required this.token,
    required this.me,
  }) : super(key: key);

  @override
  State<SplitBillManagementScreen> createState() =>
      _SplitBillManagementScreenState();
}

class _SplitBillManagementScreenState extends State<SplitBillManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _client = CustomHttpClient();
  final NumberFormat _formatter = NumberFormat('#,###', 'vi_VN');

  bool _isLoading = true;
  List<dynamic> _receivables = [];
  List<dynamic> _payables = [];
  final Set<String> _remindedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/split-bill/me'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (mounted) {
          setState(() {
            _receivables = data['receivables'] ?? [];
            _payables = data['payables'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePayment(String memberRecordId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          try {
            final response = await _client.post(
              Uri.parse('${ApiConfig.baseUrl}/split-bill/pay'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'member_record_id': memberRecordId,
                'pin': pin,
              }),
            );

            if (response.statusCode == 200) {
              Navigator.pop(context); // Close bottom sheet
              SnackbarUtils.showSuccess(context, 'Thanh toán thành công');
              _loadData();
              return null;
            } else {
              final errorData = jsonDecode(response.body);
              return errorData['error'] ?? 'Giao dịch thất bại';
            }
          } catch (e) {
            return 'Lỗi kết nối mạng';
          }
        },
      ),
    );
  }

  Future<void> _handleRemind(String billId) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/split-bill/remind/$billId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _remindedIds.add(billId);
        });
        SnackbarUtils.showSuccess(context, 'Đã gửi nhắc nhở thành công.');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể gửi nhắc nhở')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lỗi kết nối mạng')));
    }
  }

  Future<void> _handleCancel(String billId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy yêu cầu chia tiền này không? (Sẽ xóa khỏi danh sách)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/split-bill/cancel/$billId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        _showSuccessDialog('Đã hủy yêu cầu chia tiền thành công.');
        _loadData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể hủy yêu cầu')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lỗi kết nối mạng')));
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Thành công',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Đóng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE4E1), Color(0xFFF6F8FB)],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Chia tiền",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.star_border_rounded,
                  color: Colors.black54,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.headset_mic_rounded,
                  color: Colors.black54,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.home_rounded, color: Colors.black54),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.push_pin_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ghim Chia tiền lên trang chủ để dễ dàng quản lý các yêu cầu chia tiền của bạn!",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Thêm ngay",
                          style: TextStyle(
                            color: Colors.pink.shade400,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.close_rounded,
                  color: Colors.black54,
                  size: 18,
                ),
              ],
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Quản lý khoản cần trả/cần thu",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFE91E63),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFE91E63),
                  tabs: const [
                    Tab(text: "Đang chờ"),
                    Tab(text: "Đã xong"),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.pink),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [_buildPendingTab(), _buildCompletedTab()],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SplitBillSelectPeopleScreen(
                      token: widget.token,
                      transactionData: const {},
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Tạo yêu cầu chia tiền",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    final pendingPayables = _payables
        .where((p) => p['my_status'] == 'PENDING')
        .toList();
    final pendingReceivables = _receivables
        .where((r) => r['status'] == 'PENDING')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cần trả (${pendingPayables.length})",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (pendingPayables.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "Không có khoản nào cần trả",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...pendingPayables.map((p) => _buildPayableCard(p)),

          const SizedBox(height: 16),
          Text(
            "Cần thu (${pendingReceivables.length})",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (pendingReceivables.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "Không có khoản nào cần thu",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...pendingReceivables.map((r) => _buildReceivableCard(r)),
        ],
      ),
    );
  }

  Widget _buildCompletedTab() {
    final completedPayables = _payables
        .where((p) => p['my_status'] == 'PAID')
        .toList();
    final completedReceivables = _receivables
        .where((r) => r['status'] == 'COMPLETED')
        .toList();

    if (completedPayables.isEmpty && completedReceivables.isEmpty) {
      return const Center(
        child: Text("Không có dữ liệu", style: TextStyle(color: Colors.grey)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Đã trả (${completedPayables.length})",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...completedPayables.map(
            (p) => _buildPayableCard(p, isCompleted: true),
          ),

          const SizedBox(height: 16),
          Text(
            "Đã thu đủ (${completedReceivables.length})",
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...completedReceivables.map(
            (r) => _buildReceivableCard(r, isCompleted: true),
          ),
        ],
      ),
    );
  }

  Widget _buildPayableCard(
    Map<String, dynamic> item, {
    bool isCompleted = false,
  }) {
    String creatorName = item['creator_name'] ?? 'Người dùng';
    double amount = double.tryParse(item['my_amount']?.toString() ?? '0') ?? 0;
    String note = item['note'] ?? '';
    DateTime date =
        DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.pie_chart_rounded,
                          color: Colors.blue,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Chia tiền",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note.isNotEmpty
                        ? (note.length > 20
                              ? "${note.substring(0, 20)}..."
                              : note)
                        : "Lời nhắn",
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(date),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: item['creator_avatar'] != null
                    ? NetworkImage(item['creator_avatar'])
                    : null,
                child: item['creator_avatar'] == null
                    ? Text(
                        creatorName.isNotEmpty
                            ? creatorName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creatorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_formatter.format(amount)}đ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompleted)
                ElevatedButton(
                  onPressed: () =>
                      _handlePayment(item['member_record_id'].toString()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    "Thanh toán",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                const Text(
                  "Đã thanh toán",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceivableCard(
    Map<String, dynamic> item, {
    bool isCompleted = false,
  }) {
    List<dynamic> members = item['members'] ?? [];
    int totalMembers = members.length;
    int paidMembers = members.where((m) => m['status'] == 'PAID').length;

    double splitAmount =
        double.tryParse(item['split_amount']?.toString() ?? '0') ?? 0;
    double totalAmount =
        double.tryParse(item['total_amount']?.toString() ?? '0') ?? 0;
    double receivedAmount = paidMembers * splitAmount;

    String note = item['note'] ?? '';
    DateTime date =
        DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.grey.shade200 : Colors.green.shade200,
          width: isCompleted ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? Colors.black.withValues(alpha: 0.02)
                : Colors.green.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.pie_chart_rounded,
                          color: Colors.pink,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Chia tiền",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note.isNotEmpty
                        ? (note.length > 20
                              ? "${note.substring(0, 20)}..."
                              : note)
                        : "Lời nhắn",
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(date),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.pink.shade50,
                child: Text(
                  widget.me['name']?[0] ?? 'M',
                  style: const TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tổng cần thu",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          "Nhận ",
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        Text(
                          "${_formatter.format(receivedAmount)}đ",
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          " / ${_formatter.format(totalAmount)}đ",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: totalMembers > 0
                              ? (paidMembers / totalMembers)
                              : 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isCompleted) ...[
                    const Text(
                      "Chưa nhận đủ",
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _handleCancel(item['id'].toString()),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text(
                            "Hủy",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _remindedIds.contains(item['id'].toString())
                            ? OutlinedButton(
                                onPressed: null,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: const Text(
                                  "Đã nhắc nhở",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: () =>
                                    _handleRemind(item['id'].toString()),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFE91E63),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                child: const Text(
                                  "Nhắc nhở",
                                  style: TextStyle(
                                    color: Color(0xFFE91E63),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      "Đã nhận đủ",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

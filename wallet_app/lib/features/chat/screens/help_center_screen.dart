import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/services/custom_http_client.dart';
import '../../ai/screens/ai_chat_screen.dart';
import '../../history/screens/transaction_history_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  final String token;
  final String fullName;
  final String phone;

  const HelpCenterScreen({
    Key? key,
    required this.token,
    required this.fullName,
    required this.phone,
  }) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final CustomHttpClient _client = CustomHttpClient();
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.getTransactionHistory}?limit=5'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _transactions = data['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return '';
    final parts = fullName.trim().split(' ');
    return parts.last;
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0đ';
    final number = double.tryParse(amount.toString()) ?? 0;
    return '${NumberFormat('#,###', 'vi_VN').format(number)}đ';
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4EE), // Pink header
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trung tâm Trợ giúp',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildOnlineSupportBanner(),
            const SizedBox(height: 16),
            _buildTransactionQueries(),
            const Divider(thickness: 6, color: Color(0xFFF5F5F5)),
            _buildHelpTopics(),
            const Divider(thickness: 6, color: Color(0xFFF5F5F5)),
            _buildFAQSection(),
            _buildFeedbackBanner(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFFFE4EE),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 40,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Chào ',
                            style: TextStyle(
                              color: AppColors.primaryPink,
                              fontSize: 24,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: '${_getFirstName(widget.fullName)} 👋',
                            style: const TextStyle(
                              color: AppColors.primaryPink,
                              fontSize: 24,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mio có thể giúp gì cho bạn?',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.pink.shade100, width: 2),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      size: 50,
                      color: AppColors.primaryPink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Search Bar Positioned Overlap
        Positioned(
          bottom: -20,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search_rounded, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Tìm kiếm vấn đề của bạn tại đây',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: const [
                  Icon(
                    Icons.history_rounded,
                    color: AppColors.primaryPink,
                    size: 20,
                  ),
                  Text(
                    'Lịch sử',
                    style: TextStyle(
                      color: AppColors.primaryPink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineSupportBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.pink.shade100),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primaryPink,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hỗ trợ trực tuyến',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trả lời mọi câu hỏi của bạn 24/7',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiChatScreen(token: widget.token),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(120, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Chat với Mio',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionQueries() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thắc mắc về giao dịch?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TransactionHistoryScreen(token: widget.token),
                      ),
                    );
                  },
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primaryPink),
              ),
            )
          else if (_transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Không có giao dịch gần đây.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  final isPositive =
                      tx['type'] == 'DEPOSIT' ||
                      tx['type'] == 'TRANSFER' &&
                          tx['receiver_phone'] != null &&
                          tx['amount'] != null &&
                          tx['sender_phone'] != null &&
                          tx['type'] == 'TRANSFER' &&
                          tx['amount'] > 0; // Simplified
                  // Actually let's just determine color by tx_type
                  bool isReceive =
                      tx['type'] == 'DEPOSIT' ||
                      (tx['type'] == 'TRANSFER' &&
                          tx['receiver_phone'] !=
                              widget
                                  .phone); // Very rough logic just for UI display
                  final color = Colors.black87;
                  String prefix = tx['type'] == 'DEPOSIT' ? '+' : '-';

                  return Container(
                    width: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['type'] == 'DEPOSIT'
                                        ? 'Nạp tiền vào ví'
                                        : 'Giao dịch',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormatter.format(tx['created_at']),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    'Mã giao dịch: ${tx['transaction_code'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Thành công',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '$prefix${CurrencyFormatter.format(tx['amount'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHelpTopics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Trợ giúp theo chủ đề',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Xem tất cả',
                style: TextStyle(
                  color: AppColors.primaryPink,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: [
              _buildTopicIcon(Icons.play_circle_outline_rounded, 'Mới bắt đầu'),
              _buildTopicIcon(
                Icons.card_giftcard_rounded,
                'Ưu đãi và Quà\ncủa tôi',
              ),
              _buildTopicIcon(
                Icons.account_balance_rounded,
                'Ngân hàng và\nNguồn tiền',
              ),
              _buildTopicIcon(
                Icons.receipt_long_rounded,
                'Thanh toán dịch\nvụ',
              ),
              _buildTopicIcon(Icons.sports_esports_rounded, 'Trò chơi'),
              _buildTopicIcon(Icons.security_rounded, 'Tài khoản và\nbảo mật'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.pink.shade50.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryPink, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFAQSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Các vấn đề thường gặp',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _buildFAQItem('Làm thế nào để liên hệ với Chăm sóc Khách hàng Mio?'),
          _buildFAQItem(
            'Làm thế nào để điều chuyển tài khoản Ví cũ sang Ví mới?',
          ),
          _buildFAQItem(
            'Tôi nên làm gì khi phát hiện có giao dịch bất thường hoặc bị mất tiền trong ví Mio?',
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryPink,
              ),
              label: const Text(
                'Xem thêm',
                style: TextStyle(
                  color: AppColors.primaryPink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryPink),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String text) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.black87,
          ),
          onTap: () {},
        ),
        const Divider(height: 1, color: Color(0xFFF5F5F5)),
      ],
    );
  }

  Widget _buildFeedbackBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.feedback_rounded,
            color: AppColors.primaryPink,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mio cần bạn góp ý',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mỗi đề xuất của bạn là động lực để Mio cải thiện từng chút một.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {},
                    child: const Text(
                      'Khám phá ngay',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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

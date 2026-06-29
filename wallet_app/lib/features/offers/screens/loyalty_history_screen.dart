import 'package:flutter/material.dart';
import '../services/loyalty_service.dart';
import '../../../core/utils/date_formatter.dart';
import 'package:intl/intl.dart';
import '../../history/screens/transaction_detail_screen.dart';

class LoyaltyHistoryScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> summary;

  const LoyaltyHistoryScreen({
    Key? key,
    required this.token,
    required this.summary,
  }) : super(key: key);

  @override
  State<LoyaltyHistoryScreen> createState() => _LoyaltyHistoryScreenState();
}

class _LoyaltyHistoryScreenState extends State<LoyaltyHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoyaltyService _loyaltyService = LoyaltyService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  Widget _buildTopSection() {
    final int todayPoints = widget.summary['todayPoints'] ?? 0;
    final int expiringPoints = widget.summary['expiringPoints'] ?? 0;
    final String nearestExpiration = widget.summary['nearestExpiration'] ?? '';

    String expiringText = '';
    if (expiringPoints > 0 && nearestExpiration.isNotEmpty) {
      final DateTime date = DateTime.parse(nearestExpiration);
      final formattedDate = DateFormat('dd-MM-yyyy').format(date);
      expiringText = '$expiringPoints Xu sẽ hết hạn vào $formattedDate';
    }

    return Container(
      color: const Color(0xFFFFF0F5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
                    child: const Text('m', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatNumber(widget.summary['totalPoints'] ?? 0),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Tích thêm Xu',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                const TextSpan(text: 'Bạn đã nhận '),
                TextSpan(
                  text: '${_formatNumber(todayPoints)} Xu',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' hôm nay'),
              ],
            ),
          ),
          if (expiringText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    expiringText,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử Xu'),
        backgroundColor: const Color(0xFFFFF0F5),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.headset_mic_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.home_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildTopSection(),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.orange,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Đã nhận'),
                Tab(text: 'Đã dùng'),
                Tab(text: 'Thu hồi'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _HistoryListTab(token: widget.token, tabName: 'EARNED', service: _loyaltyService),
                _HistoryListTab(token: widget.token, tabName: 'SPENT', service: _loyaltyService),
                _HistoryListTab(token: widget.token, tabName: 'REVOKED', service: _loyaltyService),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryListTab extends StatefulWidget {
  final String token;
  final String tabName;
  final LoyaltyService service;

  const _HistoryListTab({Key? key, required this.token, required this.tabName, required this.service}) : super(key: key);

  @override
  State<_HistoryListTab> createState() => _HistoryListTabState();
}

class _HistoryListTabState extends State<_HistoryListTab> {
  bool _isLoading = true;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await widget.service.getLoyaltyHistory(widget.token, widget.tabName, 1);
    setState(() {
      _data = result;
      _isLoading = false;
    });
  }

  Widget _getIconForTransaction(String description) {
    if (description.toLowerCase().contains('google play')) {
      return const Icon(Icons.play_arrow, color: Colors.blue, size: 24); // mock icon
    }
    if (description.toLowerCase().contains('thanh toán')) {
      return const Icon(Icons.storefront, color: Colors.cyan, size: 24);
    }
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
      child: const Center(
        child: Text('m', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (_data.isEmpty) {
      return const Center(child: Text('Chưa có giao dịch nào'));
    }

    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) {
        final group = _data[index];
        final month = group['month'];
        final List items = group['items'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                month,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ...items.map((item) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailScreen(
                        token: widget.token,
                        transaction: Map<String, dynamic>.from(item),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _getIconForTransaction(item['description']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['description'] ?? 'Giao dịch',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.format(item['created_at']),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['display_amount'],
                      style: TextStyle(
                        color: widget.tabName == 'EARNED' ? Colors.orange : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList()
          ],
        );
      },
    );
  }
}

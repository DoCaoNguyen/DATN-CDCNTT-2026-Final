import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'redeem_scratch_card_screen.dart';
import 'loyalty_history_screen.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../services/loyalty_service.dart';

class OffersScreen extends StatefulWidget {
  final String token;
  final String loyaltyPoints;
  final Future<void> Function() onRefresh;

  const OffersScreen({
    Key? key,
    required this.token,
    required this.loyaltyPoints,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoyaltyService _loyaltyService = LoyaltyService();
  Map<String, dynamic> _summary = {};
  int _currentStreak = 0;
  bool _checkedInToday = false;
  bool _isLoadingCheckin = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    final summary = await _loyaltyService.getLoyaltySummary(widget.token);
    final checkinStatus = await _loyaltyService.getCheckinStatus(widget.token);
    if (mounted) {
      setState(() {
        _summary = summary;
        _currentStreak = checkinStatus['currentStreak'] ?? 0;
        _checkedInToday = checkinStatus['checkedInToday'] ?? false;
        _isLoadingCheckin = false;
      });
    }
  }

  Future<void> _handleCheckin() async {
    if (_checkedInToday) return;

    setState(() {
      _isLoadingCheckin = true;
    });

    final result = await _loyaltyService.checkin(widget.token);
    if (result['success'] == true) {
      final data = result['data'];
      final isGift = data['isGift'] ?? false;
      final reward = data['rewardPoints'] ?? 50;
      
      setState(() {
        _checkedInToday = true;
        _currentStreak = data['newStreak'] ?? _currentStreak + 1;
        _isLoadingCheckin = false;
      });

      if (isGift) {
        _showGiftAnimation(reward);
      } else {
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Điểm danh thành công! +$reward Xu');
        }
      }
      
      // Refresh balance
      widget.onRefresh();
      _fetchData();
    } else {
      setState(() {
        _isLoadingCheckin = false;
      });
      if (mounted) {
        SnackbarUtils.showError(context, result['message'] ?? 'Lỗi điểm danh');
      }
    }
  }

  void _showGiftAnimation(int rewardPoints) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _GiftBoxAnimationDialog(rewardPoints: rewardPoints);
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatNumber(String value) {
    final number = int.tryParse(value);
    if (number == null) return "0";
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: Colors.pink,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom Header & Balance Section
            SliverToBoxAdapter(
              child: _buildHeaderSection(),
            ),
            
            // TabBar Sticky
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.pink,
                    indicatorWeight: 3,
                    labelColor: Colors.pink,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                    tabs: [
                      const Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard, size: 20),
                            SizedBox(width: 8),
                            Text('Sẵn quà'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400, width: 1.5)),
                              child: const Text('m', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1, color: Colors.grey)),
                            ),
  
                            const SizedBox(width: 8),
                            Text('Tích Xu'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // TabBarView content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabSanQua(),
                  _buildTabTichXu(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3F2FD), Color(0xFFF5F5F9)], // Light blue to very light grey/pinkish
        ),
      ),
      child: Column(
        children: [
          // Custom App Bar (Search + Icons)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.search, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Text('Tìm kiếm ưu đãi...', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: const Icon(Icons.notifications_none, color: Colors.black87, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: const Icon(Icons.chat_bubble_outline, color: Colors.black87, size: 20),
                  ),
                ],
              ),
            ),
          ),
          
          // Balance Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
                              child: const Text('m', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatNumber(widget.loyaltyPoints),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoyaltyHistoryScreen(
                                  token: widget.token,
                                  summary: _summary,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Lịch sử Xu',
                              style: TextStyle(color: Colors.pink.shade600, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Builder(builder: (context) {
                      final int expiringPoints = _summary['expiringPoints'] ?? 0;
                      final String nearestExpiration = _summary['nearestExpiration'] ?? '';
                      if (expiringPoints > 0 && nearestExpiration.isNotEmpty) {
                        final DateTime date = DateTime.parse(nearestExpiration);
                        final formattedDate = DateFormat('dd-MM-yyyy').format(date);
                        return Text(
                          '$expiringPoints xu sẽ hết hạn vào $formattedDate',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.shade200),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.card_giftcard, size: 18, color: Colors.black54),
                              const SizedBox(width: 8),
                              const Text('Quà của tôi', style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                child: const Text('34', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 20, color: Colors.grey.shade300),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_scanner, size: 18, color: Colors.black54),
                              const SizedBox(width: 8),
                              const Text('Nhập mã', style: TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------- TAB SẴN QUÀ -------
  Widget _buildTabSanQua() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Categories
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryItem(Icons.vibration, 'Lắc ngay\ntrúng quà', Colors.blue),
                _buildCategoryItem(Icons.account_balance_wallet, 'Hoàn tiền\nmua sắm', Colors.green),
                _buildCategoryItem(Icons.receipt_long, 'Thanh toán\nhóa đơn', Colors.pink),
                _buildCategoryItem(Icons.emoji_events, 'Nhiệm vụ\nsăn quà', Colors.purple),
                _buildCategoryItem(Icons.card_giftcard, 'Đổi thẻ cào', Colors.orange, onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RedeemScratchCardScreen(
                        loyaltyPoints: widget.loyaltyPoints.toString(),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Banner 1
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange.shade100, Colors.orange.shade50]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                            children: [
                              const TextSpan(text: 'Ví Trả Sau - Hoàn tiền '),
                              TextSpan(text: '50%', style: TextStyle(color: Colors.pink.shade600, fontSize: 20)),
                            ]
                          )
                        ),
                        const SizedBox(height: 4),
                        const Text('Tối đa 10K/giao dịch tại 500K+ cửa hàng khắp phố phường.', style: TextStyle(fontSize: 12, color: Colors.black54), maxLines: 2),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.pink.shade200)),
                      child: Text('Khám phá', style: TextStyle(color: Colors.pink.shade600, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Banner 2
        Container(
          color: Colors.yellow.shade50,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Mio Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(height: 4),
                    const Text('xả Xu đón hè\nSăn deal đồng giá cực xịn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Ngày 25 hằng tháng', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.beach_access, size: 60, color: Colors.orangeAccent),
            ],
          ),
        ),

        const SizedBox(height: 16),
        
        // Deals List
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildDealCard('Ví Trả Sau', 'Hoàn 35K', 'Cho đơn từ 35K', 'Thu thập', Colors.pink.shade50, true),
              _buildDealCard('GS25', 'Ưu đãi 5K', 'Cho đơn từ 30K tại ...', '50', Colors.white, false, originalPrice: '5.000'),
              _buildDealCard('Hóa đơn', 'Ưu đãi 3K', 'Cho đơn từ 100K', '10', Colors.white, false, originalPrice: '3.000'),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCategoryItem(IconData icon, String title, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDealCard(String brand, String title, String subtitle, String actionText, Color bgColor, bool isActionButton, {String? originalPrice}) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            alignment: Alignment.topRight,
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
              child: Text(brand, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                if (isActionButton)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.pink),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(actionText, style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.w500, fontSize: 12)),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
                        child: const Text('m', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1)),
                      ),
                      const SizedBox(width: 4),
                      Text(actionText, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
                      if (originalPrice != null) ...[
                        const SizedBox(width: 4),
                        Text(originalPrice, style: const TextStyle(color: Colors.grey, fontSize: 10, decoration: TextDecoration.lineThrough)),
                      ]
                    ],
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ------- TAB TÍCH XU -------
  Widget _buildTabTichXu() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily Check-in Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text('Điểm danh mỗi ngày nhận quà', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(7, (index) {
                    int dayIndex = index + 1; // 1 to 7
                    
                    // Correct logic for check-in days
                    bool isPast = dayIndex <= _currentStreak;
                    bool isToday = !_checkedInToday && dayIndex == (_currentStreak + 1);
                    
                    bool isGift = dayIndex == 3 || dayIndex == 5 || dayIndex == 7;
                    
                    String dayLabel = isToday ? 'Hôm nay' : 'Ngày $dayIndex';
                    String value = isGift ? '???' : '+50';
                    
                    return _buildCheckinDay(
                      dayLabel, 
                      value, 
                      isToday, 
                      isGift, 
                      isPast: isPast,
                      index: index,
                    );
                  }),
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Info Section
        const Text('Tìm hiểu về Xu trên Mio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildInfoCard('Tích Xu với\nmọi giao dịch', Colors.orange.shade50, Colors.orange.shade800),
              _buildInfoCard('Đổi Xu nhận\nưu đãi', Colors.pink.shade50, Colors.pink.shade800),
              _buildInfoCard('Đổi Xu\nthanh toán', Colors.blue.shade50, Colors.blue.shade800),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Real Deals Section (Đổi Thẻ Cào here)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Đủ Xu đổi liền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade600),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RedeemScratchCardScreen(
                        loyaltyPoints: widget.loyaltyPoints,
                      ),
                    ),
                  );
                },
                child: _buildDealCard('Đổi Thẻ Cào', 'Đổi thẻ cào ĐT', 'Mệnh giá 10K - 100K', '10.000', Colors.pink.shade50, false),
              ),
              _buildDealCard('Gong Cha', 'Ưu đãi 20K', 'Cho đơn từ 120K', '39', Colors.pink.shade50, false, originalPrice: '20.000'),
              _buildDealCard('Long Châu', 'Ưu đãi 30K', 'Cho đơn từ 549K', '79', Colors.blue.shade50, false, originalPrice: '30.000'),
            ],
          ),
        ),

        const SizedBox(height: 24),
        
        // Tasks Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.track_changes, color: Colors.orange, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nhiệm vụ Tích Xu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Nhận 10.000 Xu cực dễ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade600),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCheckinDay(String dayLabel, String value, bool isToday, bool isGift, {bool isPast = false, int index = 0}) {
    
    Widget content = Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isToday ? Colors.white : Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: isToday ? Colors.green : Colors.grey.shade300, width: isToday ? 2 : 1),
            ),
            alignment: Alignment.center,
            child: isPast 
              ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
              : isGift 
                ? const Icon(Icons.card_giftcard, color: Colors.pink, size: 20)
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber),
                    child: const Text('m', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1)),
                  ),
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? Colors.green : Colors.grey)),
          const SizedBox(height: 2),
          Text(dayLabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );

    if (isToday) {
      return InkWell(
        onTap: _isLoadingCheckin ? null : _handleCheckin,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: _isLoadingCheckin ? 0.5 : 1.0,
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildInfoCard(String text, Color bgColor, Color textColor) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return true;
  }
}

class _GiftBoxAnimationDialog extends StatefulWidget {
  final int rewardPoints;

  const _GiftBoxAnimationDialog({Key? key, required this.rewardPoints}) : super(key: key);

  @override
  State<_GiftBoxAnimationDialog> createState() => _GiftBoxAnimationDialogState();
}

class _GiftBoxAnimationDialogState extends State<_GiftBoxAnimationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.elasticOut))
    );

    _controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _isOpen = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (_isOpen) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Column(
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 80),
                            const SizedBox(height: 16),
                            Text(
                              '+${widget.rewardPoints} Xu',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Nhận quà', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  )
                ],
              );
            }

            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _shakeAnimation.value,
                child: const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 100),
              ),
            );
          },
        ),
      ),
    );
  }
}

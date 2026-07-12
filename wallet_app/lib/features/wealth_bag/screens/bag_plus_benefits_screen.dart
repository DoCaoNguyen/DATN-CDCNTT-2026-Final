import 'package:flutter/material.dart';

class BagPlusBenefitsScreen extends StatefulWidget {
  final int initialIndex;

  const BagPlusBenefitsScreen({Key? key, this.initialIndex = 0})
    : super(key: key);

  @override
  State<BagPlusBenefitsScreen> createState() => _BagPlusBenefitsScreenState();
}

class _BagPlusBenefitsScreenState extends State<BagPlusBenefitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  late final DateTime now;
  late final int currentMonth;
  late final int nextMonth;
  late final int lastDayOfMonth;
  late final String currentMonthStr;

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    currentMonth = now.month;
    nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
    lastDayOfMonth = DateTime(now.year, currentMonth + 1, 0).day;
    currentMonthStr = currentMonth.toString().padLeft(2, '0');

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _selectedTab = widget.initialIndex;
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _selectedTab == 2;

    // Determine background color based on selected tab
    Color bgColor;
    if (_selectedTab == 0) {
      bgColor = const Color(0xFFEAF2FB); // Silver: Light blue
    } else if (_selectedTab == 1) {
      bgColor = const Color(0xFFFFF6DF); // Gold: Light yellow
    } else {
      bgColor = const Color(0xFF141414); // Platinum: Dark
    }

    final Color appBarColor = bgColor;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quyền lợi hạng Túi+',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.headset_mic_outlined, color: textColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.home_outlined, color: textColor),
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tier tab bar
          Container(
            color: appBarColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: Colors.black87,
                unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Bạc'),
                  Tab(text: 'Vàng'),
                  Tab(text: 'Bạch Kim'),
                ],
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSilverTab(context),
                _buildGoldTab(context),
                _buildPlatinumTab(context),
              ],
            ),
          ),
        ],
      ),

      // Sticky footer with price and buy button
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Price section
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '* Sở hữu Túi+ ngay từ giờ đến hết $lastDayOfMonth/$currentMonthStr',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Giá chỉ',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _selectedTab == 0
                          ? '9.000đ '
                          : _selectedTab == 1
                          ? '19.000đ '
                          : '49.000đ ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE85D04),
                      ),
                    ),
                    Text(
                      _selectedTab == 0
                          ? '19.000đ'
                          : _selectedTab == 1
                          ? '39.000đ'
                          : '69.000đ',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black38,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Buy button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D04),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Thông báo'),
                    content: const Text(
                      'Tính năng Mua Túi+ đang được phát triển. Vui lòng quay lại sau!',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Đã hiểu',
                          style: TextStyle(color: Color(0xFFE85D04)),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                'Mua ngay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSilverTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Silver tier intro card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTierIcon(
                  gradientColors: const [Color(0xFFF8FAFC), Color(0xFFCBD5E1)],
                  borderColor: const Color(0xFFF1F5F9),
                  shadowColor: const Color(0xFF829AB1),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hạng Bạc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Càng dùng càng thêm lợi - bắt đầu hành trình tài chính hiệu quả nhẹ nhàng mỗi ngày.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '*Thời hạn Túi+: 1 tháng (1/$currentMonth - $lastDayOfMonth/$currentMonthStr)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Benefits card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quyền lợi từ Túi+',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                _buildBenefitItem(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFFE85D04),
                  title: 'Thêm ',
                  titleHighlight: '50 triệu',
                  titleSuffix: ' hạn mức rút miễn phí',
                  subtitle: 'Khi rút tiền từ Túi về ngân hàng',
                ),
                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                _buildBenefitItem(
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFFE85D04),
                  title: 'Thêm ',
                  titleHighlight: '0,2%/năm',
                  titleSuffix: ' lãi gửi tiết kiệm',
                  subtitle: 'Áp dụng với ngân hàng BVBank',
                ),
                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                _buildBenefitItem(
                  icon: Icons.monetization_on_outlined,
                  iconColor: const Color(0xFFE85D04),
                  title: 'Thêm Xu đổi Voucher',
                  titleHighlight: null,
                  titleSuffix: null,
                  subtitle: null,
                  bulletPoints: const [
                    'Cộng 1 Xu mỗi 10K thanh toán với Túi',
                    'Cộng thêm Xu đến 8%/năm',
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Free tier card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhận Túi+ Bạc tháng $nextMonth miễn phí',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hoàn thành điều kiện dưới đây trước ngày $lastDayOfMonth/$currentMonthStr để nhận quyền lợi miễn phí.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hoàn thành 1 trong 3 cách',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMethodCard(
                  icon: Icons.phone_android,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: Colors.orange,
                  title: 'Cách 1: Nạp tiền điện thoại',
                  description:
                      'Đạt hạng Thuê bao Tâm giao của dịch vụ Nạp tiền điện thoại',
                  actionText: 'Thực hiện →',
                ),
                const SizedBox(height: 10),
                _buildMethodCard(
                  icon: Icons.savings_outlined,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: Colors.orange,
                  title: 'Cách 2: Nhận tiền tự động vào Túi',
                  description:
                      'Bật Nhận tiền tự động vào Túi và nhận 7 triệu tiền chuyển đến Ví của bạn.',
                  actionText: 'Thực hiện →',
                ),
                const SizedBox(height: 10),
                _buildMethodCard(
                  icon: Icons.emoji_events_outlined,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: Colors.orange,
                  title:
                      'Cách 3: Đạt hạng Khỏe mạnh của Điểm MoMo (601 - 700 điểm)',
                  description:
                      'Vào Điểm MoMo ngày 3 hàng tháng để kiểm tra hạng và nhận Túi+ miễn phí.',
                  actionText: 'Đến Điểm MoMo →',
                  actionColor: const Color(0xFFE85D04),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGoldTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold tier intro card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF9E6), Color(0xFFFFF3CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTierIcon(
                  gradientColors: const [Color(0xFFFFF9DB), Color(0xFFFFD43B)],
                  borderColor: const Color(0xFFFFEC99),
                  shadowColor: const Color(0xFFD48806),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hạng Vàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Cân bằng giữa tích lũy và chi tiêu – đầu tư cho tương lai từ những thói quen hàng ngày.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '*Thời hạn Túi+: 1 tháng (1/$currentMonth - $lastDayOfMonth/$currentMonthStr)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Benefits card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quyền lợi từ Túi+',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                _buildBenefitItem(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFFFFAA00),
                  title: 'Thêm ',
                  titleHighlight: '100 triệu',
                  titleSuffix: ' hạn mức rút miễn phí',
                  subtitle: 'Khi rút tiền từ Túi về ngân hàng',
                ),
                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                _buildBenefitItem(
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFFFFAA00),
                  title: 'Thêm ',
                  titleHighlight: '0,3%/năm',
                  titleSuffix: ' lãi gửi tiết kiệm',
                  subtitle: 'Áp dụng với ngân hàng BVBank',
                ),
                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                _buildBenefitItem(
                  icon: Icons.refresh_outlined,
                  iconColor: const Color(0xFFFFAA00),
                  title: 'Thêm hoàn tiền ',
                  titleHighlight: '0,1%',
                  titleSuffix: null,
                  subtitle: null,
                  bulletPoints: const [
                    'Khi thanh toán hóa đơn điện, nước, Internet và nạp tiền điện thoại',
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                _buildBenefitItem(
                  icon: Icons.monetization_on_outlined,
                  iconColor: const Color(0xFFFFAA00),
                  title: 'Thêm Xu đổi Voucher',
                  titleHighlight: null,
                  titleSuffix: null,
                  subtitle: null,
                  bulletPoints: const [
                    'Cộng 2 Xu mỗi 10K thanh toán với Túi',
                    'Cộng thêm Xu đến 12%/năm',
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Free tier card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhận Túi+ Vàng tháng $nextMonth miễn phí',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hoàn thành điều kiện dưới đây trước ngày $lastDayOfMonth/$currentMonthStr để nhận quyền lợi miễn phí.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hoàn thành 1 trong 2 cách',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMethodCard(
                  icon: Icons.checklist_outlined,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: Colors.orange,
                  title: 'Cách 1: Hoàn thành tất cả nhiệm vụ sau',
                  description:
                      'Hoàn thành đầy đủ các nhiệm vụ được giao trong tháng để nhận Túi+ Vàng miễn phí.',
                  actionText: 'Thực hiện →',
                ),
                const SizedBox(height: 10),
                _buildMethodCard(
                  icon: Icons.emoji_events_outlined,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: Colors.orange,
                  title:
                      'Cách 2: Đạt hạng Đỉnh cao của Điểm MoMo (trên 700 điểm)',
                  description:
                      'Vào Điểm MoMo ngày 3 hàng tháng để kiểm tra hạng và nhận Túi+ miễn phí.',
                  actionText: 'Đến Điểm MoMo →',
                  actionColor: const Color(0xFFE85D04),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlatinumTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platinum header (dark background handled by Scaffold)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTierIcon(
                gradientColors: const [Color(0xFFFFF4E6), Color(0xFFFFD8A8)],
                borderColor: const Color(0xFFFFE8CC),
                shadowColor: const Color(0xFFFAAD14),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hạng Bạch Kim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Khởi đầu hành trình tài chính đẳng cấp – mỗi giao dịch đều được ưu ái và thêm lợi',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '*Thời hạn Túi+: 1 tháng (1/$currentMonth - $lastDayOfMonth/$currentMonthStr)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Benefits card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quyền lợi từ Túi+',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                _buildBenefitItem(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Colors.black54,
                  title: 'Hạn mức rút miễn phí ',
                  titleHighlight: 'không giới hạn',
                  titleSuffix: null,
                  subtitle: 'Khi rút tiền từ Túi về ngân hàng',
                ),
                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                _buildBenefitItem(
                  icon: Icons.timer_outlined,
                  iconColor: Colors.black54,
                  title: 'Thêm ',
                  titleHighlight: '0,5%/năm',
                  titleSuffix: ' lãi gửi tiết kiệm',
                  subtitle: 'Áp dụng với ngân hàng BVBank',
                ),
                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                _buildBenefitItem(
                  icon: Icons.refresh_outlined,
                  iconColor: Colors.black54,
                  title: 'Thêm hoàn tiền ',
                  titleHighlight: '0,1%',
                  titleSuffix: ' không giới hạn',
                  subtitle: 'Khi thanh toán với Túi',
                ),
                const Divider(height: 24, color: Color(0xFFEEEEEE)),
                _buildBenefitItem(
                  icon: Icons.monetization_on_outlined,
                  iconColor: Colors.black54,
                  title: 'Thêm Xu đổi Voucher',
                  titleHighlight: null,
                  titleSuffix: null,
                  subtitle: null,
                  bulletPoints: const [
                    'Cộng 4 Xu mỗi 10K thanh toán với Túi',
                    'Cộng thêm Xu đến 15%/năm',
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Free tier card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhận Túi+ Bạch Kim tháng $nextMonth miễn phí',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hoàn thành điều kiện dưới đây trước ngày $lastDayOfMonth/$currentMonthStr để nhận quyền lợi miễn phí.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hoàn thành nhiệm vụ sau',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Duy trì số dư Túi',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.savings_outlined,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Số dư Túi trung bình tháng này đạt 50 triệu',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Thực hiện →',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE85D04),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTierIcon({
    required List<Color> gradientColors,
    required Color borderColor,
    required Color shadowColor,
  }) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(-1, -1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String? titleHighlight,
    required String? titleSuffix,
    required String? subtitle,
    List<String>? bulletPoints,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleHighlight != null
                  ? RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: title),
                          TextSpan(
                            text: titleHighlight,
                            style: const TextStyle(
                              color: Color(0xFFE85D04),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (titleSuffix != null) TextSpan(text: titleSuffix),
                        ],
                      ),
                    )
                  : Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
              if (bulletPoints != null) ...[
                const SizedBox(height: 4),
                ...bulletPoints.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $b',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String description,
    required String actionText,
    Color actionColor = Colors.black45,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: 13,
                color: actionColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

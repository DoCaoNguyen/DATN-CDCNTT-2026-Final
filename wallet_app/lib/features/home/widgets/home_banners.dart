import 'package:flutter/material.dart';
import '../../transfer/screens/transfer_main_screen.dart';
import '../../bank/screens/bank_transfer_list_screen.dart';
import '../../split_bill/screens/split_bill_management_screen.dart';
import '../../topup/screens/topup_main_screen.dart';

class FinancialCenterBanner extends StatelessWidget {
  final String activeLang;
  final String fullName;

  const FinancialCenterBanner({
    Key? key,
    required this.activeLang,
    required this.fullName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                activeLang == 'VIE'
                    ? "Trung Tâm Tài Chính của $fullName"
                    : "$fullName's Financial Center",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.blue.shade700,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class HomeEventBanner extends StatelessWidget {
  final String activeLang;
  final String token;
  final Map<String, dynamic> me;

  const HomeEventBanner({
    Key? key,
    required this.activeLang,
    required this.token,
    required this.me,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activeLang == 'VIE' ? "Sự kiện đang diễn ra" : "Ongoing Events",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                activeLang == 'VIE' ? "Xem tất cả" : "See all",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFC62828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFC62828), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -20,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 110,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          activeLang == 'VIE'
                              ? "Chia tiền hóa đơn"
                              : "Split Bill Easily",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: Text(
                            activeLang == 'VIE'
                                ? "Chia tiền hóa đơn giao dịch cho bạn bè khi thanh toán chung."
                                : "Split your transaction bills with friends easily.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SplitBillManagementScreen(
                                  token: token,
                                  me: me,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              activeLang == 'VIE'
                                  ? "Khám phá ngay"
                                  : "Explore Now",
                              style: const TextStyle(
                                color: Color(0xFFC62828),
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
            ),
          ),
        ],
      ),
    );
  }
}

class HomeRecommendations extends StatelessWidget {
  final String activeLang;
  final String token;
  final Map<String, dynamic> me;

  const HomeRecommendations({
    Key? key,
    required this.activeLang,
    required this.token,
    required this.me,
  }) : super(key: key);

  Widget buildRecommendItem(
    BuildContext context,
    IconData icon,
    String? badge,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        color: Colors.transparent,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                if (badge != null)
                  Positioned(
                    top: -8,
                    left: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              activeLang == 'VIE' ? "Mio đề xuất" : "Recommended",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                buildRecommendItem(
                  context,
                  Icons.send_rounded,
                  null,
                  activeLang == 'VIE' ? "Chuyển tiền" : "Transfer",
                  Colors.pink,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransferMainScreen(token: token),
                    ),
                  ),
                ),
                buildRecommendItem(
                  context,
                  Icons.account_balance_rounded,
                  null,
                  activeLang == 'VIE' ? "Ngân hàng" : "Bank",
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BankTransferListScreen(token: token),
                    ),
                  ),
                ),
                buildRecommendItem(
                  context,
                  Icons.pie_chart_rounded,
                  null,
                  activeLang == 'VIE' ? "Chia tiền" : "Split bill",
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SplitBillManagementScreen(token: token, me: me),
                    ),
                  ),
                ),
                buildRecommendItem(
                  context,
                  Icons.phone_android_rounded,
                  null,
                  activeLang == 'VIE' ? "Nạp ĐT" : "Topup",
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TopupMainScreen(token: token),
                    ),
                  ),
                ),
                buildRecommendItem(
                  context,
                  Icons.redeem_rounded,
                  null,
                  activeLang == 'VIE' ? "Lì xì" : "Lucky money",
                  Colors.red.shade400,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          activeLang == 'VIE'
                              ? "Chức năng đang phát triển"
                              : "Feature in development",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

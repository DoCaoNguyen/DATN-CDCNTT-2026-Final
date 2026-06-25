import 'package:flutter/material.dart';

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

  const HomeEventBanner({Key? key, required this.activeLang}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activeLang == 'VIE' ? "Sự kiện đang diễn ra" : "Ongoing Events",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.red,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.2,
                      child: Container(color: Colors.black),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeLang == 'VIE'
                              ? "Dùng Ví Trả Sau\nHoàn tiền 50%*"
                              : "Use Postpaid Wallet\n50% Cashback*",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeLang == 'VIE'
                              ? "Tối đa 10k mọi giao dịch từ 1-30/6"
                              : "Max 10k for all transactions June 1-30",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activeLang == 'VIE' ? "Khám phá ngay" : "Explore Now",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
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

  const HomeRecommendations({Key? key, required this.activeLang})
    : super(key: key);

  Widget buildRecommendItem(
    IconData icon,
    String? badge,
    String title,
    Color color,
  ) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
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
    );
  }

  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
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
                  Icons.campaign_rounded,
                  activeLang == 'VIE' ? "Từ 220k" : "From 220k",
                  activeLang == 'VIE'
                      ? "Loa thông\nbáo chuyển ..."
                      : "Payment\nSpeaker",
                  Colors.pink,
                ),
                buildRecommendItem(
                  Icons.card_giftcard_rounded,
                  activeLang == 'VIE' ? "Hoàn 50%" : "50% Back",
                  activeLang == 'VIE'
                      ? "Ví Trả Sau -\nHoàn 50%"
                      : "Postpaid -\n50% Back",
                  Colors.pinkAccent,
                ),
                buildRecommendItem(
                  Icons.sports_esports_rounded,
                  null,
                  activeLang == 'VIE' ? "Mã thẻ Game\nOnline" : "Game\nCards",
                  Colors.blue,
                ),
                buildRecommendItem(
                  Icons.account_balance_wallet_rounded,
                  null,
                  activeLang == 'VIE' ? "Túi Thần Tài" : "Wealth Bag",
                  Colors.orange,
                ),
                buildRecommendItem(
                  Icons.electric_bolt_rounded,
                  null,
                  activeLang == 'VIE'
                      ? "Thanh toán\nđiện"
                      : "Electricity\nBill",
                  Colors.yellow.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

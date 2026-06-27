import 'package:flutter/material.dart';
import 'redeem_scratch_card_screen.dart';

class OffersScreen extends StatelessWidget {
  final String token;
  final String loyaltyPoints;

  const OffersScreen({
    Key? key,
    required this.token,
    required this.loyaltyPoints,
  }) : super(key: key);

  String _formatNumber(String value) {
    final number = int.tryParse(value);
    if (number == null) return "0";
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  Widget _buildOfferCategory(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<int> cardValues = [10000, 20000, 30000, 50000, 100000];

    return Scaffold(
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
        elevation: 0,
        title: const Text(
          'Ưu đãi & Đổi Xu',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text(
                  _formatNumber(loyaltyPoints),
                  style: TextStyle(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Danh mục Ưu đãi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildOfferCategory(
                      context,
                      'Đổi Thẻ Cào',
                      Icons.phone_android_rounded,
                      Colors.blue,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RedeemScratchCardScreen(
                              loyaltyPoints: loyaltyPoints,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildOfferCategory(
                      context,
                      'Mã Giảm Giá',
                      Icons.discount_rounded,
                      Colors.pink,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sắp ra mắt!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

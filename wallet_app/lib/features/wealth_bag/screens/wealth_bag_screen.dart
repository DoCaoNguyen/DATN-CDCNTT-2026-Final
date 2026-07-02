import 'package:flutter/material.dart';

class WealthBagScreen extends StatefulWidget {
  final String token;

  const WealthBagScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<WealthBagScreen> createState() => _WealthBagScreenState();
}

class _WealthBagScreenState extends State<WealthBagScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Túi Thần Tài",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFDF9F1), Color(0xFFF7F4EF)],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Chào mừng bạn đến với Túi Thần Tài",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Nạp ít nhất 20.000đ vào Túi để nhận tiền lời mỗi ngày. Bạn có thể rút tiền bất kỳ lúc nào.",
                      style: TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepItem("Mở Túi", Icons.check_circle, Colors.deepOrange, true),
                        _buildStepItem("Nạp tiền từ\n20.000đ", Icons.radio_button_checked, Colors.deepOrange, false, isCenter: true),
                        _buildStepItem("Nhận tiền lời", Icons.check_circle, Colors.grey.shade300, false),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // TODO: Handle deposit logic
                        },
                        icon: const Icon(Icons.login_rounded, color: Colors.white),
                        label: const Text(
                          "Nạp tiền ngay",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: Colors.black54),
                  SizedBox(width: 4),
                  Text(
                    "Tài sản của bạn được lưu ký tại Vietcombank",
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: const Text(
                "Túi Thần Tài là sản phẩm tài chính của Công ty Cổ phần Finsight giúp người dùng góp vốn hợp tác kinh doanh với Finsight trên nền tảng ứng dụng Mio. Vốn được ủy thác cho CTCP Quản lý quỹ Thiên Việt và lưu ký an toàn tại Vietcombank. Đây là đầu tư linh hoạt, không phải tiền gửi tiết kiệm – bạn nhớ đọc kỹ thông tin.",
                style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.5),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: "Tổng quan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Lịch sử",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Cộng đồng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_task),
            label: "Túi+",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Tôi",
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, IconData icon, Color color, bool isCompleted, {bool isCenter = false}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.savings, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCenter ? FontWeight.bold : FontWeight.normal,
              color: isCenter ? Colors.deepOrange : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

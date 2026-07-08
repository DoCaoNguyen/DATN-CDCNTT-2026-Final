import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../services/wealth_bag_service.dart';
import 'wealth_bag_transaction_screen.dart';

import '../widgets/wealth_bag_history_tab.dart';
import '../widgets/bag_plus_tab.dart';

class WealthBagScreen extends StatefulWidget {
  final String token;

  const WealthBagScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<WealthBagScreen> createState() => _WealthBagScreenState();
}

class _WealthBagScreenState extends State<WealthBagScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isActive = false;
  double _balance = 0;
  double _profit = 0;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final data = await WealthBagService().getStatus(widget.token);
      if (data != null) {
        setState(() {
          _isActive = data['is_active'] ?? false;
          _balance = double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0;
          _profit = double.tryParse(data['total_profit']?.toString() ?? '0') ?? 0.0;
          
          if (_balance > 0 || _profit > 0) _isActive = true;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint("Error fetching wealth bag status: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }
  
  String _formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return "${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
    }
    String formatted = amount.toStringAsFixed(2);
    while (formatted.endsWith('0') && formatted.contains('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    List<String> parts = formatted.split('.');
    String intPart = parts[0].replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    if (parts.length > 1) return "$intPart,${parts[1]}đ";
    return "$intPartđ";
  }

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
        title: Text(
          _currentIndex == 1
              ? "Lịch sử giao dịch"
              : _currentIndex == 2
                  ? "Túi+"
                  : "Túi Thần Tài",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : (_currentIndex == 1
              ? const WealthBagHistoryTab()
              : _currentIndex == 2
                  ? const BagPlusTab()
                  : (_isActive ? _buildDashboard() : _buildWelcome())),
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

  Widget _buildDashboard() {
    return SingleChildScrollView(
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
            child: Column(
              children: [
                // Balance Card
                Container(
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
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                          child: const Text("Cơ hội sinh lời đến 4%/năm", style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Tiền trong Túi", style: TextStyle(color: Colors.black54, fontSize: 14)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _isBalanceVisible ? _formatAmount(_balance) : '******',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                                  child: Icon(_isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black54, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text("Tiền lời sẽ được cộng vào Túi\nsau 2-4 ngày", style: TextStyle(color: Colors.black54, fontSize: 12)),
                                ),
                                Container(width: 1, height: 24, color: Colors.grey.shade300),
                                const SizedBox(width: 12),
                                const Text("Xem tổng hợp\ntiền lời", style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.deepOrange, size: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_circle, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(child: Text("Thêm Túi+, thêm quyền lợi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                            Icon(Icons.chevron_right, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Actions Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildActionItem(Icons.swap_horiz, "Nạp/Rút", onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const WealthBagTransactionScreen())).then((_) => _fetchStatus());
                    })),
                    Expanded(child: _buildActionItem(Icons.account_balance, "Chuyển khoản\nvào Túi")),
                    Expanded(child: _buildActionItem(Icons.receipt_long, "Chuyển tiền\nThanh toán")),
                    Expanded(child: _buildActionItem(Icons.chat_bubble_outline, "Tin nhắn", hasNotification: true)),
                  ],
                ),
                const SizedBox(height: 24),
                // Security Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    const Text("Tài sản của bạn được lưu ký tại Vietcombank", style: TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Colors.grey.shade100,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Túi Thần Tài là sản phẩm của Công ty Cổ phần Finsight (chi tiết bên dưới)", style: TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
                          children: [
                            TextSpan(text: "✨ Tiền lời lần đầu sẽ được cộng vào Túi sau 2 - 4 ngày. Sau lần đầu, bạn sẽ nhận tiền lời mỗi ngày. "),
                            TextSpan(text: "Xem cách tính tiền lời", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Stack(
                        children: [
                          Positioned(
                            top: 65,
                            left: 45,
                            right: 45,
                            child: Row(
                              children: [
                                Expanded(child: Container(height: 2, color: Colors.deepOrange)),
                                Expanded(child: Container(height: 2, color: Colors.deepOrange.shade100)),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStepItem(0, "Mở Túi", Icons.check_circle, Colors.deepOrange, true),
                              _buildStepItem(1, "Nạp tiền từ\n20.000đ", Icons.check_circle, Colors.deepOrange, true, isCenter: true),
                              _buildStepItem(2, "Nhận tiền lời", Icons.radio_button_checked, Colors.deepOrange, false),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.money, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(child: Text("Tối ưu tiền của bạn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                          Icon(Icons.chevron_right, color: Colors.pink.shade300, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text("Phân chia, tích lũy và sinh lời", style: TextStyle(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFeatureCard("Tích lũy lâu dài", "7% cho 6 th...", "Gửi tiết kiệm", Colors.pink.shade50, Colors.pink),
                            const SizedBox(width: 12),
                            _buildFeatureCard("Nhiều mục đích", "Chia từng ...", "Tạo Quỹ ng...", Colors.purple.shade50, Colors.purple),
                            const SizedBox(width: 12),
                            _buildFeatureCard("Tài sản của bạn", "Cập nhật n...", "Mọi nguồn ...", Colors.green.shade50, Colors.green),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, {bool hasNotification = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng đang phát triển")));
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.deepOrange, size: 24),
              ),
              if (hasNotification)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String highlight, String subtitle, Color bgColor, Color iconColor) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(highlight, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: iconColor)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Icon(Icons.stars, color: iconColor.withOpacity(0.5), size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
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
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Chào mừng bạn đến với Túi Thần Tài", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Nạp ít nhất 20.000đ vào Túi để nhận tiền lời mỗi ngày. Bạn có thể rút tiền bất kỳ lúc nào.", style: TextStyle(color: Colors.black87, fontSize: 14)),
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      Positioned(
                        top: 65,
                        left: 45,
                        right: 45,
                        child: Row(
                          children: [
                            Expanded(child: Container(height: 2, color: Colors.deepOrange)),
                            Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepItem(0, "Mở Túi", Icons.check_circle, Colors.deepOrange, true),
                          _buildStepItem(1, "Nạp tiền từ\n20.000đ", Icons.radio_button_checked, Colors.deepOrange, false, isCenter: true),
                          _buildStepItem(2, "Nhận tiền lời", Icons.check_circle, Colors.grey.shade300, false),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const WealthBagTransactionScreen())).then((_) => _fetchStatus());
                      },
                      icon: const Icon(Icons.login_rounded, color: Colors.white),
                      label: const Text("Nạp tiền ngay", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                Text("Tài sản của bạn được lưu ký tại Vietcombank", style: TextStyle(color: Colors.black54, fontSize: 13)),
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
    );
  }

  Widget _buildStepItem(int index, String title, IconData icon, Color color, bool isCompleted, {bool isCenter = false}) {
    Widget topIcon;
    if (index == 0) {
      topIcon = Transform.translate(
        offset: const Offset(-8, 0),
        child: Icon(Icons.savings, color: Colors.pink.shade200, size: 36),
      );
    } else if (index == 1) {
      topIcon = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.savings, color: Colors.pink.shade200, size: 36),
          const Positioned(
            top: -12,
            child: Icon(Icons.monetization_on, color: Colors.amber, size: 16),
          ),
        ],
      );
    } else {
      topIcon = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.savings, color: Colors.red, size: 36),
          const Positioned(top: -4, left: -8, child: Icon(Icons.star, color: Colors.amber, size: 12)),
          const Positioned(top: -12, right: -4, child: Icon(Icons.monetization_on, color: Colors.amber, size: 14)),
          const Positioned(top: 8, right: -12, child: Icon(Icons.monetization_on, color: Colors.amber, size: 16)),
        ],
      );
    }

    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Center(child: topIcon),
          ),
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(icon, color: color, size: 20),
          ),
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

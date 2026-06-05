import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../auth/screens/kyc_flow_screen.dart';
import '../../transfer/screens/transfer_main_screen.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/constants/api_config.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final bool isVerified;
  final String token;

  const HomeScreen({
    Key? key,
    this.userId = '',
    this.isVerified = true,
    this.token = '',
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String _balance = "0";
  bool _isLoadingBalance = true;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();

    if (!widget.isVerified && widget.userId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showKycDialog();
      });
    }

    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    if (widget.token.isEmpty) {
      setState(() => _isLoadingBalance = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getWalletBalance),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _balance = responseData['data']['available_balance'] ?? "0";
          _isLoadingBalance = false;
        });
      } else {
        setState(() => _isLoadingBalance = false);
      }
    } catch (e) {
      print("Lỗi lấy số dư ví: $e");
      setState(() => _isLoadingBalance = false);
    }
  }

  String _formatCurrency(String amount) {
    try {
      final value = int.parse(amount);
      return "${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
    } catch (e) {
      return "0đ";
    }
  }

  void _showKycDialog() {
    String activeLang = AppState.currentLanguage.value;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          activeLang == 'VIE' ? 'Yêu cầu xác thực' : 'Authentication Required',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          activeLang == 'VIE'
              ? 'Tài khoản của bạn chưa được xác thực danh tính. Vui lòng hoàn tất eKYC để sử dụng dịch vụ.'
              : 'Your account is not verified. Please complete eKYC to use our services.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              activeLang == 'VIE' ? 'Để sau' : 'Later',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KycFlowScreen(userId: widget.userId),
                ),
              );
            },
            child: Text(
              activeLang == 'VIE' ? 'Xác thực ngay' : 'Verify Now',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.currentLanguage,
      builder: (context, activeLang, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),

          body: _buildBody(activeLang),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (!widget.isVerified) {
                _showKycDialog();
              } else {
                print("Mở Camera quét QR");
              }
            },
            backgroundColor: Colors.pink,
            elevation: 2,
            shape: const CircleBorder(),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 28,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            color: Colors.white,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBottomNavItem(
                        Icons.home,
                        "MoMo",
                        0,
                        isActive: true,
                      ),
                      _buildBottomNavItem(
                        Icons.local_offer_outlined,
                        activeLang == 'VIE' ? "Ưu đãi" : "Offers",
                        1,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Text(
                      activeLang == 'VIE' ? "Quét mọi QR" : "Scan QR",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBottomNavItem(
                        Icons.history,
                        activeLang == 'VIE' ? "Lịch sử GD" : "History",
                        2,
                      ),
                      _buildBottomNavItem(
                        Icons.person_outline,
                        activeLang == 'VIE' ? "Tôi" : "Me",
                        3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(String activeLang) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeaderSection(activeLang),
          _buildWalletCard(activeLang),
          _buildFinancialCenterBanner(activeLang),
          _buildServicesGrid(activeLang),
          _buildEventBanner(activeLang),
          _buildRecommendations(activeLang),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(String activeLang) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0F7FA), Color(0xFFF1F8E9), Colors.white],
        ),
      ),
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      hintText: activeLang == 'VIE'
                          ? "Tìm bạn bè để chuyển tiền"
                          : "Find friends to transfer",
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 28,
                    color: Colors.black54,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chat_bubble_outline,
                size: 28,
                color: Colors.black54,
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickAction(
                Icons.account_balance_wallet,
                Colors.pink,
                activeLang == 'VIE' ? "Nạp/Rút" : "Deposit",
              ),
              _buildQuickAction(
                Icons.qr_code,
                Colors.pink,
                activeLang == 'VIE' ? "Nhận tiền" : "Receive",
              ),
              _buildQuickAction(
                Icons.qr_code_scanner,
                Colors.pink,
                activeLang == 'VIE' ? "QR Thanh toán" : "QR Pay",
              ),
              _buildQuickAction(
                Icons.apps,
                Colors.pink,
                activeLang == 'VIE' ? "Ví tiện ích" : "Utilities",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(String activeLang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                      child: Icon(
                        _isBalanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activeLang == 'VIE' ? "Ví MoMo" : "MoMo Wallet",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "momo",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isLoadingBalance
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.pink,
                            ),
                          )
                        : Text(
                            _isBalanceVisible
                                ? _formatCurrency(_balance)
                                : "******",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      activeLang == 'VIE' ? "Ví Trả Sau" : "Postpaid Wallet",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.card_giftcard,
                      size: 14,
                      color: Colors.pink.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activeLang == 'VIE' ? "Dự phòng 5Tr" : "5M Reserve",
                  style: const TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      activeLang == 'VIE' ? "Túi Thần Tài" : "Wealth Bag",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const Text("🐂", style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activeLang == 'VIE' ? "Mở Túi ngay" : "Open Now",
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCenterBanner(String activeLang) {
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
              Icon(
                Icons.shield_outlined,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                activeLang == 'VIE'
                    ? "Trung Tâm Tài Chính của Thống"
                    : "Thong's Financial Center",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Icon(Icons.chevron_right, color: Colors.blue.shade700, size: 20),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(String activeLang) {
    // Icons.swap_horiz chính là biểu tượng 2 mũi tên chuyển tiền
    final List<Map<String, dynamic>> services = [
      {
        'icon': Icons.swap_horiz,
        'name': activeLang == 'VIE' ? 'Chuyển tiền' : 'Transfer',
        'color': Colors.red,
      },
      {
        'icon': Icons.account_balance,
        'name': activeLang == 'VIE'
            ? 'Chuyển tiền\nNgân hàng'
            : 'Bank\nTransfer',
        'color': Colors.blue,
      },
      {
        'icon': Icons.receipt_long,
        'name': activeLang == 'VIE' ? 'Thanh toán hóa\nđơn' : 'Pay\nBills',
        'color': Colors.teal,
      },
      {
        'icon': Icons.phone_android,
        'name': activeLang == 'VIE' ? 'Nạp tiền điện\nthoại' : 'Mobile\nTop-up',
        'color': Colors.blueAccent,
      },
      {
        'icon': Icons.four_g_mobiledata,
        'name': 'Data 4G/5G',
        'color': Colors.blue,
      },
      {
        'icon': Icons.card_giftcard,
        'name': activeLang == 'VIE'
            ? 'Ví Trả Sau Hoàn\n50%'
            : 'Postpaid\n50% Back',
        'color': Colors.pink,
        'badge': activeLang == 'VIE' ? 'Hoàn 50%' : '50% Back',
      },
      {
        'icon': Icons.monetization_on,
        'name': activeLang == 'VIE' ? 'Vay Nhanh' : 'Fast Loan',
        'color': Colors.orange,
      },
      {
        'icon': Icons.credit_card,
        'name': activeLang == 'VIE' ? 'Ví Trả Sau' : 'Postpaid Wallet',
        'color': Colors.pinkAccent,
      },
      {
        'icon': Icons.home_work_outlined,
        'name': activeLang == 'VIE' ? 'Thanh toán\nkhoản vay' : 'Loan\nPayment',
        'color': Colors.orangeAccent,
      },
      {
        'icon': Icons.movie_creation_outlined,
        'name': activeLang == 'VIE' ? 'Mua vé xem\nphim' : 'Movie\nTickets',
        'color': Colors.deepOrange,
      },
      {
        'icon': Icons.flight_takeoff,
        'name': activeLang == 'VIE' ? 'Du lịch - Đi lại' : 'Travel',
        'color': Colors.pink,
        'badge': '06 06',
      },
      {
        'icon': Icons.grid_view,
        'name': activeLang == 'VIE' ? 'Xem thêm dịch\nvụ' : 'More\nServices',
        'color': Colors.grey,
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 16,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return GestureDetector(
            onTap: () {
              if (!widget.isVerified) {
                _showKycDialog();
              } else {
                // --- ĐÃ SỬA: Gắn logic chuyển trang đúng vào nút 2 mũi tên (Chuyển tiền) ---
                if (service['name'] == 'Chuyển tiền' ||
                    service['name'] == 'Transfer') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransferMainScreen(token: widget.token),
                    ),
                  );
                  _fetchBalance();
                } else {
                  print("Chuyển sang dịch vụ: ${service['name']}");
                }
              }
            },
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: service['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        service['icon'],
                        color: service['color'],
                        size: 28,
                      ),
                    ),
                    if (service['badge'] != null)
                      Positioned(
                        top: -8,
                        right: -12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            service['badge'],
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
                  service['name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventBanner(String activeLang) {
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

  Widget _buildRecommendations(String activeLang) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              activeLang == 'VIE' ? "MoMo đề xuất" : "Recommended",
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
                _buildRecommendItem(
                  Icons.campaign,
                  activeLang == 'VIE' ? "Từ 220k" : "From 220k",
                  activeLang == 'VIE'
                      ? "Loa thông\nbáo chuyển ..."
                      : "Payment\nSpeaker",
                  Colors.pink,
                ),
                _buildRecommendItem(
                  Icons.card_giftcard,
                  activeLang == 'VIE' ? "Hoàn 50%" : "50% Back",
                  activeLang == 'VIE'
                      ? "Ví Trả Sau -\nHoàn 50%"
                      : "Postpaid -\n50% Back",
                  Colors.pinkAccent,
                ),
                _buildRecommendItem(
                  Icons.sports_esports,
                  null,
                  activeLang == 'VIE' ? "Mã thẻ Game\nOnline" : "Game\nCards",
                  Colors.blue,
                ),
                _buildRecommendItem(
                  Icons.account_balance_wallet,
                  null,
                  activeLang == 'VIE' ? "Túi Thần Tài" : "Wealth Bag",
                  Colors.orange,
                ),
                _buildRecommendItem(
                  Icons.electric_bolt,
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

  Widget _buildQuickAction(IconData icon, Color color, String title) {
    return GestureDetector(
      onTap: () {
        if (!widget.isVerified) {
          _showKycDialog();
        } else {
          // Khôi phục lại hành động chỉ print ra terminal cho 4 nút tròn phía trên
          print("Đang mở tính năng: $title");
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendItem(
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
                  color: color.withOpacity(0.1),
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

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    int index, {
    bool isActive = false,
  }) {
    return MaterialButton(
      minWidth: 40,
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.pink : Colors.grey),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.pink : Colors.grey,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

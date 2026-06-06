import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../auth/kyc/sceens/kyc_flow_screen.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/constants/api_config.dart';

// Nhúng các Widget con đã tách
import '../widgets/set_wallet_code_dialog.dart';
import '../widgets/wallet_card.dart';
import '../widgets/services_grid.dart';

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
  String? _walletCode;
  bool _isLoadingBalance = true;

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
      if (mounted) setState(() => _isLoadingBalance = false);
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
        if (mounted) {
          setState(() {
            _balance = responseData['data']?['available_balance']?.toString() ?? "0";
            _walletCode = responseData['data']?['wallet_code'];
            _isLoadingBalance = false;
          });

          // Nếu đã KYC mà chưa có mã ví thì hiện popup bắt tạo
          if (widget.isVerified && (_walletCode == null || _walletCode!.isEmpty)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSetWalletCodeDialog();
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingBalance = false);
      }
    } catch (e) {
      print("Lỗi lấy số dư ví: $e");
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  void _showSetWalletCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SetWalletCodeDialog(
        token: widget.token,
        onSuccess: (newCode) {
          setState(() => _walletCode = newCode);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tạo mã ví thành công!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
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
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderSection(activeLang),
                
                // Đã thay thế thẻ ví cũ bằng Widget WalletCard
                WalletCard(
                  activeLang: activeLang,
                  isLoading: _isLoadingBalance,
                  balance: _balance,
                ),
                
                _buildFinancialCenterBanner(activeLang),
                
                // Đã thay thế Grid cũ bằng Widget ServicesGrid
                ServicesGrid(
                  activeLang: activeLang,
                  isVerified: widget.isVerified,
                  token: widget.token,
                  walletCode: _walletCode,
                  onRequireKyc: _showKycDialog,
                  onRequireWalletCode: _showSetWalletCodeDialog,
                  onRefreshBalance: _fetchBalance,
                ),
                
                _buildEventBanner(activeLang),
                _buildRecommendations(activeLang),
                const SizedBox(height: 80),
              ],
            ),
          ),
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
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                      _buildBottomNavItem(Icons.home, "MoMo", 0, isActive: true),
                      _buildBottomNavItem(Icons.local_offer_outlined, activeLang == 'VIE' ? "Ưu đãi" : "Offers", 1),
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
                      _buildBottomNavItem(Icons.history, activeLang == 'VIE' ? "Lịch sử GD" : "History", 2),
                      _buildBottomNavItem(Icons.person_outline, activeLang == 'VIE' ? "Tôi" : "Me", 3),
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

  // =========================================================
  // CÁC HÀM UI CŨ GIỮ NGUYÊN BÊN TRONG FILE NÀY
  // =========================================================

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
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                children: [
                  const Icon(Icons.notifications_none, size: 28, color: Colors.black54),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chat_bubble_outline, size: 28, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickAction(Icons.account_balance_wallet, Colors.pink, activeLang == 'VIE' ? "Nạp/Rút" : "Deposit"),
              _buildQuickAction(Icons.qr_code, Colors.pink, activeLang == 'VIE' ? "Nhận tiền" : "Receive"),
              _buildQuickAction(Icons.qr_code_scanner, Colors.pink, activeLang == 'VIE' ? "QR Thanh toán" : "QR Pay"),
              _buildQuickAction(Icons.apps, Colors.pink, activeLang == 'VIE' ? "Ví tiện ích" : "Utilities"),
            ],
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
              Icon(Icons.shield_outlined, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                activeLang == 'VIE' ? "Trung Tâm Tài Chính của Thống" : "Thong's Financial Center",
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          Icon(Icons.chevron_right, color: Colors.blue.shade700, size: 20),
        ],
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
                    child: Opacity(opacity: 0.2, child: Container(color: Colors.black)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeLang == 'VIE' ? "Dùng Ví Trả Sau\nHoàn tiền 50%*" : "Use Postpaid Wallet\n50% Cashback*",
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeLang == 'VIE' ? "Tối đa 10k mọi giao dịch từ 1-30/6" : "Max 10k for all transactions June 1-30",
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        activeLang == 'VIE' ? "Khám phá ngay" : "Explore Now",
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
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
                _buildRecommendItem(Icons.campaign, activeLang == 'VIE' ? "Từ 220k" : "From 220k", activeLang == 'VIE' ? "Loa thông\nbáo chuyển ..." : "Payment\nSpeaker", Colors.pink),
                _buildRecommendItem(Icons.card_giftcard, activeLang == 'VIE' ? "Hoàn 50%" : "50% Back", activeLang == 'VIE' ? "Ví Trả Sau -\nHoàn 50%" : "Postpaid -\n50% Back", Colors.pinkAccent),
                _buildRecommendItem(Icons.sports_esports, null, activeLang == 'VIE' ? "Mã thẻ Game\nOnline" : "Game\nCards", Colors.blue),
                _buildRecommendItem(Icons.account_balance_wallet, null, activeLang == 'VIE' ? "Túi Thần Tài" : "Wealth Bag", Colors.orange),
                _buildRecommendItem(Icons.electric_bolt, null, activeLang == 'VIE' ? "Thanh toán\nđiện" : "Electricity\nBill", Colors.yellow.shade700),
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
          print("Đang mở tính năng: $title");
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecommendItem(IconData icon, String? badge, String title, Color color) {
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
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 28),
              ),
              if (badge != null)
                Positioned(
                  top: -8,
                  left: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      badge,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index, {bool isActive = false}) {
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
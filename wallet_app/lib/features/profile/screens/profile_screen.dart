import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/services/custom_http_client.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_state.dart';
import '../../auth/login/screens/login_phone_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/socket_service.dart';
import 'personal_profile_screen.dart';
import 'login_security_screen.dart';
import 'account_management_screen.dart';
import '../../chat/screens/help_center_screen.dart';
import '../../merchant/screens/merchant_screen.dart';
import '../../financial_center/screens/financial_center_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;

  const ProfileScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _client = CustomHttpClient();
  bool _isLoading = true;
  String _fullName = '';
  String _phone = '';
  String? _email;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getMyProfile),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        if (jsonResp['data'] != null) {
          setState(() {
            _fullName = jsonResp['data']['full_name'] ?? 'Người dùng';
            _phone = jsonResp['data']['phone'] ?? '';
            _email = jsonResp['data']['email'];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Lỗi lấy thông tin profile: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildTopActionCards(),
                _buildQuickSettings(),
                const SizedBox(height: 16),
                _buildSectionTitle('Tiện ích'),
                _buildUtilitiesGrid(),
                const SizedBox(height: 16),
                _buildScamTipsSection(),
                const SizedBox(height: 16),
                _buildCharitySection(),
                const SizedBox(height: 16),
                _buildMoreSettingsSection(),
                _buildFooterSection(),
                const SizedBox(height: 100), // Space for bottom nav bar
              ],
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8F5E9), // Light green
            Color(0xFFF1F8E9),
            Color(0xFFF5F5F5),
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.palette_rounded, size: 16, color: Colors.black87),
                    SizedBox(width: 4),
                    Text('Đổi ảnh nền', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.pink.shade100,
                child: Text(
                  _getInitials(_fullName),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryPink),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _fullName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _phone,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Đã sinh trắc học',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PersonalProfileScreen(
                      token: widget.token,
                      fullName: _fullName,
                      phone: _phone,
                      email: _email,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_rounded, size: 18, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Trang cá nhân', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard_rounded, size: 18, color: AppColors.primaryPink),
                  SizedBox(width: 4),
                  Text('Nhận Ngay 250K', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettings() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickSettingItem(
            Icons.security_rounded, 
            'Quản lý\ntài khoản', 
            badge: 'Mio',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountManagementScreen(
                    token: widget.token,
                  ),
                ),
              );
            },
          ),
          _buildQuickSettingItem(Icons.settings_applications_rounded, 'Cài đặt thanh\ntoán'),
          _buildQuickSettingItem(
            Icons.person_outline_rounded,
            'Đăng nhập và\nbảo mật',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginSecurityScreen(
                    token: widget.token,
                    phone: _phone,
                  ),
                ),
              );
            },
          ),
          _buildQuickSettingItem(Icons.notifications_none_rounded, 'Cài đặt thông\nbáo'),
        ],
      ),
    );
  }

  Widget _buildQuickSettingItem(IconData icon, String title, {String? badge, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 30, color: Colors.black54),
                if (badge != null)
                  Positioned(
                    bottom: -5,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildUtilitiesGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        children: [
          _buildUtilityItem(Icons.account_balance_rounded, 'Trung Tâm Tài Chính', Colors.blue, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FinancialCenterScreen(balance: "0", token: widget.token),
              ),
            );
          }),
          _buildUtilityItem(Icons.verified_rounded, 'Điểm Mio', AppColors.primaryPink),
          _buildUtilityItem(Icons.receipt_long_rounded, 'Thanh toán', Colors.teal),
          _buildUtilityItem(Icons.card_giftcard_rounded, 'Nhận Ngay 250K', AppColors.primaryPink, badge: 'Mio'),
          _buildUtilityItem(Icons.attach_money_rounded, 'Quản lý chi tiêu', Colors.teal.shade300),
          _buildUtilityItem(Icons.redeem_rounded, 'Quà của tôi', Colors.pinkAccent),
        ],
      ),
    );
  }

  Widget _buildUtilityItem(IconData icon, String title, Color color, {String? badge, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 32, color: color),
            if (badge != null)
              Positioned(
                top: -5,
                left: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
      ),
    );
  }

  Widget _buildScamTipsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.primaryPink, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Bí kíp nhận diện lừa đảo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Nhận biết kịch bản lừa đảo phổ biến để bảo vệ bản thân',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildScamCard('Nhận biết lừa đảo\nMua hàng Online', Colors.pink.shade50),
                _buildScamCard('Cẩn trọng với\nKịch bản mượn tiền', Colors.green.shade50),
                _buildScamCard('Nhận diện kịch bản\nGiả mạo công an', Colors.red.shade50),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildScamCard(String title, Color bgColor) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: const Center(child: Icon(Icons.security_rounded, size: 40, color: Colors.black26)),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: const Text(
              'Tìm hiểu ngay',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.primaryPink, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharitySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_border_rounded, color: AppColors.primaryPink),
                  const SizedBox(width: 8),
                  const Text('Máy tính cho em', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.computer_rounded, color: Colors.black26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tặng phòng máy cho học sinh nghèo miền núi: Lập Quỹ Tấm lòng vàng...',
                  style: TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoreSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
        children: [
          _buildMoreSettingsItem(
            icon: Icons.storefront_rounded,
            title: 'Đối tác kinh doanh',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MerchantScreen(token: widget.token),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 56),
          _buildMoreSettingsItem(
            icon: Icons.help_outline_rounded,
            title: 'Trung tâm trợ giúp',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HelpCenterScreen(
                    token: widget.token,
                    fullName: _fullName,
                    phone: _phone,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 56),
          _buildMoreSettingsItem(
            icon: Icons.notifications_none_rounded,
            title: 'Cài đặt thông báo',
            onTap: () {},
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 56),
          _buildMoreSettingsItem(
            icon: Icons.mail_outline_rounded,
            title: 'Chia sẻ góp ý',
            onTap: () {},
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 56),
          _buildMoreSettingsItem(
            icon: Icons.phone_android_rounded,
            title: 'Thông tin chung',
            onTap: () {},
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 56),
          _buildLanguageItem(),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _buildLogoutSwitchAccountRow(),
        ],
      ),
      ),
    );
  }

  Widget _buildMoreSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLanguageItem() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.translate_rounded, size: 20, color: Colors.black54),
      ),
      title: const Text(
        'Ngôn ngữ',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: ValueListenableBuilder<String>(
        valueListenable: AppState.currentLanguage,
        builder: (context, currentLang, child) {
          final isVietnamese = currentLang == 'VIE';
          return Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    AppState.currentLanguage.value = 'ENG';
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: !isVietnamese ? const Color(0xFF333333) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'EN',
                      style: TextStyle(
                        color: !isVietnamese ? Colors.white : Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    AppState.currentLanguage.value = 'VIE';
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isVietnamese ? const Color(0xFF333333) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'VI',
                      style: TextStyle(
                        color: isVietnamese ? Colors.white : Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoutSwitchAccountRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _showLogoutDialog,
              child: const Text(
                'Đăng xuất',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 16,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
                  (route) => false,
                );
              },
              child: const Text(
                'Đổi tài khoản',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bạn có muốn kết thúc phiên đăng nhập này không?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Đóng',
                        style: TextStyle(
                          color: AppColors.primaryPink,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _performLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Đồng ý',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performLogout() async {
    // Ngắt kết nối Socket
    SocketService().disconnect();

    // Xoá thông tin đăng nhập tự động
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('is_verified');
    } catch (e) {
      print('Lỗi xoá SharedPreferences: $e');
    }

    try {
      await _client.post(
        Uri.parse(ApiConfig.logout),
      );
    } catch (e) {
      print('Lỗi gọi API logout: $e');
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          'Phiên bản 5.9.0 build 50900',
          style: TextStyle(
            fontSize: 11,
            color: Colors.black38,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF0F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD1E1), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE3EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppColors.primaryPink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'An toàn tài sản & Bảo mật thông tin của bạn là ưu tiên hàng đầu của Mio.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tìm hiểu thêm >',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400, width: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'PCI DSS',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade800,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, color: Colors.white, size: 8),
                              SizedBox(width: 2),
                              Text(
                                'SECURE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


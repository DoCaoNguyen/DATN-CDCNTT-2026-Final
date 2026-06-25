import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/app_version_footer.dart';
import '../widgets/setting_menu_items.dart';
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
import 'help_center_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;

  const ProfileScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
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
    final data = await _profileService.fetchProfile();
    if (mounted) {
      setState(() {
        if (data != null) {
          _fullName = data['full_name'] ?? 'Người dùng';
          _phone = data['phone'] ?? '';
          _email = data['email'];
        }
        _isLoading = false;
      });
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeader(
                    fullName: _fullName,
                    phone: _phone,
                    initial: _getInitial(),
                  ),
                  _buildTopActionCards(),
                  _buildQuickSettings(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Tiện ích'),
                  _buildUtilitiesGrid(),
                  const SizedBox(height: 16),
                  _buildScamTipsSection(),
                  const SizedBox(height: 16),
                  SettingMenuItems(
                    onLogout: _showLogoutDialog,
                    token: widget.token,
                    fullName: _fullName,
                    phone: _phone,
                  ),
                  const AppVersionFooter(),
                  const SizedBox(height: 100), // Space for bottom nav bar
                ],
              ),
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
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_rounded, size: 18, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Trang cá nhân',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
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
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_giftcard_rounded,
                    size: 18,
                    color: AppColors.primaryPink,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Nhận Ngay 250K',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
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
                  builder: (context) =>
                      AccountManagementScreen(token: widget.token),
                ),
              );
            },
          ),
          _buildQuickSettingItem(
            Icons.settings_applications_rounded,
            'Cài đặt thanh\ntoán',
          ),
          _buildQuickSettingItem(
            Icons.person_outline_rounded,
            'Đăng nhập và\nbảo mật',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LoginSecurityScreen(token: widget.token, phone: _phone),
                ),
              );
            },
          ),
          _buildQuickSettingItem(
            Icons.notifications_none_rounded,
            'Cài đặt thông\nbáo',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettingItem(
    IconData icon,
    String title, {
    String? badge,
    VoidCallback? onTap,
  }) {
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
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
          _buildUtilityItem(
            Icons.account_balance_rounded,
            'Trung Tâm Tài Chính',
            Colors.blue,
          ),
          _buildUtilityItem(
            Icons.verified_rounded,
            'Điểm Mio',
            AppColors.primaryPink,
          ),
          _buildUtilityItem(
            Icons.receipt_long_rounded,
            'Thanh toán',
            Colors.teal,
          ),
          _buildUtilityItem(
            Icons.card_giftcard_rounded,
            'Nhận Ngay 250K',
            AppColors.primaryPink,
            badge: 'Mio',
          ),
          _buildUtilityItem(
            Icons.attach_money_rounded,
            'Quản lý chi tiêu',
            Colors.teal.shade300,
          ),
          _buildUtilityItem(
            Icons.redeem_rounded,
            'Quà của tôi',
            Colors.pinkAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityItem(
    IconData icon,
    String title,
    Color color, {
    String? badge,
  }) {
    return Column(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
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
                  const Icon(
                    Icons.shield_rounded,
                    color: AppColors.primaryPink,
                    size: 24,
                  ),
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
                _buildScamCard(
                  'Nhận biết lừa đảo\nMua hàng Online',
                  Colors.pink.shade50,
                ),
                _buildScamCard(
                  'Cẩn trọng với\nKịch bản mượn tiền',
                  Colors.green.shade50,
                ),
                _buildScamCard(
                  'Nhận diện kịch bản\nGiả mạo công an',
                  Colors.red.shade50,
                ),
              ],
            ),
          ),
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
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.security_rounded,
                  size: 40,
                  color: Colors.black26,
                ),
              ),
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
              style: TextStyle(
                color: AppColors.primaryPink,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitial() {
    if (_fullName.isEmpty) return 'M';
    final parts = _fullName.trim().split(' ');
    if (parts.isEmpty) return 'M';
    return parts.last[0].toUpperCase();
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
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
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
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
      debugPrint('Lỗi xoá SharedPreferences: $e');
    }

    await _profileService.logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
        (route) => false,
      );
    }
  }
}

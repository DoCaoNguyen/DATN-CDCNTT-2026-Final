import 'package:flutter/material.dart';
import '../../../../core/utils/app_state.dart';
import '../../auth/login/screens/login_phone_screen.dart';
import '../../chat/screens/help_center_screen.dart';

class SettingMenuItems extends StatelessWidget {
  final VoidCallback onLogout;
  final String token;
  final String fullName;
  final String phone;

  const SettingMenuItems({
    Key? key,
    required this.onLogout,
    required this.token,
    this.fullName = '',
    this.phone = '',
  }) : super(key: key);

  Widget buildMoreSettingsItem({
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
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget buildLanguageItem() {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.translate_rounded,
          size: 20,
          color: Colors.black54,
        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: !isVietnamese
                          ? const Color(0xFF333333)
                          : Colors.transparent,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isVietnamese
                          ? const Color(0xFF333333)
                          : Colors.transparent,
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

  Widget _buildLogoutSwitchAccountRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onLogout,
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
          Container(width: 1, height: 16, color: Colors.grey.shade300),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPhoneScreen(),
                  ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          buildMoreSettingsItem(
            icon: Icons.help_outline_rounded,
            title: 'Trung tâm trợ giúp',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HelpCenterScreen(
                    token: token,
                    fullName: fullName,
                    phone: phone,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 56),
          buildMoreSettingsItem(
            icon: Icons.notifications_none_rounded,
            title: 'Cài đặt thông báo',
            onTap: () {},
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 56),
          buildMoreSettingsItem(
            icon: Icons.mail_outline_rounded,
            title: 'Chia sẻ góp ý',
            onTap: () {},
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 56),
          buildMoreSettingsItem(
            icon: Icons.phone_android_rounded,
            title: 'Thông tin chung',
            onTap: () {},
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 56),
          buildLanguageItem(),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          _buildLogoutSwitchAccountRow(context),
        ],
      ),
    );
  }
}

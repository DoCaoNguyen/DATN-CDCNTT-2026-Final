import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'dart:math' as math;
import 'change_pin_screen.dart';
import 'malware_scan_screen.dart';
import 'package:safe_device/safe_device.dart';

class LoginSecurityScreen extends StatefulWidget {
  final String token;
  final String phone;

  const LoginSecurityScreen({
    Key? key,
    required this.token,
    required this.phone,
  }) : super(key: key);

  @override
  State<LoginSecurityScreen> createState() => _LoginSecurityScreenState();
}

class _LoginSecurityScreenState extends State<LoginSecurityScreen> {
  bool _biometricEnabled = true;
  bool _quickLoginEnabled = true;
  bool _showMoreSecurity = false;
  String _autoLockOption = 'Không';

  int _riskCount = 0;
  bool _isLoadingRisk = true;

  @override
  void initState() {
    super.initState();
    _checkRisks();
  }

  Future<void> _checkRisks() async {
    int count = 0;
    try {
      if (await SafeDevice.isJailBroken) count++;
      if (!(await SafeDevice.isRealDevice)) count++;
      if (await SafeDevice.isMockLocation) count++;
      if (await SafeDevice.isDevelopmentModeEnable) {
        count++;
      } else if (!(await SafeDevice.isSafeDevice)) {
        count++;
      }
    } catch (e) {
      debugPrint("Lỗi quét bảo mật nền: $e");
    }
    if (mounted) {
      setState(() {
        _riskCount = count;
        _isLoadingRisk = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đăng nhập và bảo mật',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityStatusCard(),
            const SizedBox(height: 8),
            _buildScamBanner(),
            const SizedBox(height: 16),
            _buildSectionTitle('Bảo mật'),
            _buildSecuritySection(),
            const SizedBox(height: 16),
            _buildSectionTitle('Tài khoản'),
            _buildAccountSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Trạng thái bảo mật Card ───
  Widget _buildSecurityStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Left: text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trạng thái bảo mật',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      const TextSpan(
                        text: 'Hoàn thành: ',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                        children: [
                          TextSpan(
                            text: '5/5',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Security gauge
              _buildSecurityGauge(),
            ],
          ),
          const SizedBox(height: 8),
          // Chevron down
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black38,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityGauge() {
    return SizedBox(
      width: 80,
      height: 55,
      child: CustomPaint(
        painter: _SecurityGaugePainter(),
        child: const Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(right: 0, bottom: 0),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Banner tra cứu lừa đảo ───
  Widget _buildScamBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3CD), Color(0xFFFFE082)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              const TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: 'Tra cứu lừa đảo ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: 'khi số lạ gọi,\nmua hàng shop lạ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Title ───
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
      ),
    );
  }

  // ─── Bảo mật section ───
  Widget _buildSecuritySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Sinh trắc học
          _buildSwitchItem(
            icon: Icons.fingerprint_rounded,
            iconColor: Colors.deepPurple,
            title: 'Sinh trắc học',
            value: _biometricEnabled,
            onChanged: (val) {
              setState(() => _biometricEnabled = val);
            },
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
          // Mã PIN 6 số
          _buildNavigationItem(
            icon: Icons.more_horiz_rounded,
            iconColor: Colors.black87,
            title: 'Mã PIN 6 số',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePinScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
          // Quét mã độc
          _buildNavigationItem(
            icon: Icons.qr_code_scanner_rounded,
            iconColor: Colors.teal,
            title: 'Quét mã độc',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingRisk)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  )
                else if (_riskCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_riskCount',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MalwareScanScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
          // Smart OTP
          _buildNavigationItem(
            icon: Icons.phonelink_lock_rounded,
            iconColor: Colors.blue,
            title: 'Smart OTP',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Đã kích hoạt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
          // Tra cứu lừa đảo
          _buildNavigationItem(
            icon: Icons.policy_rounded,
            iconColor: Colors.orange,
            title: 'Tra cứu lừa đảo',
            onTap: () {},
          ),
          // Xem thêm
          if (!_showMoreSecurity)
            InkWell(
              onTap: () {
                setState(() => _showMoreSecurity = true);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Xem thêm',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          if (_showMoreSecurity) ...[
            const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
            _buildNavigationItem(
              icon: Icons.devices_rounded,
              iconColor: Colors.indigo,
              title: 'Quản lý thiết bị',
              onTap: () {},
            ),
            const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
            _buildNavigationItem(
              icon: Icons.history_rounded,
              iconColor: Colors.grey,
              title: 'Lịch sử đăng nhập',
              onTap: () {},
            ),
            InkWell(
              onTap: () {
                setState(() => _showMoreSecurity = false);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Thu gọn',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Tài khoản section ───
  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Cập nhật Số điện thoại
          _buildNavigationItem(
            icon: Icons.phone_rounded,
            iconColor: Colors.green,
            title: 'Cập nhật Số điện thoại',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
          // Đăng nhập nhanh
          _buildSwitchItem(
            icon: Icons.flash_on_rounded,
            iconColor: Colors.amber.shade700,
            title: 'Đăng nhập nhanh',
            value: _quickLoginEnabled,
            onChanged: (val) {
              setState(() => _quickLoginEnabled = val);
            },
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
          // Tự động khoá ứng dụng
          _buildDropdownItem(
            icon: Icons.lock_outline_rounded,
            iconColor: Colors.blueGrey,
            title: 'Tự động khoá ứng dụng',
            value: _autoLockOption,
            options: ['Không', '30 giây', '1 phút', '5 phút'],
            onChanged: (val) {
              setState(() => _autoLockOption = val);
            },
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
          // Quản lý dữ liệu cá nhân
          _buildNavigationItem(
            icon: Icons.verified_user_rounded,
            iconColor: Colors.teal,
            title: 'Quản lý dữ liệu cá nhân',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
          // Hạn mức Ví
          _buildNavigationItem(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: Colors.purple,
            title: 'Hạn mức Ví',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ─── Reusable: Switch item ───
  Widget _buildSwitchItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: Colors.green,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
      ),
    );
  }

  // ─── Reusable: Navigation item ───
  Widget _buildNavigationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  // ─── Reusable: Dropdown item ───
  Widget _buildDropdownItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Colors.grey,
            ),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            items: options.map((opt) {
              return DropdownMenuItem(value: opt, child: Text(opt));
            }).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ),
    );
  }
}

// ─── Custom Painter: Security Gauge ───
class _SecurityGaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.45;

    // Background arc (grey)
    final bgPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Progress arc (green gradient simulation)
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Draw segments with different colors for gauge effect
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow.shade600,
      Colors.lightGreen,
      Colors.green,
    ];
    const segments = 5;
    const gapAngle = 0.03;
    final segmentAngle = (math.pi - (segments - 1) * gapAngle) / segments;

    for (int i = 0; i < segments; i++) {
      progressPaint.color = colors[i];
      final startAngle = math.pi + i * (segmentAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/services/custom_http_client.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/otp_input_widget.dart';

class PersonalProfileScreen extends StatefulWidget {
  final String token;
  final String fullName;
  final String phone;
  final String? walletCode;
  final String? email;

  const PersonalProfileScreen({
    Key? key,
    required this.token,
    required this.fullName,
    required this.phone,
    this.walletCode,
    this.email,
  }) : super(key: key);

  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen> {
  int _activePostTab = 0;
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.email;
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
    final displayAccountNo = widget.walletCode ?? widget.phone;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Trang cá nhân",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        actions: [
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
            // User Card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Upper Gradient info part
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFD4E2),
                          const Color(0xFFFFBCCF).withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.6,
                              ),
                              child: Text(
                                _getInitials(widget.fullName),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Name and phone/account
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    "Số tài khoản: $displayAccountNo",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.black38,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Privacy settings button
                  InkWell(
                    onTap: () {},
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Cài đặt quyền riêng tư",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Profile Completeness Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Hoàn thiện Hồ sơ",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _currentEmail != null && _currentEmail!.isNotEmpty
                            ? "2/2 hoàn thành"
                            : "1/2 hoàn thành",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCompletenessRow(
                    icon: Icons.assignment_rounded,
                    iconColor: Colors.red.shade300,
                    text: "Đã xác thực sinh trắc học",
                    isDone: true,
                  ),
                  const Divider(height: 24, color: Color(0xFFF5F5F7)),
                  InkWell(
                    onTap: () {
                      if (_currentEmail == null || _currentEmail!.isEmpty) {
                        _showEmailInputDialog();
                      }
                    },
                    child: _buildCompletenessRow(
                      icon: Icons.mail_outline_rounded,
                      iconColor: Colors.green.shade300,
                      text: "Xác thực gmail để bảo vệ tài khoản",
                      isDone:
                          _currentEmail != null && _currentEmail!.isNotEmpty,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Posts Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Bài viết",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildPostTab("Tất cả", 0),
                  _buildPostTab("Nhóm", 1),
                  _buildPostTab("Đánh giá", 2),
                  _buildPostTab("Hoạt động", 3),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Empty state view
            Center(
              child: Column(
                children: [
                  // Empty state box illustration
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inbox_rounded,
                      size: 44,
                      color: Colors.black26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Chưa có bài viết nào để hiển thị",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Người dùng này chưa có bài viết nào",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.pink),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      "Xem bảng tin",
                      style: TextStyle(
                        color: Colors.pink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletenessRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required bool isDone,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        if (isDone)
          const Icon(Icons.check_circle_rounded, color: Colors.pink, size: 20)
        else
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
      ],
    );
  }

  Widget _buildPostTab(String text, int index) {
    final isActive = _activePostTab == index;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: isActive,
        onSelected: (_) {
          setState(() {
            _activePostTab = index;
          });
        },
        selectedColor: const Color(0xFFFFE4EE),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isActive ? Colors.pink : Colors.black87,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isActive ? Colors.pink.shade200 : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showEmailInputDialog() {
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: AppColors.primaryPink,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Xác thực Email",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Vui lòng nhập địa chỉ email của bạn để nhận mã xác thực OTP bảo mật.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Địa chỉ Email",
                        hintText: "VD: example@gmail.com",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryPink,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text(
                              "Hủy bỏ",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPink,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final email = emailController.text.trim();
                                    if (email.isEmpty || !email.contains('@')) {
                                      SnackbarUtils.showError(
                                        context,
                                        "Email không hợp lệ",
                                      );
                                      return;
                                    }

                                    setDialogState(() => isLoading = true);
                                    try {
                                      final client = CustomHttpClient();
                                      final response = await client.post(
                                        Uri.parse(
                                          "${ApiConfig.baseUrl}/users/email/request-otp",
                                        ),
                                        body: jsonEncode({"email": email}),
                                      );
                                      setDialogState(() => isLoading = false);

                                      if (!mounted) return;

                                      if (response.statusCode == 200) {
                                        Navigator.pop(context);
                                        _showOtpDialog(email);
                                      } else {
                                        final error =
                                            jsonDecode(
                                              response.body,
                                            )['error'] ??
                                            "Lỗi không xác định";
                                        SnackbarUtils.showError(context, error);
                                      }
                                    } catch (e) {
                                      setDialogState(() => isLoading = false);
                                      SnackbarUtils.showError(
                                        context,
                                        "Lỗi kết nối: $e",
                                      );
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Nhận OTP",
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOtpDialog(String email) {
    String currentOtp = "";
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Xác thực Email",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Mã OTP gồm 6 chữ số đã được gửi tới:\n$email",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    OtpInputWidget(
                      length: 6,
                      onChanged: (val) {
                        currentOtp = val;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (currentOtp.length != 6) {
                                  SnackbarUtils.showError(
                                    context,
                                    "Vui lòng nhập đủ 6 số OTP",
                                  );
                                  return;
                                }

                                setSheetState(() => isLoading = true);
                                try {
                                  final client = CustomHttpClient();
                                  final response = await client.post(
                                    Uri.parse(
                                      "${ApiConfig.baseUrl}/users/email/verify-otp",
                                    ),
                                    body: jsonEncode({
                                      "email": email,
                                      "otp": currentOtp,
                                    }),
                                  );

                                  if (!mounted) return;

                                  if (response.statusCode == 200) {
                                    Navigator.pop(context);
                                    setState(() {
                                      _currentEmail = email;
                                    });
                                    SnackbarUtils.showSuccess(
                                      context,
                                      "Xác thực Email thành công!",
                                    );
                                  } else {
                                    setSheetState(() => isLoading = false);
                                    final error =
                                        jsonDecode(response.body)['error'] ??
                                        "Mã OTP không hợp lệ";
                                    SnackbarUtils.showError(context, error);
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  setSheetState(() => isLoading = false);
                                  SnackbarUtils.showError(
                                    context,
                                    "Lỗi kết nối mạng, vui lòng thử lại!",
                                  );
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Xác nhận",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

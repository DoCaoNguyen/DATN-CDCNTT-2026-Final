import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/login/sceens/login_phone_screen.dart';

class CustomHttpClient extends http.BaseClient {
  final http.Client _innerClient = http.Client();
  
  // Global NavigatorKey dùng để hiển thị Dialog hoặc điều hướng cưỡng bức (Force Navigate) từ xa không cần BuildContext
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Cờ hiệu ngăn chặn việc hiển thị lặp lại nhiều Dialog khi nhiều API cùng lỗi 401 cùng lúc
  static bool _isLoggingOut = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Tự động lấy Token từ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    // 2. Tự động đính kèm header Authorization
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Đính kèm thêm skip warning ngrok
    request.headers['ngrok-skip-browser-warning'] = 'true';
    request.headers['Content-Type'] = 'application/json';

    // 3. Thực thi request
    final response = await _innerClient.send(request);

    // 4. Lắng nghe và đánh chặn mã lỗi 401
    if (response.statusCode == 401) {
      _handleUnauthorized();
    }

    return response;
  }

  /// Xử lý cưỡng bức đăng xuất khi nhận mã lỗi 401
  static Future<void> _handleUnauthorized() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      // 1. Xóa sạch dữ liệu đăng nhập lưu cục bộ
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('is_verified');

      // 2. Lấy context an toàn thông qua navigatorKey toàn cục để hiển thị Dialog thông báo
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Cảnh báo bảo mật', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Tài khoản của bạn đã được đăng nhập trên một thiết bị khác. Phiên làm việc hiện tại đã hết hạn.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx); // Đóng Dialog
                  _navigateToLogin();       // Điều hướng về màn hình Login
                },
                child: const Text('Đăng nhập lại', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      } else {
        // Dự phòng nếu không lấy được context (ví dụ app đang tắt), vẫn thực hiện chuyển hướng
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint("Lỗi xử lý tự động đăng xuất: $e");
      _isLoggingOut = false;
    }
  }

  /// Thực hiện điều hướng về trang Login và xóa sạch Backstack màn hình trước đó
  static void _navigateToLogin() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPhoneScreen()),
      (route) => false,
    );
    _isLoggingOut = false; // Reset cờ sau khi đã điều hướng xong
  }
}

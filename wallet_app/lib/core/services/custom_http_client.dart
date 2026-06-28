import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_config.dart';
import '../../features/auth/login/screens/login_phone_screen.dart';
import 'socket_service.dart';

class CustomHttpClient extends http.BaseClient {
  final http.Client _innerClient = http.Client();
  static const _secureStorage = FlutterSecureStorage();
  static Completer<bool>? _refreshCompleter;

  // Global NavigatorKey dùng để hiển thị Dialog hoặc điều hướng cưỡng bức (Force Navigate) từ xa không cần BuildContext
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Cờ hiệu ngăn chặn việc hiển thị lặp lại nhiều Dialog khi nhiều API cùng lỗi 401 cùng lúc
  static bool _isLoggingOut = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Tự động lấy Token từ SecureStorage
    final String? token = await _secureStorage.read(key: 'access_token');

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
      if (request.url.path.contains('/auth/refresh-token') ||
          request.url.path.contains('/auth/login')) {
        _handleUnauthorized();
        return response;
      }

      // Cơ chế Lock chống Race Condition
      if (_refreshCompleter != null) {
        // Có request khác đang refresh token, chờ nó hoàn thành
        final success = await _refreshCompleter!.future;
        if (success) {
          final newToken = await _secureStorage.read(key: 'access_token');
          return await _retryRequest(request, newToken);
        } else {
          return response; // Nếu refresh thất bại, trả về response 401 gốc
        }
      }

      // Tạo Lock cho các request khác chờ
      _refreshCompleter = Completer<bool>();

      // Concurrency check: Kiểm tra xem token đã được cập nhật bởi một request nào đó trước khi ta tạo Lock chưa
      final currentTokenInStorage = await _secureStorage.read(key: 'access_token');
      if (currentTokenInStorage != null && currentTokenInStorage != token) {
        _refreshCompleter!.complete(true);
        _refreshCompleter = null;
        return await _retryRequest(request, currentTokenInStorage);
      }

      final refreshSuccess = await _tryRefreshToken();
      _refreshCompleter!.complete(refreshSuccess);
      _refreshCompleter = null;

      if (refreshSuccess) {
        final newToken = await _secureStorage.read(key: 'access_token');
        return await _retryRequest(request, newToken);
      } else {
        _handleUnauthorized();
      }
    }

    return response;
  }

  Future<http.StreamedResponse> _retryRequest(http.BaseRequest request, String? newToken) async {
    final newRequest = http.Request(request.method, request.url);
    newRequest.headers.addAll(request.headers);
    if (newToken != null && newToken.isNotEmpty) {
      newRequest.headers['Authorization'] = 'Bearer $newToken';
    }

    if (request is http.Request) {
      newRequest.bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      final multipartReq = http.MultipartRequest(request.method, request.url)
        ..headers.addAll(newRequest.headers)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
      return await _innerClient.send(multipartReq);
    }

    return await _innerClient.send(newRequest);
  }

  static Future<bool> _tryRefreshToken() async {
    try {
      final String? refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.refreshToken),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String newToken =
            responseData['access_token'] ??
            responseData['data']?['access_token'] ??
            '';
        String newRefreshToken =
            responseData['refresh_token'] ??
            responseData['data']?['refresh_token'] ??
            '';

        if (newToken.isNotEmpty) {
          await _secureStorage.write(key: 'access_token', value: newToken);
          if (newRefreshToken.isNotEmpty) {
            await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);
          }
          
          // Cập nhật SocketService với token mới
          SocketService().updateToken(newToken);
          
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Xử lý cưỡng bức đăng xuất khi nhận mã lỗi 401
  static Future<void> _handleUnauthorized() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      // 1. Xóa sạch dữ liệu đăng nhập lưu cục bộ
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('is_verified');

      // 2. Lấy context an toàn thông qua navigatorKey toàn cục để hiển thị Dialog thông báo
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Cảnh báo bảo mật',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                  _navigateToLogin(); // Điều hướng về màn hình Login
                },
                child: const Text(
                  'Đăng nhập lại',
                  style: TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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

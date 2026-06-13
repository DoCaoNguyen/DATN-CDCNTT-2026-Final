import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import 'auth_interceptor.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService({String? token, Function(Map<String, dynamic>)? onBalanceUpdate}) {
    if (token != null) {
      _instance._token = token;
    }
    if (onBalanceUpdate != null) {
      _instance._onBalanceUpdate = onBalanceUpdate;
    }
    return _instance;
  }

  SocketService._internal();

  IO.Socket? socket;
  String? _token;
  Function(Map<String, dynamic>)? _onBalanceUpdate;
  bool _isShowingKickoutDialog = false;

  void connect() {
    if (_token != null) {
      connectSocket(_token!);
    }
  }

  void connectSocket(String token) {
    _token = token;
    final String url = ApiConfig.socketUrl;
    debugPrint("Kết nối đến Socket Server: $url");

    disconnect();

    socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    socket?.onConnect((_) {
      debugPrint('Kết nối Socket.io thành công!');
    });

    socket?.onDisconnect((_) {
      debugPrint('Đã ngắt kết nối Socket.io!');
    });

    socket?.onConnectError((data) {
      debugPrint('Lỗi kết nối Socket.io: $data');
    });

    socket?.on('balance_update', (data) {
      debugPrint('Nhận sự kiện balance_update: $data');
      if (_onBalanceUpdate != null) {
        if (data is Map<String, dynamic>) {
          _onBalanceUpdate!(data);
        } else if (data is Map) {
          _onBalanceUpdate!(Map<String, dynamic>.from(data));
        }
      }
    });

    socket?.on('force_logout', (data) async {
      debugPrint('Nhận sự kiện force_logout (Active Kick-out): $data');
      await _handleForceLogout();
    });
  }

  Future<void> _handleForceLogout() async {
    if (_isShowingKickoutDialog) return;
    _isShowingKickoutDialog = true;

    // 1. Wipe credentials
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'is_verified');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('is_verified');

    // 2. Disconnect Socket
    disconnect();

    // 3. Navigate to login screen immediately
    _navigateToLogin();

    // 4. Wait for navigation transition to complete, then display the dialog on the login screen context
    await Future.delayed(const Duration(milliseconds: 400));

    final context = AuthInterceptor.navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Cảnh báo bảo mật', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Tài khoản của bạn vừa được đăng nhập trên một thiết bị khác. Thiết bị hiện tại đã bị đăng xuất.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _isShowingKickoutDialog = false;
              },
              child: const Text('Đã hiểu', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } else {
      _isShowingKickoutDialog = false;
    }
  }

  void _navigateToLogin() {
    AuthInterceptor.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/services/notification_service.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/login/screens/login_phone_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'core/services/custom_http_client.dart';
import 'core/services/socket_service.dart';
import 'core/services/network_service.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'features/auth/screens/wallet_link_confirm_screen.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // transparent status bar
      statusBarIconBrightness: Brightness.dark, // dark text for status bar
    ),
  );
  NetworkService().initialize();

  String? token;
  String? userId;
  bool isVerified = false;

  try {
    // Khởi tạo Firebase SDK với cấu hình tường minh để tránh lỗi đồng bộ của Gradle
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCvEj2SohLRzMSI3au6-E2RSrAy6QXxaeU",
        appId: "1:727424923764:android:eb4fbe4135efcf70d0b921",
        messagingSenderId: "727424923764",
        projectId: "wallet-app-loyalty",
        storageBucket: "wallet-app-loyalty.firebasestorage.app",
      ),
    );

    // Khởi tạo dịch vụ thông báo
    await NotificationService.instance.initialize();

    // Xin quyền hiển thị thông báo
    await NotificationService.instance.requestPermissions();

    // Đọc thông tin phiên đăng nhập trước đó
    const secureStorage = FlutterSecureStorage();
    token = await secureStorage.read(key: 'access_token');

    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
    isVerified = prefs.getBool('is_verified') ?? false;

    // Kết nối Socket.io nếu đã đăng nhập trước đó
    if (token != null && token.isNotEmpty) {
      SocketService().connectSocket(token);
    }
  } catch (e) {
    debugPrint("Lỗi khởi tạo hệ thống: $e");
  }

  runApp(MyApp(token: token, userId: userId, isVerified: isVerified));
}

class MyApp extends StatefulWidget {
  final String? token;
  final String? userId;
  final bool isVerified;

  const MyApp({super.key, this.token, this.userId, required this.isVerified});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    // Xử lý deep link khi app đang mở hoặc chạy nền
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Cố gắng bắt link nếu app mở lần đầu bằng link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        // Có độ trễ để đợi MaterialApp khởi tạo xong Navigator
        Future.delayed(const Duration(seconds: 1), () {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {
      debugPrint("Lỗi đọc initial deeplink: $e");
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'mio' && uri.host == 'link') {
      final merchant = uri.queryParameters['merchant'] ?? 'Đối tác';
      // Mở màn hình xác nhận liên kết
      CustomHttpClient.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => WalletLinkConfirmScreen(merchantName: merchant),
        ),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem người dùng đã đăng nhập chưa
    final bool isLoggedIn =
        widget.token != null &&
        widget.token!.isNotEmpty &&
        widget.userId != null &&
        widget.userId!.isNotEmpty;

    return MaterialApp(
      navigatorKey: CustomHttpClient.navigatorKey,
      title: 'Ví Điện Tử Mio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryPink),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      routes: {'/login': (context) => const LoginPhoneScreen()},
      home: isLoggedIn
          ? HomeScreen(userId: widget.userId!, isVerified: widget.isVerified, token: widget.token!)
          : const LoginPhoneScreen(),
    );
  }
}

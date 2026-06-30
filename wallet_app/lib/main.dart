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

class MyApp extends StatelessWidget {
  final String? token;
  final String? userId;
  final bool isVerified;

  const MyApp({super.key, this.token, this.userId, required this.isVerified});

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem người dùng đã đăng nhập chưa
    final bool isLoggedIn =
        token != null &&
        token!.isNotEmpty &&
        userId != null &&
        userId!.isNotEmpty;

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
          ? HomeScreen(userId: userId!, isVerified: isVerified, token: token!)
          : const LoginPhoneScreen(),
    );
  }
}

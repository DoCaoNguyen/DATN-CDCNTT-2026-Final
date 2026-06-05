import 'package:flutter/material.dart';
// Nhớ import các file chúng ta đã tạo
import 'core/constants/app_colors.dart';
import 'features/auth/screens/login_phone_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ví Điện Tử', // Tên của ứng dụng
      debugShowCheckedModeBanner: false, // Tắt dải băng "DEBUG" màu đỏ ở góc phải màn hình
      theme: ThemeData(
        // Lấy màu hồng chủ đạo làm màu gốc cho toàn bộ theme
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryPink),
        useMaterial3: true,
        // Cài đặt màu nền mặc định cho các màn hình
        scaffoldBackgroundColor: AppColors.background, 
      ),
      // Trỏ thẳng trang chủ của app về màn hình Đăng nhập
      home: const LoginPhoneScreen(),
    );
  }
}
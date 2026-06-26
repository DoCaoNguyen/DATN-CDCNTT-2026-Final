import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../home/screens/home_screen.dart';

class KycDialogs {
  static void showWarning(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28), SizedBox(width: 8), Text("Ảnh không đạt chuẩn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        content: Text(message ?? "Hệ thống không nhận diện được đầy đủ thẻ. Vui lòng đặt thẻ lọt thỏm vào khung hình và chụp lại ở nơi đủ sáng.", style: const TextStyle(height: 1.5, fontSize: 15)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Chụp lại", style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold, fontSize: 16)))],
      ),
    );
  }

  static void showError(BuildContext context, String message, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Xác thực thất bại', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink), onPressed: onRetry, child: const Text('Thử lại từ đầu', style: TextStyle(color: Colors.white)))),
          ],
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text('Xác thực thành công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Khuôn mặt và CCCD hoàn toàn trùng khớp. Hồ sơ đã được duyệt.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_verified', true);
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomeScreen(userId: userId, isVerified: true)), (route) => false);
                  }
                },
                child: const Text('Về trang chủ', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
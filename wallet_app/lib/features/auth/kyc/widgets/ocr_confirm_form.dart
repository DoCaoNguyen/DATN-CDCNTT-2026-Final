import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class OcrConfirmForm extends StatelessWidget {
  final TextEditingController idNumberController;
  final TextEditingController fullNameController;
  final TextEditingController dobController;
  final TextEditingController genderController;
  final TextEditingController addressController;
  final TextEditingController expiryDateController;
  final VoidCallback onSubmit;

  const OcrConfirmForm({
    Key? key,
    required this.idNumberController,
    required this.fullNameController,
    required this.dobController,
    required this.genderController,
    required this.addressController,
    required this.expiryDateController,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Xác nhận thông tin', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hệ thống đã trích xuất thông tin từ CCCD. Vui lòng kiểm tra kỹ trước khi tiếp tục.",
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: idNumberController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Số CCCD", border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fullNameController,
              readOnly: false,
              decoration: const InputDecoration(
                labelText: "Họ và Tên", border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: dobController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Ngày sinh (DD/MM/YYYY)", border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: genderController,
                    readOnly: false,
                    decoration: const InputDecoration(
                      labelText: "Giới tính", border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: expiryDateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Ngày hết hạn trên CCCD (DD/MM/YYYY)",
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              readOnly: false,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Quê quán / Nơi thường trú", border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text("Xác nhận thông tin", style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text("Bạn có chắc chắn các thông tin trên đã chính xác?\n\nLưu ý: Thông tin này sẽ được dùng để định danh tài khoản và không thể tự ý thay đổi sau này.", style: TextStyle(height: 1.5)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Kiểm tra lại", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onSubmit();
                          },
                          child: const Text("Đồng ý", style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Thông tin hợp lệ, Quét khuôn mặt', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
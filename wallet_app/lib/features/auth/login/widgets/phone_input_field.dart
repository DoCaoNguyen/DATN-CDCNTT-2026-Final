import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasError;
  final String activeLang; // Nhận ngôn ngữ để dịch chữ "Số điện thoại"

  const PhoneInputField({
    Key? key,
    required this.controller,
    this.hasError = false,
    this.activeLang = 'VIE', // Mặc định là VIE
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(
          color: hasError ? Colors.red : AppColors.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Cố định cờ Việt Nam
          const Text('🇻🇳', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          // Cố định mã vùng +84
          const Text(
            '+84',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 24,
            color: hasError
                ? Colors.red.withValues(alpha: 0.5)
                : AppColors.border,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: InputBorder.none,
                // Dịch chữ trong ô nhập theo ngôn ngữ
                hintText: activeLang == 'VIE'
                    ? 'Số điện thoại'
                    : 'Phone number',
                hintStyle: TextStyle(
                  color: hasError
                      ? Colors.red.withValues(alpha: 0.6)
                      : AppColors.textLight,
                  fontSize: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

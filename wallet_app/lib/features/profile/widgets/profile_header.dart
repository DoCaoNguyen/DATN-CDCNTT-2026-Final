import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String fullName;
  final String phone;
  final String initial;

  const ProfileHeader({
    Key? key,
    required this.fullName,
    required this.phone,
    required this.initial,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8F5E9), // Light green
            Color(0xFFF1F8E9),
            Color(0xFFF5F5F5),
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.palette_rounded,
                      size: 16,
                      color: Colors.black87,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Đổi ảnh nền',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.pink.shade100,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                phone,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Đã sinh trắc học',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CameraActionButtons extends StatelessWidget {
  final bool isPreviewing;
  final bool isCapturing;
  final VoidCallback onTake;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;

  const CameraActionButtons({
    Key? key,
    required this.isPreviewing,
    required this.isCapturing,
    required this.onTake,
    required this.onRetake,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: isPreviewing
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onRetake,
                      child: const Text(
                        'Chụp lại',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isCapturing ? null : onConfirm,
                      child: isCapturing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Tiếp tục',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: GestureDetector(
                onTap: onTake,
                child: isCapturing
                    ? const CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryPink,
                            width: 4,
                          ),
                        ),
                      ),
              ),
            ),
    );
  }
}

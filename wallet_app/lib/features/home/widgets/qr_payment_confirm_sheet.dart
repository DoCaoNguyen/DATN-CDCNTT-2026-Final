import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import 'qr_payment_success_dialog.dart';

class QrPaymentConfirmSheet extends StatefulWidget {
  final String qrToken;
  final int amount;
  final String description;
  final String merchantName;
  final VoidCallback onComplete;
  final Function(String) onError;

  const QrPaymentConfirmSheet({
    Key? key,
    required this.qrToken,
    required this.amount,
    required this.description,
    required this.merchantName,
    required this.onComplete,
    required this.onError,
  }) : super(key: key);

  @override
  State<QrPaymentConfirmSheet> createState() => _QrPaymentConfirmSheetState();
}

class _QrPaymentConfirmSheetState extends State<QrPaymentConfirmSheet> {
  final _client = CustomHttpClient();
  bool isPaying = false;

  String fmtAmt(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );

  Future<void> _processQrPayment(String qrToken, int amount) async {
    final idempotencyKey =
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.processPayment),
        headers: {
          'Content-Type': 'application/json',
          'idempotency-key': idempotencyKey,
        },
        body: jsonEncode({'qr_token': qrToken}),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close sheet

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => QrPaymentSuccessDialog(
            amount: amount,
            remaining: data['balance_remaining'],
            onDone: widget.onComplete,
          ),
        );
      } else {
        final errMsg =
            jsonDecode(response.body)['error'] ?? 'Thanh toán thất bại';
        widget.onError(errMsg);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      widget.onError('Lỗi kết nối. Vui lòng thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primaryPink,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Xác nhận thanh toán',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn sắp thanh toán số tiền sau:',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.pink.shade100),
            ),
            child: Column(
              children: [
                Text(
                  widget.merchantName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${fmtAmt(widget.amount)}đ',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPink,
                  ),
                ),
                if (widget.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isPaying
                      ? null
                      : () {
                          Navigator.pop(context);
                          Future.delayed(
                            const Duration(milliseconds: 300),
                            widget.onComplete,
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isPaying
                      ? null
                      : () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (pinSheetCtx) => PinConfirmBottomSheet(
                              onPinEntered: (pin) async {
                                try {
                                  final verifyResp = await _client.post(
                                    Uri.parse(ApiConfig.verifyPin),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({'pin': pin}),
                                  );
                                  if (verifyResp.statusCode == 200) {
                                    if (!mounted) return null;
                                    Navigator.pop(pinSheetCtx);
                                    setState(() => isPaying = true);
                                    await _processQrPayment(
                                      widget.qrToken,
                                      widget.amount,
                                    );
                                    return null;
                                  } else {
                                    final data = jsonDecode(verifyResp.body);
                                    return data['error'] ??
                                        "Mã PIN không chính xác";
                                  }
                                } catch (e) {
                                  return "Lỗi kết nối máy chủ";
                                }
                              },
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isPaying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Thanh toán ngay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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

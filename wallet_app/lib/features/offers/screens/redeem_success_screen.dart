import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RedeemSuccessScreen extends StatelessWidget {
  final String provider;
  final int faceValue;
  final String cardCode;
  final String serial;
  final int deductedPoints;
  final String transactionId;
  final bool isMoney;

  const RedeemSuccessScreen({
    Key? key,
    required this.provider,
    required this.faceValue,
    required this.cardCode,
    required this.serial,
    required this.deductedPoints,
    required this.transactionId,
    this.isMoney = false,
  }) : super(key: key);

  String _formatNumber(String value) {
    final number = int.tryParse(value);
    if (number == null) return "0";
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  String _formatTransactionId(String txId) {
    String digitsOnly = txId.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 12) {
      return digitsOnly.substring(0, 12);
    }
    return digitsOnly.padRight(12, '0');
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFE4EE), Color(0xFFFFE4EE)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            // Pop back until home or offers
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: Text(
          isMoney ? 'Thanh toán thành công' : 'Đổi thẻ thành công',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE4EE), Color(0xFFFFF0F5), Color(0xFFF5F5F9)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
              ),
              const SizedBox(height: 24),
              const Text(
                'Giao dịch thành công!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                '- ${_formatNumber(deductedPoints.toString())} ${isMoney ? 'đ' : 'Xu'}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Loại thẻ', style: TextStyle(color: Colors.black54, fontSize: 16)),
                        Text(
                          'Thẻ cào $provider',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Colors.black12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mệnh giá', style: TextStyle(color: Colors.black54, fontSize: 16)),
                        Text(
                          '${_formatNumber(faceValue.toString())}đ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Colors.black12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mã nạp', style: TextStyle(color: Colors.black54, fontSize: 16)),
                        Row(
                          children: [
                            Text(
                              cardCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _copyToClipboard(context, cardCode, 'mã nạp'),
                              child: const Icon(Icons.copy_rounded, color: Colors.blue, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Colors.black12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số Serial', style: TextStyle(color: Colors.black54, fontSize: 16)),
                        Row(
                          children: [
                            Text(
                              serial,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _copyToClipboard(context, serial, 'số serial'),
                              child: const Icon(Icons.copy_rounded, color: Colors.grey, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Colors.black12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mã giao dịch', style: TextStyle(color: Colors.black54, fontSize: 14)),
                        Text(
                          _formatTransactionId(transactionId),
                          style: const TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Về trang chủ',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

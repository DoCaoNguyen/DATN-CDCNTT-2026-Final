import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionResultScreen extends StatelessWidget {
  final int amount;
  final bool isWithdraw;
  final String methodName;
  final String? transactionId;

  const TransactionResultScreen({
    super.key,
    required this.amount,
    this.isWithdraw = false,
    this.methodName = 'Ví Mio',
    this.transactionId,
  });

  String _formatAmount(int amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.') +
        'đ';
  }

  String _generateTransactionId() {
    final rand = Random();
    String id = "";
    for (int i = 0; i < 12; i++) {
      id += rand.nextInt(10).toString();
    }
    return id;
  }

  String _getCurrentTime() {
    return DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF), // Màu nền tổng thể sáng
      appBar: AppBar(
        backgroundColor: const Color(
          0xFFFDF9F1,
        ), // Gradient giả lập từ trên xuống
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Kết quả giao dịch",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
        automaticallyImplyLeading: false, // Bỏ nút back
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Thẻ kết quả giao dịch
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isWithdraw ? "Rút tiền thành công" : "Giao dịch thành công",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isWithdraw
                        ? "-${_formatAmount(amount)}"
                        : _formatAmount(amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(height: 1, color: Colors.grey.shade200),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (isWithdraw) ...[
                          _buildInfoRow("Rút tiền về", methodName),
                          const SizedBox(height: 12),
                          _buildInfoRow("Phí giao dịch", "Miễn phí"),
                        ] else ...[
                          _buildInfoRow("Dịch vụ/ Cửa hàng", "Túi Thần Tài"),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            "Giao dịch",
                            transactionId ?? _generateTransactionId(),
                            valueColor: Colors.pink,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            "Thời gian thanh toán",
                            _getCurrentTime(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.pink),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            ),
                            child: const Text(
                              "Màn hình chính",
                              style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              if (isWithdraw) {
                                Navigator.of(context)
                                  ..pop()
                                  ..pop()
                                  ..pop();
                              } else {
                                Navigator.of(context)
                                  ..pop()
                                  ..pop();
                              }
                            },
                            child: const Text(
                              "Túi Thần Tài",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Các widget quảng cáo/ quản lý chi tiêu giả lập
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.cyan.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.pie_chart, color: Colors.teal, size: 16),
                            SizedBox(width: 8),
                            Text(
                              "Quản lý chi tiêu",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Báo cáo chi tiêu được tạo tự động",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Mở Quản lý chi tiêu để xem chi tiết",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.pink),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {},
                          child: const Text(
                            "Xem báo cáo ngay",
                            style: TextStyle(color: Colors.pink, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.data_usage, size: 64, color: Colors.teal),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String title,
    String value, {
    Color valueColor = Colors.black87,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

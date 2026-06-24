import 'package:flutter/material.dart';
import 'bank_transfer_input_screen.dart';

class BankTransferSuccessScreen extends StatelessWidget {
  final String token;
  final String bankName;
  final String bankCode;
  final String accountNumber;
  final String amount;
  final String note;
  final String referenceCode;
  final String paymentTime;
  final String? cardHolderName;

  const BankTransferSuccessScreen({
    Key? key,
    required this.token,
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
    required this.amount,
    required this.note,
    required this.referenceCode,
    required this.paymentTime,
    this.cardHolderName,
  }) : super(key: key);

  String _formatAmount(String value) {
    final number = int.tryParse(value);
    if (number == null) return "0đ";
    return "${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4EE),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Kết quả giao dịch',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE4EE), Color(0xFFFFF0F5), Color(0xFFF5F5F9)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Success Icon Circle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Giao dịch thành công',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatAmount(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Detailed receipt
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Success row
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.blue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Thành công.',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          _buildRow('Giao dịch', referenceCode),
                          _buildRow('Thời gian thanh toán', paymentTime),

                          const Divider(height: 24),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.pink,
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  'mio',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Biên lai chuyển tiền',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          _buildRow(
                            'Người nhận',
                            cardHolderName ?? 'PHAN VAN THONG',
                          ),
                          _buildRow('Số thẻ/TK', accountNumber),
                          _buildRow('Ngân hàng', bankName),
                          _buildRow('Tin nhắn', note),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save template block
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tạo mẫu chuyển tiền để chuyển nhanh hơn vào lần sau',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.pink,
                              backgroundColor: Colors.pink.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                            ),
                            child: const Text(
                              'Tạo mẫu',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.pink,
                            side: const BorderSide(color: Colors.pink),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Chia tiền',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Redirect back to Screen 1 pre-filled
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BankTransferInputScreen(
                                  token: token,
                                  bankName: bankName,
                                  bankCode: bankCode,
                                  prefilledAccountNumber: accountNumber,
                                  cardHolderName: cardHolderName,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Chuyển thêm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

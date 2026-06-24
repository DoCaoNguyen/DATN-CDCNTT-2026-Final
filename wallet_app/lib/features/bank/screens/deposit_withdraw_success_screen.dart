import 'package:flutter/material.dart';

class DepositWithdrawSuccessScreen extends StatelessWidget {
  final String token;
  final String amount;
  final bool isDeposit;
  final String referenceCode;
  final String paymentTime;

  const DepositWithdrawSuccessScreen({
    Key? key,
    required this.token,
    required this.amount,
    required this.isDeposit,
    required this.referenceCode,
    required this.paymentTime,
  }) : super(key: key);

  String _formatAmount(String value) {
    final number = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (number == null) return "0đ";
    return "${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _formatAmount(amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4EE),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Kết quả giao dịch',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE4EE), Color(0xFFF5F5F9)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Success Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Green checkmark
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF4CAF50),
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Giao dịch thành công',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedAmount,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details
                    _buildDetailRow(
                      'Dịch vụ/ Cửa hàng',
                      isDeposit ? 'Nạp tiền vào ví' : 'Rút tiền về ngân hàng',
                    ),
                    _buildDetailRowWithChevron('Giao dịch', referenceCode),
                    _buildDetailRow('Thời gian thanh toán', paymentTime),

                    const SizedBox(height: 24),

                    // Buttons
                    _buildActionButtons(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quản lý chi tiêu
              _buildSpendingManagementCard(),

              if (!isDeposit) ...[
                const SizedBox(height: 16),
                _buildSecurityAlertCard(),
                const SizedBox(height: 20),
                const Text(
                  'Có thể bạn quan tâm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPromotionBanner(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithChevron(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFE91E63),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFE91E63),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final homeButton = Expanded(
      child: SizedBox(
        height: 44,
        child: OutlinedButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE91E63), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Màn hình chính',
            style: TextStyle(
              color: Color(0xFFE91E63),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );

    final newTransactionButton = Expanded(
      child: SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // returns to DepositWithdrawScreen
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Tạo giao dịch mới',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );

    // Left outlined, Right filled - changes placement based on screen type (withdrawal vs deposit)
    if (isDeposit) {
      // Deposit: Left = newTransaction, Right = homeButton
      return Row(
        children: [newTransactionButton, const SizedBox(width: 12), homeButton],
      );
    } else {
      // Withdrawal: Left = homeButton, Right = newTransaction
      return Row(
        children: [homeButton, const SizedBox(width: 12), newTransactionButton],
      );
    }
  }

  Widget _buildSpendingManagementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Colors.teal,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quản lý chi tiêu',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Báo cáo chi tiêu được tạo tự động',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mở Quản lý chi tiêu để xem chi tiết',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE91E63), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            child: const Text(
              'Xem báo cáo ngay',
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityAlertCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.crisis_alert_rounded, color: Colors.pink, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bạn ngủ, A.I thức canh tiền',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A.I Tự động giữ lại giao dịch bất thường, để bạn kiểm soát.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Xem ngay',
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 160,
        width: double.infinity,
        color: Colors.red,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Container(color: Colors.black),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '01/06 - 30/06',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Dùng Ví Trả Sau\nHoàn tiền 50%*",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "*Tối đa 10k/giao dịch tại cửa\nhàng có loa thanh toán Mio",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Trả sau ngay',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class DepositWithdrawInputLayout extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onTabChanged;
  final Map<String, dynamic>? selectedBank;
  final String mioBalance;
  final TextEditingController amountController;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<int> onQuickAmountSelected;
  final VoidCallback onConfirmPressed;
  final int parsedAmount;

  const DepositWithdrawInputLayout({
    Key? key,
    required this.activeTab,
    required this.onTabChanged,
    required this.selectedBank,
    required this.mioBalance,
    required this.amountController,
    required this.onAmountChanged,
    required this.onQuickAmountSelected,
    required this.onConfirmPressed,
    required this.parsedAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDeposit = activeTab == 0;
    final bankName = selectedBank != null
        ? selectedBank!['bank_name']
        : "Không xác định";
    final bankDetails = selectedBank != null
        ? "${selectedBank!['bank_name']} - ${selectedBank!['card_number']}"
        : "Chưa liên kết ngân hàng";

    return Column(
      children: [
        // TabBar
        Container(
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onTabChanged(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: activeTab == 0
                              ? Colors.pink
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.input_rounded,
                          color: activeTab == 0 ? Colors.pink : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Nạp tiền',
                          style: TextStyle(
                            color: activeTab == 0 ? Colors.pink : Colors.grey,
                            fontWeight: activeTab == 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => onTabChanged(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: activeTab == 1
                              ? Colors.pink
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.output_rounded,
                          color: activeTab == 1 ? Colors.pink : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rút tiền',
                          style: TextStyle(
                            color: activeTab == 1 ? Colors.pink : Colors.grey,
                            fontWeight: activeTab == 1
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source / Target bank card
                Text(
                  isDeposit ? 'Nạp tiền vào' : 'Rút tiền từ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.pink.shade100,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.pink,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                'mio',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ví Mio',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  mioBalance,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isDeposit) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.monetization_on_rounded,
                                color: Colors.orange,
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Túi Thần Tài',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Đến 4%/năm',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Amount input field
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDeposit ? 'Số tiền cần nạp' : 'Số tiền cần rút',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      TextField(
                        controller: amountController,
                        onChanged: onAmountChanged,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0đ',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick selector buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onQuickAmountSelected(50000),
                        child: const Text('50.000'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onQuickAmountSelected(100000),
                        child: const Text('100.000'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onQuickAmountSelected(200000),
                        child: const Text('200.000'),
                      ),
                    ),
                  ],
                ),

                if (!isDeposit) ...[
                  const SizedBox(height: 20),
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
                        const Icon(
                          Icons.account_balance_rounded,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chuyển tiền ngân hàng',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Miễn phí chuyển tiền với Túi và Quỹ',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Thử ngay',
                            style: TextStyle(
                              color: Colors.pink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Security warning
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.pink,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'An toàn tài sản & Bảo mật thông tin của bạn là ưu tiên hàng đầu của Mio.',
                              style: TextStyle(
                                color: Colors.pink.shade900,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tìm hiểu thêm >',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Button
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (parsedAmount > 0) {
                    onConfirmPressed();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vui lòng nhập số tiền")),
                    );
                  }
                },
                child: Text(
                  isDeposit ? 'Nạp tiền' : 'Rút tiền',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

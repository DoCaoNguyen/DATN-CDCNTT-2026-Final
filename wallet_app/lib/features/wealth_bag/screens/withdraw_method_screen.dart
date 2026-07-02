import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'withdraw_confirm_screen.dart';

class WithdrawMethodScreen extends StatefulWidget {
  final int amount;

  const WithdrawMethodScreen({super.key, required this.amount});

  @override
  State<WithdrawMethodScreen> createState() => _WithdrawMethodScreenState();
}

class _WithdrawMethodScreenState extends State<WithdrawMethodScreen> {
  String _selectedMethod = 'wallet';

  String _formatAmount(int amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount).replaceAll(',', '.') + 'đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF), // Light background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Rút tiền từ Túi Thần Tài",
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.download_rounded, color: Colors.deepOrange, size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Số tiền cần rút:", style: TextStyle(color: Colors.black54, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(widget.amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Chọn cách rút tiền",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Withdraw to wallet option
                  const Text("Rút về Ví Mio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => _selectedMethod = 'wallet'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: _selectedMethod == 'wallet' ? Colors.deepOrange : Colors.grey.shade300,
                          width: _selectedMethod == 'wallet' ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.pink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'mio',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Ví Mio", style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text("Miễn phí rút từ Túi về Ví", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: 'wallet',
                            groupValue: _selectedMethod,
                            activeColor: Colors.deepOrange,
                            onChanged: (val) => setState(() => _selectedMethod = val!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Withdraw to bank option (mock)
                  const Text("Rút về ngân hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text(
                    "Phí 0,5% - 1% giá trị giao dịch, phí tối thiểu 5.000đ.",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {}, // Navigate to add bank or open bottom sheet in real app
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.deepOrange),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.add, color: Colors.deepOrange, size: 16),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text("Thêm ngân hàng nhận tiền", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      "Xem biểu phí rút về ngân hàng >",
                      style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WithdrawConfirmScreen(
                        amount: widget.amount,
                        method: _selectedMethod,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Tiếp tục",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

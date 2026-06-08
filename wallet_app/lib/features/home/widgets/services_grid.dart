import 'package:flutter/material.dart';
import '../../transfer/screens/transfer_main_screen.dart';

class ServicesGrid extends StatelessWidget {
  final String activeLang;
  final bool isVerified;
  final String token;
  final bool isPinSet;
  final VoidCallback onRequireKyc;
  final VoidCallback onRequireWalletCode;
  final VoidCallback onRefreshBalance;

  const ServicesGrid({
    Key? key,
    required this.activeLang,
    required this.isVerified,
    required this.token,
    required this.isPinSet,
    required this.onRequireKyc,
    required this.onRequireWalletCode,
    required this.onRefreshBalance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {'icon': Icons.swap_horiz, 'name': activeLang == 'VIE' ? 'Chuyển tiền' : 'Transfer', 'color': Colors.red},
      {'icon': Icons.account_balance, 'name': activeLang == 'VIE' ? 'Chuyển tiền\nNgân hàng' : 'Bank\nTransfer', 'color': Colors.blue},
      {'icon': Icons.receipt_long, 'name': activeLang == 'VIE' ? 'Thanh toán\nhóa đơn' : 'Pay\nBills', 'color': Colors.teal},
      {'icon': Icons.phone_android, 'name': activeLang == 'VIE' ? 'Nạp tiền\nđiện thoại' : 'Top-up', 'color': Colors.blueAccent},
      // ... Thêm các dịch vụ khác của bạn vào đây
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, childAspectRatio: 0.8, crossAxisSpacing: 8, mainAxisSpacing: 16,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return GestureDetector(
            onTap: () async {
              if (!isVerified) {
                onRequireKyc();
              } else {
                if (service['name'] == 'Chuyển tiền' || service['name'] == 'Transfer') {
                  if (!isPinSet) {
                    onRequireWalletCode();
                    return;
                  }
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => TransferMainScreen(token: token)));
                  onRefreshBalance();
                }
              }
            },
            child: Column(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: service['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(service['icon'], color: service['color'], size: 28),
                ),
                const SizedBox(height: 8),
                Text(service['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87)),
              ],
            ),
          );
        },
      ),
    );
  }
}
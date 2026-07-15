import '../../../core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import '../../transfer/screens/transfer_main_screen.dart';
import '../../bank/screens/bank_transfer_list_screen.dart';

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
      {
        'icon': Icons.send_rounded,
        'name': activeLang == 'VIE' ? 'Chuyển tiền' : 'Transfer',
        'color': Colors.pink,
      },
      {
        'icon': Icons.account_balance_rounded,
        'name': activeLang == 'VIE' ? 'Ngân hàng' : 'Bank',
        'color': Colors.blueAccent,
      },
      {
        'icon': Icons.pie_chart_rounded,
        'name': activeLang == 'VIE' ? 'Chia tiền' : 'Split Bill',
        'color': Colors.orange,
      },
      {
        'icon': Icons.phone_android_rounded,
        'name': activeLang == 'VIE' ? 'Nạp ĐT' : 'Top up',
        'color': Colors.green,
      },
      {
        'icon': Icons.card_giftcard_rounded,
        'name': activeLang == 'VIE' ? 'Lì xì' : 'Red Packet',
        'color': Colors.red,
      },
      {
        'icon': Icons.savings_rounded,
        'name': activeLang == 'VIE' ? 'Tiết Kiệm Online' : 'Online Savings',
        'color': Colors.pinkAccent,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 16,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return GestureDetector(
            onTap: () async {
              if (!isVerified) {
                onRequireKyc();
              } else {
                if (service['name'] == 'Chuyển tiền' ||
                    service['name'] == 'Transfer') {
                  if (!isPinSet) {
                    onRequireWalletCode();
                    return;
                  }
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransferMainScreen(token: token),
                    ),
                  );
                  onRefreshBalance();
                } else if (service['name'].toString().contains('Ngân hàng') ||
                    service['name'].toString().contains('Bank')) {
                  if (!isPinSet) {
                    onRequireWalletCode();
                    return;
                  }
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BankTransferListScreen(token: token),
                    ),
                  );
                  onRefreshBalance();
                } else if (service['name'].toString().contains('Nạp ĐT') ||
                    service['name'].toString().contains('Top up')) {
                  SnackbarUtils.showWarning(context, 'Tính năng đang phát triển', margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16));
                } else if (service['name'].toString().contains('Chia tiền') ||
                    service['name'].toString().contains('Split Bill')) {
                  SnackbarUtils.showWarning(context, 'Tính năng đang phát triển', margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16));
                } else if (service['name'].toString().contains('Lì xì') ||
                    service['name'].toString().contains('Red Packet')) {
                  SnackbarUtils.showWarning(context, 'Tính năng đang phát triển', margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16));
                } else if (service['name'].toString().contains('Tiết Kiệm') ||
                    service['name'].toString().contains('Savings')) {
                  SnackbarUtils.showWarning(context, 'Tính năng đang phát triển', margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16));
                }
              }
            },
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: service['color'].withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    service['icon'],
                    color: service['color'],
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  service['name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

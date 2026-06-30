import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'limit_info_screen.dart';

import 'dart:convert';
import '../../../../core/services/custom_http_client.dart';
import '../../../../core/constants/api_config.dart';
import 'package:intl/intl.dart';
import '../../bank/screens/bank_link_screen.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../settings/screens/linked_services_screen.dart';

class AccountManagementScreen extends StatefulWidget {
  final String token;

  const AccountManagementScreen({Key? key, required this.token})
    : super(key: key);

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final _client = CustomHttpClient();
  bool _isLoading = true;
  String _balance = '0';

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getWalletBalance));
      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        setState(() {
          _balance = jsonResp['data']['available_balance'] ?? '0';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Quản lý tài khoản',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildBalanceCard(context),
            const SizedBox(height: 16),
            _buildUtilitiesSection(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Số dư khả dụng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          CurrencyFormatter.format(_balance),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.visibility_rounded,
                    size: 20,
                    color: Colors.black54,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Ví điện tử', style: TextStyle(fontSize: 15)),
                ),
                _isLoading
                    ? const SizedBox()
                    : Text(
                        CurrencyFormatter.format(_balance),
                        style: const TextStyle(fontSize: 15),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BankLinkScreen(token: widget.token),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Thêm mới tài khoản/thẻ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilitiesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Tiện ích thêm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
              _buildUtilityItem(
                icon: Icons.sort_rounded,
                iconColor: Colors.orange,
                title: 'Thứ tự thanh toán',
                subtitle: 'Sắp xếp và cấu hình nguồn tiền',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 50),
              _buildUtilityItem(
                icon: Icons.video_library_rounded,
                iconColor: AppColors.primaryPink,
                title: 'Thông tin hạn mức',
                subtitle: 'Quản lý hạn mức giao dịch và nạp rút',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LimitInfoScreen(token: widget.token),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 50),
              _buildUtilityItem(
                icon: Icons.receipt_long_rounded,
                iconColor: Colors.pinkAccent,
                title: 'Dịch vụ liên kết & Hóa đơn định kỳ',
                subtitle: 'Quản lý dịch vụ liên kết và hóa đơn định kỳ',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LinkedServicesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      ],
    );
  }

  Widget _buildUtilityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 28),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}

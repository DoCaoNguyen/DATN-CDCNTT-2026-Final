import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../financial_center_api/financial_center_api.dart';
import 'package:intl/intl.dart';
import '../../bank/screens/bank_link_screen.dart';
import 'payment_order_screen.dart';
import '../widgets/financial_center_appbar_actions.dart';

class FinancialCenterScreen extends StatefulWidget {
  final String balance;
  final String token;

  const FinancialCenterScreen({Key? key, required this.balance, required this.token}) : super(key: key);

  @override
  State<FinancialCenterScreen> createState() => _FinancialCenterScreenState();
}

class _FinancialCenterScreenState extends State<FinancialCenterScreen> {
  bool _isBalanceVisible = true;
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<dynamic> _linkedBanks = [];

  @override
  void initState() {
    super.initState();
    _fetchLinkedBanks();
  }

  Future<void> _fetchLinkedBanks() async {
    try {
      final sortedBanks = await FinancialCenterApi.getSortedLinkedBanks(widget.token);
      
      if (mounted) {
        setState(() {
          // filter out the ones that are not enabled or keep them depending on logic
          // The previous logic didn't filter by `isEnabled` explicitly, but it was just banks
          // In FinancialCenterApi.getSortedLinkedBanks, the original data is in 'original_data'
          // We can map it back to the original bank object but keep the order
          _linkedBanks = sortedBanks.map((b) => b['original_data']).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(String amountStr) {
    try {
      final amount = double.parse(amountStr.replaceAll(RegExp(r'[^0-9]'), ''));
      return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
    } catch (e) {
      return '$amountStr đ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayBalance = _isBalanceVisible ? _formatCurrency(widget.balance) : "******";

    return Scaffold(
      backgroundColor: _selectedIndex == 0 ? Colors.white : Colors.grey.shade50,
      appBar: _selectedIndex == 0 ? _buildOverviewAppBar() : _buildAccountAppBar(),
      body: _selectedIndex == 0 ? _buildOverviewBody(displayBalance) : _buildAccountManagementBody(displayBalance),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primaryPink,
          unselectedItemColor: Colors.grey.shade600,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart),
              label: 'Tổng quan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'QL Tài Khoản',
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildOverviewAppBar() {
    return AppBar(
      backgroundColor: Colors.blue,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Trung Tâm Tài Chính',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.white),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAccountAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFCE4EC), // light pinkish
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Quản lý tài khoản',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: false,
      actions: const [
        FinancialCenterAppBarActions(),
      ],
    );
  }

  Widget _buildOverviewBody(String displayBalance) {
    return Column(
      children: [
        // Header section with gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.shade100],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Toggle Button (Tài sản / Phải trả)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 60),
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Tài sản',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'Phải trả',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tổng tài sản',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayBalance,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBalanceVisible = !_isBalanceVisible;
                      });
                    },
                    child: Icon(
                      _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // List content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
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
                      // Header card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'So với ${DateFormat('dd/MM/yyyy').format(DateTime.now())} --',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Thu gọn',
                                  style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_up_rounded, color: Colors.blue.shade700, size: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // List items
                      _buildOverviewAssetItem(
                        iconData: Icons.account_balance_wallet,
                        iconColor: Colors.pink,
                        title: 'Ví MoMo',
                        value: displayBalance,
                        subtitle: '--',
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(color: AppColors.primaryPink, strokeWidth: 2)),
                        ),
                      ..._linkedBanks.map((bank) {
                        return Column(
                          children: [
                            _buildDivider(),
                            _buildOverviewAssetItem(
                              iconData: Icons.account_balance,
                              iconColor: Colors.green,
                              title: bank['bank_name'] ?? 'Ngân hàng',
                              value: 'Bấm xem số dư',
                              valueColor: AppColors.primaryPink,
                              subtitle: '--',
                            ),
                          ],
                        );
                      }).toList(),
                      _buildDivider(),
                      _buildOverviewAssetItem(
                        iconData: Icons.pie_chart,
                        iconColor: Colors.red,
                        title: 'Tài sản còn lại',
                        value: '--',
                        subtitle: '--',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountManagementBody(String displayBalance) {
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account balances card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số dư khả dụng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
                        Row(
                          children: [
                            Text(displayBalance, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() { _isBalanceVisible = !_isBalanceVisible; });
                              },
                              child: Icon(_isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.black87, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // account items inside the card
                  _buildAccountItem(iconData: Icons.account_balance_wallet, iconColor: Colors.pink, title: 'Ví MoMo', value: displayBalance, valueColor: Colors.black87),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryPink, strokeWidth: 2)),
                    ),
                  ..._linkedBanks.map((bank) {
                    return _buildAccountItem(
                      iconData: Icons.account_balance,
                      iconColor: Colors.green,
                      title: bank['bank_name'] ?? 'Ngân hàng',
                      value: 'Xem số dư >',
                      valueColor: Colors.black87,
                      isBoldValue: true,
                      highlightText: 'Bật xem số dư để tiện quản lý & giao dịch',
                      highlightColor: Colors.blue.shade50,
                      highlightTextColor: Colors.blue.shade700,
                    );
                  }).toList(),
                  // Add new button
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BankLinkScreen(token: widget.token),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        label: const Text('Thêm mới tài khoản/thẻ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text('Tiện ích thêm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            
            // Utilities card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildUtilityRow(
                    iconData: Icons.money_outlined,
                    iconColor: Colors.orange,
                    title: 'Thứ tự thanh toán',
                    subtitle: 'Sắp xếp và cấu hình nguồn tiền',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PaymentOrderScreen(token: widget.token)),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildUtilityRow(iconData: Icons.credit_score, iconColor: Colors.pink, title: 'Thông tin hạn mức', subtitle: 'Quản lý hạn mức giao dịch và nạp rút'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewAssetItem({
    required IconData iconData,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            alignment: Alignment.center,
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade600, size: 16),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem({
    required IconData iconData,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
    bool isBoldValue = false,
    String? highlightText,
    Color? highlightColor,
    Color? highlightTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade100),
                ),
                alignment: Alignment.center,
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
          if (highlightText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                highlightText,
                style: TextStyle(fontSize: 12, color: highlightTextColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUtilityRow({
    required IconData iconData,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
        ],
      ),
    ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 16,
      endIndent: 16,
    );
  }
}

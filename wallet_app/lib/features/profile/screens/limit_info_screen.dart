import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/custom_http_client.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_formatter.dart';

class LimitInfoScreen extends StatefulWidget {
  final String token;
  const LimitInfoScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<LimitInfoScreen> createState() => _LimitInfoScreenState();
}

class _LimitInfoScreenState extends State<LimitInfoScreen> {
  final _client = CustomHttpClient();
  bool _isLoading = true;
  Map<String, dynamic>? _limitsData;

  @override
  void initState() {
    super.initState();
    _fetchLimits();
  }

  Future<void> _fetchLimits() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getWalletLimits));
      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        setState(() {
          _limitsData = jsonResp['data'];
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
          'Hạn mức giao dịch',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            )
          : _limitsData == null
          ? const Center(child: Text('Không thể tải thông tin hạn mức'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final limits = _limitsData!['limits'];
    final usage = _limitsData!['usage'];

    final monthlyLimit =
        double.tryParse(limits['monthly_transaction_limit']) ?? 1;
    final monthlyUsage =
        double.tryParse(usage['monthly_transaction_usage']) ?? 0;
    final monthlyPercent = (monthlyUsage / monthlyLimit).clamp(0.0, 1.0);

    final dailyDepositLimit =
        double.tryParse(limits['daily_deposit_limit']) ?? 1;
    final dailyDepositUsage =
        double.tryParse(usage['daily_deposit_usage']) ?? 0;
    final dailyDepositPercent = (dailyDepositUsage / dailyDepositLimit).clamp(
      0.0,
      1.0,
    );

    final dailyWithdrawLimit =
        double.tryParse(limits['daily_withdrawal_limit']) ?? 1;
    final dailyWithdrawUsage =
        double.tryParse(usage['daily_withdrawal_usage']) ?? 0;
    final dailyWithdrawPercent = (dailyWithdrawUsage / dailyWithdrawLimit)
        .clamp(0.0, 1.0);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildMonthlySection(monthlyLimit, monthlyUsage, monthlyPercent),
          const SizedBox(height: 16),
          _buildDailySection(
            dailyDepositLimit,
            dailyDepositUsage,
            dailyDepositPercent,
            dailyWithdrawLimit,
            dailyWithdrawUsage,
            dailyWithdrawPercent,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMonthlySection(double limit, double usage, double percent) {
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
          const Text(
            'Hạn mức giao dịch trong tháng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tính tổng giao dịch của 1 ví.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primaryPink.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Colors.black54,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Dịch vụ thường',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(usage.toString()),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Giới hạn: ${CurrencyFormatter.format(limit.toString())}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                  ),
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySection(
    double depLimit,
    double depUsage,
    double depPercent,
    double withLimit,
    double withUsage,
    double withPercent,
  ) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primaryPink,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hạn mức nạp/rút tiền trong ngày',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Xem chi tiết hạn mức nạp/rút tiền với ngân hàng liên kết.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressRow('Đã nạp tiền', depUsage, depLimit, depPercent),
          const SizedBox(height: 16),
          _buildProgressRow('Đã rút tiền', withUsage, withLimit, withPercent),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    String title,
    double usage,
    double limit,
    double percent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 14),
            children: [
              TextSpan(text: '$title '),
              TextSpan(
                text: CurrencyFormatter.format(usage.toString()),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: ' / ${CurrencyFormatter.format(limit.toString())}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

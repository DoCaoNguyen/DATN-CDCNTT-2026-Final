import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/services/custom_http_client.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../home/services/home_service.dart';
import '../../financial_center/financial_center_api/financial_center_api.dart';

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
  double _balance = 0.0;
  List<dynamic> _linkedBanks = [];
  bool _isSpecialServiceTabActive = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final limitsRes = await _client.get(
        Uri.parse(ApiConfig.getWalletLimits),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      
      final balanceData = await HomeService().fetchBalance(widget.token);
      final banksData = await FinancialCenterApi.getSortedLinkedBanks(widget.token);
      
      if (mounted) {
        setState(() {
          if (limitsRes.statusCode == 200) {
            final jsonResp = jsonDecode(limitsRes.body);
            _limitsData = jsonResp['data'];
          }
          if (balanceData != null) {
            _balance = double.tryParse(balanceData['available_balance']?.toString() ?? '0') ?? 0.0;
          }
          _linkedBanks = banksData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hạn mức Ví Mio',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.support_agent_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            )
          : _limitsData == null
              ? const Center(child: Text('Không thể tải thông tin hạn mức'))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: Colors.pink,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    final limits = _limitsData!['limits'] ?? {};
    final usage = _limitsData!['usage'] ?? {};

    final monthlyLimit = double.tryParse(limits['monthly_transaction_limit']?.toString() ?? '100000000') ?? 100000000;
    final monthlyUsage = double.tryParse(usage['monthly_transaction_usage']?.toString() ?? '0') ?? 0;
    final monthlyPercent = (monthlyUsage / monthlyLimit).clamp(0.0, 1.0);

    final specialLimit = double.tryParse(limits['monthly_special_service_limit']?.toString() ?? '300000000') ?? 300000000;
    final specialUsage = double.tryParse(usage['monthly_special_service_usage']?.toString() ?? '0') ?? 0;
    final specialPercent = specialLimit > 0 ? (specialUsage / specialLimit).clamp(0.0, 1.0) : 0.0;

    final dailyDepositLimit = double.tryParse(limits['daily_deposit_limit']?.toString() ?? '50000000') ?? 50000000;
    final dailyDepositUsage = double.tryParse(usage['daily_deposit_usage']?.toString() ?? '0') ?? 0;
    final dailyDepositPercent = (dailyDepositUsage / dailyDepositLimit).clamp(0.0, 1.0);

    final dailyWithdrawLimit = double.tryParse(limits['daily_withdrawal_limit']?.toString() ?? '50000000') ?? 50000000;
    final dailyWithdrawUsage = double.tryParse(usage['daily_withdrawal_usage']?.toString() ?? '0') ?? 0;
    
    final dailyTxLimit = 50000000.0;
    final dailyTxUsage = monthlyUsage > dailyTxLimit ? dailyTxLimit : monthlyUsage; 
    final dailyTxPercent = (dailyTxUsage / dailyTxLimit).clamp(0.0, 1.0);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Column(
              children: [
                _buildMonthlyCard(monthlyLimit, monthlyUsage, monthlyPercent, specialLimit, specialUsage, specialPercent),
                const SizedBox(height: 12),
                _buildDailyDepositCard(dailyDepositLimit, dailyDepositUsage, dailyDepositPercent, dailyWithdrawLimit, dailyWithdrawUsage),
                const SizedBox(height: 12),
                _buildDailyTxCard(dailyTxLimit, dailyTxUsage, dailyTxPercent),
                const SizedBox(height: 12),
                _buildWalletCapacityCard(200000000.0, _balance),
                const SizedBox(height: 12),
                _buildDailyReceiveCard(100000000.0, 0.0),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCard(double limit, double usage, double percent, double specialLimit, double specialUsage, double specialPercent) {
    final double displayPercent = _isSpecialServiceTabActive ? specialPercent : percent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hạn mức giao dịch trong tháng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Tính tổng giao dịch của 1 ví. ',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                'Xem thêm',
                style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSpecialServiceTabActive = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: !_isSpecialServiceTabActive ? Colors.pink.shade100 : Colors.grey.shade200, 
                          width: !_isSpecialServiceTabActive ? 1.5 : 1.0),
                      borderRadius: BorderRadius.circular(12),
                      color: !_isSpecialServiceTabActive ? Colors.white : Colors.grey.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.monetization_on_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Dịch vụ thường',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: !_isSpecialServiceTabActive ? Colors.black : Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(usage.toString()),
                          style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Giới hạn:\n${CurrencyFormatter.format(limit.toString())}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSpecialServiceTabActive = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _isSpecialServiceTabActive ? Colors.pink.shade100 : Colors.grey.shade200, 
                          width: _isSpecialServiceTabActive ? 1.5 : 1.0),
                      borderRadius: BorderRadius.circular(12),
                      color: _isSpecialServiceTabActive ? Colors.white : Colors.grey.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.diamond_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Dịch vụ đặc biệt',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isSpecialServiceTabActive ? Colors.black : Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(specialUsage.toString()),
                          style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Giới hạn:\n${CurrencyFormatter.format(specialLimit.toString())}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Hạn mức trên được quy định theo luật của Ngân Hàng Nhà Nước đối với Ví điện tử.',
                    style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  '${(displayPercent * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                CircularPercentIndicator(
                  radius: 70.0,
                  lineWidth: 16.0,
                  percent: displayPercent,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: Colors.grey.shade100,
                  progressColor: Colors.green.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  '${((1 - displayPercent) * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDailyDepositCard(double depLimit, double depUsage, double depPercent, double withLimit, double withUsage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.pink, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hạn mức nạp/rút tiền trong ngày',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Xem chi tiết hạn mức nạp/rút tiền với ngân hàng liên kết.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLinearProgress('Đã nạp tiền', depUsage, depLimit),
          const SizedBox(height: 16),
          _buildLinearProgress('Đã rút tiền', withUsage, withLimit),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('Bạn đang liên kết với ngân hàng:', style: TextStyle(color: Colors.black87, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          if (_linkedBanks.isEmpty)
            const Text('Chưa có ngân hàng liên kết', style: TextStyle(color: Colors.black54, fontSize: 13, fontStyle: FontStyle.italic)),
          ..._linkedBanks.map((bank) {
            final String name = bank['name'] ?? 'Ngân hàng';
            final originalData = bank['original_data'] ?? {};
            final String shortName = originalData['short_name'] ?? name;
            final String logo = originalData['logo'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildBankItem(shortName, logo),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDailyTxCard(double limit, double usage, double percent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hạn mức giao dịch trong ngày',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                        children: [
                          const TextSpan(text: 'Xem chi tiết các loại giao dịch và hạn mức. '),
                          TextSpan(text: 'Xem thêm', style: TextStyle(color: Colors.blue.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLinearProgress('Đã giao dịch', usage, limit),
        ],
      ),
    );
  }

  Widget _buildWalletCapacityCard(double limit, double usage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.teal, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hạn mức sức chứa ví',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sức chứa tối đa của Ví Mio.',
                      style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLinearProgress('Số dư', usage, limit),
        ],
      ),
    );
  }

  Widget _buildDailyReceiveCard(double limit, double usage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.attach_money_rounded, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hạn mức nhận tiền trong ngày',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hạn mức nhận tiền từ ví Mio khác.',
                      style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLinearProgress('Đã nhận tiền', usage, limit),
        ],
      ),
    );
  }

  Widget _buildLinearProgress(String title, double usage, double limit) {
    double percent = (usage / limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            children: [
              TextSpan(text: '$title '),
              TextSpan(
                text: CurrencyFormatter.format(usage.toString()),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: ' / ${CurrencyFormatter.format(limit.toString())}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankItem(String name, String iconPath) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                radius: 16,
                child: const Icon(Icons.account_balance, size: 18, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          Text(
            'Xem hạn mức',
            style: TextStyle(color: Colors.pink.shade400, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

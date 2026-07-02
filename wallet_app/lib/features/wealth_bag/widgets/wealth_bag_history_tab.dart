import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';

class WealthBagHistoryTab extends StatefulWidget {
  const WealthBagHistoryTab({super.key});

  @override
  State<WealthBagHistoryTab> createState() => _WealthBagHistoryTabState();
}

class _WealthBagHistoryTabState extends State<WealthBagHistoryTab> {
  String _selectedFilter = 'ALL';
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  final List<Map<String, String>> _filters = [
    {'label': 'Tất cả', 'value': 'ALL'},
    {'label': 'Tiền lời', 'value': 'PROFIT'},
    {'label': 'Nhận tiền', 'value': 'RECEIVE'}, // Not fully implemented in backend, using placeholder
    {'label': 'Nạp tiền', 'value': 'DEPOSIT'},
    {'label': 'Rút tiền', 'value': 'WITHDRAW'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('${ApiConfig.wealthBagHistory}?type=$_selectedFilter');
      final response = await CustomHttpClient().get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _transactions = data['data'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching wealth bag history: $e");
    }
    setState(() {
      _transactions = [];
      _isLoading = false;
    });
  }

  String _formatAmount(dynamic amount) {
    double val = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat('#,###', 'vi_VN').format(val).replaceAll(',', '.') + 'đ';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthYear(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return "Tháng ${DateFormat('MM/yyyy').format(date)}";
    } catch (e) {
      return "";
    }
  }

  Map<String, List<dynamic>> _groupTransactionsByMonth() {
    Map<String, List<dynamic>> grouped = {};
    for (var tx in _transactions) {
      String monthYear = _getMonthYear(tx['created_at']);
      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }
      grouped[monthYear]!.add(tx);
    }
    return grouped;
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filter['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.deepOrange : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.deepOrange.withOpacity(0.1),
              backgroundColor: Colors.grey.shade200,
              side: BorderSide(
                color: isSelected ? Colors.deepOrange : Colors.transparent,
              ),
              onSelected: (selected) {
                if (selected && _selectedFilter != filter['value']) {
                  setState(() {
                    _selectedFilter = filter['value']!;
                  });
                  _fetchHistory();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    final bool isDepositOrProfit = tx['transaction_type'] == 'DEPOSIT' || tx['transaction_type'] == 'PROFIT';
    final String sign = isDepositOrProfit ? '+' : '-';
    final IconData icon = tx['transaction_type'] == 'WITHDRAW' 
        ? Icons.currency_exchange // Example icon for withdraw
        : Icons.monetization_on_outlined; // Example icon for deposit/profit

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(icon, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description'] ?? 'Giao dịch',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(tx['created_at']),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  "Số dư mới: ${_formatAmount(tx['balance_after'])}",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            "$sign${_formatAmount(tx['amount'])}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedTransactions = _groupTransactionsByMonth();

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _transactions.isEmpty
              ? const Center(child: Text("Không có giao dịch nào."))
              : ListView.builder(
                  itemCount: groupedTransactions.length,
                  itemBuilder: (context, index) {
                    String monthYear = groupedTransactions.keys.elementAt(index);
                    List<dynamic> monthTxs = groupedTransactions[monthYear]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Text(
                            monthYear,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            children: monthTxs.map((tx) => _buildTransactionItem(tx)).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

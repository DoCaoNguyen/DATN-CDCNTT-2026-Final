import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/services/custom_http_client.dart';
import '../widgets/help_center_screen_widgets.dart';

class HelpCenterScreen extends StatefulWidget {
  final String token;
  final String fullName;
  final String phone;

  const HelpCenterScreen({
    Key? key,
    required this.token,
    required this.fullName,
    required this.phone,
  }) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final CustomHttpClient _client = CustomHttpClient();
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.getTransactionHistory}?limit=5'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _transactions = data['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4EE), // Pink header
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trung tâm Trợ giúp',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HelpCenterHeader(fullName: widget.fullName),
            const SizedBox(height: 8),
            OnlineSupportBanner(token: widget.token),
            const SizedBox(height: 16),
            TransactionQueriesSection(
              isLoading: _isLoading,
              transactions: _transactions,
              token: widget.token,
              phone: widget.phone,
            ),
            const Divider(thickness: 6, color: Color(0xFFF5F5F5)),
            const HelpTopicsSection(),
            const Divider(thickness: 6, color: Color(0xFFF5F5F5)),
            const FAQSection(),
            const FeedbackBanner(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';

class LinkedServicesScreen extends StatefulWidget {
  const LinkedServicesScreen({Key? key}) : super(key: key);

  @override
  State<LinkedServicesScreen> createState() => _LinkedServicesScreenState();
}

class _LinkedServicesScreenState extends State<LinkedServicesScreen> {
  bool _isLoading = true;
  List<dynamic> _linkedServices = [];
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _fetchLinkedServices();
  }

  Future<void> _fetchLinkedServices() async {
    try {
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'access_token');
      
      if (token != null) {
        final response = await http.get(
          Uri.parse(ApiConfig.getLinkedServices),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (response.statusCode == 200) {
          final jsonResp = jsonDecode(response.body);
          if (jsonResp['data'] != null) {
            setState(() {
              _linkedServices = jsonResp['data'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching linked services: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hoá đơn định kỳ & Dịch vụ đã liê...',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Icon(Icons.support_agent, size: 18, color: Colors.black87),
                SizedBox(width: 8),
                Icon(Icons.home_outlined, size: 18, color: Colors.black87),
              ],
            ),
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBanner(),
                  const SizedBox(height: 16),
                  
                  _buildSectionTitle('Dịch vụ đã liên kết'),
                  _buildLinkedServicesList(),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Hóa đơn định kỳ'),
                  _buildEmptyRecurringBills(),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Tài khoản/thẻ thanh toán'),
                  _buildPaymentAccounts(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade100, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            'https://cdn-icons-png.flaticon.com/512/1012/1012558.png', 
            width: 40, height: 40,
            errorBuilder: (_, __, ___) => const Icon(Icons.phone_android, size: 40, color: Colors.pink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chụp màn hình - Gửi phản ánh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                const Text(
                  'Sử dụng ngay tính năng "Chụp - Phản ánh" để góp ý mọi vấn đề với Mio.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Xem hướng dẫn',
                    style: TextStyle(color: Colors.blue.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildLinkedServicesList() {
    if (_linkedServices.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Bạn chưa liên kết với dịch vụ nào.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _linkedServices.length,
      itemBuilder: (context, index) {
        final item = _linkedServices[index];
        final serviceName = item['service_name'] ?? 'Unknown';
        final limit = item['limit_per_day'] ?? 5000000;
        final formattedLimit = currencyFormatter.format(num.tryParse(limit.toString()) ?? 5000000);
        final iconUrl = item['service_icon'] ?? 'https://cdn-icons-png.flaticon.com/512/2875/2875364.png';
        
        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  iconUrl,
                  width: 40,
                  height: 40,
                  errorBuilder: (_, __, ___) => const Icon(Icons.apps, size: 40),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    const Text('Tên gợi nhớ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Hạn mức $formattedLimit/ngày', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Đang sử dụng',
                      style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyRecurringBills() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Image.network(
            'https://cdn-icons-png.flaticon.com/512/10339/10339678.png', 
            width: 80, height: 80,
            errorBuilder: (_, __, ___) => const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa có hóa đơn/dịch vụ thanh toán định kỳ nào.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add, color: Colors.pink, size: 16),
                SizedBox(width: 4),
                Text('Thêm hóa đơn', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentAccounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Áp dụng cho mọi hóa đơn định kỳ và dịch vụ đã liên kết',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Ví Mio', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Text(
                'Tuỳ chỉnh',
                style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.pink, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

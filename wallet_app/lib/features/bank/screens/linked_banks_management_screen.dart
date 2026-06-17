import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/services/custom_http_client.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import 'bank_link_screen.dart';

class LinkedBanksManagementScreen extends StatefulWidget {
  final String token;

  const LinkedBanksManagementScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<LinkedBanksManagementScreen> createState() => _LinkedBanksManagementScreenState();
}

class _LinkedBanksManagementScreenState extends State<LinkedBanksManagementScreen> {
  final _client = CustomHttpClient();
  bool _isLoading = true;
  List<dynamic> _linkedBanks = [];

  @override
  void initState() {
    super.initState();
    _fetchLinkedBanks();
  }

  Future<void> _fetchLinkedBanks() async {
    setState(() => _isLoading = true);
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getLinkedBanks),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _linkedBanks = data['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching linked banks: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unlinkBank(String bankId) async {
    setState(() => _isLoading = true);
    try {
      // Create custom DELETE URI or modify CustomHttpClient if DELETE is missing.
      // CustomHttpClient might only have get/post. Wait, I will use http.delete just in case
      // Let's check if CustomHttpClient has delete
      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/wallet/unlink-bank/$bankId'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hủy liên kết thành công"), backgroundColor: Colors.green),
        );
        _fetchLinkedBanks();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? "Hủy liên kết thất bại"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error unlinking bank: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi hệ thống"), backgroundColor: Colors.red),
      );
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUnlinkConfirmDialog(String bankId, String bankName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hủy liên kết", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("Bạn có chắc chắn muốn hủy liên kết ngân hàng $bankName?"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _unlinkBank(bankId);
              },
              child: const Text("Hủy liên kết", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tài khoản/Thẻ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : Column(
              children: [
                Expanded(
                  child: _linkedBanks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('Chưa có thẻ/tài khoản nào được liên kết', style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _linkedBanks.length,
                          itemBuilder: (context, index) {
                            final bank = _linkedBanks[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance, color: Colors.blue),
                                ),
                                title: Text(
                                  bank['bank_name'] ?? 'Ngân hàng',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    bank['card_number'] ?? '',
                                    style: const TextStyle(color: Colors.black87, letterSpacing: 1.2),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _showUnlinkConfirmDialog(bank['id'], bank['bank_name']),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BankLinkScreen(token: widget.token),
                            ),
                          ).then((_) => _fetchLinkedBanks());
                        },
                        child: const Text('THÊM LIÊN KẾT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

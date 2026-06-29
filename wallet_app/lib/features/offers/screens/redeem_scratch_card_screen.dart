import 'package:flutter/material.dart';
import '../services/offers_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import 'redeem_success_screen.dart';

class RedeemScratchCardScreen extends StatefulWidget {
  final String loyaltyPoints;
  final String? initialProvider;
  final int? initialValue;

  const RedeemScratchCardScreen({
    Key? key,
    required this.loyaltyPoints,
    this.initialProvider,
    this.initialValue,
  }) : super(key: key);

  @override
  State<RedeemScratchCardScreen> createState() => _RedeemScratchCardScreenState();
}

class _RedeemScratchCardScreenState extends State<RedeemScratchCardScreen> {
  bool _isLoading = false;
  final List<String> _providers = ['Viettel', 'Vinaphone', 'Mobifone', 'Vietnamobile'];
  final List<int> _values = [10000, 20000, 30000, 50000, 100000, 200000];
  
  String? _selectedProvider;
  int? _selectedValue;

  @override
  void initState() {
    super.initState();
    if (widget.initialProvider != null && _providers.contains(widget.initialProvider)) {
      _selectedProvider = widget.initialProvider;
    }
    if (widget.initialValue != null && _values.contains(widget.initialValue)) {
      _selectedValue = widget.initialValue;
    }
    
    // Auto show confirm dialog if both are provided
    if (_selectedProvider != null && _selectedValue != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConfirmDialog();
      });
    }
  }

  String _formatNumber(String value) {
    final number = int.tryParse(value);
    if (number == null) return "0";
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  Widget _buildProviderLogo(String provider) {
    switch (provider) {
      case 'Viettel':
        return const Text(
          'viettel',
          style: TextStyle(color: Color(0xFFEE0033), fontWeight: FontWeight.bold, fontSize: 14),
        );
      case 'Vinaphone':
        return const Text(
          'vinaphone',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
        );
      case 'Mobifone':
        return RichText(
          text: const TextSpan(
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            children: [
              TextSpan(text: 'mobi', style: TextStyle(color: Colors.blue)),
              TextSpan(text: 'fone', style: TextStyle(color: Colors.red)),
            ],
          ),
        );
      case 'Vietnamobile':
        return const Text(
          'Vietnamobile',
          style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 14),
        );
      default:
        return const Icon(Icons.sim_card, size: 20, color: Colors.grey);
    }
  }

  void _showConfirmDialog() {
    if (_selectedProvider == null || _selectedValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhà mạng và mệnh giá')),
      );
      return;
    }

    final int requiredPoints = (_selectedValue! * 0.95).toInt();
    final int currentPoints = int.tryParse(widget.loyaltyPoints) ?? 0;

    if (currentPoints < requiredPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xu của bạn không đủ để đổi thẻ mệnh giá này'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard_rounded, size: 48, color: Colors.pink),
              ),
              const SizedBox(height: 16),
              const Text(
                'Xác nhận đổi thẻ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng kiểm tra lại thông tin',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nhà mạng', style: TextStyle(color: Colors.black54)),
                        _buildProviderLogo(_selectedProvider!),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Colors.black12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mệnh giá thẻ', style: TextStyle(color: Colors.black54)),
                        Text(
                          '${_formatNumber(_selectedValue.toString())}đ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Colors.black12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Xu thanh toán',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              _formatNumber(requiredPoints.toString()),
                              style: const TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Close dialog

                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (pinSheetCtx) => PinConfirmBottomSheet(
                            onPinEntered: (pin) async {
                              try {
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('auth_token') ?? '';
                                
                                final verifyResp = await http.post(
                                  Uri.parse(ApiConfig.verifyPin),
                                  headers: {
                                    'Authorization': 'Bearer $token',
                                    'Content-Type': 'application/json',
                                  },
                                  body: jsonEncode({'pin': pin}),
                                );
                                
                                if (verifyResp.statusCode == 200) {
                                  if (!mounted) return null;
                                  Navigator.pop(pinSheetCtx);
                                  await _processRedeem(token);
                                  return null;
                                } else {
                                  final data = jsonDecode(verifyResp.body);
                                  return data['error'] ?? "Mã PIN không chính xác";
                                }
                              } catch (e) {
                                return "Lỗi kết nối máy chủ";
                              }
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processRedeem(String token) async {
    setState(() => _isLoading = true);
    try {
      final offersService = OffersService(token: token);
      final result = await offersService.redeemScratchCard(_selectedProvider!, _selectedValue!);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RedeemSuccessScreen(
            provider: result['provider'],
            faceValue: result['faceValue'],
            cardCode: result['cardCode'],
            serial: result['serial'],
            deductedPoints: result['deducted_points'],
            transactionId: result['transaction_id'].toString(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildProviderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn nhà mạng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _providers.map((provider) {
            final isSelected = _selectedProvider == provider;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedProvider = provider;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildProviderLogo(provider),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildValueSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn mệnh giá',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _values.length,
          itemBuilder: (context, index) {
            final value = _values[index];
            final isSelected = _selectedValue == value;
            final requiredPoints = (value * 0.95).toInt();
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedValue = value;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.pink.withOpacity(0.05) : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.pink : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_formatNumber(value.toString())}đ',
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? Colors.pink : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatNumber(requiredPoints.toString())} Xu',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFE4EE), Color(0xFFFFE4EE)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 0,
        title: const Text(
          'Đổi thẻ điện thoại',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFE4EE), Color(0xFFFFF0F5), Color(0xFFF5F5F9)],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số dư Xu:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              _formatNumber(widget.loyaltyPoints),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildProviderSelector(),
                  const SizedBox(height: 24),
                  _buildValueSelector(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _showConfirmDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Xác nhận đổi',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class RedeemScratchCardScreen extends StatefulWidget {
  final String loyaltyPoints;

  const RedeemScratchCardScreen({
    Key? key,
    required this.loyaltyPoints,
  }) : super(key: key);

  @override
  State<RedeemScratchCardScreen> createState() => _RedeemScratchCardScreenState();
}

class _RedeemScratchCardScreenState extends State<RedeemScratchCardScreen> {
  final List<String> _providers = ['Viettel', 'Vinaphone', 'Mobifone', 'Vietnamobile'];
  final List<int> _values = [10000, 20000, 30000, 50000, 100000];
  
  String? _selectedProvider;
  int? _selectedValue;

  String _formatNumber(String value) {
    final number = int.tryParse(value);
    if (number == null) return "0";
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _showConfirmDialog() {
    if (_selectedProvider == null || _selectedValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhà mạng và mệnh giá')),
      );
      return;
    }

    final int requiredPoints = (_selectedValue! * 0.95).toInt();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận đổi thẻ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_android_rounded, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text('Nhà mạng: $_selectedProvider'),
            const SizedBox(height: 8),
            Text('Mệnh giá: ${_formatNumber(_selectedValue.toString())}đ', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Xu cần đổi: ${_formatNumber(requiredPoints.toString())} Xu', style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng đổi Xu đang được phát triển!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                child: Text(
                  provider,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
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
      body: Container(
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

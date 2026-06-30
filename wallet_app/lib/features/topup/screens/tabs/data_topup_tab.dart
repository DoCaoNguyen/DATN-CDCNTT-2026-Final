import 'package:flutter/material.dart';
import '../../../../core/widgets/pin_confirm_bottom_sheet.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../services/topup_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../../core/services/custom_http_client.dart';
import '../../../../core/constants/api_config.dart';
import 'dart:convert';

class DataTopupTab extends StatefulWidget {
  final String token;

  const DataTopupTab({Key? key, required this.token}) : super(key: key);

  @override
  State<DataTopupTab> createState() => _DataTopupTabState();
}

class _DataTopupTabState extends State<DataTopupTab> {
  final TextEditingController _phoneController = TextEditingController();

  final List<Map<String, dynamic>> _dataPackages = [
    {
      'id': 'DATA_10K_1D',
      'name': 'Giải trí cả ngày',
      'duration': '1 ngày',
      'data': '1GB',
      'price': 10000,
      'description': 'Miễn phí truy cập MXH. 1GB data tốc độ cao.',
    },
    {
      'id': 'DATA_50K_7D',
      'name': 'Tuần lướt thả ga',
      'duration': '7 ngày',
      'data': '7GB',
      'price': 50000,
      'description': '1GB data tốc độ cao mỗi ngày.',
    },
    {
      'id': 'DATA_100K_30D',
      'name': 'Gói tháng cơ bản',
      'duration': '30 ngày',
      'data': '15GB',
      'price': 100000,
      'description': 'Lướt web cả tháng với 15GB tốc độ cao.',
    },
    {
      'id': 'DATA_200K_30D',
      'name': 'Gói tháng VIP',
      'duration': '30 ngày',
      'data': '60GB',
      'price': 200000,
      'description': '2GB tốc độ cao mỗi ngày. Miễn phí Tiktok, Youtube.',
    },
  ];

  Map<String, dynamic>? _selectedPackage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMyPhone();
  }

  Future<void> _fetchMyPhone() async {
    try {
      final client = CustomHttpClient();
      final response = await client.get(Uri.parse(ApiConfig.getMyProfile));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['phone'] != null) {
          if (mounted && _phoneController.text.isEmpty) {
            setState(() {
              _phoneController.text = data['data']['phone'];
            });
          }
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        String phone = contact.phones.first.number.replaceAll(RegExp(r'\D'), '');
        setState(() {
          _phoneController.text = phone;
        });
      }
    }
  }

  void _showConfirmDialog() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      SnackbarUtils.showError(context, 'Vui lòng nhập số điện thoại');
      return;
    }
    if (_selectedPackage == null) {
      SnackbarUtils.showError(context, 'Vui lòng chọn gói Data');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          Navigator.pop(context); // Close PIN
          await _processTopup(phone);
          return null;
        },
      ),
    );
  }

  Future<void> _processTopup(String phone) async {
    setState(() => _isLoading = true);
    try {
      final service = TopupService(token: widget.token);
      final result = await service.processTopup(
        type: 'DATA',
        phone: phone,
        amount: _selectedPackage!['price'],
        provider: _selectedPackage!['name'],
        dataPackageId: _selectedPackage!['id'],
      );

      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nạp thành công', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          content: Text('Bạn đã nạp thành công gói ${_selectedPackage!['name']} cho số điện thoại $phone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _phoneController.clear();
                  _selectedPackage = null;
                });
              },
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Số điện thoại nạp Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Nhập số điện thoại',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.contacts, color: Colors.pink),
                  onPressed: _pickContact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Chọn gói Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dataPackages.length,
            itemBuilder: (context, index) {
              final pkg = _dataPackages[index];
              final isSelected = _selectedPackage == pkg;
              return GestureDetector(
                onTap: () => setState(() => _selectedPackage = pkg),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pink.shade50 : Colors.white,
                    border: Border.all(color: isSelected ? Colors.pink : Colors.grey.shade300, width: isSelected ? 2 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.pink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(pkg['data'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            Text(pkg['duration'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pkg['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.pink : Colors.black87)),
                            const SizedBox(height: 4),
                            Text(pkg['description'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatNumber(pkg['price'])}đ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedPackage != null) ? _showConfirmDialog : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Nạp ngay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

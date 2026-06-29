import 'package:flutter/material.dart';
import '../../../../core/widgets/pin_confirm_bottom_sheet.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../services/topup_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../../core/services/custom_http_client.dart';
import '../../../../core/constants/api_config.dart';
import 'dart:convert';

class PhoneTopupTab extends StatefulWidget {
  final String token;

  const PhoneTopupTab({Key? key, required this.token}) : super(key: key);

  @override
  State<PhoneTopupTab> createState() => _PhoneTopupTabState();
}

class _PhoneTopupTabState extends State<PhoneTopupTab> {
  final TextEditingController _phoneController = TextEditingController();
  final List<int> _values = [10000, 20000, 30000, 50000, 100000, 200000, 300000, 500000];

  int? _selectedValue;
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
    if (_selectedValue == null) {
      SnackbarUtils.showError(context, 'Vui lòng chọn mệnh giá');
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
        type: 'PHONE',
        phone: phone,
        amount: _selectedValue!,
      );

      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nạp thành công', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          content: Text('Bạn đã nạp thành công ${_formatNumber(result['amount'])}đ cho số điện thoại $phone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _phoneController.clear();
                  _selectedValue = null;
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
          const Text('Số điện thoại nạp tiền', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          const Text('Chọn mệnh giá nạp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _values.length,
            itemBuilder: (context, index) {
              final val = _values[index];
              final isSelected = _selectedValue == val;
              return GestureDetector(
                onTap: () => setState(() => _selectedValue = val),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pink.shade50 : Colors.white,
                    border: Border.all(color: isSelected ? Colors.pink : Colors.grey.shade300, width: isSelected ? 2 : 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_formatNumber(val)}đ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.pink : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedValue != null) ? _showConfirmDialog : null,
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

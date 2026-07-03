import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../financial_center_api/financial_center_api.dart';
import '../widgets/financial_center_appbar_actions.dart';

class PaymentOrderScreen extends StatefulWidget {
  final String token;
  const PaymentOrderScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<PaymentOrderScreen> createState() => _PaymentOrderScreenState();
}

class _PaymentOrderScreenState extends State<PaymentOrderScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _fetchLinkedBanks();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'payment_order_prefs_${widget.token}';
    final List<Map<String, dynamic>> savedData = _paymentMethods.map((m) => {
      'id': m['id'],
      'isEnabled': m['isEnabled'],
    }).toList();
    await prefs.setString(key, jsonEncode(savedData));
  }

  Future<void> _fetchLinkedBanks() async {
    try {
      final sortedBanks = await FinancialCenterApi.getSortedLinkedBanks(widget.token);
      
      List<Map<String, dynamic>> methods = [
        {
          'id': 'wallet',
          'name': 'Ví Mio',
          'iconData': Icons.account_balance_wallet,
          'iconColor': Colors.pink,
          'isEnabled': true,
          'isFixed': true,
        }
      ];

      methods.addAll(sortedBanks);

      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool get _isAllEnabled {
    if (_paymentMethods.isEmpty) return false;
    final unfixed = _paymentMethods.where((method) => !method['isFixed']);
    if (unfixed.isEmpty) return true;
    return unfixed.every((method) => method['isEnabled'] == true);
  }

  void _toggleAll(bool? value) {
    if (value == null) return;
    setState(() {
      for (var method in _paymentMethods) {
        if (!method['isFixed']) {
          method['isEnabled'] = value;
        }
      }
    });
    _savePreferences();
  }

  void _toggleItem(int index, bool? value) {
    if (value == null || _paymentMethods[index]['isFixed']) return;
    setState(() {
      _paymentMethods[index]['isEnabled'] = value;
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCE4EC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thứ tự thanh toán',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: const [
          FinancialCenterAppBarActions(),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Nhấn giữ ≡ để sắp xếp thứ tự thanh toán',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    children: [
                      const TextSpan(text: 'Bật tắt '),
                      WidgetSpan(
                        child: Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                        alignment: PlaceholderAlignment.middle,
                      ),
                      const TextSpan(text: ' để chọn tài khoản/thẻ được sử dụng cho '),
                      const TextSpan(
                        text: 'dịch vụ liên kết & hoá đơn định kỳ',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(text: ' (Apple, Google...)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Thứ tự thanh toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 12),

          // Toggle All
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _isAllEnabled,
                    onChanged: _toggleAll,
                    activeColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Bật tất cả tài khoản/thẻ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reorderable List
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 40),
                itemCount: _paymentMethods.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _paymentMethods.removeAt(oldIndex);
                    _paymentMethods.insert(newIndex, item);
                  });
                  _savePreferences();
                },
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  return _buildReorderableItem(
                    key: ValueKey(method['id']),
                    index: index,
                    method: method,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableItem({required Key key, required int index, required Map<String, dynamic> method}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Index number
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: method['isEnabled'],
                      onChanged: method['isFixed'] ? null : (val) => _toggleItem(index, val),
                      activeColor: method['isFixed'] ? Colors.pink.shade100 : AppColors.primaryPink,
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.pink.shade100;
                        }
                        if (states.contains(MaterialState.selected)) {
                          return AppColors.primaryPink;
                        }
                        return Colors.white;
                      }),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    alignment: Alignment.center,
                    child: Icon(method['iconData'], color: method['iconColor'], size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      method['name'],
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  ),
                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.menu, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wallet_app/core/services/custom_http_client.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/pin_confirm_bottom_sheet.dart';

class LinkedServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const LinkedServiceDetailScreen({Key? key, required this.service})
    : super(key: key);

  @override
  State<LinkedServiceDetailScreen> createState() =>
      _LinkedServiceDetailScreenState();
}

class _LinkedServiceDetailScreenState extends State<LinkedServiceDetailScreen> {
  final _secureStorage = const FlutterSecureStorage();
  final _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  bool _isLoading = false;
  bool _isAutoDebitEnabled = true;

  num _dailyLimit = 0;
  num _txLimit = 0;

  List<dynamic> _transactions = [];
  bool _isLoadingTransactions = true;

  final List<num> dailyLimits = [
    100000,
    200000,
    500000,
    1000000,
    2000000,
    5000000,
    10000000,
    20000000,
    30000000,
  ];

  final List<num> txLimits = [
    100000,
    200000,
    500000,
    1000000,
    2000000,
    5000000,
  ];

  @override
  void initState() {
    super.initState();
    _dailyLimit =
        num.tryParse(
          widget.service['limit_per_day']?.toString() ?? '5000000',
        ) ??
        5000000;
    _txLimit =
        num.tryParse(
          widget.service['limit_per_transaction']?.toString() ?? '5000000',
        ) ??
        5000000;
    _isAutoDebitEnabled = widget.service['status'] == 'ACTIVE';
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final token = await _secureStorage.read(key: 'access_token');
      if (token == null) return;

      final response = await CustomHttpClient().get(
        Uri.parse(ApiConfig.getLinkedServiceTransactions(widget.service['id'])),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _transactions = jsonResp['data'] ?? [];
            _isLoadingTransactions = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) {
        setState(() => _isLoadingTransactions = false);
      }
    }
  }

  Future<void> _updateLimits(num newDaily, num newTx) async {
    if (newTx > newDaily) {
      SnackbarUtils.showWarning(
        context,
        'Hạn mức giao dịch phải nhỏ hơn hoặc bằng hạn mức ngày!',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await _secureStorage.read(key: 'access_token');
      final response = await CustomHttpClient().patch(
        Uri.parse(ApiConfig.updateLinkedServiceLimits(widget.service['id'])),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'limit_per_day': newDaily,
          'limit_per_transaction': newTx,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _dailyLimit = newDaily;
          _txLimit = newTx;
        });
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Cập nhật hạn mức thành công');
        }
      } else {
        throw Exception('Failed to update limits');
      }
    } catch (e) {
      debugPrint('Error updating limits: $e');
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Có lỗi xảy ra, vui lòng thử lại sau!',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleToggleStatus(bool newValue) async {
    if (!newValue) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn có muốn tạm khoá liên kết với ${widget.service['service_name']}?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bạn sẽ không thể thanh toán cho dịch vụ này đến khi bạn mở khoá.',
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Tạm khóa',
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Để sau',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirm != true) return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          try {
            final token = await _secureStorage.read(key: 'access_token');
            final verifyRes = await CustomHttpClient().post(
              Uri.parse(ApiConfig.verifyPin),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'pin': pin}),
            );
            final verifyJson = jsonDecode(verifyRes.body);
            if (verifyRes.statusCode != 200) {
              return verifyJson['error'] ??
                  verifyJson['message'] ??
                  'Mã PIN không đúng';
            }

            final updateRes = await CustomHttpClient().patch(
              Uri.parse(
                ApiConfig.updateLinkedServiceLimits(
                  widget.service['id'].toString(),
                ),
              ),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'status': newValue ? 'ACTIVE' : 'INACTIVE'}),
            );

            if (updateRes.statusCode == 200) {
              if (mounted) {
                setState(() => _isAutoDebitEnabled = newValue);
                Navigator.pop(context);
                SnackbarUtils.showSuccess(
                  context,
                  newValue ? 'Đã mở khóa dịch vụ' : 'Đã tạm khóa dịch vụ',
                );
              }
              return null;
            } else {
              return 'Cập nhật thất bại';
            }
          } catch (e) {
            return 'Có lỗi xảy ra';
          }
        },
      ),
    );
  }

  Future<void> _unlinkService() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy liên kết'),
        content: Text(
          'Bạn có chắc chắn muốn hủy liên kết với ${widget.service['service_name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Hủy liên kết',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          try {
            final token = await _secureStorage.read(key: 'access_token');

            final verifyRes = await CustomHttpClient().post(
              Uri.parse(ApiConfig.verifyPin),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'pin': pin}),
            );
            final verifyJson = jsonDecode(verifyRes.body);
            if (verifyRes.statusCode != 200) {
              return verifyJson['error'] ??
                  verifyJson['message'] ??
                  'Mã PIN không đúng';
            }

            final response = await CustomHttpClient().delete(
              Uri.parse(
                ApiConfig.unlinkService(widget.service['id'].toString()),
              ),
              headers: {'Authorization': 'Bearer $token'},
            );

            if (response.statusCode == 200) {
              if (mounted) {
                Navigator.pop(context); // Close BottomSheet
                SnackbarUtils.showSuccess(
                  context,
                  'Đã hủy liên kết thành công',
                );
                Navigator.pop(context, true); // Close screen & refresh
              }
              return null;
            } else {
              return 'Hủy liên kết thất bại';
            }
          } catch (e) {
            return 'Có lỗi xảy ra, vui lòng thử lại sau';
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = '';
    if (widget.service['created_at'] != null) {
      try {
        final date = DateTime.parse(widget.service['created_at']);
        formattedDate = DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        formattedDate = 'N/A';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.service['service_name'] ?? 'Chi tiết dịch vụ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Service Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                widget.service['service_icon'] != null &&
                                    widget.service['service_icon']
                                        .toString()
                                        .isNotEmpty
                                ? Image.network(
                                    widget.service['service_icon'],
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.apps, size: 40),
                                  )
                                : const Icon(
                                    Icons.apps,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.service['service_name'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _isAutoDebitEnabled
                                  ? Colors.green.shade100
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _isAutoDebitEnabled
                                  ? 'Đang sử dụng'
                                  : 'Ngừng sử dụng',
                              style: TextStyle(
                                color: _isAutoDebitEnabled
                                    ? Colors.green
                                    : Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ngày liên kết',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Settings Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cài đặt',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cho phép thanh toán',
                            style: TextStyle(fontSize: 15),
                          ),
                          Switch(
                            value: _isAutoDebitEnabled,
                            activeColor: Colors.green,
                            onChanged: (val) => _handleToggleStatus(val),
                          ),
                        ],
                      ),
                      if (!_isAutoDebitEnabled) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Các giao dịch từ ${widget.service['service_name']} sẽ thất bại. Bật để tiếp tục thanh toán.',
                          style: const TextStyle(
                            color: Colors.pink,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Bạn cho phép dịch vụ thanh toán không cần mở app, bao gồm các gói định kỳ (nếu có).',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Limits Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hạn mức thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Theo ngày',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: dailyLimits.map((limit) {
                            final isSelected = _dailyLimit == limit;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(
                                  '${_currencyFormatter.format(limit).replaceAll(' đ', 'đ')} /ngày',
                                ),
                                selected: isSelected,
                                selectedColor: Colors.white,
                                backgroundColor: Colors.white,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: !_isAutoDebitEnabled
                                        ? Colors.grey.shade300
                                        : (isSelected
                                              ? Colors.pink
                                              : Colors.grey.shade300),
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: !_isAutoDebitEnabled
                                      ? Colors.grey.shade400
                                      : (isSelected
                                            ? Colors.pink
                                            : Colors.grey.shade600),
                                  fontWeight: isSelected && _isAutoDebitEnabled
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (_isAutoDebitEnabled && selected)
                                    _updateLimits(limit, _txLimit);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Theo giao dịch',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: txLimits.map((limit) {
                            final isSelected = _txLimit == limit;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(
                                  '${_currencyFormatter.format(limit).replaceAll(' đ', 'đ')} /GD',
                                ),
                                selected: isSelected,
                                selectedColor: Colors.white,
                                backgroundColor: Colors.white,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: !_isAutoDebitEnabled
                                        ? Colors.grey.shade300
                                        : (isSelected
                                              ? Colors.pink
                                              : Colors.grey.shade300),
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: !_isAutoDebitEnabled
                                      ? Colors.grey.shade400
                                      : (isSelected
                                            ? Colors.pink
                                            : Colors.grey.shade600),
                                  fontWeight: isSelected && _isAutoDebitEnabled
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (_isAutoDebitEnabled && selected)
                                    _updateLimits(_dailyLimit, limit);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lưu ý: Hạn mức thanh toán theo giao dịch phải nhỏ hơn hoặc bằng hạn mức thanh toán theo ngày',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Transaction History
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lịch sử thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingTransactions)
                        const Center(child: CircularProgressIndicator())
                      else if (_transactions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Chưa có giao dịch nào',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Container(
                          height:
                              350, // Cố định chiều cao khung chứa khoảng 5 giao dịch
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            shrinkWrap:
                                false, // Để scrollable mượt mà trong khung cố định
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _transactions.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final tx = _transactions[index];
                              final amountStr = _currencyFormatter
                                  .format(
                                    num.parse(tx['amount']?.toString() ?? '0'),
                                  )
                                  .replaceAll(' đ', 'đ');
                              String timeStr = '';
                              if (tx['created_at'] != null) {
                                final date = DateTime.parse(tx['created_at']);
                                timeStr = DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(date);
                              }
                              final isSuccess = tx['status'] == 'SUCCESS';

                              return Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSuccess
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: isSuccess
                                          ? Colors.green
                                          : Colors.red,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Thanh toán ${widget.service['service_name']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '-$amountStr',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isSuccess ? 'Thành công' : 'Thất bại',
                                        style: TextStyle(
                                          color: isSuccess
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // 5. Unlink Button
                OutlinedButton.icon(
                  onPressed: _unlinkService,
                  icon: const Icon(Icons.link_off, color: Colors.black87),
                  label: const Text(
                    'Huỷ liên kết',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

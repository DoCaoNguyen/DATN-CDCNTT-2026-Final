import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../widgets/custom_date_range_picker_sheet.dart';

class ExportTransactionScreen extends StatefulWidget {
  final String token;

  const ExportTransactionScreen({Key? key, required this.token})
    : super(key: key);

  @override
  State<ExportTransactionScreen> createState() =>
      _ExportTransactionScreenState();
}

class _ExportTransactionScreenState extends State<ExportTransactionScreen> {
  final CustomHttpClient _client = CustomHttpClient();
  final TextEditingController _emailController = TextEditingController();
  String _selectedDuration = '7 ngày';
  bool _isLoading = false;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getMyProfile));
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['data'] != null) {
          final email = resData['data']['email'];
          if (email != null && email.toString().isNotEmpty) {
            setState(() {
              _emailController.text = email.toString();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy thông tin cá nhân: $e");
    }
  }

  void _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ email hợp lệ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> requestBody = {'email': email};

      if (_customStartDate != null && _customEndDate != null) {
        requestBody['startDate'] = _customStartDate!.toIso8601String();
        requestBody['endDate'] = _customEndDate!.toIso8601String();
      } else {
        int duration = 7;
        if (_selectedDuration == '30 ngày')
          duration = 30;
        else if (_selectedDuration == '60 ngày')
          duration = 60;
        else if (_selectedDuration == '90 ngày')
          duration = 90;
        requestBody['duration'] = duration.toString();
      }

      final response = await _client.post(
        Uri.parse(ApiConfig.exportTransaction),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Thành công',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Yêu cầu xuất dữ liệu đã được gửi. Vui lòng kiểm tra email của bạn.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Đóng',
                  style: TextStyle(color: AppColors.primaryPink),
                ),
              ),
            ],
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Gửi thất bại')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lỗi kết nối mạng')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomDateRangePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CustomDateRangePickerSheet(
          initialStartDate: _customStartDate,
          initialEndDate: _customEndDate,
          onDateRangeSelected: (start, end) {
            setState(() {
              _customStartDate = start;
              _customEndDate = end;
              final startStr =
                  "${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}";
              final endStr =
                  "${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}";
              _selectedDuration = 'Từ $startStr đến $endStr';
            });
          },
        );
      },
    );
  }

  Widget _buildDurationButton(String title) {
    bool isCustomSelected =
        title == 'Thời gian khác' && _selectedDuration.startsWith('Từ ');
    bool isSelected = _selectedDuration == title || isCustomSelected;

    String displayTitle = title;
    if (title == 'Thời gian khác' && isCustomSelected) {
      displayTitle = _selectedDuration;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (title == 'Thời gian khác') {
            _showCustomDateRangePicker();
          } else {
            setState(() {
              _selectedDuration = title;
              _customStartDate = null;
              _customEndDate = null;
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primaryPink : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? AppColors.primaryPink : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: displayTitle.length > 15 ? 12 : 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
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
        title: const Text(
          "Tải dữ liệu giao dịch",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Khoảng thời gian",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tính năng hỗ trợ xuất dữ liệu trong 12 tháng gần nhất",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildDurationButton('7 ngày'),
                      _buildDurationButton('30 ngày'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildDurationButton('60 ngày'),
                      _buildDurationButton('90 ngày'),
                    ],
                  ),
                  Row(children: [_buildDurationButton('Thời gian khác')]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tệp tin sẽ được gửi về:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email*",
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primaryPink,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Xác nhận",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

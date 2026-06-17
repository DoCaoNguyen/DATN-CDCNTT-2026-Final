import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';

class ExportTransactionScreen extends StatefulWidget {
  final String token;

  const ExportTransactionScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ExportTransactionScreen> createState() => _ExportTransactionScreenState();
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
      print("Lỗi lấy thông tin cá nhân: $e");
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
      final Map<String, dynamic> requestBody = {
        'email': email,
      };

      if (_customStartDate != null && _customEndDate != null) {
        requestBody['startDate'] = _customStartDate!.toIso8601String();
        requestBody['endDate'] = _customEndDate!.toIso8601String();
      } else {
        int duration = 7;
        if (_selectedDuration == '30 ngày') duration = 30;
        else if (_selectedDuration == '60 ngày') duration = 60;
        else if (_selectedDuration == '90 ngày') duration = 90;
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
            title: const Text('Thành công', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Yêu cầu xuất dữ liệu đã được gửi. Vui lòng kiểm tra email của bạn.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Đóng', style: TextStyle(color: AppColors.primaryPink)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối mạng')),
      );
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
        return _CustomDateRangePickerSheet(
          initialStartDate: _customStartDate,
          initialEndDate: _customEndDate,
          onDateRangeSelected: (start, end) {
            setState(() {
              _customStartDate = start;
              _customEndDate = end;
              final startStr = "${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}";
              final endStr = "${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}";
              _selectedDuration = 'Từ $startStr đến $endStr';
            });
          },
        );
      },
    );
  }

  Widget _buildDurationButton(String title) {
    bool isCustomSelected = title == 'Thời gian khác' && _selectedDuration.startsWith('Từ ');
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
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
                  Row(
                    children: [
                      _buildDurationButton('Thời gian khác'),
                    ],
                  ),
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
                        borderSide: const BorderSide(color: AppColors.primaryPink),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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

class _CustomDateRangePickerSheet extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime start, DateTime end) onDateRangeSelected;

  const _CustomDateRangePickerSheet({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  State<_CustomDateRangePickerSheet> createState() => _CustomDateRangePickerSheetState();
}

class _CustomDateRangePickerSheetState extends State<_CustomDateRangePickerSheet> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  late final DateTime _firstDate;
  late final DateTime _lastDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _firstDate = DateTime(now.year - 1, now.month, now.day);
    _lastDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  void _onDayClick(DateTime date) {
    if (date.isBefore(_firstDate) || date.isAfter(_lastDate)) return;

    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = date;
        _endDate = null;
      } else {
        if (date.isBefore(_startDate!)) {
          _startDate = date;
          _endDate = null;
        } else {
          _endDate = date;
        }
      }
    });
  }

  String _getVietnameseWeekday(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday: return 'T2';
      case DateTime.tuesday: return 'T3';
      case DateTime.wednesday: return 'T4';
      case DateTime.thursday: return 'T5';
      case DateTime.friday: return 'T6';
      case DateTime.saturday: return 'T7';
      case DateTime.sunday: return 'CN';
      default: return '';
    }
  }

  String _formatDateDisplay(DateTime? date) {
    if (date == null) return '-- --/--/----';
    final wk = _getVietnameseWeekday(date);
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year;
    return '$wk, $dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    final int year = _currentMonth.year;
    final int month = _currentMonth.month;
    final int startingWeekday = DateTime(year, month, 1).weekday;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final int emptyCells = startingWeekday - 1; 
    final int totalCells = emptyCells + daysInMonth;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), 
                const Text(
                  'Chọn khoảng thời gian',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _startDate != null ? AppColors.primaryPink.withOpacity(0.5) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày bắt đầu',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateDisplay(_startDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _startDate != null ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _endDate != null ? AppColors.primaryPink.withOpacity(0.5) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày kết thúc',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateDisplay(_endDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _endDate != null ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                    });
                  },
                ),
                Text(
                  'Tháng ${_currentMonth.month}/${_currentMonth.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentMonth.year > now.year || (_currentMonth.year == now.year && _currentMonth.month >= now.month)
                      ? null
                      : () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                          });
                        },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((day) {
                final isWeekend = day == 'T7' || day == 'CN';
                return Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isWeekend ? Colors.red : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                if (index < emptyCells) {
                  return const SizedBox.shrink();
                }
                
                final int day = index - emptyCells + 1;
                final DateTime date = DateTime(year, month, day);
                final bool isOutOfRange = date.isBefore(_firstDate) || date.isAfter(_lastDate);
                
                final bool isStart = _startDate != null &&
                    date.year == _startDate!.year &&
                    date.month == _startDate!.month &&
                    date.day == _startDate!.day;
                    
                final bool isEnd = _endDate != null &&
                    date.year == _endDate!.year &&
                    date.month == _endDate!.month &&
                    date.day == _endDate!.day;
                    
                final bool inRange = _startDate != null && _endDate != null &&
                    date.isAfter(_startDate!) && date.isBefore(_endDate!);

                Color? cellColor;
                Color textColor = Colors.black87;
                BoxDecoration? decoration;

                if (isOutOfRange) {
                  textColor = Colors.grey.shade300;
                } else if (isStart || isEnd) {
                  textColor = Colors.white;
                  decoration = const BoxDecoration(
                    color: AppColors.primaryPink,
                    shape: BoxShape.circle,
                  );
                } else if (inRange) {
                  cellColor = AppColors.primaryPink.withOpacity(0.12);
                  textColor = AppColors.primaryPink;
                }
                
                final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                if (isWeekend && !isStart && !isEnd && !inRange && !isOutOfRange) {
                  textColor = Colors.red;
                }

                return GestureDetector(
                  onTap: isOutOfRange ? null : () => _onDayClick(date),
                  child: Container(
                    color: cellColor,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    alignment: Alignment.center,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: decoration,
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: (isStart || isEnd) ? FontWeight.bold : FontWeight.normal,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_startDate != null && _endDate != null)
                      ? () {
                          widget.onDateRangeSelected(_startDate!, _endDate!);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    disabledBackgroundColor: Colors.grey.shade200,
                    disabledForegroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Xác nhận",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

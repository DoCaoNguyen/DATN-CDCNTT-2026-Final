import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CustomDateRangePickerSheet extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime start, DateTime end) onDateRangeSelected;

  const CustomDateRangePickerSheet({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  State<CustomDateRangePickerSheet> createState() =>
      CustomDateRangePickerSheetState();
}

class CustomDateRangePickerSheetState
    extends State<CustomDateRangePickerSheet> {
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
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
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
                  icon: const Icon(Icons.close_rounded, color: Colors.black54),
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
                        color: _startDate != null
                            ? AppColors.primaryPink.withValues(alpha: 0.5)
                            : Colors.transparent,
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
                            color: _startDate != null
                                ? Colors.black87
                                : Colors.grey,
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
                        color: _endDate != null
                            ? AppColors.primaryPink.withValues(alpha: 0.5)
                            : Colors.transparent,
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
                            color: _endDate != null
                                ? Colors.black87
                                : Colors.grey,
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
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  'Tháng ${_currentMonth.month}/${_currentMonth.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed:
                      _currentMonth.year > now.year ||
                          (_currentMonth.year == now.year &&
                              _currentMonth.month >= now.month)
                      ? null
                      : () {
                          setState(() {
                            _currentMonth = DateTime(
                              _currentMonth.year,
                              _currentMonth.month + 1,
                            );
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
                final bool isOutOfRange =
                    date.isBefore(_firstDate) || date.isAfter(_lastDate);

                final bool isStart =
                    _startDate != null &&
                    date.year == _startDate!.year &&
                    date.month == _startDate!.month &&
                    date.day == _startDate!.day;

                final bool isEnd =
                    _endDate != null &&
                    date.year == _endDate!.year &&
                    date.month == _endDate!.month &&
                    date.day == _endDate!.day;

                final bool inRange =
                    _startDate != null &&
                    _endDate != null &&
                    date.isAfter(_startDate!) &&
                    date.isBefore(_endDate!);

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
                  cellColor = AppColors.primaryPink.withValues(alpha: 0.12);
                  textColor = AppColors.primaryPink;
                }

                final isWeekend =
                    date.weekday == DateTime.saturday ||
                    date.weekday == DateTime.sunday;
                if (isWeekend &&
                    !isStart &&
                    !isEnd &&
                    !inRange &&
                    !isOutOfRange) {
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
                          fontWeight: (isStart || isEnd)
                              ? FontWeight.bold
                              : FontWeight.normal,
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

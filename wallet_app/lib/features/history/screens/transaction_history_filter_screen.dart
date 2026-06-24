import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionFilterConfig {
  final String time; // "Tất cả", "Tháng 6/2026", ...
  final String account; // "Tất cả", "Ví Mio", "Tài khoản ngân hàng"
  final String? service; // null means all

  TransactionFilterConfig({
    this.time = "Tất cả",
    this.account = "Tất cả",
    this.service,
  });

  TransactionFilterConfig copyWith({
    String? time,
    String? account,
    String? service,
    bool clearService = false,
  }) {
    return TransactionFilterConfig(
      time: time ?? this.time,
      account: account ?? this.account,
      service: clearService ? null : (service ?? this.service),
    );
  }
}

class TransactionHistoryFilterScreen extends StatefulWidget {
  final TransactionFilterConfig initialConfig;

  const TransactionHistoryFilterScreen({Key? key, required this.initialConfig})
    : super(key: key);

  @override
  State<TransactionHistoryFilterScreen> createState() =>
      _TransactionHistoryFilterScreenState();
}

class _TransactionHistoryFilterScreenState
    extends State<TransactionHistoryFilterScreen> {
  late TransactionFilterConfig _config;
  bool _showAllMonths = false;

  final List<String> _accountOptions = [
    "Tất cả",
    "Ví Mio",
    "Tài khoản ngân hàng",
  ];

  final List<Map<String, dynamic>> _serviceOptions = [
    {
      "label": "Nhận tiền",
      "icon": Icons.arrow_downward_rounded,
      "color": Colors.green,
    },
    {"label": "Rút tiền", "icon": Icons.outbox_rounded, "color": Colors.teal},
    {
      "label": "Chuyển tiền",
      "icon": Icons.swap_horiz_rounded,
      "color": Colors.red,
    },
    {
      "label": "Nạp tiền",
      "icon": Icons.account_balance_wallet_rounded,
      "color": Colors.blue,
    },
    {
      "label": "Chi tiêu sinh hoạt",
      "icon": Icons.shopping_basket_rounded,
      "color": Colors.orange,
    },
    {
      "label": "Hóa đơn & Tiện ích",
      "icon": Icons.receipt_long_rounded,
      "color": Colors.green,
    },
    {
      "label": "Giải trí & Mua sắm",
      "icon": Icons.movie_rounded,
      "color": Colors.pinkAccent,
    },
    {
      "label": "Chi phí phát sinh",
      "icon": Icons.warning_amber_rounded,
      "color": Colors.redAccent,
    },
    {
      "label": "Khác",
      "icon": Icons.more_horiz_rounded,
      "color": Colors.grey.shade600,
    },
  ];

  List<String> _getMonths() {
    List<String> months = ["Tất cả"];
    DateTime now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      DateTime m = DateTime(now.year, now.month - i, 1);
      months.add("Tháng ${m.month}/${m.year}");
    }
    return months;
  }

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTimeChips() {
    List<String> allMonths = _getMonths();
    List<String> displayMonths = _showAllMonths
        ? allMonths
        : allMonths.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: displayMonths.map((m) {
              bool isSelected = _config.time == m;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _config = _config.copyWith(time: m);
                  });
                },
                child: Container(
                  width:
                      (MediaQuery.of(context).size.width - 32 - 24) /
                      3, // 3 columns
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pink.shade50 : Colors.white,
                    border: Border.all(
                      color: isSelected ? Colors.pink : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    m,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.pink : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _showAllMonths = !_showAllMonths;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _showAllMonths ? "Thu gọn" : "Xem thêm",
                  style: const TextStyle(
                    color: Colors.pink,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  _showAllMonths
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.pink,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _accountOptions.map((acc) {
          bool isSelected = _config.account == acc;
          return GestureDetector(
            onTap: () {
              setState(() {
                _config = _config.copyWith(account: acc);
              });
            },
            child: Container(
              width: (MediaQuery.of(context).size.width - 32 - 24) / 3,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.pink.shade50 : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.pink : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Text(
                acc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.pink : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServiceGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.9,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _serviceOptions.length,
        itemBuilder: (context, index) {
          final srv = _serviceOptions[index];
          final String label = srv['label'];
          final IconData icon = srv['icon'];
          final Color color = srv['color'];
          final bool isSelected = _config.service == label;

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _config = _config.copyWith(clearService: true); // Deselect
                } else {
                  _config = _config.copyWith(service: label);
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.pink.shade50 : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.pink : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.pink : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bộ lọc Lịch sử giao dịch",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Theo thời gian"),
                    _buildTimeChips(),
                    const SizedBox(height: 8),
                    _buildSectionTitle("Theo tài khoản/thẻ"),
                    _buildAccountChips(),
                    const SizedBox(height: 8),
                    _buildSectionTitle("Theo dịch vụ"),
                    _buildServiceGrid(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Bottom Buttons
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _config = TransactionFilterConfig();
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Xóa bộ lọc",
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context, _config);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Áp dụng",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

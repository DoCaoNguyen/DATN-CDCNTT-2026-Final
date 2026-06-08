import 'package:flutter/material.dart';
import 'bank_detail_input_screen.dart';

class BankListScreen extends StatefulWidget {
  final String token;

  const BankListScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<BankListScreen> createState() => _BankListScreenState();
}

class _BankListScreenState extends State<BankListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<Map<String, dynamic>> _popularBanks = [
    {'name': 'Vietcombank', 'code': 'VCB', 'color': Colors.green, 'icon': Icons.shield},
    {'name': 'BIDV', 'code': 'BIDV', 'color': Colors.blue.shade800, 'icon': Icons.account_balance},
    {'name': 'VietinBank', 'code': 'CTG', 'color': Colors.blue.shade900, 'icon': Icons.person},
    {'name': 'Techcombank', 'code': 'TCB', 'color': Colors.red, 'icon': Icons.change_history},
    {'name': 'Agribank', 'code': 'AGR', 'color': Colors.red.shade800, 'icon': Icons.agriculture},
    {'name': 'SACOMBANK', 'code': 'STB', 'color': Colors.blue.shade700, 'icon': Icons.star},
    {'name': 'ACB', 'code': 'ACB', 'color': Colors.blue, 'icon': Icons.business},
    {'name': 'Thẻ quốc tế', 'code': 'VISA', 'color': Colors.orange, 'icon': Icons.credit_card},
  ];

  final List<Map<String, String>> _allBanks = [
    {'name': 'ABBank', 'code': 'ABB'},
    {'name': 'ACB', 'code': 'ACB'},
    {'name': 'Agribank', 'code': 'AGR'},
    {'name': 'Bắc Á Bank', 'code': 'BAB'},
    {'name': 'Bảo Việt Bank', 'code': 'BVB'},
    {'name': 'BIDV', 'code': 'BIDV'},
    {'name': 'BVBank', 'code': 'BVBANK'},
    {'name': 'Eximbank', 'code': 'EIB'},
    {'name': 'GPBank', 'code': 'GPB'},
    {'name': 'HDBank', 'code': 'HDB'},
    {'name': 'LienVietPostBank', 'code': 'LPB'},
    {'name': 'MBBank', 'code': 'MBB'},
    {'name': 'MSB', 'code': 'MSB'},
    {'name': 'Nam A Bank', 'code': 'NAB'},
    {'name': 'NCB', 'code': 'NCB'},
    {'name': 'OCB', 'code': 'OCB'},
    {'name': 'OceanBank', 'code': 'OJB'},
    {'name': 'PG Bank', 'code': 'PGB'},
    {'name': 'PVcomBank', 'code': 'PVB'},
    {'name': 'Sacombank', 'code': 'STB'},
    {'name': 'Saigonbank', 'code': 'SGB'},
    {'name': 'SCB', 'code': 'SCB'},
    {'name': 'SHB', 'code': 'SHB'},
    {'name': 'Shinhan Bank', 'code': 'SHINHAN'},
    {'name': 'Techcombank', 'code': 'TCB'},
    {'name': 'TPBank', 'code': 'TPB'},
    {'name': 'VIB', 'code': 'VIB'},
    {'name': 'VietABank', 'code': 'VAB'},
    {'name': 'VietBank', 'code': 'VIBANK'},
    {'name': 'Vietcombank', 'code': 'VCB'},
    {'name': 'VietinBank', 'code': 'CTG'},
    {'name': 'VPBank', 'code': 'VPB'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBankSelected(String bankName, String bankCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BankDetailInputScreen(
          token: widget.token,
          bankName: bankName,
          bankCode: bankCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter banks based on search query
    final filteredPopular = _popularBanks.where((bank) {
      final name = bank['name'].toString().toLowerCase();
      final code = bank['code'].toString().toLowerCase();
      return name.contains(_searchQuery) || code.contains(_searchQuery);
    }).toList();

    final filteredAll = _allBanks.where((bank) {
      final name = bank['name']!.toLowerCase();
      final code = bank['code']!.toLowerCase();
      return name.contains(_searchQuery) || code.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Liên kết ngân hàng',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm ngân hàng',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Popular Banks Grid
                  if (filteredPopular.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                      child: Text(
                        'NGÂN HÀNG PHỔ BIẾN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filteredPopular.length,
                        itemBuilder: (context, index) {
                          final bank = filteredPopular[index];
                          return GestureDetector(
                            onTap: () => _onBankSelected(bank['name'], bank['code']),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: bank['color'].withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(bank['icon'], color: bank['color'], size: 18),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    bank['name'],
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // All Banks List
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
                    child: Text(
                      'TOÀN BỘ NGÂN HÀNG',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Open Account Promo
                  if (_searchQuery.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance, color: Colors.blue, size: 20),
                        ),
                        title: const Text(
                          'Mở tài khoản ngân hàng',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Miễn phí - An toàn bảo mật',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {},
                      ),
                    ),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredAll.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF0F0F5)),
                      itemBuilder: (context, index) {
                        final bank = filteredAll[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              bank['name']!.substring(0, minOf(2, bank['name']!.length)).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            bank['name']!,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                          onTap: () => _onBankSelected(bank['name']!, bank['code']!),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int minOf(int a, int b) => a < b ? a : b;
}

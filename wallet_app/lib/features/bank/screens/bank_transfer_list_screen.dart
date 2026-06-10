import 'package:flutter/material.dart';
import 'bank_transfer_input_screen.dart';

class BankTransferListScreen extends StatefulWidget {
  final String token;
  const BankTransferListScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<BankTransferListScreen> createState() => _BankTransferListScreenState();
}

class _BankTransferListScreenState extends State<BankTransferListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Popular banks list matching Screen 1 details
  final List<Map<String, dynamic>> _popularBanks = [
    {'name': 'Vietcombank', 'code': 'VCB', 'color': const Color(0xFF1B5E20), 'iconText': 'VCB', 'logoBg': Colors.green.shade50},
    {'name': 'MBBank', 'code': 'MBB', 'color': const Color(0xFF0D47A1), 'iconText': 'MB', 'logoBg': Colors.blue.shade50},
    {'name': 'BIDV', 'code': 'BIDV', 'color': const Color(0xFF01579B), 'iconText': 'BIDV', 'logoBg': Colors.lightBlue.shade50},
    {'name': 'Techcombank', 'code': 'TCB', 'color': const Color(0xFFB71C1C), 'iconText': 'TCB', 'logoBg': Colors.red.shade50},
    {'name': 'VietinBank', 'code': 'CTG', 'color': const Color(0xFF006064), 'iconText': 'CTG', 'logoBg': Colors.cyan.shade50},
    {'name': 'ACB', 'code': 'ACB', 'color': const Color(0xFF0D47A1), 'iconText': 'ACB', 'logoBg': Colors.blue.shade100},
    {'name': 'VPBank', 'code': 'VPB', 'color': const Color(0xFF2E7D32), 'iconText': 'VPB', 'logoBg': Colors.green.shade100},
    {'name': 'SACOMBANK', 'code': 'STB', 'color': const Color(0xFF1565C0), 'iconText': 'STB', 'logoBg': Colors.indigo.shade50},
    {'name': 'OCB', 'code': 'OCB', 'color': const Color(0xFFE65100), 'iconText': 'OCB', 'logoBg': Colors.orange.shade50},
    {'name': 'TPBank', 'code': 'TPB', 'color': const Color(0xFF4A148C), 'iconText': 'TPB', 'logoBg': Colors.purple.shade50},
    {'name': 'Agribank', 'code': 'AGR', 'color': const Color(0xFF8D6E63), 'iconText': 'AGR', 'logoBg': Colors.brown.shade50},
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

  void _selectBank(String bankName, String bankCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BankTransferInputScreen(
          token: widget.token,
          bankName: bankName,
          bankCode: bankCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPopular = _popularBanks.where((b) {
      final name = b['name'].toString().toLowerCase();
      final code = b['code'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || code.contains(_searchQuery.toLowerCase());
    }).toList();

    final filteredAll = _allBanks.where((b) {
      final name = b['name']!.toLowerCase();
      final code = b['code']!.toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || code.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFECEF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chuyển tiền ngân hàng',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Paste section
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFFECEF),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Tìm ngân hàng, tài khoản người nhận',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.pink,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.content_copy, size: 14),
                  label: const Text('Dán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.pink, size: 20),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Popular Banks title
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 12),
                    child: Text(
                      'Ngân hàng phổ biến',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                  ),

                  // Popular grid
                  if (filteredPopular.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.9,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: filteredPopular.length,
                        itemBuilder: (context, index) {
                          final bank = filteredPopular[index];
                          return GestureDetector(
                            onTap: () => _selectBank(bank['name'], bank['code']),
                            child: Card(
                              color: Colors.white,
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: bank['logoBg'],
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      bank['iconText'],
                                      style: TextStyle(
                                        color: bank['color'],
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    bank['name'],
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Không tìm thấy ngân hàng phổ biến phù hợp', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),

                  // Tabs: Gần đây / Đã lưu / Mẫu chuyển tiền
                  const SizedBox(height: 16),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        _buildTabButton('Gần đây', Icons.history, true),
                        const SizedBox(width: 8),
                        _buildTabButton('Đã lưu', Icons.bookmark_border, false),
                        const SizedBox(width: 8),
                        _buildTabButton('Mẫu chuyển tiền', Icons.description_outlined, false),
                      ],
                    ),
                  ),

                  // Tab content placeholder matching mockup
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.wallet, size: 40, color: Colors.pink.shade300),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có người nhận nào gần đây',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Những người bạn đã chuyển sẽ xuất hiện ở đây để tìm lại nhanh hơn!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  // All banks list section
                  if (_searchQuery.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 16, bottom: 12),
                      child: Text(
                        'Tất cả ngân hàng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredAll.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                      itemBuilder: (context, idx) {
                        final b = filteredAll[idx];
                        return ListTile(
                          tileColor: Colors.white,
                          title: Text(b['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: Text(b['code']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () => _selectBank(b['name']!, b['code']!),
                        );
                      },
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.pink.shade50 : const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(16),
        border: isActive ? Border.all(color: Colors.pink.shade200) : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isActive ? Colors.pink : Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.pink : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

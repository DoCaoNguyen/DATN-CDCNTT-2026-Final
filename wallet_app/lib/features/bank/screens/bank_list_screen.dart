import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bank_detail_input_screen.dart';
import 'dart:convert';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';

class BankListScreen extends StatefulWidget {
  final String token;

  const BankListScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<BankListScreen> createState() => _BankListScreenState();
}

class _BankListScreenState extends State<BankListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  Set<String> _installedBankCodes = {};
  Set<String> _linkedBankCodes = {};
  final _client = CustomHttpClient();

  @override
  void initState() {
    super.initState();
    _checkInstalledBanks();
    _fetchLinkedBanks();
  }

  Future<void> _fetchLinkedBanks() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getLinkedBanks));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            final banks = data['data'] as List<dynamic>? ?? [];
            _linkedBankCodes = banks
                .map((b) => b['bank_code'].toString())
                .toSet();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching linked banks: $e");
    }
  }

  Future<void> _checkInstalledBanks() async {
    final Map<String, String> schemes = {
      'VCB': 'vietcombankmobile://',
      'TCB': 'techcombank://',
      'MB': 'mbbank://',
      'BIDV': 'bidvsmartbanking://',
      'ABB': 'abbank://',
    };

    Set<String> installed = {};
    for (var entry in schemes.entries) {
      try {
        if (await canLaunchUrl(Uri.parse(entry.value))) {
          installed.add(entry.key);
        }
      } catch (e) {
        // ignore
      }
    }
    if (mounted) {
      setState(() {
        _installedBankCodes = installed;
      });
    }
  }

  final List<Map<String, dynamic>> _popularBanks = [
    {
      'name': 'Vietcombank',
      'code': 'VCB',
      'color': Colors.green,
      'icon': Icons.shield_rounded,
    },
    {
      'name': 'BIDV',
      'code': 'BIDV',
      'color': Colors.blue.shade800,
      'icon': Icons.account_balance_rounded,
    },
    {
      'name': 'VietinBank',
      'code': 'ICB',
      'color': Colors.blue.shade900,
      'icon': Icons.person_rounded,
    },
    {
      'name': 'Techcombank',
      'code': 'TCB',
      'color': Colors.red,
      'icon': Icons.change_history_rounded,
    },
    {
      'name': 'Agribank',
      'code': 'VBA',
      'color': Colors.red.shade800,
      'icon': Icons.agriculture_rounded,
    },
    {
      'name': 'SACOMBANK',
      'code': 'STB',
      'color': Colors.blue.shade700,
      'icon': Icons.star_rounded,
    },
    {
      'name': 'ACB',
      'code': 'ACB',
      'color': Colors.blue,
      'icon': Icons.business_rounded,
    },
    {
      'name': 'Thẻ quốc tế',
      'code': 'VISA',
      'color': Colors.orange,
      'icon': Icons.credit_card_rounded,
    },
  ];

  final List<Map<String, String>> _allBanks = [
    {'name': 'ABBank', 'code': 'ABB'},
    {'name': 'ACB', 'code': 'ACB'},
    {'name': 'Agribank', 'code': 'VBA'},
    {'name': 'Bắc Á Bank', 'code': 'BAB'},
    {'name': 'Bảo Việt Bank', 'code': 'BVB'},
    {'name': 'BIDV', 'code': 'BIDV'},
    {'name': 'BVBank', 'code': 'VCCB'},
    {'name': 'Eximbank', 'code': 'EIB'},
    {'name': 'GPBank', 'code': 'GPB'},
    {'name': 'HDBank', 'code': 'HDB'},
    {'name': 'LienVietPostBank', 'code': 'LPB'},
    {'name': 'MBBank', 'code': 'MB'},
    {'name': 'MSB', 'code': 'MSB'},
    {'name': 'Nam A Bank', 'code': 'NAB'},
    {'name': 'NCB', 'code': 'NCB'},
    {'name': 'OCB', 'code': 'OCB'},
    {'name': 'PG Bank', 'code': 'PGB'},
    {'name': 'PVcomBank', 'code': 'PVCB'},
    {'name': 'Sacombank', 'code': 'STB'},
    {'name': 'Saigonbank', 'code': 'SGICB'},
    {'name': 'SCB', 'code': 'SCB'},
    {'name': 'SHB', 'code': 'SHB'},
    {'name': 'Shinhan Bank', 'code': 'SHBVN'},
    {'name': 'Techcombank', 'code': 'TCB'},
    {'name': 'TPBank', 'code': 'TPB'},
    {'name': 'VIB', 'code': 'VIB'},
    {'name': 'VietABank', 'code': 'VAB'},
    {'name': 'VietBank', 'code': 'VIETBANK'},
    {'name': 'Vietcombank', 'code': 'VCB'},
    {'name': 'VietinBank', 'code': 'ICB'},
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
    filteredPopular.sort((a, b) {
      bool aInst = _installedBankCodes.contains(a['code']);
      bool bInst = _installedBankCodes.contains(b['code']);
      if (aInst && !bInst) return -1;
      if (!aInst && bInst) return 1;
      return 0;
    });

    final filteredAll = _allBanks.where((bank) {
      final name = bank['name']!.toLowerCase();
      final code = bank['code']!.toLowerCase();
      return name.contains(_searchQuery) || code.contains(_searchQuery);
    }).toList();
    filteredAll.sort((a, b) {
      bool aInst = _installedBankCodes.contains(a['code']);
      bool bInst = _installedBankCodes.contains(b['code']);
      if (aInst && !bInst) return -1;
      if (!aInst && bInst) return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Liên kết ngân hàng',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.black87),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
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
                      padding: EdgeInsets.only(
                        left: 16.0,
                        top: 16.0,
                        bottom: 8.0,
                      ),
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 0.9,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: filteredPopular.length,
                        itemBuilder: (context, index) {
                          final bank = filteredPopular[index];
                          final isLinked = _linkedBankCodes.contains(
                            bank['code'],
                          );
                          return GestureDetector(
                            onTap: isLinked
                                ? null
                                : () => _onBankSelected(
                                    bank['name'],
                                    bank['code'],
                                  ),
                            child: Opacity(
                              opacity: isLinked ? 0.5 : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipOval(
                                      child: Image.network(
                                        'https://api.vietqr.io/img/${bank['code']}.png',
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width: 36,
                                                height: 36,
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                  Icons.account_balance_rounded,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      ),
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
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // All Banks List
                  const Padding(
                    padding: EdgeInsets.only(
                      left: 16.0,
                      top: 24.0,
                      bottom: 8.0,
                    ),
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
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 6.0,
                      ),
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
                          child: const Icon(
                            Icons.account_balance_rounded,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Mở tài khoản ngân hàng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Miễn phí - An toàn bảo mật',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                        ),
                        onTap: () {},
                      ),
                    ),

                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredAll.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Color(0xFFF0F0F5)),
                      itemBuilder: (context, index) {
                        final bank = filteredAll[index];
                        final isLinked = _linkedBankCodes.contains(
                          bank['code'],
                        );
                        return Opacity(
                          opacity: isLinked ? 0.5 : 1.0,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                'https://api.vietqr.io/img/${bank['code']}.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.pink.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      bank['name']!
                                          .substring(
                                            0,
                                            minOf(2, bank['name']!.length),
                                          )
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.pink,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            title: Text(
                              bank['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            trailing: isLinked
                                ? const Text(
                                    'Đã liên kết',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  )
                                : const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                            onTap: isLinked
                                ? null
                                : () => _onBankSelected(
                                    bank['name']!,
                                    bank['code']!,
                                  ),
                          ),
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

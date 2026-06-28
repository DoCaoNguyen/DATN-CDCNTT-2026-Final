import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';
import 'transfer_search_screen.dart'; 
import 'transfer_amount_screen.dart';
import '../../bank/screens/bank_transfer_input_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../split_bill/screens/split_bill_management_screen.dart';

class TransferMainScreen extends StatefulWidget {
  final String token; 
  final String? initialPhone; 
  final String? initialName; 
  
  const TransferMainScreen({
    Key? key, 
    required this.token,
    this.initialPhone, 
    this.initialName,  
  }) : super(key: key);

  @override
  State<TransferMainScreen> createState() => _TransferMainScreenState();
}

class _TransferMainScreenState extends State<TransferMainScreen> {
  final _client = CustomHttpClient();
  List<dynamic> _linkedBanks = [];
  bool _isLoadingBanks = true;
  List<dynamic> _recentContacts = [];

  @override
  void initState() {
    super.initState();
    _fetchLinkedBanks();
    _fetchRecentContacts();
  }

  Future<void> _fetchRecentContacts() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getChatList),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['data'] != null) {
          if (mounted) {
            setState(() {
              _recentContacts = (data['data'] as List).take(10).toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching recent contacts: $e");
    }
  }

  Future<void> _fetchLinkedBanks() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getLinkedBanks),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _linkedBanks = data['data'] ?? [];
            _isLoadingBanks = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingBanks = false);
        }
      }
    } catch (e) {
      debugPrint("Error fetching linked banks: $e");
      if (mounted) {
        setState(() => _isLoadingBanks = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9), 
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context), 
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildTransferToSection(),
                    _buildQuickTransferSection(),
                    _buildMyBankAccountSection(),
                    _buildOffersSection(),
                    _buildOtherServicesSection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. PHẦN HEADER (AppBar + Ô Tìm kiếm)
  // ==========================================
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFE4EE), // Hồng nhạt trên cùng
            Color(0xFFFFF0F5),
            Color(0xFFF5F5F9), // Chuyển dần sang xám nền
          ],
        ),
      ),
      child: Column(
        children: [
          // AppBar Custom
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); 
                }, 
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Chuyển tiền',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.support_agent_rounded, size: 18),
                    SizedBox(width: 4),
                    Text('|', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 4),
                    Icon(Icons.home_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ô Tìm kiếm
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => TransferSearchScreen(token: widget.token))
                            );
                          },
                          child: Container(
                            height: double.infinity,
                            color: Colors.transparent, 
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Nhập SĐT/STK tại đây',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      // Nút "Dán"
                      Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Row(
                            children: [
                              Icon(Icons.paste_rounded, size: 14, color: Colors.pink.shade700),
                              const SizedBox(width: 4),
                              Text('Dán', style: TextStyle(color: Colors.pink.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nút Danh bạ
              Container(
                height: 44,
                width: 44,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.contact_phone_rounded, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. PHẦN CHUYỂN TIỀN ĐẾN
  // ==========================================
  Widget _buildTransferToSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chuyển tiền đến', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.pink.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                        child: const Text('mio', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, height: 1)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Ví Mio khác', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_rounded, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('Ngân hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Danh sách ngân hàng cuộn ngang
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildBankItem('MB', 'MBBank'),
                _buildBankItem('VCB', 'Vietcombank'),
                _buildBankItem('TCB', 'Techcombank'),
                _buildBankItem('BIDV', 'BIDV'),
                _buildBankItem('ICB', 'Vietinbank'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBankItem(String bankCode, String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
              image: DecorationImage(
                image: NetworkImage('https://api.vietqr.io/img/$bankCode.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }

  // ==========================================
  // 3. PHẦN CHỌN CHUYỂN NHANH
  // ==========================================
  Widget _buildQuickTransferSection() {
    if (_recentContacts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Chọn chuyển nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          ..._recentContacts.map((contact) {
            final name = contact['counterparty_name'] ?? 'Người lạ';
            final phone = contact['counterparty_phone'] ?? '';
            final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
            return Column(
              children: [
                _buildQuickTransferUser(
                  avatarColor: Colors.purple.shade100,
                  initials: initials,
                  name: name,
                  phone: phone,
                ),
                if (_recentContacts.last != contact)
                  const Divider(height: 1, indent: 70),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickTransferUser({required Color avatarColor, required String initials, required String name, required String phone}) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColor,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                child: const Text('mio', style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.bold, height: 1)),
              ),
            ),
          )
        ],
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      trailing: const Icon(Icons.history, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransferAmountScreen(
              token: widget.token,
              receiverName: name,
              receiverPhone: phone,
            ),
          ),
        );
      },
    );
  }

  String _maskCardNumber(String? number) {
    if (number == null || number.isEmpty) return '';
    if (number.length > 4) {
      return '******${number.substring(number.length - 4)}';
    }
    return '******$number';
  }

  // ==========================================
  // 4. PHẦN TÀI KHOẢN NGÂN HÀNG CỦA TÔI
  // ==========================================
  Widget _buildMyBankAccountSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Tài khoản ngân hàng của tôi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          if (_isLoadingBanks)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: CircularProgressIndicator(color: Colors.pink),
              ),
            )
          else if (_linkedBanks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Chưa liên kết tài khoản ngân hàng nào.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _linkedBanks.length,
              itemBuilder: (context, index) {
                final bank = _linkedBanks[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BankTransferInputScreen(
                          token: widget.token,
                          bankName: bank['bank_name'] ?? 'Ngân hàng',
                          bankCode: bank['bank_code'] ?? 'BANK',
                          prefilledAccountNumber: bank['card_number'] ?? bank['account_number'],
                          cardHolderName: bank['card_holder_name'] ?? bank['account_holder_name'],
                        ),
                      ),
                    );
                  },
                  leading: Container(
                    height: 44,
                    width: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8F2FC),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0F75BD), size: 22),
                  ),
                  title: Text(
                    bank['card_holder_name'] ?? bank['account_holder_name'] ?? 'Tài khoản liên kết', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                  subtitle: Text(
                    "${bank['bank_name'] ?? 'Ngân hàng'} - ${_maskCardNumber(bank['card_number'] ?? bank['account_number'])}", 
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                );
              },
            ),
        ],
      ),
        ),
      ),
    );
  }

  // ==========================================
  // 5. PHẦN ƯU ĐÃI KHI CHUYỂN TIỀN
  // ==========================================
  Widget _buildOffersSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ưu đãi khi chuyển tiền trên Mio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right_rounded, color: Colors.pink),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildOfferCard('Chuyển tiền Mio', 'Hoàn tiền', 'Khi chuyển Mio', Icons.currency_exchange_rounded, Colors.red),
                const SizedBox(width: 12),
                _buildOfferCard('Chuyển khoản Ngân...', 'Hoàn tiền', 'Chuyển Ngân hàng', Icons.account_balance_rounded, Colors.blue),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOfferCard(String title, String highlight, String subtitle, IconData icon, Color iconColor) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 4),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(highlight, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.pink),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Khám phá', style: TextStyle(color: Colors.pink, fontSize: 11, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // ==========================================
  // 6. PHẦN DỊCH VỤ KHÁC
  // ==========================================
  Widget _buildOtherServicesSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dịch vụ khác', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOtherServiceItem(Icons.card_giftcard_rounded, Colors.pink, 'Gửi thiệp'),
              _buildOtherServiceItem(Icons.receipt_long_rounded, Colors.pinkAccent, 'Chia tiền', onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SplitBillManagementScreen(
                      token: widget.token,
                      me: const {}, // Dummy user, since it's hardcoded internally or unused there
                    ),
                  ),
                );
              }),
              _buildOtherServiceItem(Icons.notifications_active_rounded, Colors.purple, 'Nhắc trả tiền'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOtherServiceItem(IconData icon, Color color, String name, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ==========================================
  // 7. BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildBottomNavItem(Icons.currency_exchange_rounded, 'Chuyển tiền', isActive: true),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ChatListScreen(token: widget.token)),
                  );
                },
                child: _buildBottomNavItem(Icons.chat_bubble_outline_rounded, 'Chuyển qua Chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? Colors.pink : Colors.grey),
        const SizedBox(height: 4),
        Text(
          label, 
          style: TextStyle(
            fontSize: 11, 
            color: isActive ? Colors.pink : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal
          )
        ),
      ],
    );
  }
}
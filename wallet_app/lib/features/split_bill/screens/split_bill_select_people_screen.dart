import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';
import 'split_bill_input_amount_screen.dart';

class SplitBillSelectPeopleScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> transactionData;

  const SplitBillSelectPeopleScreen({
    Key? key,
    required this.token,
    required this.transactionData,
  }) : super(key: key);

  @override
  State<SplitBillSelectPeopleScreen> createState() =>
      _SplitBillSelectPeopleScreenState();
}

class _SplitBillSelectPeopleScreenState
    extends State<SplitBillSelectPeopleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, dynamic> _me = {
    'id': 'me',
    'name': 'Phan Văn Thống (Tôi)',
    'shortName': 'Tôi',
    'initials': 'VT',
    'phone': '•••••••437',
    'color': Colors.pink.shade50,
  };

  final _client = CustomHttpClient();
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  bool _isLoadingContacts = false;
  List<Map<String, dynamic>> _selectedFriends = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMyProfile();
    _syncContacts();
  }

  Future<void> _fetchMyProfile() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/users/me'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (mounted) {
          setState(() {
            String fullName = data['full_name'] ?? 'Phan Văn Thống';
            _me['name'] = '$fullName (Tôi)';
            _me['realName'] = fullName;
            _me['shortName'] = 'Tôi';
            _me['id'] = data['id'].toString();
            _me['realPhone'] = data['phone'] ?? '';

            if (data['phone'] != null && data['phone'].toString().length >= 4) {
              String p = data['phone'].toString();
              _me['phone'] = '•••••••${p.substring(p.length - 3)}';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch profile: $e');
    }
  }

  Future<void> _syncContacts() async {
    setState(() => _isLoadingContacts = true);
    try {
      final PermissionStatus permissionStatus = await Permission.contacts
          .request();
      if (permissionStatus == PermissionStatus.granted) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
        );
        final Set<String> phonesSet = {};

        for (var contact in contacts) {
          if (contact.phones.isNotEmpty) {
            for (var phone in contact.phones) {
              String num = phone.number.replaceAll(RegExp(r'[^0-9+]'), '');
              if (num.startsWith('+84')) {
                num = '0${num.substring(3)}';
              }
              if (num.startsWith('84')) {
                num = '0${num.substring(2)}';
              }
              if (num.length >= 10 && num.length <= 11) {
                phonesSet.add(num);
              }
            }
          }
        }

        if (phonesSet.isNotEmpty) {
          final response = await _client.post(
            Uri.parse('${ApiConfig.baseUrl}/users/check-contacts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phones': phonesSet.toList()}),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (mounted) {
              final List<dynamic> contactResults = data['data'] ?? [];
              setState(() {
                _friends = contactResults.map((user) {
                  String name = user['full_name'] ?? 'Chưa cập nhật tên';
                  String rawPhone = user['phone'] ?? '';
                  String maskedPhone = rawPhone;
                  if (rawPhone.length >= 4) {
                    maskedPhone =
                        '•••••••${rawPhone.substring(rawPhone.length - 3)}';
                  }

                  return {
                    'id': user['id'].toString(),
                    'name': name,
                    'shortName': name.split(' ').last,
                    'initials': name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    'phone': maskedPhone,
                    'realPhone': rawPhone,
                    'avatar': user['avatar'],
                    'color': Colors.pink.shade50,
                  };
                }).toList();
                _filteredFriends = List.from(_friends);
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error syncing contacts: $e");
    } finally {
      if (mounted) setState(() => _isLoadingContacts = false);
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredFriends = List.from(_friends);
      });
      return;
    }

    String cleanQuery = query.toLowerCase();
    setState(() {
      _filteredFriends = _friends.where((friend) {
        final name = friend['name'].toString().toLowerCase();
        final phone = friend['phone'].toString().toLowerCase();
        return name.contains(cleanQuery) || phone.contains(cleanQuery);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleSelection(Map<String, dynamic> friend) {
    setState(() {
      if (_selectedFriends.any((f) => f['id'] == friend['id'])) {
        _selectedFriends.removeWhere((f) => f['id'] == friend['id']);
      } else {
        _selectedFriends.add(friend);
      }
    });
  }

  int get _totalMembers => _selectedFriends.length + 1; // +1 for "Me"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE4E1), Color(0xFFF6F8FB)],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Chọn người",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.black54),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.headset_mic_rounded,
                  color: Colors.black54,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.home_rounded, color: Colors.black54),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: "Nhập tên, số điện thoại",
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.pink,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bạn bè không có Ví Mio?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Chia tiền với QR để nhận từ cả Ví Mio và ngân hàng",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black54),
              ],
            ),
          ),

          // Selected Members List
          if (_totalMembers > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Danh sách thành viên ($_totalMembers)",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFriends.clear();
                          });
                        },
                        child: const Text(
                          "Bỏ chọn tất cả",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSelectedMemberAvatar(_me, isMe: true),
                        ..._selectedFriends.map(
                          (f) => _buildSelectedMemberAvatar(f),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Tab Bar & Friend List
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Text(
                      "Đề xuất",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFFE91E63),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFFE91E63),
                    tabs: const [
                      Tab(text: "Người dùng"),
                      Tab(text: "Nhóm"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _isLoadingContacts
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.pink,
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredFriends.length,
                                itemBuilder: (context, index) {
                                  final friend = _filteredFriends[index];
                                  final isSelected = _selectedFriends.any(
                                    (f) => f['id'] == friend['id'],
                                  );
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: friend['color'],
                                      backgroundImage: friend['avatar'] != null
                                          ? NetworkImage(friend['avatar'])
                                          : null,
                                      child: friend['avatar'] == null
                                          ? Text(
                                              friend['initials'],
                                              style: const TextStyle(
                                                color: Color(0xFFE91E63),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      friend['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle:
                                        friend['phone'].toString().contains('*')
                                        ? Text.rich(
                                            TextSpan(
                                              children: friend['phone']
                                                  .toString()
                                                  .split('')
                                                  .map((char) {
                                                    if (char == '*') {
                                                      return WidgetSpan(
                                                        alignment:
                                                            PlaceholderAlignment
                                                                .middle,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 4.0,
                                                              ),
                                                          child: Text(
                                                            '*',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 14,
                                                                  fontFamily:
                                                                      'monospace',
                                                                  letterSpacing:
                                                                      1.2,
                                                                ),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    return TextSpan(
                                                      text: char,
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                        fontFamily: 'monospace',
                                                        letterSpacing: 1.2,
                                                      ),
                                                    );
                                                  })
                                                  .toList(),
                                            ),
                                          )
                                        : Text(
                                            friend['phone'],
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                    trailing: Checkbox(
                                      value: isSelected,
                                      activeColor: const Color(0xFFE91E63),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        _toggleSelection(friend);
                                      },
                                    ),
                                    onTap: () => _toggleSelection(friend),
                                  );
                                },
                              ),
                        const Center(
                          child: Text(
                            "Không có nhóm nào",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _totalMembers >= 2
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SplitBillInputAmountScreen(
                            token: widget.token,
                            transactionData: widget.transactionData,
                            me: _me,
                            selectedFriends: _selectedFriends,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Tiếp tục",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedMemberAvatar(
    Map<String, dynamic> member, {
    bool isMe = false,
  }) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: member['color'],
                backgroundImage: member['avatar'] != null
                    ? NetworkImage(member['avatar'])
                    : null,
                child: member['avatar'] == null
                    ? Text(
                        member['initials'],
                        style: const TextStyle(
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              if (!isMe)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      _toggleSelection(member);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            member['shortName'],
            style: const TextStyle(fontSize: 11, color: Colors.black87),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

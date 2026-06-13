import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import 'transfer_amount_screen.dart';

import 'package:flutter_contacts/flutter_contacts.dart';

class TransferSearchScreen extends StatefulWidget {
  final String token;
  const TransferSearchScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<TransferSearchScreen> createState() => _TransferSearchScreenState();
}

class _TransferSearchScreenState extends State<TransferSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<Contact> _phoneContacts = [];
  bool _isLoading = false;
  bool _isLoadingContacts = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchPhoneContacts();
  }

  Future<void> _fetchPhoneContacts() async {
    try {
      var status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status == PermissionStatus.granted || status == PermissionStatus.limited) {
        final contacts = await FlutterContacts.getAll(properties: ContactProperties.all);
        if (mounted) {
          setState(() {
            // Chỉ lấy contact có số điện thoại
            _phoneContacts = contacts.where((c) => c.phones.isNotEmpty).toList();
            _isLoadingContacts = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingContacts = false);
      }
    } catch (e) {
      debugPrint("Error fetching contacts: $e");
      if (mounted) setState(() => _isLoadingContacts = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    // Đợi 500ms sau khi người dùng ngừng gõ mới gọi API để tránh spam server
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.searchUsers}?q=$query'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = data['data'] ?? [];
        });
      }
    } catch (e) {
      print("Lỗi tìm kiếm: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF0F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            autofocus: true, 
            textAlignVertical: TextAlignVertical.center, // --- ĐÃ SỬA: Ép chữ căn giữa theo chiều dọc ---
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              isDense: true, // --- ĐÃ SỬA: Giúp TextField gọn gàng lại vừa đúng chiều cao 40 ---
              hintText: 'Tìm tên, SĐT, tài khoản...',
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              // Canh chỉnh Icon tìm kiếm
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              // Canh chỉnh Icon xóa (X)
              suffixIcon: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.grey, size: 16),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero, // --- ĐÃ SỬA: Xóa padding dọc đi để textAlignVertical tự lo việc căn giữa ---
            ),
          ),
        ),
      ),
      body: _searchController.text.isEmpty
          ? _buildEmptyState() // Hiển thị hình 1
          : _buildSearchResults(), // Hiển thị hình 2
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danh bạ điện thoại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_isLoadingContacts)
            const Center(child: CircularProgressIndicator(color: Colors.pink))
          else if (_phoneContacts.isEmpty)
            const Center(child: Text('Không có liên hệ nào hoặc chưa cấp quyền', style: TextStyle(color: Colors.grey)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _phoneContacts.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final contact = _phoneContacts[index];
                final name = contact.displayName;
                final phone = contact.phones.first.number;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.pink.shade50,
                    child: Text(
                      (name != null && name.isNotEmpty) ? name[0].toUpperCase() : 'C',
                      style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransferAmountScreen(
                          token: widget.token,
                          receiverPhone: phone,
                          receiverName: name ?? 'Chưa có tên',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text("Không tìm thấy kết quả", style: TextStyle(color: Colors.grey)));
    }

    return Container(
      color: Colors.white,
      child: ListView.separated(
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          String name = user['full_name'] ?? 'Chưa cập nhật tên';
          String phone = user['phone'] ?? '';
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.blue)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text(phone, style: const TextStyle(color: Colors.pink, fontSize: 13)),
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
        },
      ),
    );
  }
}
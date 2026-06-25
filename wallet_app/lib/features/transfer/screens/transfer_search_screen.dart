import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';
import 'transfer_amount_screen.dart';

class TransferSearchScreen extends StatefulWidget {
  final String token;
  const TransferSearchScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<TransferSearchScreen> createState() => _TransferSearchScreenState();
}

class _TransferSearchScreenState extends State<TransferSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _client = CustomHttpClient();
  List<dynamic> _searchResults = [];
  List<dynamic> _contactResults = [];
  bool _isLoading = false;
  bool _isLoadingContacts = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _syncContacts();
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
              setState(() {
                _contactResults = data['data'] ?? [];
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

    String cleanQuery = query.replaceAll(' ', '');
    final isNumeric = RegExp(r'^[0-9]+$').hasMatch(cleanQuery);

    if (isNumeric && cleanQuery.length < 10) {
      final localSuggestions = _contactResults.where((user) {
        final phone = user['phone'] as String? ?? '';
        return phone.contains(cleanQuery);
      }).toList();

      debugPrint("--- DEBUG ---");
      debugPrint("Query: $cleanQuery");
      debugPrint("isNumeric: $isNumeric");
      debugPrint("Total contacts from backend: ${_contactResults.length}");
      debugPrint("Matched suggestions: ${localSuggestions.length}");

      setState(() {
        _searchResults = localSuggestions;
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
      final response = await _client.get(
        Uri.parse('${ApiConfig.searchUsers}?q=$query'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Lỗi tìm kiếm: $e");
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
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            autofocus: true,
            textAlignVertical: TextAlignVertical
                .center, // --- ĐÃ SỬA: Ép chữ căn giữa theo chiều dọc ---
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              isDense:
                  true, // --- ĐÃ SỬA: Giúp TextField gọn gàng lại vừa đúng chiều cao 40 ---
              hintText: 'Tìm tên, SĐT, tài khoản...',
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              // Canh chỉnh Icon tìm kiếm
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.grey,
                size: 20,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              // Canh chỉnh Icon xóa (X)
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.cancel_rounded,
                  color: Colors.grey,
                  size: 16,
                ),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets
                  .zero, // --- ĐÃ SỬA: Xóa padding dọc đi để textAlignVertical tự lo việc căn giữa ---
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
          const Text(
            'Danh bạ có dùng Mio',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_isLoadingContacts)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Colors.pink),
              ),
            )
          else if (_contactResults.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Không tìm thấy ai trong danh bạ dùng Mio',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ..._contactResults.map((user) {
              String name = user['full_name'] ?? 'Chưa cập nhật tên';
              String phone = user['phone'] ?? '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.pink.shade100,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  phone,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
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
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          "Không tìm thấy kết quả",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: ListView.separated(
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          String name = user['full_name'] ?? 'Chưa cập nhật tên';
          String phone = user['phone'] ?? '';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              phone,
              style: const TextStyle(color: Colors.pink, fontSize: 13),
            ),
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

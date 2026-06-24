import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/utils/snackbar_utils.dart';

class ContactSelectorScreen extends StatefulWidget {
  final String token;
  final String redPacketId;

  const ContactSelectorScreen({
    Key? key,
    required this.token,
    required this.redPacketId,
  }) : super(key: key);

  @override
  State<ContactSelectorScreen> createState() => _ContactSelectorScreenState();
}

class _ContactSelectorScreenState extends State<ContactSelectorScreen> {
  final _client = CustomHttpClient();
  List<dynamic> _chatList = [];
  bool _isLoading = true;

  final Set<String> _selectedPhones = {};
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchChatList();
  }

  Future<void> _fetchChatList() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getChatList),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _chatList = data['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendRedPacket() async {
    if (_selectedPhones.isEmpty) {
      SnackbarUtils.showError(context, 'Vui lòng chọn ít nhất 1 người nhận');
      return;
    }

    setState(() => _isSending = true);

    // Send through SocketService
    final socketService = SocketService();
    // Connect just in case
    socketService.connectSocket(widget.token);

    for (final phone in _selectedPhones) {
      socketService.sendMessage(
        phone,
        widget.redPacketId,
        messageType: 'RED_PACKET',
      );
      // small delay to ensure events are sent properly
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() => _isSending = false);

    if (mounted) {
      SnackbarUtils.showSuccess(context, 'Gửi lì xì thành công!');
      Navigator.pop(context); // Trở về trang Home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        title: const Text(
          'Chọn người nhận',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _chatList.isEmpty
          ? const Center(
              child: Text(
                'Chưa có liên hệ nào',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatList.length,
              itemBuilder: (context, index) {
                final chat = _chatList[index];
                final name = chat['counterparty_name'] ?? 'Người lạ';
                final phone = chat['counterparty_phone'] ?? '';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                final isSelected = _selectedPhones.contains(phone);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      phone,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    trailing: Checkbox(
                      value: isSelected,
                      activeColor: const Color(0xFFE53935),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedPhones.add(phone);
                          } else {
                            _selectedPhones.remove(phone);
                          }
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedPhones.remove(phone);
                        } else {
                          _selectedPhones.add(phone);
                        }
                      });
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSending || _selectedPhones.isEmpty
                  ? null
                  : _sendRedPacket,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Gửi (${_selectedPhones.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

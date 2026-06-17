import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/services/socket_service.dart';
import '../../transfer/screens/transfer_amount_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String token;
  final String counterpartyPhone;
  final String counterpartyName;

  const ChatDetailScreen({
    Key? key,
    required this.token,
    required this.counterpartyPhone,
    required this.counterpartyName,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _client = CustomHttpClient();
  List<dynamic> _messages = [];
  bool _isLoading = true;

  final TextEditingController _chatController = TextEditingController();
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
    
    _chatController.addListener(() {
      setState(() {
        _isTyping = _chatController.text.isNotEmpty;
      });
    });

    // Init socket
    SocketService().initSocket(widget.token);
    SocketService().onReceiveMessage((data) {
      if (mounted) {
        setState(() {
          _messages.insert(0, data); // Thêm vào đầu list (do reverse: true)
        });
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    SocketService().offReceiveMessage();
    super.dispose();
  }

  Future<void> _fetchChatHistory() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getChatHistory(widget.counterpartyPhone)));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _messages = List.from(data['data'] ?? []);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching chat history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '';
    final date = DateTime.parse(isoString).toLocal();
    return DateFormat('dd MMM, HH:mm').format(date).replaceAll('MMM', 'thg ${date.month.toString().padLeft(2, '0')}');
  }

  String _formatCurrency(String amount) {
    final number = double.tryParse(amount) ?? 0;
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildAddFriendBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.pink))
                : _messages.isEmpty
                    ? const Center(child: Text("Chưa có giao dịch nào", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg);
                        },
                      ),
          ),
          _buildChatInputArea(),
          _buildBottomActionRow(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFFE4EE),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.pink.shade100,
            radius: 18,
            child: Text(
              widget.counterpartyName.isNotEmpty ? widget.counterpartyName[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.counterpartyName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const Text('Người lạ', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.grid_view_rounded, color: Colors.black87), onPressed: () {}),
        IconButton(icon: const Icon(Icons.phone_in_talk_outlined, color: Colors.black87), onPressed: () {}),
        IconButton(icon: const Icon(Icons.home_outlined, color: Colors.black87), onPressed: () {}),
      ],
    );
  }

  Widget _buildAddFriendBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Kết bạn để trò chuyện dễ dàng hơn', style: TextStyle(fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.pink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.person_add_alt_1, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Kết bạn', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg) {
    final isReceived = msg['direction'] == 'RECEIVE';
    final isText = msg['message_type'] == 'TEXT';
    final amountFormatted = _formatCurrency(msg['amount'].toString());
    final dateFormatted = _formatDateTime(msg['created_at']);
    final timeOnly = msg['created_at'] != null ? DateFormat('HH:mm').format(DateTime.parse(msg['created_at']).toLocal()) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isReceived ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(dateFormatted, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ),
          Row(
            mainAxisAlignment: isReceived ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: isText ? CrossAxisAlignment.center : CrossAxisAlignment.end,
            children: [
              if (isReceived)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(widget.counterpartyName.isNotEmpty ? widget.counterpartyName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              if (isReceived) const SizedBox(width: 8),
              
              if (isText) 
                // Bong bóng chữ thuần túy
                Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isReceived ? Colors.white : Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isReceived ? Colors.grey.shade300 : Colors.pink.shade100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(child: Text(msg['note'] ?? '', style: const TextStyle(fontSize: 15, color: Colors.black87))),
                      const SizedBox(width: 8),
                      Text(timeOnly, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                )
              else 
                // Bong bóng giao dịch tiền
                Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isReceived ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5), // Xanh lá nhạt nếu nhận, xám nếu chuyển
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isReceived ? Colors.green.shade200 : Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(isReceived ? Icons.arrow_downward : Icons.arrow_upward, color: isReceived ? Colors.green : Colors.grey, size: 14),
                              const SizedBox(width: 4),
                              Text(isReceived ? 'Đã nhận' : 'Đã chuyển', style: TextStyle(color: isReceived ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          Text(timeOnly, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(amountFormatted, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(isReceived ? 'Nhận tiền qua Mio' : 'Chuyển tiền qua Mio', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      if (msg['note'] != null && msg['note'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('"${msg['note']}"', style: const TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                  Icon(Icons.emoji_emotions_outlined, color: Colors.grey.shade600, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_isTyping)
            GestureDetector(
              onTap: () {
                if (_chatController.text.trim().isNotEmpty) {
                  SocketService().sendMessage(widget.counterpartyPhone, _chatController.text.trim());
                  _chatController.clear();
                }
              },
              child: const Icon(Icons.send, color: Colors.pink),
            )
          else
            Icon(Icons.image_outlined, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildBottomActionRow(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransferAmountScreen(
                      token: widget.token,
                      receiverName: widget.counterpartyName,
                      receiverPhone: widget.counterpartyPhone,
                    ),
                  ),
                ).then((_) => _fetchChatHistory()); // Cập nhật lại list sau khi chuyển tiền
              },
              child: _buildActionBtn(Icons.currency_exchange, 'Chuyển tiền', Colors.red),
            ),
            _buildActionBtn(Icons.chat_bubble_outline, 'Nhắc trả tiền', Colors.pink),
            _buildActionBtn(Icons.card_giftcard, 'Gửi thiệp', Colors.pinkAccent),
            _buildActionBtn(Icons.money, 'Giật lì xì', Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }
}

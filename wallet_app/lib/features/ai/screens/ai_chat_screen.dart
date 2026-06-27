import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';

class AiChatScreen extends StatefulWidget {
  final String token;

  const AiChatScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  int _mioBalance = 0;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    // Add initial greeting
    _messages.add(
      ChatMessage(
        text:
            "Chào bạn! Mình là Trợ lý Mio 247. Mình có thể giúp gì cho bạn hôm nay?",
        isUser: false,
      ),
    );
  }

  Future<void> _fetchBalance() async {
    try {
      final client = CustomHttpClient();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/wallet/me'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['data'] != null) {
          if (mounted) {
            setState(() {
              _mioBalance = int.parse(data['data']['balance'].toString());
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching balance: $e");
    }
  }

  int _parseAmount(String amountStr) {
    String cleanStr = amountStr.toLowerCase().replaceAll(',', '').replaceAll('.', '');
    int multiplier = 1;
    if (cleanStr.endsWith('k')) {
      multiplier = 1000;
      cleanStr = cleanStr.replaceAll('k', '');
    }
    return (int.tryParse(cleanStr) ?? 0) * multiplier;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Kiểm tra nhanh local ý định nạp/rút/chuyển tiền
    final transferMatch = RegExp(r'^(chuyển|ck)\s+([\d\.\,kK]+)', caseSensitive: false).firstMatch(text);
    final depositMatch = RegExp(r'^nạp\s+([\d\.\,kK]+)', caseSensitive: false).firstMatch(text);
    final withdrawMatch = RegExp(r'^rút\s+([\d\.\,kK]+)', caseSensitive: false).firstMatch(text);

    int? amount;
    String? intent;

    if (transferMatch != null) {
      amount = _parseAmount(transferMatch.group(2)!);
      intent = 'TRANSFER';
    } else if (depositMatch != null) {
      amount = _parseAmount(depositMatch.group(1)!);
      intent = 'DEPOSIT';
    } else if (withdrawMatch != null) {
      amount = _parseAmount(withdrawMatch.group(1)!);
      intent = 'WITHDRAW';
    }

    if (amount != null && intent != null) {
      if (intent == 'TRANSFER') {
        if (amount < 1000) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số tiền chuyển tối thiểu là 1.000đ'), backgroundColor: Colors.red));
          return;
        }
        if (amount > 50000000) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hạn mức chuyển tiền tối đa là 50.000.000đ/ngày'), backgroundColor: Colors.red));
          return;
        }
        if (amount > _mioBalance) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số dư không đủ để thực hiện giao dịch này'), backgroundColor: Colors.red));
          return;
        }
      } else {
        // Nạp / Rút
        if (amount < 10000) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Số tiền ${intent == 'DEPOSIT' ? 'nạp' : 'rút'} tối thiểu là 10.000đ'), backgroundColor: Colors.red));
          return;
        }
        if (amount > 50000000) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Số tiền ${intent == 'DEPOSIT' ? 'nạp' : 'rút'} vượt quá hạn mức 50.000.000đ/ngày'), backgroundColor: Colors.red));
          return;
        }
        if (intent == 'WITHDRAW' && amount > _mioBalance) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số dư không đủ để thực hiện giao dịch này'), backgroundColor: Colors.red));
          return;
        }
      }
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final client = CustomHttpClient();
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/ai/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${widget.token}', // CustomHttpClient will also inject latest token automatically
        },
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(ChatMessage(text: data['data'], isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  "Xin lỗi, hiện tại tôi không thể kết nối. Vui lòng thử lại sau.",
              isUser: false,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Lỗi kết nối mạng.", isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4EE),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.pink.shade400,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Trợ thủ AI - Mio247",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, 
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Trung tâm trợ giúp",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.home_rounded, color: Colors.black87, size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.pink),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.pink : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: msg.isUser
                ? const Radius.circular(0)
                : const Radius.circular(16),
            bottomLeft: msg.isUser
                ? const Radius.circular(16)
                : const Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.more_horiz,
                color: Colors.pinkAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Nhập nội dung...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _sendMessage,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.grey,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

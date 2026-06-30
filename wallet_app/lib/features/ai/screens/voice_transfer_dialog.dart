import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';

class VoiceTransferDialog extends StatefulWidget {
  final String token;

  const VoiceTransferDialog({Key? key, required this.token}) : super(key: key);

  @override
  State<VoiceTransferDialog> createState() => _VoiceTransferDialogState();
}

class _VoiceTransferDialogState extends State<VoiceTransferDialog> {
  final TextEditingController _textController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _processText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung cần chuyển tiền.'),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final client = CustomHttpClient();
      var response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/ai/extract-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) Navigator.pop(context, data['data']);
      } else {
        String errorMsg = 'AI không thể phân tích nội dung.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMsg = errorData['error'];
          }
        } catch (_) {}
        if (mounted) Navigator.pop(context, {'error': errorMsg});
      }
    } catch (e) {
      if (mounted) Navigator.pop(context, {'error': 'Lỗi kết nối máy chủ AI.'});
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Chuyển tiền bằng giọng nói",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Nhấn vào mic trên bàn phím để đọc lệnh.\nVí dụ: \"Chuyển 50 ngàn cho mẹ\" hoặc \"Nạp 100k vào ví\"",
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            autofocus: true,
            maxLines: null,
            decoration: InputDecoration(
              hintText: "Đang nghe...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: _isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.pink,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.pink),
                      onPressed: _processText,
                    ),
            ),
            onSubmitted: (_) => _processText(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

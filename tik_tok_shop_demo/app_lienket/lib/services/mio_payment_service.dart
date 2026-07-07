import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class MioPaymentService {
  // Demo API Key. In production, this would be a real key registered via merchant portal
  static String merchantApiKey = 'mio_test_key_12345'; // Giả lập key, có thể thay đổi trong Cài đặt
  static String apiSecret = ''; // Dành cho các request cần verify
  
  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    merchantApiKey = prefs.getString('api_key') ?? 'mio_test_key_12345';
    apiSecret = prefs.getString('api_secret') ?? '';
  }
  static const String baseUrl = ApiConfig.mioApiUrl;

  /// Returns the deep link URI string (e.g., mio://pay?token=...)
  static Future<String?> createOrder({
    required double amount,
    required String description,
    required String merchantOrderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/create'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': merchantApiKey, // Lưu ý: Để chạy thực tế cần insert 1 API Key này vào DB bảng merchant_api_keys
        },
        body: jsonEncode({
          'amount': amount.toStringAsFixed(0),
          'description': description,
          'merchant_order_id': merchantOrderId,
          'callback_url': 'https://example.com/webhook',
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        return data['qrCode']; // Đây là chuỗi mio://pay?token=...
      } else {
        print('Error creating order: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      return null;
    }
  }
}

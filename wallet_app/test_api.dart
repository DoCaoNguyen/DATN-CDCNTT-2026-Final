import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http.post(
      Uri.parse('https://batboy-buffalo-backspin.ngrok-free.dev/api/v1/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': '0987654321@wallet.com', 
        'phone': '0987654321'
      }),
    );
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
  } catch (e) {
    print('Lỗi: $e');
  }
}

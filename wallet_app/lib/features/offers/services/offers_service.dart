import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';

class OffersService {
  final String token;

  OffersService({required this.token});

  Future<Map<String, dynamic>> redeemScratchCard(String provider, int faceValue) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payment/loyalty/redeem'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'provider': provider,
          'faceValue': faceValue,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData['data'];
      } else {
        throw Exception(responseData['error'] ?? 'Lỗi không xác định khi đổi thẻ');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

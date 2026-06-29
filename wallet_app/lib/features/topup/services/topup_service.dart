import 'dart:convert';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';

class TopupService {
  final String token;

  TopupService({required this.token});

  Future<Map<String, dynamic>> processTopup({
    required String type,
    String? provider,
    String? phone,
    required int amount,
    String? dataPackageId,
  }) async {
    final client = CustomHttpClient();
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}/payment/topup'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': type,
        'provider': provider,
        'phone': phone,
        'amount': amount,
        'dataPackageId': dataPackageId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception(data['error'] ?? 'Giao dịch thất bại');
    }
  }
}

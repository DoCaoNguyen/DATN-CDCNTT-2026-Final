import 'dart:convert';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';

class WealthBagService {
  final CustomHttpClient _client = CustomHttpClient();

  Future<Map<String, dynamic>?> getStatus(String token) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.wealthBagStatus),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print("Error fetching wealth bag status: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> activate(String token) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.wealthBagActivate),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print("Error activating wealth bag: $e");
      return null;
    }
  }
}

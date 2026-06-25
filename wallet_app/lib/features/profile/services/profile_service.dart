import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';

class ProfileService {
  final CustomHttpClient _client = CustomHttpClient();

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getMyProfile));
      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        return jsonResp['data'];
      }
    } catch (e) {
      debugPrint('Lỗi lấy thông tin profile: $e');
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _client.post(Uri.parse(ApiConfig.logout));
    } catch (e) {
      debugPrint('Lỗi gọi API logout: $e');
    }
  }
}

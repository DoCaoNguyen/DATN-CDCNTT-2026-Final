import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';

class HomeService {
  final CustomHttpClient _client = CustomHttpClient();

  Future<Map<String, dynamic>?> fetchBalance(String token) async {
    if (token.isEmpty) return null;
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getWalletBalance),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      }
    } catch (e) {
      debugPrint("Lỗi lấy số dư ví: $e");
    }
    return null;
  }

  Future<int> fetchUnreadCount(String token) async {
    if (token.isEmpty) return 0;
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getUnreadNotificationCount),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['unreadCount'] ?? 0;
        }
      }
    } catch (e) {
      debugPrint("Fetch unread count error: $e");
    }
    return 0;
  }

  Future<Map<String, dynamic>?> fetchProfile(String token) async {
    if (token.isEmpty) return null;
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getMyProfile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null || data['success'] == true) {
          final profileData = data['data'] ?? data;
          bool isKycVerified = profileData['is_kyc_verified'] == true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_verified', isKycVerified);
          return profileData;
        }
      }
    } catch (e) {
      debugPrint("Fetch profile error: $e");
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchUsersByVoice(String name) async {
    List<Map<String, dynamic>> matchedUsers = [];
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.searchUsers}?q=$name'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List users = data['data'] ?? [];
        for (var u in users) {
          matchedUsers.add({
            'name': u['full_name'] ?? 'Không tên',
            'phone': u['phone'] ?? '',
            'source': 'Mio App',
          });
        }
      }
    } catch (e) {
      debugPrint("Voice Transfer search API error: $e");
    }
    return matchedUsers;
  }
}

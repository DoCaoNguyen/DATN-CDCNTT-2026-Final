import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';

class LoyaltyService {
  Future<Map<String, dynamic>> getLoyaltySummary(String token) async {
    try {
      final client = CustomHttpClient();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/loyalty/summary'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return {};
    } catch (e) {
      debugPrint("Error fetching loyalty summary: $e");
      return {};
    }
  }

  Future<List<dynamic>> getLoyaltyHistory(
    String token,
    String tab,
    int page,
  ) async {
    try {
      final client = CustomHttpClient();
      final response = await client.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/loyalty/history?tab=$tab&page=$page&limit=20',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching loyalty history: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getCheckinStatus(String token) async {
    try {
      final client = CustomHttpClient();
      final response = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/loyalty/checkin-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return {'currentStreak': 0, 'checkedInToday': false};
    } catch (e) {
      debugPrint("Error fetching checkin status: $e");
      return {'currentStreak': 0, 'checkedInToday': false};
    }
  }

  Future<Map<String, dynamic>> checkin(String token) async {
    try {
      final client = CustomHttpClient();
      final response = await client.post(
        Uri.parse('${ApiConfig.baseUrl}/loyalty/checkin'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } catch (e) {
      debugPrint("Error checking in: $e");
      return {'success': false, 'message': 'Lỗi kết nối'};
    }
  }
}

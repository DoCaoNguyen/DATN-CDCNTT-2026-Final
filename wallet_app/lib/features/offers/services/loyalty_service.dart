import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import 'package:flutter/foundation.dart';

class LoyaltyService {
  Future<Map<String, dynamic>> getLoyaltySummary(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/loyalty/summary'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
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
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/loyalty/history?tab=$tab&page=$page&limit=20',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/loyalty/checkin-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/loyalty/checkin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
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

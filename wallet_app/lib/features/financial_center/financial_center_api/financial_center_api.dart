import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';

class FinancialCenterApi {
  static final _client = CustomHttpClient();

  static Future<List<dynamic>?> fetchLinkedBanks(String token) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getLinkedBanks),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetches linked banks and sorts them based on saved SharedPreferences order.
  /// Also returns the enabled status for each bank if needed.
  static Future<List<Map<String, dynamic>>> getSortedLinkedBanks(String token) async {
    final banks = await fetchLinkedBanks(token);
    if (banks == null) return [];

    List<Map<String, dynamic>> methods = [];
    for (var i = 0; i < banks.length; i++) {
      final bank = banks[i];
      methods.add({
        'id': bank['id']?.toString() ?? bank['bank_code']?.toString() ?? 'bank_$i',
        'name': bank['bank_name'] ?? 'Ngân hàng',
        'original_data': bank, // keep original API data if needed
        'isEnabled': true,
        'isFixed': false,
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final String key = 'payment_order_prefs_$token';
    final String? savedStr = prefs.getString(key);

    if (savedStr != null) {
      try {
        final List<dynamic> savedData = jsonDecode(savedStr);
        List<Map<String, dynamic>> orderedMethods = [];
        for (var saved in savedData) {
          final String savedId = saved['id'];
          final bool savedEnabled = saved['isEnabled'] ?? true;
          final index = methods.indexWhere((m) => m['id'] == savedId);
          if (index != -1) {
            var method = methods.removeAt(index);
            method['isEnabled'] = savedEnabled;
            orderedMethods.add(method);
          }
        }
        orderedMethods.addAll(methods);
        methods = orderedMethods;
      } catch (e) {
        // Fallback to original order
      }
    }
    return methods;
  }
}

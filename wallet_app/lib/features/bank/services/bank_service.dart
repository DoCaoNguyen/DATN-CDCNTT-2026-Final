import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';

class BankService {
  final CustomHttpClient _client = CustomHttpClient();

  Future<String?> fetchMioBalance() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getWalletBalance));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['available_balance']?.toString();
      }
    } catch (e) {
      debugPrint("Error fetching Mio balance: $e");
    }
    return null;
  }

  Future<List<dynamic>?> fetchLinkedBanks() async {
    try {
      final response = await _client.get(Uri.parse(ApiConfig.getLinkedBanks));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching linked banks: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>> executeTransactionWithFace({
    required String token,
    required File selfieFile,
    required bool isDeposit,
    required int amount,
    required String externalReference,
    String? linkedBankId,
  }) async {
    try {
      final url = isDeposit ? ApiConfig.deposit : ApiConfig.withdraw;
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['amount'] = amount.toString();
      request.fields['external_reference'] = externalReference;

      if (!isDeposit && linkedBankId != null) {
        request.fields['linked_bank_id'] = linkedBankId;
      }

      request.files.add(
        await http.MultipartFile.fromPath('face_image', selfieFile.path),
      );

      var responseStream = await request.send();
      var response = await http.Response.fromStream(responseStream);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? "Giao dịch thất bại.",
        };
      }
    } catch (e) {
      return {'success': false, 'error': "Lỗi kết nối máy chủ."};
    }
  }
}

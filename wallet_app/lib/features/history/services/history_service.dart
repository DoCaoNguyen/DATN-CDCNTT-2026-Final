import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/constants/api_config.dart';

class HistoryService {
  final CustomHttpClient _client = CustomHttpClient();

  Future<Map<String, dynamic>?> fetchTransactionStats() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getTransactionStats),
      );
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          return resData['data'];
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy thống kê: $e");
    }
    return null;
  }

  Future<List<dynamic>?> fetchTransactions(
    int page,
    String timeFilter,
    String? serviceFilter,
  ) async {
    String url = "${ApiConfig.getTransactionHistory}?page=$page&limit=20";

    // Convert time -> startDate, endDate
    if (timeFilter != "Tất cả") {
      final timeStr = timeFilter.replaceAll("Tháng ", "");
      final parts = timeStr.split("/");
      if (parts.length == 2) {
        final month = int.tryParse(parts[0]) ?? 1;
        final year = int.tryParse(parts[1]) ?? 2026;
        final startStr = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(year, month, 1));
        final endStr = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(year, month + 1, 0));
        url += "&startDate=$startStr&endDate=$endStr";
      }
    }

    // Convert service -> type
    if (serviceFilter != null) {
      String? type;
      if (serviceFilter == "Nạp tiền")
        type = "DEPOSIT";
      else if (serviceFilter == "Rút tiền")
        type = "WITHDRAW";
      else if (serviceFilter == "Nhận tiền" || serviceFilter == "Chuyển tiền")
        type = "TRANSFER";
      else if ([
        "Chi tiêu sinh hoạt",
        "Hóa đơn & Tiện ích",
        "Giải trí & Mua sắm",
        "Chi phí phát sinh",
      ].contains(serviceFilter))
        type = "PAYMENT";

      if (type != null) {
        url += "&type=$type";
      }
    }

    try {
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['success'] == true && resData['data'] != null) {
          return resData['data'];
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy lịch sử: $e");
    }
    return null;
  }
}

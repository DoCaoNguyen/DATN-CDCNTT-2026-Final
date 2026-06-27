import 'package:flutter/material.dart';

class TransactionCategoryHelper {
  static String determineCategoryTag(dynamic tx) {
    if (tx['category_name'] != null &&
        tx['category_name'].toString().isNotEmpty) {
      return tx['category_name'].toString();
    }
    final note = (tx['transfer_note'] ?? tx['description'] ?? '')
        .toString()
        .toLowerCase();
    if (tx['transaction_type'] == 'DEPOSIT') {
      return "Nạp tiền";
    }
    if (tx['transaction_type'] == 'LOYALTY_REDEEM') {
      return "Đổi thưởng";
    }
    if (note.contains('ăn') ||
        note.contains('uống') ||
        note.contains('lẩu') ||
        note.contains('cafe') ||
        note.contains('cơm') ||
        note.contains('bánh')) {
      return "Ăn uống";
    }
    if (note.contains('chơi') ||
        note.contains('game') ||
        note.contains('nhạc') ||
        note.contains('phim') ||
        note.contains('giải trí') ||
        note.contains('netflix')) {
      return "Giải trí";
    }
    if (note.contains('chợ') ||
        note.contains('siêu thị') ||
        note.contains('mua sắm') ||
        note.contains('quần áo') ||
        note.contains('shopee')) {
      return "Chợ, siêu thị";
    }
    if (note.contains('điện') ||
        note.contains('nước') ||
        note.contains('internet') ||
        note.contains('mạng') ||
        note.contains('tiền nhà') ||
        note.contains('học phí') ||
        note.contains('hoá đơn')) {
      return "Hóa đơn";
    }
    return "Chưa phân loại";
  }

  static Color getTagColor(String tag) {
    if (tag == "Nạp tiền") return Colors.blue.shade600;
    if (["Chợ, siêu thị", "Ăn uống", "Di chuyển"].contains(tag)) {
      return Colors.orange.shade700;
    }
    if ([
      "Mua sắm",
      "Giải trí",
      "Làm đẹp",
      "Sức khỏe",
      "Từ thiện",
      "Đổi thưởng",
    ].contains(tag)) {
      return Colors.pink.shade600;
    }
    if (["Hóa đơn", "Nhà cửa", "Người thân"].contains(tag)) {
      return Colors.blue.shade600;
    }
    if (["Đầu tư", "Học tập"].contains(tag)) {
      return Colors.teal.shade600;
    }
    switch (tag) {
      case "Ăn uống":
        return Colors.orange.shade700;
      case "Giải trí":
        return Colors.pink.shade600;
      case "Hóa đơn":
        return Colors.teal.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  static Color getTagBgColor(String tag) {
    if (tag == "Nạp tiền") return Colors.blue.shade50;
    if (["Chợ, siêu thị", "Ăn uống", "Di chuyển"].contains(tag)) {
      return Colors.orange.shade50;
    }
    if ([
      "Mua sắm",
      "Giải trí",
      "Làm đẹp",
      "Sức khỏe",
      "Từ thiện",
      "Đổi thưởng",
    ].contains(tag)) {
      return Colors.pink.shade50;
    }
    if (["Hóa đơn", "Nhà cửa", "Người thân"].contains(tag)) {
      return Colors.blue.shade50;
    }
    if (["Đầu tư", "Học tập"].contains(tag)) {
      return Colors.teal.shade50;
    }
    switch (tag) {
      case "Ăn uống":
        return Colors.orange.shade50;
      case "Giải trí":
        return Colors.pink.shade50;
      case "Hóa đơn":
        return Colors.teal.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  static IconData getTransactionIcon(dynamic tx) {
    if (tx['transaction_type'] == 'DEPOSIT') {
      return Icons.account_balance_wallet_rounded;
    }
    if (tx['transaction_type'] == 'LOYALTY_REDEEM') {
      return Icons.card_giftcard_rounded;
    }
    if (tx['entry_type'] == 'CREDIT') {
      return Icons.call_received_rounded;
    }
    return Icons.send_rounded;
  }

  static Color getIconColor(dynamic tx) {
    if (tx['transaction_type'] == 'DEPOSIT') {
      return Colors.blue;
    }
    if (tx['transaction_type'] == 'LOYALTY_REDEEM') {
      return Colors.pink;
    }
    if (tx['entry_type'] == 'CREDIT') {
      return Colors.green;
    }
    return Colors.pink;
  }
}

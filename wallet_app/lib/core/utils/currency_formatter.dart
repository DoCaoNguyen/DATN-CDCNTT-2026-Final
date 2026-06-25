class CurrencyFormatter {
  static String format(dynamic amountVal) {
    try {
      // Bỏ qua các ký tự không phải số nếu cần (tuỳ chọn)
      // Hiện tại giữ nguyên logic cũ
      final value = int.parse(amountVal.toString());
      return "${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
    } catch (e) {
      return "0đ";
    }
  }
}

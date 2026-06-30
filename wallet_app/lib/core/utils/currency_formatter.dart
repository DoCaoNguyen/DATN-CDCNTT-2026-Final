class CurrencyFormatter {
  static String format(dynamic amountVal) {
    try {
      final value = double.parse(amountVal.toString()).toInt();
      return "${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
    } catch (e) {
      return "0đ";
    }
  }
}

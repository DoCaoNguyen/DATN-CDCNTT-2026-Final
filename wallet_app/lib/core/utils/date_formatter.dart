class DateFormatter {
  static String format(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      return "$hour:$minute - $day/$month/$year";
    } catch (e) {
      return dateStr;
    }
  }
}

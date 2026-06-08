class ApiConfig {
  // --- BASE URL ---
  // Dùng 10.0.2.2 cho máy ảo Android
  // Dùng IP WiFi (VD: 192.168.1.x) nếu chạy trên máy thật
  static const String baseUrl = 'https://orectic-noctilucent-ronan.ngrok-free.dev/api/v1';

  static String get socketUrl {
    final uri = Uri.parse(baseUrl);
    return "${uri.scheme}://${uri.host}";
  }

  // --- AUTH ENDPOINTS ---
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String setPassword = '$baseUrl/auth/set-password';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String verifyKyc = '$baseUrl/kyc/verify';
  static const String getWalletBalance = '$baseUrl/wallet/balance';
  static const String searchUsers = '$baseUrl/users/search';
  static const String transfer = '$baseUrl/transaction/transfer';
  static const String setWalletCode = '$baseUrl/wallet/set-code';
  static const String getMyProfile = '$baseUrl/users/me';
  static const String getTransactionHistory = '$baseUrl/transaction/history';
  static const String requestMoneyQR = '$baseUrl/payment/request';
  static const String processPayment = '$baseUrl/payment/process';
  static const String getLinkedBanks = '$baseUrl/wallet/linked-banks';
  static const String linkBank = '$baseUrl/wallet/link-bank';
  static const String deposit = '$baseUrl/transaction/deposit';
  static const String withdraw = '$baseUrl/transaction/withdraw';
}
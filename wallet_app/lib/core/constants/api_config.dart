class ApiConfig {
  // --- BASE URL ---
  // Dùng 10.0.2.2 cho máy ảo Android
  // Dùng IP WiFi (VD: 192.168.1.x) nếu chạy trên máy thật
  static const String baseUrl =
      'https://orectic-noctilucent-ronan.ngrok-free.dev/api/v1';

  static String get socketUrl {
    final uri = Uri.parse(baseUrl);
    final portStr = uri.hasPort ? ":${uri.port}" : "";
    return "${uri.scheme}://${uri.host}$portStr";
  }

  // --- AUTH ENDPOINTS ---
  static const String checkPhone = '$baseUrl/auth/check-phone';
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String setPassword = '$baseUrl/auth/set-password';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String refreshToken = '$baseUrl/auth/refresh-token';
  static const String forgotPasswordOtp = '$baseUrl/auth/forgot-password-otp';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String exportTransaction = '$baseUrl/transaction/export';

  // --- KYC ENDPOINTS ---
  static const String verifyKyc = '$baseUrl/kyc/verify';
  static const String getWalletBalance = '$baseUrl/wallet/balance';
  static const String getWalletLimits = '$baseUrl/wallet/limits';
  static const String searchUsers = '$baseUrl/users/search';
  static const String transfer = '$baseUrl/transaction/transfer';
  static const String setWalletCode = '$baseUrl/wallet/set-code';
  static const String getMyProfile = '$baseUrl/users/me';
  static const String getTransactionHistory = '$baseUrl/transaction/history';
  static const String getTransactionStats = '$baseUrl/transaction/stats';
  static const String getTransactionsByMonth = '$baseUrl/transaction/month';
  static const String getChatList = '$baseUrl/transaction/chat-list';
  static String getChatHistory(String phone) =>
      '$baseUrl/transaction/chat/$phone';
  static const String requestMoneyQR = '$baseUrl/payment/request';
  static const String paymentPreview = '$baseUrl/payment/preview';
  static const String processPayment = '$baseUrl/payment/process';
  static const String getLinkedBanks = '$baseUrl/wallet/linked-banks';
  static const String linkBank = '$baseUrl/wallet/link-bank';
  static const String verifyPin = '$baseUrl/wallet/verify-pin';
  static const String deposit = '$baseUrl/transaction/deposit';
  static const String withdraw = '$baseUrl/transaction/withdraw';
  static const String bankTransfer = '$baseUrl/transaction/bank-transfer';
  static const String registerDevice = '$baseUrl/notifications/register-device';
  static const String getNotifications = '$baseUrl/notifications';
  static const String getUnreadNotificationCount =
      '$baseUrl/notifications/unread-count';
  static const String markNotificationRead = '$baseUrl/notifications/read';
  static const String markAllNotificationsRead =
      '$baseUrl/notifications/read-all';

  // --- RED PACKET ENDPOINTS ---
  static const String createRedPacket = '$baseUrl/red-packet/create';
  static String getRedPacketDetails(String id) => '$baseUrl/red-packet/$id';
  static String claimRedPacket(String id) => '$baseUrl/red-packet/$id/claim';
}

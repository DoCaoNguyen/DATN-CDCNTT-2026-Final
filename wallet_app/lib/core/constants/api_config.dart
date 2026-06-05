class ApiConfig {
  // --- BASE URL ---
  // Dùng 10.0.2.2 cho máy ảo Android
  // Dùng IP WiFi (VD: 192.168.1.x) nếu chạy trên máy thật
  static const String baseUrl = 'https://orectic-noctilucent-ronan.ngrok-free.dev/api/v1';

  // --- AUTH ENDPOINTS ---
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String setPassword = '$baseUrl/auth/set-password';
  static const String login = '$baseUrl/auth/login';
  static const String verifyKyc = '$baseUrl/kyc/verify';
  static const String getWalletBalance = '$baseUrl/wallet/balance';
  static const String searchUsers = '$baseUrl/users/search';
  static const String transfer = '$baseUrl/transaction/transfer';
  
}
class ApiConfig {
  static const String baseUrl = 'https://batboy-buffalo-backspin.ngrok-free.dev/api/v1';

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
}

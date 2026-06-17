import 'dart:convert';
import 'package:flutter/material.dart';

import '../../auth/kyc/sceens/kyc_flow_screen.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/constants/api_config.dart';
import '../widgets/set_wallet_code_dialog.dart';
import '../widgets/wallet_card.dart';
import '../widgets/services_grid.dart';
import 'qr_main_screen.dart';
import 'notification_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../history/screens/transaction_history_screen.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/custom_http_client.dart';
import '../../bank/screens/bank_link_screen.dart';
import '../../bank/screens/deposit_withdraw_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_android/local_auth_android.dart';
import '../../transfer/screens/transfer_confirm_screen.dart';
import '../../../core/utils/snackbar_utils.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final bool isVerified;
  final String token;

  const HomeScreen({
    Key? key,
    this.userId = '',
    this.isVerified = true,
    this.token = '',
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _balance = "0";
  String? _walletCode;
  bool _isPinSet = false;
  bool _isLoadingBalance = true;
  int _unreadCount = 0;

  SocketService? _socketService;
  final _client = CustomHttpClient();

  @override
  void initState() {
    super.initState();

    if (!widget.isVerified && widget.userId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showKycDialog();
      });
    }

    _fetchBalance();
    _fetchUnreadCount();
    _initSocket();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSetupBiometric();
    });
  }

  @override
  void dispose() {
    _socketService?.disconnect();
    super.dispose();
  }

  void _initSocket() {
    if (widget.token.isNotEmpty) {
      // Đăng ký FCM Token thiết bị lên Backend
      NotificationService.instance.registerUserToken(widget.token);

      _socketService = SocketService(
        token: widget.token,
        onBalanceUpdate: (data) {
          if (mounted) {
            setState(() {
              _balance = data['newBalance']?.toString() ?? _balance;
            });
            _showBalanceUpdateNotification(data);
          }
        },
      );
      _socketService!.connect();
    }
  }

  Future<void> _checkAndSetupBiometric() async {
    const storage = FlutterSecureStorage();
    final hasSetup = await storage.read(key: "hasSetupBiometric");
    if (hasSetup == "true") return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: Colors.pink, size: 28),
            SizedBox(width: 8),
            Text(
              "Thiết lập Vân tay/FaceID",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          "Bạn có muốn thiết lập đăng nhập bằng Vân tay/FaceID để bảo mật và giao dịch nhanh chóng hơn không?",
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Để sau",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _promptPinForBiometric();
            },
            child: const Text(
              "Đồng ý",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _promptPinForBiometric() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        autoTriggerBiometric: false,
        onPinEntered: (pin) async {
          try {
            final response = await _client.post(
              Uri.parse(ApiConfig.verifyPin),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'pin': pin}),
            );

            if (response.statusCode == 200) {
              Navigator.pop(context); // Close PIN sheet
              await _authenticateBiometric(pin);
              return null;
            } else {
              final data = jsonDecode(response.body);
              return data['error'] ?? "Mã PIN không chính xác";
            }
          } catch (e) {
            return "Lỗi kết nối máy chủ";
          }
        },
      ),
    );
  }

  Future<void> _authenticateBiometric(String pinCode) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        _showErrorSnackBar("Thiết bị không hỗ trợ xác thực sinh trắc học.");
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Vui lòng xác thực sinh trắc học của bạn',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Thiết lập sinh trắc học',
            cancelButton: 'Hủy',
          ),
        ],
      );

      if (didAuthenticate) {
        const storage = FlutterSecureStorage();
        await storage.write(key: "hasSetupBiometric", value: "true");
        await storage.write(key: "biometric_pin", value: pinCode);

        if (mounted) {
          SnackbarUtils.showSuccess(context, "Thiết lập thành công!");
        }
      } else {
        _showErrorSnackBar("Xác thực sinh trắc học thất bại.");
      }
    } catch (e) {
      _showErrorSnackBar("Lỗi thiết lập sinh trắc học: $e");
    }
  }

  void _showBalanceUpdateNotification(Map<String, dynamic> data) {
    final String type = data['type'] ?? '';
    final String rawAmount = data['amount']?.toString() ?? '0';
    final String formattedAmount = _formatAmountValue(rawAmount);

    String message = '';
    if (type == 'DEPOSIT') {
      message = 'Nạp tiền thành công: +$formattedAmount';
    } else if (type == 'TRANSFER_SENT') {
      message = 'Chuyển tiền thành công: -$formattedAmount';
    } else if (type == 'TRANSFER_RECEIVED') {
      final String sender = data['senderName'] ?? 'Người gửi';
      message = 'Nhận tiền từ $sender: +$formattedAmount';
    } else {
      message = 'Số dư ví đã thay đổi: $formattedAmount';
    }

    SnackbarUtils.showSuccess(context, message);
  }

  String _formatAmountValue(String value) {
    final number = int.tryParse(value);
    if (number == null) return "${value}đ";
    return "${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }

  Future<void> _fetchBalance() async {
    if (widget.token.isEmpty) {
      if (mounted) setState(() => _isLoadingBalance = false);
      return;
    }

    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getWalletBalance),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _balance =
                responseData['data']?['available_balance']?.toString() ?? "0";
            _walletCode = responseData['data']?['wallet_code'];
            _isPinSet = responseData['data']?['is_pin_set'] ?? false;
            _isLoadingBalance = false;
          });

          // Nếu đã KYC mà chưa có mã PIN thì hiện popup bắt tạo
          if (widget.isVerified && !_isPinSet) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSetWalletCodeDialog();
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingBalance = false);
      }
    } catch (e) {
      print("Lỗi lấy số dư ví: $e");
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _fetchUnreadCount() async {
    if (widget.token.isEmpty) return;
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getUnreadNotificationCount),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _unreadCount = data['unreadCount'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch unread count error: $e");
    }
  }

  void _showSetWalletCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SetWalletCodeDialog(
        token: widget.token,
        onSuccess: (newCode) {
          setState(() {
            _walletCode = newCode;
            _isPinSet = true;
          });
          SnackbarUtils.showSuccess(context, 'Tạo mã PIN thành công!');
        },
      ),
    );
  }

  void _showKycDialog() {
    String activeLang = AppState.currentLanguage.value;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          activeLang == 'VIE' ? 'Yêu cầu xác thực' : 'Authentication Required',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          activeLang == 'VIE'
              ? 'Tài khoản của bạn chưa được xác thực danh tính. Vui lòng hoàn tất eKYC để sử dụng dịch vụ.'
              : 'Your account is not verified. Please complete eKYC to use our services.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              activeLang == 'VIE' ? 'Để sau' : 'Later',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => KycFlowScreen(userId: widget.userId),
                ),
              );
            },
            child: Text(
              activeLang == 'VIE' ? 'Xác thực ngay' : 'Verify Now',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDepositWithdrawClick() async {
    setState(() => _isLoadingBalance = true);
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.getLinkedBanks),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
          'ngrok-skip-browser-warning': 'true',
        },
      );
      setState(() => _isLoadingBalance = false);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List banks = responseData['data'] ?? [];
        if (banks.isEmpty) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BankLinkScreen(token: widget.token),
            ),
          );
        } else {
          if (!mounted) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DepositWithdrawScreen(token: widget.token),
            ),
          );
          if (result == true) {
            _fetchBalance();
          }
        }
      } else {
        _showErrorSnackBar("Không thể kiểm tra thông tin liên kết ngân hàng.");
      }
    } catch (e) {
      setState(() => _isLoadingBalance = false);
      _showErrorSnackBar("Lỗi kết nối máy chủ khi kiểm tra ngân hàng.");
      debugPrint("Check linked banks error: $e");
    }
  }

  void _showAlreadyLinkedDialog(String bankName, String cardNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Nạp/Rút tiền',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tài khoản của bạn đã liên kết với:\n$bankName - $cardNumber\n\n(Tính năng Nạp/Rút tiền đang được phát triển thêm)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.currentLanguage,
      builder: (context, activeLang, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: const Color(0xFFF5F5F5),
          body: _selectedIndex == 0
              ? RefreshIndicator(
                  onRefresh: _fetchBalance,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeaderSection(activeLang),

                        // Đã thay thế thẻ ví cũ bằng Widget WalletCard
                        WalletCard(
                          activeLang: activeLang,
                          isLoading: _isLoadingBalance,
                          balance: _balance,
                          onToggleVisibility: _fetchBalance,
                        ),

                        _buildFinancialCenterBanner(activeLang),

                        // Đã thay thế Grid cũ bằng Widget ServicesGrid
                        ServicesGrid(
                          activeLang: activeLang,
                          isVerified: widget.isVerified,
                          token: widget.token,
                          isPinSet: _isPinSet,
                          onRequireKyc: _showKycDialog,
                          onRequireWalletCode: _showSetWalletCodeDialog,
                          onRefreshBalance: _fetchBalance,
                        ),

                        _buildEventBanner(activeLang),
                        _buildRecommendations(activeLang),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                )
              : _selectedIndex == 1
              ? Center(
                  child: Text(
                    activeLang == 'VIE'
                        ? 'Trang Ưu đãi (Sắp ra mắt)'
                        : 'Offers (Coming soon)',
                  ),
                )
              : _selectedIndex == 2
              ? TransactionHistoryScreen(token: widget.token)
              : ProfileScreen(token: widget.token),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (!widget.isVerified) {
                _showKycDialog();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrMainScreen(token: widget.token),
                  ),
                );
              }
            },
            backgroundColor: Colors.pink,
            elevation: 2,
            shape: const CircleBorder(),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            color: Colors.white,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Expanded(
                    child: _buildBottomNavItem(
                      Icons.home_rounded,
                      "Mio",
                      0,
                      isActive: _selectedIndex == 0,
                    ),
                  ),
                  Expanded(
                    child: _buildBottomNavItem(
                      Icons.local_offer_rounded,
                      activeLang == 'VIE' ? "Ưu đãi" : "Offers",
                      1,
                      isActive: _selectedIndex == 1,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          activeLang == 'VIE' ? "Quét mọi QR" : "Scan QR",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildBottomNavItem(
                      Icons.history_rounded,
                      activeLang == 'VIE' ? "Lịch sử GD" : "History",
                      2,
                      isActive: _selectedIndex == 2,
                    ),
                  ),
                  Expanded(
                    child: _buildBottomNavItem(
                      Icons.person_outline_rounded,
                      activeLang == 'VIE' ? "Tôi" : "Me",
                      3,
                      isActive: _selectedIndex == 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(String activeLang) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0F7FA), Color(0xFFF1F8E9), Colors.white],
        ),
      ),
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                      hintText: activeLang == 'VIE'
                          ? "Tìm bạn bè để chuyển tiền"
                          : "Find friends to transfer",
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationScreen(token: widget.token),
                    ),
                  );
                  _fetchUnreadCount(); // Refresh count when coming back
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: Colors.black87,
                      ),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction(
                  Icons.account_balance_wallet_rounded,
                  Colors.pink,
                  activeLang == 'VIE' ? "Nạp/Rút" : "Deposit",
                ),
                _buildQuickAction(
                  Icons.qr_code_rounded,
                  Colors.pink,
                  activeLang == 'VIE' ? "Nhận tiền" : "Receive",
                ),
                _buildQuickAction(
                  Icons.qr_code_scanner_rounded,
                  Colors.pink,
                  activeLang == 'VIE' ? "QR Thanh toán" : "QR Pay",
                ),
                _buildQuickAction(
                  Icons.apps_rounded,
                  Colors.pink,
                  activeLang == 'VIE' ? "Ví tiện ích" : "Utilities",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCenterBanner(String activeLang) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_rounded,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                activeLang == 'VIE'
                    ? "Trung Tâm Tài Chính của Thống"
                    : "Thong's Financial Center",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.blue.shade700, size: 20),
        ],
      ),
    );
  }

  Widget _buildEventBanner(String activeLang) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activeLang == 'VIE' ? "Sự kiện đang diễn ra" : "Ongoing Events",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.red,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.2,
                      child: Container(color: Colors.black),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeLang == 'VIE'
                              ? "Dùng Ví Trả Sau\nHoàn tiền 50%*"
                              : "Use Postpaid Wallet\n50% Cashback*",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeLang == 'VIE'
                              ? "Tối đa 10k mọi giao dịch từ 1-30/6"
                              : "Max 10k for all transactions June 1-30",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activeLang == 'VIE' ? "Khám phá ngay" : "Explore Now",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(String activeLang) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              activeLang == 'VIE' ? "Mio đề xuất" : "Recommended",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildRecommendItem(
                  Icons.campaign_rounded,
                  activeLang == 'VIE' ? "Từ 220k" : "From 220k",
                  activeLang == 'VIE'
                      ? "Loa thông\nbáo chuyển ..."
                      : "Payment\nSpeaker",
                  Colors.pink,
                ),
                _buildRecommendItem(
                  Icons.card_giftcard_rounded,
                  activeLang == 'VIE' ? "Hoàn 50%" : "50% Back",
                  activeLang == 'VIE'
                      ? "Ví Trả Sau -\nHoàn 50%"
                      : "Postpaid -\n50% Back",
                  Colors.pinkAccent,
                ),
                _buildRecommendItem(
                  Icons.sports_esports_rounded,
                  null,
                  activeLang == 'VIE' ? "Mã thẻ Game\nOnline" : "Game\nCards",
                  Colors.blue,
                ),
                _buildRecommendItem(
                  Icons.account_balance_wallet_rounded,
                  null,
                  activeLang == 'VIE' ? "Túi Thần Tài" : "Wealth Bag",
                  Colors.orange,
                ),
                _buildRecommendItem(
                  Icons.electric_bolt_rounded,
                  null,
                  activeLang == 'VIE'
                      ? "Thanh toán\nđiện"
                      : "Electricity\nBill",
                  Colors.yellow.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, Color color, String title) {
    return GestureDetector(
      onTap: () {
        if (!widget.isVerified) {
          _showKycDialog();
        } else {
          if (title == "Nạp/Rút" || title == "Deposit") {
            _handleDepositWithdrawClick();
          } else if (title == "Nhận tiền" || title == "Receive") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QrMainScreen(token: widget.token, initialIndex: 1),
              ),
            );
          } else if (title == "QR Thanh toán" || title == "QR Pay") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QrMainScreen(token: widget.token, initialIndex: 0),
              ),
            );
          } else {
            print("Đang mở tính năng: $title");
          }
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendItem(
    IconData icon,
    String? badge,
    String title,
    Color color,
  ) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              if (badge != null)
                Positioned(
                  top: -8,
                  left: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    int index, {
    bool isActive = false,
  }) {
    return MaterialButton(
      minWidth: 40,
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.pink : Colors.grey),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.pink : Colors.grey,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

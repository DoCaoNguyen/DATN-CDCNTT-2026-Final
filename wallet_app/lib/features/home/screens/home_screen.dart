import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/home_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/kyc/screens/kyc_flow_screen.dart';
import '../../../core/utils/app_state.dart';
import '../../../core/constants/api_config.dart';
import '../widgets/set_wallet_code_dialog.dart';
import '../widgets/wallet_card.dart';
import '../widgets/services_grid.dart';
import '../widgets/home_header.dart';
import '../widgets/home_banners.dart';
import '../../financial_center/screens/financial_center_screen.dart';
import 'qr_main_screen.dart';
import 'notification_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../history/screens/transaction_history_screen.dart';
import '../../offers/screens/offers_screen.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/custom_http_client.dart';
import '../../bank/screens/bank_link_screen.dart';
import '../../bank/screens/deposit_withdraw_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_android/local_auth_android.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../ai/screens/voice_transfer_dialog.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../chat/screens/chat_list_screen.dart';

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
  final HomeService _homeService = HomeService();
  int _selectedIndex = 0;
  String _balance = "0";
  String _loyaltyPoints = "0";
  String? _walletCode;
  bool _isPinSet = false;
  bool _isLoadingBalance = true;
  int _unreadCount = 0;
  String _fullName = "Bạn";

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
    _fetchProfile();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _promptPinForBiometric();
            },
            child: const Text(
              "Đồng ý",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
              headers: {'Content-Type': 'application/json'},
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
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

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
    final data = await _homeService.fetchBalance(widget.token);
    if (data != null && mounted) {
      setState(() {
        _balance = data['available_balance']?.toString() ?? "0";
        _loyaltyPoints = data['loyalty_points']?.toString() ?? "0";
        _walletCode = data['wallet_code'];
        _isPinSet = data['is_pin_set'] ?? false;
        _isLoadingBalance = false;
      });
      if (widget.isVerified && !_isPinSet) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSetWalletCodeDialog();
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _fetchUnreadCount() async {
    final count = await _homeService.fetchUnreadCount(widget.token);
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  Future<void> _fetchProfile() async {
    final data = await _homeService.fetchProfile(widget.token);
    if (data != null && mounted) {
      final String? name = data['full_name'];
      if (name != null && name.trim().isNotEmpty) {
        setState(() {
          _fullName = name.trim().split(' ').last;
        });
      }
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
          'Tài khoản của bạn đã liên kết với:\n\n$bankName - $cardNumber\n\n(Tính năng Nạp/Rút tiền đang được phát triển thêm)',
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
                        HomeHeader(
                          activeLang: activeLang,
                          token: widget.token,
                          unreadCount: _unreadCount,
                          onRefreshUnread: _fetchUnreadCount,
                          isVerified: widget.isVerified,
                          onRequireKyc: _showKycDialog,
                          onDepositWithdraw: _handleDepositWithdrawClick,
                        ),

                        // Đã thay thế thẻ ví cũ bằng Widget WalletCard
                        WalletCard(
                          activeLang: activeLang,
                          isLoading: _isLoadingBalance,
                          balance: _balance,
                          onToggleVisibility: _fetchBalance,
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FinancialCenterScreen(balance: _balance, token: widget.token),
                              ),
                            );
                          },
                          child: FinancialCenterBanner(
                            activeLang: activeLang,
                            fullName: _fullName,
                          ),
                        ),

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

                        HomeEventBanner(activeLang: activeLang),
                        HomeRecommendations(activeLang: activeLang),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                )
              : _selectedIndex == 1
              ? OffersScreen(token: widget.token, loyaltyPoints: _loyaltyPoints, onRefresh: _fetchBalance)
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/custom_http_client.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/pin_confirm_bottom_sheet.dart';
import '../../../core/widgets/otp_input_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/screens/personal_profile_screen.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import 'package:intl/intl.dart';
import 'merchant_settings_screen.dart';

class MerchantScreen extends StatefulWidget {
  final String token;

  const MerchantScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends State<MerchantScreen> {
  final _client = CustomHttpClient();
  bool _isLoading = true;

  bool _isEmailVerified = false;
  String _userEmail = '';
  String _userFullName = '';
  String _userPhone = '';

  bool _isMerchant = false;
  Map<String, dynamic> _merchantData = {};

  // Registration Form
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _webhookController = TextEditingController();
  final _redirectUrlController = TextEditingController();

  bool _isRegistering = false;
  bool _keysVisible = false;

  // Statement History
  List<dynamic> _statementList = [];
  List<dynamic> _filteredStatementList = [];
  bool _isLoadingStatement = false;
  bool _isFetchingMoreStatement = false;
  int _statementPage = 1;
  bool _hasMoreStatement = true;
  String _filterMonth = "Tất cả";
  // Biến alias cho dropdown UI
  String _selectedMonth = "Tất cả";
  String? _filterType; // null = Tất cả, 'CREDIT' = Nhận, 'DEBIT' = Rút
  final TextEditingController _searchStatementController =
      TextEditingController();
  final ScrollController _statementScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchStatement();
    _searchStatementController.addListener(_applyStatementFilter);
    _statementScrollController.addListener(() {
      // Tự động load thêm khi cuộn đến cách đáy 100px
      if (_statementScrollController.position.pixels >=
          _statementScrollController.position.maxScrollExtent - 100) {
        _fetchStatement(loadMore: true);
      }
    });

    // Đăng ký nhận sự kiện cập nhật số dư merchant qua Socket
    SocketService().onMerchantBalanceUpdate((data) {
      if (mounted && _isMerchant) {
        setState(() {
          _merchantData['available_balance'] =
              data['newBalance']?.toString() ??
              _merchantData['available_balance'];
        });
        debugPrint(
          'Merchant balance updated via Socket: ${data['newBalance']}',
        );
      }
    });
  }

  @override
  void dispose() {
    SocketService().offMerchantBalanceUpdate();
    _nameController.dispose();
    _phoneController.dispose();
    _webhookController.dispose();
    _redirectUrlController.dispose();
    _searchStatementController.dispose();
    _statementScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch User Profile
      final userRes = await _client.get(Uri.parse(ApiConfig.getMyProfile));
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _userEmail = userData['data']['email'] ?? '';
        _isEmailVerified = _userEmail.isNotEmpty;
        _userFullName = userData['data']['full_name'] ?? '';
        _userPhone = userData['data']['phone'] ?? '';

        if (_phoneController.text.isEmpty) {
          _phoneController.text = _userPhone;
        }
      }

      // Fetch Merchant Info
      final merchantRes = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/merchant/me'),
      );
      if (merchantRes.statusCode == 200) {
        final merchantData = jsonDecode(merchantRes.body);
        _merchantData = merchantData['data'];
        _isMerchant = true;

        // Fetch Balance
        final balanceRes = await _client.get(
          Uri.parse('${ApiConfig.baseUrl}/merchant/balance'),
        );
        if (balanceRes.statusCode == 200) {
          final balanceData = jsonDecode(balanceRes.body);
          _merchantData['available_balance'] =
              balanceData['data']['available_balance'];
        }
      } else if (merchantRes.statusCode == 404) {
        _isMerchant = false;
      }
    } catch (e) {
      debugPrint('Error fetching merchant data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStatement({bool loadMore = false}) async {
    if (!mounted) return;
    // Chống gọi dup khi đang fetch
    if (loadMore) {
      if (!_hasMoreStatement || _isFetchingMoreStatement) return;
      setState(() {
        _isFetchingMoreStatement = true;
        _statementPage++;
      });
    } else {
      if (_isLoadingStatement) return;
      setState(() {
        _isLoadingStatement = true;
        _statementPage = 1;
        _statementList = [];
        _filteredStatementList = [];
      });
    }

    String url =
        '${ApiConfig.baseUrl}/merchant/balance/statement?page=$_statementPage&limit=10';

    if (_filterMonth != "Tất cả") {
      final timeStr = _filterMonth.replaceAll("Tháng ", "");
      final parts = timeStr.split("/");
      if (parts.length == 2) {
        final month = int.tryParse(parts[0]) ?? 1;
        final year = int.tryParse(parts[1]) ?? 2026;
        final startStr = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(year, month, 1));
        final endStr = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(year, month + 1, 0));
        url += "&date_from=$startStr&date_to=$endStr";
      }
    }

    if (_filterType != null) {
      url += "&type=$_filterType";
    }

    try {
      final res = await _client.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final resData = jsonDecode(res.body);
        if (resData['success'] == true) {
          final items = resData['data']['items'] as List<dynamic>;
          if (mounted) {
            setState(() {
              if (loadMore) {
                _statementList.addAll(items);
              } else {
                _statementList = items;
              }
              _hasMoreStatement = items.length >= 10;
            });
            _applyStatementFilter();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching statement: $e");
    } finally {
      if (mounted)
        setState(() {
          _isLoadingStatement = false;
          _isFetchingMoreStatement = false;
        });
    }
  }

  void _applyStatementFilter() {
    final keyword = _searchStatementController.text.toLowerCase().trim();
    setState(() {
      _filteredStatementList = _statementList.where((tx) {
        // Lọc theo từ khóa
        final note = (tx['description'] ?? '').toString().toLowerCase();
        final paymentNo = (tx['payment_no'] ?? '').toString().toLowerCase();
        final amount = tx['amount']?.toString() ?? '';
        final matchesKeyword =
            keyword.isEmpty ||
            note.contains(keyword) ||
            paymentNo.contains(keyword) ||
            amount.replaceAll(RegExp(r'[^0-9]'), '').contains(keyword) ||
            amount.contains(keyword);
        // Lọc theo loại giao dịch
        final matchesType =
            _filterType == null ||
            (_filterType == 'CREDIT' && tx['entry_type'] == 'CREDIT') ||
            (_filterType == 'DEBIT' && tx['entry_type'] == 'DEBIT');
        return matchesKeyword && matchesType;
      }).toList();
    });
  }

  bool _hasActiveFilter() {
    return _filterMonth != "Tất cả" || _filterType != null;
  }

  void _openFilterSheet() {
    String tempMonth = _filterMonth;
    String? tempType = _filterType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Lọc giao dịch",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // --- Phần 1: Lọc theo tháng ---
              const Text(
                "Theo tháng",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getFilterMonths().map((m) {
                  final selected = tempMonth == m;
                  return GestureDetector(
                    onTap: () => setSheet(() => tempMonth = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Colors.pink : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? Colors.pink : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        m,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // --- Phần 2: Lọc theo loại ---
              const Text(
                "Theo loại giao dịch",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _typeChip(
                    null,
                    "Tất cả",
                    tempType,
                    (v) => setSheet(() => tempType = v),
                  ),
                  _typeChip(
                    'CREDIT',
                    "Nhận tiền",
                    tempType,
                    (v) => setSheet(() => tempType = v),
                  ),
                  _typeChip(
                    'DEBIT',
                    "Rút tiền",
                    tempType,
                    (v) => setSheet(() => tempType = v),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setSheet(() {
                          tempMonth = "Tất cả";
                          tempType = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.pink),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Xoá bộ lọc",
                        style: TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _filterMonth = tempMonth;
                          _filterType = tempType;
                        });
                        _fetchStatement();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Áp dụng",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(
    String? value,
    String label,
    String? currentValue,
    void Function(String?) onTap,
  ) {
    final selected = currentValue == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.pink : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.pink : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final webhook = _webhookController.text.trim();
    final redirectUrl = _redirectUrlController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      SnackbarUtils.showError(context, 'Vui lòng nhập Tên và SĐT doanh nghiệp');
      return;
    }

    setState(() => _isRegistering = true);

    try {
      // Yêu cầu OTP
      final otpRes = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/users/email/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": _userEmail}),
      );

      if (otpRes.statusCode != 200) {
        SnackbarUtils.showError(context, 'Lỗi gửi mã OTP');
        setState(() => _isRegistering = false);
        return;
      }

      // Hiển thị hộp thoại OTP
      _showOtpDialog(name, phone, webhook, redirectUrl);
    } catch (e) {
      SnackbarUtils.showError(context, 'Lỗi kết nối máy chủ');
    } finally {
      setState(() => _isRegistering = false);
    }
  }

  void _showOtpDialog(String name, String phone, String webhook, String redirectUrl) {
    String currentOtp = "";
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Xác thực OTP",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Mã OTP gồm 6 chữ số đã được gửi tới:\n$_userEmail",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    OtpInputWidget(
                      length: 6,
                      onChanged: (val) {
                        currentOtp = val;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isVerifying
                            ? null
                            : () async {
                                if (currentOtp.length != 6) {
                                  SnackbarUtils.showError(
                                    context,
                                    "Mã OTP phải gồm 6 số",
                                  );
                                  return;
                                }

                                setSheetState(() => isVerifying = true);

                                try {
                                  final verifyRes = await _client.post(
                                    Uri.parse(
                                      '${ApiConfig.baseUrl}/users/email/verify-otp',
                                    ),
                                    headers: {
                                      "Content-Type": "application/json",
                                    },
                                    body: jsonEncode({
                                      "email": _userEmail,
                                      "otp": currentOtp,
                                    }),
                                  );

                                  if (!mounted) return;

                                  if (verifyRes.statusCode == 200) {
                                    final regRes = await _client.post(
                                      Uri.parse(
                                        '${ApiConfig.baseUrl}/merchant/register',
                                      ),
                                      headers: {
                                        "Content-Type": "application/json",
                                      },
                                        body: jsonEncode({
                                          "merchant_name": name,
                                          "contact_phone": phone,
                                          "callback_url": webhook,
                                          "redirect_url": redirectUrl,
                                        }),
                                    );

                                    if (!mounted) return;

                                    if (regRes.statusCode == 201) {
                                      Navigator.pop(
                                        context,
                                      ); // Đóng bottom sheet
                                      SnackbarUtils.showSuccess(
                                        context,
                                        "Đăng ký Merchant thành công!",
                                      );
                                      _fetchData(); // Load lại dữ liệu
                                    } else {
                                      final err =
                                          jsonDecode(regRes.body)['error'] ??
                                          "Đăng ký thất bại";
                                      SnackbarUtils.showError(context, err);
                                    }
                                  } else {
                                    final err =
                                        jsonDecode(verifyRes.body)['error'] ??
                                        "Mã OTP không hợp lệ";
                                    SnackbarUtils.showError(context, err);
                                  }
                                } catch (e) {
                                  if (mounted)
                                    SnackbarUtils.showError(
                                      context,
                                      "Lỗi kết nối máy chủ",
                                    );
                                } finally {
                                  if (mounted)
                                    setSheetState(() => isVerifying = false);
                                }
                              },
                        child: isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Xác nhận",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPinBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinConfirmBottomSheet(
        onPinEntered: (pin) async {
          try {
            // Xác thực PIN qua API
            final response = await _client.post(
              Uri.parse(ApiConfig.verifyPin),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'pin': pin}),
            );

            if (response.statusCode == 200) {
              if (mounted) {
                Navigator.pop(context);
                setState(() => _keysVisible = true);
              }
              return null; // Thành công
            } else {
              return 'Mã PIN không chính xác';
            }
          } catch (e) {
            return 'Lỗi kết nối máy chủ';
          }
        },
      ),
    );
  }

  Future<void> _updateWebhook() async {
    final webhook = _webhookController.text.trim();
    if (webhook.isEmpty) {
      SnackbarUtils.showError(context, "Vui lòng nhập Webhook URL");
      return;
    }
    try {
      final res = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/merchant/webhook'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"callback_url": webhook}),
      );
      if (res.statusCode == 200) {
        SnackbarUtils.showSuccess(context, "Cập nhật Webhook thành công");
      } else {
        SnackbarUtils.showError(context, "Cập nhật thất bại");
      }
    } catch (e) {
      SnackbarUtils.showError(context, "Lỗi kết nối");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Đối tác kinh doanh',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _isMerchant
          ? _buildMerchantInfo()
          : _isEmailVerified
          ? _buildRegistrationForm()
          : _buildRequireEmail(),
    );
  }

  Widget _buildRequireEmail() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread_rounded,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              "Xác thực Email",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Để đăng ký trở thành Đối tác kinh doanh, bạn cần cung cấp và xác thực địa chỉ email.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersonalProfileScreen(
                        token: widget.token,
                        email: null,
                        fullName: _userFullName,
                        phone: _userPhone,
                      ),
                    ),
                  ).then((_) => _fetchData());
                },
                child: const Text(
                  'Cập nhật Email ngay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Đăng ký Merchant",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Điền thông tin doanh nghiệp của bạn để bắt đầu tích hợp thanh toán qua API.",
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            "Tên doanh nghiệp / Cửa hàng",
            _nameController,
            Icons.storefront_rounded,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            "Số điện thoại liên hệ",
            _phoneController,
            Icons.phone_rounded,
            isNumber: true,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            "Webhook URL (Tùy chọn)",
            _webhookController,
            Icons.link_rounded,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            "Redirect URL (Tùy chọn)",
            _redirectUrlController,
            Icons.link_rounded,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _isRegistering ? null : _handleRegister,
              child: _isRegistering
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Đăng ký ngay",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantInfo() {
    final balanceStr = _merchantData['available_balance'] ?? '0';
    final formattedBalance = CurrencyFormatter.format(balanceStr);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _merchantData['merchant_name'] ?? 'Merchant',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "SĐT: ${_merchantData['contact_phone']}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.settings_rounded,
                  color: Colors.pink,
                  size: 28,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => PinConfirmBottomSheet(
                      onPinEntered: (pin) async {
                        try {
                          final response = await _client.post(
                            Uri.parse(ApiConfig.verifyPin),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'pin': pin}),
                          );

                          if (response.statusCode == 200) {
                            Navigator.pop(ctx); // Đóng bottom sheet
                            if (!mounted) return null;

                            // Điều hướng qua màn hình settings
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MerchantSettingsScreen(
                                  token: widget.token,
                                  merchantData: _merchantData,
                                ),
                              ),
                            ).then((_) => _fetchData());

                            return null; // Return null = success
                          } else {
                            final data = jsonDecode(response.body);
                            return data['error'] ?? "Mã PIN không chính xác";
                          }
                        } catch (e) {
                          return "Không thể kết nối máy chủ";
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withAlpha(76),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "SỐ DƯ DOANH THU",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  formattedBalance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildStatementFilter(),
          const SizedBox(height: 16),
          _buildStatementList(),
        ],
      ),
    );
  }

  Widget _buildStatementFilter() {
    return Row(
      children: [
        // Thanh tìm kiếm (style giống màn hình lịch sử)
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchStatementController,
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) => _applyStatementFilter(),
                    decoration: const InputDecoration(
                      hintText: "Tìm kiếm giao dịch",
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Nút lọc (tune icon - giống màn hình lịch sử)
        GestureDetector(
          onTap: _openFilterSheet,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _hasActiveFilter()
                  ? Colors.pink.shade50
                  : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
              border: _hasActiveFilter()
                  ? Border.all(color: Colors.pink.shade200)
                  : null,
            ),
            child: Icon(
              Icons.tune_rounded,
              color: _hasActiveFilter() ? Colors.pink : Colors.grey.shade600,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getFilterMonths() {
    List<String> months = ["Tất cả"];
    final now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      months.add("Tháng ${d.month}/${d.year}");
    }
    return months;
  }

  Widget _buildStatementList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Lịch sử giao dịch",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (_hasActiveFilter())
              GestureDetector(
                onTap: () {
                  setState(() {
                    _filterMonth = "Tất cả";
                    _selectedMonth = "Tất cả";
                    _filterType = null;
                  });
                  _fetchStatement();
                },
                child: const Text(
                  "Xóa lọc",
                  style: TextStyle(
                    color: Colors.pink,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Khung cố định hiển thị tối đa ~6 giao dịch (~72px * 6 = 432px)
        Container(
          height: 432,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoadingStatement
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.pink),
                )
              : _filteredStatementList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Không có giao dịch nào.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    controller: _statementScrollController,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount:
                        _filteredStatementList.length +
                        (_isFetchingMoreStatement ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 70),
                    itemBuilder: (context, index) {
                      if (index == _filteredStatementList.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.pink,
                            ),
                          ),
                        );
                      }
                      return _buildHistoryItem(_filteredStatementList[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(dynamic tx) {
    final bool isCredit = tx['entry_type'] == 'CREDIT';
    final String amountRaw = tx['amount']?.toString() ?? '0';
    final String balanceAfterRaw = tx['balance_after']?.toString() ?? '0';
    final String date = tx['created_at'] != null
        ? DateFormatter.format(tx['created_at'])
        : '';
    final String note = tx['description'] ?? 'Giao d\u1ecbch';

    // Xác định tiêu đề rõ ràng & icon theo loại
    String title;
    IconData iconData;
    Color iconColor;
    if (isCredit) {
      final String paymentNo = tx['payment_no']?.toString() ?? '';
      title = paymentNo.isNotEmpty
          ? "\u0110\u01a1n h\u00e0ng $paymentNo"
          : "Nh\u1eadn doanh thu \u0111\u01a1n h\u00e0ng";
      iconData = Icons.call_received_rounded;
      iconColor = Colors.green;
    } else if (note.toLowerCase().contains('ng\u00e2n h\u00e0ng') ||
        note.toLowerCase().contains('bank')) {
      title = "R\u00fat ti\u1ec1n v\u1ec1 ng\u00e2n h\u00e0ng";
      iconData = Icons.account_balance_rounded;
      iconColor = Colors.orange.shade700;
    } else {
      title = "R\u00fat ti\u1ec1n v\u1ec1 v\u00ed c\u00e1 nh\u00e2n";
      iconData = Icons.account_balance_wallet_rounded;
      iconColor = Colors.pink;
    }

    return InkWell(
      onTap: () {
        // Bottom sheet chi tiết giao dịch (giống màn hình lịch sử)
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${isCredit ? '+' : '-'}${CurrencyFormatter.format(amountRaw)}",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isCredit ? Colors.green.shade700 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildStatementDetailRow(
                    "Trạng thái",
                    "Thành công",
                    isStatus: true,
                  ),
                  _buildStatementDetailRow("Thời gian", date),
                  _buildStatementDetailRow(
                    "Số dư sau GD",
                    CurrencyFormatter.format(balanceAfterRaw),
                  ),
                  // Thông tin bên gửi/nhận
                  if (isCredit) ...[
                    if (tx['payer_name'] != null)
                      _buildStatementDetailRow(
                        "Người thanh toán",
                        "${tx['payer_name']}${tx['payer_phone'] != null ? '\n${tx['payer_phone']}' : ''}",
                      ),
                    if (tx['payment_no'] != null)
                      _buildStatementDetailRow(
                        "Mã đơn hàng",
                        tx['payment_no'].toString(),
                      ),
                  ] else ...[
                    if (tx['bank_code'] != null)
                      _buildStatementDetailRow(
                        "Ngân hàng",
                        tx['bank_code'].toString(),
                      ),
                    if (tx['bank_account_number'] != null)
                      _buildStatementDetailRow(
                        "Số tài khoản",
                        tx['bank_account_number'].toString(),
                      ),
                    if (tx['wallet_owner_name'] != null)
                      _buildStatementDetailRow(
                        "Ví nhận",
                        "${tx['wallet_owner_name']}${tx['wallet_owner_phone'] != null ? ' (${tx['wallet_owner_phone']})' : ''}",
                      ),
                  ],
                  _buildStatementDetailRow("Nội dung", note),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Đóng",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon tròn viền xám - giống màn hình lịch sử giao dịch
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Tên + ngày + tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isCredit
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isCredit ? "Doanh thu" : "R\u00fat ti\u1ec1n",
                      style: TextStyle(
                        color: isCredit
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Số tiền + số dư sau GD
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${isCredit ? '+' : '-'}${CurrencyFormatter.format(amountRaw)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCredit ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "SD: ${CurrencyFormatter.format(balanceAfterRaw)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementDetailRow(
    String label,
    String value, {
    bool isStatus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: isStatus
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Th\u00e0nh c\u00f4ng",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.pink, width: 1.5),
        ),
      ),
    );
  }
}

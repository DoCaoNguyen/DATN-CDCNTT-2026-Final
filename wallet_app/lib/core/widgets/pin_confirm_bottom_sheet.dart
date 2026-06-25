import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_android/local_auth_android.dart';
import '../../features/auth/forgot_pin/screens/forgot_pin_face_auth_screen.dart';

class PinConfirmBottomSheet extends StatefulWidget {
  final Future<String?> Function(String) onPinEntered;
  final bool autoTriggerBiometric;
  const PinConfirmBottomSheet({
    Key? key,
    required this.onPinEntered,
    this.autoTriggerBiometric = true,
  }) : super(key: key);

  @override
  State<PinConfirmBottomSheet> createState() => _PinConfirmBottomSheetState();
}

class _PinConfirmBottomSheetState extends State<PinConfirmBottomSheet> {
  final TextEditingController pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _errorMessage;
  bool _isLoading = false;
  bool _hasBiometric = false;
  bool _showPinEntry = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  @override
  void dispose() {
    pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    final hasBiometricSetup = await _storage.read(key: "hasSetupBiometric");
    if (hasBiometricSetup == "true") {
      setState(() {
        _hasBiometric = true;
        if (widget.autoTriggerBiometric) {
          _showPinEntry = false;
        } else {
          _showPinEntry = true;
        }
      });
      if (widget.autoTriggerBiometric) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _authenticateWithBiometrics();
        });
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          _focusNode.requestFocus();
        });
      }
    } else {
      setState(() {
        _hasBiometric = false;
        _showPinEntry = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _focusNode.requestFocus();
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) return;

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Xác thực để thực hiện giao dịch',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Xác thực sinh trắc học',
            cancelButton: 'Hủy',
          ),
        ],
      );

      if (didAuthenticate) {
        final storedPin = await _storage.read(key: "biometric_pin");
        if (storedPin != null && storedPin.isNotEmpty) {
          if (mounted) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          }

          String? error = await widget.onPinEntered(storedPin);

          if (mounted) {
            setState(() {
              _isLoading = false;
              if (error != null) {
                _errorMessage = error;
                _showPinEntry = true;
                Future.delayed(const Duration(milliseconds: 100), () {
                  _focusNode.requestFocus();
                });
              }
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _showPinEntry = true;
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            _focusNode.requestFocus();
          });
        }
      }
    } catch (e) {
      debugPrint("Biometric Auth Error: $e");
      if (mounted) {
        setState(() {
          _showPinEntry = true;
        });
      }
    }
  }

  Widget _buildPinDots() {
    String pin = pinController.text;
    bool hasError = _errorMessage != null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasError ? Colors.red : Colors.grey.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(30),
        color: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          bool isFilled = index < pin.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled
                  ? (hasError ? Colors.red : Colors.grey.shade600)
                  : Colors.grey.shade300,
            ),
          );
        }),
      ),
    );
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đặt lại mã PIN xác thực',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bạn sẽ phải đăng xuất khỏi tài khoản này để đặt lại mã PIN xác thực.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'KHÔNG',
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext); // Đóng Dialog
                          Navigator.pop(
                            context,
                          ); // Đóng BottomSheet nhập mã PIN
                          // Chuyển hướng tới màn hình xác thực khuôn mặt
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPinFaceAuthScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Đồng ý',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasKeyboard = MediaQuery.of(context).viewInsets.bottom > 0;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          bottom: hasKeyboard
              ? 24
              : (24 + MediaQuery.of(context).padding.bottom),
          left: 24,
          right: 24,
        ),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                Text(
                  _showPinEntry ? 'Nhập mã PIN xác thực' : 'Xác thực bảo mật',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!_showPinEntry && _hasBiometric)
              Column(
                children: [
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _authenticateWithBiometrics,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: Colors.pink,
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Vui lòng quét Vân tay/FaceID của bạn",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showPinEntry = true;
                      });
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _focusNode.requestFocus();
                      });
                    },
                    child: const Text(
                      "Hủy",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              )
            else
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0.0,
                        child: TextField(
                          controller: pinController,
                          focusNode: _focusNode,
                          autofocus: false,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          enabled: !_isLoading,
                          decoration: const InputDecoration(counterText: ""),
                          onChanged: (val) async {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                            setState(() {});

                            if (val.length == 6) {
                              setState(() => _isLoading = true);

                              String? error = await widget.onPinEntered(val);

                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                  if (error != null) {
                                    _errorMessage = error;
                                    pinController.clear();
                                    Future.delayed(
                                      const Duration(milliseconds: 50),
                                      () {
                                        _focusNode.requestFocus();
                                      },
                                    );
                                  }
                                });
                              }
                            }
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _focusNode.requestFocus(),
                        child: Container(
                          color: Colors.white,
                          width: double.infinity,
                          child: _buildPinDots(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_errorMessage != null && !_isLoading)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.pink,
                      ),
                    ),
                  if (_hasBiometric) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showPinEntry = false;
                        });
                        _authenticateWithBiometrics();
                      },
                      icon: const Icon(
                        Icons.fingerprint_rounded,
                        color: Colors.pink,
                        size: 20,
                      ),
                      label: const Text(
                        "Xác thực bằng Vân tay/FaceID",
                        style: TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _showForgotPinDialog,
                    child: const Text(
                      'Quên mã PIN?',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

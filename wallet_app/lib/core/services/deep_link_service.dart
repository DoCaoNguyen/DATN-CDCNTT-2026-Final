import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'custom_http_client.dart';
import '../../features/merchant/screens/deep_link_payment_auth_screen.dart';
import '../../features/merchant/screens/deep_link_account_link_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/login/screens/login_phone_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  void initialize() {
    _appLinks = AppLinks();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    // Check initial link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        // Delay processing to allow UI to build
        Future.delayed(const Duration(seconds: 1), () {
          _processUri(uri);
        });
      }
    });

    // Listen to incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _processUri(uri);
      },
      onError: (err) {
        debugPrint('Error listening to deep links: $err');
      },
    );
  }

  void _processUri(Uri uri) async {
    debugPrint('Received Deep Link: $uri');
    if (uri.scheme == 'mio' && uri.host == 'pay') {
      final token = uri.queryParameters['token'];
      final amount = uri.queryParameters['amount'];
      final description = uri.queryParameters['description'];

      if (token != null) {
        final context = CustomHttpClient.navigatorKey.currentContext;
        if (context != null) {
          // Check if user is logged in
          const secureStorage = FlutterSecureStorage();
          final accessToken = await secureStorage.read(key: 'access_token');
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('user_id');

          if (accessToken != null &&
              accessToken.isNotEmpty &&
              userId != null &&
              userId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeepLinkPaymentAuthScreen(
                  qrToken: token,
                  amount: amount,
                  description: description,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vui lòng đăng nhập để tiếp tục thanh toán'),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
              (route) => false,
            );
          }
        }
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'custom_http_client.dart';
import '../utils/snackbar_utils.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  bool _isDisconnected = false;
  bool _isDialogShowing = false;

  void initialize() {
    // Kiểm tra trạng thái mạng ngay khi khởi động
    Future.delayed(const Duration(seconds: 1), () async {
      final initialResults = await Connectivity().checkConnectivity();
      _handleConnectivityChange(initialResults);
    });

    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _handleConnectivityChange(results);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    bool isNone = results.contains(ConnectivityResult.none) || results.isEmpty;

    if (isNone && !_isDisconnected) {
      _isDisconnected = true;
      _attemptShowNoInternetUI();
    } else if (!isNone && _isDisconnected) {
      _isDisconnected = false;
      _attemptHideNoInternetUI();
    }
  }

  void _attemptShowNoInternetUI() {
    final context = CustomHttpClient.navigatorKey.currentContext;
    if (context == null) {
      // Nếu UI chưa kịp dựng, thử lại sau 500ms
      Future.delayed(
        const Duration(milliseconds: 500),
        _attemptShowNoInternetUI,
      );
      return;
    }
    _showNoInternetDialog();
    _showNoInternetSnackbar();
  }

  void _attemptHideNoInternetUI() {
    final context = CustomHttpClient.navigatorKey.currentContext;
    if (context == null) {
      Future.delayed(
        const Duration(milliseconds: 500),
        _attemptHideNoInternetUI,
      );
      return;
    }

    if (_isDialogShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogShowing = false;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    SnackbarUtils.showSuccess(context, 'Đã khôi phục kết nối internet.');
  }

  void _showNoInternetDialog() {
    final context = CustomHttpClient.navigatorKey.currentContext;
    if (context == null) return;

    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Úi, mất kết nối rồi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Có thể do mạng yếu hoặc chưa kết nối internet.\nBạn hãy kiểm tra và thử lại nhé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _isDialogShowing = false;
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Đã hiểu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  void _showNoInternetSnackbar() {
    final context = CustomHttpClient.navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Mất kết nối internet'),
          ],
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(
          days: 1,
        ), // Keeps it active until dismissed or network returns
        action: SnackBarAction(
          label: 'Cài đặt',
          textColor: Colors.white,
          onPressed: () {
            // Can add open settings logic here if needed
          },
        ),
      ),
    );
  }
}

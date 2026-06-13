import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_config.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final _storage = const FlutterSecureStorage();

  // Global NavigatorKey for navigation and context-aware UI without BuildContext
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    options.headers['ngrok-skip-browser-warning'] = 'true';
    options.headers['Content-Type'] = 'application/json';

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final requestPath = err.requestOptions.path;

      // Check if the 401 error did NOT originate from the login or refresh-token endpoint
      if (!requestPath.contains('/auth/refresh-token') && !requestPath.contains('/auth/login')) {
        
        // 1. Concurrency Check: Check if another request has already refreshed the token
        final currentToken = await _storage.read(key: 'access_token');
        final requestToken = err.requestOptions.headers['Authorization']
            ?.toString()
            .replaceAll('Bearer ', '');

        if (currentToken != null && currentToken.isNotEmpty && currentToken != requestToken) {
          // Token was already updated by a previous request. Retry immediately with the new token.
          try {
            final response = await _retryRequest(err.requestOptions, currentToken);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(err);
          }
        }

        // 2. Perform token refresh
        final bool refreshSuccess = await _performTokenRefresh();
        if (refreshSuccess) {
          final newAccessToken = await _storage.read(key: 'access_token');
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            try {
              final response = await _retryRequest(err.requestOptions, newAccessToken);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(err);
            }
          }
        }
      }

      // 3. Handle refresh token failure or direct 401 on login/refresh
      await _handleSessionExpired();
      return handler.next(err);
    }

    return handler.next(err);
  }

  /// Refreshes the access token using the refresh token stored in secure storage.
  /// Bypasses the interceptor's dio instance using a fresh Dio instance to avoid deadlocks.
  Future<bool> _performTokenRefresh() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final refreshDio = Dio();
      final response = await refreshDio.post(
        ApiConfig.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final data = responseData['data'] ?? responseData;
        final newAccessToken = data['access_token'] ?? '';
        final newRefreshToken = data['refresh_token'] ?? '';

        if (newAccessToken.isNotEmpty) {
          await _storage.write(key: 'access_token', value: newAccessToken);
          if (newRefreshToken.isNotEmpty) {
            await _storage.write(key: 'refresh_token', value: newRefreshToken);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Retries the failed request with the new access token.
  Future<Response> _retryRequest(RequestOptions requestOptions, String newAccessToken) {
    final options = Options(
      method: requestOptions.method,
      headers: Map<String, dynamic>.from(requestOptions.headers)
        ..['Authorization'] = 'Bearer $newAccessToken',
    );

    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Clears secure storage and forces redirection to the login screen.
  Future<void> _handleSessionExpired() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'is_verified');

    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);

    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Phiên đăng nhập đã hết hạn hoặc tài khoản được đăng nhập ở thiết bị khác. Vui lòng đăng nhập lại.',
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}

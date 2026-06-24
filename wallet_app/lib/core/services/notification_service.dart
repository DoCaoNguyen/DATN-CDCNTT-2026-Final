import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import 'custom_http_client.dart';

/// Top-level background message handler.
/// BẮT BUỘC phải là top-level function (nằm ngoài class) và được đánh dấu với `@pragma('vm:entry-point')`
/// để tránh bị trình biên dịch loại bỏ (tree-shaking) khi build release.
///
/// [CƠ CHẾ HOẠT ĐỘNG TRÊN DART ISOLATE VÀ DOZE MODE]:
/// 1. **Dart Isolate độc lập**: Khi ứng dụng bị KILLED (đóng hoàn toàn) hoặc chạy ngầm, hệ điều hành (Android/iOS)
///    sẽ nhận tin nhắn từ Firebase Service gốc của máy. Sau đó, nó sẽ đánh thức một tiến trình Dart Isolate mới
///    chạy ngầm (background isolate) tách biệt hoàn toàn với main isolate của giao diện. Isolate này không có UI,
///    và hàm `_firebaseMessagingBackgroundHandler` sẽ được kích hoạt tại đây.
/// 2. **Vượt qua Doze Mode**: Trên Android, Doze mode hạn chế mạng và CPU để tiết kiệm pin. FCM giải quyết bằng
///    cách gửi gói tin với "high priority" (độ ưu tiên cao). Khi nhận được gói tin này, Google Play Services
///    (hoặc Apple APNs) sẽ tạm thời đưa ứng dụng vào một danh sách miễn trừ (whitelist) trong vài giây ngắn ngủi,
///    cấp quyền truy cập mạng và tài nguyên CPU để Isolate xử lý dữ liệu và đẩy Local Notification hiển thị ngay lập tức.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Bắt buộc phải khởi tạo Firebase bên trong Isolate chạy ngầm trước khi truy cập bất kỳ dịch vụ Firebase nào
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCvEj2SohLRzMSI3au6-E2RSrAy6QXxaeU",
      appId: "1:727424923764:android:eb4fbe4135efcf70d0b921",
      messagingSenderId: "727424923764",
      projectId: "wallet-app-loyalty",
      storageBucket: "wallet-app-loyalty.firebasestorage.app",
    ),
  );

  debugPrint("Background Isolate nhận được tin nhắn FCM: ${message.messageId}");

  // Nếu gói tin FCM ĐÃ CÓ sẵn payload `notification` (title, body),
  // hệ điều hành (Android/iOS) đã TỰ ĐỘNG hiển thị thông báo trên khay hệ thống.
  // Do đó, ta KHÔNG gọi `showLocalNotification` để tránh bị hiển thị thông báo kép (duplicate).
  if (message.notification == null) {
    // Chỉ tự tạo Local Notification nếu đây là Data-only message.
    await NotificationService.instance.showLocalNotification(message);
  }
}

class NotificationService {
  // Singleton Pattern
  NotificationService._privateConstructor();
  static final NotificationService instance =
      NotificationService._privateConstructor();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Lưu trữ token hiện tại của thiết bị
  String? _fcmToken;

  /// Khởi tạo Firebase Messaging và Flutter Local Notifications
  Future<void> initialize() async {
    // 1. Đăng ký background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Cấu hình Flutter Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationClick,
    );

    // Tạo Notification Channel mặc định cho Android (Bắt buộc từ Android 8.0+)
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }

    // 3. Đăng ký listener xử lý thông báo khi ứng dụng đang mở (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        "Foreground nhận được tin nhắn FCM: ${message.notification?.title}",
      );
      if (message.notification == null || Platform.isAndroid) {
        showLocalNotification(message);
      }
    });

    // Cấu hình hiển thị thông báo trực tiếp khi đang mở app (chỉ dành riêng cho iOS)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Lắng nghe thay đổi của Token FCM (khi token hết hạn và được tạo mới)
    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint("FCM Token được làm mới: $newToken");
      _sendTokenToServer();
    });

    // Lấy Token hiện tại khi khởi động
    try {
      _fcmToken = await _fcm.getToken();
      debugPrint("FCM Token hiện tại: $_fcmToken");
    } catch (e) {
      debugPrint("Không thể lấy FCM Token: $e");
    }
  }

  /// Xin quyền Push Notification (Hỗ trợ Android 13+ và iOS)
  Future<bool> requestPermissions() async {
    bool granted = false;

    if (Platform.isIOS) {
      // Yêu cầu quyền trên iOS thông qua FCM
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      granted = settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (Platform.isAndroid) {
      // Đăng ký quyền POST_NOTIFICATIONS cho Android 13+ (API 33)
      if (await Permission.notification.isDenied) {
        final PermissionStatus status = await Permission.notification.request();
        granted = status.isGranted;
      } else {
        granted = true;
      }
    }

    debugPrint(
      "Quyền Push Notification: ${granted ? 'Được cấp' : 'Bị từ chối'}",
    );
    return granted;
  }

  /// Cập nhật Token xác thực của người dùng và đồng bộ FCM Token lên Backend
  Future<void> registerUserToken(String userToken) async {
    await _sendTokenToServer();
  }

  /// Gửi FCM Token lên server Node.js (dùng CustomHttpClient để tự động refresh token khi cần)
  Future<void> _sendTokenToServer() async {
    if (_fcmToken == null) {
      debugPrint("Không thể gửi Token lên server: Thiếu FCMToken.");
      return;
    }

    // Kiểm tra có auth token không
    final prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('auth_token');
    if (authToken == null || authToken.isEmpty) {
      debugPrint("Không thể gửi Token lên server: Thiếu AuthToken.");
      return;
    }

    try {
      final client = CustomHttpClient();
      final response = await client.post(
        Uri.parse(ApiConfig.registerDevice),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcmToken': _fcmToken,
          'deviceName': _getDeviceModelName(),
          'deviceType': Platform.isAndroid
              ? 'ANDROID'
              : (Platform.isIOS ? 'IOS' : 'WEB'),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Đồng bộ FCM Token lên Backend thành công!");
      } else {
        debugPrint(
          "Đồng bộ FCM Token thất bại: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("Lỗi kết nối khi gửi FCM Token lên Backend: $e");
    }
  }

  /// Hiển thị Local Notification dựa trên Data Payload nhận được từ FCM
  Future<void> showLocalNotification(RemoteMessage message) async {
    // Ưu tiên parse từ `data` payload vì chúng ta ép hệ thống đánh thức app thông qua Data Payload
    final data = message.data;

    String title =
        data['title'] ?? message.notification?.title ?? 'Biến động số dư';
    String body =
        data['body'] ??
        message.notification?.body ??
        'Tài khoản của bạn vừa có sự thay đổi.';

    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'wallet_balance_channel_id', // ID trùng với Channel đã tạo
      'Biến Động Số Dư', // Tên Channel hiển thị trong Settings của điện thoại
      channelDescription: 'Thông báo biến động số dư ví điện tử',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode, // Đảm bảo ID thông báo là duy nhất
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(
        data,
      ), // Truyền data payload để xử lý khi click vào thông báo
    );
  }

  /// Tạo channel thông báo trên Android (bắt buộc cho Android 8.0+)
  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'wallet_balance_channel_id',
      'Biến Động Số Dư',
      description: 'Thông báo biến động số dư ví điện tử',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Xử lý sự kiện click vào thông báo trên điện thoại
  void _onNotificationClick(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        debugPrint(
          "Người dùng đã click vào thông báo. Dữ liệu nhận được: $data",
        );
        // Bạn có thể phát triển thêm logic điều hướng ở đây, ví dụ:
        // Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionHistoryScreen(...)));
      } catch (e) {
        debugPrint("Lỗi parse payload từ thông báo click: $e");
      }
    }
  }

  /// Lấy thông tin model thiết bị đơn giản
  String _getDeviceModelName() {
    return '${Platform.operatingSystem.toUpperCase()} Device';
  }
}

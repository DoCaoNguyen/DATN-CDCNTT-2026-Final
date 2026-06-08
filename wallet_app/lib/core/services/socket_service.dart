import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../constants/api_config.dart';

class SocketService {
  IO.Socket? socket;
  final String token;
  final Function(Map<String, dynamic>) onBalanceUpdate;

  SocketService({required this.token, required this.onBalanceUpdate});

  void connect() {
    final String url = ApiConfig.socketUrl;
    debugPrint("Kết nối đến Socket Server: $url");

    socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    socket?.onConnect((_) {
      debugPrint('Kết nối Socket.io thành công!');
    });

    socket?.onDisconnect((_) {
      debugPrint('Đã ngắt kết nối Socket.io!');
    });

    socket?.onConnectError((data) {
      debugPrint('Lỗi kết nối Socket.io: $data');
    });

    socket?.on('balance_update', (data) {
      debugPrint('Nhận sự kiện balance_update: $data');
      if (data is Map<String, dynamic>) {
        onBalanceUpdate(data);
      } else if (data is Map) {
        onBalanceUpdate(Map<String, dynamic>.from(data));
      }
    });
  }

  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
  }
}

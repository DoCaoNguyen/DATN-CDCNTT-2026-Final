import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService({String? token, Function(dynamic)? onBalanceUpdate}) {
    if (token != null) {
      _instance._token = token;
    }
    if (onBalanceUpdate != null) {
      _instance._onBalanceUpdate = onBalanceUpdate;
      if (_instance._socket != null) {
        _instance._socket!.off('balance_update');
        _instance._socket!.on(
          'balance_update',
          (data) => _instance._onBalanceUpdate?.call(data),
        );
      }
    }
    return _instance;
  }

  SocketService._internal();

  IO.Socket? _socket;
  String? _token;
  Function(dynamic)? _onBalanceUpdate;

  void connectSocket(String token) {
    _token = token;
    connect();
  }

  void connect() {
    if (_token == null) return;

    if (_socket != null) {
      // Cập nhật token mới nếu có
      _socket!.auth = {'token': _token};
      if (!_socket!.connected) {
        _socket!.connect();
      }
      return;
    }

    _socket = IO.io(ApiConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'ngrok-skip-browser-warning': 'true'},
      'auth': {'token': _token},
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Socket connected: ${_socket!.id}');
    });

    if (_onBalanceUpdate != null) {
      _socket!.on('balance_update', (data) => _onBalanceUpdate?.call(data));
    }

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    _socket!.onError((error) {
      debugPrint('Socket error: $error');
    });
  }

  void initSocket(String token) {
    connectSocket(token);
  }

  void updateToken(String newToken) {
    if (_token == newToken) return;
    _token = newToken;
    if (_socket != null) {
      _socket!.auth = {'token': _token};
      if (_socket!.connected) {
        _socket!.disconnect();
        _socket!.connect();
      }
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  void sendMessage(
    String receiverPhone,
    String content, {
    String messageType = 'TEXT',
  }) {
    if (_socket != null) {
      _socket!.emit('send_message', {
        'receiverPhone': receiverPhone,
        'content': content,
        'messageType': messageType,
      });
    } else {
      debugPrint('Socket is not initialized');
    }
  }

  void onReceiveMessage(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('receive_message', (data) {
        callback(data);
      });
    }
  }

  void offReceiveMessage() {
    if (_socket != null) {
      _socket!.off('receive_message');
    }
  }
}

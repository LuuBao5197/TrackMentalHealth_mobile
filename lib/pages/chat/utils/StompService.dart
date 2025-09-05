import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:trackmentalhealth/core/constants/chat_api.dart';

import '../../../core/constants/api_constants.dart' as api_constants;

class StompService {
  late StompClient _stompClient;
  bool _connected = false;

  // Thay đổi IP theo backend của bạn
  final ip = api_constants.ApiConstants.ipLocal;
  late final String _socketUrl = 'ws://${ip}:9999/ws';

  /// Khởi tạo kết nối STOMP
  void connect({
    required void Function(StompFrame frame) onConnect,
    void Function(dynamic error)? onError,
  }) {
    _stompClient = StompClient(
      config: StompConfig(
        url: _socketUrl,
        onConnect: (frame) {
          _connected = true;
          print("✅ STOMP connected");
          onConnect(frame);
        },
        beforeConnect: () async {
          print('🔄 Connecting to STOMP...');
          await Future.delayed(const Duration(milliseconds: 200));
        },
        onStompError: (frame) {
          print('❌ STOMP error: ${frame.body}');
        },
        onWebSocketError: (dynamic error) {
          print('❌ WebSocket error: $error');
          if (onError != null) onError(error);
        },
        onDisconnect: (_) {
          _connected = false;
          print('🔌 Disconnected from STOMP');
        },
      ),
    );

    _stompClient.activate();
  }

  /// Subscribe tới một topic (chat hoặc call)
  void subscribe(String destination, void Function(StompFrame frame) callback) {
    if (!_connected) {
      print('⚠️ Cannot subscribe, STOMP not connected');
      return;
    }
    print('🔔 Subscribing to $destination');
    _stompClient.subscribe(destination: destination, callback: callback);
  }

  /// Gửi tin nhắn chat
  void sendMessage(String destination, Map<String, dynamic> body) {
    _send(destination, body);
  }

  /// Gửi tín hiệu video call (offer, answer, candidate)
  void sendCallSignal(int sessionId, Map<String, dynamic> signal) {
    final destination = "/app/call/$sessionId";
    _send(destination, signal);
  }

  /// Hàm private gửi dữ liệu chung
  void _send(String destination, Map<String, dynamic> body) {
    if (!_connected) {
      print('⚠️ Cannot send, STOMP not connected');
      return;
    }

    final jsonBody = jsonEncode(body);
    print('📤 Sending to $destination: $jsonBody');

    _stompClient.send(
      destination: destination,
      body: jsonBody,
    );
  }

  /// Ngắt kết nối
  void disconnect() {
    if (_connected) {
      _stompClient.deactivate();
      _connected = false;
      print('🔌 STOMP manually disconnected');
    }
  }
}

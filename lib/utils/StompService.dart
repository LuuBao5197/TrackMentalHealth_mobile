import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../core/constants/api_constants.dart' as api_constants;

class StompService {
  late StompClient _stompClient;
  bool _connected = false;

  final ip = api_constants.ApiConstants.ipLocal;
  late final String _socketUrl = 'ws://$ip:9999/ws';

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
          print("✅ STOMP connected to $_socketUrl");
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
  void subscribe(String destination, void Function(dynamic parsed) callback) {
    if (!_connected) {
      print('⚠️ Cannot subscribe, STOMP not connected');
      return;
    }
    print('🔔 Subscribing to $destination');

    _stompClient.subscribe(
      destination: destination,
      callback: (frame) {
        try {
          dynamic raw;

          // Trường hợp frame có body (StompFrame)
          if (frame is StompFrame) {
            if (frame.body == null || frame.body!.isEmpty) {
              print("⚠️ Empty frame body from $destination");
              return;
            }
            print("📩 Raw frame body from $destination: ${frame.body}");
            raw = jsonDecode(frame.body!);
          }
          // Trường hợp lib trả thẳng Map hoặc String
          else if (frame is String) {
            print("📩 Raw string from $destination: $frame");
            raw = jsonDecode(frame as String);
          } else if (frame is Map<String, dynamic>) {
            print("📩 Raw map from $destination: $frame");
            raw = frame;
          } else {
            print("⚠️ Unexpected frame type: ${frame.runtimeType}");
            return;
          }

          // Trả về cho callback
          if (raw is Map<String, dynamic>) {
            callback(raw);
          } else {
            print("❌ Unexpected parsed type: ${raw.runtimeType}");
          }
        } catch (e, s) {
          print("❌ Error parsing JSON from $destination: $e");
          print(s);
        }
      },
    );
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

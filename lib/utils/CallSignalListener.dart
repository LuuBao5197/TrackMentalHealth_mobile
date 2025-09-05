import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../pages/chat/VideoCallPage/PrivateCallPage.dart';

class CallSignalListener extends StatefulWidget {
  final String sessionId;
  final String currentUserId;
  final String currentUserName;

  const CallSignalListener({
    Key? key,
    required this.sessionId,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  State<CallSignalListener> createState() => _CallSignalListenerState();
}

class _CallSignalListenerState extends State<CallSignalListener> {
  StompClient? stompClient;

  @override
  void initState() {
    super.initState();
    connectStomp();
  }

  void connectStomp() {
    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://localhost:8080/ws/websocket', // không SockJS
        onConnect: (StompFrame frame) {
          print('✅ Connected to STOMP');
          stompClient?.subscribe(
            destination: '/topic/call',
            callback: (frame) {
              print('📩 ${frame.body}');
            },
          );
        },
        onWebSocketError: (dynamic error) => print('⚠️ $error'),
      ),
    );

    stompClient?.activate();
  }
  void sendCallSignal(Map<String, dynamic> signal) {
    stompClient?.send(
      destination: "/app/call/${widget.sessionId}",
      body: jsonEncode(signal),
    );
  }

  void _handleCallSignal(Map<String, dynamic> signal) {
    print("📞 Nhận tín hiệu call: $signal");
    final type = signal["type"];

    switch (type) {
      case "CALL_REQUEST":
        if (signal["callerId"] != widget.currentUserId) {
          _showIncomingCallDialog(signal);
        }
        break;

      case "CALL_ACCEPTED":
        if (signal["calleeId"] != widget.currentUserId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PrivateCallPage(
                sessionId: widget.sessionId,
                currentUserId: widget.currentUserId,
                currentUserName: widget.currentUserName,
                isCaller: true,
              ),
            ),
          );
        }
        break;

      case "CALL_REJECTED":
        Fluttertoast.showToast(msg: "📵 Call was rejected");
        Navigator.popUntil(context, ModalRoute.withName("/chat/${widget.sessionId}"));
        break;

      case "CALL_ENDED":
        Fluttertoast.showToast(msg: "📴 Call ended");
        Navigator.popUntil(context, ModalRoute.withName("/chat/${widget.sessionId}"));
        break;

      default:
        break;
    }
  }

  void _showIncomingCallDialog(Map<String, dynamic> signal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text("${signal["callerName"]} is calling..."),
          actions: [
            TextButton(
              onPressed: () {
                sendCallSignal({
                  "type": "CALL_ACCEPTED",
                  "calleeId": widget.currentUserId,
                  "sessionId": widget.sessionId,
                });
                Navigator.pop(context); // đóng dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PrivateCallPage(
                      sessionId: widget.sessionId,
                      currentUserId: widget.currentUserId,
                      currentUserName: widget.currentUserName,
                      isCaller: false,
                    ),
                  ),
                );
              },
              child: const Text("Accept"),
            ),
            TextButton(
              onPressed: () {
                sendCallSignal({
                  "type": "CALL_REJECTED",
                  "calleeId": widget.currentUserId,
                  "sessionId": widget.sessionId,
                });
                Navigator.pop(context);
              },
              child: const Text("Reject", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // không render UI, chỉ lắng nghe
  }
}

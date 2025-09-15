import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trackmentalhealth/utils/showToast.dart';

import '../pages/chat/VideoCallPage/PrivateCallPage.dart';
import 'StompService.dart';

class CallSignalListener extends StatefulWidget {
  final String sessionId;
  final String currentUserId;
  final String currentUserName;
  final StompService stompService;

  const CallSignalListener({
    Key? key,
    required this.sessionId,
    required this.currentUserId,
    required this.currentUserName,
    required this.stompService,
  }) : super(key: key);

  @override
  State<CallSignalListener> createState() => _CallSignalListenerState();
}

class _CallSignalListenerState extends State<CallSignalListener> {
  @override
  void initState() {
    super.initState();

    widget.stompService.connect(onConnect: (frame) {
      widget.stompService.subscribe("/topic/call", (signal) {
        _handleCallSignal(signal);
      });
    });
  }

  void _handleCallSignal(Map<String, dynamic> signal) {
    print("📞 Nhận tín hiệu: $signal");

    switch (signal["type"]) {
      case "CALL_REQUEST":
        if (signal["calleeId"] == widget.currentUserId) {
          _showIncomingCallDialog(signal);
        }
        break;

      case "CALL_ACCEPTED":
        if (signal["callerId"] == widget.currentUserId) {
          // caller join call
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
        if (signal["callerId"] == widget.currentUserId) {
          showToast("📵 Call was rejected",'error');
          Navigator.popUntil(context, ModalRoute.withName("/chat/${widget.sessionId}"));
        }
        break;

      case "CALL_ENDED":
        showToast("📵 Call ended",'warning');
        Navigator.popUntil(context, ModalRoute.withName("/chat/${widget.sessionId}"));
        break;
    }
  }

  void _showIncomingCallDialog(Map<String, dynamic> signal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("${signal["callerName"]} is calling..."),
        actions: [
          TextButton(
            onPressed: () {
              widget.stompService.sendCallSignal(
                int.parse(widget.sessionId),
                {
                  "type": "CALL_ACCEPTED",
                  "callerId": signal["callerId"],
                  "calleeId": widget.currentUserId,
                  "sessionId": widget.sessionId,
                },
              );
              Navigator.pop(context);
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
              widget.stompService.sendCallSignal(
                int.parse(widget.sessionId),
                {
                  "type": "CALL_REJECTED",
                  "callerId": signal["callerId"],
                  "calleeId": widget.currentUserId,
                  "sessionId": widget.sessionId,
                },
              );
              Navigator.pop(context);
            },
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.stompService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

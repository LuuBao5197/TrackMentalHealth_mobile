import 'package:flutter/material.dart';
import 'package:trackmentalhealth/utils/CallSignalManager.dart';
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
    CallSignalManager.handleCallSignal(
      signal: signal,
      currentUserId: widget.currentUserId,
      currentUserName: widget.currentUserName,
      sessionId: widget.sessionId,
      stompService: widget.stompService,
      context: context,
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

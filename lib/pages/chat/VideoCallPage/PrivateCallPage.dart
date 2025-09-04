import 'dart:math';
import 'package:flutter/material.dart';
import 'package:trackmentalhealth/helper/ZegoService.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class PrivateCallPage extends StatefulWidget {
  final String? sessionId;
  final String currentUserId;
  final String currentUserName;
  final bool isCaller;

  const PrivateCallPage({
    super.key,
    this.sessionId,
    required this.currentUserId,
    required this.currentUserName,
    required this.isCaller,
  });

  @override
  State<PrivateCallPage> createState() => _PrivateCallPageState();
}

class _PrivateCallPageState extends State<PrivateCallPage> {
  late final String callID;
  late final String userID;
  late final String userName;

  @override
  void initState() {
    super.initState();
    _initializeCallData();
  }

  void _initializeCallData() {
    // Sử dụng sessionId làm callID nếu có, nếu không tạo ngẫu nhiên
    callID = widget.sessionId ?? _generateRandomID(100000, 999999);
    userID = widget.currentUserId; // Sử dụng currentUserId đã truyền vào
    userName = widget.currentUserName; // Sử dụng currentUserName đã truyền vào
  }

  String _generateRandomID(int min, int max) {
    return (min + Random().nextInt(max - min + 1)).toString();
  }

  Future<bool> _confirmExit() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Thoát cuộc gọi"),
        content: const Text("Bạn có chắc chắn muốn thoát cuộc gọi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Đồng ý"),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _confirmExit()) {
          if (mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ZegoUIKitPrebuiltCall(
                appID: ZegoService.appID,
                appSign: ZegoService.appSign,
                userID: userID,
                userName: userName,
                callID: callID,
                config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  ..topMenuBarConfig = ZegoTopMenuBarConfig(isVisible: false)
                  ..bottomMenuBarConfig = ZegoBottomMenuBarConfig(
                    buttons: [
                      ZegoMenuBarButtonName.toggleMicrophoneButton,
                      ZegoMenuBarButtonName.toggleCameraButton,
                      ZegoMenuBarButtonName.switchCameraButton,
                      ZegoMenuBarButtonName.chatButton,
                      ZegoMenuBarButtonName.hangUpButton,
                    ],
                  ),
              );
            },
          ),
        ),
      ),
    );
  }
}
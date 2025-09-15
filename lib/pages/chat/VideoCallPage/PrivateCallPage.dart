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
    required this.isCaller, //

  });
  @override
  State<PrivateCallPage> createState() => _PrivateCallPageState();
}

class _PrivateCallPageState extends State<PrivateCallPage> {
  late final String callID;

  @override
  void initState() {
    super.initState();
    callID = widget.sessionId ?? _generateRandomID(100000, 999999);
  }

  String _generateRandomID(int min, int max) {
    return (min + Random().nextInt(max - min + 1)).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: ZegoService.appID,           // kiểm tra appID ở ZegoService.dart
          appSign: ZegoService.appSign,       // kiểm tra appSign có đúng không
          userID: widget.currentUserId,
          userName: widget.currentUserName,
          callID: callID,
          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            ..topMenuBar = ZegoCallTopMenuBarConfig(isVisible: false)
            ..bottomMenuBar = ZegoCallBottomMenuBarConfig(
              buttons: [
                ZegoCallMenuBarButtonName.toggleMicrophoneButton,
                ZegoCallMenuBarButtonName.toggleCameraButton,
                ZegoCallMenuBarButtonName.switchCameraButton,
                ZegoCallMenuBarButtonName.hangUpButton,
              ],
            ),
        ),
      ),
    );
  }
}

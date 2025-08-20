import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class ChatVideoGroupPage extends StatelessWidget {
  final String callID;
  final String userId;
  final String userName;

  const ChatVideoGroupPage({
    Key? key,
    required this.callID,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: 1208118836, // AppID lấy từ Zego Console
        appSign: "2ce327a5bf092634cba9d35ff700ddd8", // AppSign từ Zego Console
        userID: userId,
        userName: userName,
        callID: callID,
        config: ZegoUIKitPrebuiltCallConfig.groupVideoCall()
          ..onOnlySelfInRoom = (context) {
            // Thoát khi chỉ còn 1 mình
            Navigator.pop(context);
          },
      ),
    );
  }
}

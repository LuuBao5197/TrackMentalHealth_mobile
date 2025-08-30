import 'dart:math';
import 'package:flutter/material.dart';
import 'package:trackmentalhealth/helper/ZegoService.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';

class PublicCallPage extends StatefulWidget {
  final String? paramRoomID;

  const PublicCallPage({Key? key, this.paramRoomID}) : super(key: key);

  @override
  State<PublicCallPage> createState() => _PublicCallPageState();
}

class _PublicCallPageState extends State<PublicCallPage> {
  late String roomID;
  late String userID;
  late String userName;

  @override
  void initState() {
    super.initState();

    // Lấy roomID từ param hoặc random
    roomID = widget.paramRoomID ?? (100000 + Random().nextInt(900000)).toString();

    // Lấy userID từ backend/session (ở đây random cho demo)
    userID = (Random().nextInt(1000000)).toString();
    userName = "Guest ${userID.substring(userID.length - 4)}";
  }

  void _confirmExit() async {
    final confirm = await showDialog<bool>(
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
    );

    if (confirm == true) {
      Navigator.pop(context); // hoặc Navigator.pushReplacementNamed(context, "/user/chat/list")
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ZegoUIKitPrebuiltVideoConference(
          appID: ZegoService.appID, // lấy từ ZEGOCLOUD console
          appSign: ZegoService.appSign, // lấy từ ZEGOCLOUD console
          conferenceID: roomID,
          userID: userID,
          userName: userName,
          config: ZegoUIKitPrebuiltVideoConferenceConfig(),
        ),
      ),
    );
  }
}

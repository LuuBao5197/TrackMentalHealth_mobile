import 'dart:math';
import 'package:flutter/material.dart';
import 'package:trackmentalhealth/helper/ZegoService.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';

class PublicCallPage extends StatefulWidget {
  const PublicCallPage({Key? key}) : super(key: key);

  @override
  State<PublicCallPage> createState() => _PublicCallPageState();
}

class _PublicCallPageState extends State<PublicCallPage> {
  final String roomID = "public_room"; // phòng chung test
  late String userID;
  late String userName;

  @override
  void initState() {
    super.initState();

    // random user ID cho test
    userID = (Random().nextInt(1000000)).toString();
    userName = "Guest_${userID.substring(userID.length - 4)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Zego Test Public Call")),
      body: SafeArea(
        child: ZegoUIKitPrebuiltVideoConference(
          appID: ZegoService.appID,
          appSign: ZegoService.appSign,
          conferenceID: roomID,
          userID: userID,
          userName: userName,
          config: ZegoUIKitPrebuiltVideoConferenceConfig(
            // bật camera + mic khi join
            turnOnCameraWhenJoining: true,
            turnOnMicrophoneWhenJoining: true,

            // tắt hộp thoại confirm khi leave
            onLeaveConfirmation: (BuildContext context) async {
              return true; // luôn cho phép thoát, không hỏi confirm
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import '../../../helper/ZegoService.dart';

class PrivateCallPage extends StatefulWidget {
  final String sessionId;        // roomID
  final String currentUserId;
  final String currentUserName;
  final bool isCaller;

  const PrivateCallPage({
    Key? key,
    required this.sessionId,
    required this.currentUserId,
    required this.currentUserName,
    required this.isCaller,
  }) : super(key: key);

  @override
  State<PrivateCallPage> createState() => _PrivateCallPageState();
}

class _PrivateCallPageState extends State<PrivateCallPage> {
  Widget? localView;
  int? localViewID;
  Widget? remoteView;
  int? remoteViewID;

  @override
  void initState() {
    super.initState();
    _startListenEvent();
    _loginRoom();
  }

  @override
  void dispose() {
    _stopListenEvent();
    _logoutRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isCaller ? "Calling..." : "Incoming call")),
      body: Stack(
        children: [
          localView ?? Container(color: Colors.black),
          Positioned(
            top: 40,
            right: 20,
            width: 120,
            child: AspectRatio(
              aspectRatio: 9.0 / 16.0,
              child: remoteView ?? Container(color: Colors.grey),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.call_end, size: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loginRoom() async {
    final user = ZegoUser(widget.currentUserId, widget.currentUserName);
    final roomID = widget.sessionId;

    ZegoRoomConfig roomConfig = ZegoRoomConfig.defaultConfig()
      ..isUserStatusNotify = true;

    await ZegoExpressEngine.instance
        .loginRoom(roomID, user, config: roomConfig)
        .then((res) {
      if (res.errorCode == 0) {
        _startPreview();
        _startPublish();
      } else {
        debugPrint("❌ loginRoom failed: ${res.errorCode}");
      }
    });
  }

  Future<void> _logoutRoom() async {
    _stopPreview();
    _stopPublish();
    await ZegoExpressEngine.instance.logoutRoom(widget.sessionId);
  }


  void _startListenEvent() {
    ZegoExpressEngine.onRoomUserUpdate =
        (roomID, updateType, List<ZegoUser> userList) {
      debugPrint("👥 onRoomUserUpdate: $updateType, users: ${userList.map((e) => e.userID)}");
    };

    ZegoExpressEngine.onRoomStreamUpdate =
        (roomID, updateType, List<ZegoStream> streamList, _) {
      debugPrint("🎥 onRoomStreamUpdate: $updateType, streams: ${streamList.map((e) => e.streamID)}");

      if (updateType == ZegoUpdateType.Add) {
        for (var stream in streamList) {
          _startPlayStream(stream.streamID);
        }
      } else {
        for (var stream in streamList) {
          _stopPlayStream(stream.streamID);
        }
      }
    };
  }

  void _stopListenEvent() {
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
  }

  Future<void> _startPreview() async {
    await ZegoExpressEngine.instance.createCanvasView((viewID) {
      localViewID = viewID;
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPreview(canvas: canvas);
    }).then((widget) {
      setState(() => localView = widget);
    });
  }

  Future<void> _stopPreview() async {
    ZegoExpressEngine.instance.stopPreview();
    if (localViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(localViewID!);
      setState(() {
        localView = null;
        localViewID = null;
      });
    }
  }

  Future<void> _startPublish() async {
    String streamID = "${widget.sessionId}_${widget.currentUserId}_call";
    await ZegoExpressEngine.instance.startPublishingStream(streamID);
  }

  Future<void> _stopPublish() async {
    await ZegoExpressEngine.instance.stopPublishingStream();
  }

  Future<void> _startPlayStream(String streamID) async {
    await ZegoExpressEngine.instance.createCanvasView((viewID) {
      remoteViewID = viewID;
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    }).then((widget) {
      setState(() => remoteView = widget);
    });
  }

  Future<void> _stopPlayStream(String streamID) async {
    ZegoExpressEngine.instance.stopPlayingStream(streamID);
    if (remoteViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(remoteViewID!);
      setState(() {
        remoteViewID = null;
        remoteView = null;
      });
    }
  }
}

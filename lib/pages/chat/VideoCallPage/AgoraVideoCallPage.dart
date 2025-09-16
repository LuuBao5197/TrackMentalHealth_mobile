import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:trackmentalhealth/helper/AgoraService.dart';
import 'package:trackmentalhealth/utils/CallInitiator.dart';

class AgoraVideoCallPage extends StatefulWidget {
  final String channelName;
  final int uid;
  final String callerName;
  final String calleeName;
  final bool isCaller;

  const AgoraVideoCallPage({
    Key? key,
    required this.channelName,
    required this.uid,
    required this.callerName,
    required this.calleeName,
    required this.isCaller,
  }) : super(key: key);

  @override
  State<AgoraVideoCallPage> createState() => _AgoraVideoCallPageState();
}

class _AgoraVideoCallPageState extends State<AgoraVideoCallPage> {
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerEnabled = true;
  String? _error;
  int? _remoteUid;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      await AgoraService.initialize();
      _setupAgoraEventHandlers();
      await AgoraService.joinChannel(
        channelName: widget.channelName,
        uid: widget.uid,
      );
      
      setState(() {
        _isInitialized = true;
        _isJoined = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _setupAgoraEventHandlers() {
    AgoraService.engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('✅ Successfully joined channel: ${connection.channelId}');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('👤 Remote user joined: $remoteUid');
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          print('👤 Remote user left: $remoteUid, reason: $reason');
          setState(() {
            _remoteUid = null;
          });
        },
        onError: (ErrorCodeType err, String msg) {
          print('❌ Agora error: $err - $msg');
          setState(() {
            _error = 'Agora error: $msg';
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    AgoraService.leaveChannel();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    AgoraService.muteLocalAudio(_isMuted);
  }

  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    AgoraService.muteLocalVideo(!_isVideoEnabled);
  }

  void _switchCamera() {
    AgoraService.switchCamera();
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
    // Agora sẽ tự động sử dụng speaker khi không có headphone
  }

  void _endCall() {
    AgoraService.leaveChannel();
    
    // Gửi signal kết thúc cuộc gọi nếu cần
    // CallInitiator.endCall(...) có thể được gọi từ đây nếu cần
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 64),
              SizedBox(height: 16),
              Text(
                'Lỗi kết nối',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video views
            _buildVideoViews(),
            
            // Call info
            _buildCallInfo(),
            
            // Control buttons
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoViews() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Remote video (full screen)
          if (_remoteUid != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: AgoraService.engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            ),
          
          // Local video (picture-in-picture)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: AgoraService.engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallInfo() {
    return Positioned(
      top: 50,
      left: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isCaller ? widget.calleeName : widget.callerName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _isJoined ? 'Đã kết nối' : 'Đang kết nối...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            color: _isMuted ? Colors.red : Colors.white,
            onPressed: _toggleMute,
          ),
          
          // Video toggle button
          _buildControlButton(
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            color: _isVideoEnabled ? Colors.white : Colors.red,
            onPressed: _toggleVideo,
          ),
          
          // Switch camera button
          _buildControlButton(
            icon: Icons.switch_camera,
            color: Colors.white,
            onPressed: _switchCamera,
          ),
          
          // Speaker button
          _buildControlButton(
            icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
            color: Colors.white,
            onPressed: _toggleSpeaker,
          ),
          
          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            onPressed: _endCall,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(
          icon,
          color: color,
          size: 30,
        ),
      ),
    );
  }
}

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trackmentalhealth/config/agora_config.dart';

class AgoraService {
  static RtcEngine? _engine;
  static bool _isInitialized = false;
  
  // Sử dụng App ID từ config
  static String get _appId => AgoraConfig.appId;

  /// Khởi tạo Agora RTC Engine
  static Future<void> initialize() async {
    if (_isInitialized) return;


    try {
      // Yêu cầu quyền camera và microphone
      await _requestPermissions();
      
      // Tạo RTC Engine instance
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      
      // Thêm cấu hình để sử dụng test mode
      await _engine!.setLogLevel(LogLevel.logLevelInfo);
      // Không set log file vì gây lỗi
      
      // Bật video
      await _engine!.enableVideo();
      
      // Bật audio
      await _engine!.enableAudio();
      
      // Cấu hình video encoder
      await _engine!.setVideoEncoderConfiguration(
        VideoEncoderConfiguration(
          dimensions: VideoDimensions(
            width: AgoraConfig.videoWidth, 
            height: AgoraConfig.videoHeight
          ),
          frameRate: AgoraConfig.frameRate,
          bitrate: AgoraConfig.bitrate,
          orientationMode: OrientationMode.orientationModeFixedPortrait,
        ),
      );
      
      _isInitialized = true;
      print('✅ Agora RTC Engine initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Agora RTC Engine: $e');
      rethrow;
    }
  }
  
  /// Yêu cầu quyền camera và microphone
  static Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();
    
    if (cameraStatus != PermissionStatus.granted) {
      throw 'Camera permission is required for video call';
    }
    
    if (microphoneStatus != PermissionStatus.granted) {
      throw 'Microphone permission is required for video call';
    }
    
    print('✅ Camera and microphone permissions granted');
  }
  
  /// Tham gia channel
  static Future<void> joinChannel({
    required String channelName,
    required int uid,
    String? token,
  }) async {
    if (_engine == null) {
      throw 'Agora RTC Engine not initialized';
    }
    
    try {
      // Thêm event listener để xử lý lỗi
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onError: (ErrorCodeType err, String msg) {
            print('❌ Agora error: $err - $msg');
          },
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('✅ Successfully joined channel: ${connection.channelId}');
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('✅ Remote user joined: $remoteUid');
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('ℹ️ Remote user left: $remoteUid, reason: $reason');
          },
        ),
      );
      
      await _engine!.joinChannel(
        token: '', // Sử dụng empty string cho App ID mode
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          publishCameraTrack: true,
        ),
      );
      print('✅ Joined channel: $channelName with uid: $uid');
    } catch (e) {
      print('❌ Failed to join channel: $e');
      rethrow;
    }
  }
  
  /// Rời khỏi channel
  ///
  static Future<void> leaveChannel() async {
    if (_engine == null) return;
    try {
      await _engine!.leaveChannel();
      print('✅ Left channel successfully');
    } catch (e) {
      print('❌ Failed to leave channel: $e');
    }
  }
  
  /// Bật/tắt microphone
  static Future<void> muteLocalAudio(bool muted) async {
    if (_engine == null) return;
    
    try {
      await _engine!.muteLocalAudioStream(muted);
      print('✅ Local audio ${muted ? 'muted' : 'unmuted'}');
    } catch (e) {
      print('❌ Failed to toggle audio: $e');
    }
  }
  
  /// Bật/tắt camera
  static Future<void> muteLocalVideo(bool muted) async {
    if (_engine == null) return;
    
    try {
      await _engine!.muteLocalVideoStream(muted);
      print('✅ Local video ${muted ? 'muted' : 'unmuted'}');
    } catch (e) {
      print('❌ Failed to toggle video: $e');
    }
  }
  
  /// Chuyển đổi camera trước/sau
  static Future<void> switchCamera() async {
    if (_engine == null) return;
    
    try {
      await _engine!.switchCamera();
      print('✅ Camera switched');
    } catch (e) {
      print('❌ Failed to switch camera: $e');
    }
  }
  
  /// Lấy RTC Engine instance
  static RtcEngine? get engine => _engine;
  
  /// Kiểm tra trạng thái khởi tạo
  static bool get isInitialized => _isInitialized;
  
  /// Dọn dẹp resources
  static Future<void> dispose() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
      print('✅ Agora RTC Engine disposed');
    }
  }
}

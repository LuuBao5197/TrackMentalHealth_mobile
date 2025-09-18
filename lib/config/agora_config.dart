class AgoraConfig {

  // Sử dụng App ID test của Agora (không cần token)
  static const String appId = '93206addcb2a486b9460a5c95ba8b7c4';
  
  // Không cần token

  // Default channel name prefix
  static const String channelPrefix = 'trackmentalhealth_';
  
  // Video configuration
  static const int videoWidth = 640;
  static const int videoHeight = 480;
  static const int frameRate = 15;
  static const int bitrate = 0; // 0 = auto
  
  // Audio configuration
  static const int sampleRate = 48000;
  static const int channels = 1; // mono
  static const int bitrateAudio = 48; // kbps
}



class AgoraConfig {
  // Thay thế bằng App ID của bạn từ Agora Console
  // Đăng ký tại: https://console.agora.io/
  static const String appId = 'a1673d21476a449e9741145e165799ba';
  
  // Token server URL (nếu sử dụng token authentication)
  static const String tokenServerUrl = '8358e972d4b348ff89c5fda61273196c';
  
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


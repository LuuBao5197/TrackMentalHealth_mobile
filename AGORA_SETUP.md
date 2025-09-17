# 🎥 Hướng dẫn Setup Agora Video Call

## 📋 Tổng quan
Dự án đã được tích hợp Agora Flutter SDK để thay thế WebRTC. Agora cung cấp video call ổn định và dễ sử dụng hơn.

## 🚀 Các bước setup

### 1. Đăng ký Agora Account
1. Truy cập [Agora Console](https://console.agora.io/)
2. Đăng ký tài khoản miễn phí
3. Tạo project mới
4. Lấy **App ID** từ project

### 2. Cấu hình App ID
1. Mở file `lib/config/agora_config.dart`
2. Thay thế `YOUR_AGORA_APP_ID` bằng App ID thực tế:

```dart
static const String appId = 'your_actual_app_id_here';
```

### 3. Cài đặt dependencies
```bash
flutter pub get
```

### 4. Build và test
```bash
flutter run
```

## 📱 Tính năng đã tích hợp

### ✅ Video Call Features
- **Video call 1-1**: Gọi video giữa 2 người
- **Audio controls**: Bật/tắt microphone
- **Video controls**: Bật/tắt camera
- **Camera switch**: Chuyển đổi camera trước/sau
- **Speaker control**: Bật/tắt loa ngoài
- **Call UI**: Giao diện gọi video đẹp mắt

### ✅ Technical Features
- **Agora RTC Engine**: Engine video call ổn định
- **Permission handling**: Tự động xin quyền camera/mic
- **Error handling**: Xử lý lỗi tốt
- **Resource management**: Tự động dọn dẹp resources

## 🔧 Cấu hình nâng cao

### Video Quality
Chỉnh sửa trong `lib/config/agora_config.dart`:
```dart
static const int videoWidth = 640;    // Độ rộng video
static const int videoHeight = 480;   // Độ cao video
static const int frameRate = 15;      // FPS
```

### Audio Quality
```dart
static const int sampleRate = 48000;  // Tần số mẫu
static const int channels = 1;        // Mono/Stereo
static const int bitrateAudio = 48;   // Bitrate audio (kbps)
```

## 🎯 Sử dụng

### Khởi tạo call
```dart
// Trong CallSignalListener
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AgoraVideoCallPage(
      channelName: 'session_123',
      uid: 12345,
      callerName: 'John Doe',
      calleeName: 'Jane Smith',
      isCaller: true,
    ),
  ),
);
```b

### API Methods
```dart
// Khởi tạo Agora
await AgoraService.initialize();

// Tham gia channel
await AgoraService.joinChannel(
  channelName: 'channel_name',
  uid: 12345,
);

// Rời khỏi channel
await AgoraService.leaveChannel();

// Bật/tắt mic
await AgoraService.muteLocalAudio(true);

// Bật/tắt camera
await AgoraService.muteLocalVideo(true);

// Chuyển camera
await AgoraService.switchCamera();
```

## 🐛 Troubleshooting

### Lỗi thường gặp

1. **"App ID not found"**
   - Kiểm tra App ID trong `agora_config.dart`
   - Đảm bảo App ID đúng và active

2. **"Permission denied"**
   - Kiểm tra permissions trong `AndroidManifest.xml`
   - Test trên thiết bị thật (không phải emulator)

3. **"Failed to join channel"**
   - Kiểm tra kết nối internet
   - Kiểm tra channel name và uid

### Debug
Bật debug logs:
```dart
// Trong AgoraService.initialize()
await _engine!.setLogLevel(LogLevel.logLevelDebug);
```

## 📊 So sánh với WebRTC

| Tính năng | WebRTC | Agora |
|-----------|--------|-------|
| Setup | Phức tạp | Đơn giản |
| UI Components | Tự code | Có sẵn |
| Stability | Trung bình | Cao |
| Documentation | Hạn chế | Tốt |
| Support | Community | Official |
| Cost | Free | Free tier |

## 🎉 Kết luận

Agora đã được tích hợp thành công! Video call giờ đây sẽ:
- ✅ Ổn định hơn
- ✅ Dễ sử dụng hơn  
- ✅ Có UI đẹp hơn
- ✅ Ít lỗi hơn

Chỉ cần thay App ID và chạy `flutter run` là có thể sử dụng ngay!


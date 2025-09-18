# 🔌 Hướng dẫn WebSocket Connection

## 🎯 Tổng quan
Hướng dẫn này giải thích cách WebSocket (STOMP) hoạt động và cách xử lý kết nối trong ứng dụng video call.

## 🚀 Các cải thiện đã thêm

### ✅ **Tự động kết nối lại**
- **Retry logic**: Thử kết nối lại tối đa 5 lần
- **Exponential backoff**: Tăng dần thời gian chờ giữa các lần thử
- **Auto-reconnect**: Tự động kết nối lại khi mất kết nối

### ✅ **Heartbeat monitoring**
- **Ping/Pong**: Gửi heartbeat mỗi 30 giây
- **Connection health**: Kiểm tra sức khỏe kết nối
- **Auto-recovery**: Tự động phục hồi khi phát hiện mất kết nối

### ✅ **Subscription management**
- **Auto-resubscribe**: Tự động subscribe lại khi kết nối lại
- **Persistent subscriptions**: Lưu trữ subscriptions để resubscribe
- **Error handling**: Xử lý lỗi subscription tốt hơn

### ✅ **Connection status UI**
- **Real-time indicator**: Hiển thị trạng thái kết nối real-time
- **Connection dialog**: Dialog chi tiết về trạng thái kết nối
- **Manual reconnect**: Nút kết nối lại thủ công

## 🔧 Cách hoạt động

### **1. Kết nối ban đầu**
```dart
stompService.connect(
  onConnect: (frame) {
    print("✅ Đã kết nối");
    // Subscribe các topics
  },
  onError: (error) {
    print("❌ Lỗi kết nối: $error");
  },
);
```

### **2. Tự động kết nối lại**
- Khi mất kết nối → Tự động thử kết nối lại
- Thử tối đa 5 lần với delay 3 giây
- Resubscribe tất cả topics đã đăng ký

### **3. Heartbeat monitoring**
- Gửi ping mỗi 30 giây
- Phát hiện mất kết nối nhanh chóng
- Tự động kết nối lại khi cần

### **4. UI Status**
- **Xanh**: Đã kết nối
- **Cam**: Đang kết nối
- **Đỏ**: Mất kết nối

## 📱 Cách sử dụng

### **Trong ChatDetail**
```dart
// Hiển thị trạng thái kết nối trong AppBar
ConnectionStatusWidget(
  stompService: stompService,
  showInAppBar: true,
)

// Kiểm tra kết nối trước khi gọi video
if (!stompService.isConnected) {
  // Hiển thị thông báo lỗi
  return;
}
```

### **Kiểm tra trạng thái**
```dart
// Kiểm tra đã kết nối
if (stompService.isConnected) {
  // Gửi dữ liệu
}

// Kiểm tra đang kết nối
if (stompService.isConnecting) {
  // Hiển thị loading
}

// Lấy số lần thử kết nối
int attempts = stompService.reconnectAttempts;
```

### **Kết nối lại thủ công**
```dart
// Kết nối lại ngay lập tức
stompService.reconnect();

// Reset số lần thử
stompService.resetReconnectAttempts();
```

## 🐛 Troubleshooting

### **Lỗi thường gặp**

1. **"Không thể gửi, chưa kết nối STOMP"**
   - Kiểm tra kết nối internet
   - Kiểm tra server WebSocket có chạy không
   - Thử kết nối lại thủ công

2. **"Đã thử kết nối 5 lần, dừng lại"**
   - Kiểm tra URL WebSocket
   - Kiểm tra server có hoạt động không
   - Reset và thử lại

3. **"Signal không hợp lệ"**
   - Kiểm tra subscription có đúng không
   - Kiểm tra format dữ liệu gửi
   - Kiểm tra server có xử lý đúng không

### **Debug logs**
Tìm các log quan trọng:
```
🔄 [StompService] Kết nối lần 1/5...
✅ [StompService] Đã kết nối thành công
🔔 [StompService] Subscribing to /topic/call/123
📤 [StompService] Gửi đến /app/call/123: {...}
❌ [StompService] WebSocket error: ...
```

## ⚙️ Cấu hình

### **Thay đổi retry settings**
```dart
// Trong StompService.dart
static const int _maxReconnectAttempts = 5;  // Số lần thử tối đa
static const Duration _reconnectDelay = Duration(seconds: 3);  // Delay giữa các lần thử
static const Duration _heartbeatInterval = Duration(seconds: 30);  // Interval heartbeat
```

### **Thay đổi WebSocket URL**
```dart
// Trong StompService.dart
final ip = api_constants.ApiConstants.ipLocal;
late final String _socketUrl = 'ws://$ip:9999/ws';
```

## 🎯 Best Practices

### **1. Luôn kiểm tra kết nối trước khi gửi**
```dart
if (stompService.isConnected) {
  stompService.sendMessage(destination, data);
} else {
  // Hiển thị thông báo lỗi hoặc thử kết nối lại
}
```

### **2. Xử lý lỗi gracefully**
```dart
try {
  stompService.sendCallSignal(sessionId, signal);
} catch (e) {
  // Xử lý lỗi, có thể thử lại hoặc hiển thị thông báo
}
```

### **3. Dispose resources đúng cách**
```dart
@override
void dispose() {
  stompService.dispose();  // Dọn dẹp tất cả resources
  super.dispose();
}
```

### **4. Monitor connection status**
```dart
// Sử dụng ConnectionStatusWidget để hiển thị trạng thái
ConnectionStatusWidget(stompService: stompService)
```

## 📊 Monitoring

### **Connection metrics**
- **Uptime**: Thời gian kết nối liên tục
- **Reconnect attempts**: Số lần thử kết nối lại
- **Failed sends**: Số lần gửi thất bại
- **Heartbeat failures**: Số lần heartbeat thất bại

### **Performance tips**
- Sử dụng connection pooling nếu có nhiều connections
- Implement message queuing khi mất kết nối
- Cache messages để gửi lại khi kết nối lại

## 🚀 Kết quả

Sau khi áp dụng các cải thiện:

✅ **Kết nối ổn định hơn** - Tự động kết nối lại khi mất kết nối
✅ **UI thông minh** - Hiển thị trạng thái kết nối real-time  
✅ **Error handling tốt** - Xử lý lỗi gracefully
✅ **Performance tốt** - Heartbeat monitoring và auto-recovery
✅ **User experience** - Thông báo rõ ràng về trạng thái kết nối

---

**Chúc bạn sử dụng thành công! 🎉**

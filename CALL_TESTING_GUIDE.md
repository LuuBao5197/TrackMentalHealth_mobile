# 📞 Hướng dẫn Test Video Call

## 🎯 Tổng quan
Hướng dẫn này giúp bạn test đầy đủ tính năng video call trong ứng dụng Flutter.

## 🚀 Các tính năng đã cải thiện

### ✅ **Nhận cuộc gọi**
- **Dialog đẹp mắt** với animation pulse và slide
- **Âm thanh cuộc gọi** lặp lại mỗi 2 giây
- **Rung thiết bị** khi có cuộc gọi đến
- **Nút nhận/từ chối** với hiệu ứng đẹp
- **Timeout** sau 30 giây nếu không trả lời

### ✅ **Kết thúc cuộc gọi**
- **Dọn dẹp tự động** tất cả resources
- **Thông báo kết thúc** với SnackBar
- **Rung nhẹ** khi kết thúc cuộc gọi
- **Gửi signal** thông báo cho người kia
- **Reset trạng thái** về ban đầu

### ✅ **Thông báo thông minh**
- **CallNotificationService** quản lý tất cả thông báo
- **Toast messages** cho các trạng thái khác nhau
- **Âm thanh và rung** phù hợp với từng tình huống

## 🧪 Cách Test

### **Test 1: Gửi cuộc gọi**
1. Mở app Flutter
2. Vào trang chat với người khác
3. Nhấn nút video call
4. **Kiểm tra:**
   - Dialog "Đang gọi..." xuất hiện
   - Có nút "Hủy" để hủy cuộc gọi
   - Sau 30 giây tự động timeout

### **Test 2: Nhận cuộc gọi**
1. Có người gọi video đến
2. **Kiểm tra:**
   - Dialog cuộc gọi đến với animation
   - Âm thanh cuộc gọi phát ra
   - Thiết bị rung
   - Nút "Nhận" (xanh) và "Từ chối" (đỏ)
   - Sau 30 giây tự động timeout

### **Test 3: Chấp nhận cuộc gọi**
1. Nhấn nút "Nhận" (xanh)
2. **Kiểm tra:**
   - Dialog biến mất
   - Âm thanh dừng
   - Chuyển đến trang video call
   - Video hiển thị bình thường

### **Test 4: Từ chối cuộc gọi**
1. Nhấn nút "Từ chối" (đỏ)
2. **Kiểm tra:**
   - Dialog biến mất
   - Âm thanh dừng
   - Thông báo "Cuộc gọi bị từ chối"
   - Quay lại trang chat

### **Test 5: Kết thúc cuộc gọi**
1. Trong cuộc gọi video, nhấn nút "Kết thúc" (đỏ)
2. **Kiểm tra:**
   - Rung nhẹ
   - Thông báo "Cuộc gọi đã kết thúc"
   - Quay lại trang trước
   - Người kia nhận được thông báo

### **Test 6: Người kia rời cuộc gọi**
1. Người kia nhấn kết thúc cuộc gọi
2. **Kiểm tra:**
   - Thông báo "Người dùng đã rời cuộc gọi"
   - Video của người kia biến mất
   - Có thể tiếp tục cuộc gọi hoặc kết thúc

### **Test 7: Lỗi kết nối**
1. Tắt internet trong cuộc gọi
2. **Kiểm tra:**
   - Thông báo lỗi hiển thị
   - Cuộc gọi tự động kết thúc
   - Quay lại trang chat

## 🔧 Debug và Troubleshooting

### **Kiểm tra logs**
```bash
flutter logs
```

Tìm các log:
- `📞 [CallInitiator]` - Log khởi tạo cuộc gọi
- `📞 [CallSignalListener]` - Log nhận signal
- `📞 [SignalManager]` - Log xử lý signal
- `📞 [AgoraVideoCallPage]` - Log trang video call

### **Lỗi thường gặp**

1. **"Camera permission denied"**
   - Kiểm tra quyền camera trong Settings
   - Test trên thiết bị thật (không phải emulator)

2. **"Agora RTC Engine not initialized"**
   - Kiểm tra App ID trong `agora_config.dart`
   - Đảm bảo `AgoraService.initialize()` được gọi

3. **"Signal không hợp lệ"**
   - Kiểm tra StompService connection
   - Kiểm tra sessionId và userId

4. **"Cuộc gọi không được trả lời"**
   - Kiểm tra timeout (30 giây)
   - Kiểm tra kết nối internet

## 📱 Test trên thiết bị thật

### **Android**
```bash
flutter run --release
```

### **iOS**
```bash
flutter run --release
```

## 🎉 Kết quả mong đợi

Sau khi test, bạn sẽ thấy:

1. **Giao diện đẹp mắt** với animation mượt mà
2. **Âm thanh và rung** phù hợp với từng tình huống
3. **Thông báo rõ ràng** cho mọi trạng thái
4. **Xử lý lỗi tốt** khi có vấn đề
5. **Performance ổn định** không bị lag

## 🚀 Tính năng nâng cao

### **Thêm vào tương lai:**
- [ ] Push notification khi app đang background
- [ ] Call history
- [ ] Screen sharing
- [ ] Group video call
- [ ] Call recording
- [ ] Voice message

## 📞 Support

Nếu gặp vấn đề, hãy kiểm tra:
1. Logs trong console
2. Quyền camera/microphone
3. Kết nối internet
4. App ID Agora
5. StompService connection

---

**Chúc bạn test thành công! 🎉**

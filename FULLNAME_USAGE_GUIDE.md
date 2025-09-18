# 👤 Hướng dẫn sử dụng Fullname trong Video Call

## 🎯 Tổng quan
Hướng dẫn này giải thích cách sử dụng fullname từ UserSession trong ứng dụng video call.

## ✅ **Các cải thiện đã thực hiện**

### **1. Lưu trữ fullname trong state**
```dart
class _ChatDetailState extends State<ChatDetail> {
  String? currentUserFullName;  // Thêm biến lưu fullname
  
  Future<void> _initChat() async {
    // Lấy fullname từ UserSession
    currentUserFullName = await UserSession.getFullname();
  }
}
```

### **2. Sử dụng fullname trong CallInitiator**
```dart
await CallInitiator.sendCallRequest(
  sessionId: widget.sessionId.toString(),
  callerId: currentUserId!,
  callerName: currentUserFullName ?? "User",  // Sử dụng fullname thực
  calleeId: widget.user.id.toString(),
  calleeName: widget.user.fullName ?? "User",
  stompService: stompService,
);
```

### **3. Sử dụng fullname trong AgoraVideoCallPage**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AgoraVideoCallPage(
      channelName: widget.sessionId.toString(),
      uid: int.parse(currentUserId!),
      callerName: currentUserFullName ?? "User",  // Sử dụng fullname thực
      calleeName: widget.user.fullName ?? "User",
      isCaller: true,
      stompService: stompService,
    ),
  ),
);
```

### **4. Sử dụng fullname trong CallSignalListener**
```dart
CallSignalListener(
  sessionId: widget.sessionId.toString(),
  currentUserId: currentUserId!,
  currentUserName: currentUserFullName ?? "User",  // Sử dụng fullname thực
  stompService: stompService,
),
```

### **5. Hiển thị fullname trong Chat UI**
```dart
// Trong Chat widget
user: types.User(
  id: currentUserId.toString(),
  firstName: currentUserFullName,  // Hiển thị fullname trong chat
  imageUrl: currentUserAvatar,
),

// Trong messages
author: types.User(
  id: chatMsg.senderId.toString(),
  firstName: isCurrentUser ? currentUserFullName : widget.user.fullName,
  imageUrl: isCurrentUser ? currentUserAvatar : widget.user.avatar,
),
```

## 🔄 **Luồng hoạt động**

### **1. Khởi tạo**
1. `_initChat()` được gọi
2. Lấy `userId`, `avatar`, và `fullname` từ UserSession
3. Lưu vào state variables

### **2. Gửi cuộc gọi**
1. User nhấn nút video call
2. Kiểm tra kết nối WebSocket
3. Gửi call request với `callerName` = `currentUserFullName`
4. Chuyển đến AgoraVideoCallPage với tên đúng

### **3. Nhận cuộc gọi**
1. CallSignalListener nhận signal
2. Hiển thị dialog với tên người gọi đúng
3. Chuyển đến AgoraVideoCallPage với tên đúng

### **4. Hiển thị trong chat**
1. Messages hiển thị tên người gửi đúng
2. User info trong chat hiển thị tên đúng

## 📱 **Kết quả**

### **Trước khi sửa:**
- ❌ Tên hiển thị: "User" (hardcoded)
- ❌ Không nhất quán giữa các màn hình
- ❌ Không phản ánh tên thật của user

### **Sau khi sửa:**
- ✅ Tên hiển thị: Tên thật từ UserSession
- ✅ Nhất quán trên tất cả màn hình
- ✅ Phản ánh đúng tên user đã đăng nhập

## 🧪 **Cách test**

### **1. Test hiển thị tên trong chat**
1. Đăng nhập với tài khoản có fullname
2. Vào chat với người khác
3. Kiểm tra tên hiển thị trong chat messages

### **2. Test video call**
1. Gửi video call
2. Kiểm tra tên hiển thị trong dialog cuộc gọi đến
3. Kiểm tra tên hiển thị trong AgoraVideoCallPage

### **3. Test call signals**
1. Kiểm tra logs để xem tên được gửi trong signals
2. Kiểm tra tên hiển thị trong các thông báo

## 🔧 **Troubleshooting**

### **Lỗi thường gặp**

1. **"Tên hiển thị là 'User'"**
   - Kiểm tra UserSession.getFullname() có trả về null không
   - Kiểm tra fullname có được lưu trong SharedPreferences không

2. **"Tên không nhất quán"**
   - Kiểm tra tất cả chỗ sử dụng tên đã được cập nhật chưa
   - Kiểm tra currentUserFullName có được set đúng không

3. **"Lỗi khi lấy fullname"**
   - Kiểm tra UserSession.getFullname() có await không
   - Kiểm tra SharedPreferences có hoạt động không

### **Debug logs**
Tìm các log quan trọng:
```
📞 [CallInitiator] Gửi call request từ [Tên thật] đến [Tên người nhận]
📞 [CallSignalListener] Nhận call signal từ [Tên thật]
✅ [AgoraVideoCallPage] Cuộc gọi với [Tên thật]
```

## 🎯 **Best Practices**

### **1. Luôn sử dụng currentUserFullName**
```dart
// ✅ Đúng
callerName: currentUserFullName ?? "User"

// ❌ Sai
callerName: "User"
callerName: UserSession.getFullname()  // Không await
```

### **2. Xử lý null values**
```dart
// Luôn có fallback
currentUserFullName ?? "User"
```

### **3. Consistency**
```dart
// Sử dụng cùng một biến ở mọi nơi
currentUserFullName
```

## 🚀 **Kết luận**

Sau khi áp dụng các cải thiện:

✅ **Tên hiển thị chính xác** - Sử dụng tên thật từ UserSession
✅ **Nhất quán** - Cùng một tên trên tất cả màn hình
✅ **User experience tốt** - User thấy tên mình và người khác đúng
✅ **Maintainable** - Dễ bảo trì và cập nhật

---

**Chúc bạn sử dụng thành công! 🎉**

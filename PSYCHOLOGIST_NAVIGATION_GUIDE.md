# 👨‍⚕️ Hướng dẫn Navigation cho Psychologist

## 🎯 Tổng quan
Hướng dẫn này giải thích cách psychologist được điều hướng đến Appointment Management thay vì My Appointment.

## ✅ **Các cải thiện đã thực hiện**

### **1. Bỏ comment AppointmentManagement.dart**
- File `lib/pages/appointment/AppointmentForPsychologist/AppointmentManagement.dart` đã được bỏ comment
- Cập nhật UI để phù hợp với theme hiện tại
- Thêm error handling và loading states

### **2. Thêm logic kiểm tra role trong ChatScreen**
- Thêm biến `currentUserRole` để lưu role của user
- Lấy role từ `UserSession.getRole()` trong `_initUserIdAndFetchData()`
- Kiểm tra role khi nhấn nút appointment

### **3. Điều hướng thông minh**
- **Psychologist**: Đi đến `AppointmentManagementPage` để quản lý appointments
- **User thường**: Đi đến `AppointmentPage` để xem appointments của mình

### **4. UI động**
- Nút hiển thị text khác nhau tùy theo role:
  - Psychologist: "Appointment Management"
  - User thường: "My Appointment"

## 🔄 **Luồng hoạt động**

### **1. Khởi tạo**
1. `_initUserIdAndFetchData()` được gọi
2. Lấy `userId` và `role` từ UserSession
3. Lưu vào state variables

### **2. Hiển thị UI**
1. Nút appointment hiển thị text phù hợp với role
2. Icon và style giữ nguyên

### **3. Nhấn nút appointment**
1. Lấy `userId` từ UserSession
2. Kiểm tra `currentUserRole`
3. **Nếu là psychologist:**
   - Tạo User object với thông tin từ UserSession
   - Điều hướng đến `AppointmentManagementPage`
4. **Nếu là user thường:**
   - Điều hướng đến `AppointmentPage`

## 📱 **Cách test**

### **Test 1: Psychologist login**
1. Đăng nhập với tài khoản có role = "psychologist"
2. Vào trang Chat
3. **Kiểm tra:**
   - Nút hiển thị "Appointment Management"
   - Nhấn nút → Chuyển đến AppointmentManagementPage
   - Có thể xem danh sách appointments cần xử lý
   - Có thể Accept/Decline appointments

### **Test 2: User thường login**
1. Đăng nhập với tài khoản có role = "user" hoặc null
2. Vào trang Chat
3. **Kiểm tra:**
   - Nút hiển thị "My Appointment"
   - Nhấn nút → Chuyển đến AppointmentPage
   - Có thể xem appointments của mình
   - Có thể tạo/sửa appointments

### **Test 3: Role không xác định**
1. Đăng nhập với tài khoản không có role
2. **Kiểm tra:**
   - Nút hiển thị "My Appointment" (default)
   - Hoạt động như user thường

## 🔧 **Troubleshooting**

### **Lỗi thường gặp**

1. **"Nút vẫn hiển thị 'My Appointment'"**
   - Kiểm tra `currentUserRole` có được set đúng không
   - Kiểm tra UserSession.getRole() có trả về "psychologist" không
   - Kiểm tra role có được lưu trong SharedPreferences không

2. **"Lỗi khi tạo User object"**
   - Kiểm tra UserSession.getFullname(), getEmail(), getAvatar() có trả về null không
   - Kiểm tra User constructor có đúng không

3. **"AppointmentManagementPage không load được"**
   - Kiểm tra API `getAppointmentByPsyId` có hoạt động không
   - Kiểm tra `widget.currentUser.userId` có đúng không

### **Debug logs**
Tìm các log quan trọng:
```
🔄 [ChatScreen] Loading user role: psychologist
✅ [ChatScreen] Role detected: psychologist
📅 [ChatScreen] Navigating to AppointmentManagementPage
📊 [AppointmentManagement] Loading appointments for psychologist
```

## 🎯 **Best Practices**

### **1. Luôn kiểm tra role trước khi điều hướng**
```dart
if (currentUserRole == 'psychologist') {
  // Điều hướng đến AppointmentManagementPage
} else {
  // Điều hướng đến AppointmentPage
}
```

### **2. Xử lý null values**
```dart
currentUserRole == 'psychologist' ? 'Appointment Management' : 'My Appointment'
```

### **3. Tạo User object đầy đủ**
```dart
final user = User(
  id: userId,
  fullName: await UserSession.getFullname(),
  email: await UserSession.getEmail(),
  avatar: await UserSession.getAvatar(),
);
```

## 🚀 **Kết quả**

Sau khi áp dụng các cải thiện:

✅ **Psychologist** được điều hướng đến Appointment Management
✅ **User thường** vẫn đi đến My Appointment
✅ **UI động** hiển thị text phù hợp với role
✅ **Error handling** tốt cho các trường hợp edge case
✅ **Maintainable** code dễ bảo trì và mở rộng

## 📋 **Checklist test**

- [ ] Đăng nhập với tài khoản psychologist
- [ ] Kiểm tra nút hiển thị "Appointment Management"
- [ ] Nhấn nút → Chuyển đến AppointmentManagementPage
- [ ] Có thể xem danh sách appointments
- [ ] Có thể Accept/Decline appointments
- [ ] Đăng nhập với tài khoản user thường
- [ ] Kiểm tra nút hiển thị "My Appointment"
- [ ] Nhấn nút → Chuyển đến AppointmentPage

---

**Chúc bạn test thành công! 🎉**

# 🔧 Sửa lỗi Appointment Management

## 🎯 Vấn đề
API `getAppointmentByPsyId` cần `psyId` (ID của psychologist trong bảng psychologist), nhưng chúng ta chỉ có `userId` (ID của user trong bảng user).

## ❌ **Lỗi ban đầu**
```dart
// SAI: Truyền userId thay vì psyId
final res = await getAppointmentByPsyId(widget.currentUser.id!);
```

## ✅ **Cách sửa**

### **1. Thêm biến psyId**
```dart
class _AppointmentManagementPageState extends State<AppointmentManagementPage> {
  List<Appointment> appointments = [];
  bool loading = true;
  String? error;
  int? psyId;  // Thêm biến này
}
```

### **2. Tìm psyId từ userId**
```dart
Future<void> _findPsyId() async {
  try {
    // Lấy danh sách psychologists và tìm psyId từ userId
    final psychologists = await getPsychologists();
    final psy = psychologists.firstWhere(
      (p) => p.usersID?.id == widget.currentUser.id,
      orElse: () => throw Exception('Psychologist not found'),
    );
    
    setState(() {
      psyId = psy.id;
    });
    
    // Sau khi tìm được psyId, mới fetch appointments
    fetchAppointments();
  } catch (e) {
    setState(() {
      error = "Failed to find psychologist ID: $e";
      loading = false;
    });
  }
}
```

### **3. Sử dụng psyId trong fetchAppointments**
```dart
Future<void> fetchAppointments() async {
  if (psyId == null) {
    setState(() {
      error = "Psychologist ID not found";
      loading = false;
    });
    return;
  }
  
  setState(() => loading = true);
  try {
    final res = await getAppointmentByPsyId(psyId!);  // Sử dụng psyId
    // ... rest of the code
  } catch (e) {
    // ... error handling
  }
}
```

### **4. Cập nhật initState**
```dart
@override
void initState() {
  super.initState();
  _findPsyId();  // Tìm psyId trước
}
```

## 🔄 **Luồng hoạt động mới**

1. **initState()** → Gọi `_findPsyId()`
2. **findPsyId()** → Lấy danh sách psychologists từ API
3. **findPsyId()** → Tìm psychologist có `usersID.id` = `widget.currentUser.id`
4. **findPsyId()** → Lưu `psy.id` vào `psyId`
5. **findPsyId()** → Gọi `fetchAppointments()`
6. **fetchAppointments()** → Sử dụng `psyId` để gọi API

## 🧪 **Cách test**

### **Test 1: Psychologist hợp lệ**
1. Đăng nhập với tài khoản psychologist
2. Vào Appointment Management
3. **Kiểm tra:**
   - Không có lỗi "Psychologist ID not found"
   - Danh sách appointments hiển thị đúng
   - Có thể Accept/Decline appointments

### **Test 2: Psychologist không tồn tại**
1. Đăng nhập với tài khoản không phải psychologist
2. Vào Appointment Management
3. **Kiểm tra:**
   - Hiển thị lỗi "Psychologist not found"
   - Không crash app

### **Test 3: Lỗi API**
1. Tắt internet
2. Vào Appointment Management
3. **Kiểm tra:**
   - Hiển thị lỗi "Failed to find psychologist ID"
   - Không crash app

## 🔧 **Troubleshooting**

### **Lỗi thường gặp**

1. **"Psychologist not found"**
   - Kiểm tra `widget.currentUser.id` có đúng không
   - Kiểm tra có psychologist nào có `usersID.id` = `widget.currentUser.id` không
   - Kiểm tra API `getPsychologists()` có hoạt động không

2. **"Psychologist ID not found"**
   - Kiểm tra `_findPsyId()` có được gọi không
   - Kiểm tra `psyId` có được set đúng không

3. **"Failed to fetch appointments"**
   - Kiểm tra `psyId` có đúng không
   - Kiểm tra API `getAppointmentByPsyId(psyId)` có hoạt động không

### **Debug logs**
Tìm các log quan trọng:
```
🔍 [AppointmentManagement] Finding psyId for userId: 123
✅ [AppointmentManagement] Found psyId: 456
📊 [AppointmentManagement] Fetching appointments for psyId: 456
❌ [AppointmentManagement] Psychologist not found for userId: 123
```

## 🎯 **Kết quả**

Sau khi sửa:

✅ **API được gọi đúng** với `psyId` thay vì `userId`
✅ **Error handling tốt** cho các trường hợp edge case
✅ **Loading states** hiển thị đúng
✅ **Không crash app** khi có lỗi
✅ **Code dễ hiểu** và maintainable

---

**Lỗi đã được sửa! 🎉**

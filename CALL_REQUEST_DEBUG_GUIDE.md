# Hướng dẫn Debug Call Request từ Web sang Flutter

## Vấn đề đã được sửa:

### 1. **CallSignalListener sử dụng chung StompService**
- Trước: Tạo StompService riêng → có thể không kết nối
- Sau: Sử dụng chung StompService với ChatDetail → đảm bảo kết nối

### 2. **ChatDetail subscribe call topic**
- Trước: Chỉ subscribe chat topic
- Sau: Subscribe cả call topic để nhận call signals

### 3. **NotificationListenerWidget cải thiện logging**
- Thêm logging chi tiết để debug call signals

## Cách kiểm tra:

### 1. **Kiểm tra logs trong Flutter:**
```
📞 [ChatDetail] Subscribing to call signals: /topic/call/{sessionId}
📞 [CallSignalListener] StompService đã kết nối, subscribe call signals ngay
📞 [CallSignalListener] Nhận call signal: {signal_data}
```

### 2. **Kiểm tra WebSocket connection:**
- Mở DevTools → Network → WS
- Kiểm tra WebSocket connection đến `ws://{ip}:9999/ws`
- Xem có message nào được gửi đến `/topic/call/{sessionId}` không

### 3. **Kiểm tra call request từ web:**
- Khi gọi từ web, kiểm tra console có log:
```
📞 [ChatDetail] ====== CALL SIGNAL RECEIVED ======
📞 [ChatDetail] Call signal: {signal_data}
📞 [ChatDetail] Signal type: CALL_REQUEST
```

### 4. **Kiểm tra StompService connection:**
- Logs sẽ hiển thị:
```
✅ [StompService] ====== CONNECTED ======
✅ [StompService] WebSocket connected for session: {sessionId}
```

## Các bước debug:

1. **Mở Flutter app và vào ChatDetail**
2. **Kiểm tra console logs có hiển thị:**
   - WebSocket connected
   - Subscribed to call signals
3. **Từ web, gửi call request**
4. **Kiểm tra Flutter console có nhận được call signal không**
5. **Nếu không nhận được, kiểm tra:**
   - WebSocket connection status
   - Session ID có đúng không
   - Call request có được gửi đến đúng topic không

## Logs quan trọng cần chú ý:

```
✅ [StompService] ====== CONNECTED ======
📞 [ChatDetail] Subscribing to call signals: /topic/call/{sessionId}
📞 [CallSignalListener] StompService đã kết nối, subscribe call signals ngay
📞 [ChatDetail] ====== CALL SIGNAL RECEIVED ======
📞 [CallSignalListener] Nhận call signal: {signal_data}
```

## Nếu vẫn không hoạt động:

1. **Kiểm tra IP address trong api_constants.dart**
2. **Kiểm tra WebSocket server có chạy không**
3. **Kiểm tra firewall/network**
4. **Kiểm tra session ID có đúng không**
5. **Kiểm tra call request từ web có đúng format không**

## Test case:

1. Mở 2 tab browser (1 web, 1 Flutter)
2. Vào cùng 1 chat session
3. Từ web, click video call
4. Kiểm tra Flutter có hiển thị incoming call dialog không

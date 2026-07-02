# Fix Luồng Access Token / Refresh Token cho Ví Điện Tử Mio

## Tổng quan vấn đề

Sau khi phân tích kỹ toàn bộ codebase, hệ thống **đã triển khai gần đầy đủ** luồng Access/Refresh Token. Tuy nhiên, mình phát hiện **5 vấn đề nghiêm trọng** cần khắc phục:

## Phân tích hiện trạng

### ✅ Những gì đã có và hoạt động tốt
| Thành phần | File | Trạng thái |
|---|---|---|
| **Bước 1 - Đăng nhập** | [login_password_screen.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/features/auth/login/screens/login_password_screen.dart#L74-L97) | ✅ Nhận cả `access_token` + `refresh_token`, lưu vào `SharedPreferences` |
| **Bước 2 - Gọi API** | [custom_http_client.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/custom_http_client.dart#L18-L34) | ✅ Tự động đính kèm `Bearer token` vào header mỗi request |
| **Bước 3 - Phát hiện 401** | [custom_http_client.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/custom_http_client.dart#L36-L42) | ✅ Lắng nghe mã lỗi 401 |
| **Bước 4 - Refresh Token** | [custom_http_client.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/custom_http_client.dart#L44-L69) | ✅ Gọi API refresh + retry request gốc |
| **Bước 5 - Retry** | [custom_http_client.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/custom_http_client.dart#L49-L66) | ✅ Tự động gửi lại request với token mới |
| **Force Logout** | [custom_http_client.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/custom_http_client.dart#L116-L177) | ✅ Xóa token + hiển thị dialog + chuyển về Login |

---

## 🔴 Các vấn đề cần fix

### Vấn đề 1: Race Condition khi nhiều API cùng gặp 401

> [!CAUTION]
> **Mức độ: NGHIÊM TRỌNG** — Có thể gây gọi API refresh token nhiều lần cùng lúc, dẫn đến mất phiên đăng nhập.

**Hiện trạng:** Khi 3-4 API call đồng thời đều nhận 401 (ví dụ: load trang chủ gọi cùng lúc `balance`, `profile`, `notifications`), mỗi call sẽ **gọi `_tryRefreshToken()` riêng lẻ**. Nếu server áp dụng cơ chế **xoay vòng Refresh Token** (rotate), chỉ lần gọi đầu tiên thành công, các lần sau sẽ dùng Refresh Token cũ đã bị vô hiệu hóa → **tất cả đều thất bại → Force Logout**.

**File:** [custom_http_client.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/custom_http_client.dart#L44)

> [!NOTE]
> `AuthInterceptor` (dùng Dio/QueuedInterceptor) đã xử lý concurrency tốt hơn nhưng **không hề được sử dụng** ở bất kỳ đâu trong app. Nó chỉ nằm im trong file [auth_interceptor.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/auth_interceptor.dart).

---

### Vấn đề 2: Lưu token bằng `SharedPreferences` (KHÔNG MÃ HÓA)

> [!WARNING]
> **Mức độ: QUAN TRỌNG** — Token tài chính phải được bảo vệ ở mức cao nhất.

**Hiện trạng:** Cả `access_token` và `refresh_token` đang được lưu bằng `SharedPreferences` — một cơ chế lưu trữ **plain-text** không được mã hóa.

- Trên Android: lưu trong file XML tại `/data/data/com.xxx/shared_prefs/` → **dễ dàng đọc được** trên thiết bị root.
- Ứng dụng tài chính theo chuẩn PCI-DSS / OWASP **bắt buộc** phải dùng Keystore/Keychain.

**File:** [login_password_screen.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/features/auth/login/screens/login_password_screen.dart#L93-L97)

---

### Vấn đề 3: Hai hệ thống HTTP song song, không đồng nhất

> [!WARNING]
> **Mức độ: QUAN TRỌNG** — Gây nhầm lẫn và tiềm ẩn lỗi bảo mật.

**Hiện trạng:** App đang tồn tại **2 hệ thống HTTP client hoàn toàn tách biệt**:

| # | Hệ thống | Package | File | Đang dùng? |
|---|---|---|---|---|
| 1 | `CustomHttpClient` | `http` | [custom_http_client.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/custom_http_client.dart) | ✅ 40+ file |
| 2 | `AuthInterceptor` | `dio` | [auth_interceptor.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/auth_interceptor.dart) | ❌ 0 file |

- `CustomHttpClient` đang được 40+ file sử dụng, nhưng **thiếu cơ chế chống race condition**.
- `AuthInterceptor` (Dio) được viết tốt hơn với `QueuedInterceptor` (tự động queue hóa các request 401) nhưng **không hề được import hay sử dụng** ở bất kỳ đâu.

---

### Vấn đề 4: Socket.io không tự cập nhật token mới

> [!IMPORTANT]
> **Mức độ: TRUNG BÌNH** — Sau khi refresh token, Socket sẽ bị ngắt kết nối vì vẫn dùng token cũ.

**Hiện trạng:** Khi Access Token được refresh thành công trong `CustomHttpClient`, chỉ có `SharedPreferences` được cập nhật. `SocketService` vẫn giữ token cũ trong bộ nhớ → Socket dần bị ngắt và không nhận được cập nhật real-time (balance_update, receive_message).

**File:** [socket_service.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/socket_service.dart#L31-L46)

---

### Vấn đề 5: Login dùng `http.post` trực tiếp, bypass CustomHttpClient

> [!NOTE]  
> **Mức độ: NHẸ** — Không ảnh hưởng luồng, nhưng không nhất quán.

**Hiện trạng:** Màn hình login gọi `http.post()` trực tiếp thay vì dùng `CustomHttpClient`. Các file auth (login, register, forgot_password) dùng `package:http` raw — điều này đúng logic (vì lúc login chưa có token), nhưng thiếu header `ngrok-skip-browser-warning` khiến request qua ngrok tunnel có thể bị chặn.

---

## Proposed Changes

### Phương án: Nâng cấp `CustomHttpClient` (Rủi ro thấp, ảnh hưởng ít nhất)

> [!IMPORTANT]
> Mình **KHÔNG** chọn phương án chuyển toàn bộ 40+ file sang Dio vì sẽ tạo ra hàng trăm thay đổi, rủi ro regression rất cao. Thay vào đó, mình sẽ **nâng cấp `CustomHttpClient` đang có** để đạt cùng mức chất lượng như `AuthInterceptor` (Dio).

---

### Component 1: Core — Nâng cấp `CustomHttpClient`

#### [MODIFY] [custom_http_client.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/custom_http_client.dart)

**Thay đổi chính:**
1. **Thêm cơ chế Lock (Completer)** để chống race condition: Khi request đầu tiên đang refresh token, tất cả request khác sẽ **chờ** kết quả thay vì gọi refresh song song.
2. **Chuyển sang `FlutterSecureStorage`** để lưu/đọc token thay vì `SharedPreferences`.
3. **Cập nhật SocketService** sau khi refresh token thành công.
4. **Thêm concurrency check** tương tự `AuthInterceptor`: Nếu token đã được refresh bởi request trước đó, retry ngay mà không cần gọi refresh lại.

```dart
// Pseudocode minh họa cơ chế Lock
static Completer<bool>? _refreshCompleter;

if (response.statusCode == 401) {
  // Nếu đang có request khác refresh, chờ nó xong
  if (_refreshCompleter != null) {
    await _refreshCompleter!.future;
    // Retry với token mới
  } else {
    // Lock - Tạo Completer
    _refreshCompleter = Completer<bool>();
    final success = await _tryRefreshToken();
    _refreshCompleter!.complete(success);
    _refreshCompleter = null;
    // Xử lý kết quả
  }
}
```

---

### Component 2: Core — Chuyển token storage sang `FlutterSecureStorage`

#### [MODIFY] [custom_http_client.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/custom_http_client.dart)
- Thay `SharedPreferences.getString('auth_token')` → `FlutterSecureStorage.read(key: 'access_token')`

#### [MODIFY] [login_password_screen.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/features/auth/login/screens/login_password_screen.dart#L93-L97)
- Khi đăng nhập thành công, lưu token vào `FlutterSecureStorage` thay vì `SharedPreferences`.
- Vẫn giữ `SharedPreferences` cho `user_id` và `is_verified` (không phải dữ liệu nhạy cảm).

#### [MODIFY] [main.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/main.dart#L47-L56)
- Đọc token từ `FlutterSecureStorage` khi app khởi động thay vì `SharedPreferences`.

---

### Component 3: Socket — Tự cập nhật token khi refresh

#### [MODIFY] [socket_service.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/socket_service.dart)
- Thêm method `updateToken(String newToken)` để cập nhật auth token và reconnect socket.

#### [MODIFY] [custom_http_client.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/custom_http_client.dart)
- Sau khi refresh token thành công, gọi `SocketService().updateToken(newToken)`.

---

### Component 4: Dọn dẹp — Xóa code thừa

#### [DELETE] [auth_interceptor.dart](file:///D:/KH23_CNTT_HK6_DATN_CODE/DATN-CDCNTT-2026-Final/wallet_app/lib/core/services/auth_interceptor.dart)
- File này không được sử dụng ở bất kỳ đâu, gây nhầm lẫn. Xóa bỏ để giữ codebase sạch.

---

## Open Questions

> [!IMPORTANT]
> **Câu 1:** Backend có áp dụng cơ chế **Rotate Refresh Token** không (mỗi lần dùng refresh token sẽ cấp refresh token mới và vô hiệu hóa cái cũ)? Điều này quyết định mức độ ưu tiên fix race condition.

> [!IMPORTANT]
> **Câu 2:** Bạn có muốn giữ lại file `auth_interceptor.dart` (Dio) cho mục đích tham khảo hay xóa luôn? Vì hiện tại nó hoàn toàn không được sử dụng.

> [!IMPORTANT]
> **Câu 3:** Về thời hạn Access Token trên server, hiện tại cấu hình là bao lâu (15 phút? 30 phút?)? Thông tin này giúp mình tối ưu thêm tính năng **proactive refresh** (tự refresh trước khi hết hạn thay vì chờ lỗi 401).

---

## Verification Plan

### Automated Tests
- Không có unit test framework đang chạy trong project, nên sẽ không tạo test tự động.

### Manual Verification
1. **Test đăng nhập bình thường:** Đăng nhập → Xác nhận token được lưu vào `FlutterSecureStorage` thay vì `SharedPreferences`.
2. **Test token hết hạn:** Chờ token hết hạn hoặc invalidate thủ công trên server → Xác nhận app tự refresh ngầm mà không bị gián đoạn.
3. **Test race condition:** Mở app sau khi token hết hạn (trang chủ gọi đồng thời nhiều API) → Xác nhận chỉ 1 lần refresh được thực thi.
4. **Test force logout:** Invalidate cả refresh token trên server → Xác nhận app hiển thị dialog cảnh báo bảo mật và chuyển về Login.
5. **Test Socket reconnect:** Sau khi token được refresh → Xác nhận Socket.io tự kết nối lại với token mới.

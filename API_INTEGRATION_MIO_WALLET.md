# Tài Liệu Tích Hợp Ví Mio Dành Cho Đối Tác (Merchant)

Tài liệu này hướng dẫn các ứng dụng đối tác (như App Tích Điểm, Sàn TMĐT,...) cách tích hợp tính năng **Liên kết Ví Mio** và **Thanh toán tự động (Auto-Debit)**.

---

## 1. Tổng Quan Luồng Hoạt Động (Workflows)

Hệ thống hỗ trợ luồng thanh toán liền mạch (Seamless Checkout). Người dùng chỉ cần liên kết ví 1 lần duy nhất, sau đó có thể thanh toán các đơn hàng mà không cần phải thoát khỏi App Đối Tác hay nhập mã PIN/OTP thêm lần nào nữa (luồng Auto-Debit).

### Luồng Liên Kết Ví (Account Linking)
1. Trên App Đối tác, người dùng chọn **"Liên kết Ví Mio"**.
2. App Đối tác chuyển hướng (Deep Link) sang ứng dụng Ví Mio.
3. Người dùng xác nhận liên kết trên Ví Mio.
4. Ví Mio trả về App Đối tác một mã `auth_code`.
5. App Đối tác gọi API `Verify Auth Code` để đổi `auth_code` lấy `wallet_token` (Token ủy quyền vĩnh viễn).
6. App Đối tác lưu lại `wallet_token` này vào database của mình để dùng cho các lần thanh toán sau.

### Luồng Thanh Toán (Auto-Debit Charge)
1. Người dùng chọn thanh toán đơn hàng bằng **Ví Mio** trên App Đối tác.
2. App Đối tác gọi API `Charge` (Truyền lên `wallet_token` của người dùng + `api_key` của App Đối tác + `amount`).
3. Ví Mio xử lý trừ tiền ngầm mà không cần người dùng xác thực mã PIN.
4. Ví Mio trả về kết quả qua API và đồng thời đẩy thêm `Webhook` báo trạng thái giao dịch cho App Đối tác.

---

## 2. Thông Số Kỹ Thuật & Môi Trường

- **Base URL (Ví Mio)**: `https://orectic-noctilucent-ronan.ngrok-free.dev`
- **API Key**: Mỗi đối tác sẽ được cấp một `API_KEY` riêng từ trang Quản trị Đối tác của Ví Mio.

---

## 3. Chi Tiết API (Do Ví Mio cung cấp)

### 3.1. API Đổi mã xác thực lấy Token Liên Kết
Sau khi nhận được `auth_code` từ luồng Deep Link, đối tác cần gọi API này để lấy Token ủy quyền. **Lưu ý: Mã `auth_code` chỉ có hiệu lực 1 lần trong vòng 5 phút.**

- **Endpoint**: `POST /api/v1/merchant/auth-code/verify`
- **Headers**: 
  - `Content-Type: application/json`

- **Request Body**:
```json
{
  "auth_code": "mã_nhận_được_từ_deep_link",
  "merchant_name": "Tên App Đối Tác (VD: AppTichDiem)"
}
```

- **Response (Thành công)**:
```json
{
  "success": true,
  "wallet_token": "tok_mio_xxxxxxxxxxxxxxxxx",
  "masked_phone": "******1234",
  "message": "Xác thực thành công"
}
```
> [!IMPORTANT]
> Bạn phải lưu lại `wallet_token` này tương ứng với User ID trên hệ thống của bạn để sử dụng cho API Thanh Toán ở bước sau.

### 3.2. API Ra Lệnh Trừ Tiền (Auto-Debit Charge)
API được gọi từ Server của Đối tác sang Server của Ví Mio (Server-to-Server) để trừ tiền trực tiếp từ ví người dùng mà không cần người dùng xác nhận OTP/PIN.

- **Endpoint**: `POST /api/v1/merchant/charge`
- **Headers**: 
  - `Content-Type: application/json`

- **Request Body**:
```json
{
  "api_key": "API_KEY_CUA_DOI_TAC_DUOC_MIO_CAP",
  "merchant_code": "MA_DOI_TAC (VD: MC_APPTICHDIEM)",
  "wallet_token": "tok_mio_xxxxxxxxxxxxxxxxx",
  "amount": 50000,
  "order_id": "MÃ_ĐƠN_HÀNG_CỦA_BẠN_12345"
}
```

- **Response (Thành công)**:
```json
{
  "success": true,
  "message": "Thanh toán thành công",
  "data": {
    "transaction_id": "TX_MIO_999999",
    "amount": 50000,
    "status": "SUCCESS"
  }
}
```
> [!WARNING]
> Nếu Response trả về lỗi `403` hoặc mã lỗi liên quan đến việc *"Không tìm thấy ví liên kết"*, đối tác nên tự động cập nhật trạng thái ví của user thành `UNLINKED` (Đã hủy liên kết) trên hệ thống của mình.

---

## 4. Webhook (App Đối Tác Cần Cung Cấp)

Ví Mio sẽ bắn (push) dữ liệu bất đồng bộ đến các Endpoint của App Đối tác trong một số trường hợp. App đối tác cần xây dựng các API nhận Webhook và cấu hình đường dẫn (Callback URL) trên trang Quản trị của Ví Mio.

### 4.1. Webhook Kết Quả Thanh Toán
Dùng để đối soát hoặc cập nhật trạng thái đơn hàng trong trường hợp xử lý bất đồng bộ hoặc mạng bị chập chờn.

- **Method**: `POST`
- **Payload Ví Mio gửi sang**:
```json
{
  "event": "PAYMENT_SUCCESS",
  "order_id": "MÃ_ĐƠN_HÀNG_CỦA_BẠN_12345",
  "amount": 50000,
  "transaction_id": "TX_MIO_999999",
  "timestamp": 1718000000000
}
```

### 4.2. Webhook Hủy Liên Kết Chủ Động
Khi người dùng mở App Ví Mio và chủ động bấm "Hủy liên kết" với App Đối tác. Ví Mio sẽ báo cho Đối tác biết để cập nhật lại giao diện, yêu cầu user phải liên kết lại ở lần mua hàng sau.

- **Method**: `POST`
- **Payload Ví Mio gửi sang**:
```json
{
  "event": "USER_UNLINKED",
  "wallet_account": "tok_mio_xxxxxxxxxxxxxxxxx",
  "service_name": "Tên App Đối Tác (VD: AppTichDiem)"
}
```

Khi nhận được Webhook này, App Đối tác cần tìm user sở hữu `wallet_account` tương ứng trong Database và đánh dấu trạng thái ví của họ thành `UNLINKED`.

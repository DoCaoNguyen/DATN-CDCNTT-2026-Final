# Ví Mio Payment Gateway — Hướng Dẫn Tích Hợp Cho Đối Tác

> Tài liệu này dành cho **developer của Merchant (bên thứ ba)** muốn tích hợp thanh toán qua Ví Mio.

---

## Bước 1 — Nhận Credentials Từ Admin

Sau khi hồ sơ Merchant được duyệt, Admin sẽ gửi cho bạn email onboarding gồm:

```
- Username đăng nhập Merchant Portal
- Mật khẩu tạm thời (phải đổi lần đầu)
- Link Merchant Portal: http://localhost:5174
```

Đăng nhập vào Merchant Portal → Sidebar → **API Keys** → **Tạo Sandbox Key**.

Hệ thống sẽ hiện modal **1 lần duy nhất**:

```
API Key (Public):   pk_test_a1b2c3d4e5f6...   ← dùng ở frontend
Secret Key:         sk_test_z9y8x7w6v5u4...   ← chỉ dùng ở backend
```

> ⚠️ **Lưu Secret Key ngay lập tức!** Hệ thống không lưu và không hiển thị lại sau khi đóng modal.

---

## Bước 2 — Lưu Credentials Vào Biến Môi Trường

Tạo file `.env` trong backend project của bạn:

```env
# Ví Mio API Credentials — KHÔNG commit file .env lên Git!
VIO_API_KEY=pk_test_a1b2c3d4e5f6...
VIO_API_SECRET=sk_test_z9y8x7w6v5u4...
VIO_BASE_URL=http://localhost:8000/api/v1
```

Thêm `.env` vào `.gitignore`:
```
.env
```

---

## Bước 3 — Cách Sử Dụng 2 Loại Key

| Key | Loại | Dùng ở đâu | Tại sao |
|---|---|---|---|
| `pk_test_...` | **Public Key** | Frontend hoặc Backend | Chỉ định danh merchant, không có quyền thực hiện giao dịch |
| `sk_test_...` | **Secret Key** | **Chỉ Backend** | Dùng để ký (sign) request tài chính — KHÔNG được để lộ |

**Public key ở frontend** (ví dụ: khởi tạo form thanh toán, hiển thị UI):
```http
GET /api/v1/some-public-endpoint
X-Api-Key: pk_test_a1b2c3d4e5f6
```

**Secret key cho endpoint tài chính** (charge/debit): Phải ký HMAC — xem Bước 4.

---

## Bước 4 — Gọi API Thanh Toán Tự Động (Auto-Debit)

Endpoint tài chính bắt buộc phải gửi **3 headers**:

| Header | Mô tả |
|---|---|
| `X-Api-Key` | Public key (`pk_test_...`) |
| `X-Timestamp` | Unix timestamp **milliseconds** khi tạo request |
| `X-Signature` | HMAC-SHA256 của `"<timestamp>.<JSON.stringify(body)>"` ký bằng Secret Key |

### Công thức tạo Signature:

```
message   = timestamp + "." + JSON.stringify(requestBody)
signature = HMAC_SHA256(message, VIO_API_SECRET)
```

---

## Code Mẫu — NodeJS (Express Backend)

```javascript
// vio-client.js — Tích hợp thanh toán Ví Mio
const crypto = require('crypto');
const axios  = require('axios');

const VIO_API_KEY    = process.env.VIO_API_KEY;
const VIO_API_SECRET = process.env.VIO_API_SECRET;
const VIO_BASE_URL   = process.env.VIO_BASE_URL;

/**
 * Tạo headers xác thực cho request tài chính (có HMAC signature).
 */
function buildAuthHeaders(requestBody) {
    const timestamp = Date.now().toString();
    const message   = `${timestamp}.${JSON.stringify(requestBody)}`;
    const signature = crypto
        .createHmac('sha256', VIO_API_SECRET)
        .update(message)
        .digest('hex');

    return {
        'X-Api-Key'   : VIO_API_KEY,
        'X-Timestamp' : timestamp,
        'X-Signature' : signature,
        'Content-Type': 'application/json',
    };
}

/**
 * Gọi API tự động trừ tiền ví của user.
 *
 * @param {string} walletToken  - Token ủy quyền của user (tok_mio_...)
 * @param {number} amount       - Số tiền VND (VD: 50000)
 * @param {string} orderId      - Mã đơn hàng bên bạn
 */
async function chargeWallet(walletToken, amount, orderId) {
    const body = {
        wallet_token: walletToken,
        amount      : amount,
        order_id    : orderId,
    };

    const response = await axios.post(
        `${VIO_BASE_URL}/merchant/charge`,
        body,
        { headers: buildAuthHeaders(body) }
    );

    return response.data;
}

module.exports = { chargeWallet };
```

### Sử dụng trong route của bạn:

```javascript
const { chargeWallet } = require('./vio-client');

router.post('/checkout', async (req, res) => {
    const { wallet_token, cart_total, order_id } = req.body;

    try {
        const result = await chargeWallet(wallet_token, cart_total, order_id);
        // Cập nhật đơn hàng thành công
        await Order.update({ status: 'PAID' }, { where: { id: order_id } });
        res.json({ success: true, data: result });
    } catch (err) {
        const msg = err.response?.data?.error || err.message;
        res.status(400).json({ error: msg });
    }
});
```

---

## Bước 5 — Nhận Webhook Callback

Sau khi giao dịch hoàn tất, Ví Mio sẽ gọi `POST` đến **Callback URL** bạn đã cấu hình trong Merchant Portal.

### Xác minh Webhook:

```javascript
const crypto = require('crypto');

function verifyWebhook(req) {
    const signature = req.headers['x-vio-signature'];
    const expected  = crypto
        .createHmac('sha256', process.env.VIO_API_SECRET)
        .update(JSON.stringify(req.body))
        .digest('hex');

    return crypto.timingSafeEqual(
        Buffer.from(signature, 'hex'),
        Buffer.from(expected, 'hex')
    );
}

router.post('/webhook/vio', express.json(), async (req, res) => {
    if (!verifyWebhook(req)) {
        return res.status(401).json({ error: 'Invalid signature' });
    }

    const { event_type, data } = req.body;
    if (event_type === 'PAYMENT_SUCCESS') {
        await Order.update({ status: 'PAID' }, { where: { id: data.merchant_order_id } });
    }

    // Luôn trả 200 — nếu không Ví Mio sẽ retry
    res.status(200).json({ received: true });
});
```

---

## Bảng Mã Lỗi

| HTTP | Error | Nguyên nhân | Cách xử lý |
|---|---|---|---|
| 401 | `Thieu X-Api-Key header` | Thiếu header | Thêm `X-Api-Key` |
| 401 | `Thieu X-Signature hoac X-Timestamp` | Gọi endpoint tài chính thiếu signature | Thêm cả `X-Timestamp` + `X-Signature` |
| 401 | `Chu ky khong hop le: Timestamp het han` | Timestamp > 5 phút | Sync đồng hồ server, dùng `Date.now()` |
| 401 | `Chu ky khong hop le` | Secret sai hoặc body bị thay đổi | Kiểm tra lại `VIO_API_SECRET` và cách tạo message |
| 401 | `Key nay khong ho tro HMAC signature` | Key cũ tạo trước khi hệ thống nâng cấp | Tạo key mới tại Merchant Portal |
| 401 | `API Key da bi thu hoi` | Key bị revoke | Tạo key mới tại Merchant Portal |
| 403 | `Tai khoan Merchant khong kha dung` | Merchant bị suspend | Liên hệ Admin |
| 403 | `Dich vu chua duoc lien ket` | User chưa link app bên bạn với Ví | Hướng dẫn user link trong app Ví Mio |
| 400 | `Vuot qua han muc` | Vượt giới hạn giao dịch ngày | Thông báo cho user |
| 400 | `So du khong du` | Số dư ví không đủ | Thông báo cho user |

---

## Checklist Tích Hợp

```
[ ] Đã lấy API Key từ Merchant Portal
[ ] Lưu key vào .env, không hardcode, không commit lên Git
[ ] Đã implement buildAuthHeaders() với HMAC signature
[ ] Test gọi /merchant/charge thành công trong Sandbox
[ ] Đã implement endpoint nhận webhook + xác minh signature
[ ] Callback URL đã cấu hình trong Merchant Portal
[ ] Test webhook nhận được sau giao dịch thành công
[ ] Xử lý idempotency (webhook có thể đến nhiều lần cùng 1 order)
```

---

## Hỗ Trợ

Liên hệ Admin qua email để được cấp **Production key** (`pk_live_` / `sk_live_`) khi sẵn sàng go-live.

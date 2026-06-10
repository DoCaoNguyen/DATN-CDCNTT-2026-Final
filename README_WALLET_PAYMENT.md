# Wallet Payment Gateway

> Hệ thống ví điện tử và cổng thanh toán với kiến trúc Modular Monolith + Layered Architecture

## 📋 Tổng quan

**Wallet Payment Gateway** là hệ thống mô phỏng ví điện tử và cổng thanh toán, hỗ trợ:

- 👤 **User Wallet** - Người dùng đăng ký, đăng nhập và sử dụng ví điện tử
- 💰 **Topup** - Nạp tiền giả lập vào ví
- 🔁 **Transfer** - Chuyển tiền giữa các ví người dùng
- 📱 **QR Payment** - Thanh toán qua QR Code động
- 🏪 **Merchant Gateway** - Merchant tích hợp API tạo thanh toán
- 🔔 **Webhook/Callback** - Gửi kết quả thanh toán về merchant
- 🛠️ **Admin Web** - Quản lý user, ví, merchant, giao dịch, báo cáo và audit log

---

## 🏗️ Kiến trúc

Hệ thống được thiết kế theo:

- **Modular Monolith** - Một backend service duy nhất, chia module nghiệp vụ rõ ràng
- **Layered Architecture** - Mỗi module đi theo luồng `Routes → Controller → Service → Repository`
- **Shared Database** - Sử dụng chung PostgreSQL cho phạm vi MVP đồ án
- **Ledger-based Transaction** - Mọi biến động tiền được ghi nhận bằng debit/credit ledger

### Nguyên tắc thiết kế

1. ✅ Mỗi module phụ trách một nhóm nghiệp vụ rõ ràng
2. ✅ Business rules nằm trong Service, không đặt trực tiếp trong Controller
3. ✅ Repository chỉ phụ trách thao tác database
4. ✅ Giao dịch tiền phải chạy trong database transaction
5. ✅ Không cập nhật số dư ví trực tiếp ngoài Wallet/Ledger service
6. ✅ API có side effect tiền phải dùng `Idempotency-Key`
7. ✅ Merchant API phải xác thực bằng API Key + Signature
8. ✅ Webhook gửi về merchant phải có Signature
9. ✅ Transaction, Ledger, Audit Log không được sửa/xóa trực tiếp

---

---

## 📦 Module chính

| Module | Trách nhiệm |
|--------|-------------|
| **Auth** | Đăng ký, đăng nhập, JWT, refresh token, phân quyền người dùng |
| **Wallet** | Quản lý ví điện tử, số dư, khóa/mở ví, lịch sử biến động |
| **Topup** | Nạp tiền giả lập vào ví người dùng |
| **Transfer** | Chuyển tiền giữa các ví người dùng |
| **Transaction / Ledger** | Ghi nhận giao dịch tiền bằng debit/credit, đảm bảo đối soát số dư |
| **Merchant** | Quản lý merchant, tài khoản merchant, API key và cấu hình callback |
| **Payment Gateway** | Merchant tạo payment order, sinh payment URL/QR và truy vấn trạng thái thanh toán |
| **QR Payment** | User quét QR, xem thông tin thanh toán và xác nhận thanh toán bằng ví |
| **Webhook** | Gửi callback kết quả payment/refund về merchant, retry và lưu log |
| **Refund** | Hoàn tiền toàn phần hoặc một phần cho giao dịch đã thanh toán |
| **Admin** | Quản trị user, ví, merchant, payment, transaction và webhook |
| **Dashboard** | Hiển thị KPI, biểu đồ giao dịch và cảnh báo hệ thống |
| **Report** | Báo cáo topup, transfer, payment, refund, webhook và đối soát ledger |
| **Setting** | Cấu hình hạn mức, thời gian hết hạn payment/QR, retry webhook và logging |
| **Audit Log** | Ghi nhận audit log, system log và trace payment flow |

---

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- PostgreSQL 14+
- npm hoặc yarn
- Redis/RabbitMQ: tùy chọn cho phase nâng cao

### 1. Clone & Setup

```bash
git clone <repository-url>
cd DATN-CDCNTT-2026-Final
npm install
```

### 2. Configure Environment

Copy `.env.example` thành `.env`:

```bash
cp .env.example .env
```

Ví dụ `.env`:

```env
NODE_ENV=development
PORT=5000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=ewallet_db
DB_USER=postgres
DB_PASSWORD=postgres

JWT_ACCESS_SECRET=change_me_access_secret
JWT_REFRESH_SECRET=change_me_refresh_secret

MERCHANT_SIGNATURE_TOLERANCE_SECONDS=300
IDEMPOTENCY_TTL_HOURS=24
WEBHOOK_TIMEOUT_SECONDS=10
WEBHOOK_MAX_RETRY=5

APP_BASE_URL=http://localhost:5000
PAYMENT_WEB_URL=http://localhost:3000
```

### 3. Configure Database

```bash
createdb ewallet_db
psql -d ewallet_db -f database/ewallet_db.sql
psql -d ewallet_db -f database/ewallet_sample-data.sql
```

### 4. Run

```bash
npm run dev
```

### 5. Access Swagger

```text
http://localhost:5000/swagger
```

Health check:

```http
GET http://localhost:5000/api/v1/health
```

---

## 🔐 Tài khoản demo

Mật khẩu demo:

```text
Password@123
```

| Username | Role |
|----------|------|
| `superadmin` | SUPER_ADMIN |
| `admin` | ADMIN |
| `support` | SUPPORT_STAFF |
| `user_an` | USER |
| `user_binh` | USER |
| `merchant_one_owner` | MERCHANT_OWNER |
| `merchant_one_staff` | MERCHANT_STAFF |

---

## 📚 Tài liệu

### API

- `docs/api/API_CONVENTIONS_WALLET_PAYMENT.md`
- `docs/api/API_DESIGN_OVERVIEW_WALLET_PAYMENT.md`
- `docs/api/API_DESIGN_DETAIL_WALLET_PAYMENT_UPDATED.md`

### FRS

- `docs/frs/FRS_MAIN_WALLET_PAYMENT.md`
- `docs/frs/FRS_MOD_*.md`

### Database

- `database/ewallet_db.sql`
- `database/ewallet_sample-data.sql`

### Architecture / DEV-SPEC

- `docs/architecture/architecture.md`
- `docs/dev-spec/DEV_SPEC_BACKEND_WALLET_PAYMENT.md`
- `docs/diagrams/`

---

## 🛠️ Development

### Run dev

```bash
npm run dev
```

### Run tests

```bash
npm test
```

### Lint

```bash
npm run lint
```

### Reset database demo

```bash
psql -d ewallet_db -f database/ewallet_db.sql
psql -d ewallet_db -f database/ewallet_sample-data.sql
```

---

## 🎯 Roadmap

| Phase | Module/Layer | Status |
|-------|--------------|--------|
| Phase 1 | Foundation: Auth, RBAC, Response, Error, DB | 📋 Chờ |
| Phase 2 | Wallet Core: Wallet, Ledger, Topup, Transfer | 📋 Chờ |
| Phase 3 | Merchant Gateway: Merchant, API Key, Payment Order | 📋 Chờ |
| Phase 4 | QR Payment: Resolve QR, Confirm Payment, Ledger Payment | 📋 Chờ |
| Phase 5 | Webhook & Refund: Callback, Retry, Refund | 📋 Chờ |
| Phase 6 | Admin, Dashboard, Report, Audit Trace | 📋 Chờ |

---

## ✅ Business Rules quan trọng

1. Mỗi user có 1 ví chính trong MVP.
2. Không cho số dư ví âm.
3. Không sửa số dư ví trực tiếp từ controller/API.
4. Mọi biến động tiền phải ghi ledger.
5. Tổng debit phải bằng tổng credit.
6. Một payment chỉ có tối đa 1 transaction `SUCCESS`.
7. Payment `PAID` không được cancel.
8. QR hết hạn hoặc đã dùng không được thanh toán.
9. Callback lỗi không rollback payment/refund.
10. Refund không được vượt số tiền payment.
11. API tiền phải có `Idempotency-Key`.
12. Không log password, token, API secret.
13. Không sửa/xóa transaction, ledger, audit log.

---

## 🤝 Contributing

Quy trình làm việc:

1. Đọc tài liệu trong `docs/`.
2. Follow API convention trong `docs/api/`.
3. Không viết business logic trong Controller.
4. Giao dịch tiền phải đi qua Service + Transaction Manager + Ledger.
5. Update Swagger/Postman khi thêm API mới.
6. Update documentation khi thay đổi business rule hoặc API contract.

---

## 📝 License

Academic Project - Graduation Thesis

## 📞 Contact

- Project: Wallet Payment Gateway
- Team: Graduation Project Team

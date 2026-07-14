# Tổng quan Hệ thống Ví điện tử & Cổng thanh toán (Merchant Portal)

Hệ thống của chúng ta là một giải pháp Thanh toán và Quản lý Ví điện tử toàn diện, bao gồm Backend Core xử lý giao dịch khắt khe và hệ thống Merchant Portal dành cho doanh nghiệp quản lý dòng tiền. Quá trình phát triển được chia làm 6 Phase (Giai đoạn) với các tính năng quản lý cốt lõi đã hoàn thiện như sau:

---

## 1. Lịch sử Phát triển (Các Phase)

* **Phase 1: Core Foundation & Auth** 
  Xây dựng kiến trúc Backend Node.js/Express, thiết kế Database PostgreSQL. Xử lý bảo mật, mã hóa mật khẩu, JWT Authentication và kiến trúc đa lớp (Controller - Service - Repository).
* **Phase 2: Transactions & Balance Engine**
  Phát triển bộ máy xử lý giao dịch. Đảm bảo tính toàn vẹn dữ liệu (ACID) khi trừ/cộng tiền, cơ chế đóng băng số dư (Hold Balance) và sao kê lịch sử biến động.
* **Phase 3: Payment Gateway API**
  Xây dựng chuẩn giao tiếp API dành cho các Merchant (Doanh nghiệp). Cho phép đối tác dùng API Keys để tạo Lệnh thanh toán (Payment Orders).
* **Phase 4: Webhook Dispatcher**
  Hệ thống bắn thông báo (Webhook) tự động tới server của Merchant khi có sự kiện (ví dụ: Thanh toán thành công). Đi kèm cơ chế tự động thử lại (Retry) và ký số bảo mật (Signature HMAC).
* **Phase 5: Khởi tạo Merchant Web Portal**
  Xây dựng hệ thống Frontend React.js/Vite. Kết nối API Backend để hiển thị dữ liệu thô ra giao diện người dùng.
* **Phase 6: Nâng cấp UI/UX chuẩn Enterprise (MEU/OMNI)**
  "Đại tu" toàn bộ giao diện Merchant Portal. Chuẩn hóa Bảng dữ liệu, Phân trang, Thanh tìm kiếm Debounce, Layout Chi tiết 2 cột và các thẻ KPI trực quan.

---

## 2. Các Chức năng Quản lý mà Hệ thống Đang đáp ứng

Hệ thống **Merchant Web Portal** hiện tại cung cấp cho Doanh nghiệp một bộ công cụ quản lý toàn diện gồm 6 Module chính:

### 🌟 2.1. Tổng quan (Dashboard)
- **Theo dõi nhanh:** Hiển thị tức thì các Lệnh thanh toán mới nhất, Giao dịch gần nhất và trạng thái Webhook.
- **Shortcut:** Cung cấp cái nhìn toàn cảnh giúp Merchant dễ dàng điều hướng tới các chức năng chi tiết.

### 💳 2.2. Đơn thanh toán (Payment Orders)
- **Quản lý Vòng đời Đơn hàng:** Xem toàn bộ các lệnh yêu cầu thanh toán được tạo từ hệ thống của Merchant.
- **Tính năng nổi bật:**
  - Lọc theo trạng thái (Thành công, Đang xử lý, Thất bại, Đã hủy).
  - Tìm kiếm Debounce theo Mã đơn (Order ID).
  - Phân trang thông minh.
  - Xem chi tiết từng đơn hàng (Mã Merchant, Mô tả, Hạn thanh toán, Số tiền).

### 💰 2.3. Quản lý Giao dịch (Transactions)
- **Kiểm soát Dòng tiền:** Theo dõi mọi luồng tiền ra/vào liên quan đến tài khoản ví của Merchant.
- **Tính năng nổi bật:**
  - Xác định loại giao dịch (Tiền vào / Tiền ra) với màu sắc rõ ràng (Xanh/Đen).
  - Truy xuất chính xác thời điểm biến động số dư.
  - Xem chi tiết mã giao dịch tham chiếu tới Đơn thanh toán tương ứng.

### 🏦 2.4. Số dư & Sao kê (Balance & Statement)
- **Quản lý Tài sản:** Cung cấp báo cáo tài chính minh bạch cho Doanh nghiệp.
- **Tính năng nổi bật:**
  - Hiển thị rạch ròi **Số dư khả dụng** (có thể rút/sử dụng) và **Số dư tạm giữ** (đang chờ xử lý).
  - Liệt kê lịch sử sao kê chi tiết để phục vụ đối soát kế toán.

### 📡 2.5. Trình Quản lý Webhooks
- **Giám sát Kỹ thuật:** Dành riêng cho đội ngũ Dev/IT của Merchant theo dõi tình trạng kết nối giữa 2 hệ thống.
- **Tính năng nổi bật:**
  - Thống kê Webhook lỗi/thành công.
  - **Màn hình Chi tiết Webhook (2-Column Layout):** Đọc trực tiếp Raw JSON Payload và Error Logs.
  - **Manual Retry:** Hỗ trợ nút "Thử lại" thủ công kèm hộp thoại xác nhận cho các webhook gửi thất bại.

### 🔑 2.6. Quản lý Khóa API (API Keys)
- **Bảo mật Tích hợp:** Nơi quản lý các thông tin nhạy cảm để hệ thống Merchant kết nối vào Cổng thanh toán.
- **Tính năng nổi bật:**
  - Cấp phát/Thu hồi thông tin: Client ID, Secret Key, Webhook Secret.
  - Copy nhanh vào Clipboard (có cảnh báo an toàn).
  - Phân tách theo Môi trường (Sandbox / Production).

---

## 3. Các Ưu điểm Kỹ thuật nổi bật (Dành riêng cho Frontend)
1. **Tốc độ & Trải nghiệm:** Áp dụng Debounce Search (đợi 400ms mới tìm kiếm) và Không làm mới trang (SPA).
2. **Expandable Row:** Trải nghiệm "Xem trước (Preview)" thông tin trực tiếp ngay tại danh sách mà không cần chuyển trang.
3. **Detail Page:** Tạm biệt các Modal tràn màn hình, hệ thống sử dụng Layout Detail 2 cột chuyên nghiệp giúp đọc JSON/Log cực kỳ thoải mái.
4. **Phân trang MEU-Style:** Ô nhập liệu nhảy trang, tùy chọn 10, 20, 50 dòng/trang, và tự động thu gọn số trang bằng ....

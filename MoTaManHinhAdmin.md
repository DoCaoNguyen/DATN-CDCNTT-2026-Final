# MÔ TẢ CÁC MÀN HÌNH ADMIN

## 3.1 Màn hình Tổng quan Hệ thống (Admin Dashboard)
### 3.1.1. Mục đích chức năng
Giúp Admin có cái nhìn bao quát về tình hình hoạt động của toàn bộ hệ thống ví điện tử theo thời gian thực. Theo dõi tổng số người dùng ví, merchant, giao dịch, dòng tiền và tỷ lệ lỗi của hệ thống.
### 3.1.2 Giao diện chức năng
Giao diện hiển thị trực quan các thẻ thống kê tổng quan (KPIs). Bên dưới là biểu đồ biến động doanh thu và danh sách các giao dịch diễn ra gần nhất.
*[Chèn ảnh Giao diện Tổng quan Hệ thống]*
Hình: Giao diện Tổng quan Hệ thống (Admin Dashboard)
### 3.1.3 Kết quả thực hiện
Admin theo dõi được sức khỏe của hệ thống một cách nhanh chóng, đưa ra các quyết định điều hành kịp thời dựa trên số liệu thực tế.

---

## 3.2 Màn hình Quản lý danh sách người dùng ví
### 3.2.1. Mục đích chức năng
Giúp Admin quản lý tập trung toàn bộ người dùng ví trong hệ thống. Chức năng hỗ trợ theo dõi thông tin tài khoản, trạng thái xác minh, tình trạng sử dụng ví và xem chi tiết hồ sơ định danh (KYC) của người dùng.
### 3.2.2 Giao diện chức năng
Giao diện hiển thị danh sách người dùng kèm các thông tin cơ bản. Khi truy cập chi tiết, ngoài các thẻ Thông tin chung và Lịch sử, hệ thống cung cấp thêm tab "Hồ sơ KYC" để đối chiếu ảnh giấy tờ tùy thân (CCCD), ảnh selfie, kết quả quét thông tin (OCR) và tỷ lệ trùng khớp khuôn mặt (Face Match) từ AI.
*[Chèn ảnh Giao diện danh sách và chi tiết người dùng ví]*
Hình: Giao diện quản lý và chi tiết người dùng ví
### 3.2.3 Kết quả thực hiện
Admin có thể nhanh chóng tra cứu, kiểm tra trạng thái tài khoản và rà soát hồ sơ định danh pháp lý của người dùng trong cùng một màn hình tập trung.
## 3.3 Màn hình Tra cứu lịch sử nạp tiền
### 3.3.1. Mục đích chức năng
Màn hình tra cứu lịch sử nạp tiền của người dùng, hiển thị tổng số giao dịch, tổng tiền thành công và hỗ trợ lọc theo thời gian.
### 3.3.2 Giao diện chức năng
Hiển thị bảng danh sách giao dịch nạp tiền, số tiền, phương thức nạp và trạng thái. Kèm theo bộ lọc thời gian và thanh tìm kiếm.
*[Chèn ảnh Giao diện Tra cứu lịch sử nạp tiền]*
Hình: Giao diện Tra cứu lịch sử nạp tiền
### 3.3.3 Kết quả thực hiện
Quản trị viên nắm bắt được dòng tiền đầu vào của hệ thống, hỗ trợ công tác đối soát kế toán và giải quyết khiếu nại nạp tiền nhanh chóng.

---

## 3.4 Màn hình Lịch sử giao dịch chuyển tiền (P2P)
### 3.4.1. Mục đích chức năng
Thống kê chi tiết các giao dịch chuyển tiền qua lại giữa các tài khoản ví (P2P), cho phép theo dõi dòng tiền nội bộ và xuất dữ liệu ra file Excel.
### 3.4.2 Giao diện chức năng
Giao diện liệt kê mã giao dịch, người chuyển, người nhận, số tiền và nội dung chuyển. Tích hợp nút xuất báo cáo (Export Excel).
*[Chèn ảnh Giao diện Lịch sử chuyển tiền P2P]*
Hình: Giao diện Lịch sử giao dịch chuyển tiền (P2P)
### 3.4.3 Kết quả thực hiện
Giám sát chặt chẽ hoạt động chuyển tiền P2P, dễ dàng báo cáo và truy vết khi có dấu hiệu gian lận hoặc yêu cầu tra soát.

---

## 3.5 Màn hình Quản lý giao dịch thanh toán Merchant
### 3.5.1. Mục đích chức năng
Giúp quản trị viên theo dõi danh sách các giao dịch khách hàng thanh toán cho cửa hàng (Merchant) cùng trạng thái tương ứng.
### 3.5.2 Giao diện chức năng
Bảng danh sách chi tiết mã hóa đơn, tên Merchant, mã giao dịch, số tiền thanh toán và trạng thái thành công/thất bại.
*[Chèn ảnh Giao diện thanh toán Merchant]*
Hình: Giao diện Quản lý giao dịch thanh toán Merchant
### 3.5.3 Kết quả thực hiện
Quản lý luồng giao dịch thương mại minh bạch, hỗ trợ đối soát công nợ giữa hệ thống ví và các đối tác kinh doanh.

---

## 3.6 Màn hình Quản lý giao dịch hoàn tiền
### 3.6.1. Mục đích chức năng
Quản lý danh sách các giao dịch phát sinh hoàn tiền từ Merchant hoặc hệ thống trả về lại tài khoản ví của người dùng.
### 3.6.2 Giao diện chức năng
Hiển thị thông tin mã giao dịch gốc, lý do hoàn tiền, số tiền hoàn và trạng thái đã cộng tiền vào ví khách hàng hay chưa.
*[Chèn ảnh Giao diện Giao dịch hoàn tiền]*
Hình: Giao diện Quản lý giao dịch hoàn tiền
### 3.6.3 Kết quả thực hiện
Theo dõi sát sao các khoản bồi hoàn, đảm bảo quyền lợi của người dùng ví khi phát sinh giao dịch lỗi hoặc hủy đơn từ phía cửa hàng.

---

## 3.7 Màn hình Báo cáo hiệu quả hoạt động Merchant
### 3.7.1. Mục đích chức năng
Tổng hợp hiệu quả hoạt động của từng Merchant, cung cấp số liệu về tổng số đơn hàng, đơn thành công và tổng doanh thu.
### 3.7.2 Giao diện chức năng
Hiển thị danh sách các Merchant đi kèm với các cột thống kê hiệu suất (số đơn, doanh thu, tỷ lệ thành công).
*[Chèn ảnh Giao diện Báo cáo hiệu quả Merchant]*
Hình: Giao diện Báo cáo hiệu quả hoạt động Merchant
### 3.7.3 Kết quả thực hiện
Đánh giá được tiềm năng và hiệu quả kinh doanh của từng đối tác, làm cơ sở để đưa ra các chương trình khuyến mãi hoặc hỗ trợ phù hợp.

---

## 3.8 Màn hình Báo cáo doanh thu phí MDR
### 3.8.1. Mục đích chức năng
Giúp quản trị viên thống kê tổng lợi nhuận thu được từ phí chiết khấu đối tác (MDR - Merchant Discount Rate).
### 3.8.2 Giao diện chức năng
Hiển thị biểu đồ doanh thu phí và bảng chi tiết các khoản phí thu được theo thời gian hoặc theo Merchant.
*[Chèn ảnh Giao diện Báo cáo doanh thu phí MDR]*
Hình: Giao diện Báo cáo doanh thu phí MDR
### 3.8.3 Kết quả thực hiện
Nắm bắt chính xác nguồn thu cốt lõi của nền tảng ví điện tử, hỗ trợ phân tích tài chính định kỳ.

---

## 3.9 Màn hình Tra cứu API Logs
### 3.9.1. Mục đích chức năng
Ghi lại toàn bộ lịch sử các giao tiếp (lệnh gọi) với hệ thống thông qua API, bao gồm thời gian, phương thức (GET/POST), trạng thái thành công/thất bại và dữ liệu chi tiết.
### 3.9.2 Giao diện chức năng
Danh sách các log request hệ thống, cho phép xem chi tiết payload (dữ liệu gửi/nhận) của từng request.
*[Chèn ảnh Giao diện API Logs]*
Hình: Giao diện Tra cứu API Logs
### 3.9.3 Kết quả thực hiện
Giúp kỹ sư hệ thống theo dõi hiệu suất, lưu lượng và phát hiện kịp thời các bất thường trong quá trình giao tiếp dữ liệu.

---

## 3.10 Màn hình Truy vết lỗi hệ thống (Error Logs)
### 3.10.1. Mục đích chức năng
Nơi tập trung ghi nhận các ngoại lệ, lỗi kỹ thuật (bugs) xảy ra trong quá trình hệ thống vận hành.
### 3.10.2 Giao diện chức năng
Bảng danh sách các lỗi kỹ thuật kèm mức độ nghiêm trọng (CRITICAL, ERROR), vị trí phát sinh lỗi và thông báo chi tiết (stack trace).
*[Chèn ảnh Giao diện Truy vết lỗi]*
Hình: Giao diện Truy vết lỗi hệ thống
### 3.10.3 Kết quả thực hiện
Giúp đội ngũ phát triển nhanh chóng khoanh vùng và khắc phục sự cố, giảm thiểu thời gian gián đoạn dịch vụ.

---

## 3.11 Màn hình Tra cứu Webhook Logs
### 3.11.1. Mục đích chức năng
Lưu trữ lịch sử các sự kiện Webhook (dữ liệu đẩy từ hệ thống này sang hệ thống khác hoặc từ đối tác về ví), đảm bảo việc đồng bộ dữ liệu diễn ra chính xác.
### 3.11.2 Giao diện chức năng
Hiển thị trạng thái các lệnh bắn Webhook sang hệ thống Merchant, số lần Retry và nội dung phản hồi từ server đối tác.
*[Chèn ảnh Giao diện Webhook Logs]*
Hình: Giao diện Tra cứu Webhook Logs
### 3.11.3 Kết quả thực hiện
Kiểm soát chặt chẽ việc tích hợp hệ thống, hỗ trợ đối tác Merchant gỡ lỗi (debug) khi họ không nhận được thông báo thanh toán.

---

## 3.12 Màn hình Tra cứu Nhật ký thao tác (Audit Logs)
### 3.12.1. Mục đích chức năng
Ghi lại nhật ký các thao tác quan trọng của người dùng và quản trị viên (ví dụ: ai đã sửa cấu hình, duyệt giao dịch, xóa dữ liệu...).
### 3.12.2 Giao diện chức năng
Bảng chi tiết thông tin: Thời gian, Tài khoản thực hiện thao tác, Hành động (Thêm/Sửa/Xóa) và Đối tượng bị tác động.
*[Chèn ảnh Giao diện Nhật ký thao tác]*
Hình: Giao diện Tra cứu Nhật ký thao tác (Audit Logs)
### 3.12.3 Kết quả thực hiện
Đảm bảo tính minh bạch và bảo mật của hệ thống. Dễ dàng truy cứu trách nhiệm khi có sự cố do thao tác sai lệch.

---

## 3.13 Màn hình Quản lý Roles & Permissions (Phân quyền)
### 3.13.1. Mục đích chức năng
Cho phép thiết lập và kiểm soát các nhóm quyền (Role) trong hệ thống theo cơ chuẩn RBAC với các quyền hạn chi tiết. Giúp quản trị viên phân bổ chính xác khả năng truy cập và thao tác cho từng đối tượng người dùng.
### 3.13.2 Giao diện chức năng
Danh sách các vai trò hiện có trong hệ thống. Khi tạo/sửa vai trò sẽ hiển thị Ma trận phân quyền cho phép tích chọn từng tính năng riêng biệt.
*[Chèn ảnh Giao diện Phân quyền]*
Hình: Giao diện Quản lý Phân quyền (Roles & Permissions)
### 3.13.3 Kết quả thực hiện
Tăng cường tính bảo mật, đảm bảo nguyên tắc đặc quyền tối thiểu (nhân viên chỉ nhìn thấy tính năng phục vụ cho công việc của họ).

---

## 3.14 Màn hình Cài đặt chung
### 3.14.1. Mục đích chức năng
Nơi quản lý toàn bộ các tham số hệ thống cốt lõi và cấu hình nghiệp vụ của ví điện tử (ví dụ: thời gian hết hạn mã QR, số lần thử lại Webhook, cấu hình bảo mật token...).
### 3.14.2 Giao diện chức năng
Giao diện trực quan liệt kê các biến môi trường/cấu hình, cho phép admin điều chỉnh giá trị dễ dàng kèm theo tính năng xem lịch sử sửa đổi.
*[Chèn ảnh Giao diện Cài đặt chung]*
Hình: Giao diện Cài đặt chung hệ thống
### 3.14.3 Kết quả thực hiện
Cho phép quản trị viên điều chỉnh cấu hình hệ thống một cách linh hoạt mà không cần can thiệp vào mã nguồn, giúp hệ thống phản ứng nhanh với các thay đổi nghiệp vụ.

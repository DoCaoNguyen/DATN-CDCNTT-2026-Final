# MEU Omni Solutions - UI/UX Pattern Audit

## Mục Đích
File này tổng hợp các pattern UI/UX tốt nhất từ project `meu-omni-solutions-frontend`, chọn lọc ra những thành phần phù hợp để áp dụng cho `Merchant Portal` (vốn đang sử dụng kiến trúc Vanilla CSS Modules), nhằm nâng cao trải nghiệm người dùng theo hướng SaaS chuyên nghiệp.

## 1. Pattern Được Chọn Lọc (Nên Lấy)
| Pattern | Vị trí trong MEU | Áp dụng vào Merchant Portal | Ghi chú / Cần tạo mới hay sửa |
|---------|-----------------|---------------------------|----------------------------|
| **KPI Card (Top)** | Hóa đơn bán hàng, Báo cáo bán hàng, Báo cáo dòng tiền | `PaymentOrders.jsx`, `Webhooks.jsx`, `Balance.jsx`, `Dashboard.jsx` | Tạo component `KPICard.jsx` (hoặc mở rộng `Card.jsx`). Background trắng, padding rộng, icon màu pastel, text số to rõ ràng. |
| **Search/Filter/Sort Toolbar** | Hóa đơn bán hàng list | `PaymentOrders.jsx`, `Transactions.jsx`, `Webhooks.jsx`, `ApiKeys.jsx` | Mở rộng `SearchInput.jsx` kết hợp thành layout `Toolbar` ngang, bao gồm các ô Filter, Sort nằm bên cạnh. |
| **Pill Date Filters** | Báo cáo bán hàng, Báo cáo dòng tiền | `Balance.jsx` (Báo cáo sao kê) | Tạo component `DatePill.jsx` hoặc tái sử dụng cấu trúc `Tabs.jsx` nhưng thiết kế nhỏ gọn hơn (Pill shape). |
| **Expandable Table Row** | Hóa đơn bán hàng list | `PaymentOrders.jsx`, `Webhooks.jsx` | Sửa `Table.jsx` để hỗ trợ render dropdown row, khi bấm chevron sẽ xổ ra 3 cards chi tiết ở dưới. |
| **Detail Page Layout (2 Cột)** | Chi tiết hóa đơn (Detail) | Modal của `PaymentOrders.jsx` và `Transactions.jsx` | Sửa `OrderDetailModal` & `TransactionDetailModal` thành dạng 2 cột (Left: Main content, Right: Summary/Metadata Sticky). |
| **Header Detail** | Chi tiết hóa đơn | Phía trên cùng của các Modal chi tiết | Thêm nút Back/Đóng mượt mà, Title rõ ràng kèm Badge Status bên cạnh. |
| **Badge Style** | Bảng danh sách & Detail | Toàn cục (`StatusBadge.jsx`) | Tinh chỉnh `StatusBadge.jsx`: nền nhạt (light background), chữ đậm màu, góc bo tròn mềm mại (radius lớn). |

## 2. Pattern KHÔNG Nên Lấy (Cần Tránh)
- **Cấu trúc Domain Bán hàng/Kho/POS**: Không copy các nghiệp vụ "Sản phẩm", "Tồn kho", "Chiết khấu", "Khách hàng" vì Merchant Portal là ví điện tử / cổng thanh toán (chỉ quản lý Đơn, Giao dịch, Dòng tiền).
- **Tailwind / shadcn**: Toàn bộ MEU dùng Tailwind. Merchant Portal chỉ dùng Vanilla CSS / CSS Modules. Tuyệt đối không copy class Tailwind.
- **Biểu đồ (Chart) phức tạp**: Nếu `Balance.jsx` không có library biểu đồ nhẹ sẵn có, KHÔNG cài thêm Recharts chỉ để cho giống MEU nếu chỉ để "cho có". Ta sẽ ưu tiên dùng bảng Statement.

## 3. Các File Merchant Portal Sẽ Ảnh Hưởng
- **UI Components (`src/components/ui/`)**: 
  - `Table.jsx` (Thêm expand row)
  - `Card.jsx` (Thêm variant cho KPI)
  - `StatusBadge.jsx` (Chỉnh màu & border)
  - Thêm `DatePill.jsx` / `Toolbar.jsx`.
- **Pages (`src/pages/`)**: 
  - `Dashboard.jsx`, `PaymentOrders.jsx`, `Transactions.jsx`, `Webhooks.jsx`, `Balance.jsx`, `ApiKeys.jsx`.
- **Modals (`src/components/ui/Modal/`)**:
  - `OrderDetailModal.jsx`, `TransactionDetailModal.jsx`, `WebhookDetailModal.jsx`.

## 4. Hành Động Tiếp Theo
1. Dựng layout KPI Cards, Toolbar, Expandable Table.
2. Nâng cấp CSS của Badge, Modal.
3. Apply logic này vào từng trang cụ thể trong Phase 6.

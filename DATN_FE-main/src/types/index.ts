// Định nghĩa cấu trúc chuẩn của mọi API trả về
export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  trace_id?: string;
}

// Payload gửi lên khi đăng nhập
export interface LoginPayload {
  login_id: string;
  password: string;
}

// Dữ liệu nhận về khi đăng nhập thành công
export interface LoginResponseData {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  user: {
    id: string;
    full_name?: string;
    role?: string;
  };
}
// Các cấu trúc cũ giữ nguyên ở trên...

// Dữ liệu KPI cho Admin Dashboard[cite: 9, 10, 11]
export interface DashboardKpis {
  total_users: number;
  active_wallets: number;
  total_merchants: number;
  payment_success_count: number;
  payment_success_amount: number;
  transfer_success_count: number;
  transfer_success_amount: number;
  topup_success_amount: number;
  refund_success_amount: number;
  callback_failed_count: number;
}
export interface UserDetail {
  id: string;              // Tương ứng: users.id
  full_name: string;       // Tương ứng: users.full_name
  email: string;           // Tương ứng: users.email
  phone: string;           // Tương ứng: users.phone
  status: 'ACTIVE' | 'LOCKED' | 'SUSPENDED'; // Tương ứng: users.status (hoặc wallets.status)
  wallet_no: string;       // SỬA Ở ĐÂY: Tương ứng với wallets.wallet_no (VD: WAL000001)
  balance: number;         // Tương ứng: wallet_balances.available_balance
  created_at: string;      // Tương ứng: users.created_at (hoặc lấy tạm một field thời gian)
}

// Payload tạo người dùng mới bám sát cấu trúc bảng 'users'
export interface CreateUserPayload {
  username: string;
  full_name: string;
  email: string;
  phone: string;
  password?: string;
  user_type?: 'USER' | 'ADMIN' | 'MERCHANT_USER'; 
}
// Cấu trúc dữ liệu Merchant
export interface MerchantDetail {
  id: string;
  merchant_code: string;
  merchant_name: string;
  business_type: string;
  email: string;
  phone: string;
  status: 'PENDING' | 'PENDING_REVIEW' | 'ACTIVE' | 'SUSPENDED' | 'REJECTED';
  default_callback_url: string | null;
  default_redirect_url?: string | null;
  api_key?: string | null; // Dùng để hiển thị trạng thái API Key
  created_at: string;
}

// Payload Đăng ký Merchant
export interface CreateMerchantPayload {
  merchant_code: string;
  merchant_name: string;
  business_type: string;
  email: string;
  phone: string;
  callback?: {
    default_callback_url: string;
    default_redirect_url: string;
  };
}

// Payload Cấu hình Callback
export interface ConfigCallbackPayload {
  default_callback_url: string;
  default_redirect_url: string;
}
// Cấu trúc Audit Log (Nhật ký thao tác nghiệp vụ)
export interface AuditLogDetail {
  id: string;
  trace_id: string;
  actor_type: string;
  actor_id: string;
  action: string;
  entity_type: string;
  entity_id: string;
  old_data: Record<string, unknown> | null;
  new_data: Record<string, unknown> | null;
  metadata: Record<string, unknown> | null;
  reason: string;
  ip_address: string;
  user_agent: string;
  created_at: string;
}

// Cấu trúc System Log (Nhật ký hệ thống & lỗi)
export interface SystemLogDetail {
  id: string;
  trace_id: string;
  level: 'INFO' | 'WARN' | 'ERROR' | 'CRITICAL';
  module: string;
  event: string;
  message: string;
  context: Record<string, unknown> | null;
  entity_type: string;
  entity_id: string;
  created_at: string;
}
// Cấu trúc Giao dịch tổng (Ledger Transaction)
export interface TransactionDetail {
  id: string;
  trans_code: string; // Mã giao dịch hệ thống
  trans_type: 'TOPUP' | 'TRANSFER' | 'PAYMENT' | 'REFUND';
  amount: number;
  status: 'PENDING' | 'SUCCESS' | 'FAILED' | 'REVERSED';
  description: string;
  source_id: string; // Tương ứng: ledger_transactions.source_id (Mã đơn hàng/Mã đối chiếu)
  created_at: string;
}

// Cấu trúc Chi tiết bút toán Kế toán (Ledger Entry)
export interface LedgerEntry {
  id: string;
  wallet_id: string;
  direction: 'DEBIT' | 'CREDIT'; // DEBIT: Trừ tiền, CREDIT: Cộng tiền
  amount: number;
  post_balance: number; // Số dư sau giao dịch
  description: string;
  created_at: string;
}
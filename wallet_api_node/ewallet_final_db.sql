-- =========================================================
-- ewallet_db.sql
-- Project: Xay dung vi dien tu va cong thanh toan
-- Version: FINAL 1.0
-- Purpose:
--   Fresh PostgreSQL schema for e-wallet + payment gateway demo.
--   Base direction: keep ewallet mobile/wallet features, merge selected
--   payment-safe improvements from db_wallets_demo_v2.sql.
--
-- Main improvements:
--   - RBAC, refresh token, login attempt tracking
--   - Ledger debit/credit with user wallet / merchant balance / system account
--   - Merchant API key hashing, merchant callback config, merchant balance
--   - Payment order, QR, callback/webhook retry, refund
--   - Strong idempotency by actor/path/resource
--   - Audit/system log with trace_id
--   - Mobile-friendly extensions: KYC, linked bank, withdrawal, notifications, devices, OTP
--
-- Note:
--   Run this file in a new/empty PostgreSQL database.
--   Recommended DB name: ewallet_db
--   ID convention: UUID primary keys are generated in Node.js backend.
-- =========================================================
--CREATE DATABASE ewallet_db;

-- CREATE EXTENSION IF NOT EXISTS pgcrypto; -- Không cần nếu UUID sinh ở backend

-- =========================================================
-- 1. ENUM TYPES
-- =========================================================

CREATE TYPE user_type AS ENUM ('USER', 'MERCHANT_USER', 'ADMIN', 'SUPER_ADMIN', 'SUPPORT_STAFF');
CREATE TYPE user_status AS ENUM ('ACTIVE', 'PENDING_VERIFY', 'LOCKED', 'BLOCKED', 'INACTIVE');

CREATE TYPE role_scope AS ENUM ('SYSTEM', 'MERCHANT');

CREATE TYPE wallet_status AS ENUM ('ACTIVE', 'LOCKED', 'CLOSED');
CREATE TYPE wallet_type AS ENUM ('PERSONAL');

CREATE TYPE ledger_transaction_type AS ENUM ('TOPUP', 'TRANSFER', 'PAYMENT', 'REFUND', 'WITHDRAWAL', 'ADJUSTMENT');
CREATE TYPE transaction_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'CANCELED');
CREATE TYPE ledger_entry_type AS ENUM ('DEBIT', 'CREDIT');
CREATE TYPE ledger_account_type AS ENUM ('USER_WALLET', 'MERCHANT_BALANCE', 'SYSTEM_ACCOUNT');

CREATE TYPE deposit_method AS ENUM ('SANDBOX_BANK', 'SANDBOX_CARD');
CREATE TYPE transfer_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'CANCELED');
CREATE TYPE deposit_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'CANCELED');
CREATE TYPE withdrawal_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'CANCELED');

CREATE TYPE merchant_status AS ENUM ('PENDING_REVIEW', 'ACTIVE', 'SUSPENDED', 'REJECTED', 'CLOSED');
CREATE TYPE business_type AS ENUM ('ONLINE', 'OFFLINE', 'BOTH');
CREATE TYPE api_key_status AS ENUM ('ACTIVE', 'REVOKED', 'EXPIRED');
CREATE TYPE api_environment AS ENUM ('SANDBOX', 'LIVE');

CREATE TYPE payment_order_status AS ENUM ('PENDING', 'PAID', 'EXPIRED', 'CANCELED', 'FAILED');
CREATE TYPE payment_transaction_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED');
CREATE TYPE payment_refund_status AS ENUM ('NONE', 'PARTIALLY_REFUNDED', 'FULLY_REFUNDED');
CREATE TYPE qr_status AS ENUM ('ACTIVE', 'USED', 'EXPIRED', 'CANCELED');

CREATE TYPE refund_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'CANCELED');

CREATE TYPE webhook_event_type AS ENUM (
    'PAYMENT_SUCCESS',
    'PAYMENT_FAILED',
    'PAYMENT_EXPIRED',
    'PAYMENT_CANCELED',
    'REFUND_SUCCESS',
    'REFUND_FAILED'
);
CREATE TYPE webhook_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'RETRYING');

CREATE TYPE idempotency_actor_type AS ENUM ('USER', 'MERCHANT', 'ADMIN', 'SYSTEM');
CREATE TYPE idempotency_status AS ENUM ('PROCESSING', 'COMPLETED', 'FAILED');

CREATE TYPE log_level AS ENUM ('INFO', 'WARN', 'ERROR', 'CRITICAL');
CREATE TYPE audit_actor_type AS ENUM ('USER', 'MERCHANT', 'ADMIN', 'SYSTEM');

CREATE TYPE setting_value_type AS ENUM ('STRING', 'NUMBER', 'BOOLEAN', 'JSON');

-- =========================================================
-- 2. COMMON UPDATED_AT TRIGGER
-- =========================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =========================================================
-- 3. AUTH / RBAC
-- =========================================================

CREATE TABLE users (
    id UUID PRIMARY KEY, -- Khóa chính
    user_type user_type NOT NULL DEFAULT 'USER', -- Loại tài khoản
    full_name VARCHAR(255) NOT NULL, -- Họ tên
    username VARCHAR(100), -- Tên đăng nhập
    email VARCHAR(255), -- Email
    phone VARCHAR(20), -- Số điện thoại
    password_hash TEXT NOT NULL, -- Mật khẩu đã hash
    --role VARCHAR(50) NOT NULL DEFAULT 'USER', -- Role cũ 
    status user_status NOT NULL DEFAULT 'ACTIVE', -- Trạng thái tài khoản
    --failed_login_count INT NOT NULL DEFAULT 0, -- Số lần login sai
    failed_login_attempts INT NOT NULL DEFAULT 0, -- Số lần login sai
    locked_until TIMESTAMPTZ, -- Khóa đến thời điểm
    last_login_at TIMESTAMPTZ, -- Lần đăng nhập cuối
    is_kyc_verified BOOLEAN NOT NULL DEFAULT false, -- Đã xác thực KYC
    pin_hash TEXT, -- PIN đã hash
    token_version INT NOT NULL DEFAULT 1, -- Phiên bản token
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT users_username_unique UNIQUE (username),
    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_phone_unique UNIQUE (phone),
    --CONSTRAINT users_failed_login_count_check CHECK (failed_login_count >= 0),
    CONSTRAINT users_failed_login_attempts_check CHECK (failed_login_attempts >= 0),
    CONSTRAINT users_token_version_check CHECK (token_version >= 1)
);

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE roles (
    id UUID PRIMARY KEY, -- Khóa chính
    code VARCHAR(100) NOT NULL UNIQUE, -- Mã role
    name VARCHAR(255) NOT NULL, -- Tên role
    scope role_scope NOT NULL DEFAULT 'SYSTEM', -- Phạm vi role
    description TEXT, -- Mô tả
    is_system BOOLEAN NOT NULL DEFAULT false, -- Role hệ thống
    is_active BOOLEAN NOT NULL DEFAULT true, -- Còn hoạt động
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() -- Thời điểm cập nhật
);

CREATE TRIGGER trg_roles_updated_at
BEFORE UPDATE ON roles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE permissions (
    id UUID PRIMARY KEY, -- Khóa chính
    code VARCHAR(150) NOT NULL UNIQUE, -- Mã quyền
    name VARCHAR(255) NOT NULL, -- Tên quyền
    description TEXT, -- Mô tả
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() -- Thời điểm tạo
);

CREATE TABLE user_roles (
    user_id UUID NOT NULL REFERENCES users(id), -- User được gán role
    role_id UUID NOT NULL REFERENCES roles(id), -- Role được gán
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id), -- Role được cấp quyền
    permission_id UUID NOT NULL REFERENCES permissions(id), -- Quyền được cấp
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY, -- Khóa chính
    user_id UUID NOT NULL REFERENCES users(id), -- User sở hữu token
    token_hash TEXT NOT NULL UNIQUE, -- Token đã hash
    token_family_id UUID NOT NULL, -- Nhóm refresh token
    expires_at TIMESTAMPTZ NOT NULL, -- Thời điểm hết hạn
    revoked_at TIMESTAMPTZ, -- Thời điểm thu hồi
    reused_at TIMESTAMPTZ, -- Thời điểm dùng lại
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    created_by_ip VARCHAR(45), -- IP tạo token
    revoked_by_ip VARCHAR(45), -- IP thu hồi token
    user_agent VARCHAR(500) -- Thông tin thiết bị/trình duyệt
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_family ON refresh_tokens(token_family_id);

CREATE TABLE password_resets (
    id UUID PRIMARY KEY, -- Khóa chính
    user_id UUID NOT NULL REFERENCES users(id), -- User reset mật khẩu
    reset_token_hash TEXT NOT NULL UNIQUE, -- Token reset đã hash
    expires_at TIMESTAMPTZ NOT NULL, -- Thời điểm hết hạn
    used_at TIMESTAMPTZ, -- Thời điểm sử dụng
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    ip_address VARCHAR(45), -- Địa chỉ IP
    user_agent VARCHAR(500) -- Thông tin thiết bị/trình duyệt
);

CREATE INDEX idx_password_resets_user_id ON password_resets(user_id);

CREATE TABLE auth_login_attempts (
    id BIGSERIAL PRIMARY KEY, -- Khóa chính
    login_id VARCHAR(255) NOT NULL, -- Email/phone/username đăng nhập
    user_id UUID REFERENCES users(id), -- User nếu xác định được
    success BOOLEAN NOT NULL DEFAULT false, -- Đăng nhập thành công
    failure_reason VARCHAR(255), -- Lý do thất bại
    ip_address VARCHAR(45), -- Địa chỉ IP
    user_agent VARCHAR(500), -- Thông tin thiết bị/trình duyệt
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() -- Thời điểm tạo
);

CREATE INDEX idx_auth_login_attempts_login_id ON auth_login_attempts(login_id);
CREATE INDEX idx_auth_login_attempts_created_at ON auth_login_attempts(created_at DESC);
--CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- =========================================================
-- 4. WALLET
-- =========================================================

CREATE TABLE wallets (
    id UUID PRIMARY KEY, -- Khóa chính
    user_id UUID NOT NULL REFERENCES users(id), -- Chủ ví
    wallet_no VARCHAR(50) NOT NULL UNIQUE, -- Mã ví
    wallet_code VARCHAR(50), -- Mã ví cũ tương thích
    wallet_type wallet_type NOT NULL DEFAULT 'PERSONAL', -- Loại ví
    currency VARCHAR(10) NOT NULL DEFAULT 'VND', -- Loại tiền tệ
    status wallet_status NOT NULL DEFAULT 'ACTIVE', -- Trạng thái ví
    lock_reason TEXT, -- Lý do khóa ví
    locked_at TIMESTAMPTZ, -- Thời điểm khóa
    locked_by UUID REFERENCES users(id), -- Admin khóa ví
    closed_at TIMESTAMPTZ, -- Thời điểm đóng ví
    pin_failed_attempts INT NOT NULL DEFAULT 0, -- Số lần sai PIN
    pin_locked_until TIMESTAMPTZ, -- Khóa PIN đến lúc
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT wallets_user_id_unique UNIQUE (user_id),
    CONSTRAINT wallets_wallet_code_unique UNIQUE (wallet_code),
    CONSTRAINT wallets_pin_failed_attempts_check CHECK (pin_failed_attempts >= 0)
);

CREATE TRIGGER trg_wallets_updated_at
BEFORE UPDATE ON wallets
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_wallets_status ON wallets(status);
CREATE INDEX idx_wallets_wallet_code ON wallets(wallet_code);

CREATE TABLE wallet_balances (
    wallet_id UUID PRIMARY KEY REFERENCES wallets(id), -- Khóa chính là ví
    available_balance BIGINT NOT NULL DEFAULT 0, -- Số dư khả dụng
    locked_balance BIGINT NOT NULL DEFAULT 0, -- Số dư bị khóa
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT wallet_balances_available_non_negative CHECK (available_balance >= 0),
    CONSTRAINT wallet_balances_locked_non_negative CHECK (locked_balance >= 0)
);

CREATE TRIGGER trg_wallet_balances_updated_at
BEFORE UPDATE ON wallet_balances
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- 4B. MOBILE / WALLET EXTENSIONS FROM ewallet_db.sql
-- =========================================================

CREATE TABLE user_kyc (
    id UUID PRIMARY KEY, -- Khóa chính
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE, -- User KYC
    id_number VARCHAR(20) UNIQUE, -- Số giấy tờ
    full_name VARCHAR(255), -- Họ tên
    dob VARCHAR(20), -- Ngày sinh
    gender VARCHAR(10), -- Giới tính
    address TEXT, -- Địa chỉ
    id_front_image TEXT NOT NULL, -- Ảnh mặt trước
    id_back_image TEXT NOT NULL, -- Ảnh mặt sau
    face_image TEXT NOT NULL, -- Ảnh khuôn mặt
    kyc_status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- Trạng thái KYC
    face_match_score NUMERIC, -- Điểm khớp mặt
    rejection_reason TEXT, -- Lý do từ chối
    reviewed_by UUID REFERENCES users(id), -- Người duyệt
    reviewed_at TIMESTAMPTZ, -- Thời điểm duyệt
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT user_kyc_status_check CHECK (kyc_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    CONSTRAINT user_kyc_face_match_score_check CHECK (face_match_score IS NULL OR (face_match_score >= 0 AND face_match_score <= 100))
);

CREATE TRIGGER trg_user_kyc_updated_at
BEFORE UPDATE ON user_kyc
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_user_kyc_status ON user_kyc(kyc_status);
CREATE INDEX idx_user_kyc_user_id ON user_kyc(user_id);

CREATE TABLE wallet_linked_banks (
    id UUID PRIMARY KEY, -- Khóa chính
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE, -- Ví liên kết ngân hàng
    bank_name VARCHAR(100) NOT NULL, -- Tên ngân hàng
    bank_code VARCHAR(20), -- Mã ngân hàng
    card_number VARCHAR(50) NOT NULL, -- Số thẻ/tài khoản
    card_holder_name VARCHAR(255) NOT NULL, -- Tên chủ thẻ
    issue_date VARCHAR(10), -- Ngày phát hành
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- Trạng thái liên kết
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT wallet_linked_banks_status_check CHECK (status IN ('ACTIVE', 'INACTIVE', 'VERIFIED', 'UNVERIFIED', 'REMOVED'))
);

CREATE TRIGGER trg_wallet_linked_banks_updated_at
BEFORE UPDATE ON wallet_linked_banks
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_wallet_linked_banks_wallet_id ON wallet_linked_banks(wallet_id);
CREATE INDEX idx_wallet_linked_banks_status ON wallet_linked_banks(status);

CREATE TABLE notifications (
    id UUID PRIMARY KEY, -- Khóa chính
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- User nhận thông báo
    title VARCHAR(255) NOT NULL, -- Tiêu đề
    content TEXT NOT NULL, -- Nội dung
    notification_type VARCHAR(50), -- Loại thông báo
    reference_id UUID, -- ID liên quan
    status VARCHAR(20) NOT NULL DEFAULT 'UNREAD', -- Trạng thái đọc
    read_at TIMESTAMPTZ, -- Thời điểm đọc
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT notifications_status_check CHECK (status IN ('UNREAD', 'READ', 'ARCHIVED'))
);

CREATE TRIGGER trg_notifications_updated_at
BEFORE UPDATE ON notifications
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_notifications_user_status ON notifications(user_id, status);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

CREATE TABLE user_devices (
    id UUID PRIMARY KEY, -- Khóa chính
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- User sở hữu thiết bị
    fcm_token VARCHAR(255) NOT NULL UNIQUE, -- Token push FCM
    device_name VARCHAR(100), -- Tên thiết bị
    device_type VARCHAR(20), -- Loại thiết bị
    last_seen_at TIMESTAMPTZ, -- Lần hoạt động gần nhất
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT user_devices_device_type_check CHECK (device_type IS NULL OR device_type IN ('ANDROID', 'IOS', 'WEB', 'OTHER'))
);

CREATE TRIGGER trg_user_devices_updated_at
BEFORE UPDATE ON user_devices
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);

CREATE TABLE otp_tracking (
    id UUID PRIMARY KEY, -- Khóa chính
    phone VARCHAR(20), -- SĐT nhận OTP
    email VARCHAR(255), -- Email nhận OTP
    otp_hash TEXT NOT NULL, -- OTP đã hash
    purpose VARCHAR(50) NOT NULL DEFAULT 'AUTH', -- Mục đích OTP
    failed_attempts INT NOT NULL DEFAULT 0, -- Số lần nhập sai
    locked_until TIMESTAMPTZ, -- Khóa đến thời điểm
    expired_at TIMESTAMPTZ NOT NULL, -- Thời điểm hết hạn
    used_at TIMESTAMPTZ, -- Thời điểm sử dụng
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    CONSTRAINT otp_tracking_target_check CHECK (phone IS NOT NULL OR email IS NOT NULL),
    CONSTRAINT otp_tracking_failed_attempts_check CHECK (failed_attempts >= 0)
);

CREATE INDEX idx_otp_tracking_phone ON otp_tracking(phone);
CREATE INDEX idx_otp_tracking_email ON otp_tracking(email);
CREATE INDEX idx_otp_tracking_expired_at ON otp_tracking(expired_at);


-- =========================================================
-- 5. MERCHANT
-- =========================================================

CREATE TABLE merchants (
    id UUID PRIMARY KEY, -- Khóa chính
    merchant_code VARCHAR(50) NOT NULL UNIQUE, -- Mã merchant
    merchant_name VARCHAR(255) NOT NULL, -- Tên merchant
    business_type business_type NOT NULL DEFAULT 'ONLINE', -- Loại kinh doanh
    representative_name VARCHAR(255), -- Người đại diện
    tax_code VARCHAR(50), -- Mã số thuế
    phone VARCHAR(20), -- Số điện thoại
    email VARCHAR(255), -- Email
    address TEXT, -- Địa chỉ
    default_callback_url TEXT, -- Callback mặc định
    default_redirect_url TEXT, -- Redirect mặc định
    webhook_secret_hash TEXT, -- Secret webhook đã hash
    status merchant_status NOT NULL DEFAULT 'PENDING_REVIEW', -- Trạng thái merchant
    risk_note TEXT, -- Ghi chú rủi ro
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT merchants_email_unique UNIQUE (email)
);

CREATE TRIGGER trg_merchants_updated_at
BEFORE UPDATE ON merchants
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_merchants_status ON merchants(status);


CREATE TABLE merchant_users (
    id UUID PRIMARY KEY, -- Khóa chính
    merchant_id UUID NOT NULL REFERENCES merchants(id), -- Merchant sở hữu
    user_id UUID NOT NULL REFERENCES users(id), -- User thuộc merchant
    role_code VARCHAR(100) NOT NULL DEFAULT 'MERCHANT_STAFF', -- Role trong merchant
    is_owner BOOLEAN NOT NULL DEFAULT false, -- Là chủ merchant
    is_active BOOLEAN NOT NULL DEFAULT true, -- Còn hoạt động
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT merchant_users_merchant_user_unique UNIQUE (merchant_id, user_id)
);

CREATE TRIGGER trg_merchant_users_updated_at
BEFORE UPDATE ON merchant_users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_merchant_users_user_id ON merchant_users(user_id);
CREATE INDEX idx_merchant_users_merchant_id ON merchant_users(merchant_id);

CREATE TABLE merchant_api_keys (
    id UUID PRIMARY KEY, -- Khóa chính
    merchant_id UUID NOT NULL REFERENCES merchants(id), -- Merchant sở hữu key
    key_name VARCHAR(100) NOT NULL, -- Tên API key
    api_key VARCHAR(255) NOT NULL UNIQUE, -- API key
    api_secret_hash TEXT NOT NULL, -- API secret đã hash
    environment api_environment NOT NULL DEFAULT 'SANDBOX', -- Môi trường
    status api_key_status NOT NULL DEFAULT 'ACTIVE', -- Trạng thái key
    last_used_at TIMESTAMPTZ, -- Lần dùng gần nhất
    expired_at TIMESTAMPTZ, -- Thời điểm hết hạn
    revoked_at TIMESTAMPTZ, -- Thời điểm thu hồi
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() -- Thời điểm cập nhật
);

CREATE TRIGGER trg_merchant_api_keys_updated_at
BEFORE UPDATE ON merchant_api_keys
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_merchant_api_keys_merchant_id ON merchant_api_keys(merchant_id);
CREATE INDEX idx_merchant_api_keys_status ON merchant_api_keys(status);

CREATE TABLE merchant_callback_configs (
    id UUID PRIMARY KEY, -- Khóa chính
    merchant_id UUID NOT NULL REFERENCES merchants(id), -- Merchant cấu hình
    default_callback_url TEXT NOT NULL, -- Callback mặc định
    default_redirect_url TEXT, -- Redirect mặc định
    webhook_secret_hash TEXT NOT NULL, -- Secret webhook đã hash
    callback_enabled BOOLEAN NOT NULL DEFAULT true, -- Bật callback
    retry_enabled BOOLEAN NOT NULL DEFAULT true, -- Bật retry
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT merchant_callback_configs_merchant_unique UNIQUE (merchant_id)
);

CREATE TRIGGER trg_merchant_callback_configs_updated_at
BEFORE UPDATE ON merchant_callback_configs
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE merchant_balances (
    merchant_id UUID PRIMARY KEY REFERENCES merchants(id), -- Khóa chính merchant
    available_balance BIGINT NOT NULL DEFAULT 0, -- Số dư khả dụng
    pending_balance BIGINT NOT NULL DEFAULT 0, -- Số dư chờ xử lý
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT merchant_balances_available_non_negative CHECK (available_balance >= 0),
    CONSTRAINT merchant_balances_pending_non_negative CHECK (pending_balance >= 0)
);

CREATE TRIGGER trg_merchant_balances_updated_at
BEFORE UPDATE ON merchant_balances
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =========================================================
-- 6. PLATFORM SETTINGS / CODE SEQUENCES
-- =========================================================

CREATE TABLE code_sequences (
    id UUID PRIMARY KEY, -- Khóa chính
    resource_name VARCHAR(100) NOT NULL UNIQUE, -- Tên resource sinh mã
    prefix VARCHAR(20) NOT NULL, -- Tiền tố mã
    current_value BIGINT NOT NULL DEFAULT 0, -- Giá trị hiện tại
    padding INT NOT NULL DEFAULT 6, -- Độ dài số
    reset_policy VARCHAR(20) NOT NULL DEFAULT 'NONE', -- Chính sách reset
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT code_sequences_current_value_check CHECK (current_value >= 0),
    CONSTRAINT code_sequences_padding_check CHECK (padding > 0)
);

CREATE TRIGGER trg_code_sequences_updated_at
BEFORE UPDATE ON code_sequences
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE app_settings (
    id UUID PRIMARY KEY, -- Khóa chính
    setting_group VARCHAR(100) NOT NULL, -- Nhóm cấu hình
    setting_key VARCHAR(150) NOT NULL UNIQUE, -- Khóa cấu hình
    setting_value JSONB NOT NULL, -- Giá trị cấu hình
    value_type setting_value_type NOT NULL DEFAULT 'STRING', -- Kiểu giá trị
    description TEXT, -- Mô tả cấu hình
    is_sensitive BOOLEAN NOT NULL DEFAULT false, -- Dữ liệu nhạy cảm
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() -- Thời điểm cập nhật
);

CREATE TRIGGER trg_app_settings_updated_at
BEFORE UPDATE ON app_settings
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE setting_histories (
    id BIGSERIAL PRIMARY KEY, -- Khóa chính
    setting_key VARCHAR(150) NOT NULL, -- Khóa cấu hình
    old_value JSONB, -- Giá trị cũ
    new_value JSONB, -- Giá trị mới
    changed_by UUID REFERENCES users(id), -- Người thay đổi
    reason TEXT, -- Lý do
    trace_id VARCHAR(100), -- Mã truy vết
    ip_address VARCHAR(45), -- Địa chỉ IP
    user_agent VARCHAR(500), -- Thông tin thiết bị/trình duyệt
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() -- Thời điểm tạo
);

CREATE INDEX idx_setting_histories_key ON setting_histories(setting_key);
CREATE INDEX idx_setting_histories_created_at ON setting_histories(created_at DESC);

-- =========================================================
-- 7. LEDGER
-- =========================================================

CREATE TABLE ledger_transactions (
    id UUID PRIMARY KEY, -- Khóa chính
    transaction_no VARCHAR(50) NOT NULL UNIQUE, -- Mã giao dịch
    transaction_type ledger_transaction_type NOT NULL, -- Loại giao dịch
    status transaction_status NOT NULL DEFAULT 'PENDING', -- Trạng thái ledger
    amount BIGINT NOT NULL, -- Tổng tiền giao dịch
    currency VARCHAR(10) NOT NULL DEFAULT 'VND', -- Loại tiền tệ
    source_type VARCHAR(50), -- Loại nghiệp vụ gốc
    source_id UUID, -- ID nghiệp vụ gốc
    idempotency_key VARCHAR(255), -- Chống xử lý trùng
    description TEXT, -- Mô tả
    created_by UUID REFERENCES users(id), -- Người tạo
    completed_at TIMESTAMPTZ, -- Thời điểm hoàn tất
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT ledger_transactions_amount_positive CHECK (amount > 0)
);

CREATE TRIGGER trg_ledger_transactions_updated_at
BEFORE UPDATE ON ledger_transactions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_ledger_transactions_type_status ON ledger_transactions(transaction_type, status);
CREATE INDEX idx_ledger_transactions_source ON ledger_transactions(source_type, source_id);
CREATE INDEX idx_ledger_transactions_created_at ON ledger_transactions(created_at DESC);

CREATE TABLE ledger_entries (
    id UUID PRIMARY KEY, -- Khóa chính
    ledger_transaction_id UUID NOT NULL REFERENCES ledger_transactions(id), -- Giao dịch ledger cha
    account_type ledger_account_type NOT NULL, -- Loại tài khoản
    wallet_id UUID REFERENCES wallets(id), -- Ví nếu là user
    merchant_id UUID REFERENCES merchants(id), -- Merchant nếu có
    system_account_code VARCHAR(50), -- Mã tài khoản hệ thống
    entry_type ledger_entry_type NOT NULL, -- Chiều tiền
    amount BIGINT NOT NULL, -- Số tiền entry
    balance_before BIGINT NOT NULL, -- Số dư trước
    balance_after BIGINT NOT NULL, -- Số dư sau
    description TEXT, -- Mô tả
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    CONSTRAINT ledger_entries_amount_positive CHECK (amount > 0),
    CONSTRAINT ledger_entries_balance_before_non_negative CHECK (balance_before >= 0),
    CONSTRAINT ledger_entries_balance_after_non_negative CHECK (balance_after >= 0),
    CONSTRAINT ledger_entries_account_target_check CHECK (
        (account_type = 'USER_WALLET' AND wallet_id IS NOT NULL AND merchant_id IS NULL AND system_account_code IS NULL)
        OR
        (account_type = 'MERCHANT_BALANCE' AND merchant_id IS NOT NULL AND wallet_id IS NULL AND system_account_code IS NULL)
        OR
        (account_type = 'SYSTEM_ACCOUNT' AND system_account_code IS NOT NULL AND wallet_id IS NULL AND merchant_id IS NULL)
    )
);

CREATE INDEX idx_ledger_entries_transaction_id ON ledger_entries(ledger_transaction_id);
CREATE INDEX idx_ledger_entries_wallet_id_created_at ON ledger_entries(wallet_id, created_at DESC);
CREATE INDEX idx_ledger_entries_merchant_id_created_at ON ledger_entries(merchant_id, created_at DESC);
CREATE INDEX idx_ledger_entries_created_at ON ledger_entries(created_at DESC);

-- =========================================================
-- 8. TOPUP / TRANSFER
-- =========================================================

CREATE TABLE deposit_transactions (
    id UUID PRIMARY KEY, -- Khóa chính
    deposit_no VARCHAR(50) NOT NULL UNIQUE, -- Mã nạp tiền
    user_id UUID NOT NULL REFERENCES users(id), -- User nạp tiền
    wallet_id UUID NOT NULL REFERENCES wallets(id), -- Ví nhận tiền
    amount BIGINT NOT NULL, -- Số tiền
    currency VARCHAR(10) NOT NULL DEFAULT 'VND', -- Loại tiền tệ
    deposit_method deposit_method NOT NULL DEFAULT 'SANDBOX_BANK', -- Phương thức nạp
    external_reference VARCHAR(255), -- Mã tham chiếu ngoài
    ledger_transaction_id UUID REFERENCES ledger_transactions(id), -- Ledger tổng
    idempotency_key VARCHAR(255) NOT NULL, -- Chống xử lý trùng
    status deposit_status NOT NULL DEFAULT 'PENDING', -- Trạng thái nạp
    failure_reason TEXT, -- Lý do thất bại
    note TEXT, -- Ghi chú
    completed_at TIMESTAMPTZ, -- Thời điểm hoàn tất
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT deposit_transactions_amount_positive CHECK (amount > 0)
);

CREATE TRIGGER trg_deposit_transactions_updated_at
BEFORE UPDATE ON deposit_transactions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_deposit_transactions_user_id_created_at ON deposit_transactions(user_id, created_at DESC);
CREATE INDEX idx_deposit_transactions_wallet_id_created_at ON deposit_transactions(wallet_id, created_at DESC);
CREATE INDEX idx_deposit_transactions_status ON deposit_transactions(status);
CREATE INDEX idx_deposit_transactions_created_at ON deposit_transactions(created_at DESC);


CREATE TABLE withdrawal_transactions (
    id UUID PRIMARY KEY, -- Khóa chính
    withdrawal_no VARCHAR(50) UNIQUE, -- Mã rút tiền
    user_id UUID NOT NULL REFERENCES users(id), -- User rút tiền
    wallet_id UUID NOT NULL REFERENCES wallets(id), -- Ví rút tiền
    linked_bank_id UUID REFERENCES wallet_linked_banks(id), -- Ngân hàng liên kết
    amount BIGINT NOT NULL, -- Số tiền
    currency VARCHAR(10) NOT NULL DEFAULT 'VND', -- Loại tiền tệ
    withdrawal_method VARCHAR(50) NOT NULL DEFAULT 'SANDBOX_BANK', -- Phương thức rút
    external_reference VARCHAR(255), -- Mã tham chiếu ngoài
    ledger_transaction_id UUID REFERENCES ledger_transactions(id), -- Ledger tổng
    idempotency_key VARCHAR(255), -- Chống xử lý trùng
    status withdrawal_status NOT NULL DEFAULT 'PENDING', -- Trạng thái rút
    bank_code VARCHAR(20), -- Mã ngân hàng
    account_number VARCHAR(50), -- Số tài khoản
    failure_reason TEXT, -- Lý do thất bại
    completed_at TIMESTAMPTZ, -- Thời điểm hoàn tất
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT withdrawal_transactions_amount_positive CHECK (amount > 0)
);

CREATE TRIGGER trg_withdrawal_transactions_updated_at
BEFORE UPDATE ON withdrawal_transactions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_withdrawal_transactions_user_id_created_at ON withdrawal_transactions(user_id, created_at DESC);
CREATE INDEX idx_withdrawal_transactions_wallet_id_created_at ON withdrawal_transactions(wallet_id, created_at DESC);
CREATE INDEX idx_withdrawal_transactions_linked_bank_id ON withdrawal_transactions(linked_bank_id);
CREATE INDEX idx_withdrawal_transactions_status ON withdrawal_transactions(status);
CREATE INDEX idx_withdrawal_transactions_created_at ON withdrawal_transactions(created_at DESC);

CREATE TABLE wallet_transfers (
    id UUID PRIMARY KEY, -- Khóa chính
    transfer_no VARCHAR(50) NOT NULL UNIQUE, -- Mã chuyển tiền
    sender_user_id UUID NOT NULL REFERENCES users(id), -- User gửi
    sender_wallet_id UUID NOT NULL REFERENCES wallets(id), -- Ví gửi
    receiver_user_id UUID NOT NULL REFERENCES users(id), -- User nhận
    receiver_wallet_id UUID NOT NULL REFERENCES wallets(id), -- Ví nhận
    amount BIGINT NOT NULL, -- Số tiền
    currency VARCHAR(10) NOT NULL DEFAULT 'VND', -- Loại tiền tệ
    description VARCHAR(255), -- Nội dung chuyển
    ledger_transaction_id UUID REFERENCES ledger_transactions(id), -- Ledger tổng
    idempotency_key VARCHAR(255) NOT NULL, -- Chống xử lý trùng
    status transfer_status NOT NULL DEFAULT 'PENDING', -- Trạng thái chuyển
    failure_reason TEXT, -- Lý do thất bại
    completed_at TIMESTAMPTZ, -- Thời điểm hoàn tất
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT wallet_transfers_amount_positive CHECK (amount > 0),
    CONSTRAINT wallet_transfers_not_self_wallet CHECK (sender_wallet_id <> receiver_wallet_id),
    CONSTRAINT wallet_transfers_not_self_user CHECK (sender_user_id <> receiver_user_id)
);

CREATE TRIGGER trg_wallet_transfers_updated_at
BEFORE UPDATE ON wallet_transfers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_wallet_transfers_sender_wallet_created_at ON wallet_transfers(sender_wallet_id, created_at DESC);
CREATE INDEX idx_wallet_transfers_receiver_wallet_created_at ON wallet_transfers(receiver_wallet_id, created_at DESC);
CREATE INDEX idx_wallet_transfers_status ON wallet_transfers(status);
CREATE INDEX idx_wallet_transfers_created_at ON wallet_transfers(created_at DESC);

-- =========================================================
-- 9. PAYMENT GATEWAY / QR PAYMENT
-- =========================================================

CREATE TABLE payment_orders (
    id UUID PRIMARY KEY, -- Khóa chính
    merchant_id UUID NOT NULL REFERENCES merchants(id), -- Merchant liên kết
    payment_no VARCHAR(50) NOT NULL UNIQUE, -- Mã thanh toán
    merchant_order_id VARCHAR(100) NOT NULL, -- Mã đơn merchant
    amount BIGINT NOT NULL, -- Số tiền
    currency VARCHAR(10) NOT NULL DEFAULT 'VND', -- Loại tiền tệ
    callback_url TEXT NOT NULL, -- URL nhận webhook
    redirect_url TEXT, -- URL quay lại merchant
    description TEXT, -- Mô tả
    status payment_order_status NOT NULL DEFAULT 'PENDING', -- Trạng thái payment
    refund_status payment_refund_status NOT NULL DEFAULT 'NONE', -- Trạng thái refund
    refunded_amount BIGINT NOT NULL DEFAULT 0, -- Số tiền đã hoàn
    idempotency_key VARCHAR(255)  NOT NULL, -- Chống xử lý trùng
    metadata JSONB, -- Dữ liệu bổ sung
    expired_at TIMESTAMPTZ NOT NULL, -- Hạn thanh toán
    paid_at TIMESTAMPTZ, -- Thời điểm thanh toán
    canceled_at TIMESTAMPTZ, -- Thời điểm hủy
    failed_reason TEXT, -- Lý do lỗi
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT payment_orders_merchant_order_unique UNIQUE (merchant_id, merchant_order_id),
    CONSTRAINT payment_orders_amount_positive CHECK (amount > 0),
    CONSTRAINT payment_orders_refunded_non_negative CHECK (refunded_amount >= 0),
    CONSTRAINT payment_orders_merchant_idempotency_unique UNIQUE (merchant_id, idempotency_key),
    CONSTRAINT payment_orders_refunded_not_over_amount CHECK (refunded_amount <= amount)
);

CREATE TRIGGER trg_payment_orders_updated_at
BEFORE UPDATE ON payment_orders
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_payment_orders_merchant_created_at ON payment_orders(merchant_id, created_at DESC);
CREATE INDEX idx_payment_orders_status ON payment_orders(status);
CREATE INDEX idx_payment_orders_expired_at ON payment_orders(expired_at);
CREATE INDEX idx_payment_orders_created_at ON payment_orders(created_at DESC);

CREATE TABLE payment_qr_codes (
    id UUID PRIMARY KEY, -- Khóa chính
    payment_order_id UUID NOT NULL REFERENCES payment_orders(id), -- Đơn thanh toán
    qr_token VARCHAR(255) NOT NULL UNIQUE, -- Token QR
    qr_payload TEXT NOT NULL, -- Nội dung QR
    qr_image_url TEXT, -- Link ảnh QR
    status qr_status NOT NULL DEFAULT 'ACTIVE', -- Trạng thái QR
    expired_at TIMESTAMPTZ NOT NULL, -- Thời điểm hết hạn
    used_at TIMESTAMPTZ, -- Thời điểm sử dụng
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now() -- Thời điểm cập nhật
);

CREATE TRIGGER trg_payment_qr_codes_updated_at
BEFORE UPDATE ON payment_qr_codes
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_payment_qr_codes_payment_order_id ON payment_qr_codes(payment_order_id);
CREATE INDEX idx_payment_qr_codes_status ON payment_qr_codes(status);
CREATE INDEX idx_payment_qr_codes_expired_at ON payment_qr_codes(expired_at);

CREATE TABLE payment_transactions (
    id UUID PRIMARY KEY, -- Khóa chính
    payment_order_id UUID NOT NULL REFERENCES payment_orders(id), -- Đơn được trả
    payer_user_id UUID NOT NULL REFERENCES users(id), -- User thanh toán
    payer_wallet_id UUID NOT NULL REFERENCES wallets(id), -- Ví thanh toán
    amount BIGINT NOT NULL, -- Số tiền
    currency VARCHAR(10) NOT NULL DEFAULT 'VND', -- Loại tiền tệ
    ledger_transaction_id UUID REFERENCES ledger_transactions(id), -- Ledger tổng
    idempotency_key VARCHAR(255) NOT NULL, -- Chống xử lý trùng
    status payment_transaction_status NOT NULL DEFAULT 'PENDING', -- Trạng thái trả tiền
    failure_reason TEXT, -- Lý do thất bại
    paid_at TIMESTAMPTZ, -- Thời điểm trả tiền
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT payment_transactions_amount_positive CHECK (amount > 0),
    CONSTRAINT payment_transactions_payer_idempotency_unique UNIQUE (payer_user_id, idempotency_key)
);

CREATE TRIGGER trg_payment_transactions_updated_at
BEFORE UPDATE ON payment_transactions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_payment_transactions_order_id ON payment_transactions(payment_order_id);
CREATE INDEX idx_payment_transactions_payer_wallet_created_at ON payment_transactions(payer_wallet_id, created_at DESC);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX idx_payment_transactions_created_at ON payment_transactions(created_at DESC);

-- DB-level protection: one payment order can have at most one SUCCESS transaction.
CREATE UNIQUE INDEX uq_payment_transactions_success_once
ON payment_transactions(payment_order_id)
WHERE status = 'SUCCESS';

-- =========================================================
-- 10. REFUND
-- =========================================================

CREATE TABLE refund_transactions (
    id UUID PRIMARY KEY, -- Khóa chính
    refund_no VARCHAR(50) NOT NULL UNIQUE, -- Mã hoàn tiền
    payment_order_id UUID NOT NULL REFERENCES payment_orders(id), -- Đơn được hoàn
    payment_transaction_id UUID REFERENCES payment_transactions(id), -- Giao dịch thanh toán
    merchant_id UUID NOT NULL REFERENCES merchants(id), -- Merchant liên kết
    user_id UUID NOT NULL REFERENCES users(id), -- User nhận hoàn
    wallet_id UUID NOT NULL REFERENCES wallets(id), -- Ví nhận hoàn
    amount BIGINT NOT NULL, -- Số tiền
    currency VARCHAR(10) NOT NULL DEFAULT 'VND', -- Loại tiền tệ
    reason VARCHAR(500) NOT NULL, -- Lý do hoàn
    status refund_status NOT NULL DEFAULT 'PENDING', -- Trạng thái hoàn
    ledger_transaction_id UUID REFERENCES ledger_transactions(id), -- Ledger tổng
    idempotency_key VARCHAR(255) NOT NULL, -- Chống xử lý trùng
    failure_reason TEXT, -- Lý do thất bại
    created_by UUID REFERENCES users(id), -- Người tạo
    refunded_at TIMESTAMPTZ, -- Thời điểm hoàn
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT refund_transactions_amount_positive CHECK (amount > 0)
);

CREATE TRIGGER trg_refund_transactions_updated_at
BEFORE UPDATE ON refund_transactions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_refund_transactions_payment_order_id ON refund_transactions(payment_order_id);
CREATE INDEX idx_refund_transactions_merchant_created_at ON refund_transactions(merchant_id, created_at DESC);
CREATE INDEX idx_refund_transactions_user_created_at ON refund_transactions(user_id, created_at DESC);
CREATE INDEX idx_refund_transactions_status ON refund_transactions(status);
CREATE INDEX idx_refund_transactions_created_at ON refund_transactions(created_at DESC);

-- =========================================================
-- 11. WEBHOOK / CALLBACK
-- =========================================================

CREATE TABLE payment_callbacks (
    id UUID PRIMARY KEY, -- Khóa chính
    event_id VARCHAR(100) NOT NULL UNIQUE, -- Mã sự kiện webhook
    payment_order_id UUID REFERENCES payment_orders(id), -- Đơn liên quan
    payment_transaction_id UUID REFERENCES payment_transactions(id), -- Payment transaction
    refund_transaction_id UUID REFERENCES refund_transactions(id), -- Refund transaction
    merchant_id UUID NOT NULL REFERENCES merchants(id), -- Merchant liên kết
    event_type webhook_event_type NOT NULL, -- Loại sự kiện
    callback_url TEXT NOT NULL, -- URL callback
    request_body JSONB NOT NULL, -- Payload gửi đi
    signature TEXT NOT NULL, -- Chữ ký webhook
    response_body JSONB, -- Phản hồi merchant
    http_status INTEGER, -- HTTP status nhận
    retry_count INTEGER NOT NULL DEFAULT 0, -- Số lần retry
    status webhook_status NOT NULL DEFAULT 'PENDING', -- Trạng thái callback
    next_retry_at TIMESTAMPTZ, -- Lần retry kế tiếp
    sent_at TIMESTAMPTZ, -- Thời điểm gửi
    last_error TEXT, -- Lỗi gần nhất
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT payment_callbacks_retry_count_check CHECK (retry_count >= 0),
    CONSTRAINT payment_callbacks_http_status_check CHECK (http_status IS NULL OR (http_status >= 100 AND http_status <= 599)),
    CONSTRAINT payment_callbacks_has_source_check CHECK (payment_order_id IS NOT NULL OR refund_transaction_id IS NOT NULL)
);

CREATE TRIGGER trg_payment_callbacks_updated_at
BEFORE UPDATE ON payment_callbacks
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_payment_callbacks_payment_order_id ON payment_callbacks(payment_order_id);
CREATE INDEX idx_payment_callbacks_refund_transaction_id ON payment_callbacks(refund_transaction_id);
CREATE INDEX idx_payment_callbacks_merchant_created_at ON payment_callbacks(merchant_id, created_at DESC);
CREATE INDEX idx_payment_callbacks_status_next_retry ON payment_callbacks(status, next_retry_at);
CREATE INDEX idx_payment_callbacks_created_at ON payment_callbacks(created_at DESC);

-- =========================================================
-- 12. IDEMPOTENCY
-- =========================================================

CREATE TABLE idempotency_keys (
    id UUID PRIMARY KEY, -- Khóa chính
    actor_type idempotency_actor_type NOT NULL, -- Loại actor
    actor_id UUID NOT NULL, -- ID actor
    idempotency_key VARCHAR(255) NOT NULL, -- Chống xử lý trùng
    request_path VARCHAR(255) NOT NULL, -- Đường dẫn request
    request_hash TEXT NOT NULL, -- Hash request
    resource_type VARCHAR(100), -- Loại resource
    resource_id UUID, -- ID resource
    response_status_code INTEGER, -- HTTP status phản hồi
    response_body JSONB, -- Body phản hồi
    status idempotency_status NOT NULL DEFAULT 'PROCESSING', -- Trạng thái xử lý key
    locked_at TIMESTAMPTZ, -- Thời điểm giữ key
    expires_at TIMESTAMPTZ NOT NULL, -- Thời điểm hết hạn
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), -- Thời điểm cập nhật
    CONSTRAINT idempotency_keys_actor_key_unique UNIQUE (actor_type, actor_id, idempotency_key),
    CONSTRAINT idempotency_keys_response_status_code_check CHECK (response_status_code IS NULL OR (response_status_code >= 100 AND response_status_code <= 599))
);

CREATE TRIGGER trg_idempotency_keys_updated_at
BEFORE UPDATE ON idempotency_keys
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_idempotency_keys_expires_at ON idempotency_keys(expires_at);
CREATE INDEX idx_idempotency_keys_resource ON idempotency_keys(resource_type, resource_id);
CREATE INDEX idx_idempotency_keys_status ON idempotency_keys(status);

-- =========================================================
-- 13. AUDIT / SYSTEM LOG
-- =========================================================

CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY, -- Khóa chính
    trace_id VARCHAR(100), -- Mã truy vết
    actor_type audit_actor_type NOT NULL, -- Loại actor
    actor_id UUID, -- ID actor
    action VARCHAR(100) NOT NULL, -- Hành động
    entity_type VARCHAR(100) NOT NULL, -- Loại đối tượng
    entity_id UUID, -- ID đối tượng
    old_data JSONB, -- Dữ liệu cũ
    new_data JSONB, -- Dữ liệu mới
    metadata JSONB, -- Dữ liệu bổ sung
    reason TEXT, -- Lý do
    ip_address VARCHAR(45), -- Địa chỉ IP
    user_agent VARCHAR(500), -- Thông tin thiết bị/trình duyệt
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() -- Thời điểm tạo
);

CREATE INDEX idx_audit_logs_trace_id ON audit_logs(trace_id);
CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_type, actor_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

CREATE TABLE system_logs (
    id BIGSERIAL PRIMARY KEY, -- Khóa chính
    trace_id VARCHAR(100), -- Mã truy vết
    level log_level NOT NULL DEFAULT 'INFO', -- Mức log
    module VARCHAR(100) NOT NULL, -- Module phát sinh
    event VARCHAR(100) NOT NULL, -- Sự kiện
    message TEXT NOT NULL, -- Nội dung log
    context JSONB, -- Ngữ cảnh log
    entity_type VARCHAR(100), -- Loại đối tượng
    entity_id UUID, -- ID đối tượng
    created_at TIMESTAMPTZ NOT NULL DEFAULT now() -- Thời điểm tạo
);

CREATE INDEX idx_system_logs_trace_id ON system_logs(trace_id);
CREATE INDEX idx_system_logs_level ON system_logs(level);
CREATE INDEX idx_system_logs_module ON system_logs(module);
CREATE INDEX idx_system_logs_entity ON system_logs(entity_type, entity_id);
CREATE INDEX idx_system_logs_created_at ON system_logs(created_at DESC);

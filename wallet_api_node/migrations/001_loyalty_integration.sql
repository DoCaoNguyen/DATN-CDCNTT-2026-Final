-- 001_loyalty_integration.sql

-- 1. Thêm cột loyalty_member_id vào bảng users
ALTER TABLE users ADD COLUMN loyalty_member_id VARCHAR(255) NULL;

-- 2. Tạo bảng loyalty_sync_logs
CREATE TABLE loyalty_sync_logs (
    id UUID PRIMARY KEY,
    payment_transaction_id UUID NOT NULL,
    amount NUMERIC NOT NULL,
    earned_points INTEGER,
    status VARCHAR(50) NOT NULL, -- PENDING, SUCCESS, FAILED
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tạo Index cho truy xuất nhanh
CREATE INDEX idx_loyalty_sync_payment_tx ON loyalty_sync_logs(payment_transaction_id);
CREATE INDEX idx_loyalty_sync_status_retry ON loyalty_sync_logs(status, retry_count);

-- 1. Thêm cột secret_key cho bảng merchants nếu chưa có
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS secret_key VARCHAR(255);

-- (Optional) Update existing merchants with a random secret key for testing purposes
-- UPDATE merchants SET secret_key = encode(gen_random_bytes(32), 'hex') WHERE secret_key IS NULL;

-- 2. Tạo bảng webhook_logs lưu trữ lịch sử gọi webhook để Audit
-- Yêu cầu thiết kế: Không cho phép sửa xóa dữ liệu hoàn tất (được handle ở logic code/trigger).
CREATE TABLE IF NOT EXISTS webhook_logs (
    id SERIAL PRIMARY KEY,
    merchant_id UUID NOT NULL REFERENCES merchants(id),
    transaction_id UUID NOT NULL REFERENCES payment_transactions(id),
    idempotency_key VARCHAR(255) UNIQUE NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, SUCCESS, FAILED
    retry_count INT DEFAULT 0,
    max_retries INT DEFAULT 7,
    last_error TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Thêm index để tối ưu query
CREATE INDEX IF NOT EXISTS idx_webhook_logs_merchant_id ON webhook_logs(merchant_id);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_status ON webhook_logs(status);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_transaction_id ON webhook_logs(transaction_id);

-- Lưu ý: Để bảo vệ dữ liệu audit hoàn toàn ở cấp độ DB, có thể tạo trigger ngăn chặn DELETE / UPDATE nếu status = 'SUCCESS' hoặc 'FAILED'
CREATE OR REPLACE FUNCTION prevent_modify_completed_webhook()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IN ('SUCCESS', 'FAILED') THEN
        RAISE EXCEPTION 'Cannot modify or delete a completed webhook log.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_modify_webhook ON webhook_logs;
CREATE TRIGGER trg_prevent_modify_webhook
BEFORE UPDATE OR DELETE ON webhook_logs
FOR EACH ROW EXECUTE FUNCTION prevent_modify_completed_webhook();

-- =========================================================
-- add_missing_tables.sql
-- Bổ sung các bảng thiếu trong ewallet_final_db.sql
-- mà backend code đang truy vấn
-- =========================================================

-- =========================================================
-- 1. CHAT MESSAGES
-- Dùng bởi: transaction.repository.js (getChatList, getChatHistory, saveChatMessage)
-- =========================================================

CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY,                                            -- Khóa chính
    sender_wallet_id UUID NOT NULL REFERENCES wallets(id),          -- Ví người gửi
    receiver_wallet_id UUID NOT NULL REFERENCES wallets(id),        -- Ví người nhận
    content TEXT NOT NULL,                                           -- Nội dung tin nhắn
    message_type VARCHAR(50) NOT NULL DEFAULT 'TEXT',               -- Loại tin nhắn (TEXT, IMAGE, ...)
    is_read BOOLEAN NOT NULL DEFAULT false,                          -- Đã đọc chưa
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),                   -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),                   -- Thời điểm cập nhật
    CONSTRAINT chat_messages_not_self CHECK (sender_wallet_id <> receiver_wallet_id)
);

CREATE TRIGGER trg_chat_messages_updated_at
BEFORE UPDATE ON chat_messages
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_chat_messages_sender_wallet ON chat_messages(sender_wallet_id, created_at DESC);
CREATE INDEX idx_chat_messages_receiver_wallet ON chat_messages(receiver_wallet_id, created_at DESC);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- =========================================================
-- 2. LOYALTY SYNC LOGS
-- Dùng bởi: LoyaltyIntegrationService.js (syncPointsAfterPayment, executeLoyaltyApiCall, retryFailedSyncs)
-- =========================================================

CREATE TABLE IF NOT EXISTS loyalty_sync_logs (
    id UUID PRIMARY KEY,                                                    -- Khóa chính
    payment_transaction_id UUID NOT NULL REFERENCES payment_transactions(id), -- Giao dịch thanh toán
    amount BIGINT NOT NULL,                                                  -- Số tiền giao dịch
    earned_points INT,                                                       -- Điểm được cộng
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',                          -- Trạng thái đồng bộ
    retry_count INT NOT NULL DEFAULT 0,                                      -- Số lần thử lại
    error_message TEXT,                                                      -- Lỗi nếu có
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),                           -- Thời điểm tạo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),                           -- Thời điểm cập nhật
    CONSTRAINT loyalty_sync_logs_status_check CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED')),
    CONSTRAINT loyalty_sync_logs_retry_count_check CHECK (retry_count >= 0),
    CONSTRAINT loyalty_sync_logs_amount_positive CHECK (amount > 0)
);

CREATE TRIGGER trg_loyalty_sync_logs_updated_at
BEFORE UPDATE ON loyalty_sync_logs
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_loyalty_sync_logs_status ON loyalty_sync_logs(status);
CREATE INDEX idx_loyalty_sync_logs_payment_tx ON loyalty_sync_logs(payment_transaction_id);
CREATE INDEX idx_loyalty_sync_logs_created_at ON loyalty_sync_logs(created_at DESC);

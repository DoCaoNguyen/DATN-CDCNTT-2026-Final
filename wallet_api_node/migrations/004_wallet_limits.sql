CREATE TABLE "wallet_limits" (
    "wallet_id" UUID PRIMARY KEY REFERENCES wallets(id) ON DELETE CASCADE,
    
    -- Hạn mức nạp/rút trong ngày (Daily Limits)
    "daily_deposit_limit" BIGINT DEFAULT 50000000,
    "daily_withdrawal_limit" BIGINT DEFAULT 50000000,
    
    -- Hạn mức giao dịch (chuyển tiền + thanh toán) trong ngày và tháng
    "daily_transaction_limit" BIGINT DEFAULT 50000000,
    "monthly_transaction_limit" BIGINT DEFAULT 100000000,
    "monthly_special_service_limit" BIGINT DEFAULT 300000000,

    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

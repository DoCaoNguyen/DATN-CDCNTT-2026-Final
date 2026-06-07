CREATE TABLE "user_kyc" (
    "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user_id" UUID REFERENCES "users"("id") UNIQUE NOT NULL,
    "id_number" VARCHAR(20) UNIQUE,
    "full_name" VARCHAR(255),
    "dob" VARCHAR(20),
    "gender" VARCHAR(10),
    "address" TEXT,
    "id_front_image" TEXT NOT NULL, -- Đường dẫn/URL ảnh mặt trước
    "id_back_image" TEXT NOT NULL,  -- Đường dẫn/URL ảnh mặt sau
    "face_image" TEXT NOT NULL,     -- Đường dẫn/URL ảnh selfie
    "kyc_status" VARCHAR(20) DEFAULT 'PENDING', -- PENDING, VERIFIED, REJECTED
    "face_match_score" DECIMAL(5,2), -- Tỉ lệ khớp khuôn mặt (%)
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);



CREATE TABLE "otp_tracking" (
    "phone" VARCHAR(20) PRIMARY KEY,
    "otp_code" VARCHAR(10) NOT NULL,
    "failed_attempts" INTEGER DEFAULT 0,
    "locked_until" TIMESTAMP(0) WITHOUT TIME ZONE NULL,
    "expired_at" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE "users"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "full_name" VARCHAR(255) NULL, "email" VARCHAR(255) NULL, "phone" VARCHAR(20) NULL, "password_hash" TEXT NOT NULL, "role" VARCHAR(50) NULL DEFAULT 'USER', "status" VARCHAR(20) NULL DEFAULT 'ACTIVE', "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP, "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "users" ADD PRIMARY KEY("id");
ALTER TABLE
    "users" ADD CONSTRAINT "users_email_unique" UNIQUE("email");
ALTER TABLE
    "users" ADD CONSTRAINT "users_phone_unique" UNIQUE("phone");

CREATE TABLE "wallets"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "user_id" UUID NOT NULL, "wallet_code" VARCHAR(50) NULL, "currency" VARCHAR(10) NULL DEFAULT 'VND', "status" VARCHAR(20) NULL DEFAULT 'ACTIVE', "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "wallets" ADD PRIMARY KEY("id");
ALTER TABLE
    "wallets" ADD CONSTRAINT "wallets_user_id_unique" UNIQUE("user_id");
ALTER TABLE
    "wallets" ADD CONSTRAINT "wallets_wallet_code_unique" UNIQUE("wallet_code");

CREATE TABLE "wallet_balances"(
    "wallet_id" UUID NOT NULL,
    "available_balance" BIGINT NULL,
    "locked_balance" BIGINT NULL,
    "updated_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "wallet_balances" ADD PRIMARY KEY("wallet_id");

CREATE TABLE "ledger_transactions"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "transaction_type" VARCHAR(30) NULL, "reference_type" VARCHAR(30) NULL, "reference_id" UUID NULL, "status" VARCHAR(20) NULL, "description" TEXT NULL, "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "ledger_transactions" ADD PRIMARY KEY("id");

CREATE TABLE "ledger_entries"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "transaction_id" UUID NOT NULL, "wallet_id" UUID NULL, "entry_type" VARCHAR(10) NULL, "amount" BIGINT NOT NULL, "balance_before" BIGINT NULL, "balance_after" BIGINT NULL, "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "ledger_entries" ADD PRIMARY KEY("id");
CREATE INDEX "ledger_entries_transaction_id_index" ON
    "ledger_entries"("transaction_id");
-- [MỚI THÊM] Index tối ưu cho việc filter lịch sử biến động số dư theo ngày tháng
CREATE INDEX "ledger_entries_created_at_index" ON 
    "ledger_entries"("created_at");

CREATE TABLE "wallet_transfers"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "sender_wallet_id" UUID NULL, "receiver_wallet_id" UUID NULL, "amount" BIGINT NOT NULL, "note" TEXT NULL, "transaction_id" UUID NULL, "status" VARCHAR(20) NULL, "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "wallet_transfers" ADD PRIMARY KEY("id");
CREATE INDEX "wallet_transfers_sender_wallet_id_index" ON
    "wallet_transfers"("sender_wallet_id");
CREATE INDEX "wallet_transfers_receiver_wallet_id_index" ON
    "wallet_transfers"("receiver_wallet_id");
-- [MỚI THÊM] Index tối ưu lọc lịch sử chuyển tiền
CREATE INDEX "wallet_transfers_created_at_index" ON 
    "wallet_transfers"("created_at");

CREATE TABLE "deposit_transactions"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "wallet_id" UUID NOT NULL, "amount" BIGINT NOT NULL, "deposit_method" VARCHAR(50) NULL, "external_reference" VARCHAR(255) NULL, "ledger_transaction_id" UUID NULL, "status" VARCHAR(20) NULL DEFAULT 'PENDING', "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "deposit_transactions" ADD PRIMARY KEY("id");
-- [MỚI THÊM] Index tối ưu lọc lịch sử nạp tiền
CREATE INDEX "deposit_transactions_created_at_index" ON 
    "deposit_transactions"("created_at");

CREATE TABLE "merchants"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "merchant_name" VARCHAR(255) NULL, "email" VARCHAR(255) NULL, "callback_url" TEXT NULL, "status" VARCHAR(20) NULL DEFAULT 'ACTIVE', "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "merchants" ADD PRIMARY KEY("id");

CREATE TABLE "merchant_api_keys"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "merchant_id" UUID NULL, "api_key" VARCHAR(255) NOT NULL, "api_secret" TEXT NOT NULL, "expired_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL, "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "merchant_api_keys" ADD PRIMARY KEY("id");
ALTER TABLE
    "merchant_api_keys" ADD CONSTRAINT "merchant_api_keys_api_key_unique" UNIQUE("api_key");

CREATE TABLE "payment_orders"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "merchant_id" UUID NULL, "order_code" VARCHAR(100) NULL, "amount" BIGINT NOT NULL, "currency" VARCHAR(10) NULL DEFAULT 'VND', "callback_url" TEXT NULL, "description" TEXT NULL, "status" VARCHAR(20) NULL, "expired_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL, "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "payment_orders" ADD PRIMARY KEY("id");
ALTER TABLE
    "payment_orders" ADD CONSTRAINT "payment_orders_order_code_unique" UNIQUE("order_code");

CREATE TABLE "payment_qr_codes"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "payment_order_id" UUID NULL, "qr_content" TEXT NULL, "qr_token" VARCHAR(255) NULL, "expired_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL, "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "payment_qr_codes" ADD PRIMARY KEY("id");
ALTER TABLE
    "payment_qr_codes" ADD CONSTRAINT "payment_qr_codes_qr_token_unique" UNIQUE("qr_token");

CREATE TABLE "payment_transactions"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "payment_order_id" UUID NULL, "payer_wallet_id" UUID NULL, "amount" BIGINT NULL, "ledger_transaction_id" UUID NULL, "status" VARCHAR(20) NULL, "paid_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL, "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "payment_transactions" ADD PRIMARY KEY("id");
CREATE INDEX "payment_transactions_status_index" ON
    "payment_transactions"("status");
-- [MỚI THÊM] Index tối ưu lọc lịch sử thanh toán qua cổng Payment
CREATE INDEX "payment_transactions_created_at_index" ON 
    "payment_transactions"("created_at");

CREATE TABLE "payment_callbacks"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "payment_transaction_id" UUID NULL, "callback_url" TEXT NULL, "request_body" jsonb NULL, "response_body" jsonb NULL, "http_status" INTEGER NULL, "retry_count" INTEGER NULL, "status" VARCHAR(20) NULL, "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "payment_callbacks" ADD PRIMARY KEY("id");

CREATE TABLE "idempotency_keys"(
    "id" UUID NOT NULL DEFAULT gen_random_uuid(), "idempotency_key" VARCHAR(255) NULL, "request_hash" TEXT NULL, "response_data" jsonb NULL, "expired_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL, "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP);
ALTER TABLE
    "idempotency_keys" ADD PRIMARY KEY("id");
ALTER TABLE
    "idempotency_keys" ADD CONSTRAINT "idempotency_keys_idempotency_key_unique" UNIQUE("idempotency_key");

CREATE TABLE "audit_logs"(
    "id" bigserial NOT NULL,
    "actor_id" UUID NULL,
    "action" VARCHAR(100) NULL,
    "entity_type" VARCHAR(50) NULL,
    "entity_id" UUID NULL,
    "old_data" jsonb NULL,
    "new_data" jsonb NULL,
    "ip_address" VARCHAR(100) NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX "audit_logs_entity_type_entity_id_index" ON
    "audit_logs"("entity_type", "entity_id");
ALTER TABLE
    "audit_logs" ADD PRIMARY KEY("id");

CREATE TABLE "system_logs"(
    "id" bigserial NOT NULL,
    "service_name" VARCHAR(100) NULL,
    "log_level" VARCHAR(20) NULL,
    "trace_id" VARCHAR(255) NULL,
    "message" TEXT NULL,
    "metadata" jsonb NULL,
    "created_at" TIMESTAMP(0) WITHOUT TIME ZONE NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE
    "system_logs" ADD PRIMARY KEY("id");

ALTER TABLE
    "payment_transactions" ADD CONSTRAINT "payment_transactions_ledger_transaction_id_foreign" FOREIGN KEY("ledger_transaction_id") REFERENCES "ledger_transactions"("id");
ALTER TABLE
    "ledger_entries" ADD CONSTRAINT "ledger_entries_transaction_id_foreign" FOREIGN KEY("transaction_id") REFERENCES "ledger_transactions"("id");
ALTER TABLE
    "wallets" ADD CONSTRAINT "wallets_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "users"("id");
ALTER TABLE
    "deposit_transactions" ADD CONSTRAINT "deposit_transactions_wallet_id_foreign" FOREIGN KEY("wallet_id") REFERENCES "wallets"("id");
ALTER TABLE
    "payment_qr_codes" ADD CONSTRAINT "payment_qr_codes_payment_order_id_foreign" FOREIGN KEY("payment_order_id") REFERENCES "payment_orders"("id");
ALTER TABLE
    "payment_orders" ADD CONSTRAINT "payment_orders_merchant_id_foreign" FOREIGN KEY("merchant_id") REFERENCES "merchants"("id");
ALTER TABLE
    "wallet_transfers" ADD CONSTRAINT "wallet_transfers_sender_wallet_id_foreign" FOREIGN KEY("sender_wallet_id") REFERENCES "wallets"("id");
ALTER TABLE
    "merchant_api_keys" ADD CONSTRAINT "merchant_api_keys_merchant_id_foreign" FOREIGN KEY("merchant_id") REFERENCES "merchants"("id");
ALTER TABLE
    "payment_callbacks" ADD CONSTRAINT "payment_callbacks_payment_transaction_id_foreign" FOREIGN KEY("payment_transaction_id") REFERENCES "payment_transactions"("id");
ALTER TABLE
    "deposit_transactions" ADD CONSTRAINT "deposit_transactions_ledger_transaction_id_foreign" FOREIGN KEY("ledger_transaction_id") REFERENCES "ledger_transactions"("id");
ALTER TABLE
    "wallet_transfers" ADD CONSTRAINT "wallet_transfers_transaction_id_foreign" FOREIGN KEY("transaction_id") REFERENCES "ledger_transactions"("id");
ALTER TABLE
    "ledger_entries" ADD CONSTRAINT "ledger_entries_wallet_id_foreign" FOREIGN KEY("wallet_id") REFERENCES "wallets"("id");
ALTER TABLE
    "wallet_transfers" ADD CONSTRAINT "wallet_transfers_receiver_wallet_id_foreign" FOREIGN KEY("receiver_wallet_id") REFERENCES "wallets"("id");
ALTER TABLE
    "wallet_balances" ADD CONSTRAINT "wallet_balances_wallet_id_foreign" FOREIGN KEY("wallet_id") REFERENCES "wallets"("id");
ALTER TABLE
    "payment_transactions" ADD CONSTRAINT "payment_transactions_payment_order_id_foreign" FOREIGN KEY("payment_order_id") REFERENCES "payment_orders"("id");
ALTER TABLE
    "payment_transactions" ADD CONSTRAINT "payment_transactions_payer_wallet_id_foreign" FOREIGN KEY("payer_wallet_id") REFERENCES "wallets"("id");


ALTER TABLE "users" ADD COLUMN "is_kyc_verified" BOOLEAN DEFAULT FALSE;
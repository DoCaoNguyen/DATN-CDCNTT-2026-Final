-- Database Schema Backup
-- Generated on 2026-06-09T04:31:16.904Z

CREATE TABLE "audit_logs" (
    "id" BIGINT NOT NULL DEFAULT nextval('audit_logs_id_seq'::regclass),
    "actor_id" UUID,
    "action" CHARACTER VARYING(100),
    "entity_type" CHARACTER VARYING(50),
    "entity_id" UUID,
    "old_data" JSONB,
    "new_data" JSONB,
    "ip_address" CHARACTER VARYING(100),
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "deposit_transactions" (
    "id" UUID NOT NULL,
    "wallet_id" UUID NOT NULL,
    "amount" BIGINT NOT NULL,
    "deposit_method" CHARACTER VARYING(50),
    "external_reference" CHARACTER VARYING(255),
    "ledger_transaction_id" UUID,
    "status" CHARACTER VARYING(20) DEFAULT 'PENDING'::character varying,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "idempotency_keys" (
    "id" UUID NOT NULL,
    "idempotency_key" CHARACTER VARYING(255),
    "request_hash" TEXT,
    "response_data" JSONB,
    "expired_at" TIMESTAMP WITHOUT TIME ZONE,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "ledger_entries" (
    "id" UUID NOT NULL,
    "transaction_id" UUID NOT NULL,
    "wallet_id" UUID,
    "entry_type" CHARACTER VARYING(10),
    "amount" BIGINT NOT NULL,
    "balance_before" BIGINT,
    "balance_after" BIGINT,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "ledger_transactions" (
    "id" UUID NOT NULL,
    "transaction_type" CHARACTER VARYING(30),
    "reference_type" CHARACTER VARYING(30),
    "reference_id" UUID,
    "status" CHARACTER VARYING(20),
    "description" TEXT,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "category_name" CHARACTER VARYING(255) DEFAULT NULL::character varying,
    "is_expense_counted" BOOLEAN DEFAULT true,
    PRIMARY KEY ("id")
);

CREATE TABLE "merchant_api_keys" (
    "id" UUID NOT NULL,
    "merchant_id" UUID,
    "api_key" CHARACTER VARYING(255) NOT NULL,
    "api_secret" TEXT NOT NULL,
    "expired_at" TIMESTAMP WITHOUT TIME ZONE,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "merchants" (
    "id" UUID NOT NULL,
    "merchant_name" CHARACTER VARYING(255),
    "email" CHARACTER VARYING(255),
    "callback_url" TEXT,
    "status" CHARACTER VARYING(20) DEFAULT 'ACTIVE'::character varying,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" CHARACTER VARYING(255) NOT NULL,
    "content" TEXT NOT NULL,
    "notification_type" CHARACTER VARYING(50),
    "reference_id" UUID,
    "status" CHARACTER VARYING(20) DEFAULT 'UNREAD'::character varying,
    "read_at" TIMESTAMP WITHOUT TIME ZONE,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "otp_tracking" (
    "phone" CHARACTER VARYING(20) NOT NULL,
    "otp_code" CHARACTER VARYING(10) NOT NULL,
    "failed_attempts" INTEGER DEFAULT 0,
    "locked_until" TIMESTAMP WITHOUT TIME ZONE,
    "expired_at" TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "email" CHARACTER VARYING(255),
    PRIMARY KEY ("phone")
);

CREATE TABLE "payment_callbacks" (
    "id" UUID NOT NULL,
    "payment_transaction_id" UUID,
    "callback_url" TEXT,
    "request_body" JSONB,
    "response_body" JSONB,
    "http_status" INTEGER,
    "retry_count" INTEGER,
    "status" CHARACTER VARYING(20),
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "payment_orders" (
    "id" UUID NOT NULL,
    "merchant_id" UUID,
    "order_code" CHARACTER VARYING(100),
    "amount" BIGINT NOT NULL,
    "currency" CHARACTER VARYING(10) DEFAULT 'VND'::character varying,
    "callback_url" TEXT,
    "description" TEXT,
    "status" CHARACTER VARYING(20),
    "expired_at" TIMESTAMP WITHOUT TIME ZONE,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "payment_qr_codes" (
    "id" UUID NOT NULL,
    "payment_order_id" UUID,
    "qr_content" TEXT,
    "qr_token" CHARACTER VARYING(255),
    "expired_at" TIMESTAMP WITHOUT TIME ZONE,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "payment_transactions" (
    "id" UUID NOT NULL,
    "payment_order_id" UUID,
    "payer_wallet_id" UUID,
    "amount" BIGINT,
    "ledger_transaction_id" UUID,
    "status" CHARACTER VARYING(20),
    "paid_at" TIMESTAMP WITHOUT TIME ZONE,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "system_logs" (
    "id" BIGINT NOT NULL DEFAULT nextval('system_logs_id_seq'::regclass),
    "service_name" CHARACTER VARYING(100),
    "log_level" CHARACTER VARYING(20),
    "trace_id" CHARACTER VARYING(255),
    "message" TEXT,
    "metadata" JSONB,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "user_devices" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "fcm_token" CHARACTER VARYING(255) NOT NULL,
    "device_name" CHARACTER VARYING(100),
    "device_type" CHARACTER VARYING(20),
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "user_kyc" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "id_number" CHARACTER VARYING(20),
    "full_name" CHARACTER VARYING(255),
    "dob" CHARACTER VARYING(20),
    "gender" CHARACTER VARYING(10),
    "address" TEXT,
    "id_front_image" TEXT NOT NULL,
    "id_back_image" TEXT NOT NULL,
    "face_image" TEXT NOT NULL,
    "kyc_status" CHARACTER VARYING(20) DEFAULT 'PENDING'::character varying,
    "face_match_score" NUMERIC,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "full_name" CHARACTER VARYING(255),
    "email" CHARACTER VARYING(255),
    "phone" CHARACTER VARYING(20),
    "password_hash" TEXT NOT NULL,
    "role" CHARACTER VARYING(50) DEFAULT 'USER'::character varying,
    "status" CHARACTER VARYING(20) DEFAULT 'ACTIVE'::character varying,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "failed_login_attempts" INTEGER DEFAULT 0,
    "locked_until" TIMESTAMP WITHOUT TIME ZONE,
    "is_kyc_verified" BOOLEAN DEFAULT false,
    "pin_hash" TEXT,
    "token_version" INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY ("id")
);

CREATE TABLE "wallet_balances" (
    "wallet_id" UUID NOT NULL,
    "available_balance" BIGINT,
    "locked_balance" BIGINT,
    "updated_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("wallet_id")
);

CREATE TABLE "wallet_linked_banks" (
    "id" UUID NOT NULL,
    "wallet_id" UUID NOT NULL,
    "bank_name" CHARACTER VARYING(100) NOT NULL,
    "bank_code" CHARACTER VARYING(20),
    "card_number" CHARACTER VARYING(50) NOT NULL,
    "card_holder_name" CHARACTER VARYING(255) NOT NULL,
    "issue_date" CHARACTER VARYING(10),
    "status" CHARACTER VARYING(20) DEFAULT 'ACTIVE'::character varying,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "wallet_transfers" (
    "id" UUID NOT NULL,
    "sender_wallet_id" UUID,
    "receiver_wallet_id" UUID,
    "amount" BIGINT NOT NULL,
    "note" TEXT,
    "transaction_id" UUID,
    "status" CHARACTER VARYING(20),
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "reference_code" CHARACTER VARYING(50),
    PRIMARY KEY ("id")
);

CREATE TABLE "wallets" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "wallet_code" CHARACTER VARYING(50),
    "currency" CHARACTER VARYING(10) DEFAULT 'VND'::character varying,
    "status" CHARACTER VARYING(20) DEFAULT 'ACTIVE'::character varying,
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    "pin_failed_attempts" INTEGER DEFAULT 0,
    "pin_locked_until" TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY ("id")
);

CREATE TABLE "withdrawal_transactions" (
    "id" UUID NOT NULL,
    "wallet_id" UUID NOT NULL,
    "linked_bank_id" UUID,
    "amount" BIGINT NOT NULL,
    "withdrawal_method" CHARACTER VARYING(50),
    "external_reference" CHARACTER VARYING(255),
    "ledger_transaction_id" UUID,
    "status" CHARACTER VARYING(20) DEFAULT 'PENDING'::character varying,
    "bank_code" CHARACTER VARYING(20),
    "account_number" CHARACTER VARYING(50),
    "created_at" TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);


CREATE UNIQUE INDEX users_email_unique ON public.users USING btree (email);
CREATE UNIQUE INDEX users_phone_unique ON public.users USING btree (phone);
CREATE UNIQUE INDEX wallets_user_id_unique ON public.wallets USING btree (user_id);
CREATE UNIQUE INDEX wallets_wallet_code_unique ON public.wallets USING btree (wallet_code);
CREATE INDEX ledger_entries_transaction_id_index ON public.ledger_entries USING btree (transaction_id);
CREATE INDEX ledger_entries_created_at_index ON public.ledger_entries USING btree (created_at);
CREATE INDEX wallet_transfers_sender_wallet_id_index ON public.wallet_transfers USING btree (sender_wallet_id);
CREATE INDEX wallet_transfers_receiver_wallet_id_index ON public.wallet_transfers USING btree (receiver_wallet_id);
CREATE INDEX wallet_transfers_created_at_index ON public.wallet_transfers USING btree (created_at);
CREATE INDEX deposit_transactions_created_at_index ON public.deposit_transactions USING btree (created_at);
CREATE UNIQUE INDEX merchant_api_keys_api_key_unique ON public.merchant_api_keys USING btree (api_key);
CREATE UNIQUE INDEX payment_orders_order_code_unique ON public.payment_orders USING btree (order_code);
CREATE UNIQUE INDEX payment_qr_codes_qr_token_unique ON public.payment_qr_codes USING btree (qr_token);
CREATE INDEX payment_transactions_status_index ON public.payment_transactions USING btree (status);
CREATE INDEX payment_transactions_created_at_index ON public.payment_transactions USING btree (created_at);
CREATE UNIQUE INDEX idempotency_keys_idempotency_key_unique ON public.idempotency_keys USING btree (idempotency_key);
CREATE INDEX audit_logs_entity_type_entity_id_index ON public.audit_logs USING btree (entity_type, entity_id);
CREATE UNIQUE INDEX user_kyc_user_id_key ON public.user_kyc USING btree (user_id);
CREATE UNIQUE INDEX user_kyc_id_number_key ON public.user_kyc USING btree (id_number);
CREATE INDEX wallet_linked_banks_wallet_id_index ON public.wallet_linked_banks USING btree (wallet_id);
CREATE INDEX withdrawal_transactions_created_at_index ON public.withdrawal_transactions USING btree (created_at);
CREATE UNIQUE INDEX user_devices_fcm_token_key ON public.user_devices USING btree (fcm_token);
CREATE INDEX user_devices_user_id_index ON public.user_devices USING btree (user_id);


ALTER TABLE ONLY public.user_devices
    ADD CONSTRAINT user_devices_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_kyc
    ADD CONSTRAINT user_kyc_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.merchant_api_keys
    ADD CONSTRAINT merchant_api_keys_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.payment_qr_codes
    ADD CONSTRAINT payment_qr_codes_payment_order_id_fkey FOREIGN KEY (payment_order_id) REFERENCES public.payment_orders(id) ON DELETE CASCADE;


ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);

ALTER TABLE ONLY public.wallet_balances
    ADD CONSTRAINT wallet_balances_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(id);

ALTER TABLE ONLY public.wallet_linked_banks
    ADD CONSTRAINT wallet_linked_banks_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(id);

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT ledger_entries_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.ledger_transactions(id),
    ADD CONSTRAINT ledger_entries_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(id);

ALTER TABLE ONLY public.deposit_transactions
    ADD CONSTRAINT deposit_transactions_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(id),
    ADD CONSTRAINT deposit_transactions_ledger_transaction_id_fkey FOREIGN KEY (ledger_transaction_id) REFERENCES public.ledger_transactions(id);

ALTER TABLE ONLY public.withdrawal_transactions
    ADD CONSTRAINT withdrawal_transactions_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(id),
    ADD CONSTRAINT withdrawal_transactions_linked_bank_id_fkey FOREIGN KEY (linked_bank_id) REFERENCES public.wallet_linked_banks(id),
    ADD CONSTRAINT withdrawal_transactions_ledger_transaction_id_fkey FOREIGN KEY (ledger_transaction_id) REFERENCES public.ledger_transactions(id);

ALTER TABLE ONLY public.wallet_transfers
    ADD CONSTRAINT wallet_transfers_sender_wallet_id_fkey FOREIGN KEY (sender_wallet_id) REFERENCES public.wallets(id),
    ADD CONSTRAINT wallet_transfers_receiver_wallet_id_fkey FOREIGN KEY (receiver_wallet_id) REFERENCES public.wallets(id),
    ADD CONSTRAINT wallet_transfers_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.ledger_transactions(id);

ALTER TABLE ONLY public.payment_orders
    ADD CONSTRAINT payment_orders_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.merchants(id);

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_payment_order_id_fkey FOREIGN KEY (payment_order_id) REFERENCES public.payment_orders(id),
    ADD CONSTRAINT payment_transactions_payer_wallet_id_fkey FOREIGN KEY (payer_wallet_id) REFERENCES public.wallets(id),
    ADD CONSTRAINT payment_transactions_ledger_transaction_id_fkey FOREIGN KEY (ledger_transaction_id) REFERENCES public.ledger_transactions(id);

ALTER TABLE ONLY public.payment_callbacks
    ADD CONSTRAINT payment_callbacks_payment_transaction_id_fkey FOREIGN KEY (payment_transaction_id) REFERENCES public.payment_transactions(id);


ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;
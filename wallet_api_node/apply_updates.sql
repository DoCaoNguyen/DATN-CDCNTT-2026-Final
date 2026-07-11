-- 24/06/2026
CREATE TABLE IF NOT EXISTS fee_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fee_code VARCHAR(50) UNIQUE NOT NULL,
    fee_type VARCHAR(20) NOT NULL,
    fee_value NUMERIC NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE fee_configs DROP CONSTRAINT IF EXISTS chk_fee_value_positive;
ALTER TABLE fee_configs ADD CONSTRAINT chk_fee_value_positive CHECK (fee_value >= 0);

-- Insert default fee config for merchant MDR
INSERT INTO fee_configs (fee_code, fee_type, fee_value, description)
VALUES ('MERCHANT_MDR', 'PERCENTAGE', 0.02, 'Phí chiết khấu thanh toán QR của Merchant (2%)')
ON CONFLICT (fee_code) DO UPDATE SET fee_value = EXCLUDED.fee_value, description = EXCLUDED.description;


-- 26/06/2026
ALTER TABLE idempotency_keys DROP CONSTRAINT IF EXISTS uq_idempotency_key;
ALTER TABLE idempotency_keys ADD CONSTRAINT uq_idempotency_key UNIQUE (idempotency_key);

ALTER TABLE payment_orders ALTER COLUMN merchant_id DROP NOT NULL;
ALTER TABLE payment_orders ALTER COLUMN callback_url DROP NOT NULL;
ALTER TABLE payment_orders ALTER COLUMN merchant_order_id DROP NOT NULL;

-- 27/06/2026
ALTER TABLE ledger_transactions ADD COLUMN IF NOT EXISTS metadata JSONB;

CREATE TABLE IF NOT EXISTS user_linked_services (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    service_name VARCHAR(100),
    service_icon VARCHAR(255),
    limit_per_day DECIMAL(15,2) DEFAULT 5000000,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_force_change_password BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS temporary_password_expires_at TIMESTAMPTZ NULL,
ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMPTZ NULL;

ALTER TABLE public.wallet_balances 
ADD COLUMN IF NOT EXISTS loyalty_points BIGINT NOT NULL DEFAULT 0;

INSERT INTO public.permissions (id, code, name, description)
VALUES
('02000000-0000-0000-0000-000000000044', 'admin.customers.create', 'Admin create customers', 'Admin tao khach hang dung vi'),
('02000000-0000-0000-0000-000000000045', 'admin.staffs.create', 'Admin create staffs', 'Admin tao nhan vien noi bo')
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.role_permissions (role_id, permission_id, created_at)
SELECT r.id, p.id, NOW()
FROM public.roles r
JOIN public.permissions p ON p.code IN ('admin.customers.create', 'admin.staffs.create')
WHERE r.code IN ('SUPER_ADMIN', 'ADMIN')
AND NOT EXISTS (
  SELECT 1 FROM public.role_permissions rp
  WHERE rp.role_id = r.id AND rp.permission_id = p.id
);

-- 1/07/2026
ALTER TABLE user_linked_services ADD COLUMN IF NOT EXISTS wallet_token VARCHAR(255);
ALTER TABLE user_linked_services ADD COLUMN IF NOT EXISTS limit_per_transaction DECIMAL(15,2) DEFAULT 5000000;
ALTER TABLE user_linked_services ALTER COLUMN limit_per_transaction TYPE DECIMAL(15,2);

-- 7/7/2026
ALTER TABLE merchant_balances 
ADD COLUMN IF NOT EXISTS daily_withdraw_usage NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_withdraw_date DATE;

CREATE TABLE IF NOT EXISTS wealth_bag_transactions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    transaction_type VARCHAR(50),
    amount NUMERIC(20,2),
    balance_after NUMERIC(20,2),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_wealth_bags (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    balance DECIMAL(15, 2) DEFAULT 0.00,
    total_profit DECIMAL(15, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 11/07/2026
ALTER TABLE merchant_callback_configs ADD COLUMN IF NOT EXISTS unlink_callback_url VARCHAR(255);

CREATE SEQUENCE IF NOT EXISTS transaction_ref_seq START 100000000000 INCREMENT 1;

ALTER TABLE ledger_transactions
ADD COLUMN IF NOT EXISTS category_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS is_expense_counted BOOLEAN DEFAULT true;

CREATE TABLE IF NOT EXISTS loyalty_point_batches (
    id UUID PRIMARY KEY,
    wallet_id UUID NOT NULL REFERENCES wallets(id),
    initial_amount BIGINT NOT NULL,
    remaining_amount BIGINT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    ledger_transaction_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_checkins (
    user_id UUID PRIMARY KEY, 
    last_checkin_date DATE, 
    current_streak INT DEFAULT 0, 
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_checkins_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
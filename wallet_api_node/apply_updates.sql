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

CREATE TABLE split_bills (
    id SERIAL PRIMARY KEY,
    creator_id UUID REFERENCES users(id) ON DELETE CASCADE,
    total_amount DECIMAL(15, 2) NOT NULL,
    split_amount DECIMAL(15, 2) NOT NULL,
    note TEXT,
    status VARCHAR(50) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE split_bill_members (
    id SERIAL PRIMARY KEY,
    split_bill_id INTEGER REFERENCES split_bills(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING',
    paid_at TIMESTAMP
);

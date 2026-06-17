CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER', -- MEMBER, STAFF, ADMIN
    tier VARCHAR(20) NOT NULL DEFAULT 'SILVER', -- SILVER, GOLD, VIP
    total_points INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE point_rules (
    id SERIAL PRIMARY KEY,
    amount_per_point INT NOT NULL, -- e.g. 100000 = 10 points
    points_earned INT NOT NULL,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    staff_id INT REFERENCES users(id),
    amount NUMERIC NOT NULL,
    description TEXT,
    qr_payload TEXT,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE loyalty_history (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    amount NUMERIC NOT NULL,
    points_earned INT NOT NULL,
    type VARCHAR(20) NOT NULL, -- EARN, REDEEM
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rewards (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    points_required INT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default point rule (e.g. 10,000 VND = 1 point)
INSERT INTO point_rules (amount_per_point, points_earned) VALUES (10000, 1);

-- Insert admin and some staff/member for testing
-- password: 123 (hashed using bcrypt later, but for sql init we can insert plain or hash if we know it. I will let the backend handle user creation or we can insert hashes. Actually, better to just let the backend seed it or insert a plain one if we don't hash yet. Let's not insert users here, we'll do it via API).

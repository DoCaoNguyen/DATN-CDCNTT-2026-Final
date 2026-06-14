-- 002_email_verification.sql

ALTER TABLE users ADD COLUMN email_otp VARCHAR(10) NULL;
ALTER TABLE users ADD COLUMN email_otp_expired_at TIMESTAMP NULL;

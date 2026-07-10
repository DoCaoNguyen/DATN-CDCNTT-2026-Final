require('dotenv').config();
const { Pool } = require('pg');
const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT
});

const updates = [
  { key: 'refresh_token_ttl_days', group: 'XÁC THỰC', desc: 'Thời gian sống của Refresh Token (ngày)' },
  { key: 'max_login_attempts', group: 'XÁC THỰC', desc: 'Khóa tài khoản tạm thời sau số lần đăng nhập sai' },
  { key: 'access_token_ttl_minutes', group: 'XÁC THỰC', desc: 'Thời gian sống của Access Token (phút)' },
  { key: 'payment_expiry_minutes', group: 'THANH TOÁN', desc: 'Thời gian hết hạn mặc định của đơn thanh toán (phút)' },
  { key: 'signature_timestamp_tolerance_minutes', group: 'THANH TOÁN', desc: 'Độ trễ thời gian cho phép của chữ ký Merchant API (phút)' },
  { key: 'qr_expiry_minutes', group: 'MÃ QR', desc: 'Thời gian hết hạn của mã QR động (phút)' },
  { key: 'webhook_max_retry', group: 'WEBHOOK', desc: 'Số lần thử lại tối đa cho Webhook' },
  { key: 'webhook_retry_schedule', group: 'WEBHOOK', desc: 'Lịch trình thử lại Webhook (mảng phút)' },
  { key: 'audit_log_retention_days', group: 'NHẬT KÝ', desc: 'Thời gian lưu trữ nhật ký hệ thống (ngày)' },
  { key: 'default_currency', group: 'VÍ', desc: 'Loại tiền tệ mặc định của Ví' }
];

async function main() {
    for (const u of updates) {
        await pool.query(
            'UPDATE app_settings SET setting_group = $1, description = $2 WHERE setting_key = $3',
            [u.group, u.desc, u.key]
        );
    }
    console.log('Update successful');
    pool.end();
}
main();

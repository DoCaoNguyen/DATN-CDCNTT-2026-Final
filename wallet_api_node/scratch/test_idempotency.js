const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
require('dotenv').config();

const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '123',
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'wallet_db'
});

async function runTest() {
    try {
        console.log("=============================================================");
        console.log("🚀 BẮT ĐẦU TEST DOUBLE PAYMENT (IDEMPOTENCY CONCURRENCY) 🚀");
        console.log("=============================================================\n");
        
        // 1. Lấy 1 User bất kỳ từ DB
        const resUser = await pool.query(`SELECT id, role, token_version FROM users LIMIT 1`);
        if (resUser.rows.length === 0) {
            console.log("Không có user nào trong DB để test!");
            return;
        }
        const user = resUser.rows[0];

        // 2. Tạo JWT Token hợp lệ
        const token = jwt.sign(
            { userId: user.id, role: user.role, tokenVersion: user.token_version },
            process.env.JWT_SECRET,
            { expiresIn: '15m' }
        );

        // 3. Chuẩn bị dữ liệu form-data
        const formData = new FormData();
        formData.append('amount', '10000');
        formData.append('pin', '000000'); // Mã PIN đã reset
        formData.append('external_reference', 'TEST_IDEM_' + Date.now());

        const idempotencyKey = crypto.randomUUID();
        const url = 'http://localhost:8000/api/v1/transaction/deposit';

        const requestOptions = {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Idempotency-Key': idempotencyKey
            },
            body: formData
        };

        console.log(`🔄 Đang chuẩn bị bắn ĐỒNG THỜI 100 requests Nạp Tiền...`);
        console.log(`🔑 Sử dụng chung Idempotency-Key: ${idempotencyKey}`);
        console.log(`⏱️ Đợi 3 giây...`);
        await new Promise(r => setTimeout(r, 3000));

        // Bắn 100 requests cùng 1 thời điểm!
        const promises = [];
        for (let i = 0; i < 100; i++) {
            promises.push(fetch(url, requestOptions).then(async r => {
                const text = await r.text();
                return { status: r.status, body: text };
            }).catch(e => {
                return { status: 'Network Error', body: e.message };
            }));
        }

        const results = await Promise.all(promises);
        
        let successCount = 0;
        let conflictCount = 0;
        let cachedCount = 0;
        let errorCount = 0;

        results.forEach(r => {
            if (r.status === 200) {
                // Kiểm tra xem đây là kết quả xử lý thực hay kết quả lấy từ Cache của Idempotency
                // API Gốc trả về: { message: "Nạp tiền thành công", data: {...} }
                successCount++;
            } else if (r.status === 409) {
                conflictCount++;
            } else {
                errorCount++;
                console.log(`[LỖI]: HTTP ${r.status} - ${r.body.substring(0, 150)}`);
            }
        });

        console.log("\n================ KẾT QUẢ BÀI TEST ================");
        console.log(`📊 Tổng số requests đã gửi   : 100`);
        console.log(`✅ Thành công (Lọt qua chốt) : ${successCount} request`);
        console.log(`⚠️ Bị chặn bởi Redis Lock    : ${conflictCount} requests (HTTP 409)`);
        console.log(`❌ Lỗi khác                  : ${errorCount} requests`);
        
        if (successCount === 1 && conflictCount === 99) {
            console.log("\n🏆 KẾT LUẬN: CƠ CHẾ IDEMPOTENCY HOẠT ĐỘNG HOÀN HẢO! 🏆");
            console.log("   -> Chỉ có đúng 1 request được xử lý cộng tiền.");
            console.log("   -> 99 request còn lại bị Distributed Lock chặn đứng tức thời!");
        } else {
            console.log("\n❌ KẾT LUẬN: CÓ LỖI HOẶC CHƯA CHẶN ĐƯỢC CONCURRENCY!");
        }
        console.log("==================================================");

    } catch (e) {
        console.error(e);
    } finally {
        await pool.end();
    }
}

runTest();

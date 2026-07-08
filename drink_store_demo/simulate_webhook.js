const crypto = require('crypto');
require('dotenv').config({ path: '.env.local' });

async function simulateWebhook() {
  const merchantOrderId = process.argv[2];
  
  if (!merchantOrderId) {
    console.log("CÁCH DÙNG: node simulate_webhook.js <merchant_order_id>");
    console.log("Ví dụ: node simulate_webhook.js STORE_ORD_1720256000000_123");
    return;
  }

  const secretKey = process.env.MERCHANT_SECRET_KEY;
  if (!secretKey) {
    console.error("LỖI: Chưa cấu hình MERCHANT_SECRET_KEY trong .env.local");
    return;
  }

  // Tự động lấy CALLBACK_URL từ .env.local, nếu không có thì mặc định port 3001
  const webhookUrl = process.env.CALLBACK_URL || 'http://localhost:3001/api/webhook';
  
  // Payload giả lập Ví Mio trả về
  const payload = {
    merchant_order_id: merchantOrderId,
    status: 'PAID',
    amount: 45000,
    orderCode: 'VIO_' + Date.now(),
    wallet_transaction_id: 'TXN_' + Date.now(),
    phone_number: '0987654321'
  };

  const payloadString = JSON.stringify(payload);
  
  // Tính chữ ký HMAC SHA256
  const hmac = crypto.createHmac('sha256', secretKey);
  const signature = hmac.update(payloadString).digest('hex');

  console.log('Đang gửi Webhook giả lập đến Cửa hàng (' + webhookUrl + ')...');

  try {
    const res = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-webhook-signature': signature
      },
      body: payloadString
    });
    
    const data = await res.json();
    console.log('\n✅ KẾT QUẢ: Thành công! Drink store phản hồi:', data);
    console.log('👉 Hãy quay lại trình duyệt, trang sẽ tự động chuyển sang trang Success!');
  } catch (error) {
    console.log('\n❌ KẾT QUẢ: Thất bại (Lỗi gọi API)!');
    console.error('Chi tiết lỗi:', error.message);
    console.log('---');
    console.log('GỢI Ý: Đảm bảo trang web Drink Store đang được bật và Port khớp với', webhookUrl);
  }
}

simulateWebhook();

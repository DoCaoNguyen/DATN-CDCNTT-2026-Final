const { Pool } = require('pg');
require('dotenv').config({ path: '.env.local' });

const storePool = new Pool({ connectionString: process.env.DATABASE_URL });

const walletPool = new Pool({
  connectionString: 'postgresql://postgres:123456@localhost:5432/ewallet_core_db'
});

storePool.query("SELECT merchant_order_id FROM store_orders WHERE status = 'PENDING' ORDER BY id DESC LIMIT 1").then(async res => {
  if (res.rows.length > 0) {
    const merchantOrderId = res.rows[0].merchant_order_id;
    console.log("Tìm thấy đơn hàng:", merchantOrderId);
    
    try {
      await walletPool.query("UPDATE payment_orders SET status = 'SUCCESS' WHERE merchant_order_id = " + "'"+ merchantOrderId + "'");
      console.log("✅ Đã ép trạng thái đơn hàng trên Ví Mio thành SUCCESS!");
    } catch (e) {
      console.error("Lỗi cập nhật DB Ví Mio:", e.message);
    }
    
    const { exec } = require('child_process');
    exec('node simulate_webhook.js ' + merchantOrderId, (error, stdout, stderr) => {
      if (error) {
        console.error("Lỗi:", error.message);
      }
      if (stderr) {
        console.error("Stderr:", stderr);
      }
      console.log(stdout);
      
      storePool.end();
      walletPool.end();
    });
  } else {
    console.log('Không có đơn hàng nào PENDING');
    storePool.end();
    walletPool.end();
  }
});

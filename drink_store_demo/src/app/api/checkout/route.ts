import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';

export async function POST(req: NextRequest) {
  try {
    const { productName, amount } = await req.json();

    if (!productName || !amount) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    // 1. Tạo đơn hàng trong DB nội bộ (trạng thái PENDING)
    const merchantOrderId = `STORE_ORD_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    const insertRes = await query(
      'INSERT INTO store_orders (product_name, amount, merchant_order_id) VALUES ($1, $2, $3) RETURNING id',
      [productName, amount, merchantOrderId]
    );
    const orderId = insertRes.rows[0].id;

    // 2. Gọi API của Ví Điện Tử để tạo QRCode Thanh toán (Merchant API)
    // Cần API_KEY hợp lệ. Ta sẽ sử dụng biến môi trường.
    // Nếu API_KEY chưa có, app demo vẫn chạy giả lập hoặc báo lỗi tùy config.
    const apiKey = process.env.MERCHANT_API_KEY;
    if (!apiKey) {
      // Dummy demo mode nếu chưa config API KEY (ví dụ cho mục đích test UI)
      console.warn("WARNING: MERCHANT_API_KEY is missing. Using fake QR token.");
      return NextResponse.json({
        orderId,
        qrToken: 'FAKE_QR_TOKEN_FOR_TESTING'
      });
    }

    const walletApiUrl = process.env.WALLET_API_URL || 'http://localhost:3000/api/v1/payment/create';

    const walletRes = await fetch(walletApiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey
      },
      body: JSON.stringify({
        amount: amount,
        description: `Thanh toán: ${productName}`,
        merchant_order_id: merchantOrderId
      })
    });

    const data = await walletRes.json();
    if (!walletRes.ok) {
      throw new Error(data.error || 'Failed to create payment link on Wallet API');
    }

    // 3. Cập nhật qr_token vào database
    // Dữ liệu API Ví trả về qrCode chứa chuỗi URI mio://pay...
    const qrToken = data.data.qrCode;
    await query(
      'UPDATE store_orders SET qr_token = $1 WHERE id = $2',
      [qrToken, orderId]
    );

    return NextResponse.json({
      orderId,
      qrToken,
      message: 'Created order successfully'
    });

  } catch (error: any) {
    console.error('Checkout API Error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

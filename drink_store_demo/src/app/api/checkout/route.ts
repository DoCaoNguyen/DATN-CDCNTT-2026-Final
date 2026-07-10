import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';

export async function POST(req: NextRequest) {
  try {
    const { productName, amount } = await req.json();

    if (!productName || !amount) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    // 1. Tao don hang trong DB noi bo (trang thai PENDING)
    const merchantOrderId = `STORE_ORD_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    const insertRes = await query(
      'INSERT INTO store_orders (product_name, amount, merchant_order_id) VALUES ($1, $2, $3) RETURNING id',
      [productName, amount, merchantOrderId]
    );
    const orderId = insertRes.rows[0].id;

    const apiKey = process.env.MERCHANT_API_KEY;
    if (!apiKey) {
      console.warn('WARNING: MERCHANT_API_KEY chua duoc cau hinh.');
      return NextResponse.json({ error: 'Chua cau hinh MERCHANT_API_KEY trong .env.local' }, { status: 500 });
    }

    // 2. Goi Ví Mio API tao Payment Order (QR Code flow)
    // Endpoint nay chi can X-Api-Key (public key), khong can HMAC signature
    const walletApiBase = process.env.WALLET_API_URL || 'http://localhost:3000/api/v1';
    const walletApiUrl = `${walletApiBase}/payment/create`;


    const walletRes = await fetch(walletApiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Api-Key': apiKey,
      },
      body: JSON.stringify({
        amount: amount,
        description: `Thanh toan: ${productName}`,
        merchant_order_id: merchantOrderId,
      }),
    });

    const data = await walletRes.json();
    if (!walletRes.ok) {
      throw new Error(data.error || data.message || 'Loi tao Payment Order tu Ví Mio');
    }

    // 3. Luu qr_token vao DB
    const qrToken = data?.data?.qr_code || data?.data?.qrCode || data?.qr_code || merchantOrderId;
    await query(
      'UPDATE store_orders SET qr_token = $1 WHERE id = $2',
      [qrToken, orderId]
    );

    return NextResponse.json({
      orderId,
      qrToken,
      merchantOrderId,
      message: 'Tao don hang thanh cong'
    });

  } catch (error: any) {
    console.error('Checkout API Error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}


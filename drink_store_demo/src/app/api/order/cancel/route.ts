import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import crypto from 'crypto';

export async function POST(req: NextRequest) {
  try {
    const { orderId, merchantOrderId } = await req.json();

    if (!orderId && !merchantOrderId) {
      return NextResponse.json({ error: 'Missing orderId or merchantOrderId' }, { status: 400 });
    }

    // Find order
    let orderRes;
    if (orderId) {
      orderRes = await query('SELECT * FROM store_orders WHERE id = $1', [orderId]);
    } else {
      orderRes = await query('SELECT * FROM store_orders WHERE merchant_order_id = $1', [merchantOrderId]);
    }

    if (orderRes.rows.length === 0) {
      return NextResponse.json({ error: 'Order not found' }, { status: 404 });
    }

    const order = orderRes.rows[0];

    if (order.status === 'PAID' || order.status === 'SUCCESS') {
      return NextResponse.json({ error: 'Đơn hàng đã được thanh toán, không thể hủy.' }, { status: 400 });
    }

    if (order.status === 'CANCELED') {
      return NextResponse.json({ message: 'Đơn hàng đã được hủy trước đó' });
    }

    // Call Wallet API to cancel
    const apiKey = process.env.MERCHANT_API_KEY;
    const secretKey = process.env.MERCHANT_SECRET_KEY;
    
    if (!apiKey || !secretKey) {
      console.warn('WARNING: MERCHANT_API_KEY or MERCHANT_SECRET_KEY not configured.');
      return NextResponse.json({ error: 'System configuration error' }, { status: 500 });
    }

    const walletApiBase = process.env.WALLET_API_URL || 'http://localhost:8000/api/v1';
    const walletCancelUrl = `${walletApiBase}/payment/cancel`;

    const timestamp = Date.now().toString();
    const payload = { merchant_order_id: order.merchant_order_id };
    const payloadString = JSON.stringify(payload);
    
    const hmac = crypto.createHmac('sha256', secretKey);
    const signature = hmac.update(`${timestamp}.${payloadString}`).digest('hex');

    const walletRes = await fetch(walletCancelUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Api-Key': apiKey,
        'X-Timestamp': timestamp,
        'X-Signature': signature
      },
      body: payloadString,
    });

    const data = await walletRes.json();
    if (!walletRes.ok) {
      console.error('Wallet Cancel API Error:', data);
      return NextResponse.json({ error: data.error || data.message || 'Lỗi từ hệ thống ví khi hủy đơn' }, { status: walletRes.status });
    }

    // Update store_orders status
    await query('UPDATE store_orders SET status = $1 WHERE id = $2', ['CANCELED', order.id]);

    return NextResponse.json({
      message: 'Hủy đơn thành công',
      orderId: order.id
    });

  } catch (error: any) {
    console.error('Cancel API Error:', error);
    return NextResponse.json({ error: error.message || 'System error' }, { status: 500 });
  }
}

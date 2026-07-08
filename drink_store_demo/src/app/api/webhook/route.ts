import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import crypto from 'crypto';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const signature = req.headers.get('x-vio-signature') || req.headers.get('x-webhook-signature');
    const secretKey = process.env.MERCHANT_SECRET_KEY;

    // Nếu hệ thống Merchant có cấu hình SECRET_KEY, ta verify chữ ký
    if (secretKey && signature) {
      const hmac = crypto.createHmac('sha256', secretKey);
      const computedSignature = hmac.update(JSON.stringify(body)).digest('hex');
      
      if (computedSignature !== signature) {
        return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
      }
    }

    // Body mong đợi: { order_code, merchant_order_id, amount, status }
    const { merchant_order_id, status } = body;

    if (!merchant_order_id || (status !== 'PAID' && status !== 'success')) {
      return NextResponse.json({ error: 'Invalid payload' }, { status: 400 });
    }

    // Cập nhật trạng thái đơn hàng trong DB nội bộ
    await query(
      'UPDATE store_orders SET status = $1 WHERE merchant_order_id = $2',
      ['PAID', merchant_order_id]
    );

    console.log(`[Webhook] Order ${merchant_order_id} has been PAID!`);
    return NextResponse.json({ message: 'Webhook received successfully' });

  } catch (error: any) {
    console.error('Webhook Error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

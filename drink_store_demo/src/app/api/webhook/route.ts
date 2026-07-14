import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import crypto from 'crypto';

export async function POST(req: NextRequest) {
  try {
    // Đọc raw body TEXT trước khi parse - để verify signature trên đúng chuỗi được gửi đến
    const rawBody = await req.text();
    const signature = req.headers.get('x-vio-signature') || req.headers.get('x-webhook-signature');
    const secretKey = process.env.MERCHANT_SECRET_KEY;

    // Verify HMAC trên rawBody string (cùng chuỗi mà E-Wallet đã ký)
    // Nếu verify trên JSON.stringify(JSON.parse(rawBody)) sẽ bị sai do key order bị đảo
    if (secretKey && signature) {
      const computedSignature = crypto
        .createHmac('sha256', secretKey)
        .update(rawBody)  // Ký trên chuỗi gốc, không phải re-serialized
        .digest('hex');
      
      if (computedSignature !== signature) {
        console.error(`[Webhook] Signature mismatch! Expected: ${computedSignature}, Got: ${signature}`);
        return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
      }
    }

    // Parse JSON sau khi đã verify xong
    const body = JSON.parse(rawBody);
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

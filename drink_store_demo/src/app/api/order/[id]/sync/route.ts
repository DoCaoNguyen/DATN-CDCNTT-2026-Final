import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';

export const dynamic = 'force-dynamic';

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: orderId } = await params;
    
    if (!orderId) {
      return NextResponse.json({ error: 'Missing order id' }, { status: 400 });
    }

    const result = await query('SELECT merchant_order_id, status FROM store_orders WHERE id = $1', [orderId]);
    
    if (result.rows.length === 0) {
      return NextResponse.json({ error: 'Order not found' }, { status: 404 });
    }

    const order = result.rows[0];
    if (order.status === 'PAID') {
      return NextResponse.json({ status: 'PAID' });
    }

    const apiKey = process.env.MERCHANT_API_KEY || '';
    if (!apiKey) {
      return NextResponse.json({ error: 'Missing API Key' }, { status: 500 });
    }

    const walletApiBase = process.env.WALLET_API_URL || 'http://localhost:3000/api/v1';
    const walletApiUrl = `${walletApiBase}/payment/status?merchant_order_id=${order.merchant_order_id}`;
    
    const response = await fetch(walletApiUrl, {
      method: 'GET',
      headers: {
        'x-api-key': apiKey
      },
      cache: 'no-store'
    });

    if (!response.ok) {
       return NextResponse.json({ error: 'Failed to check status from wallet' }, { status: response.status });
    }

    const data = await response.json();
    const walletStatus = data.data?.order_status || data.data?.status;

    if (walletStatus === 'PAID' || walletStatus === 'SUCCESS') {
      await query('UPDATE store_orders SET status = $1 WHERE id = $2', ['PAID', orderId]);
      return NextResponse.json({ status: 'PAID' });
    } else if (walletStatus === 'EXPIRED') {
      await query('UPDATE store_orders SET status = $1 WHERE id = $2', ['EXPIRED', orderId]);
      return NextResponse.json({ status: 'EXPIRED' });
    } else if (walletStatus === 'CANCELED') {
      await query('UPDATE store_orders SET status = $1 WHERE id = $2', ['CANCELED', orderId]);
      return NextResponse.json({ status: 'CANCELED' });
    }

    return NextResponse.json({ status: order.status });
  } catch (error: any) {
    console.error('Sync Order API Error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

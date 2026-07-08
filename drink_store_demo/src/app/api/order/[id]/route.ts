import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';

export const dynamic = 'force-dynamic';

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: orderId } = await params;
    
    if (!orderId) {
      return NextResponse.json({ error: 'Missing order id' }, { status: 400 });
    }

    const result = await query('SELECT status, created_at FROM store_orders WHERE id = $1', [orderId]);
    
    if (result.rows.length === 0) {
      return NextResponse.json({ error: 'Order not found' }, { status: 404 });
    }

    const order = result.rows[0];
    let currentStatus = order.status;

    if (currentStatus === 'PENDING') {
      const createdAt = new Date(order.created_at).getTime();
      const now = Date.now();
      const diffMins = (now - createdAt) / (1000 * 60);

      if (diffMins > 15) {
        currentStatus = 'EXPIRED';
        await query('UPDATE store_orders SET status = $1 WHERE id = $2', [currentStatus, orderId]);
      }
    }

    return NextResponse.json({ status: currentStatus });

  } catch (error: any) {
    console.error('Get Order API Error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

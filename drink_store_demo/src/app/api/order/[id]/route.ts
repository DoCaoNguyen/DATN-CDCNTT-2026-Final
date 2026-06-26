import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: orderId } = await params;
    
    if (!orderId) {
      return NextResponse.json({ error: 'Missing order id' }, { status: 400 });
    }

    const result = await query('SELECT status FROM store_orders WHERE id = $1', [orderId]);
    
    if (result.rows.length === 0) {
      return NextResponse.json({ error: 'Order not found' }, { status: 404 });
    }

    return NextResponse.json({ status: result.rows[0].status });

  } catch (error: any) {
    console.error('Get Order API Error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

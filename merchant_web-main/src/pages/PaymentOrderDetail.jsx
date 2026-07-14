import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, Copy, ExternalLink, Calendar, CreditCard, Clock, FileText } from 'lucide-react';
import { toast } from 'sonner';
import { format } from 'date-fns';
import { merchantApi } from '../api/merchantApi';
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card/Card';
import { StatusBadge } from '../components/ui/Badge/StatusBadge';
import { Button } from '../components/ui/Button/Button';
import { Skeleton } from '../components/ui/Skeleton/Skeleton';
import { formatCurrency, formatDate } from '../utils/formatters';

const PaymentOrderDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const { data: orderResponse, isLoading, isError } = useQuery({
    queryKey: ['merchantPaymentOrder', id],
    queryFn: () => merchantApi.getPaymentOrderById(id),
    enabled: !!id,
    retry: false
  });

  let order = orderResponse?.data || orderResponse;
  
  if (order) {
    const exp = order.expired_at || order.expires_at;
    if (order.status === 'PENDING' && exp && new Date(exp) < new Date()) {
      order = { ...order, status: 'EXPIRED' };
    }
  }

  const handleCopy = (text, type) => {
    if (!text) return;
    navigator.clipboard.writeText(text);
    toast.success(`Đã sao chép ${type}`);
  };

  const renderJson = (data) => {
    try {
      if (typeof data === 'string') return JSON.stringify(JSON.parse(data), null, 2);
      return JSON.stringify(data, null, 2);
    } catch {
      return String(data || '');
    }
  };

  if (isLoading) {
    return (
      <div style={{ padding: '2rem' }}>
        <Skeleton height="40px" width="300px" style={{ marginBottom: '2rem' }} />
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px' }}>
          <Skeleton height="400px" />
          <Skeleton height="400px" />
        </div>
      </div>
    );
  }

  if (isError || !order) {
    return (
      <div style={{ padding: '2rem', textAlign: 'center' }}>
        <h2 style={{ color: 'var(--danger-color)' }}>Không tìm thấy đơn thanh toán</h2>
        <Button variant="outline" onClick={() => navigate('/merchant/payment-orders')} style={{ marginTop: '1rem' }}>
          Quay lại danh sách
        </Button>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', paddingBottom: '2rem' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        <Button 
          variant="outline" 
          onClick={() => navigate('/merchant/payment-orders')}
          style={{ padding: '8px', width: '40px', height: '40px', justifyContent: 'center' }}
        >
          <ArrowLeft size={20} />
        </Button>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <h1 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'var(--text-main)', margin: 0 }}>
              {order.payment_no || order.id?.substring(0, 8)}
            </h1>
            <StatusBadge status={order.status} />
          </div>
          <p style={{ color: 'var(--text-muted)', margin: '4px 0 0 0', fontSize: '0.875rem' }}>
            Mã ĐH Merchant: {order.merchant_order_id || '-'}
          </p>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '24px', '@media (min-width: 992px)': { gridTemplateColumns: '2fr 1fr' } }}>
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', alignItems: 'start' }}>
          
          {/* Left Column */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            
            <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
              <CardHeader style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-light)' }}>
                <CardTitle style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <CreditCard size={18} />
                  Thông tin lệnh thanh toán
                </CardTitle>
              </CardHeader>
              <CardContent style={{ padding: '1.25rem' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div>
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Mã lệnh (Payment No)</div>
                    <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{order.payment_no || '-'}</div>
                  </div>
                  <div>
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Mã ĐH Merchant</div>
                    <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{order.merchant_order_id || '-'}</div>
                  </div>
                  <div style={{ gridColumn: '1 / -1' }}>
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Mô tả</div>
                    <div style={{ fontWeight: 500 }}>{order.description || '-'}</div>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
              <CardHeader style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-light)' }}>
                <CardTitle style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <FileText size={18} />
                  Dữ liệu Callback / Payload
                </CardTitle>
              </CardHeader>
              <CardContent style={{ padding: 0 }}>
                <div style={{ background: '#1e293b', color: '#e2e8f0', padding: '1rem', overflowX: 'auto', fontSize: '0.875rem', borderBottomLeftRadius: 'var(--radius-lg)', borderBottomRightRadius: 'var(--radius-lg)' }}>
                  <pre style={{ margin: 0, fontFamily: 'monospace' }}>
                    {renderJson({
                      id: order.id,
                      payment_no: order.payment_no,
                      merchant_order_id: order.merchant_order_id,
                      amount: order.amount,
                      currency: order.currency || 'VND',
                      status: order.status,
                      callback_url: order.callback_url,
                      metadata: order.metadata
                    })}
                  </pre>
                </div>
              </CardContent>
            </Card>

          </div>

          {/* Right Column */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', position: 'sticky', top: '24px' }}>
            
            <Card style={{ boxShadow: 'var(--shadow-sm)', backgroundColor: 'var(--bg-main)', border: '1px solid var(--border-light)' }}>
              <CardContent style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>Tóm tắt thanh toán</div>
                <div style={{ fontSize: '2rem', fontWeight: 700, color: 'var(--text-main)', lineHeight: 1 }}>
                  {formatCurrency(order.amount)}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '8px' }}>
                  <StatusBadge status={order.status} />
                  <span style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>{order.currency || 'VND'}</span>
                </div>
              </CardContent>
            </Card>

            <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
              <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
                <CardTitle style={{ fontSize: '0.875rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Calendar size={16} /> Thời gian
                </CardTitle>
              </CardHeader>
              <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '0.875rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Tạo lúc:</span>
                  <span style={{ fontWeight: 500 }}>{formatDate(order.created_at)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Hết hạn lúc:</span>
                  <span style={{ fontWeight: 500 }}>{order.expired_at ? formatDate(order.expired_at) : '-'}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Cập nhật lúc:</span>
                  <span style={{ fontWeight: 500 }}>{order.updated_at ? formatDate(order.updated_at) : '-'}</span>
                </div>
              </CardContent>
            </Card>

            <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
              <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
                <CardTitle style={{ fontSize: '0.875rem' }}>Thao tác nhanh</CardTitle>
              </CardHeader>
              <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <Button variant="outline" size="sm" onClick={() => handleCopy(order.payment_no || order.id, 'Mã lệnh')} style={{ width: '100%', justifyContent: 'center' }}>
                  Copy Mã lệnh <Copy size={14} style={{ marginLeft: '0.5rem' }} />
                </Button>
                <Button variant="ghost" size="sm" onClick={() => handleCopy(order.merchant_order_id, 'Mã ĐH Merchant')} style={{ width: '100%', justifyContent: 'center' }}>
                  Copy Mã ĐH Merchant
                </Button>
              </CardContent>
            </Card>

          </div>
        </div>
      </div>
    </div>
  );
};

export default PaymentOrderDetail;

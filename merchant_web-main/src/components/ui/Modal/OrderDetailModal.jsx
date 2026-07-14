import { Modal } from './Modal';
import { Button } from '../Button/Button';
import { StatusBadge } from '../Badge/StatusBadge';
import { Card, CardHeader, CardTitle, CardContent } from '../Card/Card';
import { formatCurrency, formatDate } from '../../../utils/formatters';
import { Copy } from 'lucide-react';
import { toast } from 'sonner';

export const OrderDetailModal = ({ isOpen, onClose, order }) => {
  if (!order) return null;

  const handleCopy = (text) => {
    navigator.clipboard.writeText(text);
    toast.success('Đã sao chép');
  };

  const renderJson = (data) => {
    try {
      return JSON.stringify(data, null, 2);
    } catch {
      return '';
    }
  };

  const headerTitle = (
    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
      <span>Chi tiết lệnh thanh toán</span>
      <span style={{ fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-muted)' }}>
        #{order.payment_no?.substring(0, 8) || order.id?.substring(0, 8)}
      </span>
      <StatusBadge status={order.status} />
    </div>
  );

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={headerTitle} maxWidth="1000px">
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', alignItems: 'start' }}>

        {/* Left Column - Main Content */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>

          <Card style={{ boxShadow: 'none' }}>
            <CardHeader style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-light)' }}>
              <CardTitle>Thông tin chung</CardTitle>
            </CardHeader>
            <CardContent style={{ padding: '1.25rem' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                <div>
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Mã lệnh (Payment No)</div>
                  <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{order.payment_no || ''}</div>
                </div>
                <div>
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Mã ĐH Merchant</div>
                  <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{order.merchant_order_id || '-'}</div>
                </div>
                <div style={{ gridColumn: '1 / -1' }}>
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Nội dung/Mô tả</div>
                  <div style={{ padding: '12px', background: 'var(--bg-main)', borderRadius: 'var(--radius-md)', fontSize: '0.875rem' }}>
                    {order.description || order.cancel_reason || 'Không có mô tả'}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card style={{ boxShadow: 'none' }}>
            <CardHeader style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-light)' }}>
              <CardTitle>Dữ liệu Callback / Payload</CardTitle>
            </CardHeader>
            <CardContent style={{ padding: 0 }}>
              <div style={{ background: '#1e293b', color: '#e2e8f0', padding: '1rem', overflowX: 'auto', maxHeight: '400px', fontSize: '0.875rem', borderBottomLeftRadius: 'var(--radius-lg)', borderBottomRightRadius: 'var(--radius-lg)' }}>
                <pre style={{ margin: 0, fontFamily: 'monospace' }}>
                  {renderJson({
                    id: order.id,
                    payment_no: order.payment_no,
                    amount: order.amount,
                    currency: order.currency,
                    status: order.status,
                    merchant_order_id: order.merchant_order_id,
                    return_url: order.return_url,
                    cancel_url: order.cancel_url,
                    webhook_url: order.webhook_url,
                    created_at: order.created_at,
                  })}
                </pre>
              </div>
            </CardContent>
          </Card>

        </div>

        {/* Right Column - Sticky Sidebar */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', position: 'sticky', top: '0' }}>

          <Card style={{ boxShadow: 'none', backgroundColor: 'var(--bg-main)', border: 'none' }}>
            <CardContent style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>Tổng thanh toán</div>
              <div style={{ fontSize: '2rem', fontWeight: 700, color: 'var(--text-main)', lineHeight: 1 }}>
                {formatCurrency(order.amount)}
              </div>
            </CardContent>
          </Card>

          <Card style={{ boxShadow: 'none' }}>
            <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
              <CardTitle style={{ fontSize: '0.875rem' }}>Thời gian</CardTitle>
            </CardHeader>
            <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '0.875rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Tạo lúc:</span>
                <span style={{ fontWeight: 500 }}>{formatDate(order.created_at)}</span>
              </div>
              {order.expired_at && (
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Hết hạn:</span>
                  <span style={{ fontWeight: 500 }}>{formatDate(order.expired_at)}</span>
                </div>
              )}
            </CardContent>
          </Card>

          <Card style={{ boxShadow: 'none' }}>
            <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
              <CardTitle style={{ fontSize: '0.875rem' }}>Thao tác nhanh</CardTitle>
            </CardHeader>
            <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <Button variant="outline" size="sm" onClick={() => handleCopy(order.payment_no || order.id)} style={{ width: '100%', justifyContent: 'center' }}>
                Sao chép Mã lệnh <Copy size={14} style={{ marginLeft: '0.5rem' }} />
              </Button>
              {order.merchant_order_id && (
                <Button variant="ghost" size="sm" onClick={() => handleCopy(order.merchant_order_id)} style={{ width: '100%', justifyContent: 'center' }}>
                  Sao chép Mã ĐH
                </Button>
              )}
            </CardContent>
          </Card>

        </div>
      </div>

      <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '24px', paddingTop: '16px', borderTop: '1px solid var(--border-light)' }}>
        <Button onClick={onClose} variant="secondary">Đóng cửa sổ</Button>
      </div>
    </Modal>
  );
};

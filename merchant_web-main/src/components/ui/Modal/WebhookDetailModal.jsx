import { Modal } from './Modal';
import { Button } from '../Button/Button';
import { StatusBadge } from '../Badge/StatusBadge';
import { Card, CardHeader, CardTitle, CardContent } from '../Card/Card';
import { formatCurrency, formatDate } from '../../../utils/formatters';
import { Copy, RefreshCw } from 'lucide-react';
import { toast } from 'sonner';

export const WebhookDetailModal = ({ isOpen, onClose, webhook, onRetry, onConfirmRetry }) => {
  if (!webhook) return null;

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
      <span>Chi tiết Webhook</span>
      <span style={{ fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-muted)' }}>
        #{webhook.id?.substring(0, 8)}
      </span>
      <StatusBadge status={webhook.status} />
    </div>
  );

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={headerTitle} maxWidth="1000px">
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', alignItems: 'start' }}>
        
        {/* Left Column - Main Content */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          
          <Card style={{ boxShadow: 'none' }}>
            <CardHeader style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-light)' }}>
              <CardTitle>Payload Gửi đi</CardTitle>
            </CardHeader>
            <CardContent style={{ padding: 0 }}>
              <div style={{ background: '#1e293b', color: '#e2e8f0', padding: '1rem', overflowX: 'auto', maxHeight: '400px', fontSize: '0.875rem', borderBottomLeftRadius: 'var(--radius-lg)', borderBottomRightRadius: 'var(--radius-lg)' }}>
                <pre style={{ margin: 0, fontFamily: 'monospace' }}>
                  {renderJson(webhook.payload)}
                </pre>
              </div>
            </CardContent>
          </Card>

          {webhook.last_error && (
            <Card style={{ boxShadow: 'none' }}>
              <CardHeader style={{ padding: '1.25rem', borderBottom: '1px solid var(--status-failed-bg)', backgroundColor: 'var(--status-failed-bg)' }}>
                <CardTitle style={{ color: 'var(--status-failed)' }}>Lỗi phản hồi gần nhất (Response/Error)</CardTitle>
              </CardHeader>
              <CardContent style={{ padding: '1.25rem', backgroundColor: 'var(--status-failed-bg)', borderBottomLeftRadius: 'var(--radius-lg)', borderBottomRightRadius: 'var(--radius-lg)' }}>
                 <div style={{ color: 'var(--status-failed)', fontSize: '0.875rem', fontWeight: 500 }}>
                   {webhook.last_error}
                 </div>
              </CardContent>
            </Card>
          )}

        </div>

        {/* Right Column - Sticky Sidebar */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', position: 'sticky', top: '0' }}>
          
          <Card style={{ boxShadow: 'none', backgroundColor: 'var(--bg-main)', border: 'none' }}>
            <CardContent style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>Loại sự kiện</div>
              <div style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--text-main)', lineHeight: 1 }}>
                {webhook.event_type}
              </div>
            </CardContent>
          </Card>

          <Card style={{ boxShadow: 'none' }}>
            <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
              <CardTitle style={{ fontSize: '0.875rem' }}>Lịch sử & Thời gian</CardTitle>
            </CardHeader>
            <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '0.875rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Số lần thử:</span>
                <span style={{ fontWeight: 500 }}>{webhook.attempt_count || 0}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Tạo lúc:</span>
                <span style={{ fontWeight: 500 }}>{formatDate(webhook.created_at)}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Lần thử cuối:</span>
                <span style={{ fontWeight: 500 }}>{webhook.last_attempt_at ? formatDate(webhook.last_attempt_at) : '-'}</span>
              </div>
            </CardContent>
          </Card>

          <Card style={{ boxShadow: 'none' }}>
            <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
              <CardTitle style={{ fontSize: '0.875rem' }}>Thao tác nhanh</CardTitle>
            </CardHeader>
            <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <Button variant="outline" size="sm" onClick={() => handleCopy(webhook.id)} style={{ width: '100%', justifyContent: 'center' }}>
                Sao chép Event ID <Copy size={14} style={{ marginLeft: '0.5rem' }} />
              </Button>
              <Button variant="ghost" size="sm" onClick={() => handleCopy(renderJson(webhook.payload))} style={{ width: '100%', justifyContent: 'center' }}>
                Sao chép Payload JSON
              </Button>
              
              {(webhook.status === 'FAILED' || webhook.can_retry === true) && (
                <div style={{ marginTop: '8px', paddingTop: '16px', borderTop: '1px solid var(--border-light)' }}>
                  <Button variant="primary" size="sm" onClick={() => onConfirmRetry ? onConfirmRetry(webhook) : onRetry?.()} style={{ width: '100%', justifyContent: 'center' }}>
                    Gửi lại webhook <RefreshCw size={14} style={{ marginLeft: '0.5rem' }} />
                  </Button>
                </div>
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

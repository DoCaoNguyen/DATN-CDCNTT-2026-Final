import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, Copy, Clock, Globe, ShieldAlert, RefreshCw, Code, RefreshCcw } from 'lucide-react';
import { toast } from 'sonner';
import { merchantApi } from '../api/merchantApi';
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card/Card';
import { StatusBadge } from '../components/ui/Badge/StatusBadge';
import { Button } from '../components/ui/Button/Button';
import { Skeleton } from '../components/ui/Skeleton/Skeleton';
import { ConfirmModal } from '../components/ui/Modal/ConfirmModal';
import { formatDate } from '../utils/formatters';

const WebhookDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [isRetrying, setIsRetrying] = useState(false);
  const [retryModalOpen, setRetryModalOpen] = useState(false);

  const { data: webhookResponse, isLoading, isError, refetch } = useQuery({
    queryKey: ['merchantWebhook', id],
    queryFn: () => merchantApi.getWebhookById(id),
    enabled: !!id,
    retry: false
  });

  const webhook = webhookResponse?.data || webhookResponse;

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

  const handleRetry = async () => {
    try {
      setIsRetrying(true);
      await merchantApi.retryWebhook(webhook.id);
      toast.success('Đã gửi lệnh thử lại webhook');
      setRetryModalOpen(false);
      refetch();
    } catch (err) {
      toast.error('Thử lại thất bại: ' + (err.response?.data?.message || err.message));
    } finally {
      setIsRetrying(false);
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

  if (isError || !webhook) {
    return (
      <div style={{ padding: '2rem', textAlign: 'center' }}>
        <h2 style={{ color: 'var(--danger-color)' }}>Không tìm thấy Webhook Event</h2>
        <Button variant="outline" onClick={() => navigate('/merchant/webhooks')} style={{ marginTop: '1rem' }}>
          Quay lại danh sách
        </Button>
      </div>
    );
  }

  const canRetry = webhook.status === 'FAILED' || webhook.can_retry;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px', paddingBottom: '2rem' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <Button 
            variant="outline" 
            onClick={() => navigate('/merchant/webhooks')}
            style={{ padding: '8px', width: '40px', height: '40px', justifyContent: 'center' }}
          >
            <ArrowLeft size={20} />
          </Button>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <h1 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'var(--text-main)', margin: 0 }}>
                {webhook.id?.substring(0, 8)}...
              </h1>
              <StatusBadge status={webhook.status} />
            </div>
            <p style={{ color: 'var(--text-muted)', margin: '4px 0 0 0', fontSize: '0.875rem' }}>
              Event: {webhook.event_type}
            </p>
          </div>
        </div>
        
        {canRetry && (
          <Button onClick={() => setRetryModalOpen(true)} disabled={isRetrying}>
            <RefreshCw size={16} style={{ marginRight: '8px' }} className={isRetrying ? 'spin' : ''} />
            Thử lại
          </Button>
        )}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '24px', '@media (min-width: 992px)': { gridTemplateColumns: '2fr 1fr' } }}>
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', alignItems: 'start' }}>
          
          {/* Left Column */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
            
            <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
              <CardHeader style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-light)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <CardTitle style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Code size={18} />
                  Payload
                </CardTitle>
                <Button variant="ghost" size="sm" onClick={() => handleCopy(renderJson(webhook.payload), 'Payload')}>
                  Copy
                </Button>
              </CardHeader>
              <CardContent style={{ padding: 0 }}>
                <div style={{ background: '#1e293b', color: '#e2e8f0', padding: '1rem', overflowX: 'auto', fontSize: '0.875rem', borderBottomLeftRadius: 'var(--radius-lg)', borderBottomRightRadius: 'var(--radius-lg)', maxHeight: '400px' }}>
                  <pre style={{ margin: 0, fontFamily: 'monospace' }}>
                    {renderJson(webhook.payload)}
                  </pre>
                </div>
              </CardContent>
            </Card>

            <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
              <CardHeader style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-light)' }}>
                <CardTitle style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <RefreshCcw size={18} />
                  Lịch sử gửi (Attempts)
                </CardTitle>
              </CardHeader>
              <CardContent style={{ padding: '1.25rem' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div>
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Số lần thử (Attempt Count)</div>
                    <div style={{ fontWeight: 500 }}>{webhook.attempt_count || 0}</div>
                  </div>
                  <div>
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Lần thử cuối (Last Attempt)</div>
                    <div style={{ fontWeight: 500 }}>{webhook.last_attempt_at ? formatDate(webhook.last_attempt_at) : '-'}</div>
                  </div>
                  <div style={{ gridColumn: '1 / -1' }}>
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Lỗi lần thử cuối (Last Error)</div>
                    <div style={{ fontWeight: 500, color: 'var(--danger-color)', wordBreak: 'break-word' }}>
                      {webhook.last_error || '-'}
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            {(webhook.response_body || webhook.response_status) && (
              <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
                <CardHeader style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-light)' }}>
                  <CardTitle style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <ShieldAlert size={18} />
                    Response / Error
                  </CardTitle>
                </CardHeader>
                <CardContent style={{ padding: 0 }}>
                  <div style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
                    <span style={{ color: 'var(--text-muted)', marginRight: '8px' }}>HTTP Status:</span>
                    <span style={{ fontWeight: 600 }}>{webhook.response_status || '-'}</span>
                  </div>
                  <div style={{ background: '#1e293b', color: '#e2e8f0', padding: '1rem', overflowX: 'auto', fontSize: '0.875rem', borderBottomLeftRadius: 'var(--radius-lg)', borderBottomRightRadius: 'var(--radius-lg)' }}>
                    <pre style={{ margin: 0, fontFamily: 'monospace' }}>
                      {renderJson(webhook.response_body || webhook.error_message)}
                    </pre>
                  </div>
                </CardContent>
              </Card>
            )}

          </div>

          {/* Right Column */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', position: 'sticky', top: '24px' }}>
            
            <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
              <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
                <CardTitle style={{ fontSize: '0.875rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Globe size={16} /> Thông tin sự kiện
                </CardTitle>
              </CardHeader>
              <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '0.875rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Event Type:</span>
                  <span style={{ fontWeight: 500 }}>{webhook.event_type}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Status:</span>
                  <StatusBadge status={webhook.status} />
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Created:</span>
                  <span style={{ fontWeight: 500 }}>{formatDate(webhook.created_at)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Updated:</span>
                  <span style={{ fontWeight: 500 }}>{formatDate(webhook.updated_at)}</span>
                </div>
              </CardContent>
            </Card>

            <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
              <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
                <CardTitle style={{ fontSize: '0.875rem' }}>Thao tác nhanh</CardTitle>
              </CardHeader>
              <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <Button variant="outline" size="sm" onClick={() => handleCopy(webhook.id, 'Event ID')} style={{ width: '100%', justifyContent: 'center' }}>
                  Copy Event ID <Copy size={14} style={{ marginLeft: '0.5rem' }} />
                </Button>
                {canRetry && (
                  <Button variant="ghost" size="sm" onClick={() => setRetryModalOpen(true)} style={{ width: '100%', justifyContent: 'center', color: 'var(--primary-color)' }}>
                    <RefreshCw size={14} style={{ marginRight: '0.5rem' }} /> Thử lại
                  </Button>
                )}
              </CardContent>
            </Card>

          </div>
        </div>
      </div>

      <ConfirmModal
        isOpen={retryModalOpen}
        onClose={() => setRetryModalOpen(false)}
        onConfirm={handleRetry}
        title="Xác nhận thử lại Webhook"
        message={`Bạn có chắc chắn muốn gửi lại sự kiện webhook ${webhook.id?.substring(0, 8)} không?`}
        confirmText="Thử lại"
        cancelText="Hủy"
        type="warning"
      />
    </div>
  );
};

export default WebhookDetail;

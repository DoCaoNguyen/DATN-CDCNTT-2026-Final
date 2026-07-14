import { Modal } from './Modal';
import { Button } from '../Button/Button';
import { StatusBadge } from '../Badge/StatusBadge';
import { Card, CardHeader, CardTitle, CardContent } from '../Card/Card';
import { formatCurrency, formatDate } from '../../../utils/formatters';
import { Copy } from 'lucide-react';
import { toast } from 'sonner';

export const TransactionDetailModal = ({ isOpen, onClose, transaction }) => {
  if (!transaction) return null;

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
      <span>Chi tiết giao dịch</span>
      <span style={{ fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-muted)' }}>
        #{transaction.id?.substring(0, 8)}
      </span>
      <StatusBadge status={transaction.status} />
    </div>
  );

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={headerTitle} maxWidth="900px">
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
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Mã Giao dịch (TX)</div>
                  <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{transaction.id || '-'}</div>
                </div>
                <div>
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Mã Lệnh TT (Payment No)</div>
                  <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{transaction.payment_no || '-'}</div>
                </div>
                <div>
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Loại giao dịch</div>
                  <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{transaction.transaction_type || transaction.type || '-'}</div>
                </div>
                <div>
                  <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Mã Provider (Ref)</div>
                  <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{transaction.provider_ref_id || '-'}</div>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card style={{ boxShadow: 'none' }}>
            <CardHeader style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-light)' }}>
              <CardTitle>Metadata (JSON)</CardTitle>
            </CardHeader>
            <CardContent style={{ padding: 0 }}>
              <div style={{ background: '#1e293b', color: '#e2e8f0', padding: '1rem', overflowX: 'auto', maxHeight: '400px', fontSize: '0.875rem', borderBottomLeftRadius: 'var(--radius-lg)', borderBottomRightRadius: 'var(--radius-lg)' }}>
                <pre style={{ margin: 0, fontFamily: 'monospace' }}>
                  {renderJson({
                    id: transaction.id,
                    payment_no: transaction.payment_no,
                    amount: transaction.amount,
                    currency: transaction.currency,
                    status: transaction.status,
                    provider_ref_id: transaction.provider_ref_id,
                    metadata: transaction.metadata
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
              <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>Giá trị giao dịch</div>
              <div style={{ fontSize: '2rem', fontWeight: 700, color: 'var(--text-main)', lineHeight: 1 }}>
                {formatCurrency(transaction.amount)}
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
                <span style={{ fontWeight: 500 }}>{formatDate(transaction.created_at)}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Thanh toán lúc:</span>
                <span style={{ fontWeight: 500 }}>{transaction.paid_at ? formatDate(transaction.paid_at) : '-'}</span>
              </div>
            </CardContent>
          </Card>

          <Card style={{ boxShadow: 'none' }}>
            <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
              <CardTitle style={{ fontSize: '0.875rem' }}>Thao tác nhanh</CardTitle>
            </CardHeader>
            <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <Button variant="outline" size="sm" onClick={() => handleCopy(transaction.id)} style={{ width: '100%', justifyContent: 'center' }}>
                Sao chép Mã GD <Copy size={14} style={{ marginLeft: '0.5rem' }} />
              </Button>
              {transaction.payment_no && (
                <Button variant="ghost" size="sm" onClick={() => handleCopy(transaction.payment_no)} style={{ width: '100%', justifyContent: 'center' }}>
                  Sao chép Mã lệnh TT
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

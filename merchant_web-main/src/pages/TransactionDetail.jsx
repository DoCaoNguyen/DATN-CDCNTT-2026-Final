import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, Copy, Clock, FileText, Database, DollarSign } from 'lucide-react';
import { toast } from 'sonner';
import { merchantApi } from '../api/merchantApi';
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card/Card';
import { StatusBadge } from '../components/ui/Badge/StatusBadge';
import { Button } from '../components/ui/Button/Button';
import { Skeleton } from '../components/ui/Skeleton/Skeleton';
import { formatCurrency, formatDate } from '../utils/formatters';

const TransactionDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const { data: txResponse, isLoading, isError } = useQuery({
    queryKey: ['merchantTransaction', id],
    queryFn: () => merchantApi.getTransactionById(id),
    enabled: !!id,
    retry: false
  });

  const transaction = txResponse?.data || txResponse;

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

  if (isError || !transaction) {
    return (
      <div style={{ padding: '2rem', textAlign: 'center' }}>
        <h2 style={{ color: 'var(--danger-color)' }}>Không tìm thấy giao dịch</h2>
        <Button variant="outline" onClick={() => navigate('/merchant/transactions')} style={{ marginTop: '1rem' }}>
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
          onClick={() => navigate('/merchant/transactions')}
          style={{ padding: '8px', width: '40px', height: '40px', justifyContent: 'center' }}
        >
          <ArrowLeft size={20} />
        </Button>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <h1 style={{ fontSize: '1.5rem', fontWeight: 600, color: 'var(--text-main)', margin: 0 }}>
              {transaction.transaction_no || transaction.id?.substring(0, 8)}
            </h1>
            <StatusBadge status={transaction.status} />
          </div>
          <p style={{ color: 'var(--text-muted)', margin: '4px 0 0 0', fontSize: '0.875rem' }}>
            Mã giao dịch chi tiết
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
                  <Database size={18} />
                  Thông tin giao dịch
                </CardTitle>
              </CardHeader>
              <CardContent style={{ padding: '1.25rem' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                  <div>
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Mã giao dịch (ID)</div>
                    <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{transaction.id || '-'}</div>
                  </div>
                  <div>
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Mã lệnh (Payment No)</div>
                    <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{transaction.payment_no || '-'}</div>
                  </div>
                  <div>
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Mã tham chiếu (Ref ID)</div>
                    <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{transaction.provider_ref_id || transaction.reference_id || '-'}</div>
                  </div>
                  <div>
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Loại giao dịch</div>
                    <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{transaction.transaction_type || transaction.type || '-'}</div>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
              <CardHeader style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-light)' }}>
                <CardTitle style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <FileText size={18} />
                  Nguồn phát sinh & Metadata
                </CardTitle>
              </CardHeader>
              <CardContent style={{ padding: 0 }}>
                <div style={{ padding: '1.25rem', borderBottom: '1px solid var(--border-light)' }}>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                    <div>
                      <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Nguồn phát sinh</div>
                      <div style={{ fontWeight: 500 }}>{transaction.source_type || '-'}</div>
                    </div>
                    <div>
                      <div style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '4px' }}>Nguồn ID</div>
                      <div style={{ fontWeight: 500, wordBreak: 'break-all' }}>{transaction.source_id || transaction.payment_order_id || '-'}</div>
                    </div>
                  </div>
                </div>
                <div style={{ background: '#1e293b', color: '#e2e8f0', padding: '1rem', overflowX: 'auto', fontSize: '0.875rem', borderBottomLeftRadius: 'var(--radius-lg)', borderBottomRightRadius: 'var(--radius-lg)' }}>
                  <pre style={{ margin: 0, fontFamily: 'monospace' }}>
                    {renderJson({
                      id: transaction.id,
                      payment_order_id: transaction.payment_order_id,
                      amount: transaction.amount,
                      currency: transaction.currency || 'VND',
                      status: transaction.status,
                      metadata: transaction.metadata
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
                <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>Giá trị giao dịch</div>
                <div style={{ fontSize: '2rem', fontWeight: 700, color: 'var(--text-main)', lineHeight: 1 }}>
                  {formatCurrency(transaction.amount)}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '8px' }}>
                  <StatusBadge status={transaction.status} />
                  <span style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>{transaction.currency || 'VND'}</span>
                </div>
              </CardContent>
            </Card>

            <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
              <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
                <CardTitle style={{ fontSize: '0.875rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Clock size={16} /> Thời gian
                </CardTitle>
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
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Cập nhật lúc:</span>
                  <span style={{ fontWeight: 500 }}>{transaction.updated_at ? formatDate(transaction.updated_at) : '-'}</span>
                </div>
              </CardContent>
            </Card>

            <Card style={{ boxShadow: 'var(--shadow-sm)' }}>
              <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
                <CardTitle style={{ fontSize: '0.875rem' }}>Thao tác nhanh</CardTitle>
              </CardHeader>
              <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <Button variant="outline" size="sm" onClick={() => handleCopy(transaction.id, 'Mã GD')} style={{ width: '100%', justifyContent: 'center' }}>
                  Copy Mã GD <Copy size={14} style={{ marginLeft: '0.5rem' }} />
                </Button>
                {transaction.payment_no && (
                  <Button variant="ghost" size="sm" onClick={() => handleCopy(transaction.payment_no, 'Mã lệnh TT')} style={{ width: '100%', justifyContent: 'center' }}>
                    Copy Mã lệnh TT
                  </Button>
                )}
                {(transaction.source_id || transaction.payment_order_id) && (
                  <Button variant="ghost" size="sm" onClick={() => handleCopy(transaction.source_id || transaction.payment_order_id, 'Source ID')} style={{ width: '100%', justifyContent: 'center' }}>
                    Copy Source ID
                  </Button>
                )}
              </CardContent>
            </Card>

          </div>
        </div>
      </div>
    </div>
  );
};

export default TransactionDetail;

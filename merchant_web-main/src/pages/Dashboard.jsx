import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';
import { Wallet, CreditCard, ArrowLeftRight, Webhook, ArrowRight, RefreshCw } from 'lucide-react';
import { merchantApi } from '../api/merchantApi';
import { formatCurrency } from '../utils/formatters';
import { Card, CardHeader, CardTitle } from '../components/ui/Card/Card';
import { KPICard } from '../components/ui/Card/KPICard';
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from '../components/ui/Table/Table';
import { StatusBadge } from '../components/ui/Badge/StatusBadge';
import { Button } from '../components/ui/Button/Button';
import { Skeleton } from '../components/ui/Skeleton/Skeleton';
import { EmptyState } from '../components/ui/EmptyState/EmptyState';
import PageContainer from '../components/layout/PageContainer';
import PageHeader from '../components/layout/PageHeader';
import KpiGrid from '../components/layout/KpiGrid';

const Dashboard = () => {
  const navigate = useNavigate();

  const { data: balanceData, isLoading: loadingBalance, isError: errorBalance, refetch: refetchBalance } = useQuery({
    queryKey: ['merchantBalance'],
    queryFn: merchantApi.getBalance,
  });

  const { data: paymentsData, isLoading: loadingPayments, isError: errorPayments, refetch: refetchPayments } = useQuery({
    queryKey: ['merchantPaymentOrders'],
    queryFn: () => merchantApi.getPaymentOrders({ page: 1, limit: 5 }),
  });

  const { data: txData, isLoading: loadingTx, isError: errorTx, refetch: refetchTx } = useQuery({
    queryKey: ['merchantTransactions'],
    queryFn: () => merchantApi.getTransactions({ page: 1, limit: 5 }),
  });

  const { data: webhooksData, isLoading: loadingWebhooks, isError: errorWebhooks } = useQuery({
    queryKey: ['merchantWebhooks'],
    queryFn: () => merchantApi.getWebhooks({ page: 1, limit: 5 }),
  });

  // Extract list data
  const payments = paymentsData?.data?.items || paymentsData?.items || paymentsData?.data || [];
  const transactions = txData?.data?.items || txData?.items || txData?.data || [];
  const webhooks = webhooksData?.data?.items || webhooksData?.items || webhooksData?.data || [];
  
  const balance = balanceData?.data?.balance !== undefined ? balanceData.data.balance : balanceData?.balance;
  const holdBalance = balanceData?.data?.hold_balance !== undefined ? balanceData.data.hold_balance : balanceData?.hold_balance;

  return (
    <PageContainer>
      
      {/* Page Header */}
      <PageHeader
        title="Tổng quan"
        description="Theo dõi số dư, đơn thanh toán và webhook gần đây của merchant."
        action={
          <>
            <Button variant="secondary" onClick={() => navigate('/merchant/api-keys')}>
              Quản lý API Keys <ArrowRight size={16} style={{ marginLeft: '0.5rem' }} />
            </Button>
            <Button variant="outline" onClick={() => refetchBalance()}>
              Làm mới số dư <RefreshCw size={16} style={{ marginLeft: '0.5rem' }} />
            </Button>
          </>
        }
      />

      {/* KPI Cards */}
      <KpiGrid>
        {loadingBalance ? <Skeleton style={{ height: '110px' }} /> : errorBalance ? <span className="text-danger">Lỗi tải dữ liệu</span> : (
          <KPICard
            title="Số dư khả dụng"
            value={formatCurrency(balance)}
            subtitle={`Đang tạm giữ: ${formatCurrency(holdBalance)}`}
            icon={Wallet}
            iconColor="var(--primary-color)"
            iconBg="var(--primary-light)"
          />
        )}
        
        {loadingPayments ? <Skeleton style={{ height: '110px' }} /> : errorPayments ? <span className="text-danger">Lỗi tải dữ liệu</span> : (
          <KPICard
            title="Giao dịch thanh toán gần đây"
            value={<>{paymentsData?.meta?.total_items || payments.length || 0} <span style={{ fontSize: '0.875rem', fontWeight: 400, color: 'var(--text-muted)' }}>đơn</span></>}
            icon={CreditCard}
            iconColor="var(--status-active)"
            iconBg="var(--status-active-bg)"
          />
        )}

        {loadingTx ? <Skeleton style={{ height: '110px' }} /> : errorTx ? <span className="text-danger">Lỗi tải dữ liệu</span> : (
          <KPICard
            title="Biến động số dư gần đây"
            value={<>{txData?.meta?.total_items || transactions.length || 0} <span style={{ fontSize: '0.875rem', fontWeight: 400, color: 'var(--text-muted)' }}>GD</span></>}
            icon={ArrowLeftRight}
            iconColor="var(--status-warning)"
            iconBg="var(--status-warning-bg)"
          />
        )}

        {loadingWebhooks ? <Skeleton style={{ height: '110px' }} /> : errorWebhooks ? <span className="text-danger">Lỗi tải dữ liệu</span> : (
          <KPICard
            title="Webhook gửi gần đây"
            value={<>{webhooksData?.meta?.total_items || webhooks.length || 0} <span style={{ fontSize: '0.875rem', fontWeight: 400, color: 'var(--text-muted)' }}>lần gửi</span></>}
            icon={Webhook}
            iconColor="var(--status-sandbox)"
            iconBg="var(--status-sandbox-bg)"
          />
        )}
      </KpiGrid>

      {/* Tables Section */}
      <div className="dashboardTables">
        
        {/* Recent Payment Orders */}
        <Card>
          <CardHeader>
            <CardTitle>Đơn thanh toán mới nhất</CardTitle>
            <Button variant="ghost" size="sm" onClick={() => navigate('/merchant/payment-orders')}>Xem tất cả</Button>
          </CardHeader>
          {loadingPayments ? (
            <div style={{ padding: '1.5rem', height: '200px' }}><Skeleton /></div>
          ) : errorPayments ? (
            <EmptyState icon={CreditCard} title="Không thể tải dữ liệu" description="Có lỗi xảy ra khi lấy danh sách đơn thanh toán." action={<Button variant="outline" onClick={() => refetchPayments()}>Thử lại</Button>} />
          ) : payments.length === 0 ? (
            <EmptyState icon={CreditCard} title="Chưa có đơn hàng" description="Hệ thống chưa ghi nhận đơn thanh toán nào." />
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Mã đơn</TableHead>
                  <TableHead>Mã ĐH Merchant</TableHead>
                  <TableHead>Số tiền</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead>Thời gian</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {payments.slice(0, 5).map(p => (
                  <TableRow key={p.id || p.order_id}>
                    <TableCell>
                      <span title={p.order_id || p.id} style={{ display: 'inline-block', maxWidth: '200px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', verticalAlign: 'bottom' }}>
                        {p.order_id || p.id || ' '}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span title={p.merchant_order_id} style={{ display: 'inline-block', maxWidth: '200px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', verticalAlign: 'bottom' }}>
                        {p.merchant_order_id || ' '}
                      </span>
                    </TableCell>
                    <TableCell style={{ fontWeight: 500 }}>{formatCurrency(p.amount)}</TableCell>
                    <TableCell><StatusBadge status={p.status} /></TableCell>
                    <TableCell>{p.created_at ? format(new Date(p.created_at), 'dd/MM/yy HH:mm') : ' '}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </Card>

        {/* Recent Transactions */}
        <Card>
          <CardHeader>
            <CardTitle>Biến động số dư mới nhất</CardTitle>
            <Button variant="ghost" size="sm" onClick={() => navigate('/merchant/transactions')}>Xem tất cả</Button>
          </CardHeader>
          {loadingTx ? (
            <div style={{ padding: '1.5rem', height: '200px' }}><Skeleton /></div>
          ) : errorTx ? (
            <EmptyState icon={ArrowLeftRight} title="Không thể tải dữ liệu" description="Có lỗi xảy ra khi lấy danh sách giao dịch." action={<Button variant="outline" onClick={() => refetchTx()}>Thử lại</Button>} />
          ) : transactions.length === 0 ? (
            <EmptyState icon={ArrowLeftRight} title="Chưa có giao dịch" description="Chưa có biến động số dư nào." />
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Mã GD</TableHead>
                  <TableHead>Mã lệnh TT</TableHead>
                  <TableHead>Loại</TableHead>
                  <TableHead>Số tiền</TableHead>
                  <TableHead>Thời gian</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {transactions.slice(0, 5).map(t => (
                  <TableRow key={t.id || t.transaction_id}>
                    <TableCell>
                      <span title={t.transaction_id || t.id} style={{ display: 'inline-block', maxWidth: '200px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', verticalAlign: 'bottom' }}>
                        {t.transaction_id || t.id || ' '}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span title={t.payment_no} style={{ display: 'inline-block', maxWidth: '200px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', verticalAlign: 'bottom' }}>
                        {t.payment_no || ' '}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span style={{ 
                        padding: '0.25rem 0.5rem', 
                        borderRadius: '12px', 
                        fontSize: '0.75rem', 
                        fontWeight: 500,
                        backgroundColor: t.transaction_type === 'REFUND' ? 'var(--status-failed-bg)' : 'var(--status-active-bg)',
                        color: t.transaction_type === 'REFUND' ? 'var(--status-failed)' : 'var(--status-active)'
                      }}>
                        {t.transaction_type === 'REFUND' ? 'Hoàn tiền' : 'Thanh toán'}
                      </span>
                    </TableCell>
                    <TableCell style={{ fontWeight: 500, color: 'var(--text-main)' }}>
                      {formatCurrency(Math.abs(t.amount))}
                    </TableCell>
                    <TableCell>{t.created_at ? format(new Date(t.created_at), 'dd/MM/yyyy HH:mm') : ' '}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </Card>

      </div>
    </PageContainer>
  );
};

export default Dashboard;

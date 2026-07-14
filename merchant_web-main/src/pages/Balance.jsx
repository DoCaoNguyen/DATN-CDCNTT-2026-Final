import { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card/Card';
import { KPICard } from '../components/ui/Card/KPICard';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '../components/ui/Table/Table';
import { Pagination } from '../components/ui/Pagination/Pagination';
import { Skeleton } from '../components/ui/Skeleton/Skeleton';
import { merchantApi } from '../api/merchantApi';
import { formatCurrency, formatDate } from '../utils/formatters';
import { Wallet, Lock, ArrowUpRight, ArrowDownRight } from 'lucide-react';
import PageContainer from '../components/layout/PageContainer';
import PageHeader from '../components/layout/PageHeader';
import KpiGrid from '../components/layout/KpiGrid';

export default function Balance() {
  const [balance, setBalance] = useState({ available_balance: 0, pending_balance: 0 });
  const [balanceLoading, setBalanceLoading] = useState(true);
  
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);
  const [totalPages, setTotalPages] = useState(1);

  const [totalItems, setTotalItems] = useState(0);

  const fetchBalance = async () => {
    try {
      const res = await merchantApi.getBalance();
      const b = res.data || res;
      setBalance({
        available_balance: b.available_balance || 0,
        pending_balance: b.pending_balance || 0
      });
    } catch (err) {
      console.error(err);
    } finally {
      setBalanceLoading(false);
    }
  };

  const fetchStatement = async () => {
    try {
      setLoading(true);
      setError('');
      const res = await merchantApi.getStatement({ page, limit });
      
      const responseData = res.data || res;
      const items = responseData.items || responseData.data?.items || responseData.rows || [];
      const pagination = responseData.pagination || responseData.data?.pagination || { total_pages: 1, total_items: 0 };
      
      setData(Array.isArray(items) ? items : []);
      setTotalPages(pagination.total_pages || 1);
      setTotalItems(pagination.total_items || items.length || 0);
    } catch (err) {
      console.error(err);
      setError('Lấy lịch sử sao kê thất bại');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBalance();
  }, []);

  useEffect(() => {
    fetchStatement();
  }, [page, limit]);

  const renderAmount = (amount, entryType) => {
    if (entryType === 'CREDIT') {
      return <span style={{ color: 'var(--status-active)', fontWeight: '600' }}>+{formatCurrency(amount)}</span>;
    }
    if (entryType === 'DEBIT') {
      return <span style={{ color: 'var(--status-failed)', fontWeight: '600' }}>-{formatCurrency(amount)}</span>;
    }
    return <span style={{ color: 'var(--text-main)', fontWeight: '600' }}>{formatCurrency(amount)}</span>;
  };

  // Client-side calculations for KPI
  const creditTotal = data.filter(i => i.entry_type === 'CREDIT').reduce((sum, i) => sum + (Number(i.amount) || 0), 0);
  const debitTotal = data.filter(i => i.entry_type === 'DEBIT').reduce((sum, i) => sum + (Number(i.amount) || 0), 0);

  return (
    <PageContainer>
      <PageHeader
        title="Số dư & Sao kê"
        description="Theo dõi số dư khả dụng, số dư tạm giữ và biến động số dư của merchant."
      />

      <KpiGrid>
        {balanceLoading ? <Skeleton style={{ height: '110px' }} /> : (
          <KPICard 
            title="Số dư khả dụng" 
            value={formatCurrency(balance.available_balance)} 
            icon={Wallet} 
            iconColor="var(--primary-color)" 
            iconBg="var(--primary-light)" 
          />
        )}
        
        {balanceLoading ? <Skeleton style={{ height: '110px' }} /> : (
          <KPICard 
            title="Số dư tạm giữ" 
            value={formatCurrency(balance.pending_balance)} 
            icon={Lock} 
            iconColor="var(--status-warning)" 
            iconBg="var(--status-warning-bg)" 
          />
        )}

        <KPICard 
          title="Tiền vào trên trang" 
          value={formatCurrency(creditTotal)} 
          subtitle="Dựa trên dữ liệu trang hiện tại"
          icon={ArrowDownRight} 
          iconColor="var(--status-active)" 
          iconBg="var(--status-active-bg)" 
        />
        
        <KPICard 
          title="Tiền ra trên trang" 
          value={formatCurrency(debitTotal)} 
          subtitle="Dựa trên dữ liệu trang hiện tại"
          icon={ArrowUpRight} 
          iconColor="var(--status-failed)" 
          iconBg="var(--status-failed-bg)" 
        />
      </KpiGrid>

      <Card>
        <CardHeader style={{ paddingBottom: '1rem' }}>
          <CardTitle>Lịch sử Sao kê (Statement)</CardTitle>
        </CardHeader>

        {error ? (
          <div style={{ padding: '24px', textAlign: 'center', color: 'var(--status-failed)' }}>
            {error}
          </div>
        ) : (
          <>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Mã GD</TableHead>
                  <TableHead>Loại</TableHead>
                  <TableHead>Số tiền (+/-)</TableHead>
                  <TableHead>Số dư trước</TableHead>
                  <TableHead>Số dư sau</TableHead>
                  <TableHead>Mô tả</TableHead>
                  <TableHead>Thời gian</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody isEmpty={!loading && data.length === 0} emptyProps={{ title: 'Không có dữ liệu sao kê', description: 'Chưa có biến động số dư nào được ghi nhận.' }}>
                {loading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <TableRow key={i}>
                      <TableCell><Skeleton width="90px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="60px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="80px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="80px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="80px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="120px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="130px" height="20px" /></TableCell>
                    </TableRow>
                  ))
                ) : (
                  data.map(item => (
                    <TableRow key={item.id}>
                      <TableCell>
                        <span title={item.ledger_transaction_id}>{item.ledger_transaction_id}</span>
                      </TableCell>
                      <TableCell>{item.entry_type}</TableCell>
                      <TableCell>{renderAmount(item.amount, item.entry_type)}</TableCell>
                      <TableCell>{formatCurrency(item.balance_before)}</TableCell>
                      <TableCell>{formatCurrency(item.balance_after)}</TableCell>
                      <TableCell>{item.description}</TableCell>
                      <TableCell>{formatDate(item.created_at)}</TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          
            <div style={{ padding: '16px 24px', borderTop: '1px solid var(--border-light)' }}>
              <Pagination 
                currentPage={page} 
                totalPages={totalPages} 
                onPageChange={setPage} 
                limit={limit}
                onLimitChange={(newLimit) => { setLimit(newLimit); setPage(1); }}
              />
            </div>
          </>
        )}
      </Card>
    </PageContainer>
  );
}

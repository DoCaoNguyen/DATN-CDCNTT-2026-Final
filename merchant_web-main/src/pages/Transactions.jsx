import { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card/Card';
import { KPICard } from '../components/ui/Card/KPICard';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '../components/ui/Table/Table';
import { Tabs } from '../components/ui/Tabs/Tabs';
import { Pagination } from '../components/ui/Pagination/Pagination';
import { SearchInput } from '../components/ui/Input/SearchInput';
import { StatusBadge } from '../components/ui/Badge/StatusBadge';
import { Skeleton } from '../components/ui/Skeleton/Skeleton';

import { Button } from '../components/ui/Button/Button';
import { toast } from 'sonner';
import { merchantApi } from '../api/merchantApi';
import { formatCurrency, formatDate } from '../utils/formatters';
import { ArrowLeftRight, CheckCircle, Clock, XCircle } from 'lucide-react';
import PageContainer from '../components/layout/PageContainer';
import PageHeader from '../components/layout/PageHeader';
import KpiGrid from '../components/layout/KpiGrid';

const TABS = [
  { label: 'Tất cả', value: '' },
  { label: 'Thành công', value: 'SUCCESS' },
  { label: 'Thất bại', value: 'FAILED' },
];

import { useNavigate } from 'react-router-dom';

export default function Transactions() {
  const navigate = useNavigate();
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [activeTab, setActiveTab] = useState('');

  const fetchTransactions = async () => {
    try {
      setLoading(true);
      setError('');
      const params = { page, limit };
      if (activeTab) params.status = activeTab;

      const res = await merchantApi.getTransactions(params);

      const responseData = res.data || res;
      const items = responseData.items || responseData.data?.items || responseData.rows || [];
      const pagination = responseData.pagination || responseData.data?.pagination || { total_pages: 1, total_items: 0 };

      setData(Array.isArray(items) ? items : []);
      setTotalPages(pagination.total_pages || 1);
      setTotalItems(pagination.total_items || items.length || 0);
    } catch (err) {
      console.error(err);
      setError('Lấy danh sách giao dịch thất bại');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTransactions();
  }, [page, limit, activeTab]);

  const handleTabChange = (val) => {
    setActiveTab(val);
    setPage(1);
  };

  const truncateId = (id) => {
    if (!id) return '';
    if (id.length <= 12) return id;
    return id.substring(0, 13) + '...';
  };

  const handleViewDetail = (id) => {
    navigate(`/merchant/transactions/${id}`);
  };

  // Client-side KPIs
  const successCount = data.filter(i => i.status === 'SUCCESS').length;
  const failedCount = data.filter(i => i.status === 'FAILED').length;
  const totalAmount = data.reduce((sum, i) => sum + (Number(i.amount) || 0), 0);

  return (
    <PageContainer>
      <PageHeader
        title="Giao dịch"
        description="Theo dõi dòng tiền ra vào ví merchant của bạn."
      />

      <KpiGrid>
        <KPICard
          title="Giao dịch trên trang"
          value={data.length}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={ArrowLeftRight}
          iconColor="var(--primary-color)"
          iconBg="var(--primary-light)"
        />
        <KPICard
          title="Thành công trên trang"
          value={successCount}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={CheckCircle}
          iconColor="var(--status-active)"
          iconBg="var(--status-active-bg)"
        />
        <KPICard
          title="Thất bại trên trang"
          value={failedCount}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={XCircle}
          iconColor="var(--status-failed)"
          iconBg="var(--status-failed-bg)"
        />
        <KPICard
          title="Tổng giá trị trên trang"
          value={formatCurrency(totalAmount)}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={ArrowLeftRight}
          iconColor="var(--status-warning)"
          iconBg="var(--status-warning-bg)"
        />
      </KpiGrid>

      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 24px', flexWrap: 'wrap', gap: '16px', borderBottom: '1px solid var(--border-light)' }}>
          <Tabs tabs={TABS} activeTab={activeTab} onChange={handleTabChange} />
          <div style={{ width: '300px' }} title="Backend hiện chưa hỗ trợ tìm kiếm cho Giao dịch">
            <SearchInput
              placeholder="Tính năng tìm kiếm sắp ra mắt..."
              value=""
              onChange={() => { }}
              disabled={true}
            />
          </div>
        </div>

        {error ? (
          <div style={{ padding: '24px', textAlign: 'center', color: 'var(--danger-color)' }}>
            {error}
          </div>
        ) : (
          <>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Mã GD</TableHead>
                  <TableHead>Mã lệnh TT</TableHead>
                  <TableHead>Số tiền</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead>Ngày tạo</TableHead>
                  <TableHead>Ngày TT</TableHead>
                  <TableHead align="right">Hành động</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody isEmpty={!loading && data.length === 0} emptyProps={{ title: 'Không có giao dịch nào', description: 'Chưa có dữ liệu giao dịch hiỒn thị.' }}>
                {loading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <TableRow key={i}>
                      <TableCell><Skeleton width="100px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="100px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="80px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="90px" height="24px" borderRadius="12px" /></TableCell>
                      <TableCell><Skeleton width="140px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="140px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="60px" height="30px" /></TableCell>
                    </TableRow>
                  ))
                ) : (
                  data.map(tx => (
                    <TableRow key={tx.id}>
                      <TableCell>
                        <span title={tx.id}>{tx.id}</span>
                      </TableCell>
                      <TableCell>
                        <span title={tx.payment_no}>{tx.payment_no}</span>
                      </TableCell>
                      <TableCell style={{ fontWeight: '500', color: 'var(--text-main)' }}>
                        {formatCurrency(tx.amount, tx.currency)}
                      </TableCell>
                      <TableCell>
                        <StatusBadge status={tx.status} />
                      </TableCell>
                      <TableCell>{formatDate(tx.created_at)}</TableCell>
                      <TableCell>{tx.paid_at ? formatDate(tx.paid_at) : '-'}</TableCell>
                      <TableCell align="right">
                        <Button size="sm" variant="ghost" onClick={() => handleViewDetail(tx.id)}>Chi tiết</Button>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>

            {!loading && (
              <div style={{ padding: '16px 24px', borderTop: '1px solid var(--border-light)' }}>
                <Pagination currentPage={page} totalPages={totalPages} limit={limit} totalItems={totalItems} onPageChange={setPage} onLimitChange={(newLimit) => { setLimit(newLimit); setPage(1); }} />
              </div>
            )}
          </>
        )}
      </Card>
    </PageContainer>
  );
}

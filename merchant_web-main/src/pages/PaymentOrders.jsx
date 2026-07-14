import { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card/Card';
import { KPICard } from '../components/ui/Card/KPICard';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell, ExpandableTableRow } from '../components/ui/Table/Table';
import { Tabs } from '../components/ui/Tabs/Tabs';
import { Pagination } from '../components/ui/Pagination/Pagination';
import { SearchInput } from '../components/ui/Input/SearchInput';
import { StatusBadge } from '../components/ui/Badge/StatusBadge';
import { Skeleton } from '../components/ui/Skeleton/Skeleton';

import { Button } from '../components/ui/Button/Button';
import { toast } from 'sonner';
import { merchantApi } from '../api/merchantApi';
import { formatCurrency, formatDate } from '../utils/formatters';
import { ShoppingCart, CheckCircle, Clock, XCircle, Copy, ExternalLink } from 'lucide-react';
import PageContainer from '../components/layout/PageContainer';
import PageHeader from '../components/layout/PageHeader';
import KpiGrid from '../components/layout/KpiGrid';

const TABS = [
  { label: 'Tất cả', value: '' },
  { label: 'Đang xử lý', value: 'PENDING' },
  { label: 'Thành công', value: 'SUCCESS' },
  { label: 'Thất bại', value: 'FAILED' },
  { label: 'Đã hủy', value: 'CANCELED' },
];

import { useNavigate } from 'react-router-dom';

export default function PaymentOrders() {
  const navigate = useNavigate();
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [activeTab, setActiveTab] = useState('');
  const [keyword, setKeyword] = useState('');

  const [expandedRowId, setExpandedRowId] = useState(null);

  const fetchOrders = async () => {
    try {
      setLoading(true);
      setError('');
      const params = { page, limit };
      if (activeTab) params.status = activeTab;
      if (keyword) params.keyword = keyword;

      const res = await merchantApi.getPaymentOrders(params);

      const responseData = res.data || res;
      const items = responseData.items || responseData.data?.items || responseData.rows || [];
      const pagination = responseData.pagination || responseData.data?.pagination || { total_pages: 1, total_items: 0 };

      const processedItems = (Array.isArray(items) ? items : []).map(order => {
        let currentStatus = order.status;
        const exp = order.expired_at || order.expires_at;
        if (currentStatus === 'PENDING' && exp && new Date(exp) < new Date()) {
          currentStatus = 'EXPIRED';
        }
        return { ...order, status: currentStatus };
      });

      setData(processedItems);
      setTotalPages(pagination.total_pages || 1);
      setTotalItems(pagination.total_items || items.length || 0);
    } catch (err) {
      console.error(err);
      setError('Lấy danh sách đơn hàng thất bại');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, [page, activeTab, keyword]);

  const handleTabChange = (val) => {
    setActiveTab(val);
    setPage(1);
    setExpandedRowId(null);
  };

  const handleSearch = (val) => {
    setKeyword(val);
    setPage(1);
    setExpandedRowId(null);
  };

  const toggleRow = (id) => {
    if (expandedRowId === id) setExpandedRowId(null);
    else setExpandedRowId(id);
  };

  const truncateId = (id) => {
    if (!id) return '';
    if (id.length <= 12) return id;
    return id.substring(0, 13) + '...';
  };

  const handleViewDetail = (id) => {
    navigate(`/merchant/payment-orders/${id}`);
  };

  const handleCopy = (text) => {
    navigator.clipboard.writeText(text);
    toast.success('Đã sao chép');
  };

  // Client-side KPIs
  const totalAmount = data.reduce((sum, item) => sum + (Number(item.amount) || 0), 0);
  const successCount = data.filter(i => i.status === 'SUCCESS').length;
  const pendingCount = data.filter(i => i.status === 'PENDING').length;
  const failedCount = data.filter(i => ['FAILED', 'CANCELED'].includes(i.status)).length;

  const renderExpandedContent = (order) => (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
      <Card style={{ boxShadow: 'var(--shadow-sm)', border: 'none' }}>
        <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
          <CardTitle style={{ fontSize: '0.875rem' }}>Thông tin thanh toán</CardTitle>
        </CardHeader>
        <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem', fontSize: '0.875rem' }}>
          <div className="flex justify-between">
            <span className="text-muted">Số tiền:</span>
            <span style={{ fontWeight: 600 }}>{formatCurrency(order.amount)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-muted">Trạng thái:</span>
            <StatusBadge status={order.status} />
          </div>
          <div className="flex justify-between">
            <span className="text-muted">Tạo lúc:</span>
            <span>{formatDate(order.created_at)}</span>
          </div>
          {order.expires_at && (
            <div className="flex justify-between">
              <span className="text-muted">Hết hạn:</span>
              <span>{formatDate(order.expires_at)}</span>
            </div>
          )}
        </CardContent>
      </Card>

      <Card style={{ boxShadow: 'var(--shadow-sm)', border: 'none' }}>
        <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
          <CardTitle style={{ fontSize: '0.875rem' }}>Đơn hàng & Mô tả</CardTitle>
        </CardHeader>
        <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem', fontSize: '0.875rem' }}>
          <div className="flex justify-between">
            <span className="text-muted">Mã Merchant:</span>
            <span>{order.merchant_order_id || '-'}</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
            <span className="text-muted">Mô tả:</span>
            <span style={{ backgroundColor: 'var(--bg-main)', padding: '0.5rem', borderRadius: 'var(--radius-sm)' }}>
              {order.description || '-'}
            </span>
          </div>
        </CardContent>
      </Card>

      <Card style={{ boxShadow: 'var(--shadow-sm)', border: 'none' }}>
        <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
          <CardTitle style={{ fontSize: '0.875rem' }}>Thao tác & Ghi chú</CardTitle>
        </CardHeader>
        <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          <Button variant="outline" size="sm" onClick={(e) => { e.stopPropagation(); handleViewDetail(order.id || order.payment_no) }} style={{ width: '100%', justifyContent: 'center' }}>
            Xem chi tiết <ExternalLink size={14} style={{ marginLeft: '0.5rem' }} />
          </Button>
          <Button variant="ghost" size="sm" onClick={(e) => { e.stopPropagation(); handleCopy(order.payment_no || order.id) }} style={{ width: '100%', justifyContent: 'center' }}>
            Copy mã lệnh <Copy size={14} style={{ marginLeft: '0.5rem' }} />
          </Button>
        </CardContent>
      </Card>
    </div>
  );

  return (
    <PageContainer>
      <PageHeader
        title="Đơn hàng"
        description="Quản lý các lệnh thanh toán được tạo bởi hệ thống của bạn."
      />

      <KpiGrid>
        <KPICard
          title="Đơn trên trang hiện tại"
          value={data.length}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={ShoppingCart}
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
          title="Đang xử lý trên trang"
          value={pendingCount}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={Clock}
          iconColor="var(--status-warning)"
          iconBg="var(--status-warning-bg)"
        />
        <KPICard
          title="Thất bại/Hủy trên trang"
          value={failedCount}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={XCircle}
          iconColor="var(--status-failed)"
          iconBg="var(--status-failed-bg)"
        />
      </KpiGrid>

      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 24px', flexWrap: 'wrap', gap: '16px', borderBottom: '1px solid var(--border-light)' }}>
          <Tabs tabs={TABS} activeTab={activeTab} onChange={handleTabChange} />
          <div style={{ width: '300px' }}>
            <SearchInput
              placeholder="Tìm theo Mã đơn (Order ID)"
              value={keyword}
              onChange={handleSearch}
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
                  <TableHead style={{ width: '40px', padding: '1rem' }}></TableHead>
                  <TableHead>Mã đơn</TableHead>
                  <TableHead>Mã ĐH Merchant</TableHead>
                  <TableHead>Số tiền</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead>Ngày tạo</TableHead>
                  <TableHead align="right">Hành động</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody isEmpty={!loading && data.length === 0} emptyProps={{ title: 'Không có đơn hàng nào', description: 'Chưa có lệnh thanh toán nào được ghi nhận.' }}>
                {loading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <TableRow key={i}>
                      <TableCell><Skeleton width="20px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="100px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="120px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="80px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="90px" height="24px" borderRadius="12px" /></TableCell>
                      <TableCell><Skeleton width="140px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="60px" height="32px" /></TableCell>
                    </TableRow>
                  ))
                ) : (
                  data.map(order => (
                    <ExpandableTableRow
                      key={order.id}
                      isExpanded={expandedRowId === order.id}
                      onToggle={() => toggleRow(order.id)}
                      colSpan={7}
                      expandedContent={renderExpandedContent(order)}
                    >
                      <TableCell>
                        <span title={order.payment_no || order.id}>{order.payment_no || order.id}</span>
                      </TableCell>
                      <TableCell>
                        <span title={order.merchant_order_id}>{order.merchant_order_id}</span>
                      </TableCell>
                      <TableCell style={{ fontWeight: 500 }}>{formatCurrency(order.amount)}</TableCell>
                      <TableCell><StatusBadge status={order.status} /></TableCell>
                      <TableCell>{formatDate(order.created_at)}</TableCell>
                      <TableCell style={{ textAlign: 'right' }}>
                        <Button variant="ghost" size="sm" onClick={(e) => { e.stopPropagation(); handleViewDetail(order.id || order.payment_no); }}>
                          Chi tiết
                        </Button>
                      </TableCell>
                    </ExpandableTableRow>
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

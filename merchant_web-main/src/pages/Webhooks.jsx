import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card/Card';
import { KPICard } from '../components/ui/Card/KPICard';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell, ExpandableTableRow } from '../components/ui/Table/Table';
import { Tabs } from '../components/ui/Tabs/Tabs';
import { Pagination } from '../components/ui/Pagination/Pagination';
import { SearchInput } from '../components/ui/Input/SearchInput';
import { StatusBadge } from '../components/ui/Badge/StatusBadge';
import { Skeleton } from '../components/ui/Skeleton/Skeleton';
import { Button } from '../components/ui/Button/Button';
import { ConfirmModal } from '../components/ui/Modal/ConfirmModal';
import { useNavigate } from 'react-router-dom';
import { merchantApi } from '../api/merchantApi';
import { formatDate } from '../utils/formatters';
import { Webhook, CheckCircle, Clock, XCircle, Copy, ExternalLink, RefreshCw } from 'lucide-react';
import PageContainer from '../components/layout/PageContainer';
import PageHeader from '../components/layout/PageHeader';
import KpiGrid from '../components/layout/KpiGrid';

const TABS = [
  { label: 'Tất cả', value: '' },
  { label: 'Thành công', value: 'SUCCESS' },
  { label: 'Đang xử lý', value: 'PENDING' },
  { label: 'Thất bại', value: 'FAILED' },
];

export default function Webhooks() {
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

  const [retryModalOpen, setRetryModalOpen] = useState(false);
  const [retryTarget, setRetryTarget] = useState(null);

  const fetchWebhooks = async () => {
    try {
      setLoading(true);
      setError('');
      const params = { page, limit };
      if (activeTab) params.status = activeTab;

      const res = await merchantApi.getWebhooks(params);

      const responseData = res.data || res;
      const items = responseData.items || responseData.data?.items || responseData.rows || [];
      const pagination = responseData.pagination || responseData.data?.pagination || { total_pages: 1, total_items: 0 };

      setData(Array.isArray(items) ? items : []);
      setTotalPages(pagination.total_pages || 1);
      setTotalItems(pagination.total_items || items.length || 0);
    } catch (err) {
      console.error(err);
      setError('Lấy danh sách webhook thất bại');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWebhooks();
  }, [page, limit, activeTab]);

  const handleTabChange = (val) => {
    setActiveTab(val);
    setPage(1);
    setExpandedRowId(null);
  };

  const handleViewDetail = (id) => {
    navigate('/merchant/webhooks/' + id);
  };

  const confirmRetry = (webhook) => {
    setRetryTarget(webhook);
    setRetryModalOpen(true);
  };

  const handleRetry = async () => {
    if (!retryTarget) return;
    try {
      await merchantApi.retryWebhook(retryTarget.id);
      toast.success('Đã xếp hàng chờ gửi lại webhook');
      setRetryModalOpen(false);
      fetchWebhooks();
    } catch (err) {
      toast.error('Gửi lại webhook thất bại');
    }
  };

  const handleCopy = (text) => {
    navigator.clipboard.writeText(text);
    toast.success('Đã sao chép');
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

  // Client-side KPIs
  const successCount = data.filter(i => i.status === 'SUCCESS').length;
  const pendingCount = data.filter(i => ['PENDING', 'RETRYING'].includes(i.status)).length;
  const failedCount = data.filter(i => i.status === 'FAILED').length;

  const renderJson = (obj) => {
    try {
      return JSON.stringify(obj, null, 2);
    } catch {
      return '';
    }
  };

  const renderExpandedContent = (item) => (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
      <Card style={{ boxShadow: 'var(--shadow-sm)', border: 'none' }}>
        <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
          <CardTitle style={{ fontSize: '0.875rem' }}>Thông tin sự kiện</CardTitle>
        </CardHeader>
        <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem', fontSize: '0.875rem' }}>
          <div className="flex justify-between">
            <span className="text-muted">Event Type:</span>
            <span style={{ fontWeight: 500 }}>{item.event_type}</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-muted">Trạng thái:</span>
            <StatusBadge status={item.status} />
          </div>
          <div className="flex justify-between">
            <span className="text-muted">Tạo lúc:</span>
            <span>{formatDate(item.created_at)}</span>
          </div>
          {item.updated_at && (
            <div className="flex justify-between">
              <span className="text-muted">Cập nhật:</span>
              <span>{formatDate(item.updated_at)}</span>
            </div>
          )}
        </CardContent>
      </Card>

      <Card style={{ boxShadow: 'var(--shadow-sm)', border: 'none' }}>
        <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
          <CardTitle style={{ fontSize: '0.875rem' }}>Lịch sử gửi</CardTitle>
        </CardHeader>
        <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem', fontSize: '0.875rem' }}>
          <div className="flex justify-between">
            <span className="text-muted">Lần gửi:</span>
            <span style={{ fontWeight: 500 }}>{item.attempt_count || 0}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-muted">Lần thử cuối:</span>
            <span>{item.last_attempt_at ? formatDate(item.last_attempt_at) : '-'}</span>
          </div>
          {item.last_error && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem', marginTop: '4px' }}>
              <span className="text-muted">Lỗi gần nhất:</span>
              <span style={{ backgroundColor: 'var(--status-failed-bg)', color: 'var(--status-failed)', padding: '0.5rem', borderRadius: 'var(--radius-sm)' }}>
                {item.last_error}
              </span>
            </div>
          )}
        </CardContent>
      </Card>

      <Card style={{ boxShadow: 'var(--shadow-sm)', border: 'none' }}>
        <CardHeader style={{ padding: '1rem', borderBottom: '1px solid var(--border-light)' }}>
          <CardTitle style={{ fontSize: '0.875rem' }}>Thao tác & Payload</CardTitle>
        </CardHeader>
        <CardContent style={{ padding: '1rem', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {item.payload && (
            <div style={{ background: '#1e293b', color: '#e2e8f0', padding: '0.5rem', overflow: 'hidden', height: '40px', fontSize: '0.75rem', borderRadius: 'var(--radius-sm)' }}>
              <pre style={{ margin: 0 }}>{renderJson(item.payload).substring(0, 50)}...</pre>
            </div>
          )}
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <Button variant="outline" size="sm" onClick={(e) => { e.stopPropagation(); handleViewDetail(item.id); }} style={{ flex: 1, justifyContent: 'center' }}>
              Chi tiết <ExternalLink size={14} style={{ marginLeft: '0.5rem' }} />
            </Button>
            <Button variant="ghost" size="sm" onClick={(e) => { e.stopPropagation(); handleCopy(renderJson(item.payload)); }} style={{ flex: 1, justifyContent: 'center' }}>
              Copy <Copy size={14} style={{ marginLeft: '0.5rem' }} />
            </Button>
          </div>
          {(item.status === 'FAILED' || item.can_retry === true) && (
            <Button variant="primary" size="sm" onClick={(e) => { e.stopPropagation(); confirmRetry(item); }} style={{ width: '100%', justifyContent: 'center' }}>
              Gửi lại webhook <RefreshCw size={14} style={{ marginLeft: '0.5rem' }} />
            </Button>
          )}
        </CardContent>
      </Card>
    </div>
  );

  return (
    <PageContainer>
      <PageHeader
        title="Webhooks"
        description="Quản lý lịch sử gửi webhook từ hệ thống đến endpoint của bạn."
      />

      <KpiGrid>
        <KPICard
          title="Webhook trên trang"
          value={data.length}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={Webhook}
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
          title="Đang chờ trên trang"
          value={pendingCount}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={Clock}
          iconColor="var(--status-warning)"
          iconBg="var(--status-warning-bg)"
        />
        <KPICard
          title="Thất bại trên trang"
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
          <div style={{ width: '300px' }} title="Tính năng tìm kiếm sắp ra mắt">
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
                  <TableHead style={{ width: '40px' }}></TableHead>
                  <TableHead>Event ID</TableHead>
                  <TableHead>Event Type</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead>Lần thử</TableHead>
                  <TableHead>Ngày tạo</TableHead>
                  <TableHead align="right">Hành động</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody isEmpty={!loading && data.length === 0} emptyProps={{ title: 'Không có webhook nào', description: 'Chưa có thông báo webhook nào được ghi nhận.' }}>
                {loading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <TableRow key={i}>
                      <TableCell><Skeleton width="20px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="100px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="120px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="90px" height="24px" borderRadius="12px" /></TableCell>
                      <TableCell><Skeleton width="40px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="140px" height="20px" /></TableCell>
                      <TableCell><Skeleton width="60px" height="20px" /></TableCell>
                    </TableRow>
                  ))
                ) : (
                  data.map(item => (
                    <ExpandableTableRow
                      key={item.id}
                      isExpanded={expandedRowId === item.id}
                      onToggle={() => toggleRow(item.id)}
                      colSpan={7}
                      expandedContent={renderExpandedContent(item)}
                    >
                      <TableCell>
                        <span title={item.id}>{item.id}</span>
                      </TableCell>
                      <TableCell>{item.event_type || ' '}</TableCell>
                      <TableCell>
                        <StatusBadge status={item.status} />
                      </TableCell>
                      <TableCell style={{ fontWeight: 500 }}>{item.attempt_count || 0}</TableCell>
                      <TableCell>{formatDate(item.created_at)}</TableCell>
                      <TableCell align="right">
                        <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end' }}>
                          <Button size="sm" variant="ghost" onClick={(e) => { e.stopPropagation(); handleViewDetail(item.id); }}>
                            Chi tiết
                          </Button>
                        </div>
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

      <ConfirmModal
        isOpen={retryModalOpen}
        onClose={() => setRetryModalOpen(false)}
        onConfirm={handleRetry}
        title="Gửi lại Webhook"
        message={`Bạn có chắc chắn muốn hệ thống gửi lại webhook cho sự kiện ${retryTarget?.event_type || 'này'} không?`}
        confirmText="Gửi lại"
        cancelText="Hủy"
        type="info"
      />
    </PageContainer>
  );
}

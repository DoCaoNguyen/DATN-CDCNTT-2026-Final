import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { format } from 'date-fns';
import { Key, Plus, RotateCw, Trash2, AlertTriangle, CheckCircle, ShieldAlert, Zap, XCircle } from 'lucide-react';
import { toast } from 'sonner';
import { merchantApi } from '../api/merchantApi';
import { Card } from '../components/ui/Card/Card';
import { KPICard } from '../components/ui/Card/KPICard';
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from '../components/ui/Table/Table';
import { StatusBadge } from '../components/ui/Badge/StatusBadge';
import { Button } from '../components/ui/Button/Button';
import { Skeleton } from '../components/ui/Skeleton/Skeleton';
import { EmptyState } from '../components/ui/EmptyState/EmptyState';
import { ConfirmModal } from '../components/ui/Modal/ConfirmModal';
import { SecretOnceModal } from '../components/ui/Modal/SecretOnceModal';
import { Modal } from '../components/ui/Modal/Modal';
import { CopyButton } from '../components/ui/CopyButton/CopyButton';
import { SearchInput } from '../components/ui/Input/SearchInput';
import { Pagination } from '../components/ui/Pagination/Pagination';
import PageContainer from '../components/layout/PageContainer';
import PageHeader from '../components/layout/PageHeader';
import KpiGrid from '../components/layout/KpiGrid';

const ApiKeys = () => {
  const queryClient = useQueryClient();

  // Modals state
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);

  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [createName, setCreateName] = useState('');

  const [confirmRotate, setConfirmRotate] = useState(null);
  const [confirmRevoke, setConfirmRevoke] = useState(null);

  const [secretModalData, setSecretModalData] = useState(null);

  // Queries
  const { data: keysData, isLoading, isError, refetch } = useQuery({
    queryKey: ['merchantApiKeys', page, limit],
    queryFn: () => merchantApi.getApiKeys({ page, limit }),
  });

  const keys = Array.isArray(keysData) ? keysData : (keysData?.data?.items || keysData?.items || keysData?.data || []);

  useEffect(() => {
    if (keysData?.pagination) {
      setTotalPages(keysData.pagination.total_pages || 1);
      setTotalItems(keysData.pagination.total_items || keys.length || 0);
    }
  }, [keysData, keys.length]);

  // Mutations
  const createMutation = useMutation({
    mutationFn: merchantApi.createApiKey,
    onSuccess: (data) => {
      const result = data?.data || data;
      const apiKey = result.api_key || result.key;
      const apiSecret = result.api_secret || result.raw_secret || result.secret;

      toast.success('Tạo API Key thành công');
      setIsCreateOpen(false);
      setCreateName('');
      queryClient.invalidateQueries({ queryKey: ['merchantApiKeys'] });

      if (apiSecret) {
        setSecretModalData({ apiKey, apiSecret, title: 'Tạo API Key thành công' });
      }
    },
    onError: (err) => {
      toast.error(err.response?.data?.message || err.message || 'Lỗi khi tạo API Key');
    }
  });

  const rotateMutation = useMutation({
    mutationFn: merchantApi.rotateSecret,
    onSuccess: (data, keyId) => {
      const result = data?.data || data;
      const apiSecret = result.api_secret || result.raw_secret || result.secret;
      const keyObj = keys.find(k => k.id === keyId);
      // Backend returns the newly rotated API Key in result.api_key
      const apiKey = result.api_key || keyObj?.api_key || 'Unknown';

      toast.success('Đổi secret thành công');
      setConfirmRotate(null);
      queryClient.invalidateQueries({ queryKey: ['merchantApiKeys'] });

      if (apiSecret) {
        setSecretModalData({ apiKey, apiSecret, title: 'Đổi Secret thành công' });
      }
    },
    onError: (err) => {
      toast.error(err.response?.data?.message || err.message || 'Lỗi khi đổi secret');
    }
  });

  const revokeMutation = useMutation({
    mutationFn: merchantApi.revokeKey,
    onSuccess: () => {
      toast.success('Đã thu hồi API Key');
      setConfirmRevoke(null);
      queryClient.invalidateQueries({ queryKey: ['merchantApiKeys'] });
    },
    onError: (err) => {
      toast.error(err.response?.data?.message || err.message || 'Lỗi khi thu hồi API Key');
    }
  });

  // Client-side KPIs
  const activeCount = keys.filter(k => k.status === 'ACTIVE').length;
  const sandboxCount = keys.filter(k => k.environment === 'SANDBOX').length;
  const revokedCount = keys.filter(k => k.status === 'REVOKED').length;

  return (
    <PageContainer>
      <PageHeader
        title="API Keys"
        description="Quản lý và cấp phát API Keys dùng để tích hợp hệ thống của bạn với cổng thanh toán."
        action={
          <Button variant="primary" onClick={() => setIsCreateOpen(true)}>
            <Plus size={16} style={{ marginRight: '0.5rem' }} /> Tạo API Key mới
          </Button>
        }
      />

      <KpiGrid>
        <KPICard
          title="Key trên trang"
          value={keys.length}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={Key}
          iconColor="var(--primary-color)"
          iconBg="var(--primary-light)"
        />
        <KPICard
          title="Hoạt động trên trang"
          value={activeCount}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={CheckCircle}
          iconColor="var(--status-active)"
          iconBg="var(--status-active-bg)"
        />
        <KPICard
          title="Thử nghiệm trên trang"
          value={sandboxCount}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={ShieldAlert}
          iconColor="var(--status-sandbox)"
          iconBg="var(--status-sandbox-bg)"
        />
        <KPICard
          title="Đã thu hồi trên trang"
          value={revokedCount}
          subtitle="Dữ liệu dựa trên trang hiện tại"
          icon={XCircle}
          iconColor="var(--status-failed)"
          iconBg="var(--status-failed-bg)"
        />
      </KpiGrid>

      <Card>
        <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', margin: '16px 24px', flexWrap: 'wrap', gap: '16px' }}>
          <div style={{ width: '300px' }} title="Tìm kiếm API Key (Client-side)">
            <SearchInput
              placeholder="Tính năng tìm kiếm sắp ra mắt..."
              value=""
              onChange={() => { }}
              disabled={true}
            />
          </div>
        </div>

        {isLoading ? (
          <div style={{ padding: '1.5rem', height: '250px' }}><Skeleton /></div>
        ) : isError ? (
          <EmptyState icon={AlertTriangle} title="Không thể tải dữ liệu" description="Đã xảy ra lỗi khi lấy danh sách API Keys." action={<Button variant="outline" onClick={() => refetch()}>Thử lại</Button>} />
        ) : keys.length === 0 ? (
          <EmptyState icon={Key} title="Chưa có API Key nào" description="Bạn chưa tạo API Key nào. Hãy tạo một Sandbox Key để bắt đầu tích hợp." action={<Button variant="primary" onClick={() => setIsCreateOpen(true)}>Tạo Sandbox Key</Button>} />
        ) : (
          <>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Tên Key</TableHead>
                  <TableHead>Môi trường</TableHead>
                  <TableHead>API Key</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead>Ngày tạo</TableHead>
                  <TableHead style={{ textAlign: 'right' }}>Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {keys.map(k => {
                  const isRevoked = k.status === 'REVOKED';
                  return (
                    <TableRow key={k.id}>
                      <TableCell style={{ fontWeight: 500 }}>{k.key_name || k.name || ' '}</TableCell>
                      <TableCell><StatusBadge status={k.environment || 'SANDBOX'} /></TableCell>
                      <TableCell>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <code style={{ backgroundColor: 'var(--bg-main)', padding: '0.25rem 0.5rem', borderRadius: '4px', fontSize: '0.75rem', color: 'var(--text-main)', border: '1px solid var(--border-light)' }}>
                            {k.api_key}
                          </code>
                          <CopyButton text={k.api_key} />
                        </div>
                      </TableCell>
                      <TableCell><StatusBadge status={k.status} /></TableCell>
                      <TableCell>{k.created_at ? format(new Date(k.created_at), 'dd/MM/yyyy') : ' '}</TableCell>
                      <TableCell style={{ textAlign: 'right' }}>
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem' }}>
                         <Button
                            variant="secondary"
                            size="sm"
                            disabled={isRevoked || rotateMutation.isPending}
                            onClick={() => setConfirmRotate(k.id)}
                            title="Đổi secret"
                          >
                            <RotateCw size={14} />
                          </Button>
                          <Button
                            variant="secondary"
                            size="sm"
                            disabled={isRevoked || rotateMutation.isPending}
                            onClick={() => setConfirmRotate(k.id)}
                            title="Đổi secret"
                          >
                            <RotateCw size={14} />
                          </Button>
                          <Button
                            variant="danger"
                            size="sm"
                            disabled={isRevoked || revokeMutation.isPending}
                            onClick={() => setConfirmRevoke(k.id)}
                            title="Thu hồi"
                          >
                            <Trash2 size={14} />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>

            {!isLoading && (
              <div style={{ padding: '16px 24px', borderTop: '1px solid var(--border-light)' }}>
                <Pagination currentPage={page} totalPages={totalPages} limit={limit} totalItems={totalItems} onPageChange={setPage} onLimitChange={(newLimit) => { setLimit(newLimit); setPage(1); }} />
              </div>
            )}
          </>
        )}
      </Card>

      {/* Modals */}
      <Modal isOpen={isCreateOpen} onClose={() => setIsCreateOpen(false)} title="Tạo API Key mới">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '1.5rem' }}>
          <div>
            <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-main)' }}>Tên gợi nhớ</label>
            <input
              type="text"
              placeholder="VD: App tích hợp Shopee"
              style={{ width: '100%', padding: '0.5rem 0.75rem', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-light)', outline: 'none' }}
              value={createName}
              onChange={e => setCreateName(e.target.value)}
              maxLength={100}
            />
            {createName.trim() && createName.trim().length < 3 && (
              <p style={{ color: 'var(--status-failed)', fontSize: '0.75rem', marginTop: '0.25rem' }}>
                Tên gợi nhớ phải từ 3 đến 100 ký tự.
              </p>
            )}
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500, color: 'var(--text-main)' }}>Môi trường</label>
            <input type="text" style={{ width: '100%', padding: '0.5rem 0.75rem', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-light)', backgroundColor: 'var(--bg-main)', color: 'var(--text-muted)' }} value="SANDBOX" disabled />
            <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '0.25rem' }}>Mặc định tạo key cho môi trường Sandbox.</p>
          </div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
          <Button variant="secondary" onClick={() => setIsCreateOpen(false)} disabled={createMutation.isPending}>Hủy</Button>
          <Button
            variant="primary"
            onClick={() => createMutation.mutate({ key_name: createName.trim(), environment: 'SANDBOX' })}
            isLoading={createMutation.isPending}
            disabled={!createName.trim() || createName.trim().length < 3}
          >
            Tạo Key
          </Button>
        </div>
      </Modal>

      <ConfirmModal
        isOpen={!!confirmRotate}
        onClose={() => setConfirmRotate(null)}
        onConfirm={() => rotateMutation.mutate(confirmRotate)}
        title="Đổi Secret Key"
        message="Bạn có chắc chắn muốn đổi Secret Key không? Secret Key cũ sẽ bị vô hiệu hóa ngay lập tức và các kết nối đang sử dụng nó sẽ bị gián đoạn."
        confirmText="Đổi Secret"
        cancelText="Hủy"
        type="warning"
        isLoading={rotateMutation.isPending}
      />

      <ConfirmModal
        isOpen={!!confirmRevoke}
        onClose={() => setConfirmRevoke(null)}
        onConfirm={() => revokeMutation.mutate(confirmRevoke)}
        title="Thu hồi API Key"
        message="Bạn có chắc chắn muốn thu hồi API Key này không? Hành động này không thể hoàn tác và các kết nối đang sử dụng key này sẽ bị từ chối."
        confirmText="Thu hồi"
        cancelText="Hủy"
        type="danger"
        isLoading={revokeMutation.isPending}
      />

      {secretModalData && (
        <SecretOnceModal
          isOpen={true}
          onClose={() => setSecretModalData(null)}
          apiKey={secretModalData.apiKey}
          apiSecret={secretModalData.apiSecret}
          title={secretModalData.title}
        />
      )}
    </PageContainer>
  );
};

export default ApiKeys;

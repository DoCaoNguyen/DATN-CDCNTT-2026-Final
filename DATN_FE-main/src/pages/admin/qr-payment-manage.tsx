import React, { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { useQrPayments, useExpireQrJob } from '../../features/payments/hooks/use-payment-orders';
import { AdminTable, PageShell, SearchBar, FilterSelect, StatCard, StatusBadge } from '../../components/ui/admin-components';
import type { ColumnDef } from '@tanstack/react-table';
import { Button } from '../../components/ui/button';
import { formatVND, formatDateTime } from '../../utils/formatters';
import { QrCode, Eye, Zap, CheckCircle, Clock, XCircle } from 'lucide-react';

// Kiểm tra quyền từ localStorage
const hasPermission = (perm: string): boolean => {
  try {
    const info = JSON.parse(localStorage.getItem('user_info') || '{}');
    return Array.isArray(info.permissions) && info.permissions.includes(perm);
  } catch { return false; }
};

const STATUS_OPTIONS = [
  { value: 'ACTIVE',   label: 'Hoạt động' },
  { value: 'USED',     label: 'Đã sử dụng' },
  { value: 'EXPIRED',  label: 'Hết hạn' },
  { value: 'CANCELED', label: 'Đã huỷ' },
];

export default function QrPaymentManage() {
  const { params, setQueryParams } = useApiQueryParams();
  const navigate = useNavigate();
  const { data, isLoading } = useQrPayments(params);
  const expireJob = useExpireQrJob();
  const [confirmExpire, setConfirmExpire] = useState(false);
  const canManage = hasPermission('admin.transactions.manage');

  const items      = data?.data?.items ?? data?.items ?? [];
  const total      = data?.data?.total ?? data?.total ?? 0;
  const totalPages = data?.data?.total_pages ?? data?.total_pages ?? 1;

  const active = items.filter((r: any) => (r.status || r.qr_status) === 'ACTIVE' && (!r.expired_at || new Date(r.expired_at) >= new Date())).length;
  const used = items.filter((r: any) => (r.status || r.qr_status) === 'USED').length;
  const expired = items.filter((r: any) => (r.status || r.qr_status) === 'EXPIRED' || ((r.status || r.qr_status) === 'ACTIVE' && r.expired_at && new Date(r.expired_at) < new Date())).length;
  const canceled = items.filter((r: any) => (r.status || r.qr_status) === 'CANCELED').length;

  const handleExpire = () => {
    expireJob.mutate(undefined, {
      onSuccess: () => setConfirmExpire(false),
    });
  };

  const columns = useMemo<ColumnDef<any>[]>(() => [
    {
      accessorKey: 'qr_token',
      header: 'QR Token',
      cell: ({ row }) => (
        <div>
          <p className="font-mono text-xs text-gray-800 font-medium">
            {(row.original.qr_token || '').slice(0, 28)}…
          </p>
          <p className="text-xs text-gray-400 mt-0.5">{formatDateTime(row.original.created_at)}</p>
        </div>
      ),
    },
    {
      accessorKey: 'payment_no',
      header: 'Mã đơn',
      cell: ({ row }) => (
        <div>
          <p className="font-mono text-xs text-gray-700">{row.original.payment_no}</p>
          <p className="text-xs text-gray-400">{row.original.merchant_name || '—'}</p>
        </div>
      ),
    },
    {
      accessorKey: 'amount',
      header: 'Số tiền',
      cell: ({ getValue }) => (
        <span className="font-semibold text-gray-900">{formatVND(getValue<number>())}</span>
      ),
    },
    {
      accessorKey: 'qr_status',
      header: 'Trạng thái',
      cell: ({ getValue, row }) => {
        let currentStatus = getValue<string>() || row.original.status;
        const expiredAt = row.original.expired_at;
        if (currentStatus === 'ACTIVE' && expiredAt && new Date(expiredAt) < new Date()) {
          currentStatus = 'EXPIRED';
        }
        return <StatusBadge status={currentStatus} />;
      },
    },
    {
      accessorKey: 'expired_at',
      header: 'Hết hạn',
      cell: ({ getValue }) => {
        const d = getValue<string>();
        const isOver = d && new Date(d) < new Date();
        return (
          <span className={`text-xs ${isOver ? 'text-red-500 font-medium' : 'text-gray-500'}`}>
            {formatDateTime(d)}
          </span>
        );
      },
    },
    {
      accessorKey: 'used_at',
      header: 'Dùng lúc',
      cell: ({ getValue }) => (
        <span className="text-xs text-gray-500">
          {getValue<string>() ? formatDateTime(getValue<string>()) : '—'}
        </span>
      ),
    },
    {
      id: 'actions',
      header: '',
      cell: ({ row }) => (
        <Button
          variant="ghost"
          onClick={() => navigate(`/admin/payments/qr/${row.original.id}`)}
          className="text-blue-600 hover:bg-blue-50"
        >
          <Eye className="w-3.5 h-3.5 mr-1.5" /> Chi tiết
        </Button>
      ),
    },
  ], [navigate]);

  return (
    <PageShell
      title="Thanh toán QR"
      description="Tra cứu và giám sát các mã QR thanh toán trong hệ thống."
      actions={
        canManage && (
          <Button
            variant="warning"
            onClick={() => setConfirmExpire(true)}
          >
            <Zap className="w-4 h-4 mr-2" /> Dọn dẹp QR hết hạn
          </Button>
        )
      }
    >
      {/* Stat cards */}
      <div className="grid grid-cols-1 sm:grid-cols-5 gap-4">
        <StatCard icon={<QrCode className="w-5 h-5 text-blue-600" />} iconBg="bg-blue-50" label="Tổng QR" value={total} />
        <StatCard icon={<CheckCircle className="w-5 h-5 text-green-600" />} iconBg="bg-green-50" label="Đang hoạt động" value={active} />
        <StatCard icon={<CheckCircle className="w-5 h-5 text-violet-600" />} iconBg="bg-violet-50" label="Đã sử dụng" value={used} />
        <StatCard icon={<XCircle className="w-5 h-5 text-gray-500" />} iconBg="bg-gray-100" label="Đã hủy" value={canceled} />
        <StatCard icon={<Clock className="w-5 h-5 text-gray-500" />} iconBg="bg-gray-100" label="Hết hạn" value={expired} />
      </div>

      {/* Toolbar */}
      <div className="flex items-center gap-2 flex-wrap">
        <SearchBar
          value={params.search}
          onChange={(v) => setQueryParams({ search: v, page: 1 })}
          placeholder="Tìm theo QR token, mã đơn..."
        />
        <FilterSelect
          value={params.status}
          onChange={(v) => setQueryParams({ status: v, page: 1 })}
          options={STATUS_OPTIONS}
          placeholder="Tất cả trạng thái"
        />
      </div>

      <AdminTable
        columns={columns}
        data={items}
        isLoading={isLoading}
        page={params.page}
        limit={params.limit}
        total={total}
        totalPages={totalPages}
        onPageChange={(p) => setQueryParams({ page: p })}
        onLimitChange={(l) => setQueryParams({ limit: l, page: 1 })}
      />

      {/* Confirm Expire Dialog */}
      {confirmExpire && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl shadow-xl p-6 max-w-sm w-full mx-4">
            <h3 className="text-base font-bold text-gray-900 mb-2">Xác nhận dọn dẹp QR</h3>
            <p className="text-sm text-gray-600 mb-5">
              Thao tác này sẽ expire toàn bộ mã QR <strong>ACTIVE</strong> đã quá thời hạn và
              cập nhật trạng thái đơn hàng PENDING liên quan. Không thể hoàn tác.
            </p>
            <div className="flex gap-3 justify-end">
              <Button variant="outline" onClick={() => setConfirmExpire(false)}>
                Huỷ
              </Button>
              <Button variant="warning" onClick={handleExpire} disabled={expireJob.isPending}>
                {expireJob.isPending ? 'Đang xử lý...' : 'Xác nhận'}
              </Button>
            </div>
          </div>
        </div>
      )}
    </PageShell>
  );
}

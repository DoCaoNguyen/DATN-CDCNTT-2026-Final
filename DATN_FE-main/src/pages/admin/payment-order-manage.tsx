import React, { useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { usePaymentOrders } from '../../features/payments/hooks/use-payment-orders';
import { AdminTable, PageShell, SearchBar, FilterSelect, StatCard, StatusBadge } from '../../components/ui/admin-components';
import type { ColumnDef } from '@tanstack/react-table';
import { Button } from '../../components/ui/button';
import { formatVND, formatDateTime } from '../../utils/formatters';
import { Eye, ShoppingCart, Clock, CheckCircle, XCircle } from 'lucide-react';

const STATUS_OPTIONS = [
  { value: 'PENDING', label: 'Đang chờ' },
  { value: 'PAID', label: 'Đã thanh toán' },
  { value: 'FAILED', label: 'Thất bại' },
  { value: 'EXPIRED', label: 'Hết hạn' },
  { value: 'CANCELED', label: 'Đã huỷ' },
];

export default function PaymentOrderManage() {
  const { params, setQueryParams } = useApiQueryParams();
  const navigate = useNavigate();
  const { data, isLoading } = usePaymentOrders(params);

  const items = data?.data?.items ?? data?.items ?? [];
  const total = data?.data?.total ?? data?.total ?? 0;
  const totalPages = data?.data?.total_pages ?? data?.total_pages ?? 1;

  // Stat cards
  const pending = items.filter((r: any) => r.status === 'PENDING' && (!r.expired_at || new Date(r.expired_at) >= new Date())).length;
  const paid = items.filter((r: any) => r.status === 'PAID').length;
  const canceled = items.filter((r: any) => r.status === 'CANCELED').length;
  const expired = items.filter((r: any) => r.status === 'EXPIRED' || (r.status === 'PENDING' && r.expired_at && new Date(r.expired_at) < new Date())).length;
  const paidAmt = items
    .filter((r: any) => r.status === 'PAID')
    .reduce((s: number, r: any) => s + Number(r.amount || 0), 0);

  const columns = useMemo<ColumnDef<any>[]>(() => [
    {
      accessorKey: 'payment_no',
      header: 'Mã thanh toán',
      cell: ({ row }) => (
        <div>
          <p className="font-semibold text-gray-800 font-mono text-xs">{row.original.payment_no}</p>
          <p className="text-xs text-gray-400 mt-0.5">{formatDateTime(row.original.created_at)}</p>
        </div>
      ),
    },
    {
      accessorKey: 'merchant_name',
      header: 'Merchant',
      cell: ({ getValue }) => <span className="text-gray-700">{getValue<string>() || '—'}</span>,
    },
    {
      accessorKey: 'amount',
      header: 'Số tiền',
      cell: ({ getValue }) => (
        <span className="font-semibold text-gray-900">{formatVND(getValue<number>())}</span>
      ),
    },
    {
      accessorKey: 'payment_method',
      header: 'Phương thức',
      cell: () => <span className="text-gray-700">QR_CODE</span>,
    },
    {
      accessorKey: 'status',
      header: 'Trạng thái',
      cell: ({ getValue, row }) => {
        let currentStatus = getValue<string>();
        const expiredAt = row.original.expired_at;
        if (currentStatus === 'PENDING' && expiredAt && new Date(expiredAt) < new Date()) {
          currentStatus = 'EXPIRED';
        }
        return <StatusBadge status={currentStatus} />;
      },
    },
    {
      accessorKey: 'expired_at',
      header: 'Hết hạn',
      cell: ({ getValue }) => (
        <span className="text-xs text-gray-500">{formatDateTime(getValue<string>())}</span>
      ),
    },
    {
      accessorKey: 'callback_url',
      header: 'Webhook',
      cell: ({ row }) => (
        row.original.callback_url ? <span className="text-xs px-2 py-1 bg-purple-100 text-purple-700 rounded font-semibold">Có</span> : <span className="text-gray-400 text-xs">—</span>
      ),
    },
    {
      id: 'actions',
      header: '',
      cell: ({ row }) => (
        <Button
          variant="ghost"
          onClick={() => navigate(`/admin/payments/payment-orders/${row.original.id}`)}
          className="text-blue-600 hover:bg-blue-50"
        >
          <Eye className="w-3.5 h-3.5 mr-1.5" /> Chi tiết
        </Button>
      ),
    },
  ], [navigate]);

  return (
    <PageShell title="Đơn thanh toán Merchant" description="Quản lý và theo dõi các đơn hàng thanh toán từ Merchant.">
      {/* Stat cards */}
      <div className="grid grid-cols-1 sm:grid-cols-5 gap-4">
        <StatCard icon={<ShoppingCart className="w-5 h-5 text-blue-600" />} iconBg="bg-blue-50" label="Tổng đơn" value={total} />
        <StatCard icon={<Clock className="w-5 h-5 text-amber-500" />} iconBg="bg-amber-50" label="Đang chờ" value={pending} />
        <StatCard icon={<CheckCircle className="w-5 h-5 text-green-600" />} iconBg="bg-green-50" label="Đã thanh toán" value={paid} sub={formatVND(paidAmt)} />
        <StatCard icon={<XCircle className="w-5 h-5 text-gray-500" />} iconBg="bg-gray-100" label="Đã hủy" value={canceled} />
        <StatCard icon={<Clock className="w-5 h-5 text-gray-500" />} iconBg="bg-gray-100" label="Hết hạn" value={expired} />
      </div>

      {/* Toolbar */}
      <div className="flex items-center gap-2 flex-wrap">
        <SearchBar
          value={params.search}
          onChange={(v) => setQueryParams({ search: v, page: 1 })}
          placeholder="Tìm theo mã thanh toán..."
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
    </PageShell>
  );
}

import React, { useMemo } from 'react';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { useRefunds } from '../../features/payments/hooks/use-refunds';
import { AdminTable, PageShell, SearchBar, FilterSelect, StatCard, StatusBadge } from '../../components/ui/admin-components';
import type { ColumnDef } from '@tanstack/react-table';
import { formatVND, formatDateTime } from '../../utils/formatters';
import { RotateCcw, CheckCircle, Clock } from 'lucide-react';

const STATUS_OPTIONS = [
  { value: 'PENDING',   label: 'Đang chờ' },
  { value: 'COMPLETED', label: 'Hoàn thành' },
  { value: 'REFUNDED',  label: 'Đã hoàn' },
  { value: 'FAILED',    label: 'Thất bại' },
  { value: 'CANCELED',  label: 'Đã huỷ' },
];

export default function RefundManage() {
  const { params, setQueryParams } = useApiQueryParams();
  const { data, isLoading } = useRefunds(params);

  const items      = data?.data?.items ?? data?.items ?? [];
  const total      = data?.data?.total ?? data?.total ?? 0;
  const totalPages = data?.data?.total_pages ?? data?.total_pages ?? 1;

  const pending    = items.filter((r: any) => r.status === 'PENDING').length;
  const refunded   = items.filter((r: any) => r.status === 'REFUNDED' || r.status === 'COMPLETED').length;
  const totalAmt   = items.reduce((s: number, r: any) => s + Number(r.amount || 0), 0);

  const columns = useMemo<ColumnDef<any>[]>(() => [
    {
      accessorKey: 'refund_no',
      header: 'Mã hoàn tiền',
      cell: ({ row }) => (
        <div>
          <p className="font-semibold text-gray-800 font-mono text-xs">{row.original.refund_no}</p>
          <p className="text-xs text-gray-400 mt-0.5">{formatDateTime(row.original.created_at)}</p>
        </div>
      ),
    },
    {
      accessorKey: 'payment_no',
      header: 'Mã đơn gốc',
      cell: ({ getValue }) => (
        <span className="font-mono text-xs text-gray-600">{getValue<string>()}</span>
      ),
    },
    {
      accessorKey: 'merchant_name',
      header: 'Merchant',
      cell: ({ getValue }) => <span className="text-gray-700">{getValue<string>() || '—'}</span>,
    },
    {
      accessorKey: 'amount',
      header: 'Số tiền hoàn',
      cell: ({ getValue }) => (
        <span className="font-semibold text-purple-700">{formatVND(getValue<number>())}</span>
      ),
    },
    {
      accessorKey: 'status',
      header: 'Trạng thái',
      cell: ({ getValue }) => <StatusBadge status={getValue<string>()} />,
    },
    {
      accessorKey: 'reason',
      header: 'Lý do',
      cell: ({ getValue }) => (
        <span className="text-xs text-gray-500 max-w-[160px] block truncate">{getValue<string>() || '—'}</span>
      ),
    },
  ], []);

  return (
    <PageShell title="Quản lý hoàn tiền" description="Theo dõi và xem các yêu cầu hoàn tiền trong hệ thống.">
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard icon={<RotateCcw className="w-5 h-5 text-purple-600" />} iconBg="bg-purple-50" label="Tổng yêu cầu" value={total} />
        <StatCard icon={<Clock className="w-5 h-5 text-amber-500" />} iconBg="bg-amber-50" label="Chờ xử lý" value={pending} />
        <StatCard icon={<CheckCircle className="w-5 h-5 text-green-600" />} iconBg="bg-green-50" label="Đã hoàn" value={refunded} sub={formatVND(totalAmt)} />
      </div>

      <div className="flex items-center gap-2 flex-wrap">
        <SearchBar
          value={params.search}
          onChange={(v) => setQueryParams({ search: v, page: 1 })}
          placeholder="Tìm theo mã hoàn tiền..."
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

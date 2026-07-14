import React, { useMemo } from 'react';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { useLedgerTransactions } from '../../features/transactions/hooks/use-ledger';
import { AdminTable, PageShell, SearchBar, FilterSelect, StatCard, StatusBadge } from '../../components/ui/admin-components';
import type { ColumnDef } from '@tanstack/react-table';
import { formatVND, formatDateTime } from '../../utils/formatters';
import { BookOpen, CheckCircle, XCircle } from 'lucide-react';
import { Link } from 'react-router-dom';

const TRANSACTION_TYPE_MAP: Record<string, string> = {
  TOPUP: 'Nạp tiền',
  TRANSFER: 'Chuyển tiền',
  PAYMENT: 'Thanh toán',
  REFUND: 'Hoàn tiền',
  WITHDRAW: 'Rút tiền',
  WITHDRAWAL: 'Rút tiền',
  DEPOSIT: 'Nạp tiền',
  ADJUSTMENT: 'Điều chỉnh',
  BANK_TRANSFER: 'Chuyển khoản NH'
};

const SOURCE_TYPE_MAP: Record<string, string> = {
  SYSTEM: 'Hệ thống',
  USER: 'Người dùng',
  MERCHANT: 'Doanh nghiệp',
  ADMIN: 'Quản trị viên',
  PAYMENT: 'Đơn thanh toán',
  WITHDRAWAL: 'Đơn rút tiền',
  DEPOSIT: 'Đơn nạp tiền',
  TOPUP_TRANSACTION: 'GD Nạp tiền',
  PAYMENT_TRANSACTION: 'GD Thanh toán',
  TRANSFER_TRANSACTION: 'GD Chuyển tiền',
  REFUND_TRANSACTION: 'GD Hoàn tiền',
  WITHDRAWAL_TRANSACTION: 'GD Rút tiền',
  DEPOSIT_TRANSACTION: 'GD Nạp tiền',
  TRANSFER: 'Chuyển tiền',
  WALLET_TRANSFER: 'Chuyển tiền nội bộ'
};

const TRANSACTION_TYPE_OPTIONS = [
  { value: 'TOPUP', label: 'Nạp tiền (Topup)' },
  { value: 'DEPOSIT', label: 'Nạp tiền (Deposit)' },
  { value: 'TRANSFER', label: 'Chuyển tiền' },
  { value: 'PAYMENT', label: 'Thanh toán' },
  { value: 'REFUND', label: 'Hoàn tiền' },
  { value: 'WITHDRAWAL', label: 'Rút tiền' },
  { value: 'BANK_TRANSFER', label: 'Chuyển khoản NH' }
];

export default function LedgerManage() {
  const { params, setQueryParams } = useApiQueryParams();
  const { data, isLoading } = useLedgerTransactions(params);

  const items = data?.data?.items ?? data?.items ?? data?.rows ?? data ?? [];
  const total = data?.data?.pagination?.total ?? data?.pagination?.total ?? data?.total ?? 0;
  const totalPages = data?.data?.pagination?.total_pages ?? data?.pagination?.total_pages ?? data?.total_pages ?? Math.ceil(total / (params.limit || 10));

  const successCount = items.filter((r: any) => r.status === 'SUCCESS' || r.status === 'COMPLETED').length;
  const failedCount = items.filter((r: any) => r.status === 'FAILED' || r.status === 'ERROR').length;

  const columns = useMemo<ColumnDef<any>[]>(() => [
    {
      accessorKey: 'transaction_no',
      header: 'Mã GD / Thời gian',
      cell: ({ row }) => (
        <div>
          <p className="font-mono text-xs font-medium text-slate-800">
            {row.original.transaction_no || row.original.id}
          </p>
          <p className="text-xs text-gray-400 mt-0.5">{formatDateTime(row.original.created_at)}</p>
        </div>
      ),
    },
    {
      accessorKey: 'transaction_type',
      header: 'Loại nghiệp vụ',
      cell: ({ getValue }) => <span className="font-medium text-slate-700">{TRANSACTION_TYPE_MAP[getValue<string>()] || getValue<string>() || '—'}</span>,
    },
    {
      accessorKey: 'source',
      header: 'Nguồn phát sinh',
      cell: ({ row }) => (
        <div>
          <span className="text-sm font-medium text-slate-700 block">{SOURCE_TYPE_MAP[row.original.source_type] || row.original.source_type || '—'}</span>
          {row.original.source_id && (
            <span className="text-xs text-slate-500 font-mono truncate max-w-[120px] block">{row.original.source_id.slice(0, 8)}…</span>
          )}
        </div>
      )
    },
    {
      id: 'subject',
      header: 'Đối tượng',
      cell: () => <span className="text-xs text-slate-500">Nhiều đối tượng</span>,
    },
    {
      accessorKey: 'amount',
      header: 'Tổng tiền',
      cell: ({ row }) => {
        const amt = row.original.amount ?? row.original.total_amount ?? 0;
        return <span className="font-semibold text-slate-800">{formatVND(amt)}</span>;
      },
    },
    {
      id: 'entries_count',
      header: 'Bút toán',
      cell: ({ row }) => (
        <span className="text-xs font-medium text-slate-600 bg-slate-100 px-2 py-0.5 rounded">
          {row.original.entries_count || 0} bút toán
        </span>
      ),
    },
    {
      accessorKey: 'status',
      header: 'Trạng thái',
      cell: ({ getValue }) => <StatusBadge status={getValue<string>()} />,
    },
    {
      id: 'actions',
      header: '',
      cell: ({ row }) => (
        <Link to={`/admin/ledger/${row.original.id}`} className="text-blue-600 hover:text-blue-800 text-sm font-medium hover:underline">
          Chi tiết
        </Link>
      ),
    },
  ], []);

  return (
    <PageShell title="Sổ cái giao dịch" description="Tra cứu toàn bộ bút toán Debit/Credit và biến động số dư trong hệ thống.">
      {/* Stat cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard icon={<BookOpen className="w-5 h-5 text-blue-600" />} iconBg="bg-blue-50" label="Tổng nghiệp vụ" value={total} />
        <StatCard icon={<CheckCircle className="w-5 h-5 text-green-500" />} iconBg="bg-green-50" label="Thành công (trang này)" value={successCount} />
        <StatCard icon={<XCircle className="w-5 h-5 text-red-600" />} iconBg="bg-red-50" label="Thất bại (trang này)" value={failedCount} />
      </div>

      {/* Toolbar */}
      <div className="flex items-center gap-2 flex-wrap">
        <SearchBar
          value={params.search}
          onChange={(v) => setQueryParams({ search: v, page: 1 })}
          placeholder="Tìm theo mã GD..."
        />
        <FilterSelect
          value={params.type}
          onChange={(v) => setQueryParams({ type: v, page: 1 })}
          options={TRANSACTION_TYPE_OPTIONS}
          placeholder="Tất cả Loại GD"
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

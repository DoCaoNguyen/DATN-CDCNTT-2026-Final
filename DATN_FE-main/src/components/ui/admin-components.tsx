/**
 * Bộ shared UI components dùng chung — flat design, clean, professional.
 * Gồm: AdminTable, AdminPagination, StatusBadge, StatCard, PageShell, SearchBar
 */
import React, { useState } from 'react';
import type { ColumnDef, ExpandedState } from '@tanstack/react-table';
import {
  flexRender,
  getCoreRowModel,
  getExpandedRowModel,
  useReactTable,
} from '@tanstack/react-table';
import { ChevronLeft, ChevronRight, InboxIcon } from 'lucide-react';

// ─── Pagination chuẩn ─────────────────────────────────────────────────────────
interface AdminPaginationProps {
  page: number;        // 1-indexed
  totalPages: number;
  total: number;
  limit: number;
  onPageChange: (page: number) => void;
  onLimitChange: (limit: number) => void;
}

export function AdminPagination({
  page,
  totalPages,
  total,
  limit,
  onPageChange,
  onLimitChange,
}: AdminPaginationProps) {
  const getPageNumbers = (): (number | '...')[] => {
    if (totalPages <= 7) return Array.from({ length: totalPages }, (_, i) => i + 1);
    const pages: (number | '...')[] = [1];
    if (page > 3) pages.push('...');
    for (let i = Math.max(2, page - 1); i <= Math.min(totalPages - 1, page + 1); i++) {
      pages.push(i);
    }
    if (page < totalPages - 2) pages.push('...');
    pages.push(totalPages);
    return pages;
  };

  return (
    <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200 bg-white text-sm text-gray-600">
      <div className="flex items-center gap-2">
        <span>Trang</span>
        <span className="font-semibold text-gray-800">{page}</span>
        <span className="text-gray-400">|</span>
        <span>Số dòng trên mỗi trang</span>
        <select
          value={limit}
          onChange={(e) => { onLimitChange(Number(e.target.value)); onPageChange(1); }}
          className="border border-gray-300 rounded px-2 py-0.5 text-sm focus:outline-none focus:ring-1 focus:ring-blue-400"
        >
          {[10, 20, 50].map((v) => <option key={v} value={v}>{v}</option>)}
        </select>
        <span className="text-gray-400 text-xs">({total} bản ghi)</span>
      </div>
      <div className="flex items-center gap-1">
        <button
          onClick={() => onPageChange(page - 1)}
          disabled={page <= 1}
          className="flex items-center gap-1 px-2 py-1 rounded hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          <ChevronLeft className="w-4 h-4" />
          <span>Trước</span>
        </button>
        {getPageNumbers().map((p, idx) =>
          p === '...' ? (
            <span key={`dots-${idx}`} className="px-2 py-1 text-gray-400">...</span>
          ) : (
            <button
              key={p}
              onClick={() => onPageChange(p as number)}
              className={`w-8 h-8 rounded text-sm font-medium transition-colors ${
                p === page ? 'bg-blue-600 text-white' : 'hover:bg-gray-100 text-gray-700'
              }`}
            >
              {p}
            </button>
          )
        )}
        <button
          onClick={() => onPageChange(page + 1)}
          disabled={page >= totalPages}
          className="flex items-center gap-1 px-2 py-1 rounded hover:bg-gray-100 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          <span>Sau</span>
          <ChevronRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}

// ─── Status Badge ──────────────────────────────────────────────────────────────
const STATUS_MAP: Record<string, { label: string; className: string }> = {
  PENDING:        { label: 'Đang chờ',       className: 'bg-amber-50 text-amber-700 border border-amber-200' },
  PROCESSING:     { label: 'Đang xử lý',     className: 'bg-blue-50 text-blue-700 border border-blue-200' },
  COMPLETED:      { label: 'Hoàn thành',     className: 'bg-green-50 text-green-700 border border-green-200' },
  SUCCESS:        { label: 'Thành công',     className: 'bg-green-50 text-green-700 border border-green-200' },
  PAID:           { label: 'Đã thanh toán',  className: 'bg-green-50 text-green-700 border border-green-200' },
  FAILED:         { label: 'Thất bại',       className: 'bg-red-50 text-red-700 border border-red-200' },
  EXPIRED:        { label: 'Hết hạn',        className: 'bg-amber-50 text-amber-700 border border-amber-200' },
  CANCELED:       { label: 'Đã huỷ',         className: 'bg-slate-100 text-slate-700 border border-slate-300' },
  REFUNDED:       { label: 'Đã hoàn tiền',   className: 'bg-purple-50 text-purple-700 border border-purple-200' },
  REVERSED:       { label: 'Đã đảo chiều',   className: 'bg-purple-50 text-purple-700 border border-purple-200' },
  ACTIVE:         { label: 'Hoạt động',      className: 'bg-green-50 text-green-700 border border-green-200' },
  USED:           { label: 'Đã sử dụng',     className: 'bg-violet-50 text-violet-700 border border-violet-200' },
  RETRYING:       { label: 'Đang retry',     className: 'bg-orange-50 text-orange-700 border border-orange-200' },
  VERIFIED:       { label: 'Đã xác minh',   className: 'bg-green-50 text-green-700 border border-green-200' },
  PENDING_VERIFY: { label: 'Chờ xác minh',   className: 'bg-amber-50 text-amber-700 border border-amber-200' },
  REJECTED:       { label: 'Từ chối',        className: 'bg-red-50 text-red-700 border border-red-200' },
  LOCKED:         { label: 'Bị khoá',        className: 'bg-red-50 text-red-700 border border-red-200' },
  BLOCKED:        { label: 'Bị chặn',        className: 'bg-red-50 text-red-700 border border-red-200' },
  INACTIVE:       { label: 'Không hoạt động', className: 'bg-gray-100 text-gray-500 border border-gray-200' },
  DEBIT:          { label: 'Ghi nợ',         className: 'bg-red-50 text-red-700 border border-red-200' },
  CREDIT:         { label: 'Ghi có',         className: 'bg-green-50 text-green-700 border border-green-200' },
};

export function StatusBadge({ status }: { status: string }) {
  const key = status?.toUpperCase() || '';
  const cfg = STATUS_MAP[key] ?? { label: key || 'N/A', className: 'bg-gray-100 text-gray-600 border border-gray-200' };
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium whitespace-nowrap ${cfg.className}`}>
      {cfg.label}
    </span>
  );
}

// ─── Stat Card ─────────────────────────────────────────────────────────────────
interface StatCardProps {
  icon: React.ReactNode;
  iconBg?: string;
  label: string;
  value: string | number;
  sub?: string;
}

export function StatCard({ icon, iconBg = 'bg-blue-50', label, value, sub }: StatCardProps) {
  return (
    <div className="bg-white border border-gray-200 rounded-lg p-4 flex items-center gap-4">
      <div className={`p-2.5 rounded-lg shrink-0 ${iconBg}`}>{icon}</div>
      <div className="min-w-0">
        <p className="text-xs text-gray-500 mb-0.5">{label}</p>
        <p className="text-lg font-bold text-gray-900 truncate">{value}</p>
        {sub && <p className="text-xs text-gray-400 mt-0.5">{sub}</p>}
      </div>
    </div>
  );
}

// ─── AdminTable ────────────────────────────────────────────────────────────────
interface AdminTableProps<TData> {
  columns: ColumnDef<TData, any>[];
  data: TData[];
  isLoading?: boolean;
  page?: number;
  limit?: number;
  total?: number;
  totalPages?: number;
  onPageChange?: (page: number) => void;
  onLimitChange?: (limit: number) => void;
  renderExpandedRow?: (row: TData) => React.ReactNode;
  getRowClassName?: (row: TData) => string;
  emptyIcon?: React.ReactNode;
  emptyText?: string;
}

export function AdminTable<TData>({
  columns, data, isLoading,
  page, limit, total, totalPages,
  onPageChange, onLimitChange,
  renderExpandedRow, getRowClassName,
  emptyIcon, emptyText,
}: AdminTableProps<TData>) {
  const [expanded, setExpanded] = useState<ExpandedState>({});
  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getExpandedRowModel: getExpandedRowModel(),
    onExpandedChange: setExpanded,
    manualPagination: true,
    state: { expanded },
  });

  const showPagination =
    page !== undefined && limit !== undefined &&
    total !== undefined && totalPages !== undefined &&
    onPageChange && onLimitChange;

  return (
    <div className="bg-white border border-gray-200 rounded-lg overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead>
            {table.getHeaderGroups().map((hg) => (
              <tr key={hg.id} className="border-b border-gray-200 bg-gray-50">
                {hg.headers.map((h) => (
                  <th key={h.id} className="px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap">
                    {h.isPlaceholder ? null : flexRender(h.column.columnDef.header, h.getContext())}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody className="divide-y divide-gray-100">
            {isLoading
              ? Array.from({ length: 7 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    {columns.map((_, j) => (
                      <td key={j} className="px-4 py-3.5">
                        <div className="h-4 bg-gray-100 rounded w-3/4" />
                      </td>
                    ))}
                  </tr>
                ))
              : table.getRowModel().rows.length === 0
              ? (
                <tr>
                  <td colSpan={columns.length} className="py-16 text-center">
                    {emptyIcon ?? <InboxIcon className="w-8 h-8 text-gray-300 mx-auto mb-2" />}
                    <p className="text-gray-400 text-sm mt-2">{emptyText ?? 'Không tìm thấy dữ liệu'}</p>
                  </td>
                </tr>
              )
              : table.getRowModel().rows.map((row) => (
                  <React.Fragment key={row.id}>
                    <tr className={`hover:bg-gray-50 transition-colors ${getRowClassName ? getRowClassName(row.original) : ''}`}>
                      {row.getVisibleCells().map((cell) => (
                        <td key={cell.id} className="px-4 py-3 whitespace-nowrap">
                          {flexRender(cell.column.columnDef.cell, cell.getContext())}
                        </td>
                      ))}
                    </tr>
                    {row.getIsExpanded() && renderExpandedRow && (
                      <tr>
                        <td colSpan={columns.length} className="bg-gray-50 border-b border-gray-200 px-4 py-3">
                          {renderExpandedRow(row.original)}
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))
            }
          </tbody>
        </table>
      </div>
      {showPagination && (totalPages ?? 0) > 0 && (
        <AdminPagination
          page={page!} totalPages={totalPages!} total={total!} limit={limit!}
          onPageChange={onPageChange!} onLimitChange={onLimitChange!}
        />
      )}
    </div>
  );
}

// ─── Page Shell ────────────────────────────────────────────────────────────────
interface PageShellProps {
  title: string;
  description?: string;
  /** Alias: actions hoặc action (dùng 1 trong 2) */
  action?: React.ReactNode;
  actions?: React.ReactNode;
  children: React.ReactNode;
}

export function PageShell({ title, description, action, actions, children }: PageShellProps) {
  const headerAction = actions ?? action;
  return (
    <div className="px-6 py-5 max-w-screen-2xl mx-auto space-y-4">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
          {description && <p className="text-sm text-gray-500 mt-0.5">{description}</p>}
        </div>
        {headerAction && <div className="shrink-0">{headerAction}</div>}
      </div>
      {children}
    </div>
  );
}

// ─── Search Bar ────────────────────────────────────────────────────────────────
interface SearchBarProps {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  children?: React.ReactNode;
}

export function SearchBar({ value, onChange, placeholder = 'Tìm kiếm...', children }: SearchBarProps) {
  const [localValue, setLocalValue] = useState(value);

  React.useEffect(() => {
    setLocalValue(value);
  }, [value]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setLocalValue(e.target.value);
    onChange(e.target.value);
  };

  return (
    <div className="flex items-center gap-2">
      <div className="relative flex-1 max-w-sm">
        <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        <input
          type="text"
          value={localValue}
          onChange={handleChange}
          placeholder={placeholder}
          className="w-full pl-9 pr-4 py-1.5 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent"
        />
      </div>
      {children}
    </div>
  );
}

// ─── Filter Select ─────────────────────────────────────────────────────────────
interface FilterSelectProps {
  value: string;
  onChange: (v: string) => void;
  options: { value: string; label: string }[];
  placeholder?: string;
}

export function FilterSelect({ value, onChange, options, placeholder = 'Tất cả' }: FilterSelectProps) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="border border-gray-300 rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400 bg-white text-gray-700"
    >
      <option value="">{placeholder}</option>
      {options.map((o) => (
        <option key={o.value} value={o.value}>{o.label}</option>
      ))}
    </select>
  );
}

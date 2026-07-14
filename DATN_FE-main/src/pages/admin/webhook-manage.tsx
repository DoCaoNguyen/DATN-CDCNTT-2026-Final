import React, { useMemo, useState } from 'react';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { useWebhooks, useWebhookDetail, useRetryWebhook } from '../../features/webhooks/hooks/use-webhooks';
import { AdminTable, PageShell, SearchBar, FilterSelect, StatCard, StatusBadge } from '../../components/ui/admin-components';
import type { ColumnDef } from '@tanstack/react-table';
import { Button } from '../../components/ui/button';
import { formatDateTime } from '../../utils/formatters';
import { Webhook, AlertTriangle, RefreshCw, Eye, X, RotateCcw } from 'lucide-react';

const STATUS_OPTIONS = [
  { value: 'PENDING',  label: 'Đang chờ' },
  { value: 'SUCCESS',  label: 'Thành công' },
  { value: 'FAILED',   label: 'Thất bại' },
  { value: 'RETRYING', label: 'Đang retry' },
];

// ─── JSON Viewer đơn giản ──────────────────────────────────────────────────────
function JsonViewer({ value }: { value: any }) {
  let parsed: any = value;
  if (typeof value === 'string') {
    try { parsed = JSON.parse(value); } catch { /* giữ nguyên string */ }
  }
  return (
    <pre className="bg-gray-900 text-emerald-400 rounded-lg p-4 text-xs overflow-auto max-h-60 font-mono whitespace-pre-wrap break-all">
      {typeof parsed === 'object' ? JSON.stringify(parsed, null, 2) : String(parsed || '—')}
    </pre>
  );
}

// ─── Detail Modal ──────────────────────────────────────────────────────────────
function WebhookDetailModal({ id, onClose }: { id: string; onClose: () => void }) {
  const { data, isLoading } = useWebhookDetail(id);
  const retryMutation = useRetryWebhook();
  const [confirmRetry, setConfirmRetry] = useState(false);

  const wh = data?.data ?? data;

  const canRetry = wh && ['FAILED', 'PENDING', 'RETRYING'].includes(wh.status);

  const handleRetry = () => {
    retryMutation.mutate(id, {
      onSuccess: () => { setConfirmRetry(false); onClose(); },
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[90vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <h3 className="font-bold text-gray-900">Chi tiết Webhook</h3>
          <Button variant="ghost" size="icon" onClick={onClose}>
            <X className="w-4 h-4 text-gray-500" />
          </Button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-6 py-4 space-y-4">
          {isLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="h-4 bg-gray-100 rounded animate-pulse w-3/4" />
              ))}
            </div>
          ) : !wh ? (
            <p className="text-gray-400 text-sm">Không tìm thấy dữ liệu.</p>
          ) : (
            <>
              {/* Meta info */}
              <div className="grid grid-cols-2 gap-3 text-sm">
                <InfoRow label="ID" value={<span className="font-mono text-xs">{wh.id}</span>} />
                <InfoRow label="Trạng thái" value={<StatusBadge status={wh.status} />} />
                <InfoRow label="Loại sự kiện" value={<span className="font-mono text-xs">{wh.event_type}</span>} />
                <InfoRow label="URL" value={<span className="break-all text-xs text-blue-600">{wh.url}</span>} />
                <InfoRow label="Tạo lúc" value={formatDateTime(wh.created_at)} />
                <InfoRow label="Retry lần" value={wh.retry_count ?? 0} />
                <InfoRow label="Lần gửi gần nhất" value={formatDateTime(wh.last_attempt_at)} />
                <InfoRow label="Mã phản hồi" value={wh.response_status_code ?? '—'} />
              </div>

              {/* Request Payload */}
              <div>
                <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Request Payload</p>
                <JsonViewer value={wh.payload ?? wh.request_body} />
              </div>

              {/* Response Body */}
              {(wh.response_body || wh.response) && (
                <div>
                  <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Response Body</p>
                  <JsonViewer value={wh.response_body ?? wh.response} />
                </div>
              )}
            </>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200">
          <div />
          <div className="flex gap-3">
            <Button variant="outline" onClick={onClose}>
              Đóng
            </Button>
            {canRetry && !confirmRetry && (
              <Button variant="primary" onClick={() => setConfirmRetry(true)}>
                <RotateCcw className="w-3.5 h-3.5 mr-2" /> Thử lại
              </Button>
            )}
            {confirmRetry && (
              <Button variant="danger" onClick={handleRetry} disabled={retryMutation.isPending}>
                {retryMutation.isPending ? 'Đang gửi...' : 'Xác nhận Retry'}
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div>
      <p className="text-xs text-gray-400 mb-0.5">{label}</p>
      <div className="text-sm text-gray-800">{value}</div>
    </div>
  );
}

// ─── Main Page ─────────────────────────────────────────────────────────────────
export default function WebhookManage() {
  const { params, setQueryParams } = useApiQueryParams();
  const { data, isLoading } = useWebhooks(params);
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const items      = data?.data?.items ?? data?.items ?? [];
  const total      = data?.data?.total ?? data?.total ?? 0;
  const totalPages = data?.data?.total_pages ?? data?.total_pages ?? 1;

  const failed   = items.filter((r: any) => r.status === 'FAILED').length;
  const retrying = items.filter((r: any) => r.status === 'RETRYING').length;

  const columns = useMemo<ColumnDef<any>[]>(() => [
    {
      accessorKey: 'event_type',
      header: 'Sự kiện',
      cell: ({ row }) => (
        <div>
          <p className="font-mono text-xs font-medium text-gray-800">{row.original.event_type}</p>
          <p className="text-xs text-gray-400 mt-0.5">{formatDateTime(row.original.created_at)}</p>
        </div>
      ),
    },
    {
      accessorKey: 'url',
      header: 'URL đích',
      cell: ({ getValue }) => (
        <span className="text-xs text-blue-600 max-w-[200px] block truncate">{getValue<string>()}</span>
      ),
    },
    {
      accessorKey: 'status',
      header: 'Trạng thái',
      cell: ({ getValue }) => <StatusBadge status={getValue<string>()} />,
    },
    {
      accessorKey: 'retry_count',
      header: 'Lần retry',
      cell: ({ getValue }) => (
        <span className="text-sm text-gray-700">{getValue<number>() ?? 0}</span>
      ),
    },
    {
      accessorKey: 'response_status_code',
      header: 'HTTP',
      cell: ({ getValue }) => {
        const code = getValue<number>();
        const color = !code ? 'text-gray-400' : code >= 200 && code < 300 ? 'text-green-600' : 'text-red-600';
        return <span className={`font-mono text-xs font-semibold ${color}`}>{code ?? '—'}</span>;
      },
    },
    {
      accessorKey: 'last_attempt_at',
      header: 'Gửi lần cuối',
      cell: ({ getValue }) => (
        <span className="text-xs text-gray-500">{formatDateTime(getValue<string>())}</span>
      ),
    },
    {
      id: 'actions',
      header: '',
      cell: ({ row }) => (
        <Button
          variant="ghost"
          onClick={() => setSelectedId(row.original.id)}
          className="text-blue-600 hover:bg-blue-50"
        >
          <Eye className="w-3.5 h-3.5 mr-1.5" /> Chi tiết
        </Button>
      ),
    },
  ], []);

  return (
    <PageShell title="Webhooks" description="Giám sát các sự kiện webhook được gửi đến hệ thống.">
      {/* Stat cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <StatCard icon={<Webhook className="w-5 h-5 text-blue-600" />} iconBg="bg-blue-50" label="Tổng webhook" value={total} />
        <StatCard icon={<AlertTriangle className="w-5 h-5 text-red-500" />} iconBg="bg-red-50" label="Thất bại" value={failed} />
        <StatCard icon={<RefreshCw className="w-5 h-5 text-orange-500" />} iconBg="bg-orange-50" label="Đang retry" value={retrying} />
      </div>

      {/* Toolbar */}
      <div className="flex items-center gap-2 flex-wrap">
        <SearchBar
          value={params.search}
          onChange={(v) => setQueryParams({ search: v, page: 1 })}
          placeholder="Tìm theo event type, URL..."
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
        getRowClassName={(row: any) =>
          row.status === 'FAILED' ? 'bg-red-50/40' : ''
        }
      />

      {selectedId && (
        <WebhookDetailModal id={selectedId} onClose={() => setSelectedId(null)} />
      )}
    </PageShell>
  );
}

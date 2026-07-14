import { useEffect, useState, useMemo } from 'react';
import { ServerCrash, Activity, FileTerminal, ArrowRightLeft, Link, Shield, Eye, ArrowLeft } from 'lucide-react';
import { axiosInstance } from '../../config/axios-instance';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { AdminTable, PageShell } from '../../components/ui/admin-components';
import { Button } from '../../components/ui/button';
import { SearchFilterBar } from '../../components/organisms/filters/search-filter-bar';
import { ActionMenu, ActionMenuItem } from '../../components/ui/action-menu';
import type { ColumnDef } from '@tanstack/react-table';
import { formatDateTime } from '../../utils/formatters';

const VALID_TABS = ['API', 'PAYMENT', 'SYSTEM', 'WEBHOOK', 'AUDIT'];

export default function LogManage() {
  const { params, setQueryParams } = useApiQueryParams();

  const activeTab = VALID_TABS.includes(params.type) ? params.type : 'API';

  const [logs, setLogs] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [selectedLog, setSelectedLog] = useState<any>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleViewDetails = (log: any) => {
    setSelectedLog(log);
    setIsModalOpen(true);
  };

  useEffect(() => {
    fetchLogs();
  }, [activeTab, params.search, params.page, params.limit]);

  const fetchLogs = async () => {
    setIsLoading(true);
    try {
      let endpoint = '';
      if (activeTab === 'API') endpoint = '/admin/logs/api';
      if (activeTab === 'SYSTEM') endpoint = '/admin/logs/system';
      if (activeTab === 'PAYMENT') endpoint = '/admin/logs/traces';
      if (activeTab === 'WEBHOOK') endpoint = '/admin/logs/webhooks';
      if (activeTab === 'AUDIT') endpoint = '/admin/logs/audit-logs';

      const res = await axiosInstance.get(endpoint, { params: { q: params.search, trace_id: params.search, page: params.page, limit: params.limit } });
      const payload = res.data?.data || res.data;
      const itemsList = payload?.items || payload || [];

      if (Array.isArray(itemsList)) {
        setTotal(payload?.total || itemsList.length);
        setLogs(itemsList);
      } else {
        setTotal(0);
        setLogs([]);
      }
    } catch (error) {
      console.error('Lỗi tải Logs:', error);
      setTotal(0);
      setLogs([]);
    } finally {
      setIsLoading(false);
    }
  };

  const apiColumns = useMemo<ColumnDef<any>[]>(() => [
    { accessorKey: 'created_at', header: 'Thời gian', cell: ({ getValue }) => <span className="text-xs font-mono text-slate-500">{formatDateTime(getValue<string>())}</span> },
    {
      id: 'method_path', header: 'Method / Path', cell: ({ row }) => (
        <div>
          <span className={`px-2 py-1 text-[10px] font-bold rounded-md mr-2 ${row.original.method === 'GET' ? 'bg-blue-100 text-blue-700' : row.original.method === 'POST' ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'}`}>{row.original.method}</span>
          <span className="font-mono text-slate-800 font-medium">{row.original.path}</span>
        </div>
      )
    },
    {
      accessorKey: 'status_code', header: 'Trạng thái', cell: ({ getValue }) => {
        const code = getValue<number>() || 200;
        return <span className={`px-2 py-1 rounded-full text-xs font-bold ${code >= 400 ? 'bg-red-100 text-red-700' : 'bg-emerald-100 text-emerald-700'}`}>{code}</span>;
      }
    },
    {
      accessorKey: 'duration_ms', header: 'Thời lượng', cell: ({ getValue }) => <span className="text-slate-600 font-mono">{getValue<number>() || 0} ms</span>
    },
    {
      accessorKey: 'ip_address', header: 'Client IP', cell: ({ getValue }) => <span className="text-slate-500 font-mono text-xs">{getValue<string>() || 'Unknown'}</span>
    },
    {
      id: 'details', header: 'Chi tiết (Req / Res)', cell: ({ row }) => {
        const reqData = row.original.request || row.original.req || row.original.req_body || row.original.payload || row.original.metadata?.request || row.original.metadata?.req || row.original.metadata?.payload;
        const resData = row.original.response || row.original.res || row.original.res_body || row.original.result || row.original.metadata?.response || row.original.metadata?.res;
        return (
          <div className="flex flex-col gap-1 max-w-[250px] overflow-hidden text-[10px] font-mono">
            {reqData && (
              <div className="text-indigo-600 bg-indigo-50 px-2 py-1 rounded truncate" title={typeof reqData === 'string' ? reqData : JSON.stringify(reqData)}>
                Req: {typeof reqData === 'string' ? reqData : JSON.stringify(reqData)}
              </div>
            )}
            {resData && (
              <div className="text-emerald-600 bg-emerald-50 px-2 py-1 rounded truncate" title={typeof resData === 'string' ? resData : JSON.stringify(resData)}>
                Res: {typeof resData === 'string' ? resData : JSON.stringify(resData)}
              </div>
            )}
            {!reqData && !resData && <span className="text-slate-400">Không có dữ liệu</span>}
          </div>
        );
      }
    },
    {
      id: 'view_details', header: () => <div className="text-center">Thao tác</div>, cell: ({ row }) => (
        <div className="flex justify-center">
          <ActionMenu>
            <ActionMenuItem icon={<Eye className="w-4 h-4" />} label="Xem chi tiết" onClick={() => handleViewDetails(row.original)} />
          </ActionMenu>
        </div>
      )
    },
  ], []);

  const paymentColumns = useMemo<ColumnDef<any>[]>(() => [
    { accessorKey: 'created_at', header: 'Thời gian', cell: ({ getValue }) => <span className="text-xs font-mono text-slate-500">{formatDateTime(getValue<string>())}</span> },
    { accessorKey: 'trace_id', header: 'Trace ID', cell: ({ getValue }) => <span className="font-mono text-xs font-semibold text-slate-700">{getValue<string>() || 'N/A'}</span> },
    {
      accessorKey: 'module', header: 'Module', cell: ({ getValue }) => (
        <span className="px-2.5 py-1 bg-indigo-50 text-indigo-700 border border-indigo-100 rounded-lg text-xs font-bold flex items-center w-max">
          <ArrowRightLeft className="w-3 h-3 mr-1" /> {getValue<string>() || 'PAYMENT'}
        </span>
      )
    },
    { accessorKey: 'event', header: 'Sự kiện (Event)', cell: ({ getValue }) => <span className="text-slate-800 font-medium">{getValue<string>()}</span> },
    {
      accessorKey: 'status', header: 'Trạng thái', cell: ({ getValue }) => {
        const status = getValue<string>();
        return <span className={`px-2 py-1 rounded-md text-[10px] font-bold ${status === 'SUCCESS' ? 'bg-emerald-100 text-emerald-700' : status === 'FAILED' ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'}`}>{status || 'INFO'}</span>;
      }
    },
    {
      id: 'view_details', header: () => <div className="text-center">Thao tác</div>, cell: ({ row }) => (
        <div className="flex justify-center">
          <ActionMenu>
            <ActionMenuItem icon={<Eye className="w-4 h-4" />} label="Xem chi tiết" onClick={() => handleViewDetails(row.original)} />
          </ActionMenu>
        </div>
      )
    },
  ], []);

  const systemColumns = useMemo<ColumnDef<any>[]>(() => [
    { accessorKey: 'created_at', header: 'Thời gian', cell: ({ getValue }) => <span className="text-xs font-mono text-slate-500">{formatDateTime(getValue<string>())}</span> },
    {
      accessorKey: 'log_level', header: 'Mức độ (Level)', cell: ({ getValue }) => {
        const level = getValue<string>();
        return <span className={`px-3 py-1 rounded-full text-[10px] font-extrabold ${level === 'CRITICAL' ? 'bg-red-600 text-white animate-pulse' : level === 'ERROR' ? 'bg-red-100 text-red-700' : level === 'WARN' ? 'bg-orange-100 text-orange-700' : 'bg-blue-100 text-blue-700'}`}>{level || 'INFO'}</span>;
      }
    },
    {
      id: 'module_event', header: 'Module / Event', cell: ({ row }) => (
        <div>
          <p className="font-bold text-slate-800 text-xs">{row.original.service_name}</p>
          <p className="text-[11px] text-slate-500 mt-0.5">{row.original.event}</p>
        </div>
      )
    },
    {
      accessorKey: 'message', header: 'Chi tiết lỗi', cell: ({ getValue }) => (
        <div className="text-slate-700 font-mono text-xs max-w-sm truncate" title={getValue<string>()}>
          {getValue<string>()}
        </div>
      )
    },
    {
      id: 'view_details', header: () => <div className="text-center">Thao tác</div>, cell: ({ row }) => (
        <div className="flex justify-center">
          <ActionMenu>
            <ActionMenuItem icon={<Eye className="w-4 h-4" />} label="Xem chi tiết" onClick={() => handleViewDetails(row.original)} />
          </ActionMenu>
        </div>
      )
    },
  ], []);

  const webhookColumns = useMemo<ColumnDef<any>[]>(() => [
    { accessorKey: 'created_at', header: 'Thời gian', cell: ({ getValue }) => <span className="text-xs font-mono text-slate-500">{formatDateTime(getValue<string>())}</span> },
    { id: 'transaction_id', header: 'Transaction ID', cell: ({ row }) => <span className="font-mono text-xs font-semibold text-slate-700">{row.original.metadata?.transaction_id || 'N/A'}</span> },
    { id: 'merchant_id', header: 'Merchant ID', cell: ({ row }) => <span className="font-mono text-xs text-slate-600">{row.original.metadata?.merchant_id || 'N/A'}</span> },
    {
      id: 'status', header: 'Trạng thái', cell: ({ row }) => {
        const status = row.original.metadata?.status;
        return <span className={`px-2 py-1 rounded-md text-[10px] font-bold ${status === 'SUCCESS' ? 'bg-emerald-100 text-emerald-700' : status === 'FAILED' ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'}`}>{status || 'PENDING'}</span>;
      }
    },
    { id: 'retry', header: 'Thử lại', cell: ({ row }) => <span className="text-slate-600 font-mono text-xs">{row.original.metadata?.retry_count || 0} / {row.original.metadata?.max_retries || 5}</span> },
    {
      id: 'error', header: 'Lỗi (nếu có)', cell: ({ row }) => (
        <div className="text-slate-500 text-xs max-w-[200px] truncate" title={row.original.metadata?.last_error}>
          {row.original.metadata?.last_error || '-'}
        </div>
      )
    },
    {
      id: 'view_details', header: () => <div className="text-center">Thao tác</div>, cell: ({ row }) => (
        <div className="flex justify-center">
          <ActionMenu>
            <ActionMenuItem icon={<Eye className="w-4 h-4" />} label="Xem chi tiết" onClick={() => handleViewDetails(row.original)} />
          </ActionMenu>
        </div>
      )
    },
  ], []);

  const auditColumns = useMemo<ColumnDef<any>[]>(() => [
    { accessorKey: 'created_at', header: 'Thời gian', cell: ({ getValue }) => <span className="text-xs font-mono text-slate-500">{formatDateTime(getValue<string>())}</span> },
    {
      id: 'actor', header: 'Người thao tác', cell: ({ row }) => (
        <div className="flex flex-col">
          <span className="font-semibold text-slate-700 text-xs">{row.original.actor_type}</span>
          <span className="font-mono text-[10px] text-slate-500">{row.original.actor_id || 'N/A'}</span>
        </div>
      )
    },
    {
      accessorKey: 'action', header: 'Hành động', cell: ({ getValue }) => (
        <span className="px-2 py-1 bg-indigo-50 text-indigo-700 rounded text-xs font-semibold">{getValue<string>()}</span>
      )
    },
    {
      id: 'entity', header: 'Đối tượng', cell: ({ row }) => (
        <div className="flex flex-col">
          <span className="text-xs text-slate-600">{row.original.entity_type || 'N/A'}</span>
          <span className="font-mono text-[10px] text-slate-500">{row.original.entity_id || 'N/A'}</span>
        </div>
      )
    },
    {
      id: 'details', header: 'Chi tiết (Cũ → Mới)', cell: ({ row }) => (
        <div className="flex flex-col gap-1 max-w-[250px] overflow-hidden text-[10px] font-mono">
          {row.original.old_data && (
            <div className="text-rose-600 bg-rose-50 px-2 py-1 rounded truncate" title={JSON.stringify(row.original.old_data)}>
              - {JSON.stringify(row.original.old_data)}
            </div>
          )}
          {row.original.new_data && (
            <div className="text-emerald-600 bg-emerald-50 px-2 py-1 rounded truncate" title={JSON.stringify(row.original.new_data)}>
              + {JSON.stringify(row.original.new_data)}
            </div>
          )}
          {!row.original.old_data && !row.original.new_data && <span className="text-slate-400">Không có thay đổi dữ liệu</span>}
        </div>
      )
    },
    {
      id: 'view_details', header: () => <div className="text-center">Thao tác</div>, cell: ({ row }) => (
        <div className="flex justify-center">
          <ActionMenu>
            <ActionMenuItem icon={<Eye className="w-4 h-4" />} label="Xem chi tiết" onClick={() => handleViewDetails(row.original)} />
          </ActionMenu>
        </div>
      )
    },
  ], []);

  const currentColumns = activeTab === 'API' ? apiColumns
    : activeTab === 'PAYMENT' ? paymentColumns
      : activeTab === 'SYSTEM' ? systemColumns
        : activeTab === 'WEBHOOK' ? webhookColumns
          : auditColumns;

  if (selectedLog) {
    return (
      <div className="w-full max-w-7xl mx-auto pb-10">
        <div className="mb-6 flex items-center space-x-4">
          <Button variant="outline" size="icon" onClick={() => setSelectedLog(null)}>
            <ArrowLeft className="w-4 h-4" />
          </Button>
          <div>
            <h2 className="text-2xl font-bold text-slate-800">
            {activeTab === 'API' ? 'Chi tiết API Log' 
            : activeTab === 'PAYMENT' ? 'Chi tiết giao dịch (Payment Flow)'
            : activeTab === 'SYSTEM' ? 'Chi tiết truy vết lỗi (System Log)'
            : activeTab === 'WEBHOOK' ? 'Chi tiết Webhook Log'
            : 'Chi tiết thao tác (Audit Log)'}
            </h2>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                {selectedLog.trace_id && (
                  <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                    <p className="text-xs text-slate-500 font-medium mb-1">Trace ID</p>
                    <p className="text-sm font-mono text-slate-800 break-all">{selectedLog.trace_id}</p>
                  </div>
                )}
                {selectedLog.status && (
                  <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                    <p className="text-xs text-slate-500 font-medium mb-1">Trạng thái</p>
                    <span className={`px-2 py-1 rounded-md text-[10px] font-bold ${selectedLog.status === 'SUCCESS' ? 'bg-emerald-100 text-emerald-700' : selectedLog.status === 'FAILED' ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'}`}>{selectedLog.status}</span>
                  </div>
                )}
                {selectedLog.created_at && (
                  <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                    <p className="text-xs text-slate-500 font-medium mb-1">Thời gian</p>
                    <p className="text-sm text-slate-800">{formatDateTime(selectedLog.created_at)}</p>
                  </div>
                )}
                {selectedLog.event && (
                  <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                    <p className="text-xs text-slate-500 font-medium mb-1">Sự kiện</p>
                    <p className="text-sm font-semibold text-slate-800">{selectedLog.event}</p>
                  </div>
                )}
                {selectedLog.amount && (
                  <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                    <p className="text-xs text-slate-500 font-medium mb-1">Số tiền</p>
                    <p className="text-sm font-bold text-emerald-600">{Number(selectedLog.amount).toLocaleString('vi-VN')} VND</p>
                  </div>
                )}
                {selectedLog.event_type && (
                  <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                    <p className="text-xs text-slate-500 font-medium mb-1">Loại sự kiện</p>
                    <p className="text-sm font-mono text-slate-800">{selectedLog.event_type}</p>
                  </div>
                )}
                {(selectedLog.actor || selectedLog.actor_id) && (
                  <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                    <p className="text-xs text-slate-500 font-medium mb-1">Người thao tác (Actor ID)</p>
                    <p className="text-sm font-mono text-slate-800 break-all">{selectedLog.actor || selectedLog.actor_id}</p>
                  </div>
                )}
                {selectedLog.entity_id && (
                  <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                    <p className="text-xs text-slate-500 font-medium mb-1">Đối tượng / Ví (Entity ID)</p>
                    <p className="text-sm font-mono text-slate-800 break-all">{selectedLog.entity_id}</p>
                  </div>
                )}
              </div>

              {(() => {
                if (activeTab !== 'API') return null;

                const reqData = selectedLog.request || selectedLog.req || selectedLog.req_body || selectedLog.payload || selectedLog.metadata?.request || selectedLog.metadata?.req || selectedLog.metadata?.payload;
                const resData = selectedLog.response || selectedLog.res || selectedLog.res_body || selectedLog.result || selectedLog.metadata?.response || selectedLog.metadata?.res;
                
                return (
                  <>
                    <div className="bg-slate-50 p-3 rounded-lg border border-slate-100 mt-4">
                      <p className="text-xs text-indigo-600 font-bold mb-2 flex items-center"><ArrowRightLeft className="w-3 h-3 mr-1" /> Request (Dữ liệu gửi lên)</p>
                      <pre className="text-xs font-mono bg-[#1e1e1e] text-[#d4d4d4] p-3 rounded-md overflow-x-auto whitespace-pre-wrap max-h-[300px] overflow-y-auto">
                        {reqData ? (typeof reqData === 'string' ? reqData : JSON.stringify(reqData, null, 2)) : '{\n  "info": "Không có dữ liệu gửi lên trong log này"\n}'}
                      </pre>
                    </div>
                    
                    <div className="bg-slate-50 p-3 rounded-lg border border-slate-100 mt-4">
                      <p className="text-xs text-emerald-600 font-bold mb-2 flex items-center"><ArrowRightLeft className="w-3 h-3 mr-1" /> Response (Dữ liệu trả về)</p>
                      <pre className="text-xs font-mono bg-[#1e1e1e] text-[#d4d4d4] p-3 rounded-md overflow-x-auto whitespace-pre-wrap max-h-[300px] overflow-y-auto">
                        {resData ? (typeof resData === 'string' ? resData : JSON.stringify(resData, null, 2)) : '{\n  "info": "Không có dữ liệu trả về trong log này"\n}'}
                      </pre>
                    </div>
                  </>
                );
              })()}

              {/* Raw Data */}
              <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                  <p className="text-xs text-slate-500 font-medium mb-2">Dữ liệu thô (Raw Data JSON)</p>
                  <pre className="text-xs font-mono bg-[#1e1e1e] text-[#d4d4d4] p-3 rounded-md overflow-x-auto whitespace-pre-wrap max-h-[350px] overflow-y-auto">
                    {JSON.stringify(selectedLog, null, 2)}
                  </pre>
              </div>
            </div>
        </div>
      </div>
    );
  }

  return (
    <PageShell
      title="Logging & Audit"
      description="Truy vết hệ thống, giám sát luồng thanh toán và lỗi kỹ thuật."
    >
      <div className="mb-6 flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div className="flex flex-wrap gap-1 bg-slate-100/50 p-1 rounded-xl w-max">
        <button
          onClick={() => setQueryParams({ type: 'API', page: 1 })}
          className={`flex items-center px-5 py-2.5 rounded-lg text-sm font-semibold transition-all ${activeTab === 'API' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-600 hover:bg-slate-200/50'}`}
        >
          <FileTerminal className="w-4 h-4 mr-2" /> API Logs
        </button>
        <button
          onClick={() => setQueryParams({ type: 'PAYMENT', page: 1 })}
          className={`flex items-center px-5 py-2.5 rounded-lg text-sm font-semibold transition-all ${activeTab === 'PAYMENT' ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-600 hover:bg-slate-200/50'}`}
        >
          <Activity className="w-4 h-4 mr-2" /> Payment Flow
        </button>
        <button
          onClick={() => setQueryParams({ type: 'SYSTEM', page: 1 })}
          className={`flex items-center px-5 py-2.5 rounded-lg text-sm font-semibold transition-all ${activeTab === 'SYSTEM' ? 'bg-white text-red-600 shadow-sm' : 'text-slate-600 hover:bg-slate-200/50'}`}
        >
          <ServerCrash className="w-4 h-4 mr-2" /> Truy vết lỗi
        </button>
        <button
          onClick={() => setQueryParams({ type: 'WEBHOOK', page: 1 })}
          className={`flex items-center px-5 py-2.5 rounded-lg text-sm font-semibold transition-all ${activeTab === 'WEBHOOK' ? 'bg-white text-orange-600 shadow-sm' : 'text-slate-600 hover:bg-slate-200/50'}`}
        >
          <Link className="w-4 h-4 mr-2" /> Webhook Logs
        </button>
        <button
          onClick={() => setQueryParams({ type: 'AUDIT', page: 1 })}
          className={`flex items-center px-5 py-2.5 rounded-lg text-sm font-semibold transition-all ${activeTab === 'AUDIT' ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-600 hover:bg-slate-200/50'}`}
        >
          <Shield className="w-4 h-4 mr-2" /> Thao tác (Audit)
        </button>
      </div>
      <div className="flex items-center">
          <SearchFilterBar
            searchPlaceholder="Tìm kiếm Trace ID hoặc Path..."
            searchValue={params.search}
            onSearchChange={(val) => setQueryParams({ search: val, page: 1 })}
          />
        </div>
      </div>

      <AdminTable
        columns={currentColumns}
        data={logs}
        isLoading={isLoading}
        page={params.page}
        limit={params.limit}
        total={total}
        totalPages={Math.ceil(total / params.limit) || 1}
        onPageChange={(page) => setQueryParams({ page })}
        onLimitChange={(limit) => setQueryParams({ limit, page: 1 })}
      />
    </PageShell>
  );
}
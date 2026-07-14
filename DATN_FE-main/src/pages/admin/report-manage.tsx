import { useState, useEffect, useMemo } from 'react';
import { FileText, Download, CreditCard, ArrowRightLeft, Store, ShieldAlert } from 'lucide-react';
import toast from 'react-hot-toast';
import { reportService } from '../../features/reports/report.service';
import { formatCurrencyVND, formatDateTime, getStatusVariant } from '../../utils/formatters';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { AdminTable, PageShell, StatusBadge } from '../../components/ui/admin-components';
import { Button } from '../../components/ui/button';
import { SearchFilterBar } from '../../components/organisms/filters/search-filter-bar';
import { DateRangeFilter } from '../../components/organisms/filters/date-range-filter';
import type { ColumnDef } from '@tanstack/react-table';

const TABS = [
  { id: 'topups', label: 'Báo cáo nạp tiền', icon: CreditCard },
  { id: 'transfers', label: 'Báo cáo chuyển tiền', icon: ArrowRightLeft },
  { id: 'payments', label: 'Báo cáo thanh toán', icon: Store },
  { id: 'refunds', label: 'Báo cáo hoàn tiền', icon: ShieldAlert },
  { id: 'merchants', label: 'Báo cáo đối tác', icon: Store },
  { id: 'fees', label: 'Báo cáo doanh thu phí MDR', icon: FileText },
];

const VALID_TABS = TABS.map(t => t.id);

export default function ReportManage() {
  const { params, setQueryParams } = useApiQueryParams();
  const activeTab = VALID_TABS.includes(params.type) ? params.type : 'topups';

  const [data, setData] = useState<any[]>([]);
  const [total, setTotal] = useState(0);
  const [summary, setSummary] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchData();
  }, [activeTab, params.page, params.limit, params.search, params.status, params.fromDate, params.toDate]);

  const fetchData = async () => {
    setLoading(true);
    try {
      let result;
      // Send parameters to backend just in case backend supports them
      const apiParams = {
        page: params.page,
        limit: params.limit,
        status: params.status,
        search: params.search,
        fromDate: params.fromDate,
        toDate: params.toDate
      };

      switch (activeTab) {
        case 'topups': result = await reportService.getTopups(apiParams); break;
        case 'transfers': result = await reportService.getTransfers(apiParams); break;
        case 'payments': result = await reportService.getPayments(apiParams); break;
        case 'refunds': result = await reportService.getRefunds(apiParams); break;
        case 'merchants': result = await reportService.getMerchants(apiParams); break;
        case 'fees': result = await reportService.getFees(apiParams); break;
      }
      
      if (result && result.success) {
        let items = result.data.data || [];
        setSummary(result.data.summary);

        // Bổ sung frontend filtering dự phòng nếu backend trả về danh sách đầy đủ (không phân trang/lọc)
        if (params.search) {
          const s = params.search.toLowerCase();
          items = items.filter((item: any) => 
            JSON.stringify(item).toLowerCase().includes(s)
          );
        }
        
        if (params.status) {
          items = items.filter((item: any) => item.status === params.status);
        }

        if (params.fromDate && params.toDate) {
          const from = new Date(params.fromDate).getTime();
          const to = new Date(params.toDate).getTime();
          items = items.filter((item: any) => {
            const t = new Date(item.created_at).getTime();
            return t >= from && t <= (to + 86400000); // include whole toDate
          });
        }

        setTotal(items.length);
        // Slice phân trang frontend
        const paginated = items.slice((params.page - 1) * params.limit, params.page * params.limit);
        setData(paginated);
      } else {
        setData([]);
        setTotal(0);
        setSummary(null);
      }
    } catch (error) {
      console.error('Error fetching reports:', error);
      setData([]);
      setTotal(0);
      setSummary(null);
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async () => {
    try {
      const exportParams = {
        type: activeTab,
        status: params.status,
        search: params.search,
        fromDate: params.fromDate,
        toDate: params.toDate
      };
      const blob = await reportService.exportData(exportParams);
      
      const url = window.URL.createObjectURL(new Blob([blob]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Report_${activeTab}_${Date.now()}.xlsx`);
      document.body.appendChild(link);
      link.click();
      
      link.parentNode?.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Error exporting data:', error);
      toast.error('Có lỗi xảy ra khi xuất dữ liệu!');
    }
  };

  const statusColumn: ColumnDef<any> = {
    accessorKey: 'status',
    header: () => <div className="text-center">Trạng thái</div>,
    cell: ({ getValue }) => (
      <div className="flex justify-center">
        <StatusBadge status={getValue<string>()} />
      </div>
    )
  };

  const dateColumn: ColumnDef<any> = {
    accessorKey: 'created_at',
    header: 'Ngày tạo',
    cell: ({ getValue }) => <span className="text-slate-500 text-sm">{formatDateTime(getValue<string>())}</span>
  };

  const topupsColumns = useMemo<ColumnDef<any>[]>(() => [
    { accessorKey: 'deposit_no', header: 'Mã GD', cell: ({ getValue }) => <span className="font-medium text-slate-900">{getValue<string>()}</span> },
    { accessorKey: 'user_name', header: 'User', cell: ({ getValue }) => <span className="text-slate-600">{getValue<string>()}</span> },
    { accessorKey: 'deposit_method', header: 'Phương thức', cell: ({ getValue }) => <span className="text-slate-600">{getValue<string>()}</span> },
    { accessorKey: 'amount', header: () => <div className="text-right">Số tiền</div>, cell: ({ getValue }) => <div className="text-right font-medium text-slate-900">{formatCurrencyVND(getValue<number>())}</div> },
    statusColumn,
    dateColumn
  ], []);

  const transfersColumns = useMemo<ColumnDef<any>[]>(() => [
    { accessorKey: 'transfer_no', header: 'Mã GD', cell: ({ getValue }) => <span className="font-medium text-slate-900">{getValue<string>()}</span> },
    { accessorKey: 'sender_name', header: 'Người gửi', cell: ({ getValue }) => <span className="text-slate-600">{getValue<string>()}</span> },
    { accessorKey: 'receiver_name', header: 'Người nhận', cell: ({ getValue }) => <span className="text-slate-600">{getValue<string>()}</span> },
    { accessorKey: 'amount', header: () => <div className="text-right">Số tiền</div>, cell: ({ getValue }) => <div className="text-right font-medium text-slate-900">{formatCurrencyVND(getValue<number>())}</div> },
    statusColumn,
    dateColumn
  ], []);

  const paymentsColumns = useMemo<ColumnDef<any>[]>(() => [
    { accessorKey: 'payment_no', header: 'Mã GD', cell: ({ getValue }) => <span className="font-medium text-slate-900">{getValue<string>()}</span> },
    { accessorKey: 'merchant_name', header: 'Merchant', cell: ({ getValue }) => <span className="text-slate-600">{getValue<string>() || 'N/A'}</span> },
    { accessorKey: 'merchant_order_id', header: 'Mã đơn MH', cell: ({ getValue }) => <span className="text-slate-600">{getValue<string>()}</span> },
    { accessorKey: 'amount', header: () => <div className="text-right">Số tiền</div>, cell: ({ getValue }) => <div className="text-right font-medium text-slate-900">{formatCurrencyVND(getValue<number>())}</div> },
    statusColumn,
    dateColumn
  ], []);

  const refundsColumns = useMemo<ColumnDef<any>[]>(() => [
    { accessorKey: 'refund_no', header: 'Mã Hoàn', cell: ({ getValue }) => <span className="font-medium text-slate-900">{getValue<string>()}</span> },
    { accessorKey: 'payment_no', header: 'Mã Đơn', cell: ({ getValue }) => <span className="text-slate-600">{getValue<string>()}</span> },
    { accessorKey: 'merchant_name', header: 'Merchant', cell: ({ getValue }) => <span className="text-slate-600">{getValue<string>()}</span> },
    { accessorKey: 'amount', header: () => <div className="text-right">Số tiền</div>, cell: ({ getValue }) => <div className="text-right font-medium text-slate-900">{formatCurrencyVND(getValue<number>())}</div> },
    statusColumn,
    dateColumn
  ], []);

  const merchantsColumns = useMemo<ColumnDef<any>[]>(() => [
    { accessorKey: 'merchant_code', header: 'Mã ĐT', cell: ({ getValue }) => <span className="font-medium text-slate-900">{getValue<string>()}</span> },
    { accessorKey: 'merchant_name', header: 'Tên đối tác', cell: ({ getValue }) => <span className="text-slate-600">{getValue<string>()}</span> },
    { accessorKey: 'total_payments', header: () => <div className="text-right">Số đơn</div>, cell: ({ getValue }) => <div className="text-right text-slate-600">{getValue<number>()}</div> },
    { accessorKey: 'paid_payments', header: () => <div className="text-right">Đơn T.Công</div>, cell: ({ getValue }) => <div className="text-right text-slate-600">{getValue<number>()}</div> },
    { accessorKey: 'total_revenue', header: () => <div className="text-right">Tổng doanh số</div>, cell: ({ getValue }) => <div className="text-right font-medium text-slate-900">{formatCurrencyVND(getValue<number>())}</div> },
    statusColumn
  ], []);

  const feesColumns = useMemo<ColumnDef<any>[]>(() => [
    { accessorKey: 'ledger_transaction_id', header: 'Mã Giao Dịch Gốc', cell: ({ getValue }) => <span className="font-medium text-slate-900">{getValue<string>()}</span> },
    { accessorKey: 'amount', header: () => <div className="text-right">Số tiền phí</div>, cell: ({ getValue }) => <div className="text-right font-medium text-green-600">{formatCurrencyVND(getValue<number>())}</div> },
    dateColumn
  ], []);

  const currentColumns = activeTab === 'topups' ? topupsColumns
                       : activeTab === 'transfers' ? transfersColumns
                       : activeTab === 'payments' ? paymentsColumns
                       : activeTab === 'refunds' ? refundsColumns
                       : activeTab === 'fees' ? feesColumns
                       : merchantsColumns;

  // Render Status Options based on Tab
  const renderStatusOptions = () => {
    if (activeTab === 'merchants') {
      return (
        <>
          <option value="ACTIVE">Hoạt động (ACTIVE)</option>
          <option value="INACTIVE">Đã khóa (INACTIVE)</option>
          <option value="PENDING_REVIEW">Chờ duyệt (PENDING)</option>
        </>
      );
    } else if (activeTab === 'payments') {
      return (
        <>
          <option value="PAID">Đã thanh toán (PAID)</option>
          <option value="PENDING">Chờ xử lý (PENDING)</option>
          <option value="FAILED">Thất bại (FAILED)</option>
          <option value="EXPIRED">Hết hạn (EXPIRED)</option>
        </>
      );
    } else {
      return (
        <>
          <option value="SUCCESS">Thành công (SUCCESS)</option>
          <option value="FAILED">Thất bại (FAILED)</option>
          <option value="PENDING">Chờ xử lý (PENDING)</option>
        </>
      );
    }
  };

  const currentTab = TABS.find(t => t.id === activeTab) || TABS[0];

  return (
    <PageShell
      title={currentTab.label}
      description="Tra cứu và theo dõi các giao dịch trên hệ thống."
      actions={
        <Button variant="outline" onClick={handleExport}>
          <Download className="w-4 h-4 mr-2" />
          Xuất Excel
        </Button>
      }
    >

      {summary && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100">
            <p className="text-sm font-medium text-slate-500 mb-1">
              {activeTab === 'merchants' ? 'Tổng số đối tác / record' : 'Tổng số giao dịch / record'}
            </p>
            <h3 className="text-2xl font-bold text-slate-800">{summary.total_count}</h3>
          </div>
          {summary.total_success_amount !== undefined && (
            <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100">
              <p className="text-sm font-medium text-slate-500 mb-1">Tổng tiền thành công</p>
              <h3 className="text-2xl font-bold text-green-600">{formatCurrencyVND(summary.total_success_amount)}</h3>
            </div>
          )}
          {summary.total_revenue !== undefined && (
            <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100">
              <p className="text-sm font-medium text-slate-500 mb-1">{activeTab === 'fees' ? 'Tổng doanh thu từ phí MDR' : 'Tổng doanh thu'}</p>
              <h3 className="text-2xl font-bold text-blue-600">{formatCurrencyVND(summary.total_revenue)}</h3>
            </div>
          )}
        </div>
      )}

      <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-100 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <DateRangeFilter 
          fromDate={params.fromDate}
          toDate={params.toDate}
          onChange={(from: string, to: string) => setQueryParams({ fromDate: from, toDate: to, page: 1 })}
        />
        
        <div className="flex items-center space-x-3">
          <select 
            value={params.status}
            onChange={(e) => setQueryParams({ status: e.target.value, page: 1 })}
            className="px-4 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:border-blue-500 font-medium text-slate-700 bg-white min-w-[150px]"
          >
            <option value="">Tất cả trạng thái</option>
            {renderStatusOptions()}
          </select>
          <SearchFilterBar 
            searchPlaceholder="Tìm kiếm mã GD..."
            searchValue={params.search}
            onSearchChange={(val) => setQueryParams({ search: val, page: 1 })}
          />
        </div>
      </div>

      <AdminTable 
        columns={currentColumns}
        data={data}
        isLoading={loading}
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

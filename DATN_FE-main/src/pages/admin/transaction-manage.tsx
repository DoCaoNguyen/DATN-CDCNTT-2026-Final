import { useEffect, useState, useMemo } from 'react';
import { ChevronDown, ChevronRight } from 'lucide-react';
import { transactionService } from '../../features/transactions/transaction.service';
import type { TransactionDetail } from '../../types';
import { formatVND, formatDateTime, getStatusVariant } from '../../utils/formatters';
import { useApiQueryParams } from '../../hooks/use-api-query-params';
import { AdminTable, PageShell, StatusBadge } from '../../components/ui/admin-components';
import { SearchFilterBar } from '../../components/organisms/filters/search-filter-bar';
import { TransactionExpandedRow } from '../../features/transactions/components/transaction-expanded-row';
import type { ColumnDef } from '@tanstack/react-table';

export default function TransactionManage() {
  const [transactions, setTransactions] = useState<TransactionDetail[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Hook query params (react-router-dom)
  const { params, setQueryParams } = useApiQueryParams();

  useEffect(() => {
    fetchTransactions();
  }, [params.page, params.limit, params.search, params.status, params.type]); 

  const fetchTransactions = async () => {
    setIsLoading(true);
    try {
      const res = await transactionService.getTransactions(
        params.search, 
        params.type || '', 
        params.status
      );
      const payload = res?.data || res;
      const dataList = payload?.data?.items || payload?.items || payload?.data || payload;
      
      setTransactions(Array.isArray(dataList) ? dataList : []);
    } catch (error) {
      console.error('Lỗi tải danh sách Giao dịch:', error);
      setTransactions([]);
    } finally {
      setIsLoading(false);
    }
  };

  const renderTypeBadge = (type: string) => {
    switch(type) {
      case 'TOPUP': return <span className="px-2 py-1 bg-blue-100 text-blue-700 rounded text-xs font-bold">NẠP TIỀN</span>;
      case 'PAYMENT': return <span className="px-2 py-1 bg-indigo-100 text-indigo-700 rounded text-xs font-bold">THANH TOÁN</span>;
      case 'TRANSFER': return <span className="px-2 py-1 bg-purple-100 text-purple-700 rounded text-xs font-bold">CHUYỂN TIỀN</span>;
      case 'REFUND': return <span className="px-2 py-1 bg-orange-100 text-orange-700 rounded text-xs font-bold">HOÀN TIỀN</span>;
      default: return <span className="px-2 py-1 bg-slate-100 text-slate-700 rounded text-xs font-bold">{type}</span>;
    }
  };

  const renderStatusBadge = (status: string) => {
    return <StatusBadge status={status} />;
  };

  // Define Columns for DataTable
  const columns = useMemo<ColumnDef<TransactionDetail>[]>(
    () => [
      {
        id: 'expander',
        header: () => null,
        cell: ({ row }) => {
          return row.getCanExpand() ? (
            <button
              onClick={row.getToggleExpandedHandler()}
              className="p-1 hover:bg-gray-100 rounded text-gray-500 transition-colors"
            >
              {row.getIsExpanded() ? <ChevronDown className="w-5 h-5" /> : <ChevronRight className="w-5 h-5" />}
            </button>
          ) : null;
        },
      },
      {
        accessorKey: 'trans_code',
        header: 'Mã Giao Dịch & Thời Gian',
        cell: ({ row }) => (
          <div>
            <p className="font-bold text-slate-800 font-mono text-xs">{row.original.trans_code}</p>
            <p className="text-xs text-slate-500 mt-1">{formatDateTime(row.original.created_at)}</p>
          </div>
        ),
      },
      {
        accessorKey: 'trans_type',
        header: 'Loại GD',
        cell: ({ getValue }) => renderTypeBadge(getValue<string>()),
      },
      {
        accessorKey: 'amount',
        header: 'Số tiền (VND)',
        cell: ({ getValue }) => (
          <div className="text-right font-bold text-slate-800">{formatVND(getValue<number>())}</div>
        ),
      },
      {
        accessorKey: 'status',
        header: 'Trạng thái',
        cell: ({ getValue }) => renderStatusBadge(getValue<string>()),
      },
      {
        accessorKey: 'source_id',
        header: 'Tham chiếu (Ref)',
        cell: ({ getValue }) => (
          <div className="text-xs font-mono text-slate-500 truncate max-w-[150px]" title={getValue<string>()}>
            {getValue<string>() || 'N/A'}
          </div>
        ),
      },
    ],
    []
  );

  const total = transactions.length;
  const paginatedTransactions = useMemo(() => {
    const start = (params.page - 1) * params.limit;
    return transactions.slice(start, start + params.limit);
  }, [transactions, params.page, params.limit]);

  return (
    <PageShell
      title="Quản lý Giao dịch & Ledger"
      description="Giám sát toàn bộ luồng tiền. Dữ liệu kế toán không thể sửa xóa."
    >
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <SearchFilterBar 
          searchPlaceholder="Mã GD, Mã đối chiếu..."
          searchValue={params.search}
          onSearchChange={(value) => setQueryParams({ search: value, page: 1 })}
          typeValue={params.type || ''}
          onTypeChange={(value) => setQueryParams({ type: value, page: 1 })}
          typeOptions={[
            { label: 'Tất cả Loại GD', value: '' },
            { label: 'Nạp tiền (Topup)', value: 'TOPUP' },
            { label: 'Chuyển tiền (Transfer)', value: 'TRANSFER' },
            { label: 'Thanh toán (Payment)', value: 'PAYMENT' },
            { label: 'Hoàn tiền (Refund)', value: 'REFUND' },
          ]}
          statusValue={params.status}
          onStatusChange={(value) => setQueryParams({ status: value, page: 1 })}
          statusOptions={[
            { label: 'Tất cả Trạng thái', value: '' },
            { label: 'Thành công', value: 'SUCCESS' },
            { label: 'Đang xử lý', value: 'PENDING' },
            { label: 'Thất bại', value: 'FAILED' },
          ]}
          onReset={() => setQueryParams({ search: '', type: '', status: '', page: 1 })}
        />
      </div>

      <AdminTable 
        columns={columns}
        data={paginatedTransactions}
        isLoading={isLoading}
        page={params.page}
        limit={params.limit}
        total={total}
        totalPages={Math.ceil(total / params.limit) || 1}
        onPageChange={(page) => setQueryParams({ page })}
        onLimitChange={(limit) => setQueryParams({ limit, page: 1 })}
        renderExpandedRow={(row) => <TransactionExpandedRow transaction={row} />}
      />
    </PageShell>
  );
}
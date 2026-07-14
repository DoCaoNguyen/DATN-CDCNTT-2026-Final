import { useEffect, useState } from 'react';
import { Loader2, ArrowUpRight, ArrowDownRight, RefreshCcw } from 'lucide-react';
import { transactionService } from '../transaction.service';
import type { TransactionDetail, LedgerEntry } from '../../../types';
import { formatVND, getStatusVariant } from '../../../utils/formatters';

interface TransactionExpandedRowProps {
  transaction: TransactionDetail;
}

export function TransactionExpandedRow({ transaction }: TransactionExpandedRowProps) {
  const [entries, setEntries] = useState<LedgerEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;
    const fetchEntries = async () => {
      setIsLoading(true);
      try {
        const res = await transactionService.getTransactionEntries(transaction.id);
        if (isMounted) {
          const data = res.data || res || [];
          setEntries(Array.isArray(data) ? data : []);
        }
      } catch (error) {
        console.error('Lỗi tải chi tiết bút toán:', error);
        if (isMounted) setEntries([]);
      } finally {
        if (isMounted) setIsLoading(false);
      }
    };
    fetchEntries();
    return () => { isMounted = false; };
  }, [transaction.id]);

  const renderStatusBadge = (status: string) => {
    const v = getStatusVariant(status);
    return <span className={`px-2 py-1 rounded text-xs font-bold ${v.className}`}>{v.label}</span>;
  };

  return (
    <div className="p-6 bg-slate-50 border-x border-b border-slate-200">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6 p-4 bg-white rounded-xl border border-slate-100 shadow-sm text-sm">
        <div>
          <span className="text-slate-500 block mb-1">Số tiền gốc:</span>
          <span className="font-bold text-lg text-slate-800">{formatVND(transaction.amount)}</span>
        </div>
        <div>
          <span className="text-slate-500 block mb-1">Mô tả:</span>
          <span className="font-medium text-slate-700">{transaction.description || 'Không có mô tả'}</span>
        </div>
        <div>
          <span className="text-slate-500 block mb-1">Trạng thái:</span>
          {renderStatusBadge(transaction.status)}
        </div>
        <div>
          <span className="text-slate-500 block mb-1">Tham chiếu:</span>
          <span className="font-mono text-xs text-slate-600 bg-slate-100 px-2 py-1 rounded">{transaction.source_id || 'N/A'}</span>
        </div>
      </div>

      <h4 className="font-bold text-slate-800 mb-3 flex items-center">
        <RefreshCcw className="w-4 h-4 mr-2 text-slate-400" /> Dòng tiền chi tiết (Debit/Credit)
      </h4>
      
      {isLoading ? (
        <div className="p-8 flex justify-center bg-white rounded-xl border border-slate-100">
          <Loader2 className="w-6 h-6 animate-spin text-blue-500" />
        </div>
      ) : entries.length === 0 ? (
        <div className="p-8 text-center text-slate-500 border border-dashed border-slate-300 rounded-xl bg-white">
          Chưa có dữ liệu bút toán chi tiết.
        </div>
      ) : (
        <div className="border border-slate-200 rounded-xl overflow-hidden bg-white shadow-sm">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-slate-600 font-semibold border-b border-slate-200">
              <tr>
                <th className="p-3">ID Ví / Tài khoản</th>
                <th className="p-3">Chiều</th>
                <th className="p-3 text-right">Số tiền ghi nhận</th>
                <th className="p-3 text-right">Số dư sau GD</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {entries.map(entry => (
                <tr key={entry.id} className="hover:bg-slate-50/50 transition-colors">
                  <td className="p-3 font-mono text-xs text-slate-600">{entry.wallet_id}</td>
                  <td className="p-3">
                    {entry.direction === 'CREDIT' ? (
                      <span className="flex items-center text-emerald-600 font-bold text-xs">
                        <ArrowDownRight className="w-3 h-3 mr-1"/> CREDIT (+)
                      </span>
                    ) : (
                      <span className="flex items-center text-red-600 font-bold text-xs">
                        <ArrowUpRight className="w-3 h-3 mr-1"/> DEBIT (-)
                      </span>
                    )}
                  </td>
                  <td className={`p-3 text-right font-bold ${entry.direction === 'CREDIT' ? 'text-emerald-600' : 'text-red-600'}`}>
                    {entry.direction === 'CREDIT' ? '+' : '-'}{formatVND(entry.amount)}
                  </td>
                  <td className="p-3 text-right font-semibold text-slate-700">
                    {formatVND(entry.post_balance)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

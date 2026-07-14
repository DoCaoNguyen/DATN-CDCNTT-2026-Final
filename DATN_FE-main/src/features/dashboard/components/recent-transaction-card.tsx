import { ArrowRightLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { formatVND, formatDateTime } from '../../../utils/formatters';

interface RecentTransactionCardProps {
  transactions: any[];
}

export function RecentTransactionCard({ transactions }: RecentTransactionCardProps) {
  const navigate = useNavigate();

  return (
    <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex flex-col h-full">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h3 className="text-lg font-bold text-slate-800">Giao dịch gần đây</h3>
          <p className="text-xs text-slate-500 mt-1">Cập nhật theo thời gian thực</p>
        </div>
      </div>
      
      <div className="space-y-4 flex-1">
        {transactions && transactions.length > 0 ? (
          transactions.map((tx: any, idx: number) => (
            <div 
              key={idx} 
              className="flex items-center justify-between p-3 hover:bg-slate-50 rounded-xl transition-all cursor-pointer border border-transparent hover:border-slate-100"
              onClick={() => navigate('/admin/ledger')}
            >
              <div className="flex items-center space-x-3">
                <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0
                  ${tx.status === 'SUCCESS' ? 'bg-emerald-100 text-emerald-600' :
                    tx.status === 'FAILED' ? 'bg-red-100 text-red-600' : 'bg-amber-100 text-amber-600'}
                `}>
                  <ArrowRightLeft className="w-5 h-5" />
                </div>
                <div className="overflow-hidden">
                  <p className="font-semibold text-slate-800 text-sm truncate">{tx.transaction_type || 'Giao dịch'}</p>
                  <p className="text-[11px] text-slate-500 font-mono mt-0.5 truncate max-w-[120px]">{tx.transaction_no || tx.trans_code || tx.id}</p>
                </div>
              </div>
              <div className="text-right shrink-0">
                <p className={`font-bold text-sm ${tx.status === 'FAILED' ? 'text-slate-400 line-through' : 'text-slate-800'}`}>
                  {tx.direction === 'DEBIT' ? '-' : '+'}{formatVND(tx.amount)}
                </p>
                <p className="text-[10px] text-slate-500 mt-0.5">{tx.created_at ? formatDateTime(tx.created_at) : 'N/A'}</p>
              </div>
            </div>
          ))
        ) : (
          <div className="h-full flex items-center justify-center">
            <p className="text-slate-400 text-sm">Chưa có giao dịch nào</p>
          </div>
        )}
      </div>

      <button
        onClick={() => navigate('/admin/ledger')}
        className="w-full mt-6 py-3 text-sm font-bold text-blue-600 bg-blue-50 rounded-xl hover:bg-blue-100 hover:shadow-sm transition-all flex justify-center items-center gap-2"
      >
        Xem tất cả giao dịch <ArrowRightLeft className="w-4 h-4" />
      </button>
    </div>
  );
}

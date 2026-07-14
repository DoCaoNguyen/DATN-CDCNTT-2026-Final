import { Dialog, DialogHeader, DialogTitle } from '../../../components/ui/dialog';
import { StatusBadge } from '../../../components/common/status-badge';
import { MoneyAmount } from '../../../components/common/money-amount';
import { LoadingState } from '../../../components/common/loading-state';
import { useTransactionDetail } from '../hooks/use-transaction-detail';
import type { Transaction } from '../types/transaction.type';
import { ArrowDownRight, ArrowUpRight, RefreshCcw } from 'lucide-react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../../../components/ui/table';

interface TransactionDetailDialogProps {
  transaction: Transaction | null;
  open: boolean;
  onClose: () => void;
}

export function TransactionDetailDialog({ transaction, open, onClose }: TransactionDetailDialogProps) {
  const { data: entries, isLoading } = useTransactionDetail(transaction?.id || null);

  if (!transaction) return null;

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader className="mb-4">
        <DialogTitle>Chi tiết bút toán (Ledger Entries)</DialogTitle>
        <p className="text-xs font-mono text-slate-500 mt-1">Mã GD: {transaction.trans_code}</p>
      </DialogHeader>
      
      <div className="overflow-y-auto max-h-[70vh] -mx-6 px-6">
        <div className="grid grid-cols-2 gap-4 mb-6 p-4 bg-slate-50 rounded-xl border border-slate-100 text-sm">
          <div><span className="text-slate-500 block mb-1">Số tiền gốc:</span><MoneyAmount amount={transaction.amount} className="text-lg" /></div>
          <div><span className="text-slate-500 block mb-1">Mô tả:</span><span className="font-medium text-slate-700">{transaction.description}</span></div>
          <div><span className="text-slate-500 block mb-1">Trạng thái:</span><StatusBadge status={transaction.status} /></div>
          <div><span className="text-slate-500 block mb-1">Tham chiếu:</span><span className="font-mono text-xs">{transaction.source_id || 'N/A'}</span></div>
        </div>

        <h4 className="font-bold text-slate-800 mb-3 flex items-center">
          <RefreshCcw className="w-4 h-4 mr-2 text-slate-400" /> Dòng tiền chi tiết (Debit/Credit)
        </h4>
        
        {isLoading ? (
          <LoadingState message="Đang tải bút toán..." />
        ) : !entries || entries.length === 0 ? (
          <div className="p-8 text-center text-slate-500 border border-dashed rounded-xl bg-slate-50">
            Chưa có dữ liệu bút toán chi tiết.
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>ID Ví</TableHead>
                <TableHead>Chiều</TableHead>
                <TableHead className="text-right">Số tiền</TableHead>
                <TableHead className="text-right">Số dư sau GD</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {entries.map(entry => (
                <TableRow key={entry.id}>
                  <TableCell className="font-mono text-xs text-slate-600">{entry.wallet_id}</TableCell>
                  <TableCell>
                    {entry.direction === 'CREDIT' ? (
                      <span className="flex items-center text-emerald-600 font-bold text-xs"><ArrowDownRight className="w-3 h-3 mr-1"/> CREDIT (+)</span>
                    ) : (
                      <span className="flex items-center text-red-600 font-bold text-xs"><ArrowUpRight className="w-3 h-3 mr-1"/> DEBIT (-)</span>
                    )}
                  </TableCell>
                  <TableCell className="text-right">
                    <MoneyAmount 
                      amount={entry.amount} 
                      className={entry.direction === 'CREDIT' ? 'text-emerald-600' : 'text-red-600'} 
                    />
                  </TableCell>
                  <TableCell className="text-right font-semibold text-slate-700">
                    <MoneyAmount amount={entry.post_balance} />
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </div>
    </Dialog>
  );
}

import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../../../components/ui/table';
import { EmptyState } from '../../../components/common/empty-state';
import { LoadingState } from '../../../components/common/loading-state';
import { MoneyAmount } from '../../../components/common/money-amount';
import type { WalletLedgerEntry } from '../types/wallet.type';

interface WalletLedgerTableProps {
  ledger: WalletLedgerEntry[];
  isLoading: boolean;
}

export function WalletLedgerTable({ ledger, isLoading }: WalletLedgerTableProps) {
  if (isLoading) return <LoadingState message="Đang tải sổ cái..." />;
  if (ledger.length === 0) return <EmptyState description="Chưa có giao dịch nào được ghi nhận trong sổ cái." />;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Thời gian</TableHead>
            <TableHead>Mã GD / Loại GD</TableHead>
            <TableHead className="text-center">Ghi nhận</TableHead>
            <TableHead className="text-right">Số tiền</TableHead>
            <TableHead className="text-right">Số dư trước</TableHead>
            <TableHead className="text-right">Số dư sau</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {ledger.map((entry, idx) => (
            <TableRow key={entry.ledger_entry_id || entry.id || idx}>
              <TableCell className="text-xs text-slate-500">
                {entry.created_at ? new Date(entry.created_at).toLocaleString('vi-VN') : 'N/A'}
              </TableCell>
              <TableCell>
                <p className="font-mono font-bold text-slate-800">{entry.transaction_no}</p>
                <p className="text-xs font-semibold text-slate-500 mt-0.5">{entry.transaction_type}</p>
              </TableCell>
              <TableCell className="text-center">
                {entry.entry_type === 'CREDIT' ? (
                  <span className="px-2 py-1 bg-emerald-100 text-emerald-700 font-bold text-[10px] rounded">CREDIT (+)</span>
                ) : (
                  <span className="px-2 py-1 bg-red-100 text-red-700 font-bold text-[10px] rounded">DEBIT (-)</span>
                )}
              </TableCell>
              <TableCell className={`text-right font-bold ${entry.entry_type === 'CREDIT' ? 'text-emerald-600' : 'text-red-500'}`}>
                {entry.entry_type === 'CREDIT' ? '+' : '-'}
                <MoneyAmount amount={entry.amount} />
              </TableCell>
              <TableCell className="text-right font-medium text-slate-500">
                <MoneyAmount amount={entry.balance_before} />
              </TableCell>
              <TableCell className="text-right font-bold text-blue-600">
                <MoneyAmount amount={entry.balance_after} />
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

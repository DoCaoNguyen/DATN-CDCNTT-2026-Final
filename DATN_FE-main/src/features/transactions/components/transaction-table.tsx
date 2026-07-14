import { Eye } from 'lucide-react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../../../components/ui/table';
import { Button } from '../../../components/ui/button';
import { Badge } from '../../../components/ui/badge';
import { StatusBadge } from '../../../components/common/status-badge';
import { MoneyAmount } from '../../../components/common/money-amount';
import { CopyableText } from '../../../components/common/copyable-text';
import { EmptyState } from '../../../components/common/empty-state';
import { LoadingState } from '../../../components/common/loading-state';
import type { Transaction } from '../types/transaction.type';
import { ActionMenu, ActionMenuItem } from '../../../components/ui/action-menu';


interface TransactionTableProps {
  transactions: Transaction[];
  isLoading: boolean;
  onViewDetails: (transaction: Transaction) => void;
}

export function TransactionTable({ transactions, isLoading, onViewDetails }: TransactionTableProps) {


  const renderTypeBadge = (type: string) => {
    switch(type) {
      case 'TOPUP': return <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">NẠP TIỀN</Badge>;
      case 'PAYMENT': return <Badge variant="outline" className="bg-indigo-50 text-indigo-700 border-indigo-200">THANH TOÁN</Badge>;
      case 'TRANSFER': return <Badge variant="outline" className="bg-purple-50 text-purple-700 border-purple-200">CHUYỂN TIỀN</Badge>;
      case 'REFUND': return <Badge variant="outline" className="bg-orange-50 text-orange-700 border-orange-200">HOÀN TIỀN</Badge>;
      default: return <Badge variant="outline">{type}</Badge>;
    }
  };

  if (isLoading) {
    return <LoadingState message="Đang tải danh sách giao dịch..." />;
  }

  if (transactions.length === 0) {
    return <EmptyState description="Không tìm thấy giao dịch nào phù hợp với điều kiện lọc." />;
  }

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Mã GD & Thời Gian</TableHead>
            <TableHead>Loại GD</TableHead>
            <TableHead className="text-right">Số tiền</TableHead>
            <TableHead>Trạng thái</TableHead>
            <TableHead>Tham chiếu (Ref)</TableHead>
            <TableHead className="text-center w-[100px]">Thao tác</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {transactions.map((tx) => (
            <TableRow key={tx.id}>
              <TableCell>
                <CopyableText text={tx.trans_code} className="font-bold text-slate-800 text-xs mb-1" />
                <p className="text-xs text-slate-500">
                  {tx.created_at ? new Date(tx.created_at).toLocaleString('vi-VN') : 'N/A'}
                </p>
              </TableCell>
              <TableCell>{renderTypeBadge(tx.trans_type)}</TableCell>
              <TableCell className="text-right">
                <MoneyAmount amount={tx.amount} />
              </TableCell>
              <TableCell>
                <StatusBadge status={tx.status} />
              </TableCell>
              <TableCell>
                <CopyableText 
                  text={tx.source_id || 'N/A'} 
                  display={tx.source_id || 'N/A'} 
                  className="text-xs text-slate-500 max-w-[150px] truncate" 
                />
              </TableCell>
              <TableCell className="text-center">
                <div className="flex justify-center">
                  <ActionMenu>
                    <ActionMenuItem 
                      icon={<Eye className="w-4 h-4" />} 
                      label="Xem chi tiết" 
                      onClick={() => onViewDetails(tx)} 
                    />
                  </ActionMenu>
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

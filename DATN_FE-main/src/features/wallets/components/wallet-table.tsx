import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../../../components/ui/table';
import { EmptyState } from '../../../components/common/empty-state';
import { LoadingState } from '../../../components/common/loading-state';
import { CopyableText } from '../../../components/common/copyable-text';
import { MoneyAmount } from '../../../components/common/money-amount';
import { Button } from '../../../components/ui/button';
import { Activity, Lock, Unlock } from 'lucide-react';
import { WalletStatusBadge } from './wallet-status-badge';
import type { Wallet } from '../types/wallet.type';
import { ActionMenu, ActionMenuItem } from '../../../components/ui/action-menu';

interface WalletTableProps {
  wallets: Wallet[];
  isLoading: boolean;
  onViewDetails: (wallet: Wallet) => void;
  onAction: (wallet: Wallet, action: 'LOCK' | 'UNLOCK') => void;
}

export function WalletTable({ wallets, isLoading, onViewDetails, onAction }: WalletTableProps) {
  if (isLoading) return <LoadingState message="Đang tải danh sách ví..." />;
  if (wallets.length === 0) return <EmptyState description="Không tìm thấy dữ liệu ví phù hợp." />;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Thông tin Ví</TableHead>
            <TableHead>Chủ sở hữu</TableHead>
            <TableHead className="text-right">Khả dụng</TableHead>
            <TableHead className="text-right">Bị giữ</TableHead>
            <TableHead className="text-center">Trạng thái</TableHead>
            <TableHead className="text-center w-[150px]">Thao tác</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {wallets.map((w) => (
            <TableRow key={w.id}>
              <TableCell>
                <CopyableText text={w.wallet_no} className="font-bold text-slate-800 font-mono" />
                <p className="text-xs text-slate-400 mt-1">
                  Tạo: {w.created_at ? new Date(w.created_at).toLocaleDateString('vi-VN') : 'N/A'}
                </p>
              </TableCell>
              <TableCell>
                <p className="font-semibold text-slate-700">{w.user?.full_name || w.full_name || 'N/A'}</p>
                <p className="text-xs text-slate-500">{w.user?.phone || w.phone || ''}</p>
              </TableCell>
              <TableCell className="text-right font-bold text-blue-600">
                <MoneyAmount amount={w.balance?.available_balance ?? w.available_balance ?? 0} />
              </TableCell>
              <TableCell className="text-right font-semibold text-orange-500">
                <MoneyAmount amount={w.balance?.locked_balance ?? w.locked_balance ?? 0} />
              </TableCell>
              <TableCell className="text-center">
                <WalletStatusBadge status={w.status} />
              </TableCell>
              <TableCell>
                <div className="flex justify-center">
                  <ActionMenu>
                    <ActionMenuItem 
                      icon={<Activity className="w-4 h-4" />} 
                      label="Xem chi tiết" 
                      onClick={() => onViewDetails(w)} 
                    />
                    {w.status === 'ACTIVE' ? (
                      <ActionMenuItem 
                        icon={<Lock className="w-4 h-4" />} 
                        label="Khóa ví" 
                        onClick={() => onAction(w, 'LOCK')} 
                        danger
                      />
                    ) : w.status !== 'CLOSED' ? (
                      <ActionMenuItem 
                        icon={<Unlock className="w-4 h-4" />} 
                        label="Mở khóa" 
                        onClick={() => onAction(w, 'UNLOCK')} 
                      />
                    ) : null}
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

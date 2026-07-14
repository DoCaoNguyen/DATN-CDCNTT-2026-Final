import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../../../components/ui/table';
import { EmptyState } from '../../../components/common/empty-state';
import { LoadingState } from '../../../components/common/loading-state';
import { MoneyAmount } from '../../../components/common/money-amount';
import { Button } from '../../../components/ui/button';
import { Lock, Unlock } from 'lucide-react';
import { UserStatusBadge } from './user-status-badge';
import type { User } from '../types/user.type';

interface UserTableProps {
  users: User[];
  isLoading: boolean;
  currentUser: any;
  onAction: (user: User, action: 'LOCK' | 'UNLOCK') => void;
}

export function UserTable({ users, isLoading, currentUser, onAction }: UserTableProps) {
  if (isLoading) return <LoadingState message="Đang tải danh sách người dùng..." />;
  if (users.length === 0) return <EmptyState description="Không tìm thấy dữ liệu." />;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Người dùng ví</TableHead>
            <TableHead>Thông tin Ví</TableHead>
            <TableHead className="text-right">Số dư</TableHead>
            <TableHead className="text-center">Trạng thái</TableHead>
            <TableHead className="text-center w-[150px]">Thao tác</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {users.map((user) => (
            <TableRow key={user.id}>
              <TableCell>
                <p className="font-bold text-slate-800">{user.full_name}</p>
                <p className="text-slate-500 font-mono text-xs mb-0.5">@{user.username || 'N/A'}</p>
                <p className="text-xs text-slate-400">{user.phone} • {user.email || 'N/A'}</p>
                {user.last_login_at && (
                  <p className="text-xs text-slate-500 mt-1">Đăng nhập: {new Date(user.last_login_at).toLocaleString('vi-VN')}</p>
                )}
              </TableCell>
              <TableCell>
                <p className="font-semibold text-slate-700">{user.wallet?.wallet_no || 'Chưa mở ví'}</p>
                <p className="text-xs text-slate-500">Tạo: {user.created_at ? new Date(user.created_at).toLocaleDateString('vi-VN') : 'N/A'}</p>
              </TableCell>
              <TableCell className="text-right font-bold text-slate-800">
                <MoneyAmount amount={user.wallet?.available_balance || 0} />
              </TableCell>
              <TableCell className="text-center">
                <UserStatusBadge status={user.status} />
              </TableCell>
              <TableCell>
                <div className="flex items-center justify-center space-x-2">
                  {currentUser && user.id === currentUser.id ? (
                    <span className="text-xs font-medium text-slate-400 bg-slate-100 px-3 py-1 rounded-full cursor-not-allowed" title="Không thể thao tác trên chính tài khoản của bạn">Tài khoản của bạn</span>
                  ) : (
                    <>
                      {user.status === 'ACTIVE' ? (
                        <Button variant="outline" size="icon" onClick={() => onAction(user, 'LOCK')} title="Khóa tài khoản" className="bg-orange-50 text-orange-600 hover:bg-orange-100 hover:text-orange-700 border-none">
                          <Lock className="w-4 h-4" />
                        </Button>
                      ) : (
                        <Button variant="outline" size="icon" onClick={() => onAction(user, 'UNLOCK')} title="Mở khóa" className="bg-emerald-50 text-emerald-600 hover:bg-emerald-100 hover:text-emerald-700 border-none">
                          <Unlock className="w-4 h-4" />
                        </Button>
                      )}
                    </>
                  )}
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

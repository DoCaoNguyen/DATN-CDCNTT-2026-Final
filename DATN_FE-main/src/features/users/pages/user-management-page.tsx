import { useState, useEffect } from 'react';
import { PageHeader } from '../../../components/common/page-header';
import { ErrorState } from '../../../components/common/error-state';
import { UserFilters } from '../components/user-filters';
import { UserTable } from '../components/user-table';
import { UserActionDialog } from '../components/user-action-dialog';
import { UserCreateDialog } from '../components/user-create-dialog';
import { useUsers } from '../hooks/use-users';
import { useLockUser, useUnlockUser } from '../hooks/use-user-actions';
import type { UserQueryParams, User } from '../types/user.type';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import toast from 'react-hot-toast';
import { Dialog, DialogHeader, DialogTitle } from '../../../components/ui/dialog';
import { Button } from '../../../components/ui/button';

export default function UserManagementPage() {
  const [filters, setFilters] = useState<UserQueryParams>({ search: '', page: 1, limit: 10 });
  const [currentUser, setCurrentUser] = useState<any>(null);
  
  useEffect(() => {
    try {
      const info = localStorage.getItem('user_info');
      if (info) setCurrentUser(JSON.parse(info));
    } catch (e) {}
  }, []);

  const { data, isLoading, isError, error, refetch } = useUsers(filters);
  const users = data?.items || [];
  const total = data?.total || 0;
  const totalPages = Math.ceil(total / (filters.limit || 10)) || 1;

  // Dialog states
  const [showCreate, setShowCreate] = useState(false);
  
  const [actionUser, setActionUser] = useState<User | null>(null);
  const [actionType, setActionType] = useState<'LOCK' | 'UNLOCK' | null>(null);

  // Temp Password display
  const [tempPassword, setTempPassword] = useState('');
  
  const lockMutation = useLockUser();
  const unlockMutation = useUnlockUser();

  const handleActionConfirm = (userId: string, reason: string) => {
    if (actionType === 'LOCK') {
      lockMutation.mutate({ userId, reason }, {
        onSuccess: () => {
          toast.success('Khóa tài khoản thành công');
          setActionUser(null);
          setActionType(null);
        },
        onError: (error: any) => {
          toast.error(error.response?.data?.error || 'Lỗi khi khóa tài khoản.');
        }
      });
    } else if (actionType === 'UNLOCK') {
      unlockMutation.mutate({ userId, reason }, {
        onSuccess: () => {
          toast.success('Mở khóa tài khoản thành công');
          setActionUser(null);
          setActionType(null);
        },
        onError: (error: any) => {
          toast.error(error.response?.data?.error || 'Lỗi khi mở khóa tài khoản.');
        }
      });
    }
  };

  const handleCreateSuccess = (password?: string) => {
    setShowCreate(false);
    if (password) {
      setTempPassword(password);
    } else {
      setFilters(prev => ({ ...prev, page: 1 }));
    }
  };

  return (
    <div className="w-full max-w-7xl mx-auto pb-10 space-y-6 animate-in fade-in duration-500">
      <PageHeader 
        title="Quản lý Người dùng ví" 
        description="Tra cứu danh sách, thêm mới và kiểm soát trạng thái người dùng ví điện tử."
      />

      <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-200">
        <UserFilters 
          initialFilters={filters} 
          onFilterChange={setFilters} 
          onCreateUser={() => setShowCreate(true)} 
        />
      </div>

      {isError ? (
        <ErrorState 
          error={error?.message || 'Có lỗi xảy ra khi tải danh sách người dùng'} 
          onRetry={() => refetch()} 
        />
      ) : (
        <div className="space-y-4">
          <UserTable 
            users={users} 
            isLoading={isLoading} 
            currentUser={currentUser}
            onAction={(user, action) => {
              setActionUser(user);
              setActionType(action);
            }} 
          />
          
          {totalPages > 1 && (
            <div className="flex justify-center items-center space-x-4 pt-2">
              <button 
                disabled={filters.page === 1} 
                onClick={() => setFilters(prev => ({ ...prev, page: (prev.page || 1) - 1 }))} 
                className="px-4 py-2 rounded-lg border bg-white text-slate-600 hover:bg-slate-100 disabled:opacity-50 text-sm font-semibold flex items-center shadow-sm"
              >
                <ChevronLeft className="w-4 h-4 mr-1" /> Trước
              </button>
              <span className="text-sm font-semibold text-slate-700">Trang {filters.page} / {totalPages}</span>
              <button 
                disabled={filters.page! >= totalPages} 
                onClick={() => setFilters(prev => ({ ...prev, page: (prev.page || 1) + 1 }))} 
                className="px-4 py-2 rounded-lg border bg-white text-slate-600 hover:bg-slate-100 disabled:opacity-50 text-sm font-semibold flex items-center shadow-sm"
              >
                Sau <ChevronRight className="w-4 h-4 ml-1" />
              </button>
            </div>
          )}
        </div>
      )}

      {/* Dialogs */}
      <UserCreateDialog 
        open={showCreate} 
        onClose={() => setShowCreate(false)} 
        onSuccess={handleCreateSuccess} 
      />

      <UserActionDialog 
        user={actionType === 'LOCK' || actionType === 'UNLOCK' ? actionUser : null}
        action={actionType === 'LOCK' || actionType === 'UNLOCK' ? actionType : null}
        open={actionType === 'LOCK' || actionType === 'UNLOCK'}
        onClose={() => {
          setActionUser(null);
          setActionType(null);
        }}
        onConfirm={handleActionConfirm}
        isProcessing={lockMutation.isPending || unlockMutation.isPending}
      />

      {/* Temp Password Dialog */}
      <Dialog open={!!tempPassword} onClose={() => {}}>
        <DialogHeader>
          <DialogTitle>Tạo tài khoản thành công!</DialogTitle>
        </DialogHeader>
        <div className="py-4 text-center">
          <p className="text-sm text-slate-500 mb-4">Mật khẩu tạm thời chỉ được hiển thị <span className="font-bold text-red-500">MỘT LẦN DUY NHẤT</span>. Vui lòng sao chép lại ngay.</p>
          <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 mb-4 break-all font-mono text-lg font-bold text-indigo-600">
            {tempPassword}
          </div>
          <Button 
            onClick={() => { navigator.clipboard.writeText(tempPassword); toast.success('Đã copy!'); }}
            variant="outline"
            className="text-indigo-700 border-indigo-200 hover:bg-indigo-50"
          >
            Copy Mật Khẩu
          </Button>
        </div>
        <div className="flex justify-end border-t border-slate-100 pt-4">
          <Button onClick={() => {
            setTempPassword('');
            setFilters(prev => ({ ...prev, page: 1 }));
          }} className="bg-blue-600 hover:bg-blue-700 text-white">
            Đóng
          </Button>
        </div>
      </Dialog>
    </div>
  );
}

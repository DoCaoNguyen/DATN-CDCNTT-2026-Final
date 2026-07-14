import { useState } from 'react';
import { Dialog, DialogHeader, DialogTitle, DialogFooter } from '../../../components/ui/dialog';
import { Button } from '../../../components/ui/button';
import { Textarea } from '../../../components/ui/textarea';
import type { User } from '../types/user.type';

interface UserActionDialogProps {
  user: User | null;
  action: 'LOCK' | 'UNLOCK' | null;
  open: boolean;
  onClose: () => void;
  onConfirm: (userId: string, reason: string) => void;
  isProcessing: boolean;
}

export function UserActionDialog({ user, action, open, onClose, onConfirm, isProcessing }: UserActionDialogProps) {
  const [reason, setReason] = useState('');

  if (!user || !action) return null;

  const handleConfirm = () => {
    onConfirm(user.id, reason);
  };

  const isLock = action === 'LOCK';

  return (
    <Dialog open={open} onClose={() => {
      setReason('');
      onClose();
    }}>
      <DialogHeader>
        <DialogTitle>{isLock ? 'Khóa tài khoản hệ thống' : 'Mở khóa tài khoản'}</DialogTitle>
      </DialogHeader>

      <div className="py-4 space-y-4">
        <p className="text-sm text-slate-600">
          Người dùng: <span className="font-bold text-slate-800">{user.full_name}</span>
        </p>

        <div className="space-y-2">
          <label className="text-sm font-semibold text-slate-700">
            {isLock ? 'Lý do khóa (Bắt buộc)' : 'Lý do mở khóa (Bắt buộc)'} <span className="text-red-500">*</span>
          </label>
          <Textarea 
            value={reason} 
            onChange={(e) => setReason(e.target.value)} 
            placeholder="Nhập lý do..." 
            rows={3}
          />
        </div>
      </div>

      <DialogFooter>
        <Button variant="outline" onClick={() => {
          setReason('');
          onClose();
        }}>
          Hủy
        </Button>
        <Button 
          variant={isLock ? 'danger' : 'primary'}
          className={!isLock ? 'bg-emerald-600 hover:bg-emerald-700 text-white' : ''}
          onClick={handleConfirm}
          disabled={isProcessing || !reason.trim()}
        >
          {isProcessing ? 'Đang xử lý...' : (isLock ? 'Xác nhận khóa' : 'Xác nhận mở khóa')}
        </Button>
      </DialogFooter>
    </Dialog>
  );
}

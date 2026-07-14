import { useState } from 'react';
import { Dialog, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { Button } from '../ui/button';
import { Textarea } from '../ui/textarea';

interface ReasonDialogProps {
  open: boolean;
  onClose: () => void;
  onConfirm: (reason: string) => void;
  title: string;
  description: string;
  isLoading?: boolean;
}

export function ReasonDialog({ open, onClose, onConfirm, title, description, isLoading }: ReasonDialogProps) {
  const [reason, setReason] = useState('');

  const handleConfirm = () => {
    if (reason.trim()) {
      onConfirm(reason.trim());
      setReason('');
    }
  };

  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <DialogTitle>{title}</DialogTitle>
      </DialogHeader>
      <div className="py-4 space-y-4">
        <p className="text-slate-600 text-sm">{description}</p>
        <Textarea 
          placeholder="Nhập lý do thực hiện..." 
          value={reason} 
          onChange={(e) => setReason(e.target.value)}
        />
      </div>
      <DialogFooter>
        <Button variant="outline" onClick={onClose} disabled={isLoading}>Hủy</Button>
        <Button variant="primary" onClick={handleConfirm} disabled={isLoading || !reason.trim()}>
          {isLoading ? 'Đang xử lý...' : 'Xác nhận'}
        </Button>
      </DialogFooter>
    </Dialog>
  );
}

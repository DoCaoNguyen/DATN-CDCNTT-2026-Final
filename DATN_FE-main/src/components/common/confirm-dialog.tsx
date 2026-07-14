import { Dialog, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { Button } from '../ui/button';

interface ConfirmDialogProps {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  description: string;
  confirmText?: string;
  cancelText?: string;
  variant?: 'danger' | 'primary';
  isLoading?: boolean;
}

export function ConfirmDialog({ open, onClose, onConfirm, title, description, confirmText = 'Xác nhận', cancelText = 'Hủy', variant = 'primary', isLoading }: ConfirmDialogProps) {
  return (
    <Dialog open={open} onClose={onClose}>
      <DialogHeader>
        <DialogTitle>{title}</DialogTitle>
      </DialogHeader>
      <div className="py-4">
        <p className="text-slate-600">{description}</p>
      </div>
      <DialogFooter>
        <Button variant="outline" onClick={onClose} disabled={isLoading}>{cancelText}</Button>
        <Button variant={variant} onClick={onConfirm} disabled={isLoading}>
          {isLoading ? 'Đang xử lý...' : confirmText}
        </Button>
      </DialogFooter>
    </Dialog>
  );
}

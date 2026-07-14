
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Dialog, DialogHeader, DialogTitle } from '../../../components/ui/dialog';
import { Button } from '../../../components/ui/button';
import { Input } from '../../../components/ui/input';
import { createUserSchema, type CreateUserFormValues } from '../schemas/user.schema';
import { useCreateWalletUser } from '../hooks/use-user-actions';
import toast from 'react-hot-toast';
import { Loader2 } from 'lucide-react';

interface UserCreateDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: (tempPassword?: string) => void;
}

export function UserCreateDialog({ open, onClose, onSuccess }: UserCreateDialogProps) {
  const { register, handleSubmit, formState: { errors }, reset } = useForm<CreateUserFormValues>({
    resolver: zodResolver(createUserSchema)
  });

  const createMutation = useCreateWalletUser();

  const onSubmit = (data: CreateUserFormValues) => {
    createMutation.mutate(data, {
      onSuccess: (res: any) => {
        toast.success('Thêm Người dùng ví thành công');
        const tempPass = res.data?.temporary_password || res.temporary_password;
        reset();
        onSuccess(tempPass);
      },
      onError: (error: any) => {
        toast.error(error.response?.data?.error || 'Lỗi khi tạo user');
      }
    });
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose}>
      <DialogHeader>
        <DialogTitle>Thêm Người dùng ví (Wallet User)</DialogTitle>
      </DialogHeader>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4 py-4">
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <label className="text-sm font-semibold text-slate-700">Username <span className="text-red-500">*</span></label>
            <Input {...register('username')} placeholder="Tên đăng nhập" />
            {errors.username && <p className="text-red-500 text-xs">{errors.username.message}</p>}
          </div>
          <div className="space-y-1">
            <label className="text-sm font-semibold text-slate-700">Họ và tên <span className="text-red-500">*</span></label>
            <Input {...register('full_name')} placeholder="Họ và tên đầy đủ" />
            {errors.full_name && <p className="text-red-500 text-xs">{errors.full_name.message}</p>}
          </div>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <label className="text-sm font-semibold text-slate-700">Số điện thoại <span className="text-red-500">*</span></label>
            <Input {...register('phone')} placeholder="09xxxxxxxx" />
            {errors.phone && <p className="text-red-500 text-xs">{errors.phone.message}</p>}
          </div>
          <div className="space-y-1">
            <label className="text-sm font-semibold text-slate-700">Email</label>
            <Input {...register('email')} type="email" placeholder="example@email.com" />
            {errors.email && <p className="text-red-500 text-xs">{errors.email.message}</p>}
          </div>
        </div>

        <div className="flex justify-end space-x-3 pt-4 border-t border-slate-100">
          <Button type="button" variant="outline" onClick={handleClose}>
            Hủy bỏ
          </Button>
          <Button type="submit" disabled={createMutation.isPending} className="bg-blue-600 hover:bg-blue-700">
            {createMutation.isPending && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
            Xác nhận Tạo
          </Button>
        </div>
      </form>
    </Dialog>
  );
}

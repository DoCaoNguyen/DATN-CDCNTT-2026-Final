import { AlertCircle } from 'lucide-react';
import { Button } from '../ui/button';

export function ErrorState({ error, onRetry }: { error?: string, onRetry?: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center p-8 text-center border border-red-100 rounded-lg bg-red-50/50">
      <AlertCircle className="w-10 h-10 text-red-500 mb-4" />
      <h3 className="text-lg font-semibold text-slate-900">Đã xảy ra lỗi</h3>
      <p className="text-sm text-slate-600 mt-1 mb-4">{error || "Không thể tải dữ liệu. Vui lòng thử lại sau."}</p>
      {onRetry && <Button variant="outline" onClick={onRetry}>Thử lại</Button>}
    </div>
  );
}

import { Inbox } from 'lucide-react';

export function EmptyState({ title = "Không có dữ liệu", description = "Chưa có bản ghi nào được tìm thấy." }: { title?: string, description?: string }) {
  return (
    <div className="flex flex-col items-center justify-center p-8 text-center border rounded-lg border-dashed bg-slate-50/50">
      <div className="flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-4">
        <Inbox className="w-6 h-6 text-slate-400" />
      </div>
      <h3 className="text-lg font-semibold text-slate-900">{title}</h3>
      <p className="text-sm text-slate-500 mt-1">{description}</p>
    </div>
  );
}

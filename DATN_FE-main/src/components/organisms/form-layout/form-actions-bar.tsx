
import { Loader2 } from 'lucide-react';

interface FormActionsBarProps {
  onCancel: () => void;
  onSubmit: () => void;
  isProcessing?: boolean;
  submitText?: string;
  cancelText?: string;
}

export function FormActionsBar({ 
  onCancel, 
  onSubmit, 
  isProcessing = false,
  submitText = 'Lưu thay đổi',
  cancelText = 'Hủy bỏ'
}: FormActionsBarProps) {
  return (
    <div className="flex items-center justify-end space-x-4 pt-6 mt-6 border-t border-slate-200">
      <button 
        type="button" 
        onClick={onCancel}
        disabled={isProcessing}
        className="px-5 py-2.5 font-semibold text-slate-600 hover:bg-slate-100 rounded-xl transition-colors text-sm"
      >
        {cancelText}
      </button>
      <button 
        type="button" 
        onClick={onSubmit}
        disabled={isProcessing}
        className="px-6 py-2.5 bg-indigo-600 text-white font-semibold flex items-center justify-center rounded-xl hover:bg-indigo-700 disabled:opacity-50 transition-colors text-sm shadow-sm shadow-indigo-500/20"
      >
        {isProcessing && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
        {submitText}
      </button>
    </div>
  );
}

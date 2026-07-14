import type { ReactNode } from 'react';

interface FormSectionCardProps {
  title: string;
  description?: string;
  children: ReactNode;
}

export function FormSectionCard({ title, description, children }: FormSectionCardProps) {
  return (
    <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
      <div className="px-6 py-5 border-b border-slate-100 bg-slate-50/50">
        <h3 className="text-lg font-bold text-slate-800">{title}</h3>
        {description && <p className="text-sm text-slate-500 mt-1">{description}</p>}
      </div>
      <div className="p-6">
        {children}
      </div>
    </div>
  );
}

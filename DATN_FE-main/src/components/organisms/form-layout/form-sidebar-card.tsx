import type { ReactNode } from 'react';

interface FormSidebarCardProps {
  title: string;
  children: ReactNode;
}

export function FormSidebarCard({ title, children }: FormSidebarCardProps) {
  return (
    <div className="bg-white border border-slate-200 rounded-2xl shadow-sm overflow-hidden">
      <div className="px-5 py-4 border-b border-slate-100 bg-slate-50/50">
        <h4 className="font-semibold text-slate-800">{title}</h4>
      </div>
      <div className="p-5">
        {children}
      </div>
    </div>
  );
}

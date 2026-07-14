import React from 'react';

export function AdminShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen w-full bg-slate-50 overflow-hidden text-slate-900 font-sans">
      {children}
    </div>
  );
}

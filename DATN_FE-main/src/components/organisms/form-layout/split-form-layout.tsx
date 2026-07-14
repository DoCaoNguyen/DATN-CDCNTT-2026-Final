import type { ReactNode } from 'react';

export function SplitFormLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex flex-col lg:flex-row gap-6">
      {children}
    </div>
  );
}

export function SplitFormMain({ children }: { children: ReactNode }) {
  return (
    <div className="flex-1 space-y-6">
      {children}
    </div>
  );
}

export function SplitFormSidebar({ children }: { children: ReactNode }) {
  return (
    <div className="w-full lg:w-1/3 xl:w-1/4 space-y-6 shrink-0">
      {children}
    </div>
  );
}

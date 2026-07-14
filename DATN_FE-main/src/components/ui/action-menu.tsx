import React, { useState, useRef, useEffect } from 'react';
import { MoreVertical } from 'lucide-react';

interface ActionMenuProps {
  children: React.ReactNode;
}

export function ActionMenu({ children }: ActionMenuProps) {
  const [open, setOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="relative inline-block text-left" ref={menuRef}>
      <button 
        onClick={(e) => { e.stopPropagation(); setOpen(!open); }} 
        className="p-1.5 text-slate-500 hover:text-slate-800 hover:bg-slate-100 rounded-lg transition-colors focus:outline-none"
      >
        <MoreVertical className="w-5 h-5" />
      </button>

      {open && (
        <div className="absolute right-0 z-50 mt-1 min-w-[220px] origin-top-right bg-white border border-slate-200 rounded-lg shadow-lg py-1 ring-1 ring-black ring-opacity-5">
          {React.Children.map(children, child => {
            if (React.isValidElement(child)) {
              return React.cloneElement(child, {
                onClick: (e: any) => {
                  setOpen(false);
                  if (child.props.onClick) child.props.onClick(e);
                }
              } as any);
            }
            return child;
          })}
        </div>
      )}
    </div>
  );
}

export function ActionMenuItem({ icon, label, onClick, danger }: { icon?: React.ReactNode, label: string, onClick?: () => void, danger?: boolean }) {
  return (
    <button
      onClick={(e) => {
        e.stopPropagation();
        if (onClick) onClick();
      }}
      className={`w-full text-left px-4 py-2.5 text-sm flex items-center transition-colors ${
        danger 
          ? 'text-red-600 hover:bg-red-50' 
          : 'text-slate-700 hover:bg-slate-50 hover:text-blue-600'
      }`}
    >
      {icon && <span className="mr-2 w-4 h-4 flex items-center justify-center">{icon}</span>}
      {label}
    </button>
  );
}

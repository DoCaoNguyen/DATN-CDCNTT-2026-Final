import React from 'react';
import { cn } from './button';

export interface BadgeProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'outline';
}

export function Badge({ className, variant = "default", ...props }: BadgeProps) {
  const baseStyle = "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-blue-600 focus:ring-offset-2";
  const variants = {
    default: "border-transparent bg-slate-900 text-white",
    success: "border-transparent bg-green-100 text-green-800",
    warning: "border-transparent bg-yellow-100 text-yellow-800",
    danger: "border-transparent bg-red-100 text-red-800",
    outline: "text-slate-950",
  };
  
  return (
    <div className={cn(baseStyle, variants[variant], className)} {...props} />
  );
}

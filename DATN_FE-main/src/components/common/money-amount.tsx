import { cn } from '../ui/button';

export function MoneyAmount({ amount, currency = 'VND', className }: { amount: number, currency?: string, className?: string }) {
  const formatted = new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: currency,
  }).format(amount);

  const isNegative = amount < 0;

  return (
    <span className={cn("font-medium font-mono tabular-nums", isNegative ? "text-red-600" : "text-slate-900", className)}>
      {formatted}
    </span>
  );
}

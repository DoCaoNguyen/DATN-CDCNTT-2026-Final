import { useState } from 'react';
import { Copy, Check } from 'lucide-react';
import { cn } from '../ui/button';

export function CopyableText({ text, display, className }: { text: string, display?: string, className?: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className={cn("flex items-center space-x-2 group cursor-pointer", className)} onClick={handleCopy}>
      <span className="font-mono text-sm">{display || text}</span>
      {copied ? (
        <Check className="h-4 w-4 text-green-600" />
      ) : (
        <Copy className="h-4 w-4 text-slate-400 opacity-0 group-hover:opacity-100 transition-opacity" />
      )}
    </div>
  );
}

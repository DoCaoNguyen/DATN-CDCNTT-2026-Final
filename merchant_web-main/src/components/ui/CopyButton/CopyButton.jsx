import { useState } from 'react';
import { Copy, Check } from 'lucide-react';

export const CopyButton = ({ text, tooltip = 'Sao chép', size = 16 }) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy', err);
    }
  };

  return (
    <button
      type="button"
      onClick={handleCopy}
      title={copied ? 'Đã sao chép!' : tooltip}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '0.25rem',
        borderRadius: 'var(--radius-sm)',
        color: copied ? 'var(--status-active)' : 'var(--text-muted)',
        transition: 'all 0.2s'
      }}
      onMouseEnter={(e) => !copied && (e.currentTarget.style.backgroundColor = 'var(--bg-main)')}
      onMouseLeave={(e) => !copied && (e.currentTarget.style.backgroundColor = 'transparent')}
    >
      {copied ? <Check size={size} /> : <Copy size={size} />}
    </button>
  );
};

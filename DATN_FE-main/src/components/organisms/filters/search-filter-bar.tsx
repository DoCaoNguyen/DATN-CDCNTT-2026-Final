import React from 'react';
import { Search } from 'lucide-react';
import { Button } from '../../ui/button';

interface FilterOption {
  label: string;
  value: string;
}

interface SearchFilterBarProps {
  searchPlaceholder?: string;
  searchValue: string;
  onSearchChange: (value: string) => void;
  statusOptions?: FilterOption[];
  statusValue?: string;
  onStatusChange?: (value: string) => void;
  typeOptions?: FilterOption[];
  typeValue?: string;
  onTypeChange?: (value: string) => void;
  onReset?: () => void;
}

export function SearchFilterBar({
  searchPlaceholder = 'Tìm kiếm...',
  searchValue,
  onSearchChange,
  statusOptions,
  statusValue,
  onStatusChange,
  typeOptions,
  typeValue,
  onTypeChange,
  onReset
}: SearchFilterBarProps) {
  const [localSearch, setLocalSearch] = React.useState(searchValue);

  React.useEffect(() => {
    setLocalSearch(searchValue);
  }, [searchValue]);

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setLocalSearch(e.target.value);
    onSearchChange(e.target.value);
  };

  return (
    <div className="flex items-center space-x-3 flex-wrap gap-y-3">
      {typeOptions && onTypeChange && (
        <select
          value={typeValue || ''}
          onChange={(e) => onTypeChange(e.target.value)}
          className="p-2 border border-slate-200 rounded-lg outline-none focus:ring-2 focus:ring-blue-500/20 text-sm"
        >
          {typeOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      )}

      {statusOptions && onStatusChange && (
        <select
          value={statusValue || ''}
          onChange={(e) => onStatusChange(e.target.value)}
          className="p-2 border border-slate-200 rounded-lg outline-none focus:ring-2 focus:ring-blue-500/20 text-sm"
        >
          {statusOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      )}

      <div className="relative">
        <Search className="w-5 h-5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
        <input
          type="text"
          placeholder={searchPlaceholder}
          value={localSearch}
          onChange={handleSearchChange}
          className="pl-10 pr-4 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 w-60 text-sm"
        />
      </div>

      {onReset && (
        <Button variant="outline" onClick={onReset}>
          Đặt lại
        </Button>
      )}
    </div>
  );
}

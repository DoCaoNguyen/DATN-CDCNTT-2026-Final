import { useState } from 'react';
import { Search } from 'lucide-react';
import { Button } from '../../../components/ui/button';
import { Input } from '../../../components/ui/input';
import { TRANSACTION_TYPES, TRANSACTION_STATUSES } from '../constants/transaction.constant';
import type { TransactionQueryParams } from '../types/transaction.type';

interface TransactionFiltersProps {
  initialFilters: TransactionQueryParams;
  onFilterChange: (filters: TransactionQueryParams) => void;
}

export function TransactionFilters({ initialFilters, onFilterChange }: TransactionFiltersProps) {
  const [searchTerm, setSearchTerm] = useState(initialFilters.search || '');
  const [filterType, setFilterType] = useState(initialFilters.type || '');
  const [filterStatus, setFilterStatus] = useState(initialFilters.status || '');

  const handleApply = () => {
    onFilterChange({
      search: searchTerm,
      type: filterType,
      status: filterStatus,
    });
  };

  return (
    <div className="flex flex-col sm:flex-row gap-3 items-center w-full">
      <div className="relative w-full sm:w-64">
        <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
        <Input 
          placeholder="Mã GD, Mã đối chiếu..." 
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleApply()}
          className="pl-9"
        />
      </div>

      <select 
        value={filterType} 
        onChange={(e) => setFilterType(e.target.value)} 
        className="flex h-10 w-full sm:w-48 rounded-md border border-slate-300 bg-transparent px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-600"
      >
        <option value="">Tất cả Loại GD</option>
        {TRANSACTION_TYPES.map(type => (
          <option key={type.value} value={type.value}>{type.label}</option>
        ))}
      </select>

      <select 
        value={filterStatus} 
        onChange={(e) => setFilterStatus(e.target.value)} 
        className="flex h-10 w-full sm:w-48 rounded-md border border-slate-300 bg-transparent px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-600"
      >
        <option value="">Tất cả Trạng thái</option>
        {TRANSACTION_STATUSES.map(status => (
          <option key={status.value} value={status.value}>{status.label}</option>
        ))}
      </select>

      <Button onClick={handleApply} className="w-full sm:w-auto">
        Lọc
      </Button>
    </div>
  );
}

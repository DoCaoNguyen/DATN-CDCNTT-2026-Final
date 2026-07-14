import { useState } from 'react';
import { Search } from 'lucide-react';
import { Input } from '../../../components/ui/input';
import { Button } from '../../../components/ui/button';
import type { WalletQueryParams } from '../types/wallet.type';

interface WalletFiltersProps {
  initialFilters: WalletQueryParams;
  onFilterChange: (filters: WalletQueryParams) => void;
}

export function WalletFilters({ initialFilters, onFilterChange }: WalletFiltersProps) {
  const [searchTerm, setSearchTerm] = useState(initialFilters.search || '');

  const handleApply = () => {
    onFilterChange({
      search: searchTerm,
      page: 1, // Reset page when searching
    });
  };

  return (
    <div className="flex flex-col sm:flex-row gap-3 items-center w-full">
      <div className="relative w-full sm:w-80">
        <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
        <Input 
          placeholder="Mã ví, Tên chủ sở hữu, SĐT..." 
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleApply()}
          className="pl-9"
        />
      </div>
      <Button onClick={handleApply} className="w-full sm:w-auto">
        Tìm kiếm
      </Button>
    </div>
  );
}

import { useState } from 'react';
import { Search, Plus } from 'lucide-react';
import { Input } from '../../../components/ui/input';
import { Button } from '../../../components/ui/button';
import type { MerchantQueryParams } from '../types/merchant.type';

interface MerchantFiltersProps {
  initialFilters: MerchantQueryParams;
  onFilterChange: (filters: MerchantQueryParams) => void;
  onCreateMerchant: () => void;
}

export function MerchantFilters({ initialFilters, onFilterChange, onCreateMerchant }: MerchantFiltersProps) {
  const [searchTerm, setSearchTerm] = useState(initialFilters.search || '');

  const handleApply = () => {
    onFilterChange({
      search: searchTerm,
      page: 1, // Reset page when searching
    });
  };

  return (
    <div className="flex flex-col sm:flex-row gap-3 items-center w-full justify-between">
      <div className="flex flex-col sm:flex-row gap-3 items-center w-full sm:w-auto">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <Input 
            placeholder="Tên cửa hàng..." 
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

      <Button onClick={onCreateMerchant} className="w-full sm:w-auto bg-blue-600 hover:bg-blue-700 text-white">
        <Plus className="w-4 h-4 mr-2" />
        Đăng ký Merchant
      </Button>
    </div>
  );
}

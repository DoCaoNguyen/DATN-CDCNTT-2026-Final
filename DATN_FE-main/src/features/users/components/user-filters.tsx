import { useState } from 'react';
import { Search, UserPlus } from 'lucide-react';
import { Input } from '../../../components/ui/input';
import { Button } from '../../../components/ui/button';
import type { UserQueryParams } from '../types/user.type';

interface UserFiltersProps {
  initialFilters: UserQueryParams;
  onFilterChange: (filters: UserQueryParams) => void;
  onCreateUser: () => void;
}

export function UserFilters({ initialFilters, onFilterChange, onCreateUser }: UserFiltersProps) {
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
            placeholder="Tên, Username, SĐT..." 
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

      <Button onClick={onCreateUser} className="w-full sm:w-auto bg-blue-600 hover:bg-blue-700 text-white">
        <UserPlus className="w-4 h-4 mr-2" />
        Tạo Người dùng (Wallet User)
      </Button>
    </div>
  );
}

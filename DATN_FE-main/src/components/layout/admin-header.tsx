import { useState, useRef, useEffect } from 'react';
import { Menu, Bell, User, LogOut } from 'lucide-react';
import { Button } from '../ui/button';
import { useNavigate } from 'react-router-dom';

export function AdminHeader({ toggleSidebar }: { toggleSidebar: () => void }) {
  const handleLogout = () => {
    localStorage.clear();
    window.location.href = '/login';
  };

  const getUserInfo = () => {
    try {
      const userInfoStr = localStorage.getItem('user_info');
      if (userInfoStr) {
        return JSON.parse(userInfoStr);
      }
    } catch (e) {
      console.error('Lỗi parse user_info', e);
    }
    return null;
  };

  const user = getUserInfo();
  const navigate = useNavigate();
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <header className="flex h-16 shrink-0 items-center justify-between border-b bg-white px-4 md:px-6 z-10 shadow-sm">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={toggleSidebar} className="md:hidden">
          <Menu className="h-5 w-5" />
        </Button>
      </div>
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon">
          <Bell className="h-5 w-5 text-slate-500" />
        </Button>
        <div className="flex items-center gap-2 border-l pl-4 relative" ref={dropdownRef}>
          <div className="flex flex-col items-end hidden sm:flex">
            <span className="text-sm font-medium">{user?.full_name || user?.username || 'Admin User'}</span>
            <span className="text-xs text-slate-500">{user?.roles?.[0] || 'Superadmin'}</span>
          </div>
          <Button variant="ghost" size="icon" onClick={() => setIsDropdownOpen(!isDropdownOpen)} className={isDropdownOpen ? 'bg-slate-100' : ''}>
            <User className="h-5 w-5 text-slate-600" />
          </Button>

          {isDropdownOpen && (
            <div className="absolute top-full right-0 mt-2 w-48 bg-white border border-slate-200 rounded-lg shadow-lg py-1 z-50">
              <button 
                onClick={() => { setIsDropdownOpen(false); navigate('/admin/profile'); }} 
                className="w-full text-left px-4 py-2.5 text-sm text-slate-700 hover:bg-slate-50 hover:text-blue-600 flex items-center transition-colors"
              >
                <User className="w-4 h-4 mr-2" /> Thông tin cá nhân
              </button>
              <button 
                onClick={handleLogout} 
                className="w-full text-left px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 flex items-center border-t border-slate-100 mt-1 transition-colors"
              >
                <LogOut className="w-4 h-4 mr-2" /> Đăng xuất
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}

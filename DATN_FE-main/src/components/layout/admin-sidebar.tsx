import { useState, useEffect } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { SIDEBAR_CONFIG } from '../../config/sidebar';
import type { SidebarMenu } from '../../config/sidebar';
import * as Icons from 'lucide-react';

function getIcon(name: string) {
  return (Icons as any)[name] || Icons.Circle;
}

// Menu đơn (flat) — không có sub-items
function FlatMenuItem({ menu, closeSidebar }: { menu: SidebarMenu; closeSidebar: () => void }) {
  const Icon = getIcon(menu.icon);
  return (
    <NavLink
      to={menu.path!}
      onClick={() => { if (window.innerWidth < 768) closeSidebar(); }}
      className={({ isActive }) =>
        `flex items-center gap-3 px-3 py-2 rounded-md text-sm transition-colors ${
          isActive
            ? 'bg-gray-100 text-gray-900 font-semibold'
            : 'text-gray-700 hover:bg-gray-50'
        }`
      }
    >
      <Icon className="w-[18px] h-[18px] shrink-0" />
      <span>{menu.name}</span>
    </NavLink>
  );
}

// Menu có sub-items — đóng mở chevron
function ExpandableMenuItem({
  menu,
  closeSidebar,
}: {
  menu: SidebarMenu;
  closeSidebar: () => void;
}) {
  const location = useLocation();
  const isChildActive = menu.items?.some((item) => {
    const pathWithoutQuery = item.path.split('?')[0];
    return location.pathname === pathWithoutQuery || location.pathname.startsWith(pathWithoutQuery + '/');
  }) ?? false;
  const [isOpen, setIsOpen] = useState(isChildActive);

  // Tự mở khi navigate vào child route
  useEffect(() => {
    if (isChildActive && !isOpen) setIsOpen(true);
  }, [isChildActive]);

  const Icon = getIcon(menu.icon);

  return (
    <div>
      {/* Header button */}
      <button
        onClick={() => setIsOpen((prev) => !prev)}
        className={`w-full flex items-center justify-between px-3 py-2 rounded-md text-sm transition-colors ${
          isChildActive ? 'bg-gray-100 text-gray-900 font-semibold' : 'text-gray-700 hover:bg-gray-50'
        }`}
      >
        <span className="flex items-center gap-3">
          <Icon className="w-[18px] h-[18px] shrink-0" />
          <span>{menu.name}</span>
        </span>
        <Icons.ChevronDown
          className={`w-4 h-4 text-gray-400 transition-transform duration-200 ${
            isOpen ? 'rotate-0' : '-rotate-90'
          }`}
        />
      </button>

      {/* Sub-items */}
      <div
        className={`overflow-hidden transition-all duration-200 ease-in-out ${
          isOpen ? 'max-h-[500px] opacity-100' : 'max-h-0 opacity-0'
        }`}
      >
        <div className="ml-[30px] mt-0.5 space-y-0.5">
          {menu.items!.map((item) => {
            const hasQuery = item.path.includes('?');
            let isItemActive = false;
            
            if (hasQuery) {
              const [path, query] = item.path.split('?');
              const itemParams = new URLSearchParams(query);
              const currentParams = new URLSearchParams(location.search);
              
              isItemActive = location.pathname === path;
              for (const [key, value] of itemParams.entries()) {
                if (currentParams.get(key) !== value) {
                  if (location.pathname === '/admin/reports' && key === 'type' && !currentParams.get('type') && value === 'topups') {
                     // Default tab logic
                  } else {
                     isItemActive = false;
                  }
                }
              }
            } else {
              isItemActive = location.pathname === item.path || location.pathname.startsWith(item.path + '/');
            }

            return (
              <NavLink
                key={item.path}
                to={item.path}
                onClick={() => { if (window.innerWidth < 768) closeSidebar(); }}
                className={({ isActive }) => {
                  const finalIsActive = hasQuery ? isItemActive : isActive;
                  return `block px-3 py-1.5 rounded-md text-sm transition-colors ${
                    finalIsActive
                      ? 'text-gray-900 font-medium bg-gray-100'
                      : 'text-gray-500 hover:text-gray-800 hover:bg-gray-50'
                  }`;
                }}
              >
                {item.name}
              </NavLink>
            );
          })}
        </div>
      </div>
    </div>
  );
}

export function AdminSidebar({ isOpen, closeSidebar }: { isOpen: boolean; closeSidebar: () => void }) {
  return (
    <>
      {/* Mobile overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/30 md:hidden"
          onClick={closeSidebar}
        />
      )}

      <aside
        className={`fixed inset-y-0 left-0 z-50 w-60 bg-white border-r border-gray-200 transition-transform duration-300 ease-in-out md:static md:translate-x-0 flex flex-col ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Logo */}
        <div className="flex items-center gap-2.5 h-14 px-5 border-b border-gray-200 shrink-0">
          <Icons.Wallet className="w-6 h-6 text-blue-600" />
          <span className="text-base font-bold text-gray-900 tracking-tight">E-Wallet</span>
        </div>

        {/* Menu */}
        <nav className="flex-1 overflow-y-auto py-4 px-3 space-y-5">
          {SIDEBAR_CONFIG.map((section) => (
            <div key={section.section}>
              {/* Section label */}
              <p className="px-3 mb-2 text-xs font-semibold text-amber-600 uppercase tracking-wider">
                {section.section}
              </p>

              <div className="space-y-0.5">
                {section.menus.map((menu) =>
                  menu.path ? (
                    <FlatMenuItem key={menu.path} menu={menu} closeSidebar={closeSidebar} />
                  ) : (
                    <ExpandableMenuItem key={menu.name} menu={menu} closeSidebar={closeSidebar} />
                  )
                )}
              </div>
            </div>
          ))}
        </nav>
      </aside>
    </>
  );
}

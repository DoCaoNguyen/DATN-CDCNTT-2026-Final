import { useLocation, Link } from 'react-router-dom';
import { ChevronRight, Home } from 'lucide-react';
import { ROUTES } from '../../config/routes';
import { SIDEBAR_CONFIG } from '../../config/sidebar';

export function AdminBreadcrumb() {
  const location = useLocation();
  const paths = location.pathname.split('/').filter(Boolean);
  
  // Flatten sidebar config (section → menus → items) để tìm title
  const flatMenu = SIDEBAR_CONFIG.flatMap(section =>
    section.menus.flatMap(menu =>
      menu.path
        ? [{ name: menu.name, path: menu.path }]
        : (menu.items || [])
    )
  );
  const currentMenu = flatMenu.find(item => item.path === location.pathname);

  return (
    <nav className="flex items-center text-sm font-medium text-slate-500 mb-4 px-1">
      <Link to={ROUTES.DASHBOARD} className="hover:text-blue-600 flex items-center transition-colors">
        <Home className="h-4 w-4" />
      </Link>
      
      {paths.length > 1 && (
        <>
          <ChevronRight className="h-4 w-4 mx-1" />
          <span className="text-slate-900 capitalize">
            {currentMenu ? currentMenu.name : paths[paths.length - 1]}
          </span>
        </>
      )}
    </nav>
  );
}

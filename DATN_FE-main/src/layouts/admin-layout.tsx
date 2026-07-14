import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { AdminShell } from '../components/layout/admin-shell';
import { AdminSidebar } from '../components/layout/admin-sidebar';
import { AdminHeader } from '../components/layout/admin-header';

export default function AdminLayout() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  const toggleSidebar = () => setIsSidebarOpen(!isSidebarOpen);
  const closeSidebar = () => setIsSidebarOpen(false);

  return (
    <AdminShell>
      <AdminSidebar isOpen={isSidebarOpen} closeSidebar={closeSidebar} />
      <div className="flex-1 flex flex-col h-full overflow-hidden">
        <AdminHeader toggleSidebar={toggleSidebar} />
        <main className="flex-1 overflow-y-auto p-4 md:p-6 lg:p-8 relative bg-slate-50">
          <Outlet />
        </main>
      </div>
    </AdminShell>
  );
}
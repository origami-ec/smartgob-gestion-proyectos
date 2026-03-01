import { NavLink } from 'react-router-dom';
import { useAppStore } from '@/store/appStore';
import { useAuth } from '@/hooks/useAuth';
import { LayoutDashboard, Columns3, ListTodo, ClipboardCheck, ChevronLeft, ChevronRight } from 'lucide-react';
import clsx from 'clsx';

const LINKS = [
  { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/kanban', label: 'Kanban', icon: Columns3 },
  { to: '/tareas', label: 'Tareas', icon: ListTodo },
  { to: '/mis-tareas', label: 'Mis Tareas', icon: ClipboardCheck },
];

export default function Sidebar() {
  const { sidebarOpen, toggleSidebar } = useAppStore();
  const { user } = useAuth();

  return (
    <aside className={clsx(
      'fixed left-0 top-0 h-screen bg-gray-900 text-white flex flex-col z-30 transition-all',
      sidebarOpen ? 'w-64' : 'w-16'
    )}>
      <div className="h-16 flex items-center px-4 border-b border-gray-700">
        {sidebarOpen && <span className="text-lg font-bold text-green-400">SmartGob</span>}
        <button onClick={toggleSidebar} className="ml-auto text-gray-400 hover:text-white">
          {sidebarOpen ? <ChevronLeft size={20} /> : <ChevronRight size={20} />}
        </button>
      </div>
      <nav className="flex-1 py-4 space-y-1">
        {LINKS.map(({ to, label, icon: Icon }) => (
          <NavLink key={to} to={to}
            className={({ isActive }) => clsx(
              'flex items-center gap-3 px-4 py-2.5 text-sm transition-colors',
              isActive ? 'bg-primary-600 text-white' : 'text-gray-300 hover:bg-gray-800 hover:text-white'
            )}>
            <Icon size={20} />
            {sidebarOpen && <span>{label}</span>}
          </NavLink>
        ))}
      </nav>
      {sidebarOpen && user && (
        <div className="p-4 border-t border-gray-700 text-xs text-gray-400">
          <p className="text-white font-medium truncate">{user.nombreCompleto}</p>
          <p className="truncate">{user.correo}</p>
        </div>
      )}
    </aside>
  );
}

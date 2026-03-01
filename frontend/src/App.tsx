import { Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { useAuthStore } from '@/store/authStore';
import MainLayout from '@/components/layout/MainLayout';
import LoginPage from '@/pages/LoginPage';
import DashboardPage from '@/pages/DashboardPage';
import KanbanPage from '@/pages/KanbanPage';
import TareasPage from '@/pages/TareasPage';
import TareaDetallePage from '@/pages/TareaDetallePage';
import MisTareasPage from '@/pages/MisTareasPage';

function PrivateRoute({ children }: { children: React.ReactNode }) {
  const isAuth = useAuthStore((s) => s.isAuthenticated);
  return isAuth ? <>{children}</> : <Navigate to="/login" replace />;
}

export default function App() {
  return (
    <>
      <Toaster position="top-right" />
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/" element={<PrivateRoute><MainLayout /></PrivateRoute>}>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="kanban" element={<KanbanPage />} />
          <Route path="kanban/:equipoId" element={<KanbanPage />} />
          <Route path="tareas" element={<TareasPage />} />
          <Route path="tareas/:id" element={<TareaDetallePage />} />
          <Route path="mis-tareas" element={<MisTareasPage />} />
        </Route>
      </Routes>
    </>
  );
}

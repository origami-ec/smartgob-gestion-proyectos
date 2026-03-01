import { useAuth } from '@/hooks/useAuth';
import { useAppStore } from '@/store/appStore';
import { useApi } from '@/hooks/useApi';
import { notificacionesApi } from '@/api/entities';
import { contratosApi, equiposApi } from '@/api/entities';
import { Bell, LogOut } from 'lucide-react';

export default function Header() {
  const { user, logout } = useAuth();
  const { selectedContratoId, selectedEquipoId, setContrato, setEquipo } = useAppStore();

  const { data: contratos } = useApi(() => contratosApi.misContratos(), []);
  const { data: equipos } = useApi(
    () => selectedContratoId ? equiposApi.listarPorContrato(selectedContratoId) : Promise.resolve([]),
    [selectedContratoId]
  );
  const { data: noLeidasCount } = useApi(() => notificacionesApi.contarNoLeidas(), []);

  return (
    <header className="h-16 bg-white border-b border-gray-200 flex items-center px-6 gap-4 shrink-0">
      <div className="flex items-center gap-3">
        <select value={selectedContratoId || ''} onChange={(e) => setContrato(e.target.value || null)}
          className="input max-w-[220px] text-sm">
          <option value="">Todos los contratos</option>
          {contratos?.map(c => <option key={c.id} value={c.id}>{c.nroContrato} — {c.cliente}</option>)}
        </select>
        {equipos && equipos.length > 0 && (
          <select value={selectedEquipoId || ''} onChange={(e) => setEquipo(e.target.value || null)}
            className="input max-w-[180px] text-sm">
            <option value="">Todos los equipos</option>
            {equipos.map(eq => <option key={eq.id} value={eq.id}>{eq.nombre}</option>)}
          </select>
        )}
      </div>
      <div className="ml-auto flex items-center gap-4">
        <button className="relative text-gray-500 hover:text-gray-700">
          <Bell size={20} />
          {noLeidasCount != null && noLeidasCount > 0 && (
            <span className="absolute -top-1 -right-1 bg-red-500 text-white text-[10px] w-4 h-4 rounded-full flex items-center justify-center">
              {noLeidasCount > 9 ? '9+' : noLeidasCount}
            </span>
          )}
        </button>
        <span className="text-sm text-gray-600">{user?.nombreCompleto}</span>
        <button onClick={logout} className="text-gray-400 hover:text-red-500 transition" title="Cerrar sesión">
          <LogOut size={18} />
        </button>
      </div>
    </header>
  );
}

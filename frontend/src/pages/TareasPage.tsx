import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useApi } from '@/hooks/useApi';
import { useAppStore } from '@/store/appStore';
import { tareasApi } from '@/api/tareas';
import Badge from '@/components/common/Badge';
import ProgressBar from '@/components/common/ProgressBar';
import Spinner from '@/components/common/Spinner';
import EmptyState from '@/components/common/EmptyState';
import { ESTADOS, PRIORIDADES } from '@/constants';
import { Search, Plus } from 'lucide-react';

export default function TareasPage() {
  const navigate = useNavigate();
  const { selectedContratoId, selectedEquipoId } = useAppStore();
  const [busqueda, setBusqueda] = useState('');
  const [estado, setEstado] = useState('');
  const [prioridad, setPrioridad] = useState('');
  const [page, setPage] = useState(0);

  const { data, loading } = useApi(
    () => tareasApi.buscar({
      contratoId: selectedContratoId || undefined,
      equipoId: selectedEquipoId || undefined,
      estado: estado || undefined,
      prioridad: prioridad || undefined,
      busqueda: busqueda || undefined,
      page, size: 20,
    }),
    [selectedContratoId, selectedEquipoId, estado, prioridad, busqueda, page]
  );

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Tareas</h1>
        <button className="btn-primary flex items-center gap-2" onClick={() => {}}>
          <Plus size={16} /> Nueva Tarea
        </button>
      </div>

      {/* Filtros */}
      <div className="card flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[200px]">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input className="input pl-9" placeholder="Buscar por ID o título..."
            value={busqueda} onChange={(e) => { setBusqueda(e.target.value); setPage(0); }} />
        </div>
        <select className="input w-auto" value={estado} onChange={(e) => { setEstado(e.target.value); setPage(0); }}>
          <option value="">Todos los estados</option>
          {Object.values(ESTADOS).map(e => <option key={e.codigo} value={e.codigo}>{e.nombre}</option>)}
        </select>
        <select className="input w-auto" value={prioridad} onChange={(e) => { setPrioridad(e.target.value); setPage(0); }}>
          <option value="">Todas las prioridades</option>
          {Object.values(PRIORIDADES).map(p => <option key={p.codigo} value={p.codigo}>{p.nombre}</option>)}
        </select>
      </div>

      {loading ? <Spinner /> : !data || data.content.length === 0 ? <EmptyState message="Sin tareas" /> : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50 text-left text-gray-500 text-xs uppercase">
                <th className="py-3 px-4">ID</th><th className="px-4">Título</th><th className="px-4">Estado</th>
                <th className="px-4">Prioridad</th><th className="px-4">Asignado</th><th className="px-4">Avance</th>
                <th className="px-4">Vence</th>
              </tr>
            </thead>
            <tbody>
              {data.content.map(t => (
                <tr key={t.id} className="border-b hover:bg-gray-50 cursor-pointer"
                  onClick={() => navigate(`/tareas/${t.id}`)}>
                  <td className="py-3 px-4 font-mono text-xs text-gray-500">{t.idTarea}</td>
                  <td className="px-4 font-medium max-w-xs truncate">{t.titulo}</td>
                  <td className="px-4"><Badge label={t.estadoNombre} color={t.estadoColor} bgColor={t.estadoBgColor} /></td>
                  <td className="px-4"><Badge label={t.prioridadNombre} color={t.prioridadColor} bgColor={t.prioridadColor + '15'} /></td>
                  <td className="px-4 text-gray-600 text-xs">{t.asignadoANombre || '—'}</td>
                  <td className="px-4 w-28"><ProgressBar value={t.porcentajeAvance} /></td>
                  <td className="px-4 text-xs text-gray-500">{t.fechaEstimadaFin}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {data.totalPages > 1 && (
            <div className="flex items-center justify-between p-4 border-t bg-gray-50">
              <span className="text-xs text-gray-500">
                {data.totalElements} tareas — Página {data.page + 1} de {data.totalPages}
              </span>
              <div className="flex gap-2">
                <button className="btn-secondary text-xs" disabled={data.first} onClick={() => setPage(p => p - 1)}>Anterior</button>
                <button className="btn-secondary text-xs" disabled={data.last} onClick={() => setPage(p => p + 1)}>Siguiente</button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

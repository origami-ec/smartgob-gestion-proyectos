import { useParams } from 'react-router-dom';
import { useAppStore } from '@/store/appStore';
import { useApi } from '@/hooks/useApi';
import { useAuth } from '@/hooks/useAuth';
import { tareasApi } from '@/api/tareas';
import { ESTADOS, KANBAN_COLUMNS } from '@/constants';
import Badge from '@/components/common/Badge';
import ProgressBar from '@/components/common/ProgressBar';
import Spinner from '@/components/common/Spinner';
import EmptyState from '@/components/common/EmptyState';
import { useNavigate } from 'react-router-dom';
import type { TareaResumen } from '@/types';

export default function KanbanPage() {
  const { equipoId: paramEquipoId } = useParams();
  const { selectedEquipoId, selectedContratoId } = useAppStore();
  const equipoId = paramEquipoId || selectedEquipoId;
  const navigate = useNavigate();

  const { data: kanban, loading, reload } = useApi(
    () => equipoId ? tareasApi.kanban(equipoId, selectedContratoId || undefined) : Promise.resolve({}),
    [equipoId, selectedContratoId]
  );

  if (!equipoId) {
    return <EmptyState message="Selecciona un contrato y equipo en la barra superior para ver el Kanban" />;
  }
  if (loading) return <Spinner />;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Tablero Kanban</h1>
        <button onClick={reload} className="btn-secondary text-xs">Actualizar</button>
      </div>
      <div className="flex gap-4 overflow-x-auto pb-4">
        {KANBAN_COLUMNS.map(col => {
          const est = ESTADOS[col];
          const tareas = kanban?.[col] ?? [];
          return (
            <div key={col} className="flex-shrink-0 w-72 bg-gray-100 rounded-xl p-3">
              <div className="flex items-center justify-between mb-3">
                <Badge label={est.nombre} color={est.color} bgColor={est.bg} />
                <span className="text-xs font-semibold text-gray-500">{tareas.length}</span>
              </div>
              <div className="space-y-2 max-h-[calc(100vh-240px)] overflow-y-auto">
                {tareas.map((t: TareaResumen) => (
                  <div key={t.id} onClick={() => navigate(`/tareas/${t.id}`)}
                    className="bg-white rounded-lg p-3 shadow-sm border border-gray-200 cursor-pointer hover:shadow-md transition">
                    <div className="flex items-start justify-between gap-2">
                      <span className="text-xs font-mono text-gray-400">{t.idTarea}</span>
                      <Badge label={t.prioridadNombre} color={t.prioridadColor} bgColor={t.prioridadColor + '15'} />
                    </div>
                    <p className="text-sm font-medium mt-1.5 line-clamp-2">{t.titulo}</p>
                    <div className="mt-2">
                      <ProgressBar value={t.porcentajeAvance} />
                      <div className="flex items-center justify-between mt-1.5 text-xs text-gray-500">
                        <span>{t.asignadoANombre || 'Sin asignar'}</span>
                        <span>{t.porcentajeAvance}%</span>
                      </div>
                    </div>
                    {t.diasRestantes <= 3 && t.diasRestantes >= 0 && (
                      <p className="text-[10px] text-orange-500 mt-1">⚠ Vence en {t.diasRestantes} días</p>
                    )}
                    {t.diasRestantes < 0 && (
                      <p className="text-[10px] text-red-500 mt-1">🔴 Vencida hace {Math.abs(t.diasRestantes)} días</p>
                    )}
                  </div>
                ))}
                {tareas.length === 0 && (
                  <p className="text-xs text-gray-400 text-center py-8">Sin tareas</p>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

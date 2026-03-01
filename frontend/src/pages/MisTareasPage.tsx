import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useApi } from '@/hooks/useApi';
import { tareasApi } from '@/api/tareas';
import Badge from '@/components/common/Badge';
import ProgressBar from '@/components/common/ProgressBar';
import Spinner from '@/components/common/Spinner';
import EmptyState from '@/components/common/EmptyState';
import { ESTADOS } from '@/constants';

export default function MisTareasPage() {
  const navigate = useNavigate();
  const [estado, setEstado] = useState('');
  const { data, loading } = useApi(() => tareasApi.misTareas(estado || undefined), [estado]);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Mis Tareas</h1>
        <select className="input w-auto" value={estado} onChange={(e) => setEstado(e.target.value)}>
          <option value="">Todos los estados</option>
          {Object.values(ESTADOS).map(e => <option key={e.codigo} value={e.codigo}>{e.nombre}</option>)}
        </select>
      </div>

      {loading ? <Spinner /> : !data || data.length === 0 ? <EmptyState message="No tienes tareas asignadas" /> : (
        <div className="grid gap-3">
          {data.map(t => (
            <div key={t.id} onClick={() => navigate(`/tareas/${t.id}`)}
              className="card cursor-pointer hover:shadow-md transition flex items-center gap-4">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-mono text-xs text-gray-400">{t.idTarea}</span>
                  <Badge label={t.estadoNombre} color={t.estadoColor} bgColor={t.estadoBgColor} />
                  <Badge label={t.prioridadNombre} color={t.prioridadColor} bgColor={t.prioridadColor + '15'} />
                </div>
                <p className="font-medium truncate">{t.titulo}</p>
              </div>
              <div className="w-24 shrink-0">
                <ProgressBar value={t.porcentajeAvance} />
                <p className="text-xs text-gray-500 text-center mt-1">{t.porcentajeAvance}%</p>
              </div>
              <div className="text-right text-xs text-gray-500 shrink-0 w-20">
                <p>{t.fechaEstimadaFin}</p>
                {t.diasRestantes < 0 && <p className="text-red-500 font-semibold">Vencida</p>}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

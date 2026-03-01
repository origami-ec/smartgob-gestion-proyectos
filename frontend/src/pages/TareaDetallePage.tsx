import { useParams, useNavigate } from 'react-router-dom';
import { useState } from 'react';
import { useApi } from '@/hooks/useApi';
import { useAuth } from '@/hooks/useAuth';
import { tareasApi } from '@/api/tareas';
import Badge from '@/components/common/Badge';
import ProgressBar from '@/components/common/ProgressBar';
import Spinner from '@/components/common/Spinner';
import { formatFecha, formatFechaHora, formatRelativo } from '@/utils/format';
import { ArrowLeft, MessageSquare, Clock, Send } from 'lucide-react';
import toast from 'react-hot-toast';

export default function TareaDetallePage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();

  const { data: tarea, loading, reload } = useApi(() => tareasApi.obtener(id!), [id]);
  const { data: transiciones } = useApi(() => tareasApi.transiciones(id!), [id]);
  const { data: historico } = useApi(() => tareasApi.historico(id!), [id]);
  const { data: comentarios, reload: reloadComentarios } = useApi(() => tareasApi.comentarios(id!), [id]);

  const [comentario, setComentario] = useState('');
  const [submitting, setSubmitting] = useState(false);

  if (loading || !tarea) return <Spinner />;

  const handleCambiarEstado = async (estadoDestino: string) => {
    const motivo = window.prompt('Comentario (opcional):');
    try {
      await tareasApi.cambiarEstado(tarea.id, { estadoDestino, comentario: motivo || undefined });
      toast.success('Estado actualizado');
      reload();
    } catch (err: any) {
      toast.error(err.response?.data?.detail || 'Error al cambiar estado');
    }
  };

  const handleComentario = async () => {
    if (!comentario.trim()) return;
    setSubmitting(true);
    try {
      await tareasApi.crearComentario(tarea.id, comentario);
      setComentario('');
      reloadComentarios();
      toast.success('Comentario agregado');
    } catch { toast.error('Error'); }
    finally { setSubmitting(false); }
  };

  return (
    <div className="space-y-6 max-w-5xl">
      <button onClick={() => navigate(-1)} className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700">
        <ArrowLeft size={16} /> Volver
      </button>

      {/* Header */}
      <div className="card">
        <div className="flex items-start justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="font-mono text-sm text-gray-400">{tarea.idTarea}</span>
              <Badge label={tarea.estadoNombre} color={tarea.estadoColor} bgColor={tarea.estadoBgColor} />
              <Badge label={tarea.prioridadNombre} color={tarea.prioridadColor} bgColor={tarea.prioridadColor + '15'} />
              <Badge label={tarea.categoria} />
            </div>
            <h1 className="text-xl font-bold">{tarea.titulo}</h1>
            <p className="text-sm text-gray-500 mt-1">{tarea.nroContrato} — {tarea.cliente} · {tarea.equipoNombre}</p>
          </div>
          <div className="text-right text-sm text-gray-500">
            <p>Creado: {formatFecha(tarea.fechaAsignacion)}</p>
            <p>Vence: {formatFecha(tarea.fechaEstimadaFin)}</p>
            <p className={tarea.diasRestantes < 0 ? 'text-red-500 font-semibold' : ''}>
              {tarea.diasRestantes >= 0 ? `${tarea.diasRestantes} días restantes` : `Vencida hace ${Math.abs(tarea.diasRestantes)} días`}
            </p>
          </div>
        </div>
        <div className="mt-4">
          <div className="flex items-center justify-between text-sm mb-1">
            <span className="text-gray-500">Avance</span>
            <span className="font-semibold">{tarea.porcentajeAvance}%</span>
          </div>
          <ProgressBar value={tarea.porcentajeAvance} />
        </div>
        {tarea.descripcion && (
          <div className="mt-4 p-3 bg-gray-50 rounded-lg text-sm text-gray-700 whitespace-pre-wrap">{tarea.descripcion}</div>
        )}
      </div>

      {/* Info grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <InfoItem label="Asignado a" value={tarea.asignadoANombre || 'Sin asignar'} />
        <InfoItem label="Creado por" value={tarea.creadoPorNombre || '—'} />
        <InfoItem label="Revisado por" value={tarea.revisadoPorNombre || 'Pendiente'} />
        <InfoItem label="Comentarios / Adjuntos" value={`${tarea.totalComentarios} / ${tarea.totalAdjuntos}`} />
      </div>

      {/* Acciones de transición */}
      {transiciones && transiciones.length > 0 && (
        <div className="card">
          <h2 className="text-sm font-semibold text-gray-700 mb-3">Acciones disponibles</h2>
          <div className="flex flex-wrap gap-2">
            {transiciones.map(tr => (
              <button key={tr.estadoDestino} onClick={() => handleCambiarEstado(tr.estadoDestino)}
                className="btn-primary text-xs"> {tr.accion}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Histórico */}
      {historico && historico.length > 0 && (
        <div className="card">
          <h2 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2"><Clock size={16} /> Histórico</h2>
          <div className="space-y-3">
            {historico.map(h => (
              <div key={h.id} className="flex items-start gap-3 text-sm">
                <div className="w-2 h-2 mt-1.5 rounded-full bg-primary-500 shrink-0" />
                <div>
                  <p>
                    <span className="font-medium">{h.cambiadoPorNombre}</span>
                    {' '}{h.estadoAnterior ? `${h.estadoAnterior} → ` : ''}<strong>{h.estadoNuevo}</strong>
                  </p>
                  {h.comentario && <p className="text-gray-500 text-xs mt-0.5">{h.comentario}</p>}
                  <p className="text-xs text-gray-400">{formatRelativo(h.fecha)}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Comentarios */}
      <div className="card">
        <h2 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2"><MessageSquare size={16} /> Comentarios</h2>
        <div className="space-y-3 mb-4">
          {comentarios?.map(c => (
            <div key={c.id} className="bg-gray-50 rounded-lg p-3">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">{c.autorNombre}</span>
                <span className="text-xs text-gray-400">{formatRelativo(c.createdAt)}</span>
              </div>
              <p className="text-sm text-gray-700 mt-1 whitespace-pre-wrap">{c.contenido}</p>
            </div>
          ))}
          {(!comentarios || comentarios.length === 0) && <p className="text-xs text-gray-400">Sin comentarios</p>}
        </div>
        <div className="flex gap-2">
          <input className="input flex-1" placeholder="Escribe un comentario..."
            value={comentario} onChange={(e) => setComentario(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleComentario()} />
          <button onClick={handleComentario} disabled={submitting || !comentario.trim()} className="btn-primary">
            <Send size={16} />
          </button>
        </div>
      </div>
    </div>
  );
}

function InfoItem({ label, value }: { label: string; value: string }) {
  return (
    <div className="card text-center">
      <p className="text-xs text-gray-500 mb-1">{label}</p>
      <p className="text-sm font-medium truncate">{value}</p>
    </div>
  );
}

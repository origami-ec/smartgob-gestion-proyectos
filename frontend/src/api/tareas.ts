import api from './client';
import { API_BASE } from '@/constants';
import type { ApiResponse, PageResponse, Tarea, TareaResumen, CrearTareaRequest, CambiarEstadoRequest, TransicionPermitida, HistoricoEstado, Comentario } from '@/types';

const BASE = `${API_BASE}/tareas`;

export const tareasApi = {
  obtener: (id: string) =>
    api.get<ApiResponse<Tarea>>(`${BASE}/${id}`).then(r => r.data.data),

  buscar: (params: Record<string, string | number | undefined>) =>
    api.get<ApiResponse<PageResponse<TareaResumen>>>(BASE, { params }).then(r => r.data.data),

  kanban: (equipoId: string, contratoId?: string) =>
    api.get<ApiResponse<Record<string, TareaResumen[]>>>(`${BASE}/kanban/${equipoId}`, { params: { contratoId } }).then(r => r.data.data),

  misTareas: (estado?: string) =>
    api.get<ApiResponse<TareaResumen[]>>(`${BASE}/mis-tareas`, { params: { estado } }).then(r => r.data.data),

  pendientesRevision: (equipoId: string) =>
    api.get<ApiResponse<TareaResumen[]>>(`${BASE}/pendientes-revision/${equipoId}`).then(r => r.data.data),

  transiciones: (id: string) =>
    api.get<ApiResponse<TransicionPermitida[]>>(`${BASE}/${id}/transiciones`).then(r => r.data.data),

  historico: (id: string) =>
    api.get<ApiResponse<HistoricoEstado[]>>(`${BASE}/${id}/historico`).then(r => r.data.data),

  crear: (data: CrearTareaRequest) =>
    api.post<ApiResponse<Tarea>>(BASE, data).then(r => r.data.data),

  actualizar: (id: string, data: Partial<CrearTareaRequest>) =>
    api.put<ApiResponse<Tarea>>(`${BASE}/${id}`, data).then(r => r.data.data),

  cambiarEstado: (id: string, data: CambiarEstadoRequest) =>
    api.patch<ApiResponse<Tarea>>(`${BASE}/${id}/estado`, data).then(r => r.data.data),

  actualizarAvance: (id: string, porcentajeAvance: number, observaciones?: string) =>
    api.patch<ApiResponse<Tarea>>(`${BASE}/${id}/avance`, { porcentajeAvance, observaciones }).then(r => r.data.data),

  eliminar: (id: string) =>
    api.delete<ApiResponse<void>>(`${BASE}/${id}`),

  // Comentarios
  comentarios: (tareaId: string) =>
    api.get<ApiResponse<Comentario[]>>(`${BASE}/${tareaId}/comentarios`).then(r => r.data.data),

  crearComentario: (tareaId: string, contenido: string, tipo?: string) =>
    api.post<ApiResponse<Comentario>>(`${BASE}/${tareaId}/comentarios`, { contenido, tipo }).then(r => r.data.data),
};

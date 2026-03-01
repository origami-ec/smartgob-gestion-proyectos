import api from './client';
import { API_BASE } from '@/constants';
import type { ApiResponse, DashboardSuper, DashboardEquipo, CargaColaborador, TareaAlerta } from '@/types';

const BASE = `${API_BASE}/dashboard`;

export const dashboardApi = {
  super: () =>
    api.get<ApiResponse<DashboardSuper[]>>(`${BASE}/super`).then(r => r.data.data),

  equipo: (contratoId?: string) =>
    api.get<ApiResponse<DashboardEquipo[]>>(`${BASE}/equipo`, { params: { contratoId } }).then(r => r.data.data),

  cargaColaborador: (equipoId?: string) =>
    api.get<ApiResponse<CargaColaborador[]>>(`${BASE}/carga-colaborador`, { params: { equipoId } }).then(r => r.data.data),

  alertasSla: (contratoId?: string, equipoId?: string, alertaSla?: string) =>
    api.get<ApiResponse<TareaAlerta[]>>(`${BASE}/alertas-sla`, { params: { contratoId, equipoId, alertaSla } }).then(r => r.data.data),

  conteoKanban: (equipoId: string) =>
    api.get<ApiResponse<Record<string, number>>>(`${BASE}/kanban-conteo/${equipoId}`).then(r => r.data.data),
};

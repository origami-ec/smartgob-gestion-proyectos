import api from './client';
import { API_BASE } from '@/constants';
import type { ApiResponse, PageResponse, Empresa, Colaborador, Contrato, Equipo, Notificacion, Mensaje } from '@/types';

export const empresasApi = {
  listarActivas: () =>
    api.get<ApiResponse<Empresa[]>>(`${API_BASE}/empresas/activas`).then(r => r.data.data),
};

export const colaboradoresApi = {
  listarActivos: () =>
    api.get<ApiResponse<Colaborador[]>>(`${API_BASE}/colaboradores/activos`).then(r => r.data.data),
  listarPorEquipo: (equipoId: string) =>
    api.get<ApiResponse<Colaborador[]>>(`${API_BASE}/colaboradores/equipo/${equipoId}`).then(r => r.data.data),
};

export const contratosApi = {
  listarActivos: () =>
    api.get<ApiResponse<Contrato[]>>(`${API_BASE}/contratos/activos`).then(r => r.data.data),
  misContratos: () =>
    api.get<ApiResponse<Contrato[]>>(`${API_BASE}/contratos/mis-contratos`).then(r => r.data.data),
  obtener: (id: string) =>
    api.get<ApiResponse<Contrato>>(`${API_BASE}/contratos/${id}`).then(r => r.data.data),
};

export const equiposApi = {
  listarPorContrato: (contratoId: string) =>
    api.get<ApiResponse<Equipo[]>>(`${API_BASE}/equipos/contrato/${contratoId}`).then(r => r.data.data),
  misEquipos: () =>
    api.get<ApiResponse<Equipo[]>>(`${API_BASE}/equipos/mis-equipos`).then(r => r.data.data),
  obtener: (id: string) =>
    api.get<ApiResponse<Equipo>>(`${API_BASE}/equipos/${id}`).then(r => r.data.data),
};

export const notificacionesApi = {
  noLeidas: () =>
    api.get<ApiResponse<Notificacion[]>>(`${API_BASE}/notificaciones/no-leidas`).then(r => r.data.data),
  contarNoLeidas: () =>
    api.get<ApiResponse<number>>(`${API_BASE}/notificaciones/no-leidas/count`).then(r => r.data.data),
  marcarLeida: (id: string) =>
    api.patch(`${API_BASE}/notificaciones/${id}/leida`),
  marcarTodasLeidas: () =>
    api.patch(`${API_BASE}/notificaciones/marcar-todas-leidas`),
};

export const mensajesApi = {
  bandeja: (page = 0) =>
    api.get<ApiResponse<PageResponse<Mensaje>>>(`${API_BASE}/mensajes/bandeja`, { params: { page, size: 20 } }).then(r => r.data.data),
  contarNoLeidos: () =>
    api.get<ApiResponse<number>>(`${API_BASE}/mensajes/no-leidos/count`).then(r => r.data.data),
  enviar: (data: { destinatarioId?: string; equipoId?: string; contratoId?: string; asunto?: string; contenido: string; tipo: string }) =>
    api.post<ApiResponse<Mensaje>>(`${API_BASE}/mensajes`, data).then(r => r.data.data),
};

// ── Auth ───────────────────────────────────────────────────
export interface LoginRequest { usuario: string; password: string; }

export interface RolEquipoInfo { equipoId: string; equipoNombre?: string; rol: string; }

export interface AuthResponse {
  token: string;
  colaboradorId: string;
  nombreCompleto: string;
  correo: string;
  esSuperUsuario: boolean;
  roles: RolEquipoInfo[];
}

// ── Generics ───────────────────────────────────────────────
export interface ApiResponse<T> { success: boolean; mensaje?: string; data: T; }

export interface PageResponse<T> {
  content: T[];
  page: number; size: number;
  totalElements: number; totalPages: number;
  first: boolean; last: boolean;
}

// ── Empresa ────────────────────────────────────────────────
export interface Empresa {
  id: string; ruc: string; razonSocial: string; tipo: string; estado: string;
}

// ── Colaborador ────────────────────────────────────────────
export interface Colaborador {
  id: string; cedula: string; nombreCompleto: string; tipo: string;
  titulo?: string; correo: string; telefono?: string;
  empresaId?: string; empresaNombre?: string;
  estado: string; esSuperUsuario: boolean;
}

// ── Contrato ───────────────────────────────────────────────
export interface Contrato {
  id: string; nroContrato: string; cliente: string; tipoProyecto: string;
  fechaInicio: string; plazoDias: number; fechaFin: string;
  administradorId?: string; administradorNombre?: string;
  correoAdmin?: string; empresaContratadaId?: string; empresaNombre?: string;
  ultimaFase?: string; estado: string; objetoContrato?: string;
  diasRestantes: number;
}

// ── Equipo ─────────────────────────────────────────────────
export interface MiembroEquipo {
  asignacionId: string; colaboradorId: string; nombreCompleto: string;
  correo: string; rolEquipo: string; rolNombre: string;
  fechaAsignacion: string;
}

export interface Equipo {
  id: string; nombre: string; contratoId: string; nroContrato?: string;
  descripcion?: string; estado: string;
  totalMiembros: number; miembros?: MiembroEquipo[];
}

// ── Tarea ──────────────────────────────────────────────────
export interface TareaResumen {
  id: string; idTarea: string; titulo: string;
  estado: string; estadoNombre: string; estadoColor: string; estadoBgColor: string;
  prioridad: string; prioridadNombre: string; prioridadColor: string;
  categoria: string;
  asignadoAId?: string; asignadoANombre?: string;
  fechaEstimadaFin: string; porcentajeAvance: number;
  diasRestantes: number; dentroDePlazo: boolean;
}

export interface Tarea extends TareaResumen {
  contratoId: string; nroContrato: string; cliente: string;
  equipoId: string; equipoNombre: string;
  descripcion?: string; observaciones?: string;
  creadoPorId?: string; creadoPorNombre?: string;
  revisadoPorId?: string; revisadoPorNombre?: string;
  fechaAsignacion: string; fechaRevision?: string;
  totalComentarios: number; totalAdjuntos: number;
}

export interface CrearTareaRequest {
  contratoId: string; equipoId: string; categoria: string;
  titulo: string; descripcion?: string; prioridad: string;
  asignadoAId?: string; fechaEstimadaFin: string; observaciones?: string;
}

export interface CambiarEstadoRequest { estadoDestino: string; comentario?: string; }

export interface TransicionPermitida {
  estadoDestino: string; accion: string;
  rolesPermitidos: string[]; descripcion: string;
}

// ── Comentario ─────────────────────────────────────────────
export interface Comentario {
  id: string; autorId: string; autorNombre: string;
  contenido: string; tipo: string; createdAt: string;
}

// ── Adjunto ────────────────────────────────────────────────
export interface Adjunto {
  id: string; nombreArchivo: string; rutaArchivo: string;
  tipoMime: string; tamanoBytes: number;
  subidoPorId: string; subidoPorNombre: string; createdAt: string;
}

// ── Histórico ──────────────────────────────────────────────
export interface HistoricoEstado {
  id: string; estadoAnterior?: string; estadoNuevo: string;
  cambiadoPorId: string; cambiadoPorNombre: string;
  comentario?: string; fecha: string;
}

// ── Mensaje ────────────────────────────────────────────────
export interface Mensaje {
  id: string; remitenteId: string; remitenteNombre: string;
  destinatarioId?: string; equipoId?: string; contratoId?: string;
  asunto?: string; contenido: string; tipo: string;
  leido: boolean; createdAt: string;
}

// ── Notificación ───────────────────────────────────────────
export interface Notificacion {
  id: string; tipo: string; referenciaTipo?: string; referenciaId?: string;
  titulo: string; mensaje: string; leido: boolean;
  urlAccion?: string; createdAt: string;
}

// ── Dashboard ──────────────────────────────────────────────
export interface DashboardSuper {
  contratoId: string; nroContrato: string; cliente: string;
  tipoProyecto: string; fechaInicio: string; fechaFin: string;
  contratoEstado: string; diasRestantesContrato: number;
  totalTareas: number; tareasFinalizadas: number; tareasFueraPlazo: number;
  tareasActivas: number; tareasSuspendidas: number; tareasEnRevision: number;
  tareasCriticas: number; tareasVencidas: number; porcentajeAvanceGlobal: number;
}

export interface DashboardEquipo {
  equipoId: string; equipoNombre: string; contratoId: string;
  nroContrato: string; cliente: string;
  totalTareas: number; backlog: number; ejecutando: number;
  enRevision: number; finalizadas: number; suspendidas: number;
  fueraPlazo: number; criticas: number; vencidas: number;
  totalMiembros: number; avancePromedio: number;
}

export interface CargaColaborador {
  colaboradorId: string; nombreCompleto: string; correo: string;
  equipoId: string; rolEquipo: string; equipoNombre: string;
  tareasActivas: number; enRevision: number; vencidas: number;
  totalAsignadas: number;
}

export interface TareaAlerta extends TareaResumen {
  nroContrato: string; cliente: string; nombreEquipo: string;
  alertaSla: string; horasRestantesRevision?: number;
}

#!/bin/bash
# ============================================================
# COMMIT 7: Frontend React — Vite + TypeScript + Tailwind + Zustand
# Ejecutar desde la raíz del proyecto: smartgob-gestion-proyectos/
#
# Después:
#   cd frontend && npm install && cd ..
#   git add .
#   git commit -m "feat: frontend React - tipos, API, store, layout, kanban, dashboard, tareas"
#   git push
# ============================================================

set -e
F="frontend"
S="$F/src"
echo "📦 Commit 7: Frontend React (Vite + TS + Tailwind + Zustand)"

# =============================================================
# 1. PACKAGE.JSON actualizado con dependencias
# =============================================================
echo "  📋 package.json + configs..."

cat > $F/package.json << 'EOF'
{
  "name": "smartgob-gproyectos-ui",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "react-router-dom": "^7.1.0",
    "axios": "^1.7.0",
    "zustand": "^5.0.0",
    "clsx": "^2.1.0",
    "lucide-react": "^0.468.0",
    "react-beautiful-dnd": "^13.1.1",
    "date-fns": "^4.1.0",
    "date-fns-tz": "^3.2.0",
    "recharts": "^2.15.0",
    "react-hot-toast": "^2.4.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@types/react-beautiful-dnd": "^13.1.8",
    "@vitejs/plugin-react": "^4.3.0",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.4.49",
    "tailwindcss": "^3.4.17",
    "typescript": "^5.7.0",
    "vite": "^6.2.0"
  }
}
EOF

cat > $F/vite.config.ts << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': { target: 'http://localhost:8080', changeOrigin: true },
    },
  },
});
EOF

cat > $F/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "isolatedModules": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  },
  "include": ["src"]
}
EOF

cat > $F/tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: { 50: '#eff6ff', 100: '#dbeafe', 200: '#bfdbfe', 300: '#93c5fd', 400: '#60a5fa', 500: '#3b82f6', 600: '#2563eb', 700: '#1d4ed8', 800: '#1e40af', 900: '#1e3a8a' },
        smartgob: { 50: '#f0fdf4', 100: '#dcfce7', 500: '#22c55e', 600: '#16a34a', 700: '#15803d', 800: '#166534' },
      },
    },
  },
  plugins: [],
};
EOF

cat > $F/postcss.config.js << 'EOF'
export default {
  plugins: { tailwindcss: {}, autoprefixer: {} },
};
EOF

cat > $F/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>SmartGob — Gestión de Proyectos</title>
  <link rel="icon" type="image/svg+xml" href="/vite.svg" />
</head>
<body class="bg-gray-50 text-gray-900 antialiased">
  <div id="root"></div>
  <script type="module" src="/src/main.tsx"></script>
</body>
</html>
EOF

# =============================================================
# 2. TYPES — interfaces TypeScript
# =============================================================
echo "  📐 Types..."

cat > $S/types/index.ts << 'EOF'
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
EOF

# =============================================================
# 3. CONSTANTS
# =============================================================
echo "  📌 Constants..."

cat > $S/constants/index.ts << 'EOF'
export const ESTADOS = {
  ASG:  { codigo: 'ASG',  nombre: 'Asignado',              color: '#3B82F6', bg: '#DBEAFE' },
  EJE:  { codigo: 'EJE',  nombre: 'Ejecutando',            color: '#F59E0B', bg: '#FEF3C7' },
  SUS:  { codigo: 'SUS',  nombre: 'Suspendido',            color: '#6B7280', bg: '#F3F4F6' },
  TER:  { codigo: 'TER',  nombre: 'Terminada',             color: '#10B981', bg: '#D1FAE5' },
  TERT: { codigo: 'TERT', nombre: 'Terminada fuera plazo', color: '#EF4444', bg: '#FEE2E2' },
  REV:  { codigo: 'REV',  nombre: 'En Revisión',           color: '#8B5CF6', bg: '#EDE9FE' },
  FIN:  { codigo: 'FIN',  nombre: 'Finalizada',            color: '#059669', bg: '#ECFDF5' },
} as const;

export const PRIORIDADES = {
  CRITICA: { codigo: 'CRITICA', nombre: 'Crítica', color: '#DC2626', peso: 4 },
  ALTA:    { codigo: 'ALTA',    nombre: 'Alta',    color: '#F97316', peso: 3 },
  MEDIA:   { codigo: 'MEDIA',   nombre: 'Media',   color: '#EAB308', peso: 2 },
  BAJA:    { codigo: 'BAJA',    nombre: 'Baja',    color: '#22C55E', peso: 1 },
} as const;

export const CATEGORIAS = ['DESARROLLO','DOCUMENTACION','PRUEBAS','CAPACITACION','INFRAESTRUCTURA','GESTION'] as const;

export const ROLES_EQUIPO = {
  LDR: 'Líder de Proyecto',
  ADM: 'Administrador',
  DEV: 'Desarrollador',
  TST: 'Tester / QA',
  DOC: 'Documentador',
} as const;

export const KANBAN_COLUMNS = ['ASG', 'EJE', 'SUS', 'TER', 'TERT', 'REV', 'FIN'] as const;

export const API_BASE = '/api/v1/gestion-proyectos';
EOF

# =============================================================
# 4. API CLIENT — Axios + interceptors
# =============================================================
echo "  🌐 API Client..."

cat > $S/api/client.ts << 'EOF'
import axios from 'axios';

const api = axios.create({ baseURL: '', timeout: 30000 });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
EOF

cat > $S/api/auth.ts << 'EOF'
import api from './client';
import type { ApiResponse, AuthResponse, LoginRequest } from '@/types';

export const authApi = {
  login: (data: LoginRequest) =>
    api.post<ApiResponse<AuthResponse>>('/api/auth/login', data).then(r => r.data.data),
  me: () =>
    api.get<ApiResponse<AuthResponse>>('/api/auth/me').then(r => r.data.data),
};
EOF

cat > $S/api/tareas.ts << 'EOF'
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
EOF

cat > $S/api/dashboard.ts << 'EOF'
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
EOF

cat > $S/api/entities.ts << 'EOF'
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
EOF

# =============================================================
# 5. STORE — Zustand
# =============================================================
echo "  🏪 Store (Zustand)..."

cat > $S/store/authStore.ts << 'EOF'
import { create } from 'zustand';
import type { AuthResponse, RolEquipoInfo } from '@/types';

interface AuthState {
  token: string | null;
  user: AuthResponse | null;
  isAuthenticated: boolean;
  login: (auth: AuthResponse) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: localStorage.getItem('token'),
  user: JSON.parse(localStorage.getItem('user') || 'null'),
  isAuthenticated: !!localStorage.getItem('token'),

  login: (auth) => {
    localStorage.setItem('token', auth.token);
    localStorage.setItem('user', JSON.stringify(auth));
    set({ token: auth.token, user: auth, isAuthenticated: true });
  },

  logout: () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    set({ token: null, user: null, isAuthenticated: false });
  },
}));
EOF

cat > $S/store/appStore.ts << 'EOF'
import { create } from 'zustand';

interface AppState {
  sidebarOpen: boolean;
  selectedContratoId: string | null;
  selectedEquipoId: string | null;
  toggleSidebar: () => void;
  setContrato: (id: string | null) => void;
  setEquipo: (id: string | null) => void;
}

export const useAppStore = create<AppState>((set) => ({
  sidebarOpen: true,
  selectedContratoId: null,
  selectedEquipoId: null,
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
  setContrato: (id) => set({ selectedContratoId: id, selectedEquipoId: null }),
  setEquipo: (id) => set({ selectedEquipoId: id }),
}));
EOF

# =============================================================
# 6. HOOKS
# =============================================================
echo "  🪝 Hooks..."

cat > $S/hooks/useApi.ts << 'EOF'
import { useState, useEffect, useCallback } from 'react';

export function useApi<T>(fetcher: () => Promise<T>, deps: unknown[] = []) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await fetcher();
      setData(result);
    } catch (err: any) {
      setError(err.response?.data?.detail || err.message || 'Error');
    } finally {
      setLoading(false);
    }
  }, deps);

  useEffect(() => { load(); }, [load]);

  return { data, loading, error, reload: load, setData };
}
EOF

cat > $S/hooks/useAuth.ts << 'EOF'
import { useAuthStore } from '@/store/authStore';

export function useAuth() {
  const { user, isAuthenticated, logout } = useAuthStore();

  const isSuperUsuario = user?.esSuperUsuario ?? false;

  const getRolEnEquipo = (equipoId: string): string | null => {
    if (isSuperUsuario) return 'LDR';
    const rol = user?.roles?.find(r => r.equipoId === equipoId);
    return rol?.rol ?? null;
  };

  const esGestor = (equipoId: string): boolean => {
    if (isSuperUsuario) return true;
    const rol = getRolEnEquipo(equipoId);
    return rol === 'LDR' || rol === 'ADM';
  };

  return { user, isAuthenticated, isSuperUsuario, getRolEnEquipo, esGestor, logout };
}
EOF

# =============================================================
# 7. UTILS
# =============================================================
echo "  🔧 Utils..."

cat > $S/utils/format.ts << 'EOF'
import { format, formatDistanceToNow, parseISO, differenceInDays } from 'date-fns';
import { es } from 'date-fns/locale';

export const formatFecha = (iso: string) => {
  try { return format(parseISO(iso), 'dd/MM/yyyy', { locale: es }); }
  catch { return iso; }
};

export const formatFechaHora = (iso: string) => {
  try { return format(parseISO(iso), "dd/MM/yyyy HH:mm", { locale: es }); }
  catch { return iso; }
};

export const formatRelativo = (iso: string) => {
  try { return formatDistanceToNow(parseISO(iso), { addSuffix: true, locale: es }); }
  catch { return iso; }
};

export const diasRestantes = (fechaFin: string): number => {
  try { return differenceInDays(parseISO(fechaFin), new Date()); }
  catch { return 0; }
};

export const formatBytes = (bytes: number) => {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / 1048576).toFixed(1) + ' MB';
};

export const porcentajeColor = (pct: number) => {
  if (pct >= 80) return 'text-green-600';
  if (pct >= 50) return 'text-yellow-600';
  if (pct >= 20) return 'text-orange-500';
  return 'text-red-500';
};
EOF

# =============================================================
# 8. ENTRY POINT + CSS + ROUTER
# =============================================================
echo "  🚀 Entry point + Router..."

cat > $S/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body { @apply bg-gray-50 text-gray-900; }
}

@layer components {
  .btn-primary { @apply bg-primary-600 text-white px-4 py-2 rounded-lg hover:bg-primary-700 transition font-medium text-sm disabled:opacity-50; }
  .btn-secondary { @apply bg-white border border-gray-300 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-50 transition font-medium text-sm; }
  .btn-danger { @apply bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition font-medium text-sm; }
  .input { @apply w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500; }
  .card { @apply bg-white rounded-xl shadow-sm border border-gray-200 p-5; }
}
EOF

cat > $S/main.tsx << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </React.StrictMode>
);
EOF

cat > $S/App.tsx << 'EOF'
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
EOF

# =============================================================
# 9. LAYOUT COMPONENTS
# =============================================================
echo "  🏗️  Layout components..."

cat > $S/components/layout/MainLayout.tsx << 'EOF'
import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import Header from './Header';
import { useAppStore } from '@/store/appStore';

export default function MainLayout() {
  const sidebarOpen = useAppStore((s) => s.sidebarOpen);
  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar />
      <div className={`flex-1 flex flex-col overflow-hidden transition-all ${sidebarOpen ? 'ml-64' : 'ml-16'}`}>
        <Header />
        <main className="flex-1 overflow-auto p-6 bg-gray-50">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
EOF

cat > $S/components/layout/Sidebar.tsx << 'EOF'
import { NavLink } from 'react-router-dom';
import { useAppStore } from '@/store/appStore';
import { useAuth } from '@/hooks/useAuth';
import { LayoutDashboard, Columns3, ListTodo, ClipboardCheck, ChevronLeft, ChevronRight } from 'lucide-react';
import clsx from 'clsx';

const LINKS = [
  { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/kanban', label: 'Kanban', icon: Columns3 },
  { to: '/tareas', label: 'Tareas', icon: ListTodo },
  { to: '/mis-tareas', label: 'Mis Tareas', icon: ClipboardCheck },
];

export default function Sidebar() {
  const { sidebarOpen, toggleSidebar } = useAppStore();
  const { user } = useAuth();

  return (
    <aside className={clsx(
      'fixed left-0 top-0 h-screen bg-gray-900 text-white flex flex-col z-30 transition-all',
      sidebarOpen ? 'w-64' : 'w-16'
    )}>
      <div className="h-16 flex items-center px-4 border-b border-gray-700">
        {sidebarOpen && <span className="text-lg font-bold text-green-400">SmartGob</span>}
        <button onClick={toggleSidebar} className="ml-auto text-gray-400 hover:text-white">
          {sidebarOpen ? <ChevronLeft size={20} /> : <ChevronRight size={20} />}
        </button>
      </div>
      <nav className="flex-1 py-4 space-y-1">
        {LINKS.map(({ to, label, icon: Icon }) => (
          <NavLink key={to} to={to}
            className={({ isActive }) => clsx(
              'flex items-center gap-3 px-4 py-2.5 text-sm transition-colors',
              isActive ? 'bg-primary-600 text-white' : 'text-gray-300 hover:bg-gray-800 hover:text-white'
            )}>
            <Icon size={20} />
            {sidebarOpen && <span>{label}</span>}
          </NavLink>
        ))}
      </nav>
      {sidebarOpen && user && (
        <div className="p-4 border-t border-gray-700 text-xs text-gray-400">
          <p className="text-white font-medium truncate">{user.nombreCompleto}</p>
          <p className="truncate">{user.correo}</p>
        </div>
      )}
    </aside>
  );
}
EOF

cat > $S/components/layout/Header.tsx << 'EOF'
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
EOF

# =============================================================
# 10. COMMON COMPONENTS
# =============================================================
echo "  🧩 Common components..."

cat > $S/components/common/Badge.tsx << 'EOF'
import clsx from 'clsx';

interface BadgeProps {
  label: string;
  color?: string;
  bgColor?: string;
  className?: string;
}

export default function Badge({ label, color, bgColor, className }: BadgeProps) {
  return (
    <span className={clsx('inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium', className)}
      style={{ color: color || '#374151', backgroundColor: bgColor || '#F3F4F6' }}>
      {label}
    </span>
  );
}
EOF

cat > $S/components/common/ProgressBar.tsx << 'EOF'
import clsx from 'clsx';

interface ProgressBarProps { value: number; className?: string; }

export default function ProgressBar({ value, className }: ProgressBarProps) {
  const color = value >= 80 ? 'bg-green-500' : value >= 50 ? 'bg-yellow-500' : value >= 20 ? 'bg-orange-500' : 'bg-red-500';
  return (
    <div className={clsx('h-2 bg-gray-200 rounded-full overflow-hidden', className)}>
      <div className={clsx('h-full rounded-full transition-all', color)}
        style={{ width: `${Math.min(100, Math.max(0, value))}%` }} />
    </div>
  );
}
EOF

cat > $S/components/common/Spinner.tsx << 'EOF'
export default function Spinner({ className = '' }: { className?: string }) {
  return (
    <div className={`flex items-center justify-center py-12 ${className}`}>
      <div className="w-8 h-8 border-3 border-primary-200 border-t-primary-600 rounded-full animate-spin" />
    </div>
  );
}
EOF

cat > $S/components/common/EmptyState.tsx << 'EOF'
import { Inbox } from 'lucide-react';

interface EmptyStateProps { message?: string; icon?: React.ReactNode; }

export default function EmptyState({ message = 'Sin datos', icon }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-gray-400">
      {icon || <Inbox size={48} strokeWidth={1} />}
      <p className="mt-3 text-sm">{message}</p>
    </div>
  );
}
EOF

# =============================================================
# 11. PAGES
# =============================================================
echo "  📄 Pages..."

cat > $S/pages/LoginPage.tsx << 'EOF'
import { useState, FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';
import { authApi } from '@/api/auth';
import toast from 'react-hot-toast';

export default function LoginPage() {
  const [usuario, setUsuario] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const login = useAuthStore((s) => s.login);
  const navigate = useNavigate();

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const auth = await authApi.login({ usuario, password });
      login(auth);
      toast.success(`Bienvenido, ${auth.nombreCompleto}`);
      navigate('/dashboard');
    } catch (err: any) {
      toast.error(err.response?.data?.detail || 'Credenciales inválidas');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-white">Smart<span className="text-green-400">Gob</span></h1>
          <p className="text-gray-400 mt-2">Gestión de Proyectos</p>
        </div>
        <form onSubmit={handleSubmit} className="bg-white rounded-2xl shadow-xl p-8 space-y-5">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Cédula o Correo</label>
            <input type="text" value={usuario} onChange={(e) => setUsuario(e.target.value)}
              className="input" placeholder="0900000001" required autoFocus />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Contraseña</label>
            <input type="password" value={password} onChange={(e) => setPassword(e.target.value)}
              className="input" placeholder="••••••••" required />
          </div>
          <button type="submit" disabled={loading}
            className="btn-primary w-full py-2.5 text-base">
            {loading ? 'Ingresando...' : 'Ingresar'}
          </button>
        </form>
      </div>
    </div>
  );
}
EOF

cat > $S/pages/DashboardPage.tsx << 'EOF'
import { useAuth } from '@/hooks/useAuth';
import { useApi } from '@/hooks/useApi';
import { useAppStore } from '@/store/appStore';
import { dashboardApi } from '@/api/dashboard';
import Spinner from '@/components/common/Spinner';
import ProgressBar from '@/components/common/ProgressBar';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { AlertTriangle, CheckCircle, Clock, ListTodo } from 'lucide-react';

const COLORS = ['#3B82F6', '#F59E0B', '#8B5CF6', '#10B981', '#6B7280', '#EF4444'];

export default function DashboardPage() {
  const { isSuperUsuario } = useAuth();
  const { selectedContratoId, selectedEquipoId } = useAppStore();

  const { data: dashSuper, loading: l1 } = useApi(() => dashboardApi.super(), []);
  const { data: dashEquipo, loading: l2 } = useApi(
    () => dashboardApi.equipo(selectedContratoId || undefined), [selectedContratoId]);
  const { data: alertas, loading: l3 } = useApi(
    () => dashboardApi.alertasSla(selectedContratoId || undefined, selectedEquipoId || undefined),
    [selectedContratoId, selectedEquipoId]);

  if (l1 || l2 || l3) return <Spinner />;

  // KPIs del primer contrato o acumulado
  const totalTareas = dashSuper?.reduce((a, c) => a + c.totalTareas, 0) ?? 0;
  const finalizadas = dashSuper?.reduce((a, c) => a + c.tareasFinalizadas, 0) ?? 0;
  const vencidas = dashSuper?.reduce((a, c) => a + c.tareasVencidas, 0) ?? 0;
  const criticas = dashSuper?.reduce((a, c) => a + c.tareasCriticas, 0) ?? 0;

  const pieData = dashEquipo?.map((eq) => ({ name: eq.equipoNombre, value: eq.totalTareas })) ?? [];
  const barData = dashEquipo?.map((eq) => ({
    name: eq.equipoNombre.substring(0, 12),
    ejecutando: eq.ejecutando, revision: eq.enRevision,
    finalizadas: eq.finalizadas, vencidas: eq.vencidas,
  })) ?? [];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>

      {/* KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <KpiCard icon={<ListTodo />} label="Total Tareas" value={totalTareas} color="bg-blue-50 text-blue-600" />
        <KpiCard icon={<CheckCircle />} label="Finalizadas" value={finalizadas} color="bg-green-50 text-green-600" />
        <KpiCard icon={<AlertTriangle />} label="Críticas" value={criticas} color="bg-red-50 text-red-600" />
        <KpiCard icon={<Clock />} label="Vencidas" value={vencidas} color="bg-orange-50 text-orange-600" />
      </div>

      {/* Contratos */}
      {isSuperUsuario && dashSuper && dashSuper.length > 0 && (
        <div className="card">
          <h2 className="text-lg font-semibold mb-4">Resumen por Contrato</h2>
          <div className="space-y-3">
            {dashSuper.map(c => (
              <div key={c.contratoId} className="flex items-center gap-4 py-2 border-b last:border-0">
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-sm truncate">{c.nroContrato} — {c.cliente}</p>
                  <p className="text-xs text-gray-500">{c.diasRestantesContrato} días restantes</p>
                </div>
                <div className="w-32"><ProgressBar value={c.porcentajeAvanceGlobal} /></div>
                <span className="text-sm font-semibold w-12 text-right">{c.porcentajeAvanceGlobal}%</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {barData.length > 0 && (
          <div className="card">
            <h2 className="text-lg font-semibold mb-4">Tareas por Equipo</h2>
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={barData}>
                <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Bar dataKey="ejecutando" fill="#F59E0B" name="Ejecutando" stackId="a" />
                <Bar dataKey="revision" fill="#8B5CF6" name="Revisión" stackId="a" />
                <Bar dataKey="finalizadas" fill="#10B981" name="Finalizadas" stackId="a" />
                <Bar dataKey="vencidas" fill="#EF4444" name="Vencidas" stackId="a" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}
        {pieData.length > 0 && (
          <div className="card">
            <h2 className="text-lg font-semibold mb-4">Distribución por Equipo</h2>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie data={pieData} dataKey="value" nameKey="name" cx="50%" cy="50%"
                  outerRadius={100} label={({ name, percent }) => `${name} ${(percent*100).toFixed(0)}%`}>
                  {pieData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>

      {/* Alertas SLA */}
      {alertas && alertas.length > 0 && (
        <div className="card">
          <h2 className="text-lg font-semibold mb-4 text-red-600 flex items-center gap-2">
            <AlertTriangle size={20} /> Alertas SLA ({alertas.length})
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-gray-500 border-b">
                  <th className="py-2 px-2">Tarea</th><th className="px-2">Prioridad</th>
                  <th className="px-2">Asignado</th><th className="px-2">Vence</th><th className="px-2">Alerta</th>
                </tr>
              </thead>
              <tbody>
                {alertas.slice(0, 10).map(a => (
                  <tr key={a.id} className="border-b last:border-0 hover:bg-gray-50">
                    <td className="py-2 px-2 font-medium">{a.idTarea} — {a.titulo}</td>
                    <td className="px-2"><span style={{ color: a.prioridadColor }}>{a.prioridadNombre}</span></td>
                    <td className="px-2 text-gray-600">{a.asignadoANombre || '—'}</td>
                    <td className="px-2">{a.fechaEstimadaFin}</td>
                    <td className="px-2">
                      <span className={`text-xs font-medium ${a.alertaSla === 'VENCIDA' ? 'text-red-600' : 'text-orange-500'}`}>
                        {a.alertaSla}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

function KpiCard({ icon, label, value, color }: { icon: React.ReactNode; label: string; value: number; color: string }) {
  return (
    <div className="card flex items-center gap-4">
      <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${color}`}>{icon}</div>
      <div>
        <p className="text-2xl font-bold">{value}</p>
        <p className="text-xs text-gray-500">{label}</p>
      </div>
    </div>
  );
}
EOF

cat > $S/pages/KanbanPage.tsx << 'EOF'
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
EOF

cat > $S/pages/TareasPage.tsx << 'EOF'
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
EOF

cat > $S/pages/TareaDetallePage.tsx << 'EOF'
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
EOF

cat > $S/pages/MisTareasPage.tsx << 'EOF'
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
EOF

# =============================================================
echo ""
echo "✅ Commit 7 completado."
echo ""
echo "Archivos creados:"
echo ""
echo "  📋 Configuración:"
echo "    • package.json (deps: react, zustand, axios, recharts, tailwind, lucide, dnd)"
echo "    • vite.config.ts, tsconfig.json, tailwind.config.js, postcss.config.js"
echo "    • index.html"
echo ""
echo "  📐 Tipos + Constantes:"
echo "    • types/index.ts       — 25+ interfaces TypeScript"
echo "    • constants/index.ts   — estados, prioridades, roles, categorías"
echo ""
echo "  🌐 API Client:"
echo "    • api/client.ts        — Axios + JWT interceptor"
echo "    • api/auth.ts          — login, me"
echo "    • api/tareas.ts        — CRUD, kanban, transiciones, comentarios"
echo "    • api/dashboard.ts     — super, equipo, carga, alertas SLA"
echo "    • api/entities.ts      — empresas, colaboradores, contratos, equipos, notificaciones, mensajes"
echo ""
echo "  🏪 Store (Zustand):"
echo "    • store/authStore.ts   — token, user, login/logout"
echo "    • store/appStore.ts    — sidebar, contrato/equipo seleccionado"
echo ""
echo "  🪝 Hooks:"
echo "    • hooks/useApi.ts      — fetcher genérico con loading/error"
echo "    • hooks/useAuth.ts     — helper de permisos y roles"
echo ""
echo "  🏗️  Layout:"
echo "    • layout/MainLayout.tsx — sidebar + header + outlet"
echo "    • layout/Sidebar.tsx    — nav links con iconos"
echo "    • layout/Header.tsx     — selector contrato/equipo + notificaciones"
echo ""
echo "  🧩 Common:"
echo "    • common/Badge.tsx, ProgressBar.tsx, Spinner.tsx, EmptyState.tsx"
echo ""
echo "  📄 Pages:"
echo "    • LoginPage.tsx        — formulario con gradient dark"
echo "    • DashboardPage.tsx    — KPIs, charts Recharts, alertas SLA"
echo "    • KanbanPage.tsx       — tablero 7 columnas con cards"
echo "    • TareasPage.tsx       — tabla paginada con filtros"
echo "    • TareaDetallePage.tsx — detalle, transiciones, histórico, comentarios"
echo "    • MisTareasPage.tsx    — lista personal"
echo ""
echo "  Total: ~30 archivos frontend"
echo ""
echo "Siguiente paso:"
echo "  cd frontend && npm install && cd .."
echo "  git add ."
echo "  git commit -m \"feat: frontend React - tipos, API, store, layout, kanban, dashboard, tareas\""
echo "  git push"

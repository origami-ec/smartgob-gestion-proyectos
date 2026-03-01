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

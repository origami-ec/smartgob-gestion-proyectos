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

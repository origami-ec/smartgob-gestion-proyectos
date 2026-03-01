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

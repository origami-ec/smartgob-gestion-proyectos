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

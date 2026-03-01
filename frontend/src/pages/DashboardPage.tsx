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

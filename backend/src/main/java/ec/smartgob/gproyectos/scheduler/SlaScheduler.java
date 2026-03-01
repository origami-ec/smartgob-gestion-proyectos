package ec.smartgob.gproyectos.scheduler;

import ec.smartgob.gproyectos.domain.model.AsignacionEquipo;
import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.repository.AsignacionEquipoRepository;
import ec.smartgob.gproyectos.repository.TareaRepository;
import ec.smartgob.gproyectos.service.NotificacionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class SlaScheduler {

    private final TareaRepository tareaRepo;
    private final AsignacionEquipoRepository asignacionRepo;
    private final NotificacionService notificacionService;

    @Value("${app.sla.dias-alerta:3}")
    private int diasAlerta;

    @Value("${app.sla.horas-revision:48}")
    private int horasRevision;

    @Value("${app.notificaciones.dias-retener:30}")
    private int diasRetenerNotificaciones;

    /** Cada hora: verificar tareas próximas a vencer y notificar */
    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void verificarSla() {
        log.info("⏰ Ejecutando verificación SLA...");

        // Tareas próximas a vencer
        LocalDate limite = LocalDate.now().plusDays(diasAlerta);
        List<Tarea> proximasVencer = tareaRepo.findProximasAVencer(limite);
        for (Tarea t : proximasVencer) {
            notificarAsignadoYLideres(t, "SLA_PROXIMA_VENCER",
                    "⚠️ Tarea próxima a vencer: " + t.getIdTarea(),
                    String.format("La tarea '%s' vence el %s", t.getTitulo(), t.getFechaEstimadaFin()));
        }

        // Tareas vencidas
        List<Tarea> vencidas = tareaRepo.findVencidas();
        for (Tarea t : vencidas) {
            notificarAsignadoYLideres(t, "SLA_VENCIDA",
                    "🔴 Tarea vencida: " + t.getIdTarea(),
                    String.format("La tarea '%s' venció el %s", t.getTitulo(), t.getFechaEstimadaFin()));
        }

        // Revisiones vencidas (más de X horas en estado TER/TERT sin revisión)
        OffsetDateTime limiteRevision = OffsetDateTime.now().minusHours(horasRevision);
        List<Tarea> revisionesVencidas = tareaRepo.findRevisionesVencidas(limiteRevision);
        for (Tarea t : revisionesVencidas) {
            List<AsignacionEquipo> testers = asignacionRepo
                    .findByEquipoIdAndRol(t.getEquipo().getId(), "TST");
            testers.forEach(ae -> notificacionService.crearNotificacion(
                    ae.getColaborador().getId(), "REVISION_VENCIDA", "TAREA",
                    t.getId(), "⏰ Revisión pendiente: " + t.getIdTarea(),
                    "Tarea '" + t.getTitulo() + "' lleva más de " + horasRevision + "h sin revisar",
                    "/tareas/" + t.getId()));
        }

        log.info("SLA: {} próximas, {} vencidas, {} revisiones pendientes",
                proximasVencer.size(), vencidas.size(), revisionesVencidas.size());
    }

    /** Cada día a las 2 AM: limpiar notificaciones leídas antiguas */
    @Scheduled(cron = "0 0 2 * * *")
    @Transactional
    public void limpiarNotificaciones() {
        int eliminadas = notificacionService.limpiarAntiguas(diasRetenerNotificaciones);
        log.info("🧹 Limpieza: {} notificaciones leídas antiguas eliminadas", eliminadas);
    }

    private void notificarAsignadoYLideres(Tarea t, String tipo, String titulo, String mensaje) {
        String url = "/tareas/" + t.getId();

        // Notificar al asignado
        if (t.getAsignadoA() != null) {
            notificacionService.crearNotificacion(
                    t.getAsignadoA().getId(), tipo, "TAREA", t.getId(), titulo, mensaje, url);
        }
        // Notificar a líderes del equipo
        List<AsignacionEquipo> lideres = asignacionRepo
                .findByEquipoIdAndRol(t.getEquipo().getId(), "LDR");
        lideres.forEach(ae -> notificacionService.crearNotificacion(
                ae.getColaborador().getId(), tipo, "TAREA", t.getId(), titulo, mensaje, url));
    }
}

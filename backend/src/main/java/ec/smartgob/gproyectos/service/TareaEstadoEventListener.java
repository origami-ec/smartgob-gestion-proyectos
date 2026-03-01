package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.event.TareaEstadoCambiadoEvent;
import ec.smartgob.gproyectos.domain.model.AsignacionEquipo;
import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.repository.AsignacionEquipoRepository;
import ec.smartgob.gproyectos.repository.TareaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Escucha cambios de estado de tarea y dispara notificaciones.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class TareaEstadoEventListener {

    private final TareaRepository tareaRepo;
    private final AsignacionEquipoRepository asignacionRepo;
    private final NotificacionService notificacionService;

    @Async
    @EventListener
    @Transactional
    public void onEstadoCambiado(TareaEstadoCambiadoEvent event) {
        Tarea tarea = tareaRepo.findByIdConRelaciones(event.getTareaId()).orElse(null);
        if (tarea == null) return;

        String idTarea = tarea.getIdTarea();
        String titulo = tarea.getTitulo();
        String url = "/tareas/" + tarea.getId();

        switch (event.getEstadoNuevo()) {
            case "EJE" -> {
                // Notificar al líder que una tarea inició ejecución
                notificarLideres(tarea, "TAREA_INICIADA",
                        "Tarea iniciada: " + idTarea,
                        String.format("La tarea '%s' fue iniciada", titulo), url);
            }
            case "TER", "TERT" -> {
                // Notificar a testers que hay tarea pendiente de revisión
                notificarTesters(tarea, "TAREA_PARA_REVISION",
                        "Tarea para revisión: " + idTarea,
                        String.format("La tarea '%s' está lista para revisión", titulo), url);
            }
            case "REV" -> {
                // Notificar al asignado que su tarea está en revisión
                if (tarea.getAsignadoA() != null) {
                    notificacionService.crearNotificacion(
                            tarea.getAsignadoA().getId(), "TAREA_EN_REVISION", "TAREA",
                            tarea.getId(), "Tarea en revisión: " + idTarea,
                            "Tu tarea '" + titulo + "' está siendo revisada", url);
                }
            }
            case "FIN" -> {
                // Notificar al asignado que su tarea fue aprobada
                if (tarea.getAsignadoA() != null) {
                    notificacionService.crearNotificacion(
                            tarea.getAsignadoA().getId(), "TAREA_FINALIZADA", "TAREA",
                            tarea.getId(), "Tarea aprobada: " + idTarea,
                            "Tu tarea '" + titulo + "' fue aprobada y finalizada", url);
                }
            }
            case "ASG" -> {
                // Si es devolución (viene de REV), notificar al asignado
                if ("REV".equals(event.getEstadoAnterior()) && tarea.getAsignadoA() != null) {
                    notificacionService.crearNotificacion(
                            tarea.getAsignadoA().getId(), "TAREA_DEVUELTA", "TAREA",
                            tarea.getId(), "Tarea devuelta: " + idTarea,
                            "La tarea '" + titulo + "' fue devuelta con observaciones", url);
                }
            }
            default -> log.debug("Sin notificación para transición a {}", event.getEstadoNuevo());
        }
    }

    private void notificarLideres(Tarea tarea, String tipo, String titulo, String mensaje, String url) {
        List<AsignacionEquipo> lideres = asignacionRepo
                .findByEquipoIdAndRol(tarea.getEquipo().getId(), "LDR");
        lideres.forEach(ae -> notificacionService.crearNotificacion(
                ae.getColaborador().getId(), tipo, "TAREA", tarea.getId(), titulo, mensaje, url));
    }

    private void notificarTesters(Tarea tarea, String tipo, String titulo, String mensaje, String url) {
        List<AsignacionEquipo> testers = asignacionRepo
                .findByEquipoIdAndRol(tarea.getEquipo().getId(), "TST");
        testers.forEach(ae -> notificacionService.crearNotificacion(
                ae.getColaborador().getId(), tipo, "TAREA", tarea.getId(), titulo, mensaje, url));
    }
}

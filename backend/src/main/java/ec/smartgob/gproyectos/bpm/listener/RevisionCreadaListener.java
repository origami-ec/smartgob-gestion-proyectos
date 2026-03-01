package ec.smartgob.gproyectos.bpm.listener;

import ec.smartgob.gproyectos.repository.AsignacionEquipoRepository;
import ec.smartgob.gproyectos.service.NotificacionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateTask;
import org.activiti.engine.delegate.TaskListener;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Task Listener: cuando se crea la user task "Revisión por Tester",
 * notifica a todos los testers del equipo.
 */
@Component("revisionCreadaListener")
@RequiredArgsConstructor
@Slf4j
public class RevisionCreadaListener implements TaskListener {

    private final NotificacionService notificacionService;
    private final AsignacionEquipoRepository asignacionRepo;

    @Override
    public void notify(DelegateTask delegateTask) {
        String tareaId = (String) delegateTask.getVariable("tareaId");
        String equipoId = (String) delegateTask.getVariable("equipoId");

        if (equipoId != null) {
            try {
                UUID eqId = UUID.fromString(equipoId);
                UUID refId = UUID.fromString(tareaId);
                asignacionRepo.findByEquipoIdAndRol(eqId, "TST")
                        .forEach(ae -> notificacionService.crearNotificacion(
                                ae.getColaborador().getId(), "TAREA_PARA_REVISION",
                                "TAREA", refId,
                                "Tarea lista para revisión",
                                "Hay una tarea pendiente de revisión",
                                "/tareas/" + tareaId));
                log.info("[BPM] Notificación de revisión enviada a testers del equipo {}", equipoId);
            } catch (Exception e) {
                log.warn("[BPM] Error notificando testers: {}", e.getMessage());
            }
        }
    }
}

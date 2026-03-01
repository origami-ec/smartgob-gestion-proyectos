package ec.smartgob.gproyectos.bpm.listener;

import ec.smartgob.gproyectos.service.NotificacionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateTask;
import org.activiti.engine.delegate.TaskListener;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Task Listener: cuando se crea la user task "Asignado",
 * notifica al colaborador asignado.
 */
@Component("asignacionTaskListener")
@RequiredArgsConstructor
@Slf4j
public class AsignacionTaskListener implements TaskListener {

    private final NotificacionService notificacionService;

    @Override
    public void notify(DelegateTask delegateTask) {
        String tareaId = (String) delegateTask.getVariable("tareaId");
        String asignadoAId = (String) delegateTask.getVariable("asignadoAId");

        if (asignadoAId != null && !asignadoAId.isBlank()) {
            try {
                UUID destId = UUID.fromString(asignadoAId);
                UUID refId = UUID.fromString(tareaId);
                notificacionService.crearNotificacion(
                        destId, "TAREA_ASIGNADA", "TAREA", refId,
                        "Nueva tarea asignada",
                        "Se te ha asignado una nueva tarea",
                        "/tareas/" + tareaId);
                log.info("[BPM] Notificación de asignación enviada al colaborador {}", asignadoAId);
            } catch (Exception e) {
                log.warn("[BPM] Error enviando notificación de asignación: {}", e.getMessage());
            }
        }

        // Asignar la task de Activiti al colaborador
        if (asignadoAId != null) {
            delegateTask.setAssignee(asignadoAId);
        }
    }
}

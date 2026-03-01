package ec.smartgob.gproyectos.bpm.listener;

import ec.smartgob.gproyectos.service.NotificacionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateExecution;
import org.activiti.engine.delegate.ExecutionListener;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Execution Listener: se dispara al finalizar el proceso (end event).
 * Notifica al creador y asignado que la tarea fue finalizada.
 */
@Component("tareaFinalizadaListener")
@RequiredArgsConstructor
@Slf4j
public class TareaFinalizadaListener implements ExecutionListener {

    private final NotificacionService notificacionService;

    @Override
    public void notify(DelegateExecution execution) {
        String tareaId = (String) execution.getVariable("tareaId");
        String asignadoAId = (String) execution.getVariable("asignadoAId");
        String creadoPorId = (String) execution.getVariable("creadoPorId");

        UUID refId = UUID.fromString(tareaId);

        if (asignadoAId != null) {
            try {
                notificacionService.crearNotificacion(
                        UUID.fromString(asignadoAId), "TAREA_FINALIZADA",
                        "TAREA", refId,
                        "Tarea finalizada",
                        "Tu tarea ha sido aprobada y finalizada",
                        "/tareas/" + tareaId);
            } catch (Exception e) {
                log.warn("[BPM] Error notificando asignado: {}", e.getMessage());
            }
        }

        if (creadoPorId != null && !creadoPorId.equals(asignadoAId)) {
            try {
                notificacionService.crearNotificacion(
                        UUID.fromString(creadoPorId), "TAREA_FINALIZADA",
                        "TAREA", refId,
                        "Tarea finalizada",
                        "Una tarea que creaste ha sido finalizada",
                        "/tareas/" + tareaId);
            } catch (Exception e) {
                log.warn("[BPM] Error notificando creador: {}", e.getMessage());
            }
        }

        log.info("[BPM] Proceso finalizado para tarea {}, processInstanceId={}",
                tareaId, execution.getProcessInstanceId());
    }
}

package ec.smartgob.gproyectos.bpm.listener;

import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateTask;
import org.activiti.engine.delegate.TaskListener;
import org.springframework.stereotype.Component;

/**
 * Task Listener: se dispara al completar la user task "Ejecutando".
 * Registra métricas de tiempo en ejecución.
 */
@Component("ejecucionCompletaListener")
@Slf4j
public class EjecucionCompletaListener implements TaskListener {

    @Override
    public void notify(DelegateTask delegateTask) {
        String tareaId = (String) delegateTask.getVariable("tareaId");
        String accion = (String) delegateTask.getVariable("accion");
        log.info("[BPM] Ejecución completada para tarea {}, acción: {}", tareaId, accion);
    }
}

package ec.smartgob.gproyectos.bpm.delegate;

import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateExecution;
import org.activiti.engine.delegate.JavaDelegate;
import org.springframework.stereotype.Component;

/**
 * Service Task: REV → ASG. Devuelve la tarea al asignado con observaciones.
 */
@Component("devolverTareaDelegate")
@Slf4j
public class DevolverTareaDelegate implements JavaDelegate {

    @Override
    public void execute(DelegateExecution execution) {
        String tareaId = (String) execution.getVariable("tareaId");
        execution.setVariable("estadoActual", "ASG");
        int devoluciones = execution.getVariable("devoluciones") != null
                ? (int) execution.getVariable("devoluciones") + 1 : 1;
        execution.setVariable("devoluciones", devoluciones);
        log.info("[BPM] Tarea {} → ASG (Devuelta, #{} devolución)", tareaId, devoluciones);
    }
}

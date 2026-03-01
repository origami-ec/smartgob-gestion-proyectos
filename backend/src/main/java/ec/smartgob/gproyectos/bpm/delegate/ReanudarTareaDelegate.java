package ec.smartgob.gproyectos.bpm.delegate;

import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateExecution;
import org.activiti.engine.delegate.JavaDelegate;
import org.springframework.stereotype.Component;

/**
 * Service Task: SUS → EJE. Reanuda la tarea suspendida.
 */
@Component("reanudarTareaDelegate")
@Slf4j
public class ReanudarTareaDelegate implements JavaDelegate {

    @Override
    public void execute(DelegateExecution execution) {
        String tareaId = (String) execution.getVariable("tareaId");
        execution.setVariable("estadoActual", "EJE");
        log.info("[BPM] Tarea {} → EJE (Reanudada)", tareaId);
    }
}

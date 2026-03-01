package ec.smartgob.gproyectos.bpm.delegate;

import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateExecution;
import org.activiti.engine.delegate.JavaDelegate;
import org.springframework.stereotype.Component;

/**
 * Service Task: EJE → SUS. Suspende la tarea.
 */
@Component("suspenderTareaDelegate")
@Slf4j
public class SuspenderTareaDelegate implements JavaDelegate {

    @Override
    public void execute(DelegateExecution execution) {
        String tareaId = (String) execution.getVariable("tareaId");
        execution.setVariable("estadoActual", "SUS");
        log.info("[BPM] Tarea {} → SUS (Suspendida)", tareaId);
    }
}

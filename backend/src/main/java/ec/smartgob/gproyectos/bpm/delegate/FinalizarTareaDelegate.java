package ec.smartgob.gproyectos.bpm.delegate;

import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateExecution;
import org.activiti.engine.delegate.JavaDelegate;
import org.springframework.stereotype.Component;

/**
 * Service Task: REV → FIN. Aprueba y finaliza la tarea (100% avance).
 */
@Component("finalizarTareaDelegate")
@Slf4j
public class FinalizarTareaDelegate implements JavaDelegate {

    @Override
    public void execute(DelegateExecution execution) {
        String tareaId = (String) execution.getVariable("tareaId");
        execution.setVariable("estadoActual", "FIN");
        execution.setVariable("porcentajeAvance", 100);
        log.info("[BPM] Tarea {} → FIN (Finalizada/Aprobada)", tareaId);
    }
}

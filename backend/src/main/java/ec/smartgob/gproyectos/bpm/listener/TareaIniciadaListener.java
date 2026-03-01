package ec.smartgob.gproyectos.bpm.listener;

import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateExecution;
import org.activiti.engine.delegate.ExecutionListener;
import org.springframework.stereotype.Component;

/**
 * Execution Listener: se dispara al iniciar el proceso (start event).
 * Establece variables iniciales del proceso.
 */
@Component("tareaIniciadaListener")
@Slf4j
public class TareaIniciadaListener implements ExecutionListener {

    @Override
    public void notify(DelegateExecution execution) {
        String tareaId = (String) execution.getVariable("tareaId");
        execution.setVariable("estadoActual", "ASG");
        execution.setVariable("devoluciones", 0);
        log.info("[BPM] Proceso iniciado para tarea {}, processInstanceId={}",
                tareaId, execution.getProcessInstanceId());
    }
}

package ec.smartgob.gproyectos.bpm.delegate;

import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateExecution;
import org.activiti.engine.delegate.JavaDelegate;
import org.springframework.stereotype.Component;

/**
 * Service Task: EJE → TER/TERT. Marca terminada y evalúa si fue dentro de plazo.
 */
@Component("terminarTareaDelegate")
@Slf4j
public class TerminarTareaDelegate implements JavaDelegate {

    @Override
    public void execute(DelegateExecution execution) {
        String tareaId = (String) execution.getVariable("tareaId");
        boolean dentroDePlazo = Boolean.TRUE.equals(execution.getVariable("dentroDePlazo"));
        String estado = dentroDePlazo ? "TER" : "TERT";
        execution.setVariable("estadoActual", estado);
        log.info("[BPM] Tarea {} → {} (dentroDePlazo={})", tareaId, estado, dentroDePlazo);
    }
}

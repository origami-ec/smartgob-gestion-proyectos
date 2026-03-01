package ec.smartgob.gproyectos.bpm;

import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.HistoryService;
import org.activiti.engine.RuntimeService;
import org.activiti.engine.TaskService;
import org.activiti.engine.history.HistoricProcessInstance;
import org.activiti.engine.runtime.ProcessInstance;
import org.activiti.engine.task.Task;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Servicio puente entre la lógica de negocio y el motor Activiti BPM.
 * Gestiona el ciclo de vida del proceso BPMN para cada tarea.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class BpmTareaService {

    private static final String PROCESS_KEY = "tareaLifecycle";

    private final RuntimeService runtimeService;
    private final TaskService taskService;
    private final HistoryService historyService;

    // ── Iniciar proceso para nueva tarea ───────────────────────

    /**
     * Inicia una instancia del proceso tareaLifecycle para la tarea dada.
     * @return processInstanceId del proceso Activiti
     */
    public String iniciarProceso(Tarea tarea) {
        Map<String, Object> variables = buildVariables(tarea);

        ProcessInstance instance = runtimeService.startProcessInstanceByKey(
                PROCESS_KEY,
                tarea.getId().toString(),  // businessKey = tareaId
                variables);

        log.info("[BPM] Proceso iniciado: processId={}, businessKey={}",
                instance.getId(), tarea.getId());
        return instance.getId();
    }

    // ── Avanzar proceso (completar task actual) ────────────────

    /**
     * Completa la task activa del proceso asociado a la tarea,
     * pasando la acción que determina el flujo en los gateways.
     */
    public void avanzarProceso(UUID tareaId, String accion, Map<String, Object> variablesExtra) {
        Task activeTask = findActiveTask(tareaId);
        if (activeTask == null) {
            log.warn("[BPM] No hay task activa para tarea {}", tareaId);
            return;
        }

        Map<String, Object> vars = new HashMap<>();
        vars.put("accion", accion);
        if (variablesExtra != null) {
            vars.putAll(variablesExtra);
        }

        taskService.complete(activeTask.getId(), vars);
        log.info("[BPM] Task '{}' completada para tarea {} con acción={}",
                activeTask.getName(), tareaId, accion);
    }

    /**
     * Completa la task activa sin variables extra.
     */
    public void avanzarProceso(UUID tareaId, String accion) {
        avanzarProceso(tareaId, accion, null);
    }

    // ── Consultar estado del proceso ───────────────────────────

    /**
     * Obtiene la task activa (user task) del proceso de una tarea.
     */
    public Task findActiveTask(UUID tareaId) {
        List<Task> tasks = taskService.createTaskQuery()
                .processInstanceBusinessKey(tareaId.toString())
                .active()
                .list();
        return tasks.isEmpty() ? null : tasks.get(0);
    }

    /**
     * Obtiene información del estado actual del proceso.
     */
    public BpmEstado obtenerEstadoProceso(UUID tareaId) {
        Task activeTask = findActiveTask(tareaId);
        if (activeTask != null) {
            String estadoActual = (String) runtimeService.getVariable(
                    activeTask.getExecutionId(), "estadoActual");
            return new BpmEstado(
                    activeTask.getProcessInstanceId(),
                    activeTask.getId(),
                    activeTask.getName(),
                    estadoActual,
                    true);
        }

        // Proceso ya terminado — consultar historial
        HistoricProcessInstance historic = historyService
                .createHistoricProcessInstanceQuery()
                .processInstanceBusinessKey(tareaId.toString())
                .singleResult();

        if (historic != null) {
            return new BpmEstado(
                    historic.getId(), null, "Proceso Finalizado", "FIN", false);
        }

        return null;
    }

    /**
     * Verifica si una tarea tiene un proceso BPM activo.
     */
    public boolean tieneProcesoActivo(UUID tareaId) {
        long count = runtimeService.createProcessInstanceQuery()
                .processInstanceBusinessKey(tareaId.toString())
                .active()
                .count();
        return count > 0;
    }

    // ── Claim / Unclaim de tasks ───────────────────────────────

    /**
     * Asigna (claim) la task activa al colaborador indicado.
     */
    public void claimTask(UUID tareaId, UUID colaboradorId) {
        Task task = findActiveTask(tareaId);
        if (task == null) {
            throw new BusinessException("No hay task activa para la tarea");
        }
        taskService.claim(task.getId(), colaboradorId.toString());
        log.info("[BPM] Task '{}' claimed por {}", task.getName(), colaboradorId);
    }

    /**
     * Libera (unclaim) la task activa.
     */
    public void unclaimTask(UUID tareaId) {
        Task task = findActiveTask(tareaId);
        if (task == null) return;
        taskService.unclaim(task.getId());
        log.info("[BPM] Task '{}' unclaimed", task.getName());
    }

    // ── Actualizar variables de proceso ────────────────────────

    /**
     * Actualiza una variable en el proceso activo de una tarea.
     */
    public void actualizarVariable(UUID tareaId, String nombre, Object valor) {
        Task task = findActiveTask(tareaId);
        if (task != null) {
            runtimeService.setVariable(task.getExecutionId(), nombre, valor);
        }
    }

    // ── Eliminar proceso ───────────────────────────────────────

    /**
     * Cancela el proceso BPM asociado a una tarea.
     */
    public void cancelarProceso(UUID tareaId, String motivo) {
        List<ProcessInstance> instances = runtimeService.createProcessInstanceQuery()
                .processInstanceBusinessKey(tareaId.toString())
                .active()
                .list();
        for (ProcessInstance pi : instances) {
            runtimeService.deleteProcessInstance(pi.getId(), motivo);
            log.info("[BPM] Proceso {} cancelado para tarea {}: {}", pi.getId(), tareaId, motivo);
        }
    }

    // ── Helpers ────────────────────────────────────────────────

    private Map<String, Object> buildVariables(Tarea tarea) {
        Map<String, Object> vars = new HashMap<>();
        vars.put("tareaId", tarea.getId().toString());
        vars.put("contratoId", tarea.getContrato().getId().toString());
        vars.put("equipoId", tarea.getEquipo().getId().toString());
        vars.put("asignadoAId", tarea.getAsignadoA() != null
                ? tarea.getAsignadoA().getId().toString() : null);
        vars.put("creadoPorId", tarea.getCreadoPor() != null
                ? tarea.getCreadoPor().getId().toString() : null);
        vars.put("prioridad", tarea.getPrioridad());
        vars.put("estadoActual", tarea.getEstado());
        vars.put("dentroDePlazo", true);
        vars.put("devoluciones", 0);
        return vars;
    }

    // ── Record de estado BPM ───────────────────────────────────

    public record BpmEstado(
            String processInstanceId,
            String taskId,
            String taskName,
            String estadoActual,
            boolean activo
    ) {}
}

#!/bin/bash
# ============================================================
# COMMIT 6: BPM Activiti 6 — Proceso BPMN, Delegates, Listeners, Service
# Ejecutar desde la raíz del proyecto: smartgob-gestion-proyectos/
#
# Después:
#   git add .
#   git commit -m "feat: BPM Activiti - proceso tarea-lifecycle, delegates, listeners, servicio BPM"
#   git push
# ============================================================

set -e
B="backend/src/main/java/ec/smartgob/gproyectos"
R="backend/src/main/resources"
echo "📦 Commit 6: BPM Activiti 6"

mkdir -p $B/bpm/{listener,delegate}
mkdir -p $R/processes

# =============================================================
# 1. BPMN 2.0 — Proceso tarea-lifecycle
# =============================================================
echo "  📐 BPMN: tarea-lifecycle.bpmn20.xml..."

cat > $R/processes/tarea-lifecycle.bpmn20.xml << 'BPMNEOF'
<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:activiti="http://activiti.org/bpmn"
             targetNamespace="http://smartgob.tech2go.ec/gestion-proyectos"
             id="tareaLifecycleDefinitions">

  <process id="tareaLifecycle" name="Ciclo de Vida de Tarea" isExecutable="true">

    <!-- ═══════════════════════════════════════════════════════
         VARIABLES DEL PROCESO:
           tareaId        (UUID)   — ID de la tarea
           contratoId     (UUID)   — ID del contrato
           equipoId       (UUID)   — ID del equipo
           asignadoAId    (UUID)   — ID del colaborador asignado
           creadoPorId    (UUID)   — ID de quien creó la tarea
           estadoActual   (String) — estado actual (ASG,EJE,SUS,TER,TERT,REV,FIN)
           prioridad      (String) — CRITICA | ALTA | MEDIA | BAJA
           dentroDePlazo  (boolean)— si la tarea finalizó dentro del plazo
         ═══════════════════════════════════════════════════════ -->

    <!-- ────────────────── INICIO ────────────────── -->
    <startEvent id="start" name="Tarea Creada">
      <extensionElements>
        <activiti:executionListener event="start"
            delegateExpression="${tareaIniciadaListener}" />
      </extensionElements>
    </startEvent>

    <!-- ────────────────── ASG: ASIGNADO ────────────────── -->
    <userTask id="taskAsignado" name="Tarea Asignada"
              activiti:candidateGroups="DEV,DOC,TST">
      <extensionElements>
        <activiti:taskListener event="create"
            delegateExpression="${asignacionTaskListener}" />
      </extensionElements>
    </userTask>

    <sequenceFlow id="flow_start_asg" sourceRef="start" targetRef="taskAsignado" />

    <!-- Gateway: desde ASG el usuario puede Iniciar Ejecución -->
    <exclusiveGateway id="gw_desde_asg" name="Decisión desde Asignado" />
    <sequenceFlow id="flow_asg_gw" sourceRef="taskAsignado" targetRef="gw_desde_asg" />

    <!-- ────────────────── EJE: EJECUTANDO ────────────────── -->
    <serviceTask id="stIniciarEjecucion" name="Iniciar Ejecución"
                 activiti:delegateExpression="${iniciarEjecucionDelegate}">
    </serviceTask>

    <sequenceFlow id="flow_gw_eje" sourceRef="gw_desde_asg" targetRef="stIniciarEjecucion">
      <conditionExpression xsi:type="tFormalExpression">
        ${accion == 'INICIAR'}
      </conditionExpression>
    </sequenceFlow>

    <userTask id="taskEjecutando" name="Tarea en Ejecución"
              activiti:assignee="${asignadoAId}">
      <extensionElements>
        <activiti:taskListener event="complete"
            delegateExpression="${ejecucionCompletaListener}" />
      </extensionElements>
    </userTask>

    <sequenceFlow id="flow_st_eje" sourceRef="stIniciarEjecucion" targetRef="taskEjecutando" />

    <!-- Gateway: desde EJE puede Terminar o Suspender -->
    <exclusiveGateway id="gw_desde_eje" name="Decisión desde Ejecutando" />
    <sequenceFlow id="flow_eje_gw" sourceRef="taskEjecutando" targetRef="gw_desde_eje" />

    <!-- ────────────────── SUS: SUSPENDIDO ────────────────── -->
    <serviceTask id="stSuspender" name="Suspender Tarea"
                 activiti:delegateExpression="${suspenderTareaDelegate}">
    </serviceTask>

    <sequenceFlow id="flow_gw_sus" sourceRef="gw_desde_eje" targetRef="stSuspender">
      <conditionExpression xsi:type="tFormalExpression">
        ${accion == 'SUSPENDER'}
      </conditionExpression>
    </sequenceFlow>

    <userTask id="taskSuspendido" name="Tarea Suspendida"
              activiti:candidateGroups="LDR,ADM">
    </userTask>

    <sequenceFlow id="flow_st_sus" sourceRef="stSuspender" targetRef="taskSuspendido" />

    <!-- Reanudar: SUS → vuelve a EJE -->
    <serviceTask id="stReanudar" name="Reanudar Tarea"
                 activiti:delegateExpression="${reanudarTareaDelegate}">
    </serviceTask>

    <sequenceFlow id="flow_sus_reanudar" sourceRef="taskSuspendido" targetRef="stReanudar" />
    <sequenceFlow id="flow_reanudar_eje" sourceRef="stReanudar" targetRef="taskEjecutando" />

    <!-- ────────────────── TER/TERT: TERMINADO ────────────────── -->
    <serviceTask id="stTerminar" name="Terminar Tarea"
                 activiti:delegateExpression="${terminarTareaDelegate}">
    </serviceTask>

    <sequenceFlow id="flow_gw_ter" sourceRef="gw_desde_eje" targetRef="stTerminar">
      <conditionExpression xsi:type="tFormalExpression">
        ${accion == 'TERMINAR'}
      </conditionExpression>
    </sequenceFlow>

    <!-- ────────────────── REV: EN REVISIÓN ────────────────── -->
    <userTask id="taskRevision" name="Revisión por Tester"
              activiti:candidateGroups="TST">
      <extensionElements>
        <activiti:taskListener event="create"
            delegateExpression="${revisionCreadaListener}" />
      </extensionElements>
    </userTask>

    <sequenceFlow id="flow_ter_rev" sourceRef="stTerminar" targetRef="taskRevision" />

    <!-- Gateway: desde REV puede Aprobar (FIN) o Devolver (ASG) -->
    <exclusiveGateway id="gw_desde_rev" name="Decisión de Revisión" />
    <sequenceFlow id="flow_rev_gw" sourceRef="taskRevision" targetRef="gw_desde_rev" />

    <!-- ────────────────── FIN: FINALIZADA ────────────────── -->
    <serviceTask id="stFinalizar" name="Finalizar Tarea"
                 activiti:delegateExpression="${finalizarTareaDelegate}">
    </serviceTask>

    <sequenceFlow id="flow_gw_fin" sourceRef="gw_desde_rev" targetRef="stFinalizar">
      <conditionExpression xsi:type="tFormalExpression">
        ${accion == 'APROBAR'}
      </conditionExpression>
    </sequenceFlow>

    <endEvent id="end" name="Tarea Finalizada">
      <extensionElements>
        <activiti:executionListener event="end"
            delegateExpression="${tareaFinalizadaListener}" />
      </extensionElements>
    </endEvent>

    <sequenceFlow id="flow_fin_end" sourceRef="stFinalizar" targetRef="end" />

    <!-- ────────────────── DEVOLVER: REV → ASG ────────────────── -->
    <serviceTask id="stDevolver" name="Devolver Tarea"
                 activiti:delegateExpression="${devolverTareaDelegate}">
    </serviceTask>

    <sequenceFlow id="flow_gw_devolver" sourceRef="gw_desde_rev" targetRef="stDevolver">
      <conditionExpression xsi:type="tFormalExpression">
        ${accion == 'DEVOLVER'}
      </conditionExpression>
    </sequenceFlow>

    <!-- Vuelve a Asignado -->
    <sequenceFlow id="flow_devolver_asg" sourceRef="stDevolver" targetRef="taskAsignado" />

  </process>

</definitions>
BPMNEOF

# =============================================================
# 2. DELEGATES — JavaDelegate implementations
# =============================================================
echo "  ⚙️  Delegates..."

cat > $B/bpm/delegate/IniciarEjecucionDelegate.java << 'EOF'
package ec.smartgob.gproyectos.bpm.delegate;

import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateExecution;
import org.activiti.engine.delegate.JavaDelegate;
import org.springframework.stereotype.Component;

/**
 * Service Task: ASG → EJE. Marca la tarea como "en ejecución".
 */
@Component("iniciarEjecucionDelegate")
@Slf4j
public class IniciarEjecucionDelegate implements JavaDelegate {

    @Override
    public void execute(DelegateExecution execution) {
        String tareaId = (String) execution.getVariable("tareaId");
        execution.setVariable("estadoActual", "EJE");
        log.info("[BPM] Tarea {} → EJE (Ejecutando)", tareaId);
    }
}
EOF

cat > $B/bpm/delegate/SuspenderTareaDelegate.java << 'EOF'
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
EOF

cat > $B/bpm/delegate/ReanudarTareaDelegate.java << 'EOF'
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
EOF

cat > $B/bpm/delegate/TerminarTareaDelegate.java << 'EOF'
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
EOF

cat > $B/bpm/delegate/FinalizarTareaDelegate.java << 'EOF'
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
EOF

cat > $B/bpm/delegate/DevolverTareaDelegate.java << 'EOF'
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
EOF

# =============================================================
# 3. LISTENERS — Task & Execution Listeners
# =============================================================
echo "  📡 Listeners..."

cat > $B/bpm/listener/TareaIniciadaListener.java << 'EOF'
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
EOF

cat > $B/bpm/listener/AsignacionTaskListener.java << 'EOF'
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
EOF

cat > $B/bpm/listener/EjecucionCompletaListener.java << 'EOF'
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
EOF

cat > $B/bpm/listener/RevisionCreadaListener.java << 'EOF'
package ec.smartgob.gproyectos.bpm.listener;

import ec.smartgob.gproyectos.repository.AsignacionEquipoRepository;
import ec.smartgob.gproyectos.service.NotificacionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.activiti.engine.delegate.DelegateTask;
import org.activiti.engine.delegate.TaskListener;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Task Listener: cuando se crea la user task "Revisión por Tester",
 * notifica a todos los testers del equipo.
 */
@Component("revisionCreadaListener")
@RequiredArgsConstructor
@Slf4j
public class RevisionCreadaListener implements TaskListener {

    private final NotificacionService notificacionService;
    private final AsignacionEquipoRepository asignacionRepo;

    @Override
    public void notify(DelegateTask delegateTask) {
        String tareaId = (String) delegateTask.getVariable("tareaId");
        String equipoId = (String) delegateTask.getVariable("equipoId");

        if (equipoId != null) {
            try {
                UUID eqId = UUID.fromString(equipoId);
                UUID refId = UUID.fromString(tareaId);
                asignacionRepo.findByEquipoIdAndRol(eqId, "TST")
                        .forEach(ae -> notificacionService.crearNotificacion(
                                ae.getColaborador().getId(), "TAREA_PARA_REVISION",
                                "TAREA", refId,
                                "Tarea lista para revisión",
                                "Hay una tarea pendiente de revisión",
                                "/tareas/" + tareaId));
                log.info("[BPM] Notificación de revisión enviada a testers del equipo {}", equipoId);
            } catch (Exception e) {
                log.warn("[BPM] Error notificando testers: {}", e.getMessage());
            }
        }
    }
}
EOF

cat > $B/bpm/listener/TareaFinalizadaListener.java << 'EOF'
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
EOF

# =============================================================
# 4. BpmTareaService — puente entre Spring y Activiti
# =============================================================
echo "  🔗 BpmTareaService..."

cat > $B/bpm/BpmTareaService.java << 'EOF'
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
EOF

# =============================================================
# 5. BpmController — endpoints de consulta BPM
# =============================================================
echo "  🌐 BpmController..."

cat > $B/controller/BpmController.java << 'EOF'
package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.bpm.BpmTareaService;
import ec.smartgob.gproyectos.dto.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Controller para consultar el estado BPM de las tareas.
 */
@RestController
@RequestMapping("/api/v1/gestion-proyectos/bpm")
@RequiredArgsConstructor
public class BpmController {

    private final BpmTareaService bpmService;

    @GetMapping("/tareas/{tareaId}/estado")
    public ResponseEntity<ApiResponse<BpmTareaService.BpmEstado>> estadoProceso(
            @PathVariable UUID tareaId) {
        BpmTareaService.BpmEstado estado = bpmService.obtenerEstadoProceso(tareaId);
        if (estado == null) {
            return ResponseEntity.ok(ApiResponse.ok(null, "Sin proceso BPM asociado"));
        }
        return ResponseEntity.ok(ApiResponse.ok(estado));
    }

    @GetMapping("/tareas/{tareaId}/activo")
    public ResponseEntity<ApiResponse<Boolean>> procesoActivo(@PathVariable UUID tareaId) {
        return ResponseEntity.ok(ApiResponse.ok(bpmService.tieneProcesoActivo(tareaId)));
    }

    @PostMapping("/tareas/{tareaId}/claim")
    public ResponseEntity<ApiResponse<Void>> claim(
            @PathVariable UUID tareaId, @RequestParam UUID colaboradorId) {
        bpmService.claimTask(tareaId, colaboradorId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Task claimed"));
    }

    @PostMapping("/tareas/{tareaId}/unclaim")
    public ResponseEntity<ApiResponse<Void>> unclaim(@PathVariable UUID tareaId) {
        bpmService.unclaimTask(tareaId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Task unclaimed"));
    }
}
EOF

# =============================================================
# 6. Proceso BPMN de Contrato (simplificado)
# =============================================================
echo "  📐 BPMN: contrato-lifecycle.bpmn20.xml..."

cat > $R/processes/contrato-lifecycle.bpmn20.xml << 'BPMNEOF'
<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:activiti="http://activiti.org/bpmn"
             targetNamespace="http://smartgob.tech2go.ec/gestion-proyectos"
             id="contratoLifecycleDefinitions">

  <process id="contratoLifecycle" name="Ciclo de Vida de Contrato" isExecutable="true">

    <!-- Variables: contratoId, nroContrato, administradorId, estado -->

    <startEvent id="start" name="Contrato Registrado" />

    <userTask id="taskPlanificacion" name="Planificación"
              activiti:assignee="${administradorId}">
    </userTask>
    <sequenceFlow id="f1" sourceRef="start" targetRef="taskPlanificacion" />

    <exclusiveGateway id="gw1" />
    <sequenceFlow id="f2" sourceRef="taskPlanificacion" targetRef="gw1" />

    <userTask id="taskEjecucion" name="En Ejecución"
              activiti:assignee="${administradorId}">
    </userTask>
    <sequenceFlow id="f3" sourceRef="gw1" targetRef="taskEjecucion">
      <conditionExpression xsi:type="tFormalExpression">${fase == 'EJECUCION'}</conditionExpression>
    </sequenceFlow>

    <exclusiveGateway id="gw2" />
    <sequenceFlow id="f4" sourceRef="taskEjecucion" targetRef="gw2" />

    <userTask id="taskCierre" name="Cierre"
              activiti:assignee="${administradorId}">
    </userTask>
    <sequenceFlow id="f5" sourceRef="gw2" targetRef="taskCierre">
      <conditionExpression xsi:type="tFormalExpression">${fase == 'CIERRE'}</conditionExpression>
    </sequenceFlow>

    <endEvent id="end" name="Contrato Cerrado" />
    <sequenceFlow id="f6" sourceRef="taskCierre" targetRef="end" />

    <!-- Suspender desde ejecución -->
    <userTask id="taskSuspendido" name="Contrato Suspendido"
              activiti:candidateGroups="LDR,ADM">
    </userTask>
    <sequenceFlow id="f7" sourceRef="gw2" targetRef="taskSuspendido">
      <conditionExpression xsi:type="tFormalExpression">${fase == 'SUSPENDIDO'}</conditionExpression>
    </sequenceFlow>
    <sequenceFlow id="f8" sourceRef="taskSuspendido" targetRef="taskEjecucion" />

  </process>

</definitions>
BPMNEOF

# =============================================================
echo ""
echo "✅ Commit 6 completado."
echo ""
echo "Archivos creados:"
echo ""
echo "  📐 BPMN Processes:"
echo "    • tarea-lifecycle.bpmn20.xml   — flujo completo ASG→EJE→TER/TERT→REV→FIN"
echo "    • contrato-lifecycle.bpmn20.xml — planificación→ejecución→cierre"
echo ""
echo "  ⚙️  Delegates (JavaDelegate):"
echo "    • IniciarEjecucionDelegate     — ASG → EJE"
echo "    • SuspenderTareaDelegate       — EJE → SUS"
echo "    • ReanudarTareaDelegate        — SUS → EJE"
echo "    • TerminarTareaDelegate        — EJE → TER/TERT (evalúa plazo)"
echo "    • FinalizarTareaDelegate       — REV → FIN (100% avance)"
echo "    • DevolverTareaDelegate        — REV → ASG (incrementa contador)"
echo ""
echo "  📡 Listeners:"
echo "    • TareaIniciadaListener        — start event, init variables"
echo "    • AsignacionTaskListener       — notifica asignado + claim"
echo "    • EjecucionCompletaListener    — métricas al completar ejecución"
echo "    • RevisionCreadaListener       — notifica testers del equipo"
echo "    • TareaFinalizadaListener      — notifica asignado y creador"
echo ""
echo "  🔗 Servicio BPM:"
echo "    • BpmTareaService              — iniciar, avanzar, claim, unclaim, cancelar"
echo ""
echo "  🌐 Controller:"
echo "    • BpmController                — GET estado, POST claim/unclaim"
echo ""
echo "  Total: 15 archivos (2 BPMN + 6 delegates + 5 listeners + 1 service + 1 controller)"
echo ""
echo "Siguiente paso:"
echo "  git add ."
echo "  git commit -m \"feat: BPM Activiti - proceso tarea-lifecycle, delegates, listeners, servicio BPM\""
echo "  git push"

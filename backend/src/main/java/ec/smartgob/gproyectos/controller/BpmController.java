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

package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.request.ActualizarAvanceRequest;
import ec.smartgob.gproyectos.dto.request.ActualizarTareaRequest;
import ec.smartgob.gproyectos.dto.request.CambiarEstadoRequest;
import ec.smartgob.gproyectos.dto.request.CrearTareaRequest;
import ec.smartgob.gproyectos.dto.response.*;
import ec.smartgob.gproyectos.security.SecurityUtils;
import ec.smartgob.gproyectos.service.HistoricoEstadoService;
import ec.smartgob.gproyectos.service.TareaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/gestion-proyectos/tareas")
@RequiredArgsConstructor
public class TareaController {

    private final TareaService tareaService;
    private final HistoricoEstadoService historicoService;

    // ── Consultas ──────────────────────────────────────────────

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<TareaResponse>> obtener(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(tareaService.obtenerPorId(id)));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<TareaResumenResponse>>> buscar(
            @RequestParam(required = false) UUID contratoId,
            @RequestParam(required = false) UUID equipoId,
            @RequestParam(required = false) String estado,
            @RequestParam(required = false) String prioridad,
            @RequestParam(required = false) String categoria,
            @RequestParam(required = false) UUID asignadoAId,
            @RequestParam(required = false) String busqueda,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(
                tareaService.buscar(contratoId, equipoId, estado, prioridad,
                        categoria, asignadoAId, busqueda, pageable)));
    }

    @GetMapping("/kanban/{equipoId}")
    public ResponseEntity<ApiResponse<Map<String, List<TareaResumenResponse>>>> kanban(
            @PathVariable UUID equipoId,
            @RequestParam(required = false) UUID contratoId) {
        return ResponseEntity.ok(ApiResponse.ok(tareaService.obtenerKanban(equipoId, contratoId)));
    }

    @GetMapping("/mis-tareas")
    public ResponseEntity<ApiResponse<List<TareaResumenResponse>>> misTareas(
            @RequestParam(required = false) String estado) {
        return ResponseEntity.ok(ApiResponse.ok(
                tareaService.misTareas(SecurityUtils.currentUserId(), estado)));
    }

    @GetMapping("/pendientes-revision/{equipoId}")
    public ResponseEntity<ApiResponse<List<TareaResumenResponse>>> pendientesRevision(
            @PathVariable UUID equipoId) {
        return ResponseEntity.ok(ApiResponse.ok(tareaService.pendientesRevision(equipoId)));
    }

    @GetMapping("/{id}/transiciones")
    public ResponseEntity<ApiResponse<List<TransicionPermitidaResponse>>> transicionesPermitidas(
            @PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(
                tareaService.obtenerTransicionesPermitidas(id, SecurityUtils.currentUser())));
    }

    @GetMapping("/{id}/historico")
    public ResponseEntity<ApiResponse<List<HistoricoEstadoResponse>>> historico(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(historicoService.listarPorTarea(id)));
    }

    // ── Mutaciones ─────────────────────────────────────────────

    @PostMapping
    public ResponseEntity<ApiResponse<TareaResponse>> crear(
            @Valid @RequestBody CrearTareaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(
                        tareaService.crear(request, SecurityUtils.currentUser()), "Tarea creada"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<TareaResponse>> actualizar(
            @PathVariable UUID id, @Valid @RequestBody ActualizarTareaRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                tareaService.actualizar(id, request, SecurityUtils.currentUser()), "Tarea actualizada"));
    }

    @PatchMapping("/{id}/estado")
    public ResponseEntity<ApiResponse<TareaResponse>> cambiarEstado(
            @PathVariable UUID id, @Valid @RequestBody CambiarEstadoRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                tareaService.cambiarEstado(id, request, SecurityUtils.currentUser()), "Estado actualizado"));
    }

    @PatchMapping("/{id}/avance")
    public ResponseEntity<ApiResponse<TareaResponse>> actualizarAvance(
            @PathVariable UUID id, @Valid @RequestBody ActualizarAvanceRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                tareaService.actualizarAvance(id, request, SecurityUtils.currentUser()), "Avance actualizado"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> eliminar(@PathVariable UUID id) {
        tareaService.eliminar(id, SecurityUtils.currentUser());
        return ResponseEntity.ok(ApiResponse.ok(null, "Tarea eliminada"));
    }
}

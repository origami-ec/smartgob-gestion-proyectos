package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.request.AsignarMiembroRequest;
import ec.smartgob.gproyectos.dto.request.CrearEquipoRequest;
import ec.smartgob.gproyectos.dto.response.ApiResponse;
import ec.smartgob.gproyectos.dto.response.EquipoResponse;
import ec.smartgob.gproyectos.dto.response.MiembroEquipoResponse;
import ec.smartgob.gproyectos.security.SecurityUtils;
import ec.smartgob.gproyectos.service.EquipoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/gestion-proyectos/equipos")
@RequiredArgsConstructor
public class EquipoController {

    private final EquipoService service;

    @GetMapping("/contrato/{contratoId}")
    public ResponseEntity<ApiResponse<List<EquipoResponse>>> listarPorContrato(
            @PathVariable UUID contratoId) {
        return ResponseEntity.ok(ApiResponse.ok(service.listarPorContrato(contratoId)));
    }

    @GetMapping("/mis-equipos")
    public ResponseEntity<ApiResponse<List<EquipoResponse>>> misEquipos() {
        return ResponseEntity.ok(ApiResponse.ok(
                service.listarPorColaborador(SecurityUtils.currentUserId())));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<EquipoResponse>> obtener(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(service.obtenerPorId(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<EquipoResponse>> crear(
            @Valid @RequestBody CrearEquipoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(service.crear(request), "Equipo creado"));
    }

    @PostMapping("/{equipoId}/miembros")
    public ResponseEntity<ApiResponse<MiembroEquipoResponse>> asignarMiembro(
            @PathVariable UUID equipoId, @Valid @RequestBody AsignarMiembroRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(service.asignarMiembro(equipoId, request), "Miembro asignado"));
    }

    @DeleteMapping("/{equipoId}/miembros/{colaboradorId}")
    public ResponseEntity<ApiResponse<Void>> removerMiembro(
            @PathVariable UUID equipoId, @PathVariable UUID colaboradorId) {
        service.removerMiembro(equipoId, colaboradorId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Miembro removido"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> eliminar(@PathVariable UUID id) {
        service.eliminar(id);
        return ResponseEntity.ok(ApiResponse.ok(null, "Equipo eliminado"));
    }
}

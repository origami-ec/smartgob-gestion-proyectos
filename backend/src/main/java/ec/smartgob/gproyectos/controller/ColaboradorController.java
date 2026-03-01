package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.request.CrearColaboradorRequest;
import ec.smartgob.gproyectos.dto.response.ApiResponse;
import ec.smartgob.gproyectos.dto.response.ColaboradorResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.service.ColaboradorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/gestion-proyectos/colaboradores")
@RequiredArgsConstructor
public class ColaboradorController {

    private final ColaboradorService service;

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ColaboradorResponse>>> buscar(
            @RequestParam(required = false) String busqueda,
            @RequestParam(required = false) String tipo,
            @RequestParam(required = false) UUID empresaId,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(service.buscar(busqueda, tipo, empresaId, pageable)));
    }

    @GetMapping("/activos")
    public ResponseEntity<ApiResponse<List<ColaboradorResponse>>> listarActivos() {
        return ResponseEntity.ok(ApiResponse.ok(service.listarActivos()));
    }

    @GetMapping("/equipo/{equipoId}")
    public ResponseEntity<ApiResponse<List<ColaboradorResponse>>> listarPorEquipo(@PathVariable UUID equipoId) {
        return ResponseEntity.ok(ApiResponse.ok(service.listarPorEquipo(equipoId)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ColaboradorResponse>> obtener(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(service.obtenerPorId(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ColaboradorResponse>> crear(
            @Valid @RequestBody CrearColaboradorRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(service.crear(request), "Colaborador creado"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ColaboradorResponse>> actualizar(
            @PathVariable UUID id, @Valid @RequestBody CrearColaboradorRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(service.actualizar(id, request), "Colaborador actualizado"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> eliminar(@PathVariable UUID id) {
        service.eliminar(id);
        return ResponseEntity.ok(ApiResponse.ok(null, "Colaborador eliminado"));
    }
}

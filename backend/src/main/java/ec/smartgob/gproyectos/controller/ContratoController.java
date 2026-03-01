package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.request.CrearContratoRequest;
import ec.smartgob.gproyectos.dto.response.ApiResponse;
import ec.smartgob.gproyectos.dto.response.ContratoResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.security.SecurityUtils;
import ec.smartgob.gproyectos.service.ContratoService;
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
@RequestMapping("/api/v1/gestion-proyectos/contratos")
@RequiredArgsConstructor
public class ContratoController {

    private final ContratoService service;

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ContratoResponse>>> buscar(
            @RequestParam(required = false) String estado,
            @RequestParam(required = false) String busqueda,
            @RequestParam(required = false) UUID empresaId,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(service.buscar(estado, busqueda, empresaId, pageable)));
    }

    @GetMapping("/activos")
    public ResponseEntity<ApiResponse<List<ContratoResponse>>> listarActivos() {
        return ResponseEntity.ok(ApiResponse.ok(service.listarActivos()));
    }

    @GetMapping("/mis-contratos")
    public ResponseEntity<ApiResponse<List<ContratoResponse>>> misContratos() {
        return ResponseEntity.ok(ApiResponse.ok(
                service.listarPorColaborador(SecurityUtils.currentUserId())));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ContratoResponse>> obtener(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(service.obtenerPorId(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ContratoResponse>> crear(
            @Valid @RequestBody CrearContratoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(service.crear(request), "Contrato creado"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ContratoResponse>> actualizar(
            @PathVariable UUID id, @Valid @RequestBody CrearContratoRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(service.actualizar(id, request), "Contrato actualizado"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> eliminar(@PathVariable UUID id) {
        service.eliminar(id);
        return ResponseEntity.ok(ApiResponse.ok(null, "Contrato eliminado"));
    }
}

package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.request.CrearEmpresaRequest;
import ec.smartgob.gproyectos.dto.response.ApiResponse;
import ec.smartgob.gproyectos.dto.response.EmpresaResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.service.EmpresaService;
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
@RequestMapping("/api/v1/gestion-proyectos/empresas")
@RequiredArgsConstructor
public class EmpresaController {

    private final EmpresaService service;

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<EmpresaResponse>>> buscar(
            @RequestParam(required = false) String busqueda,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(service.buscar(busqueda, pageable)));
    }

    @GetMapping("/activas")
    public ResponseEntity<ApiResponse<List<EmpresaResponse>>> listarActivas() {
        return ResponseEntity.ok(ApiResponse.ok(service.listarActivas()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<EmpresaResponse>> obtener(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(service.obtenerPorId(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<EmpresaResponse>> crear(@Valid @RequestBody CrearEmpresaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(service.crear(request), "Empresa creada"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<EmpresaResponse>> actualizar(
            @PathVariable UUID id, @Valid @RequestBody CrearEmpresaRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(service.actualizar(id, request), "Empresa actualizada"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> eliminar(@PathVariable UUID id) {
        service.eliminar(id);
        return ResponseEntity.ok(ApiResponse.ok(null, "Empresa eliminada"));
    }
}

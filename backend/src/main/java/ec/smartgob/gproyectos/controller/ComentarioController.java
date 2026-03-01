package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.request.CrearComentarioRequest;
import ec.smartgob.gproyectos.dto.response.ApiResponse;
import ec.smartgob.gproyectos.dto.response.ComentarioResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.security.SecurityUtils;
import ec.smartgob.gproyectos.service.ComentarioTareaService;
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
@RequestMapping("/api/v1/gestion-proyectos/tareas/{tareaId}/comentarios")
@RequiredArgsConstructor
public class ComentarioController {

    private final ComentarioTareaService service;

    @GetMapping
    public ResponseEntity<ApiResponse<List<ComentarioResponse>>> listar(@PathVariable UUID tareaId) {
        return ResponseEntity.ok(ApiResponse.ok(service.listarPorTarea(tareaId)));
    }

    @GetMapping("/paginado")
    public ResponseEntity<ApiResponse<PageResponse<ComentarioResponse>>> listarPaginado(
            @PathVariable UUID tareaId, @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(service.listarPorTareaPaginado(tareaId, pageable)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ComentarioResponse>> crear(
            @PathVariable UUID tareaId, @Valid @RequestBody CrearComentarioRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(
                        service.crear(tareaId, request, SecurityUtils.currentUserId()), "Comentario agregado"));
    }

    @DeleteMapping("/{comentarioId}")
    public ResponseEntity<ApiResponse<Void>> eliminar(
            @PathVariable UUID tareaId, @PathVariable UUID comentarioId) {
        service.eliminar(comentarioId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Comentario eliminado"));
    }
}

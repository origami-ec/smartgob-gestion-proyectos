package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.response.AdjuntoResponse;
import ec.smartgob.gproyectos.dto.response.ApiResponse;
import ec.smartgob.gproyectos.security.SecurityUtils;
import ec.smartgob.gproyectos.service.AdjuntoTareaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/gestion-proyectos/tareas/{tareaId}/adjuntos")
@RequiredArgsConstructor
public class AdjuntoController {

    private final AdjuntoTareaService service;

    @GetMapping
    public ResponseEntity<ApiResponse<List<AdjuntoResponse>>> listar(@PathVariable UUID tareaId) {
        return ResponseEntity.ok(ApiResponse.ok(service.listarPorTarea(tareaId)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AdjuntoResponse>> subir(
            @PathVariable UUID tareaId, @RequestParam("file") MultipartFile file) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(
                        service.subir(tareaId, file, SecurityUtils.currentUserId()), "Archivo subido"));
    }

    @DeleteMapping("/{adjuntoId}")
    public ResponseEntity<ApiResponse<Void>> eliminar(
            @PathVariable UUID tareaId, @PathVariable UUID adjuntoId) {
        service.eliminar(adjuntoId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Adjunto eliminado"));
    }
}

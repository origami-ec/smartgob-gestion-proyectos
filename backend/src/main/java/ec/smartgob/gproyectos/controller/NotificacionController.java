package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.response.ApiResponse;
import ec.smartgob.gproyectos.dto.response.NotificacionResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.security.SecurityUtils;
import ec.smartgob.gproyectos.service.NotificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/gestion-proyectos/notificaciones")
@RequiredArgsConstructor
public class NotificacionController {

    private final NotificacionService service;

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<NotificacionResponse>>> listar(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(
                service.listar(SecurityUtils.currentUserId(), pageable)));
    }

    @GetMapping("/no-leidas")
    public ResponseEntity<ApiResponse<List<NotificacionResponse>>> noLeidas() {
        return ResponseEntity.ok(ApiResponse.ok(
                service.noLeidas(SecurityUtils.currentUserId())));
    }

    @GetMapping("/no-leidas/count")
    public ResponseEntity<ApiResponse<Long>> contarNoLeidas() {
        return ResponseEntity.ok(ApiResponse.ok(
                service.contarNoLeidas(SecurityUtils.currentUserId())));
    }

    @PatchMapping("/{id}/leida")
    public ResponseEntity<ApiResponse<Void>> marcarLeida(@PathVariable UUID id) {
        service.marcarLeida(id, SecurityUtils.currentUserId());
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @PatchMapping("/marcar-todas-leidas")
    public ResponseEntity<ApiResponse<Void>> marcarTodasLeidas() {
        service.marcarTodasLeidas(SecurityUtils.currentUserId());
        return ResponseEntity.ok(ApiResponse.ok(null, "Todas marcadas como leídas"));
    }
}

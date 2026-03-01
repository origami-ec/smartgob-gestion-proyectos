package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.request.EnviarMensajeRequest;
import ec.smartgob.gproyectos.dto.response.ApiResponse;
import ec.smartgob.gproyectos.dto.response.MensajeResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.security.SecurityUtils;
import ec.smartgob.gproyectos.service.MensajeService;
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
@RequestMapping("/api/v1/gestion-proyectos/mensajes")
@RequiredArgsConstructor
public class MensajeController {

    private final MensajeService service;

    @GetMapping("/bandeja")
    public ResponseEntity<ApiResponse<PageResponse<MensajeResponse>>> bandeja(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(
                service.bandejaEntrada(SecurityUtils.currentUserId(), pageable)));
    }

    @GetMapping("/equipo/{equipoId}")
    public ResponseEntity<ApiResponse<PageResponse<MensajeResponse>>> porEquipo(
            @PathVariable UUID equipoId, @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(service.mensajesEquipo(equipoId, pageable)));
    }

    @GetMapping("/contrato/{contratoId}")
    public ResponseEntity<ApiResponse<PageResponse<MensajeResponse>>> porContrato(
            @PathVariable UUID contratoId, @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(service.mensajesContrato(contratoId, pageable)));
    }

    @GetMapping("/conversacion/{otroUsuarioId}")
    public ResponseEntity<ApiResponse<List<MensajeResponse>>> conversacion(
            @PathVariable UUID otroUsuarioId) {
        return ResponseEntity.ok(ApiResponse.ok(
                service.conversacionDirecta(SecurityUtils.currentUserId(), otroUsuarioId)));
    }

    @GetMapping("/no-leidos/count")
    public ResponseEntity<ApiResponse<Long>> contarNoLeidos() {
        return ResponseEntity.ok(ApiResponse.ok(
                service.contarNoLeidos(SecurityUtils.currentUserId())));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<MensajeResponse>> enviar(
            @Valid @RequestBody EnviarMensajeRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(
                        service.enviar(request, SecurityUtils.currentUserId()), "Mensaje enviado"));
    }

    @PatchMapping("/{mensajeId}/leido")
    public ResponseEntity<ApiResponse<Void>> marcarLeido(@PathVariable UUID mensajeId) {
        service.marcarLeido(mensajeId, SecurityUtils.currentUserId());
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @PatchMapping("/marcar-todos-leidos")
    public ResponseEntity<ApiResponse<Void>> marcarTodosLeidos() {
        service.marcarTodosLeidos(SecurityUtils.currentUserId());
        return ResponseEntity.ok(ApiResponse.ok(null, "Todos marcados como leídos"));
    }
}

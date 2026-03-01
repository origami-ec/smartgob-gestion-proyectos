#!/bin/bash
# ============================================================
# COMMIT 5: Controllers — REST API completa
# Ejecutar desde la raíz del proyecto: smartgob-gestion-proyectos/
#
# Después:
#   git add .
#   git commit -m "feat: controllers REST - auth, CRUD, kanban, dashboard, notificaciones"
#   git push
# ============================================================

set -e
B="backend/src/main/java/ec/smartgob/gproyectos"
echo "📦 Commit 5: Controllers (REST API)"

mkdir -p $B/controller

API="/api/v1/gestion-proyectos"

# =============================================================
# Helper — extraer usuario autenticado
# =============================================================
echo "  🔧 SecurityUtils..."

cat > $B/security/SecurityUtils.java << 'EOF'
package ec.smartgob.gproyectos.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

/**
 * Utilitario para obtener el usuario autenticado desde el SecurityContext.
 */
public final class SecurityUtils {

    private SecurityUtils() {}

    public static SmartGobUserDetails currentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof SmartGobUserDetails ud)) {
            throw new IllegalStateException("No hay usuario autenticado");
        }
        return ud;
    }

    public static UUID currentUserId() {
        return currentUser().getColaboradorId();
    }

    public static boolean isSuperUsuario() {
        return currentUser().isEsSuperUsuario();
    }
}
EOF

# =============================================================
# AuthController
# =============================================================
echo "  🔐 AuthController..."

cat > $B/controller/AuthController.java << 'EOF'
package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.request.LoginRequest;
import ec.smartgob.gproyectos.dto.response.ApiResponse;
import ec.smartgob.gproyectos.dto.response.AuthResponse;
import ec.smartgob.gproyectos.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse auth = authService.login(request);
        return ResponseEntity.ok(ApiResponse.ok(auth, "Login exitoso"));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<AuthResponse>> me() {
        var user = ec.smartgob.gproyectos.security.SecurityUtils.currentUser();
        AuthResponse resp = AuthResponse.builder()
                .colaboradorId(user.getColaboradorId())
                .nombreCompleto(user.getNombreCompleto())
                .correo(user.getCorreo())
                .esSuperUsuario(user.isEsSuperUsuario())
                .build();
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }
}
EOF

# =============================================================
# EmpresaController
# =============================================================
echo "  🏢 EmpresaController..."

cat > $B/controller/EmpresaController.java << 'EOF'
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
EOF

# =============================================================
# ColaboradorController
# =============================================================
echo "  👤 ColaboradorController..."

cat > $B/controller/ColaboradorController.java << 'EOF'
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
EOF

# =============================================================
# ContratoController
# =============================================================
echo "  📋 ContratoController..."

cat > $B/controller/ContratoController.java << 'EOF'
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
EOF

# =============================================================
# EquipoController
# =============================================================
echo "  👥 EquipoController..."

cat > $B/controller/EquipoController.java << 'EOF'
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
EOF

# =============================================================
# TareaController — el más extenso
# =============================================================
echo "  📝 TareaController..."

cat > $B/controller/TareaController.java << 'EOF'
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
EOF

# =============================================================
# ComentarioController
# =============================================================
echo "  💬 ComentarioController..."

cat > $B/controller/ComentarioController.java << 'EOF'
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
EOF

# =============================================================
# AdjuntoController
# =============================================================
echo "  📎 AdjuntoController..."

cat > $B/controller/AdjuntoController.java << 'EOF'
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
EOF

# =============================================================
# MensajeController
# =============================================================
echo "  ✉️  MensajeController..."

cat > $B/controller/MensajeController.java << 'EOF'
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
EOF

# =============================================================
# NotificacionController
# =============================================================
echo "  🔔 NotificacionController..."

cat > $B/controller/NotificacionController.java << 'EOF'
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
EOF

# =============================================================
# DashboardController
# =============================================================
echo "  📊 DashboardController..."

cat > $B/controller/DashboardController.java << 'EOF'
package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.dto.response.*;
import ec.smartgob.gproyectos.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/gestion-proyectos/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService service;

    @GetMapping("/super")
    public ResponseEntity<ApiResponse<List<DashboardSuperResponse>>> dashboardSuper() {
        return ResponseEntity.ok(ApiResponse.ok(service.dashboardSuper()));
    }

    @GetMapping("/equipo")
    public ResponseEntity<ApiResponse<List<DashboardEquipoResponse>>> dashboardEquipo(
            @RequestParam(required = false) UUID contratoId) {
        return ResponseEntity.ok(ApiResponse.ok(service.dashboardEquipo(contratoId)));
    }

    @GetMapping("/carga-colaborador")
    public ResponseEntity<ApiResponse<List<CargaColaboradorResponse>>> cargaColaborador(
            @RequestParam(required = false) UUID equipoId) {
        return ResponseEntity.ok(ApiResponse.ok(service.cargaColaborador(equipoId)));
    }

    @GetMapping("/alertas-sla")
    public ResponseEntity<ApiResponse<List<TareaAlertaResponse>>> alertasSla(
            @RequestParam(required = false) UUID contratoId,
            @RequestParam(required = false) UUID equipoId,
            @RequestParam(required = false) String alertaSla) {
        return ResponseEntity.ok(ApiResponse.ok(
                service.tareasConAlerta(contratoId, equipoId, alertaSla)));
    }

    @GetMapping("/kanban-conteo/{equipoId}")
    public ResponseEntity<ApiResponse<Map<String, Long>>> conteoKanban(@PathVariable UUID equipoId) {
        return ResponseEntity.ok(ApiResponse.ok(service.conteoKanban(equipoId)));
    }
}
EOF

# =============================================================
# Scheduler — tareas SLA + limpieza
# =============================================================
echo "  ⏰ SchedulerService..."

cat > $B/scheduler/SlaScheduler.java << 'EOF'
package ec.smartgob.gproyectos.scheduler;

import ec.smartgob.gproyectos.domain.model.AsignacionEquipo;
import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.repository.AsignacionEquipoRepository;
import ec.smartgob.gproyectos.repository.TareaRepository;
import ec.smartgob.gproyectos.service.NotificacionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class SlaScheduler {

    private final TareaRepository tareaRepo;
    private final AsignacionEquipoRepository asignacionRepo;
    private final NotificacionService notificacionService;

    @Value("${app.sla.dias-alerta:3}")
    private int diasAlerta;

    @Value("${app.sla.horas-revision:48}")
    private int horasRevision;

    @Value("${app.notificaciones.dias-retener:30}")
    private int diasRetenerNotificaciones;

    /** Cada hora: verificar tareas próximas a vencer y notificar */
    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void verificarSla() {
        log.info("⏰ Ejecutando verificación SLA...");

        // Tareas próximas a vencer
        LocalDate limite = LocalDate.now().plusDays(diasAlerta);
        List<Tarea> proximasVencer = tareaRepo.findProximasAVencer(limite);
        for (Tarea t : proximasVencer) {
            notificarAsignadoYLideres(t, "SLA_PROXIMA_VENCER",
                    "⚠️ Tarea próxima a vencer: " + t.getIdTarea(),
                    String.format("La tarea '%s' vence el %s", t.getTitulo(), t.getFechaEstimadaFin()));
        }

        // Tareas vencidas
        List<Tarea> vencidas = tareaRepo.findVencidas();
        for (Tarea t : vencidas) {
            notificarAsignadoYLideres(t, "SLA_VENCIDA",
                    "🔴 Tarea vencida: " + t.getIdTarea(),
                    String.format("La tarea '%s' venció el %s", t.getTitulo(), t.getFechaEstimadaFin()));
        }

        // Revisiones vencidas (más de X horas en estado TER/TERT sin revisión)
        OffsetDateTime limiteRevision = OffsetDateTime.now().minusHours(horasRevision);
        List<Tarea> revisionesVencidas = tareaRepo.findRevisionesVencidas(limiteRevision);
        for (Tarea t : revisionesVencidas) {
            List<AsignacionEquipo> testers = asignacionRepo
                    .findByEquipoIdAndRol(t.getEquipo().getId(), "TST");
            testers.forEach(ae -> notificacionService.crearNotificacion(
                    ae.getColaborador().getId(), "REVISION_VENCIDA", "TAREA",
                    t.getId(), "⏰ Revisión pendiente: " + t.getIdTarea(),
                    "Tarea '" + t.getTitulo() + "' lleva más de " + horasRevision + "h sin revisar",
                    "/tareas/" + t.getId()));
        }

        log.info("SLA: {} próximas, {} vencidas, {} revisiones pendientes",
                proximasVencer.size(), vencidas.size(), revisionesVencidas.size());
    }

    /** Cada día a las 2 AM: limpiar notificaciones leídas antiguas */
    @Scheduled(cron = "0 0 2 * * *")
    @Transactional
    public void limpiarNotificaciones() {
        int eliminadas = notificacionService.limpiarAntiguas(diasRetenerNotificaciones);
        log.info("🧹 Limpieza: {} notificaciones leídas antiguas eliminadas", eliminadas);
    }

    private void notificarAsignadoYLideres(Tarea t, String tipo, String titulo, String mensaje) {
        String url = "/tareas/" + t.getId();

        // Notificar al asignado
        if (t.getAsignadoA() != null) {
            notificacionService.crearNotificacion(
                    t.getAsignadoA().getId(), tipo, "TAREA", t.getId(), titulo, mensaje, url);
        }
        // Notificar a líderes del equipo
        List<AsignacionEquipo> lideres = asignacionRepo
                .findByEquipoIdAndRol(t.getEquipo().getId(), "LDR");
        lideres.forEach(ae -> notificacionService.crearNotificacion(
                ae.getColaborador().getId(), tipo, "TAREA", t.getId(), titulo, mensaje, url));
    }
}
EOF

# =============================================================
echo ""
echo "✅ Commit 5 completado."
echo ""
echo "Archivos creados:"
echo "  🔧 SecurityUtils             — helper usuario autenticado"
echo "  🔐 AuthController            — POST /api/auth/login, GET /api/auth/me"
echo "  🏢 EmpresaController         — CRUD /api/v1/gestion-proyectos/empresas"
echo "  👤 ColaboradorController     — CRUD /api/v1/gestion-proyectos/colaboradores"
echo "  📋 ContratoController        — CRUD /api/v1/gestion-proyectos/contratos"
echo "  👥 EquipoController          — CRUD + miembros /api/v1/gestion-proyectos/equipos"
echo "  📝 TareaController           — CRUD, kanban, transiciones, avance, histórico"
echo "  💬 ComentarioController      — CRUD .../tareas/{id}/comentarios"
echo "  📎 AdjuntoController         — upload/delete .../tareas/{id}/adjuntos"
echo "  ✉️  MensajeController         — bandeja, equipo, contrato, directo"
echo "  🔔 NotificacionController    — listar, no-leídas, marcar leídas"
echo "  📊 DashboardController       — super, equipo, carga, alertas SLA"
echo "  ⏰ SlaScheduler              — cron SLA + limpieza notificaciones"
echo ""
echo "  Total: 13 archivos (12 controllers + 1 scheduler + 1 util)"
echo ""
echo "Siguiente paso:"
echo "  git add ."
echo "  git commit -m \"feat: controllers REST, scheduler SLA, SecurityUtils\""
echo "  git push"

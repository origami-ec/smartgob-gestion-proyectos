#!/bin/bash
# ============================================================
# COMMIT 4: Services — lógica de negocio core
# Ejecutar desde la raíz del proyecto: smartgob-gestion-proyectos/
#
# Después:
#   git add .
#   git commit -m "feat: services - lógica de negocio, auth, tareas, dashboard, SLA, notificaciones"
#   git push
# ============================================================

set -e
B="backend/src/main/java/ec/smartgob/gproyectos"
echo "📦 Commit 4: Services (lógica de negocio core)"

mkdir -p $B/service

# =============================================================
# AuthService
# =============================================================
echo "  🔐 AuthService..."

cat > $B/service/AuthService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.AsignacionEquipo;
import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.dto.request.LoginRequest;
import ec.smartgob.gproyectos.dto.response.AuthResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.repository.AsignacionEquipoRepository;
import ec.smartgob.gproyectos.repository.ColaboradorRepository;
import ec.smartgob.gproyectos.security.JwtTokenProvider;
import ec.smartgob.gproyectos.security.SmartGobUserDetails;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final ColaboradorRepository colaboradorRepo;
    private final AsignacionEquipoRepository asignacionRepo;
    private final JwtTokenProvider jwtProvider;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        Colaborador colaborador = colaboradorRepo.findByCedula(request.getUsuario())
                .or(() -> colaboradorRepo.findByCorreo(request.getUsuario()))
                .orElseThrow(() -> new ResourceNotFoundException("Colaborador", request.getUsuario()));

        if (!"ACTIVO".equals(colaborador.getEstado())) {
            throw new BusinessException("La cuenta se encuentra inactiva");
        }
        if (colaborador.getPasswordHash() == null ||
                !passwordEncoder.matches(request.getPassword(), colaborador.getPasswordHash())) {
            throw new BusinessException("Credenciales inválidas");
        }

        SmartGobUserDetails userDetails = buildUserDetails(colaborador);
        String token = jwtProvider.generateToken(userDetails);

        List<AuthResponse.RolEquipoInfo> rolesInfo = userDetails.getRolesPorEquipo().entrySet().stream()
                .map(e -> AuthResponse.RolEquipoInfo.builder()
                        .equipoId(e.getKey())
                        .rol(e.getValue())
                        .build())
                .toList();

        log.info("Login exitoso: {} ({})", colaborador.getNombreCompleto(), colaborador.getCedula());

        return AuthResponse.builder()
                .token(token)
                .colaboradorId(colaborador.getId())
                .nombreCompleto(colaborador.getNombreCompleto())
                .correo(colaborador.getCorreo())
                .esSuperUsuario(Boolean.TRUE.equals(colaborador.getEsSuperUsuario()))
                .roles(rolesInfo)
                .build();
    }

    public SmartGobUserDetails buildUserDetails(Colaborador colaborador) {
        List<AsignacionEquipo> asignaciones = asignacionRepo
                .findByColaboradorIdConEquipo(colaborador.getId());

        Map<UUID, String> rolesPorEquipo = asignaciones.stream()
                .collect(Collectors.toMap(
                        ae -> ae.getEquipo().getId(),
                        AsignacionEquipo::getRolEquipo,
                        (a, b) -> a));

        Map<UUID, Set<UUID>> contratosAccesibles = asignaciones.stream()
                .collect(Collectors.groupingBy(
                        ae -> ae.getEquipo().getContrato().getId(),
                        Collectors.mapping(ae -> ae.getEquipo().getId(), Collectors.toSet())));

        return new SmartGobUserDetails(
                colaborador.getId(), colaborador.getCedula(),
                colaborador.getNombreCompleto(), colaborador.getCorreo(),
                colaborador.getPasswordHash() != null ? colaborador.getPasswordHash() : "",
                Boolean.TRUE.equals(colaborador.getEsSuperUsuario()),
                rolesPorEquipo, contratosAccesibles);
    }
}
EOF

# =============================================================
# EmpresaService
# =============================================================
echo "  🏢 EmpresaService..."

cat > $B/service/EmpresaService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Empresa;
import ec.smartgob.gproyectos.dto.mapper.EmpresaMapper;
import ec.smartgob.gproyectos.dto.request.CrearEmpresaRequest;
import ec.smartgob.gproyectos.dto.response.EmpresaResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.repository.EmpresaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class EmpresaService {

    private final EmpresaRepository empresaRepo;
    private final EmpresaMapper mapper;

    @Transactional(readOnly = true)
    public PageResponse<EmpresaResponse> buscar(String busqueda, Pageable pageable) {
        return PageResponse.of(
                empresaRepo.buscarActivas("ACTIVO", busqueda, pageable),
                mapper::toResponse);
    }

    @Transactional(readOnly = true)
    public List<EmpresaResponse> listarActivas() {
        return empresaRepo.findAllActivas().stream().map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public EmpresaResponse obtenerPorId(UUID id) {
        return mapper.toResponse(findOrThrow(id));
    }

    @Transactional
    public EmpresaResponse crear(CrearEmpresaRequest request) {
        if (empresaRepo.existsByRuc(request.getRuc())) {
            throw new BusinessException("Ya existe una empresa con RUC: " + request.getRuc());
        }
        Empresa entity = mapper.toEntity(request);
        return mapper.toResponse(empresaRepo.save(entity));
    }

    @Transactional
    public EmpresaResponse actualizar(UUID id, CrearEmpresaRequest request) {
        Empresa entity = findOrThrow(id);
        empresaRepo.findByRuc(request.getRuc())
                .filter(e -> !e.getId().equals(id))
                .ifPresent(e -> { throw new BusinessException("RUC ya registrado por otra empresa"); });
        mapper.updateEntity(request, entity);
        return mapper.toResponse(empresaRepo.save(entity));
    }

    @Transactional
    public void eliminar(UUID id) {
        Empresa entity = findOrThrow(id);
        entity.setDeleted(true);
        entity.setEstado("INACTIVO");
        empresaRepo.save(entity);
    }

    private Empresa findOrThrow(UUID id) {
        return empresaRepo.findById(id)
                .filter(e -> !e.getDeleted())
                .orElseThrow(() -> new ResourceNotFoundException("Empresa", id.toString()));
    }
}
EOF

# =============================================================
# ColaboradorService
# =============================================================
echo "  👤 ColaboradorService..."

cat > $B/service/ColaboradorService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.Empresa;
import ec.smartgob.gproyectos.dto.mapper.ColaboradorMapper;
import ec.smartgob.gproyectos.dto.request.CrearColaboradorRequest;
import ec.smartgob.gproyectos.dto.response.ColaboradorResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.repository.ColaboradorRepository;
import ec.smartgob.gproyectos.repository.EmpresaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ColaboradorService {

    private final ColaboradorRepository colaboradorRepo;
    private final EmpresaRepository empresaRepo;
    private final ColaboradorMapper mapper;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public PageResponse<ColaboradorResponse> buscar(String busqueda, String tipo,
                                                     UUID empresaId, Pageable pageable) {
        return PageResponse.of(
                colaboradorRepo.buscar(busqueda, tipo, empresaId, pageable),
                mapper::toResponse);
    }

    @Transactional(readOnly = true)
    public List<ColaboradorResponse> listarActivos() {
        return colaboradorRepo.findAllActivos().stream().map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<ColaboradorResponse> listarPorEquipo(UUID equipoId) {
        return colaboradorRepo.findByEquipoId(equipoId).stream().map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public ColaboradorResponse obtenerPorId(UUID id) {
        return mapper.toResponse(findOrThrow(id));
    }

    @Transactional
    public ColaboradorResponse crear(CrearColaboradorRequest request) {
        if (colaboradorRepo.existsByCedula(request.getCedula())) {
            throw new BusinessException("Ya existe un colaborador con cédula: " + request.getCedula());
        }
        if (colaboradorRepo.existsByCorreo(request.getCorreo())) {
            throw new BusinessException("Ya existe un colaborador con correo: " + request.getCorreo());
        }

        Colaborador entity = mapper.toEntity(request);

        if (request.getEmpresaId() != null) {
            Empresa empresa = empresaRepo.findById(request.getEmpresaId())
                    .orElseThrow(() -> new ResourceNotFoundException("Empresa", request.getEmpresaId().toString()));
            entity.setEmpresa(empresa);
        }
        if (request.getPassword() != null && !request.getPassword().isBlank()) {
            entity.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        }

        return mapper.toResponse(colaboradorRepo.save(entity));
    }

    @Transactional
    public ColaboradorResponse actualizar(UUID id, CrearColaboradorRequest request) {
        Colaborador entity = findOrThrow(id);

        colaboradorRepo.findByCedula(request.getCedula())
                .filter(c -> !c.getId().equals(id))
                .ifPresent(c -> { throw new BusinessException("Cédula ya registrada"); });
        colaboradorRepo.findByCorreo(request.getCorreo())
                .filter(c -> !c.getId().equals(id))
                .ifPresent(c -> { throw new BusinessException("Correo ya registrado"); });

        mapper.updateEntity(request, entity);

        if (request.getEmpresaId() != null) {
            entity.setEmpresa(empresaRepo.findById(request.getEmpresaId())
                    .orElseThrow(() -> new ResourceNotFoundException("Empresa", request.getEmpresaId().toString())));
        }
        if (request.getPassword() != null && !request.getPassword().isBlank()) {
            entity.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        }

        return mapper.toResponse(colaboradorRepo.save(entity));
    }

    @Transactional
    public void eliminar(UUID id) {
        Colaborador entity = findOrThrow(id);
        entity.setDeleted(true);
        entity.setEstado("INACTIVO");
        colaboradorRepo.save(entity);
    }

    public Colaborador findOrThrow(UUID id) {
        return colaboradorRepo.findById(id)
                .filter(c -> !c.getDeleted())
                .orElseThrow(() -> new ResourceNotFoundException("Colaborador", id.toString()));
    }
}
EOF

# =============================================================
# ContratoService
# =============================================================
echo "  📋 ContratoService..."

cat > $B/service/ContratoService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Contrato;
import ec.smartgob.gproyectos.dto.mapper.ContratoMapper;
import ec.smartgob.gproyectos.dto.request.CrearContratoRequest;
import ec.smartgob.gproyectos.dto.response.ContratoResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.repository.ColaboradorRepository;
import ec.smartgob.gproyectos.repository.ContratoRepository;
import ec.smartgob.gproyectos.repository.EmpresaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ContratoService {

    private final ContratoRepository contratoRepo;
    private final ColaboradorRepository colaboradorRepo;
    private final EmpresaRepository empresaRepo;
    private final ContratoMapper mapper;

    @Transactional(readOnly = true)
    public PageResponse<ContratoResponse> buscar(String estado, String busqueda,
                                                  UUID empresaId, Pageable pageable) {
        return PageResponse.of(
                contratoRepo.buscar(estado, busqueda, empresaId, pageable),
                mapper::toResponse);
    }

    @Transactional(readOnly = true)
    public List<ContratoResponse> listarActivos() {
        return contratoRepo.findAllActivos().stream().map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public ContratoResponse obtenerPorId(UUID id) {
        return mapper.toResponse(findOrThrow(id));
    }

    @Transactional(readOnly = true)
    public List<ContratoResponse> listarPorColaborador(UUID colaboradorId) {
        return contratoRepo.findByColaboradorId(colaboradorId).stream()
                .map(mapper::toResponse).toList();
    }

    @Transactional
    public ContratoResponse crear(CrearContratoRequest request) {
        if (contratoRepo.existsByNroContrato(request.getNroContrato())) {
            throw new BusinessException("Ya existe un contrato con número: " + request.getNroContrato());
        }

        Contrato entity = mapper.toEntity(request);

        if (request.getAdministradorId() != null) {
            entity.setAdministrador(colaboradorRepo.findById(request.getAdministradorId())
                    .orElseThrow(() -> new ResourceNotFoundException("Colaborador", request.getAdministradorId().toString())));
        }
        if (request.getEmpresaContratadaId() != null) {
            entity.setEmpresaContratada(empresaRepo.findById(request.getEmpresaContratadaId())
                    .orElseThrow(() -> new ResourceNotFoundException("Empresa", request.getEmpresaContratadaId().toString())));
        }

        return mapper.toResponse(contratoRepo.save(entity));
    }

    @Transactional
    public ContratoResponse actualizar(UUID id, CrearContratoRequest request) {
        Contrato entity = findOrThrow(id);

        contratoRepo.findByNroContrato(request.getNroContrato())
                .filter(c -> !c.getId().equals(id))
                .ifPresent(c -> { throw new BusinessException("Número de contrato ya existe"); });

        mapper.updateEntity(request, entity);
        entity.setFechaFin(request.getFechaInicio().plusDays(request.getPlazoDias()));

        if (request.getAdministradorId() != null) {
            entity.setAdministrador(colaboradorRepo.findById(request.getAdministradorId()).orElse(null));
        }
        if (request.getEmpresaContratadaId() != null) {
            entity.setEmpresaContratada(empresaRepo.findById(request.getEmpresaContratadaId()).orElse(null));
        }

        return mapper.toResponse(contratoRepo.save(entity));
    }

    @Transactional
    public void eliminar(UUID id) {
        Contrato entity = findOrThrow(id);
        entity.setDeleted(true);
        entity.setEstado("INACTIVO");
        contratoRepo.save(entity);
    }

    public Contrato findOrThrow(UUID id) {
        return contratoRepo.findById(id)
                .filter(c -> !c.getDeleted())
                .orElseThrow(() -> new ResourceNotFoundException("Contrato", id.toString()));
    }
}
EOF

# =============================================================
# EquipoService
# =============================================================
echo "  👥 EquipoService..."

cat > $B/service/EquipoService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.AsignacionEquipo;
import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.Contrato;
import ec.smartgob.gproyectos.domain.model.Equipo;
import ec.smartgob.gproyectos.dto.mapper.EquipoMapper;
import ec.smartgob.gproyectos.dto.request.AsignarMiembroRequest;
import ec.smartgob.gproyectos.dto.request.CrearEquipoRequest;
import ec.smartgob.gproyectos.dto.response.EquipoResponse;
import ec.smartgob.gproyectos.dto.response.MiembroEquipoResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.repository.AsignacionEquipoRepository;
import ec.smartgob.gproyectos.repository.ColaboradorRepository;
import ec.smartgob.gproyectos.repository.ContratoRepository;
import ec.smartgob.gproyectos.repository.EquipoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class EquipoService {

    private final EquipoRepository equipoRepo;
    private final AsignacionEquipoRepository asignacionRepo;
    private final ContratoRepository contratoRepo;
    private final ColaboradorRepository colaboradorRepo;
    private final EquipoMapper mapper;

    @Transactional(readOnly = true)
    public List<EquipoResponse> listarPorContrato(UUID contratoId) {
        return equipoRepo.findByContratoId(contratoId).stream()
                .map(this::toResponseConMiembros).toList();
    }

    @Transactional(readOnly = true)
    public List<EquipoResponse> listarPorColaborador(UUID colaboradorId) {
        return equipoRepo.findByColaboradorId(colaboradorId).stream()
                .map(this::toResponseConMiembros).toList();
    }

    @Transactional(readOnly = true)
    public EquipoResponse obtenerPorId(UUID id) {
        return toResponseConMiembros(findOrThrow(id));
    }

    @Transactional
    public EquipoResponse crear(CrearEquipoRequest request) {
        Contrato contrato = contratoRepo.findById(request.getContratoId())
                .orElseThrow(() -> new ResourceNotFoundException("Contrato", request.getContratoId().toString()));

        if (equipoRepo.existsByContratoIdAndNombreAndDeletedFalse(contrato.getId(), request.getNombre())) {
            throw new BusinessException("Ya existe un equipo con ese nombre en el contrato");
        }

        Equipo entity = mapper.toEntity(request);
        entity.setContrato(contrato);
        return mapper.toResponse(equipoRepo.save(entity));
    }

    @Transactional
    public MiembroEquipoResponse asignarMiembro(UUID equipoId, AsignarMiembroRequest request) {
        Equipo equipo = findOrThrow(equipoId);
        Colaborador colaborador = colaboradorRepo.findById(request.getColaboradorId())
                .orElseThrow(() -> new ResourceNotFoundException("Colaborador", request.getColaboradorId().toString()));

        if (asignacionRepo.existsByEquipoIdAndColaboradorIdAndDeletedFalse(equipoId, colaborador.getId())) {
            throw new BusinessException("El colaborador ya está asignado a este equipo");
        }

        AsignacionEquipo asignacion = AsignacionEquipo.builder()
                .equipo(equipo)
                .colaborador(colaborador)
                .rolEquipo(request.getRolEquipo())
                .fechaAsignacion(LocalDate.now())
                .estado("ACTIVO")
                .build();

        return mapper.toMiembroResponse(asignacionRepo.save(asignacion));
    }

    @Transactional
    public void removerMiembro(UUID equipoId, UUID colaboradorId) {
        AsignacionEquipo asignacion = asignacionRepo
                .findByEquipoIdAndColaboradorId(equipoId, colaboradorId)
                .orElseThrow(() -> new ResourceNotFoundException("Asignación", equipoId + "/" + colaboradorId));
        asignacion.setDeleted(true);
        asignacion.setEstado("INACTIVO");
        asignacionRepo.save(asignacion);
    }

    @Transactional
    public void eliminar(UUID id) {
        Equipo entity = findOrThrow(id);
        entity.setDeleted(true);
        entity.setEstado("INACTIVO");
        equipoRepo.save(entity);
    }

    private EquipoResponse toResponseConMiembros(Equipo equipo) {
        EquipoResponse resp = mapper.toResponse(equipo);
        List<AsignacionEquipo> asignaciones = asignacionRepo.findByEquipoIdConColaborador(equipo.getId());
        resp.setMiembros(asignaciones.stream().map(mapper::toMiembroResponse).toList());
        resp.setTotalMiembros(asignaciones.size());
        return resp;
    }

    public Equipo findOrThrow(UUID id) {
        return equipoRepo.findById(id)
                .filter(e -> !e.getDeleted())
                .orElseThrow(() -> new ResourceNotFoundException("Equipo", id.toString()));
    }
}
EOF

# =============================================================
# TareaService — el más complejo
# =============================================================
echo "  📝 TareaService..."

cat > $B/service/TareaService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.enums.EstadoTarea;
import ec.smartgob.gproyectos.domain.event.TareaEstadoCambiadoEvent;
import ec.smartgob.gproyectos.domain.model.*;
import ec.smartgob.gproyectos.dto.mapper.TareaMapper;
import ec.smartgob.gproyectos.dto.request.ActualizarAvanceRequest;
import ec.smartgob.gproyectos.dto.request.ActualizarTareaRequest;
import ec.smartgob.gproyectos.dto.request.CambiarEstadoRequest;
import ec.smartgob.gproyectos.dto.request.CrearTareaRequest;
import ec.smartgob.gproyectos.dto.response.*;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.exception.UnauthorizedTransitionException;
import ec.smartgob.gproyectos.repository.*;
import ec.smartgob.gproyectos.security.SmartGobUserDetails;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class TareaService {

    private final TareaRepository tareaRepo;
    private final ContratoRepository contratoRepo;
    private final EquipoRepository equipoRepo;
    private final ColaboradorRepository colaboradorRepo;
    private final AsignacionEquipoRepository asignacionRepo;
    private final HistoricoEstadoTareaRepository historicoRepo;
    private final ComentarioTareaRepository comentarioRepo;
    private final AdjuntoTareaRepository adjuntoRepo;
    private final TransicionEstadoRepository transicionRepo;
    private final TareaMapper mapper;
    private final ApplicationEventPublisher eventPublisher;

    // ── Consultas ──────────────────────────────────────────────

    @Transactional(readOnly = true)
    public TareaResponse obtenerPorId(UUID id) {
        Tarea tarea = tareaRepo.findByIdConRelaciones(id)
                .orElseThrow(() -> new ResourceNotFoundException("Tarea", id.toString()));
        return enrichResponse(mapper.toResponse(tarea), tarea);
    }

    @Transactional(readOnly = true)
    public PageResponse<TareaResumenResponse> buscar(UUID contratoId, UUID equipoId, String estado,
                                                      String prioridad, String categoria,
                                                      UUID asignadoAId, String busqueda,
                                                      Pageable pageable) {
        return PageResponse.of(
                tareaRepo.buscarConFiltros(contratoId, equipoId, estado, prioridad,
                        categoria, asignadoAId, busqueda, pageable),
                mapper::toResumen);
    }

    @Transactional(readOnly = true)
    public Map<String, List<TareaResumenResponse>> obtenerKanban(UUID equipoId, UUID contratoId) {
        List<Tarea> tareas = tareaRepo.findParaKanban(equipoId, contratoId);
        return tareas.stream()
                .map(mapper::toResumen)
                .collect(Collectors.groupingBy(TareaResumenResponse::getEstado, LinkedHashMap::new, Collectors.toList()));
    }

    @Transactional(readOnly = true)
    public List<TareaResumenResponse> misTareas(UUID colaboradorId, String estado) {
        return tareaRepo.findMisTareas(colaboradorId, estado).stream()
                .map(mapper::toResumen).toList();
    }

    @Transactional(readOnly = true)
    public List<TareaResumenResponse> pendientesRevision(UUID equipoId) {
        return tareaRepo.findPendientesRevision(equipoId).stream()
                .map(mapper::toResumen).toList();
    }

    @Transactional(readOnly = true)
    public List<TransicionPermitidaResponse> obtenerTransicionesPermitidas(UUID tareaId, SmartGobUserDetails user) {
        Tarea tarea = findOrThrow(tareaId);
        String rolEnEquipo = resolverRolEnEquipo(user, tarea.getEquipo().getId());

        List<Object[]> transiciones = transicionRepo.findTransicionesDesde(tarea.getEstado());
        return transiciones.stream()
                .filter(t -> {
                    String roles = (String) t[2];
                    return roles.contains(rolEnEquipo) || roles.contains("SYSTEM") || user.isEsSuperUsuario();
                })
                .map(t -> TransicionPermitidaResponse.builder()
                        .estadoDestino((String) t[0])
                        .accion((String) t[1])
                        .rolesPermitidos(Arrays.asList(((String) t[2]).split(",")))
                        .descripcion((String) t[3])
                        .build())
                .toList();
    }

    // ── Crear ──────────────────────────────────────────────────

    @Transactional
    public TareaResponse crear(CrearTareaRequest request, SmartGobUserDetails user) {
        Contrato contrato = contratoRepo.findById(request.getContratoId())
                .orElseThrow(() -> new ResourceNotFoundException("Contrato", request.getContratoId().toString()));
        Equipo equipo = equipoRepo.findById(request.getEquipoId())
                .orElseThrow(() -> new ResourceNotFoundException("Equipo", request.getEquipoId().toString()));

        validarPermisoGestion(user, equipo.getId());

        String idTarea = generarIdTarea(contrato.getId());

        Tarea tarea = Tarea.builder()
                .idTarea(idTarea)
                .contrato(contrato)
                .equipo(equipo)
                .categoria(request.getCategoria())
                .titulo(request.getTitulo())
                .descripcion(request.getDescripcion())
                .prioridad(request.getPrioridad())
                .creadoPor(new Colaborador(user.getColaboradorId()))
                .fechaAsignacion(LocalDate.now())
                .estado("ASG")
                .fechaEstimadaFin(request.getFechaEstimadaFin())
                .porcentajeAvance(0)
                .observaciones(request.getObservaciones())
                .build();

        if (request.getAsignadoAId() != null) {
            tarea.setAsignadoA(colaboradorRepo.findById(request.getAsignadoAId())
                    .orElseThrow(() -> new ResourceNotFoundException("Colaborador", request.getAsignadoAId().toString())));
        }

        tarea = tareaRepo.save(tarea);

        registrarHistorico(tarea, null, "ASG", user.getColaboradorId(), "Tarea creada y asignada");

        log.info("Tarea creada: {} por {}", idTarea, user.getNombreCompleto());
        return obtenerPorId(tarea.getId());
    }

    // ── Actualizar datos ───────────────────────────────────────

    @Transactional
    public TareaResponse actualizar(UUID id, ActualizarTareaRequest request, SmartGobUserDetails user) {
        Tarea tarea = findOrThrow(id);
        validarPermisoGestion(user, tarea.getEquipo().getId());

        if (request.getTitulo() != null) tarea.setTitulo(request.getTitulo());
        if (request.getDescripcion() != null) tarea.setDescripcion(request.getDescripcion());
        if (request.getPrioridad() != null) tarea.setPrioridad(request.getPrioridad());
        if (request.getCategoria() != null) tarea.setCategoria(request.getCategoria());
        if (request.getFechaEstimadaFin() != null) tarea.setFechaEstimadaFin(request.getFechaEstimadaFin());
        if (request.getObservaciones() != null) tarea.setObservaciones(request.getObservaciones());
        if (request.getAsignadoAId() != null) {
            tarea.setAsignadoA(colaboradorRepo.findById(request.getAsignadoAId()).orElse(null));
        }

        return obtenerPorId(tareaRepo.save(tarea).getId());
    }

    // ── Cambio de estado ───────────────────────────────────────

    @Transactional
    public TareaResponse cambiarEstado(UUID id, CambiarEstadoRequest request, SmartGobUserDetails user) {
        Tarea tarea = findOrThrow(id);
        String estadoAnterior = tarea.getEstado();
        String estadoDestino = request.getEstadoDestino();

        if (!transicionRepo.existeTransicion(estadoAnterior, estadoDestino)) {
            throw new BusinessException(
                    String.format("Transición no permitida: %s → %s", estadoAnterior, estadoDestino));
        }

        String rolEnEquipo = resolverRolEnEquipo(user, tarea.getEquipo().getId());
        if (!user.isEsSuperUsuario() && !transicionRepo.puedeTransicionar(estadoAnterior, estadoDestino, rolEnEquipo)) {
            throw new UnauthorizedTransitionException(
                    String.format("Rol %s no puede realizar transición %s → %s", rolEnEquipo, estadoAnterior, estadoDestino));
        }

        // Lógica especial: TER/TERT → REV automático
        if ("TER".equals(estadoDestino) || "TERT".equals(estadoDestino)) {
            boolean fueraPlazo = !tarea.isDentroDePlazo();
            estadoDestino = fueraPlazo ? "TERT" : "TER";
        }

        tarea.setEstado(estadoDestino);

        // Si se finaliza, actualizar revisión
        if ("FIN".equals(estadoDestino)) {
            tarea.setRevisadoPor(new Colaborador(user.getColaboradorId()));
            tarea.setFechaRevision(OffsetDateTime.now());
            tarea.setPorcentajeAvance(100);
        }

        tarea = tareaRepo.save(tarea);
        registrarHistorico(tarea, estadoAnterior, estadoDestino, user.getColaboradorId(), request.getComentario());

        eventPublisher.publishEvent(new TareaEstadoCambiadoEvent(
                this, tarea.getId(), estadoAnterior, estadoDestino, user.getColaboradorId()));

        log.info("Tarea {} cambió {} → {} por {}", tarea.getIdTarea(), estadoAnterior, estadoDestino, user.getNombreCompleto());
        return obtenerPorId(tarea.getId());
    }

    // ── Actualizar avance ──────────────────────────────────────

    @Transactional
    public TareaResponse actualizarAvance(UUID id, ActualizarAvanceRequest request, SmartGobUserDetails user) {
        Tarea tarea = findOrThrow(id);

        boolean esAsignado = tarea.getAsignadoA() != null &&
                tarea.getAsignadoA().getId().equals(user.getColaboradorId());
        boolean esGestor = user.esGestorEnEquipo(tarea.getEquipo().getId());

        if (!esAsignado && !esGestor && !user.isEsSuperUsuario()) {
            throw new BusinessException("Solo el asignado o un gestor puede actualizar el avance");
        }

        tarea.setPorcentajeAvance(request.getPorcentajeAvance());
        if (request.getObservaciones() != null) {
            tarea.setObservaciones(request.getObservaciones());
        }

        return obtenerPorId(tareaRepo.save(tarea).getId());
    }

    // ── Soft delete ────────────────────────────────────────────

    @Transactional
    public void eliminar(UUID id, SmartGobUserDetails user) {
        Tarea tarea = findOrThrow(id);
        validarPermisoGestion(user, tarea.getEquipo().getId());
        tarea.setDeleted(true);
        tareaRepo.save(tarea);
    }

    // ── Helpers privados ───────────────────────────────────────

    private String generarIdTarea(UUID contratoId) {
        String prefijo = "T-";
        int siguiente = tareaRepo.findMaxSecuencial(contratoId, prefijo).orElse(0) + 1;
        return String.format("%s%03d", prefijo, siguiente);
    }

    private void registrarHistorico(Tarea tarea, String estadoAnterior, String estadoNuevo,
                                     UUID cambiadoPorId, String comentario) {
        HistoricoEstadoTarea hist = HistoricoEstadoTarea.builder()
                .tarea(tarea)
                .estadoAnterior(estadoAnterior)
                .estadoNuevo(estadoNuevo)
                .cambiadoPor(new Colaborador(cambiadoPorId))
                .comentario(comentario)
                .fecha(OffsetDateTime.now())
                .build();
        historicoRepo.save(hist);
    }

    private TareaResponse enrichResponse(TareaResponse resp, Tarea tarea) {
        resp.setTotalComentarios(comentarioRepo.countByTareaId(tarea.getId()));
        resp.setTotalAdjuntos(adjuntoRepo.countByTareaId(tarea.getId()));
        return resp;
    }

    private void validarPermisoGestion(SmartGobUserDetails user, UUID equipoId) {
        if (user.isEsSuperUsuario()) return;
        if (!user.esGestorEnEquipo(equipoId)) {
            throw new BusinessException("No tiene permisos de gestión sobre este equipo");
        }
    }

    private String resolverRolEnEquipo(SmartGobUserDetails user, UUID equipoId) {
        if (user.isEsSuperUsuario()) return "LDR";
        return user.getRolEnEquipo(equipoId).orElse("NONE");
    }

    public Tarea findOrThrow(UUID id) {
        return tareaRepo.findById(id)
                .filter(t -> !t.getDeleted())
                .orElseThrow(() -> new ResourceNotFoundException("Tarea", id.toString()));
    }
}
EOF

# =============================================================
# ComentarioTareaService
# =============================================================
echo "  💬 ComentarioTareaService..."

cat > $B/service/ComentarioTareaService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.ComentarioTarea;
import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.dto.mapper.ComentarioMapper;
import ec.smartgob.gproyectos.dto.request.CrearComentarioRequest;
import ec.smartgob.gproyectos.dto.response.ComentarioResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.repository.ComentarioTareaRepository;
import ec.smartgob.gproyectos.repository.TareaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ComentarioTareaService {

    private final ComentarioTareaRepository comentarioRepo;
    private final TareaRepository tareaRepo;
    private final ComentarioMapper mapper;

    @Transactional(readOnly = true)
    public List<ComentarioResponse> listarPorTarea(UUID tareaId) {
        return comentarioRepo.findByTareaIdOrdenado(tareaId).stream()
                .map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public PageResponse<ComentarioResponse> listarPorTareaPaginado(UUID tareaId, Pageable pageable) {
        return PageResponse.of(
                comentarioRepo.findByTareaIdPaginado(tareaId, pageable),
                mapper::toResponse);
    }

    @Transactional
    public ComentarioResponse crear(UUID tareaId, CrearComentarioRequest request, UUID autorId) {
        Tarea tarea = tareaRepo.findById(tareaId)
                .orElseThrow(() -> new ResourceNotFoundException("Tarea", tareaId.toString()));

        ComentarioTarea comentario = ComentarioTarea.builder()
                .tarea(tarea)
                .autor(new Colaborador(autorId))
                .contenido(request.getContenido())
                .tipo(request.getTipo() != null ? request.getTipo() : "COMENTARIO")
                .createdAt(OffsetDateTime.now())
                .build();

        comentario = comentarioRepo.save(comentario);
        return mapper.toResponse(comentarioRepo.findById(comentario.getId())
                .map(c -> { c.getAutor().getNombreCompleto(); return c; })
                .orElse(comentario));
    }

    @Transactional
    public void eliminar(UUID comentarioId) {
        if (!comentarioRepo.existsById(comentarioId)) {
            throw new ResourceNotFoundException("Comentario", comentarioId.toString());
        }
        comentarioRepo.deleteById(comentarioId);
    }
}
EOF

# =============================================================
# AdjuntoTareaService
# =============================================================
echo "  📎 AdjuntoTareaService..."

cat > $B/service/AdjuntoTareaService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.AdjuntoTarea;
import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.dto.mapper.AdjuntoMapper;
import ec.smartgob.gproyectos.dto.response.AdjuntoResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.repository.AdjuntoTareaRepository;
import ec.smartgob.gproyectos.repository.TareaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdjuntoTareaService {

    private final AdjuntoTareaRepository adjuntoRepo;
    private final TareaRepository tareaRepo;
    private final AdjuntoMapper mapper;

    @Value("${app.uploads.path:./uploads}")
    private String uploadsPath;

    @Value("${app.uploads.max-size-mb:10}")
    private int maxSizeMb;

    @Transactional(readOnly = true)
    public List<AdjuntoResponse> listarPorTarea(UUID tareaId) {
        return adjuntoRepo.findByTareaIdOrdenado(tareaId).stream()
                .map(mapper::toResponse).toList();
    }

    @Transactional
    public AdjuntoResponse subir(UUID tareaId, MultipartFile file, UUID subidoPorId) {
        Tarea tarea = tareaRepo.findById(tareaId)
                .orElseThrow(() -> new ResourceNotFoundException("Tarea", tareaId.toString()));

        if (file.getSize() > (long) maxSizeMb * 1024 * 1024) {
            throw new BusinessException("Archivo excede el tamaño máximo de " + maxSizeMb + " MB");
        }

        String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
        Path targetDir = Paths.get(uploadsPath, tarea.getContrato().getId().toString(), tareaId.toString());
        Path targetPath = targetDir.resolve(filename);

        try {
            Files.createDirectories(targetDir);
            file.transferTo(targetPath.toFile());
        } catch (IOException e) {
            log.error("Error guardando archivo: {}", e.getMessage());
            throw new BusinessException("Error al guardar el archivo");
        }

        AdjuntoTarea adjunto = AdjuntoTarea.builder()
                .tarea(tarea)
                .nombreArchivo(file.getOriginalFilename())
                .rutaArchivo(targetPath.toString())
                .tipoMime(file.getContentType())
                .tamanoBytes(file.getSize())
                .subidoPor(new Colaborador(subidoPorId))
                .createdAt(OffsetDateTime.now())
                .build();

        return mapper.toResponse(adjuntoRepo.save(adjunto));
    }

    @Transactional
    public void eliminar(UUID adjuntoId) {
        AdjuntoTarea adjunto = adjuntoRepo.findById(adjuntoId)
                .orElseThrow(() -> new ResourceNotFoundException("Adjunto", adjuntoId.toString()));
        try {
            Files.deleteIfExists(Paths.get(adjunto.getRutaArchivo()));
        } catch (IOException e) {
            log.warn("No se pudo eliminar archivo físico: {}", adjunto.getRutaArchivo());
        }
        adjuntoRepo.delete(adjunto);
    }
}
EOF

# =============================================================
# MensajeService
# =============================================================
echo "  ✉️  MensajeService..."

cat > $B/service/MensajeService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.Contrato;
import ec.smartgob.gproyectos.domain.model.Equipo;
import ec.smartgob.gproyectos.domain.model.Mensaje;
import ec.smartgob.gproyectos.dto.mapper.MensajeMapper;
import ec.smartgob.gproyectos.dto.request.EnviarMensajeRequest;
import ec.smartgob.gproyectos.dto.response.MensajeResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.repository.MensajeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MensajeService {

    private final MensajeRepository mensajeRepo;
    private final MensajeMapper mapper;

    @Transactional(readOnly = true)
    public PageResponse<MensajeResponse> bandejaEntrada(UUID destinatarioId, Pageable pageable) {
        return PageResponse.of(
                mensajeRepo.findBandejaEntrada(destinatarioId, pageable),
                mapper::toResponse);
    }

    @Transactional(readOnly = true)
    public PageResponse<MensajeResponse> mensajesEquipo(UUID equipoId, Pageable pageable) {
        return PageResponse.of(
                mensajeRepo.findByEquipoId(equipoId, pageable),
                mapper::toResponse);
    }

    @Transactional(readOnly = true)
    public PageResponse<MensajeResponse> mensajesContrato(UUID contratoId, Pageable pageable) {
        return PageResponse.of(
                mensajeRepo.findByContratoId(contratoId, pageable),
                mapper::toResponse);
    }

    @Transactional(readOnly = true)
    public List<MensajeResponse> conversacionDirecta(UUID usuarioA, UUID usuarioB) {
        return mensajeRepo.findConversacionDirecta(usuarioA, usuarioB).stream()
                .map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public long contarNoLeidos(UUID destinatarioId) {
        return mensajeRepo.countByDestinatarioIdAndLeidoFalse(destinatarioId);
    }

    @Transactional
    public MensajeResponse enviar(EnviarMensajeRequest request, UUID remitenteId) {
        if ("DIRECTO".equals(request.getTipo()) && request.getDestinatarioId() == null) {
            throw new BusinessException("Mensaje directo requiere destinatario");
        }
        if ("EQUIPO".equals(request.getTipo()) && request.getEquipoId() == null) {
            throw new BusinessException("Mensaje de equipo requiere equipo");
        }

        Mensaje mensaje = Mensaje.builder()
                .remitente(new Colaborador(remitenteId))
                .destinatario(request.getDestinatarioId() != null ? new Colaborador(request.getDestinatarioId()) : null)
                .equipo(request.getEquipoId() != null ? new Equipo(request.getEquipoId()) : null)
                .contrato(request.getContratoId() != null ? new Contrato(request.getContratoId()) : null)
                .asunto(request.getAsunto())
                .contenido(request.getContenido())
                .tipo(request.getTipo())
                .leido(false)
                .createdAt(OffsetDateTime.now())
                .build();

        return mapper.toResponse(mensajeRepo.save(mensaje));
    }

    @Transactional
    public void marcarLeido(UUID mensajeId, UUID destinatarioId) {
        mensajeRepo.marcarLeido(mensajeId, destinatarioId);
    }

    @Transactional
    public void marcarTodosLeidos(UUID destinatarioId) {
        mensajeRepo.marcarTodosLeidos(destinatarioId);
    }
}
EOF

# =============================================================
# NotificacionService
# =============================================================
echo "  🔔 NotificacionService..."

cat > $B/service/NotificacionService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.Notificacion;
import ec.smartgob.gproyectos.dto.mapper.NotificacionMapper;
import ec.smartgob.gproyectos.dto.response.NotificacionResponse;
import ec.smartgob.gproyectos.dto.response.PageResponse;
import ec.smartgob.gproyectos.repository.NotificacionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificacionService {

    private final NotificacionRepository notificacionRepo;
    private final NotificacionMapper mapper;

    @Transactional(readOnly = true)
    public PageResponse<NotificacionResponse> listar(UUID destinatarioId, Pageable pageable) {
        return PageResponse.of(
                notificacionRepo.findByDestinatarioId(destinatarioId, pageable),
                mapper::toResponse);
    }

    @Transactional(readOnly = true)
    public List<NotificacionResponse> noLeidas(UUID destinatarioId) {
        return notificacionRepo.findNoLeidasByDestinatarioId(destinatarioId).stream()
                .map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public long contarNoLeidas(UUID destinatarioId) {
        return notificacionRepo.countByDestinatarioIdAndLeidoFalse(destinatarioId);
    }

    @Transactional
    public void crearNotificacion(UUID destinatarioId, String tipo, String referenciaTipo,
                                   UUID referenciaId, String titulo, String mensaje, String urlAccion) {
        // Evitar duplicados
        if (notificacionRepo.existsByDestinatarioIdAndTipoAndReferenciaId(destinatarioId, tipo, referenciaId)) {
            return;
        }

        Notificacion notif = Notificacion.builder()
                .destinatario(new Colaborador(destinatarioId))
                .tipo(tipo)
                .referenciaTipo(referenciaTipo)
                .referenciaId(referenciaId)
                .titulo(titulo)
                .mensaje(mensaje)
                .leido(false)
                .urlAccion(urlAccion)
                .createdAt(OffsetDateTime.now())
                .build();

        notificacionRepo.save(notif);
        log.debug("Notificación creada: {} para colaborador {}", tipo, destinatarioId);
    }

    @Transactional
    public void marcarLeida(UUID id, UUID destinatarioId) {
        notificacionRepo.marcarLeida(id, destinatarioId);
    }

    @Transactional
    public void marcarTodasLeidas(UUID destinatarioId) {
        notificacionRepo.marcarTodasLeidas(destinatarioId);
    }

    @Transactional
    public int limpiarAntiguas(int diasRetener) {
        OffsetDateTime limite = OffsetDateTime.now().minusDays(diasRetener);
        return notificacionRepo.eliminarLeidasAntiguas(limite);
    }
}
EOF

# =============================================================
# DashboardService
# =============================================================
echo "  📊 DashboardService..."

cat > $B/service/DashboardService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.dto.mapper.DashboardMapper;
import ec.smartgob.gproyectos.dto.mapper.TareaMapper;
import ec.smartgob.gproyectos.dto.response.*;
import ec.smartgob.gproyectos.repository.TareaRepository;
import ec.smartgob.gproyectos.repository.projection.KanbanCountProjection;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final TareaRepository tareaRepo;
    private final DashboardMapper dashboardMapper;
    private final TareaMapper tareaMapper;

    @Transactional(readOnly = true)
    public List<DashboardSuperResponse> dashboardSuper() {
        return tareaRepo.findDashboardSuper().stream()
                .map(dashboardMapper::toSuperResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<DashboardEquipoResponse> dashboardEquipo(UUID contratoId) {
        return tareaRepo.findDashboardEquipo(contratoId).stream()
                .map(dashboardMapper::toEquipoResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<CargaColaboradorResponse> cargaColaborador(UUID equipoId) {
        return tareaRepo.findCargaColaborador(equipoId).stream()
                .map(dashboardMapper::toCargaResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<TareaAlertaResponse> tareasConAlerta(UUID contratoId, UUID equipoId, String alertaSla) {
        return tareaRepo.findTareasConAlertaSla(contratoId, equipoId, alertaSla).stream()
                .map(tareaMapper::toAlertaResponse).toList();
    }

    @Transactional(readOnly = true)
    public Map<String, Long> conteoKanban(UUID equipoId) {
        return tareaRepo.contarPorEstadoYEquipo(equipoId).stream()
                .collect(Collectors.toMap(KanbanCountProjection::getEstado, KanbanCountProjection::getTotal));
    }
}
EOF

# =============================================================
# HistoricoEstadoService
# =============================================================
echo "  📜 HistoricoEstadoService..."

cat > $B/service/HistoricoEstadoService.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.dto.mapper.HistoricoEstadoMapper;
import ec.smartgob.gproyectos.dto.response.HistoricoEstadoResponse;
import ec.smartgob.gproyectos.repository.HistoricoEstadoTareaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HistoricoEstadoService {

    private final HistoricoEstadoTareaRepository historicoRepo;
    private final HistoricoEstadoMapper mapper;

    @Transactional(readOnly = true)
    public List<HistoricoEstadoResponse> listarPorTarea(UUID tareaId) {
        return historicoRepo.findByTareaIdOrdenado(tareaId).stream()
                .map(mapper::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public long contarDevoluciones(UUID tareaId) {
        return historicoRepo.countDevoluciones(tareaId);
    }

    @Transactional(readOnly = true)
    public List<HistoricoEstadoResponse> actividadReciente(UUID colaboradorId, int diasAtras) {
        OffsetDateTime desde = OffsetDateTime.now().minusDays(diasAtras);
        return historicoRepo.findActividadReciente(colaboradorId, desde).stream()
                .map(mapper::toResponse).toList();
    }
}
EOF

# =============================================================
# TareaEstadoEventListener — listener de eventos Spring
# =============================================================
echo "  📡 TareaEstadoEventListener..."

cat > $B/service/TareaEstadoEventListener.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.event.TareaEstadoCambiadoEvent;
import ec.smartgob.gproyectos.domain.model.AsignacionEquipo;
import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.repository.AsignacionEquipoRepository;
import ec.smartgob.gproyectos.repository.TareaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Escucha cambios de estado de tarea y dispara notificaciones.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class TareaEstadoEventListener {

    private final TareaRepository tareaRepo;
    private final AsignacionEquipoRepository asignacionRepo;
    private final NotificacionService notificacionService;

    @Async
    @EventListener
    @Transactional
    public void onEstadoCambiado(TareaEstadoCambiadoEvent event) {
        Tarea tarea = tareaRepo.findByIdConRelaciones(event.getTareaId()).orElse(null);
        if (tarea == null) return;

        String idTarea = tarea.getIdTarea();
        String titulo = tarea.getTitulo();
        String url = "/tareas/" + tarea.getId();

        switch (event.getEstadoNuevo()) {
            case "EJE" -> {
                // Notificar al líder que una tarea inició ejecución
                notificarLideres(tarea, "TAREA_INICIADA",
                        "Tarea iniciada: " + idTarea,
                        String.format("La tarea '%s' fue iniciada", titulo), url);
            }
            case "TER", "TERT" -> {
                // Notificar a testers que hay tarea pendiente de revisión
                notificarTesters(tarea, "TAREA_PARA_REVISION",
                        "Tarea para revisión: " + idTarea,
                        String.format("La tarea '%s' está lista para revisión", titulo), url);
            }
            case "REV" -> {
                // Notificar al asignado que su tarea está en revisión
                if (tarea.getAsignadoA() != null) {
                    notificacionService.crearNotificacion(
                            tarea.getAsignadoA().getId(), "TAREA_EN_REVISION", "TAREA",
                            tarea.getId(), "Tarea en revisión: " + idTarea,
                            "Tu tarea '" + titulo + "' está siendo revisada", url);
                }
            }
            case "FIN" -> {
                // Notificar al asignado que su tarea fue aprobada
                if (tarea.getAsignadoA() != null) {
                    notificacionService.crearNotificacion(
                            tarea.getAsignadoA().getId(), "TAREA_FINALIZADA", "TAREA",
                            tarea.getId(), "Tarea aprobada: " + idTarea,
                            "Tu tarea '" + titulo + "' fue aprobada y finalizada", url);
                }
            }
            case "ASG" -> {
                // Si es devolución (viene de REV), notificar al asignado
                if ("REV".equals(event.getEstadoAnterior()) && tarea.getAsignadoA() != null) {
                    notificacionService.crearNotificacion(
                            tarea.getAsignadoA().getId(), "TAREA_DEVUELTA", "TAREA",
                            tarea.getId(), "Tarea devuelta: " + idTarea,
                            "La tarea '" + titulo + "' fue devuelta con observaciones", url);
                }
            }
            default -> log.debug("Sin notificación para transición a {}", event.getEstadoNuevo());
        }
    }

    private void notificarLideres(Tarea tarea, String tipo, String titulo, String mensaje, String url) {
        List<AsignacionEquipo> lideres = asignacionRepo
                .findByEquipoIdAndRol(tarea.getEquipo().getId(), "LDR");
        lideres.forEach(ae -> notificacionService.crearNotificacion(
                ae.getColaborador().getId(), tipo, "TAREA", tarea.getId(), titulo, mensaje, url));
    }

    private void notificarTesters(Tarea tarea, String tipo, String titulo, String mensaje, String url) {
        List<AsignacionEquipo> testers = asignacionRepo
                .findByEquipoIdAndRol(tarea.getEquipo().getId(), "TST");
        testers.forEach(ae -> notificacionService.crearNotificacion(
                ae.getColaborador().getId(), tipo, "TAREA", tarea.getId(), titulo, mensaje, url));
    }
}
EOF

# =============================================================
echo ""
echo "✅ Commit 4 completado."
echo ""
echo "Archivos creados:"
echo "  🔐 AuthService           — login, JWT, UserDetails"
echo "  🏢 EmpresaService        — CRUD empresas"
echo "  👤 ColaboradorService    — CRUD colaboradores"
echo "  📋 ContratoService       — CRUD contratos"
echo "  👥 EquipoService         — CRUD equipos + asignación miembros"
echo "  📝 TareaService          — CRUD, Kanban, transiciones, avance"
echo "  💬 ComentarioTareaService— comentarios por tarea"
echo "  📎 AdjuntoTareaService   — subir/descargar archivos"
echo "  ✉️  MensajeService        — mensajería directa, equipo, proyecto"
echo "  🔔 NotificacionService   — CRUD notificaciones, limpieza"
echo "  📊 DashboardService      — dashboards super/equipo/carga/alertas"
echo "  📜 HistoricoEstadoService— timeline, actividad, devoluciones"
echo "  📡 TareaEstadoEventListener — notificaciones automáticas"
echo ""
echo "  Total: 13 archivos en service/"
echo ""
echo "Siguiente paso:"
echo "  git add ."
echo "  git commit -m \"feat: services - lógica de negocio, auth, tareas, dashboard, SLA, notificaciones\""
echo "  git push"

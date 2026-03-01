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

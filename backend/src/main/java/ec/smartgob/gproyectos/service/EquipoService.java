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

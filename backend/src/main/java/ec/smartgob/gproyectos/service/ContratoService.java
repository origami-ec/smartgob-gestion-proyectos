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

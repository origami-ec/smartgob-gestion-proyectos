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

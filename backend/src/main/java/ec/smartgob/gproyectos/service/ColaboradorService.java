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

package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Empresa;
import ec.smartgob.gproyectos.dto.request.CrearEmpresaRequest;
import ec.smartgob.gproyectos.dto.response.EmpresaResponse;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

@Mapper(componentModel = "spring")
public interface EmpresaMapper {
    EmpresaResponse toResponse(Empresa entity);
    Empresa toEntity(CrearEmpresaRequest request);
    void updateEntity(CrearEmpresaRequest request, @MappingTarget Empresa entity);
}

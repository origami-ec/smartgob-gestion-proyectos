package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.dto.request.CrearColaboradorRequest;
import ec.smartgob.gproyectos.dto.response.ColaboradorResponse;
import ec.smartgob.gproyectos.dto.response.ColaboradorResumenResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

@Mapper(componentModel = "spring")
public interface ColaboradorMapper {

    @Mapping(source = "empresa.id", target = "empresaId")
    @Mapping(source = "empresa.razonSocial", target = "empresaNombre")
    ColaboradorResponse toResponse(Colaborador entity);

    ColaboradorResumenResponse toResumen(Colaborador entity);

    @Mapping(target = "empresa", ignore = true)
    @Mapping(target = "passwordHash", ignore = true)
    Colaborador toEntity(CrearColaboradorRequest request);

    @Mapping(target = "empresa", ignore = true)
    @Mapping(target = "passwordHash", ignore = true)
    @Mapping(target = "cedula", ignore = true)
    void updateEntity(CrearColaboradorRequest request, @MappingTarget Colaborador entity);
}

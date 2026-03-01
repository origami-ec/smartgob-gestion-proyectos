package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Equipo;
import ec.smartgob.gproyectos.dto.request.CrearEquipoRequest;
import ec.smartgob.gproyectos.dto.response.EquipoResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface EquipoMapper {

    @Mapping(source = "contrato.id", target = "contratoId")
    @Mapping(source = "contrato.nroContrato", target = "contratoNro")
    @Mapping(target = "totalMiembros", ignore = true)
    EquipoResponse toResponse(Equipo entity);

    @Mapping(target = "contrato", ignore = true)
    Equipo toEntity(CrearEquipoRequest request);
}

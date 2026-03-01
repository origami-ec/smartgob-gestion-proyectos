package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.AdjuntoTarea;
import ec.smartgob.gproyectos.dto.response.AdjuntoResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface AdjuntoMapper {
    @Mapping(source = "subidoPor.id", target = "subidoPorId")
    @Mapping(source = "subidoPor.nombreCompleto", target = "subidoPorNombre")
    AdjuntoResponse toResponse(AdjuntoTarea entity);
}

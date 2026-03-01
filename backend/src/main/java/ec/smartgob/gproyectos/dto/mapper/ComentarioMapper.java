package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.ComentarioTarea;
import ec.smartgob.gproyectos.dto.response.ComentarioResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface ComentarioMapper {
    @Mapping(source = "autor.id", target = "autorId")
    @Mapping(source = "autor.nombreCompleto", target = "autorNombre")
    ComentarioResponse toResponse(ComentarioTarea entity);
}

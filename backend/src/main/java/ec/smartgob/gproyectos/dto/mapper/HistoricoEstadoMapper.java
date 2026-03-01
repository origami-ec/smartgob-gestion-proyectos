package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.HistoricoEstadoTarea;
import ec.smartgob.gproyectos.dto.response.HistoricoEstadoResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface HistoricoEstadoMapper {
    @Mapping(source = "cambiadoPor.id", target = "cambiadoPorId")
    @Mapping(source = "cambiadoPor.nombreCompleto", target = "cambiadoPorNombre")
    HistoricoEstadoResponse toResponse(HistoricoEstadoTarea entity);
}

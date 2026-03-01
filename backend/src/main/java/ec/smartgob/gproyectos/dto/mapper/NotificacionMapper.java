package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Notificacion;
import ec.smartgob.gproyectos.dto.response.NotificacionResponse;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface NotificacionMapper {
    NotificacionResponse toResponse(Notificacion entity);
}

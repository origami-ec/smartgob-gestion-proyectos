package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Mensaje;
import ec.smartgob.gproyectos.dto.response.MensajeResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface MensajeMapper {
    @Mapping(source = "remitente.id", target = "remitenteId")
    @Mapping(source = "remitente.nombreCompleto", target = "remitenteNombre")
    @Mapping(source = "destinatario.id", target = "destinatarioId")
    @Mapping(source = "destinatario.nombreCompleto", target = "destinatarioNombre")
    @Mapping(source = "equipo.id", target = "equipoId")
    @Mapping(source = "contrato.id", target = "contratoId")
    MensajeResponse toResponse(Mensaje entity);
}

package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.enums.RolEquipo;
import ec.smartgob.gproyectos.domain.model.AsignacionEquipo;
import ec.smartgob.gproyectos.dto.response.AsignacionEquipoResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface AsignacionEquipoMapper {

    @Mapping(source = "equipo.id", target = "equipoId")
    @Mapping(source = "equipo.nombre", target = "equipoNombre")
    @Mapping(source = "colaborador.id", target = "colaboradorId")
    @Mapping(source = "colaborador.nombreCompleto", target = "colaboradorNombre")
    @Mapping(source = "colaborador.correo", target = "colaboradorCorreo")
    @Mapping(target = "rolNombre", expression = "java(resolverNombreRol(entity.getRolEquipo()))")
    AsignacionEquipoResponse toResponse(AsignacionEquipo entity);

    default String resolverNombreRol(String codigo) {
        try { return RolEquipo.valueOf(codigo).getNombre(); } catch (Exception e) { return codigo; }
    }
}

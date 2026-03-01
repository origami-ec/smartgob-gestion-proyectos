package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.enums.EstadoTarea;
import ec.smartgob.gproyectos.domain.enums.Prioridad;
import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.dto.response.TareaKanbanResponse;
import ec.smartgob.gproyectos.dto.response.TareaResponse;
import ec.smartgob.gproyectos.repository.projection.TareaAlertaSlaProjection;
import ec.smartgob.gproyectos.dto.response.TareaAlertaSlaResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface TareaMapper {

    @Mapping(source = "contrato.id", target = "contratoId")
    @Mapping(source = "contrato.nroContrato", target = "nroContrato")
    @Mapping(source = "contrato.cliente", target = "cliente")
    @Mapping(source = "equipo.id", target = "equipoId")
    @Mapping(source = "equipo.nombre", target = "equipoNombre")
    @Mapping(source = "asignadoA.id", target = "asignadoAId")
    @Mapping(source = "asignadoA.nombreCompleto", target = "asignadoANombre")
    @Mapping(source = "creadoPor.id", target = "creadoPorId")
    @Mapping(source = "creadoPor.nombreCompleto", target = "creadoPorNombre")
    @Mapping(target = "estadoNombre", expression = "java(resolverEstadoNombre(entity.getEstado()))")
    @Mapping(target = "estadoColor", expression = "java(resolverEstadoColor(entity.getEstado()))")
    @Mapping(target = "estadoBgColor", expression = "java(resolverEstadoBgColor(entity.getEstado()))")
    @Mapping(target = "prioridadNombre", expression = "java(resolverPrioridadNombre(entity.getPrioridad()))")
    @Mapping(target = "prioridadColor", expression = "java(resolverPrioridadColor(entity.getPrioridad()))")
    @Mapping(target = "diasRestantes", expression = "java(entity.getDiasRestantes())")
    @Mapping(target = "dentroDePlazo", expression = "java(entity.isDentroDePlazo())")
    TareaResponse toResponse(Tarea entity);

    @Mapping(source = "asignadoA.id", target = "asignadoAId")
    @Mapping(source = "asignadoA.nombreCompleto", target = "asignadoANombre")
    @Mapping(target = "prioridadColor", expression = "java(resolverPrioridadColor(entity.getPrioridad()))")
    @Mapping(target = "diasRestantes", expression = "java(entity.getDiasRestantes())")
    @Mapping(target = "dentroDePlazo", expression = "java(entity.isDentroDePlazo())")
    TareaKanbanResponse toKanban(Tarea entity);

    TareaAlertaSlaResponse toAlertaSlaResponse(TareaAlertaSlaProjection projection);

    default String resolverEstadoNombre(String c) { try { return EstadoTarea.valueOf(c).getNombre(); } catch (Exception e) { return c; } }
    default String resolverEstadoColor(String c) { try { return EstadoTarea.valueOf(c).getColorHex(); } catch (Exception e) { return "#6B7280"; } }
    default String resolverEstadoBgColor(String c) { try { return EstadoTarea.valueOf(c).getColorBgHex(); } catch (Exception e) { return "#F3F4F6"; } }
    default String resolverPrioridadNombre(String c) { try { return Prioridad.valueOf(c).getNombre(); } catch (Exception e) { return c; } }
    default String resolverPrioridadColor(String c) { try { return Prioridad.valueOf(c).getColorHex(); } catch (Exception e) { return "#6B7280"; } }
}

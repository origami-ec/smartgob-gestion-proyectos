package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Contrato;
import ec.smartgob.gproyectos.dto.request.CrearContratoRequest;
import ec.smartgob.gproyectos.dto.response.ContratoResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

@Mapper(componentModel = "spring", imports = {LocalDate.class, ChronoUnit.class})
public interface ContratoMapper {

    @Mapping(source = "administrador.id", target = "administradorId")
    @Mapping(source = "administrador.nombreCompleto", target = "administradorNombre")
    @Mapping(source = "empresaContratada.id", target = "empresaContratadaId")
    @Mapping(source = "empresaContratada.razonSocial", target = "empresaNombre")
    @Mapping(target = "diasRestantes", expression = "java((int) Math.max(0, ChronoUnit.DAYS.between(LocalDate.now(), entity.getFechaFin())))")
    ContratoResponse toResponse(Contrato entity);

    @Mapping(target = "administrador", ignore = true)
    @Mapping(target = "empresaContratada", ignore = true)
    @Mapping(target = "fechaFin", expression = "java(request.getFechaInicio().plusDays(request.getPlazoDias()))")
    Contrato toEntity(CrearContratoRequest request);

    @Mapping(target = "administrador", ignore = true)
    @Mapping(target = "empresaContratada", ignore = true)
    void updateEntity(CrearContratoRequest request, @MappingTarget Contrato entity);
}

package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.dto.response.CargaColaboradorResponse;
import ec.smartgob.gproyectos.dto.response.DashboardEquipoResponse;
import ec.smartgob.gproyectos.dto.response.DashboardSuperResponse;
import ec.smartgob.gproyectos.repository.projection.CargaColaboradorProjection;
import ec.smartgob.gproyectos.repository.projection.DashboardEquipoProjection;
import ec.smartgob.gproyectos.repository.projection.DashboardSuperProjection;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface DashboardMapper {
    DashboardSuperResponse toSuperResponse(DashboardSuperProjection projection);
    DashboardEquipoResponse toEquipoResponse(DashboardEquipoProjection projection);
    CargaColaboradorResponse toCargaResponse(CargaColaboradorProjection projection);
}

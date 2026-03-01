package ec.smartgob.gproyectos.repository.projection;

import java.math.BigDecimal;
import java.util.UUID;

public interface DashboardEquipoProjection {
    UUID getEquipoId();
    String getEquipoNombre();
    UUID getContratoId();
    String getNroContrato();
    String getCliente();
    Long getTotalTareas();
    Long getBacklog();
    Long getEjecutando();
    Long getEnRevision();
    Long getFinalizadas();
    Long getSuspendidas();
    Long getFueraPlazo();
    Long getCriticas();
    Long getVencidas();
    Long getTotalMiembros();
    BigDecimal getAvancePromedio();
}

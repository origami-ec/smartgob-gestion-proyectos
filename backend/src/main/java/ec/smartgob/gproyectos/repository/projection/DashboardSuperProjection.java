package ec.smartgob.gproyectos.repository.projection;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public interface DashboardSuperProjection {
    UUID getContratoId();
    String getNroContrato();
    String getCliente();
    String getTipoProyecto();
    LocalDate getFechaInicio();
    LocalDate getFechaFin();
    String getContratoEstado();
    Integer getDiasRestantesContrato();
    Long getTotalTareas();
    Long getTareasFinalizadas();
    Long getTareasFueraPlazo();
    Long getTareasActivas();
    Long getTareasSuspendidas();
    Long getTareasEnRevision();
    Long getTareasCriticas();
    Long getTareasVencidas();
    BigDecimal getPorcentajeAvanceGlobal();
}

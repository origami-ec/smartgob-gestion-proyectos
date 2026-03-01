package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class DashboardSuperResponse {
    private UUID contratoId;
    private String nroContrato;
    private String cliente;
    private String tipoProyecto;
    private LocalDate fechaInicio;
    private LocalDate fechaFin;
    private String contratoEstado;
    private Integer diasRestantesContrato;
    private Long totalTareas;
    private Long tareasFinalizadas;
    private Long tareasFueraPlazo;
    private Long tareasActivas;
    private Long tareasSuspendidas;
    private Long tareasEnRevision;
    private Long tareasCriticas;
    private Long tareasVencidas;
    private BigDecimal porcentajeAvanceGlobal;
}

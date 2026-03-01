package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.math.BigDecimal;
import java.util.UUID;

@Data
public class DashboardEquipoResponse {
    private UUID equipoId;
    private String equipoNombre;
    private UUID contratoId;
    private String nroContrato;
    private String cliente;
    private Long totalTareas;
    private Long backlog;
    private Long ejecutando;
    private Long enRevision;
    private Long finalizadas;
    private Long suspendidas;
    private Long fueraPlazo;
    private Long criticas;
    private Long vencidas;
    private Long totalMiembros;
    private BigDecimal avancePromedio;
}

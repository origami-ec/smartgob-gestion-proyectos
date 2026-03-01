package ec.smartgob.gproyectos.dto.request;

import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class ActualizarTareaRequest {
    private String titulo;
    private String descripcion;
    private String prioridad;
    private String categoria;
    private UUID asignadoAId;
    private LocalDate fechaEstimadaFin;
    private Integer porcentajeAvance;
    private String observaciones;
}

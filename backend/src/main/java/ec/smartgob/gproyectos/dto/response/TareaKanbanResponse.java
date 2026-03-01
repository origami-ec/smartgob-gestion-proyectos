package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class TareaKanbanResponse {
    private UUID id;
    private String idTarea;
    private String titulo;
    private String estado;
    private String prioridad;
    private String prioridadColor;
    private String categoria;
    private UUID asignadoAId;
    private String asignadoANombre;
    private LocalDate fechaEstimadaFin;
    private Integer porcentajeAvance;
    private Integer diasRestantes;
    private Boolean dentroDePlazo;
}

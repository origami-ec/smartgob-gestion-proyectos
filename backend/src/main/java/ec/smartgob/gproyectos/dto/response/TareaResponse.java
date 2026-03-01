package ec.smartgob.gproyectos.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data @JsonInclude(JsonInclude.Include.NON_NULL)
public class TareaResponse {
    private UUID id;
    private String idTarea;
    private UUID contratoId;
    private String nroContrato;
    private String cliente;
    private UUID equipoId;
    private String equipoNombre;
    private String categoria;
    private String titulo;
    private String descripcion;
    private String prioridad;
    private String prioridadNombre;
    private String prioridadColor;
    private UUID asignadoAId;
    private String asignadoANombre;
    private UUID creadoPorId;
    private String creadoPorNombre;
    private LocalDate fechaAsignacion;
    private String estado;
    private String estadoNombre;
    private String estadoColor;
    private String estadoBgColor;
    private LocalDate fechaEstimadaFin;
    private Integer porcentajeAvance;
    private String observaciones;
    private Integer diasRestantes;
    private Boolean dentroDePlazo;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
}

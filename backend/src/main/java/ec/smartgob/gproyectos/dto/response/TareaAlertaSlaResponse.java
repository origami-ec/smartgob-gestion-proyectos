package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class TareaAlertaSlaResponse {
    private UUID id;
    private String idTarea;
    private String titulo;
    private String estado;
    private String estadoNombre;
    private String estadoColor;
    private String estadoBg;
    private String prioridad;
    private String prioridadNombre;
    private String prioridadColor;
    private Integer prioridadPeso;
    private String categoria;
    private LocalDate fechaAsignacion;
    private LocalDate fechaEstimadaFin;
    private Integer porcentajeAvance;
    private UUID contratoId;
    private String nroContrato;
    private String cliente;
    private UUID equipoId;
    private String nombreEquipo;
    private UUID asignadoAId;
    private String asignadoANombre;
    private Integer diasRestantes;
    private String alertaSla;
    private Integer horasRestantesRevision;
}

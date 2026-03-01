package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class AsignacionEquipoResponse {
    private UUID id;
    private UUID equipoId;
    private String equipoNombre;
    private UUID colaboradorId;
    private String colaboradorNombre;
    private String colaboradorCorreo;
    private String rolEquipo;
    private String rolNombre;
    private LocalDate fechaAsignacion;
    private String estado;
}

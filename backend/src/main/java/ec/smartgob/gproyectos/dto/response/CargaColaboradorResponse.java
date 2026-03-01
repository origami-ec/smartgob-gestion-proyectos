package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.util.UUID;

@Data
public class CargaColaboradorResponse {
    private UUID colaboradorId;
    private String nombreCompleto;
    private String correo;
    private UUID equipoId;
    private String rolEquipo;
    private String equipoNombre;
    private Long tareasActivas;
    private Long enRevision;
    private Long vencidas;
    private Long totalAsignadas;
}

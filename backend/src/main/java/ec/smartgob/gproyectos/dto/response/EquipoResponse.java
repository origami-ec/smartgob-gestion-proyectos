package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.util.UUID;

@Data
public class EquipoResponse {
    private UUID id;
    private String nombre;
    private UUID contratoId;
    private String contratoNro;
    private String descripcion;
    private String estado;
    private Long totalMiembros;
}

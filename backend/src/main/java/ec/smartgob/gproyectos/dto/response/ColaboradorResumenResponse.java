package ec.smartgob.gproyectos.dto.response;

import lombok.*;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor
public class ColaboradorResumenResponse {
    private UUID id;
    private String cedula;
    private String nombreCompleto;
    private String correo;
}

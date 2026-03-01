package ec.smartgob.gproyectos.dto.response;

import lombok.*;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class AuthResponse {
    private String token;
    private String tipo = "Bearer";
    private UUID colaboradorId;
    private String nombreCompleto;
    private String correo;
    private Boolean esSuperUsuario;
}

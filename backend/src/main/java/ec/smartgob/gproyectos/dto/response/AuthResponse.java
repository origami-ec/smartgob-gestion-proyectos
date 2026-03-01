package ec.smartgob.gproyectos.dto.response;

import lombok.*;
import java.util.List;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class AuthResponse {
    private String token;
    @Builder.Default
    private String tipo = "Bearer";
    private UUID colaboradorId;
    private String nombreCompleto;
    private String correo;
    private Boolean esSuperUsuario;
    private List<RolEquipoInfo> roles;

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class RolEquipoInfo {
        private UUID equipoId;
        private String equipoNombre;
        private String rol;
    }
}

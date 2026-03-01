package ec.smartgob.gproyectos.dto.response;

import lombok.*;
import java.util.List;

@Data @NoArgsConstructor @AllArgsConstructor
public class TransicionResponse {
    private String estadoDestino;
    private String accion;
    private List<String> rolesPermitidos;
    private String descripcion;
}

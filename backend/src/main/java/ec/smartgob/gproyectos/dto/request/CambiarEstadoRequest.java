package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CambiarEstadoRequest {
    @NotBlank private String nuevoEstado;
    private String comentario;
    private Integer porcentajeAvance;
}

package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CrearComentarioRequest {
    @NotBlank private String contenido;
    private String tipo = "COMENTARIO";
}

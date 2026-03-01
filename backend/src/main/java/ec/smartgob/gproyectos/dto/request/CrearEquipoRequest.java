package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.UUID;

@Data
public class CrearEquipoRequest {
    @NotBlank @Size(max = 100) private String nombre;
    @NotNull private UUID contratoId;
    @Size(max = 300) private String descripcion;
}

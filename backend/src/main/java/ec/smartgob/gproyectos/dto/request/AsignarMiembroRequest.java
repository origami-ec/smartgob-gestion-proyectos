package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class AsignarMiembroRequest {
    @NotNull(message = "El colaborador es obligatorio")
    private UUID colaboradorId;

    @NotBlank(message = "El rol es obligatorio")
    private String rolEquipo;
}

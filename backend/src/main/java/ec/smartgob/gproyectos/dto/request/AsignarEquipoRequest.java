package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class AsignarEquipoRequest {
    @NotNull private UUID colaboradorId;
    @NotBlank private String rolEquipo;
}

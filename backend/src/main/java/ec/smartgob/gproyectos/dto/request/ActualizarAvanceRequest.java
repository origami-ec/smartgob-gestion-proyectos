package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ActualizarAvanceRequest {
    @NotNull(message = "El porcentaje de avance es obligatorio")
    @Min(value = 0, message = "Mínimo 0%")
    @Max(value = 100, message = "Máximo 100%")
    private Integer porcentajeAvance;

    private String observaciones;
}

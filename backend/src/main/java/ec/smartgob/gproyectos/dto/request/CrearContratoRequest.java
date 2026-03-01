package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;
import java.util.UUID;

@Data
public class CrearContratoRequest {
    @NotBlank @Size(max = 50) private String nroContrato;
    @NotBlank @Size(max = 200) private String cliente;
    @NotBlank @Size(max = 50) private String tipoProyecto;
    @NotNull private LocalDate fechaInicio;
    @NotNull @Positive private Integer plazoDias;
    private UUID administradorId;
    @Size(max = 150) private String correoAdmin;
    private UUID empresaContratadaId;
    private String objetoContrato;
}

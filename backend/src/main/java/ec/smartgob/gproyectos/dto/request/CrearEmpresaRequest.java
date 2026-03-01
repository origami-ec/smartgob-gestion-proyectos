package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CrearEmpresaRequest {
    @NotBlank @Size(min = 10, max = 20) private String ruc;
    @NotBlank @Size(max = 200) private String razonSocial;
    private String tipo = "PRIVADA";
}

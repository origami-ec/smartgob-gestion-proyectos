package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.util.UUID;

@Data
public class EmpresaResponse {
    private UUID id;
    private String ruc;
    private String razonSocial;
    private String tipo;
    private String estado;
}

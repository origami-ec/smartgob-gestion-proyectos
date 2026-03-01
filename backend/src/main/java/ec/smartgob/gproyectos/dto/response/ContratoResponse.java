package ec.smartgob.gproyectos.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data @JsonInclude(JsonInclude.Include.NON_NULL)
public class ContratoResponse {
    private UUID id;
    private String nroContrato;
    private String cliente;
    private String tipoProyecto;
    private LocalDate fechaInicio;
    private Integer plazoDias;
    private LocalDate fechaFin;
    private UUID administradorId;
    private String administradorNombre;
    private String correoAdmin;
    private UUID empresaContratadaId;
    private String empresaNombre;
    private String ultimaFase;
    private String estado;
    private String objetoContrato;
    private Integer diasRestantes;
}

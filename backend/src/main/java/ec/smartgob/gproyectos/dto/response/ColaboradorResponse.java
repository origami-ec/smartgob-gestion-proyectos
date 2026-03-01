package ec.smartgob.gproyectos.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data @JsonInclude(JsonInclude.Include.NON_NULL)
public class ColaboradorResponse {
    private UUID id;
    private String cedula;
    private String nombreCompleto;
    private String tipo;
    private String titulo;
    private String correo;
    private String telefono;
    private UUID empresaId;
    private String empresaNombre;
    private LocalDate fechaNacimiento;
    private String estado;
    private Boolean esSuperUsuario;
}

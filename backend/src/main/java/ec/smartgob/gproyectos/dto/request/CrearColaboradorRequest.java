package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;
import java.util.UUID;

@Data
public class CrearColaboradorRequest {
    @NotBlank @Size(min = 10, max = 20) private String cedula;
    @NotBlank @Size(max = 150) private String nombreCompleto;
    @NotBlank private String tipo;
    @Size(max = 100) private String titulo;
    @NotBlank @Email @Size(max = 150) private String correo;
    @Size(max = 20) private String telefono;
    private UUID empresaId;
    private LocalDate fechaNacimiento;
    private String password;
    private Boolean esSuperUsuario = false;
}

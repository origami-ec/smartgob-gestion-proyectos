package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.UUID;

@Data
public class EnviarMensajeRequest {
    private UUID destinatarioId;
    private UUID equipoId;
    private UUID contratoId;
    @Size(max = 200) private String asunto;
    @NotBlank private String contenido;
    @NotBlank private String tipo;
}

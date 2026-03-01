package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class ComentarioResponse {
    private UUID id;
    private UUID autorId;
    private String autorNombre;
    private String contenido;
    private String tipo;
    private OffsetDateTime createdAt;
}

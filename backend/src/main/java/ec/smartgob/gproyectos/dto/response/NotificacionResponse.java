package ec.smartgob.gproyectos.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data @JsonInclude(JsonInclude.Include.NON_NULL)
public class NotificacionResponse {
    private UUID id;
    private String tipo;
    private String referenciaTipo;
    private UUID referenciaId;
    private String titulo;
    private String mensaje;
    private Boolean leido;
    private String urlAccion;
    private OffsetDateTime createdAt;
}

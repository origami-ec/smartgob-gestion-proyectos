package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class MensajeResponse {
    private UUID id;
    private UUID remitenteId;
    private String remitenteNombre;
    private UUID destinatarioId;
    private String destinatarioNombre;
    private UUID equipoId;
    private UUID contratoId;
    private String asunto;
    private String contenido;
    private String tipo;
    private Boolean leido;
    private OffsetDateTime createdAt;
}

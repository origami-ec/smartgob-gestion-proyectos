package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class HistoricoEstadoResponse {
    private UUID id;
    private String estadoAnterior;
    private String estadoNuevo;
    private UUID cambiadoPorId;
    private String cambiadoPorNombre;
    private String comentario;
    private OffsetDateTime fecha;
}

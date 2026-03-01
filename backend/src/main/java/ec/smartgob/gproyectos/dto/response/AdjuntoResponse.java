package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class AdjuntoResponse {
    private UUID id;
    private String nombreArchivo;
    private String rutaArchivo;
    private String tipoMime;
    private Long tamanoBytes;
    private UUID subidoPorId;
    private String subidoPorNombre;
    private OffsetDateTime createdAt;
}

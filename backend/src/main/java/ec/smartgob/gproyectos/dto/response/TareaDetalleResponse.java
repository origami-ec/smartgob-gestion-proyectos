package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import lombok.EqualsAndHashCode;
import java.util.List;

@Data @EqualsAndHashCode(callSuper = true)
public class TareaDetalleResponse extends TareaResponse {
    private List<HistoricoEstadoResponse> historial;
    private List<ComentarioResponse> comentarios;
    private List<AdjuntoResponse> adjuntos;
    private List<TransicionResponse> transicionesDisponibles;
    private long totalDevoluciones;
}

package ec.smartgob.gproyectos.dto.response;

import lombok.*;
import java.util.List;
import java.util.Map;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class KanbanBoardResponse {
    private Map<String, List<TareaKanbanResponse>> columnas;
    private Map<String, Long> conteos;
}

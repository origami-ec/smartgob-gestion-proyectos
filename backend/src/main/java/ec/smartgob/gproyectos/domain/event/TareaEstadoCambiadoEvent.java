package ec.smartgob.gproyectos.domain.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;
import java.util.UUID;

@Getter
public class TareaEstadoCambiadoEvent extends ApplicationEvent {
    private final UUID tareaId;
    private final String estadoAnterior;
    private final String estadoNuevo;
    private final UUID cambiadoPorId;

    public TareaEstadoCambiadoEvent(Object source, UUID tareaId,
            String estadoAnterior, String estadoNuevo, UUID cambiadoPorId) {
        super(source);
        this.tareaId = tareaId;
        this.estadoAnterior = estadoAnterior;
        this.estadoNuevo = estadoNuevo;
        this.cambiadoPorId = cambiadoPorId;
    }
}

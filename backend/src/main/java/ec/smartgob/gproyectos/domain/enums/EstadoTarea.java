package ec.smartgob.gproyectos.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum EstadoTarea {
    ASG("Asignado", "#3B82F6", "#DBEAFE"),
    EJE("Ejecutando", "#F59E0B", "#FEF3C7"),
    SUS("Suspendido", "#6B7280", "#F3F4F6"),
    TER("Terminada", "#10B981", "#D1FAE5"),
    TERT("Terminada fuera plazo", "#EF4444", "#FEE2E2"),
    REV("En Revisión", "#8B5CF6", "#EDE9FE"),
    FIN("Finalizada", "#059669", "#ECFDF5");

    private final String nombre;
    private final String colorHex;
    private final String colorBgHex;
}

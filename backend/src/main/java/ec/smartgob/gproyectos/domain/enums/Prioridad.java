package ec.smartgob.gproyectos.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum Prioridad {
    CRITICA("Crítica", "#DC2626", 4), ALTA("Alta", "#F97316", 3),
    MEDIA("Media", "#EAB308", 2), BAJA("Baja", "#6B7280", 1);

    private final String nombre;
    private final String colorHex;
    private final int peso;
}

package ec.smartgob.gproyectos.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum RolEquipo {
    LDR("Líder"), ADM("Administrador"), DEV("Desarrollador"),
    TST("Tester"), DOC("Documentador");

    private final String nombre;

    public boolean esGestion() { return this == LDR || this == ADM; }
    public boolean esEjecucion() { return this == DEV || this == DOC; }
}

package ec.smartgob.gproyectos.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum CategoriaTarea {
    DESARROLLO("Desarrollo"), DISENO("Diseño"),
    DOCUMENTACION("Documentación"), PRUEBAS("Pruebas");

    private final String nombre;
}

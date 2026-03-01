package ec.smartgob.gproyectos.exception;

public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String resource, Object id) {
        super(String.format("%s no encontrado con id: %s", resource, id));
    }
}

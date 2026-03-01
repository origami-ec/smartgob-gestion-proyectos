package ec.smartgob.gproyectos.repository.projection;

import java.util.UUID;

public interface CargaColaboradorProjection {
    UUID getColaboradorId();
    String getNombreCompleto();
    String getCorreo();
    UUID getEquipoId();
    String getRolEquipo();
    String getEquipoNombre();
    Long getTareasActivas();
    Long getEnRevision();
    Long getVencidas();
    Long getTotalAsignadas();
}

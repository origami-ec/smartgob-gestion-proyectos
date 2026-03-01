package ec.smartgob.gproyectos.repository.projection;

import java.time.LocalDate;
import java.util.UUID;

public interface TareaAlertaSlaProjection {
    UUID getId();
    String getIdTarea();
    String getTitulo();
    String getEstado();
    String getPrioridad();
    String getCategoria();
    LocalDate getFechaAsignacion();
    LocalDate getFechaEstimadaFin();
    Integer getPorcentajeAvance();
    UUID getContratoId();
    UUID getEquipoId();
    UUID getAsignadoAId();
    String getNroContrato();
    String getCliente();
    String getNombreEquipo();
    String getAsignadoANombre();
    String getEstadoColor();
    String getEstadoBg();
    String getEstadoNombre();
    String getPrioridadColor();
    String getPrioridadNombre();
    Integer getPrioridadPeso();
    Integer getDiasRestantes();
    String getAlertaSla();
    Integer getHorasRestantesRevision();
}

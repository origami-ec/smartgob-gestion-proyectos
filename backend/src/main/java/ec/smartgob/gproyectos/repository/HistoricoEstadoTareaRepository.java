package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.HistoricoEstadoTarea;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface HistoricoEstadoTareaRepository extends JpaRepository<HistoricoEstadoTarea, UUID> {

    @Query("SELECT h FROM HistoricoEstadoTarea h JOIN FETCH h.cambiadoPor WHERE h.tarea.id = :tareaId ORDER BY h.fecha DESC")
    List<HistoricoEstadoTarea> findByTareaIdOrdenado(@Param("tareaId") UUID tareaId);

    @Query("SELECT h FROM HistoricoEstadoTarea h WHERE h.tarea.id = :tareaId ORDER BY h.fecha DESC LIMIT 1")
    Optional<HistoricoEstadoTarea> findUltimoByTareaId(@Param("tareaId") UUID tareaId);

    @Query("SELECT h FROM HistoricoEstadoTarea h WHERE h.tarea.id = :tareaId AND h.estadoNuevo = :estado ORDER BY h.fecha DESC LIMIT 1")
    Optional<HistoricoEstadoTarea> findUltimaTransicionAEstado(@Param("tareaId") UUID tareaId, @Param("estado") String estado);

    @Query("SELECT COUNT(h) FROM HistoricoEstadoTarea h WHERE h.tarea.id = :tareaId AND h.estadoNuevo = 'ASG' AND h.estadoAnterior = 'REV'")
    long countDevoluciones(@Param("tareaId") UUID tareaId);

    @Query("SELECT h FROM HistoricoEstadoTarea h JOIN FETCH h.tarea JOIN FETCH h.cambiadoPor WHERE h.cambiadoPor.id = :colaboradorId AND h.fecha >= :desde ORDER BY h.fecha DESC")
    List<HistoricoEstadoTarea> findActividadReciente(@Param("colaboradorId") UUID colaboradorId, @Param("desde") OffsetDateTime desde);
}

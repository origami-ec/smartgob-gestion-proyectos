package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.AdjuntoTarea;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AdjuntoTareaRepository extends JpaRepository<AdjuntoTarea, UUID> {

    @Query("SELECT a FROM AdjuntoTarea a JOIN FETCH a.subidoPor WHERE a.tarea.id = :tareaId ORDER BY a.createdAt DESC")
    List<AdjuntoTarea> findByTareaIdOrdenado(@Param("tareaId") UUID tareaId);

    long countByTareaId(UUID tareaId);

    @Query("SELECT COALESCE(SUM(a.tamanoBytes), 0) FROM AdjuntoTarea a WHERE a.tarea.id = :tareaId")
    long sumarTamanoByTareaId(@Param("tareaId") UUID tareaId);
}

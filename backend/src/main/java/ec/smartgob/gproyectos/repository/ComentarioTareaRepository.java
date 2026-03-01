package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.ComentarioTarea;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ComentarioTareaRepository extends JpaRepository<ComentarioTarea, UUID> {

    @Query("SELECT ct FROM ComentarioTarea ct JOIN FETCH ct.autor WHERE ct.tarea.id = :tareaId ORDER BY ct.createdAt DESC")
    List<ComentarioTarea> findByTareaIdOrdenado(@Param("tareaId") UUID tareaId);

    @Query("SELECT ct FROM ComentarioTarea ct JOIN FETCH ct.autor WHERE ct.tarea.id = :tareaId ORDER BY ct.createdAt DESC")
    Page<ComentarioTarea> findByTareaIdPaginado(@Param("tareaId") UUID tareaId, Pageable pageable);

    @Query("SELECT ct FROM ComentarioTarea ct JOIN FETCH ct.autor WHERE ct.tarea.id = :tareaId AND ct.tipo = :tipo ORDER BY ct.createdAt DESC")
    List<ComentarioTarea> findByTareaIdAndTipo(@Param("tareaId") UUID tareaId, @Param("tipo") String tipo);

    long countByTareaId(UUID tareaId);
}

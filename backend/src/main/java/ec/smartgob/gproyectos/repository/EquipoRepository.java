package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.Equipo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface EquipoRepository extends JpaRepository<Equipo, UUID> {

    @Query("SELECT e FROM Equipo e WHERE e.contrato.id = :contratoId AND e.deleted = false ORDER BY e.nombre")
    List<Equipo> findByContratoId(@Param("contratoId") UUID contratoId);

    @Query("SELECT e FROM Equipo e WHERE e.contrato.id = :contratoId AND LOWER(e.nombre) = LOWER(:nombre) AND e.deleted = false")
    Optional<Equipo> findByContratoIdAndNombre(@Param("contratoId") UUID contratoId, @Param("nombre") String nombre);

    boolean existsByContratoIdAndNombreAndDeletedFalse(UUID contratoId, String nombre);

    @Query("""
        SELECT DISTINCT e FROM Equipo e JOIN AsignacionEquipo ae ON ae.equipo.id = e.id
        WHERE ae.colaborador.id = :colaboradorId AND ae.deleted = false AND ae.estado = 'ACTIVO' AND e.deleted = false
        ORDER BY e.nombre
        """)
    List<Equipo> findByColaboradorId(@Param("colaboradorId") UUID colaboradorId);

    @Query("SELECT e FROM Equipo e WHERE e.deleted = false AND e.estado = 'ACTIVO' ORDER BY e.nombre")
    List<Equipo> findAllActivos();

    @Query("SELECT COUNT(ae) FROM AsignacionEquipo ae WHERE ae.equipo.id = :equipoId AND ae.deleted = false AND ae.estado = 'ACTIVO'")
    long countMiembrosActivos(@Param("equipoId") UUID equipoId);
}

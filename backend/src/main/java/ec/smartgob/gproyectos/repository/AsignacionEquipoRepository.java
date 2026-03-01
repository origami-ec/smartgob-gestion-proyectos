package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.AsignacionEquipo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AsignacionEquipoRepository extends JpaRepository<AsignacionEquipo, UUID> {

    @Query("""
        SELECT ae FROM AsignacionEquipo ae JOIN FETCH ae.colaborador
        WHERE ae.equipo.id = :equipoId AND ae.deleted = false AND ae.estado = 'ACTIVO'
        ORDER BY ae.rolEquipo, ae.colaborador.nombreCompleto
        """)
    List<AsignacionEquipo> findByEquipoIdConColaborador(@Param("equipoId") UUID equipoId);

    @Query("SELECT ae FROM AsignacionEquipo ae WHERE ae.equipo.id = :equipoId AND ae.colaborador.id = :colaboradorId AND ae.deleted = false")
    Optional<AsignacionEquipo> findByEquipoIdAndColaboradorId(@Param("equipoId") UUID equipoId, @Param("colaboradorId") UUID colaboradorId);

    boolean existsByEquipoIdAndColaboradorIdAndDeletedFalse(UUID equipoId, UUID colaboradorId);

    @Query("SELECT ae FROM AsignacionEquipo ae JOIN FETCH ae.equipo WHERE ae.colaborador.id = :colaboradorId AND ae.deleted = false AND ae.estado = 'ACTIVO' ORDER BY ae.equipo.nombre")
    List<AsignacionEquipo> findByColaboradorIdConEquipo(@Param("colaboradorId") UUID colaboradorId);

    @Query("SELECT ae.rolEquipo FROM AsignacionEquipo ae WHERE ae.equipo.id = :equipoId AND ae.colaborador.id = :colaboradorId AND ae.deleted = false AND ae.estado = 'ACTIVO'")
    Optional<String> findRolByEquipoAndColaborador(@Param("equipoId") UUID equipoId, @Param("colaboradorId") UUID colaboradorId);

    @Query("SELECT ae FROM AsignacionEquipo ae JOIN FETCH ae.colaborador WHERE ae.equipo.id = :equipoId AND ae.rolEquipo = :rol AND ae.deleted = false AND ae.estado = 'ACTIVO'")
    List<AsignacionEquipo> findByEquipoIdAndRol(@Param("equipoId") UUID equipoId, @Param("rol") String rol);

    @Query("""
        SELECT CASE WHEN COUNT(ae) > 0 THEN true ELSE false END FROM AsignacionEquipo ae
        WHERE ae.equipo.id = :equipoId AND ae.colaborador.id = :colaboradorId
          AND ae.rolEquipo IN :roles AND ae.deleted = false AND ae.estado = 'ACTIVO'
        """)
    boolean tieneRol(@Param("equipoId") UUID equipoId, @Param("colaboradorId") UUID colaboradorId, @Param("roles") List<String> roles);
}

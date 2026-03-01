package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ColaboradorRepository extends JpaRepository<Colaborador, UUID> {

    Optional<Colaborador> findByCedula(String cedula);
    Optional<Colaborador> findByCorreo(String correo);
    Optional<Colaborador> findByUsuarioSmartgobId(String usuarioSmartgobId);
    boolean existsByCedula(String cedula);
    boolean existsByCorreo(String correo);

    @Query("""
        SELECT c FROM Colaborador c
        WHERE c.deleted = false AND c.estado = 'ACTIVO'
          AND (:busqueda IS NULL
               OR LOWER(c.nombreCompleto) LIKE LOWER(CONCAT('%', :busqueda, '%'))
               OR c.cedula LIKE CONCAT('%', :busqueda, '%')
               OR LOWER(c.correo) LIKE LOWER(CONCAT('%', :busqueda, '%')))
          AND (:tipo IS NULL OR c.tipo = :tipo)
          AND (:empresaId IS NULL OR c.empresa.id = :empresaId)
        ORDER BY c.nombreCompleto
        """)
    Page<Colaborador> buscar(@Param("busqueda") String busqueda, @Param("tipo") String tipo, @Param("empresaId") UUID empresaId, Pageable pageable);

    @Query("SELECT c FROM Colaborador c WHERE c.deleted = false AND c.estado = 'ACTIVO' ORDER BY c.nombreCompleto")
    List<Colaborador> findAllActivos();

    @Query("""
        SELECT DISTINCT c FROM Colaborador c JOIN AsignacionEquipo ae ON ae.colaborador.id = c.id
        WHERE ae.equipo.id = :equipoId AND ae.deleted = false AND ae.estado = 'ACTIVO' AND c.deleted = false
        ORDER BY c.nombreCompleto
        """)
    List<Colaborador> findByEquipoId(@Param("equipoId") UUID equipoId);

    @Query("""
        SELECT DISTINCT c FROM Colaborador c
            JOIN AsignacionEquipo ae ON ae.colaborador.id = c.id
            JOIN Equipo eq ON ae.equipo.id = eq.id
        WHERE eq.contrato.id = :contratoId AND ae.deleted = false AND ae.estado = 'ACTIVO' AND c.deleted = false
        ORDER BY c.nombreCompleto
        """)
    List<Colaborador> findByContratoId(@Param("contratoId") UUID contratoId);

    @Query("""
        SELECT c FROM Colaborador c JOIN AsignacionEquipo ae ON ae.colaborador.id = c.id
        WHERE ae.equipo.id = :equipoId AND ae.rolEquipo = :rol
          AND ae.deleted = false AND ae.estado = 'ACTIVO' AND c.deleted = false
        """)
    List<Colaborador> findByEquipoIdAndRol(@Param("equipoId") UUID equipoId, @Param("rol") String rol);
}

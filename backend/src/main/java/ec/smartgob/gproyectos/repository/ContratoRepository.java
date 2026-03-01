package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.Contrato;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ContratoRepository extends JpaRepository<Contrato, UUID> {

    Optional<Contrato> findByNroContrato(String nroContrato);
    boolean existsByNroContrato(String nroContrato);

    @Query("""
        SELECT c FROM Contrato c WHERE c.deleted = false
          AND (:estado IS NULL OR c.estado = :estado)
          AND (:busqueda IS NULL
               OR LOWER(c.nroContrato) LIKE LOWER(CONCAT('%', :busqueda, '%'))
               OR LOWER(c.cliente) LIKE LOWER(CONCAT('%', :busqueda, '%')))
          AND (:empresaId IS NULL OR c.empresaContratada.id = :empresaId)
        ORDER BY c.createdAt DESC
        """)
    Page<Contrato> buscar(@Param("estado") String estado, @Param("busqueda") String busqueda, @Param("empresaId") UUID empresaId, Pageable pageable);

    @Query("SELECT c FROM Contrato c WHERE c.deleted = false AND c.estado = 'ACTIVO' ORDER BY c.nroContrato")
    List<Contrato> findAllActivos();

    @Query("SELECT c FROM Contrato c WHERE c.deleted = false AND c.estado = 'ACTIVO' AND c.administrador.id = :adminId ORDER BY c.fechaFin ASC")
    List<Contrato> findByAdministradorId(@Param("adminId") UUID adminId);

    @Query("SELECT c FROM Contrato c WHERE c.deleted = false AND c.estado = 'ACTIVO' AND c.fechaFin <= :fechaLimite AND c.fechaFin >= CURRENT_DATE ORDER BY c.fechaFin ASC")
    List<Contrato> findProximosAVencer(@Param("fechaLimite") LocalDate fechaLimite);

    @Query("SELECT c FROM Contrato c WHERE c.deleted = false AND c.estado = 'ACTIVO' AND c.fechaFin < CURRENT_DATE ORDER BY c.fechaFin ASC")
    List<Contrato> findVencidos();

    @Query("""
        SELECT DISTINCT c FROM Contrato c
            LEFT JOIN Equipo eq ON eq.contrato.id = c.id AND eq.deleted = false
            LEFT JOIN AsignacionEquipo ae ON ae.equipo.id = eq.id AND ae.deleted = false
        WHERE c.deleted = false AND c.estado = 'ACTIVO' AND ae.colaborador.id = :colaboradorId
        ORDER BY c.nroContrato
        """)
    List<Contrato> findByColaboradorId(@Param("colaboradorId") UUID colaboradorId);
}

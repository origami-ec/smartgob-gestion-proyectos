package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.Empresa;
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
public interface EmpresaRepository extends JpaRepository<Empresa, UUID> {

    Optional<Empresa> findByRuc(String ruc);
    boolean existsByRuc(String ruc);

    @Query("""
        SELECT e FROM Empresa e
        WHERE e.deleted = false AND e.estado = :estado
          AND (:busqueda IS NULL
               OR LOWER(e.razonSocial) LIKE LOWER(CONCAT('%', :busqueda, '%'))
               OR e.ruc LIKE CONCAT('%', :busqueda, '%'))
        ORDER BY e.razonSocial
        """)
    Page<Empresa> buscarActivas(@Param("estado") String estado, @Param("busqueda") String busqueda, Pageable pageable);

    @Query("SELECT e FROM Empresa e WHERE e.deleted = false AND e.estado = 'ACTIVO' ORDER BY e.razonSocial")
    List<Empresa> findAllActivas();
}

package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.Notificacion;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface NotificacionRepository extends JpaRepository<Notificacion, UUID> {

    @Query("SELECT n FROM Notificacion n WHERE n.destinatario.id = :destId ORDER BY n.createdAt DESC")
    Page<Notificacion> findByDestinatarioId(@Param("destId") UUID destinatarioId, Pageable pageable);

    @Query("SELECT n FROM Notificacion n WHERE n.destinatario.id = :destId AND n.leido = false ORDER BY n.createdAt DESC")
    List<Notificacion> findNoLeidasByDestinatarioId(@Param("destId") UUID destinatarioId);

    long countByDestinatarioIdAndLeidoFalse(UUID destinatarioId);

    @Query("SELECT n FROM Notificacion n WHERE n.destinatario.id = :destId AND n.tipo = :tipo ORDER BY n.createdAt DESC")
    Page<Notificacion> findByDestinatarioIdAndTipo(@Param("destId") UUID destinatarioId, @Param("tipo") String tipo, Pageable pageable);

    @Query("SELECT n FROM Notificacion n WHERE n.referenciaTipo = :refTipo AND n.referenciaId = :refId ORDER BY n.createdAt DESC")
    List<Notificacion> findByReferencia(@Param("refTipo") String referenciaTipo, @Param("refId") UUID referenciaId);

    boolean existsByDestinatarioIdAndTipoAndReferenciaId(UUID destinatarioId, String tipo, UUID referenciaId);

    @Modifying @Query("UPDATE Notificacion n SET n.leido = true WHERE n.id = :id AND n.destinatario.id = :destId")
    int marcarLeida(@Param("id") UUID id, @Param("destId") UUID destinatarioId);

    @Modifying @Query("UPDATE Notificacion n SET n.leido = true WHERE n.destinatario.id = :destId AND n.leido = false")
    int marcarTodasLeidas(@Param("destId") UUID destinatarioId);

    @Modifying @Query("DELETE FROM Notificacion n WHERE n.leido = true AND n.createdAt < :antes")
    int eliminarLeidasAntiguas(@Param("antes") OffsetDateTime antes);
}

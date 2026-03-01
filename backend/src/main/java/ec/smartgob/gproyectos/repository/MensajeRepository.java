package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.Mensaje;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MensajeRepository extends JpaRepository<Mensaje, UUID> {

    @Query("SELECT m FROM Mensaje m JOIN FETCH m.remitente WHERE m.destinatario.id = :destId ORDER BY m.createdAt DESC")
    Page<Mensaje> findBandejaEntrada(@Param("destId") UUID destinatarioId, Pageable pageable);

    @Query("SELECT m FROM Mensaje m JOIN FETCH m.remitente WHERE m.equipo.id = :equipoId AND m.tipo = 'EQUIPO' ORDER BY m.createdAt DESC")
    Page<Mensaje> findByEquipoId(@Param("equipoId") UUID equipoId, Pageable pageable);

    @Query("SELECT m FROM Mensaje m JOIN FETCH m.remitente WHERE m.contrato.id = :contratoId AND m.tipo = 'PROYECTO' ORDER BY m.createdAt DESC")
    Page<Mensaje> findByContratoId(@Param("contratoId") UUID contratoId, Pageable pageable);

    @Query("""
        SELECT m FROM Mensaje m JOIN FETCH m.remitente WHERE m.tipo = 'DIRECTO'
          AND ((m.remitente.id = :a AND m.destinatario.id = :b) OR (m.remitente.id = :b AND m.destinatario.id = :a))
        ORDER BY m.createdAt ASC
        """)
    List<Mensaje> findConversacionDirecta(@Param("a") UUID usuarioA, @Param("b") UUID usuarioB);

    long countByDestinatarioIdAndLeidoFalse(UUID destinatarioId);

    @Query("SELECT COUNT(m) FROM Mensaje m WHERE m.equipo.id = :equipoId AND m.tipo = 'EQUIPO' AND m.leido = false AND m.remitente.id != :colId")
    long countNoLeidosEquipo(@Param("equipoId") UUID equipoId, @Param("colId") UUID colaboradorId);

    @Modifying @Query("UPDATE Mensaje m SET m.leido = true WHERE m.destinatario.id = :destId AND m.leido = false")
    int marcarTodosLeidos(@Param("destId") UUID destinatarioId);

    @Modifying @Query("UPDATE Mensaje m SET m.leido = true WHERE m.id = :msgId AND m.destinatario.id = :destId")
    int marcarLeido(@Param("msgId") UUID mensajeId, @Param("destId") UUID destinatarioId);
}

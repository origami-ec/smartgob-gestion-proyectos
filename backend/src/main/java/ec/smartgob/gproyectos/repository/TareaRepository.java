package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.repository.projection.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TareaRepository extends JpaRepository<Tarea, UUID> {

    Optional<Tarea> findByIdTareaAndContratoId(String idTarea, UUID contratoId);

    @Query("""
        SELECT t FROM Tarea t JOIN FETCH t.contrato JOIN FETCH t.equipo
            LEFT JOIN FETCH t.asignadoA LEFT JOIN FETCH t.creadoPor
        WHERE t.id = :id AND t.deleted = false
        """)
    Optional<Tarea> findByIdConRelaciones(@Param("id") UUID id);

    @Query("""
        SELECT t FROM Tarea t JOIN t.contrato c JOIN t.equipo e LEFT JOIN t.asignadoA a
        WHERE t.deleted = false
          AND (:contratoId IS NULL OR c.id = :contratoId)
          AND (:equipoId IS NULL OR e.id = :equipoId)
          AND (:estado IS NULL OR t.estado = :estado)
          AND (:prioridad IS NULL OR t.prioridad = :prioridad)
          AND (:categoria IS NULL OR t.categoria = :categoria)
          AND (:asignadoAId IS NULL OR a.id = :asignadoAId)
          AND (:busqueda IS NULL
               OR LOWER(t.titulo) LIKE LOWER(CONCAT('%', :busqueda, '%'))
               OR LOWER(t.idTarea) LIKE LOWER(CONCAT('%', :busqueda, '%')))
        ORDER BY t.createdAt DESC
        """)
    Page<Tarea> buscarConFiltros(
            @Param("contratoId") UUID contratoId, @Param("equipoId") UUID equipoId,
            @Param("estado") String estado, @Param("prioridad") String prioridad,
            @Param("categoria") String categoria, @Param("asignadoAId") UUID asignadoAId,
            @Param("busqueda") String busqueda, Pageable pageable);

    @Query("""
        SELECT t FROM Tarea t LEFT JOIN FETCH t.asignadoA LEFT JOIN FETCH t.creadoPor
        WHERE t.equipo.id = :equipoId AND t.deleted = false
          AND (:contratoId IS NULL OR t.contrato.id = :contratoId)
        ORDER BY CASE t.prioridad WHEN 'CRITICA' THEN 1 WHEN 'ALTA' THEN 2 WHEN 'MEDIA' THEN 3 WHEN 'BAJA' THEN 4 END,
                 t.fechaEstimadaFin ASC
        """)
    List<Tarea> findParaKanban(@Param("equipoId") UUID equipoId, @Param("contratoId") UUID contratoId);

    @Query("SELECT t.estado AS estado, COUNT(t) AS total FROM Tarea t WHERE t.equipo.id = :equipoId AND t.deleted = false GROUP BY t.estado")
    List<KanbanCountProjection> contarPorEstadoYEquipo(@Param("equipoId") UUID equipoId);

    @Query("""
        SELECT t FROM Tarea t JOIN FETCH t.contrato JOIN FETCH t.equipo
        WHERE t.asignadoA.id = :colaboradorId AND t.deleted = false AND (:estado IS NULL OR t.estado = :estado)
        ORDER BY CASE t.prioridad WHEN 'CRITICA' THEN 1 WHEN 'ALTA' THEN 2 WHEN 'MEDIA' THEN 3 WHEN 'BAJA' THEN 4 END,
                 t.fechaEstimadaFin ASC
        """)
    List<Tarea> findMisTareas(@Param("colaboradorId") UUID colaboradorId, @Param("estado") String estado);

    @Query("""
        SELECT t FROM Tarea t JOIN FETCH t.contrato JOIN FETCH t.equipo LEFT JOIN FETCH t.asignadoA
        WHERE t.estado IN ('TER','TERT','REV') AND t.equipo.id = :equipoId AND t.deleted = false
        ORDER BY t.updatedAt ASC
        """)
    List<Tarea> findPendientesRevision(@Param("equipoId") UUID equipoId);

    @Query("""
        SELECT t FROM Tarea t JOIN FETCH t.contrato JOIN FETCH t.equipo LEFT JOIN FETCH t.asignadoA
        WHERE t.deleted = false AND t.estado NOT IN ('FIN','SUS') AND t.fechaEstimadaFin <= :fechaLimite
        ORDER BY t.fechaEstimadaFin ASC
        """)
    List<Tarea> findProximasAVencer(@Param("fechaLimite") LocalDate fechaLimite);

    @Query("""
        SELECT t FROM Tarea t JOIN FETCH t.contrato JOIN FETCH t.equipo LEFT JOIN FETCH t.asignadoA
        WHERE t.deleted = false AND t.estado NOT IN ('FIN','SUS','TER','TERT','REV') AND t.fechaEstimadaFin < CURRENT_DATE
        ORDER BY t.fechaEstimadaFin ASC
        """)
    List<Tarea> findVencidas();

    @Query("SELECT t FROM Tarea t WHERE t.deleted = false AND t.estado = 'REV' AND t.updatedAt < :limiteHoras ORDER BY t.updatedAt ASC")
    List<Tarea> findRevisionesVencidas(@Param("limiteHoras") OffsetDateTime limiteHoras);

    @Query(value = """
        SELECT id, id_tarea AS idTarea, titulo, estado, prioridad, categoria,
               fecha_asignacion AS fechaAsignacion, fecha_estimada_fin AS fechaEstimadaFin,
               porcentaje_avance AS porcentajeAvance, contrato_id AS contratoId,
               equipo_id AS equipoId, asignado_a_id AS asignadoAId,
               nro_contrato AS nroContrato, cliente, nombre_equipo AS nombreEquipo,
               asignado_a_nombre AS asignadoANombre, estado_color AS estadoColor,
               estado_bg AS estadoBg, estado_nombre AS estadoNombre,
               prioridad_color AS prioridadColor, prioridad_nombre AS prioridadNombre,
               prioridad_peso AS prioridadPeso, dias_restantes AS diasRestantes,
               alerta_sla AS alertaSla, horas_restantes_revision AS horasRestantesRevision
        FROM gestion_proyectos.v_tareas_alerta_sla
        WHERE (:contratoId IS NULL OR contrato_id = CAST(:contratoId AS UUID))
          AND (:equipoId IS NULL OR equipo_id = CAST(:equipoId AS UUID))
          AND (:alertaSla IS NULL OR alerta_sla = :alertaSla)
        ORDER BY prioridad_peso DESC, dias_restantes ASC
        """, nativeQuery = true)
    List<TareaAlertaSlaProjection> findTareasConAlertaSla(
            @Param("contratoId") UUID contratoId, @Param("equipoId") UUID equipoId, @Param("alertaSla") String alertaSla);

    @Query(value = """
        SELECT contrato_id AS contratoId, nro_contrato AS nroContrato, cliente,
               tipo_proyecto AS tipoProyecto, fecha_inicio AS fechaInicio, fecha_fin AS fechaFin,
               contrato_estado AS contratoEstado, dias_restantes_contrato AS diasRestantesContrato,
               total_tareas AS totalTareas, tareas_finalizadas AS tareasFinalizadas,
               tareas_fuera_plazo AS tareasFueraPlazo, tareas_activas AS tareasActivas,
               tareas_suspendidas AS tareasSuspendidas, tareas_en_revision AS tareasEnRevision,
               tareas_criticas AS tareasCriticas, tareas_vencidas AS tareasVencidas,
               porcentaje_avance_global AS porcentajeAvanceGlobal
        FROM gestion_proyectos.v_dashboard_super ORDER BY dias_restantes_contrato ASC
        """, nativeQuery = true)
    List<DashboardSuperProjection> findDashboardSuper();

    @Query(value = """
        SELECT equipo_id AS equipoId, equipo_nombre AS equipoNombre,
               contrato_id AS contratoId, nro_contrato AS nroContrato, cliente,
               total_tareas AS totalTareas, backlog, ejecutando,
               en_revision AS enRevision, finalizadas, suspendidas,
               fuera_plazo AS fueraPlazo, criticas, vencidas,
               total_miembros AS totalMiembros, avance_promedio AS avancePromedio
        FROM gestion_proyectos.v_dashboard_equipo
        WHERE (:contratoId IS NULL OR contrato_id = CAST(:contratoId AS UUID))
        ORDER BY equipo_nombre
        """, nativeQuery = true)
    List<DashboardEquipoProjection> findDashboardEquipo(@Param("contratoId") UUID contratoId);

    @Query(value = """
        SELECT colaborador_id AS colaboradorId, nombre_completo AS nombreCompleto,
               correo, equipo_id AS equipoId, rol_equipo AS rolEquipo,
               equipo_nombre AS equipoNombre, tareas_activas AS tareasActivas,
               en_revision AS enRevision, vencidas, total_asignadas AS totalAsignadas
        FROM gestion_proyectos.v_carga_colaborador
        WHERE (:equipoId IS NULL OR equipo_id = CAST(:equipoId AS UUID))
        ORDER BY tareas_activas DESC
        """, nativeQuery = true)
    List<CargaColaboradorProjection> findCargaColaborador(@Param("equipoId") UUID equipoId);

    long countByEquipoIdAndDeletedFalse(UUID equipoId);
    long countByContratoIdAndDeletedFalse(UUID contratoId);
    long countByAsignadoAIdAndEstadoInAndDeletedFalse(UUID asignadoAId, List<String> estados);

    @Query("SELECT MAX(CAST(SUBSTRING(t.idTarea, LENGTH(:prefijo) + 1) AS int)) FROM Tarea t WHERE t.contrato.id = :contratoId AND t.idTarea LIKE CONCAT(:prefijo, '%')")
    Optional<Integer> findMaxSecuencial(@Param("contratoId") UUID contratoId, @Param("prefijo") String prefijo);
}

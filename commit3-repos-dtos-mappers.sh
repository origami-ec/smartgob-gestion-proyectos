#!/bin/bash
# ============================================================
# COMMIT 3: Repositories + DTOs + Mappers (MapStruct)
# Ejecutar desde la raíz del proyecto: smartgob-gestion-proyectos/
#
# Después:
#   git add .
#   git commit -m "feat: repositories con queries custom, DTOs y MapStruct mappers"
#   git push
# ============================================================

set -e
B="backend/src/main/java/ec/smartgob/gproyectos"
echo "🚀 Commit 3: Repositories + DTOs + Mappers"

mkdir -p $B/repository/projection
mkdir -p $B/dto/{request,response,mapper}

# =============================================================
#  PARTE 1: PROYECCIONES
# =============================================================
echo "🔍 Creando proyecciones..."

cat > $B/repository/projection/TareaAlertaSlaProjection.java << 'EOF'
package ec.smartgob.gproyectos.repository.projection;

import java.time.LocalDate;
import java.util.UUID;

public interface TareaAlertaSlaProjection {
    UUID getId();
    String getIdTarea();
    String getTitulo();
    String getEstado();
    String getPrioridad();
    String getCategoria();
    LocalDate getFechaAsignacion();
    LocalDate getFechaEstimadaFin();
    Integer getPorcentajeAvance();
    UUID getContratoId();
    UUID getEquipoId();
    UUID getAsignadoAId();
    String getNroContrato();
    String getCliente();
    String getNombreEquipo();
    String getAsignadoANombre();
    String getEstadoColor();
    String getEstadoBg();
    String getEstadoNombre();
    String getPrioridadColor();
    String getPrioridadNombre();
    Integer getPrioridadPeso();
    Integer getDiasRestantes();
    String getAlertaSla();
    Integer getHorasRestantesRevision();
}
EOF

cat > $B/repository/projection/DashboardSuperProjection.java << 'EOF'
package ec.smartgob.gproyectos.repository.projection;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public interface DashboardSuperProjection {
    UUID getContratoId();
    String getNroContrato();
    String getCliente();
    String getTipoProyecto();
    LocalDate getFechaInicio();
    LocalDate getFechaFin();
    String getContratoEstado();
    Integer getDiasRestantesContrato();
    Long getTotalTareas();
    Long getTareasFinalizadas();
    Long getTareasFueraPlazo();
    Long getTareasActivas();
    Long getTareasSuspendidas();
    Long getTareasEnRevision();
    Long getTareasCriticas();
    Long getTareasVencidas();
    BigDecimal getPorcentajeAvanceGlobal();
}
EOF

cat > $B/repository/projection/DashboardEquipoProjection.java << 'EOF'
package ec.smartgob.gproyectos.repository.projection;

import java.math.BigDecimal;
import java.util.UUID;

public interface DashboardEquipoProjection {
    UUID getEquipoId();
    String getEquipoNombre();
    UUID getContratoId();
    String getNroContrato();
    String getCliente();
    Long getTotalTareas();
    Long getBacklog();
    Long getEjecutando();
    Long getEnRevision();
    Long getFinalizadas();
    Long getSuspendidas();
    Long getFueraPlazo();
    Long getCriticas();
    Long getVencidas();
    Long getTotalMiembros();
    BigDecimal getAvancePromedio();
}
EOF

cat > $B/repository/projection/CargaColaboradorProjection.java << 'EOF'
package ec.smartgob.gproyectos.repository.projection;

import java.util.UUID;

public interface CargaColaboradorProjection {
    UUID getColaboradorId();
    String getNombreCompleto();
    String getCorreo();
    UUID getEquipoId();
    String getRolEquipo();
    String getEquipoNombre();
    Long getTareasActivas();
    Long getEnRevision();
    Long getVencidas();
    Long getTotalAsignadas();
}
EOF

cat > $B/repository/projection/KanbanCountProjection.java << 'EOF'
package ec.smartgob.gproyectos.repository.projection;

public interface KanbanCountProjection {
    String getEstado();
    Long getTotal();
}
EOF

# =============================================================
#  PARTE 2: REPOSITORIES
# =============================================================
echo "🗄️  Creando repositories..."

cat > $B/repository/EmpresaRepository.java << 'EOF'
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
EOF

cat > $B/repository/ColaboradorRepository.java << 'EOF'
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
EOF

cat > $B/repository/ContratoRepository.java << 'EOF'
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
EOF

cat > $B/repository/EquipoRepository.java << 'EOF'
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
EOF

cat > $B/repository/AsignacionEquipoRepository.java << 'EOF'
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
EOF

cat > $B/repository/TareaRepository.java << 'EOF'
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
EOF

cat > $B/repository/HistoricoEstadoTareaRepository.java << 'EOF'
package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.domain.model.HistoricoEstadoTarea;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface HistoricoEstadoTareaRepository extends JpaRepository<HistoricoEstadoTarea, UUID> {

    @Query("SELECT h FROM HistoricoEstadoTarea h JOIN FETCH h.cambiadoPor WHERE h.tarea.id = :tareaId ORDER BY h.fecha DESC")
    List<HistoricoEstadoTarea> findByTareaIdOrdenado(@Param("tareaId") UUID tareaId);

    @Query("SELECT h FROM HistoricoEstadoTarea h WHERE h.tarea.id = :tareaId ORDER BY h.fecha DESC LIMIT 1")
    Optional<HistoricoEstadoTarea> findUltimoByTareaId(@Param("tareaId") UUID tareaId);

    @Query("SELECT h FROM HistoricoEstadoTarea h WHERE h.tarea.id = :tareaId AND h.estadoNuevo = :estado ORDER BY h.fecha DESC LIMIT 1")
    Optional<HistoricoEstadoTarea> findUltimaTransicionAEstado(@Param("tareaId") UUID tareaId, @Param("estado") String estado);

    @Query("SELECT COUNT(h) FROM HistoricoEstadoTarea h WHERE h.tarea.id = :tareaId AND h.estadoNuevo = 'ASG' AND h.estadoAnterior = 'REV'")
    long countDevoluciones(@Param("tareaId") UUID tareaId);

    @Query("SELECT h FROM HistoricoEstadoTarea h JOIN FETCH h.tarea JOIN FETCH h.cambiadoPor WHERE h.cambiadoPor.id = :colaboradorId AND h.fecha >= :desde ORDER BY h.fecha DESC")
    List<HistoricoEstadoTarea> findActividadReciente(@Param("colaboradorId") UUID colaboradorId, @Param("desde") OffsetDateTime desde);
}
EOF

cat > $B/repository/ComentarioTareaRepository.java << 'EOF'
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
EOF

cat > $B/repository/AdjuntoTareaRepository.java << 'EOF'
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
EOF

cat > $B/repository/MensajeRepository.java << 'EOF'
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
EOF

cat > $B/repository/NotificacionRepository.java << 'EOF'
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
EOF

cat > $B/repository/TransicionEstadoRepository.java << 'EOF'
package ec.smartgob.gproyectos.repository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

@Repository
public class TransicionEstadoRepository {

    @PersistenceContext
    private EntityManager em;

    public boolean existeTransicion(String estadoOrigen, String estadoDestino) {
        Long count = (Long) em.createNativeQuery(
                "SELECT COUNT(*) FROM gestion_proyectos.param_transicion_estado WHERE estado_origen = :o AND estado_destino = :d AND activo = TRUE")
                .setParameter("o", estadoOrigen).setParameter("d", estadoDestino).getSingleResult();
        return count > 0;
    }

    public Optional<List<String>> findRolesPermitidos(String estadoOrigen, String estadoDestino) {
        @SuppressWarnings("unchecked")
        List<String> results = em.createNativeQuery(
                "SELECT roles_permitidos FROM gestion_proyectos.param_transicion_estado WHERE estado_origen = :o AND estado_destino = :d AND activo = TRUE")
                .setParameter("o", estadoOrigen).setParameter("d", estadoDestino).getResultList();
        if (results.isEmpty()) return Optional.empty();
        return Optional.of(Arrays.asList(results.get(0).split(",")));
    }

    public boolean puedeTransicionar(String estadoOrigen, String estadoDestino, String rol) {
        return findRolesPermitidos(estadoOrigen, estadoDestino)
                .map(roles -> roles.contains(rol) || roles.contains("SYSTEM")).orElse(false);
    }

    @SuppressWarnings("unchecked")
    public List<Object[]> findTransicionesDesde(String estadoOrigen) {
        return em.createNativeQuery(
                "SELECT estado_destino, accion, roles_permitidos, descripcion FROM gestion_proyectos.param_transicion_estado WHERE estado_origen = :o AND activo = TRUE ORDER BY estado_destino")
                .setParameter("o", estadoOrigen).getResultList();
    }
}
EOF

echo "✅ Repositories completados (12 archivos + 5 proyecciones)"

# =============================================================
#  PARTE 3: DTOs REQUEST
# =============================================================
echo "📦 Creando DTOs request..."

cat > $B/dto/request/LoginRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {
    @NotBlank(message = "La cédula es obligatoria") private String cedula;
    @NotBlank(message = "La contraseña es obligatoria") private String password;
}
EOF

cat > $B/dto/request/CrearEmpresaRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CrearEmpresaRequest {
    @NotBlank @Size(min = 10, max = 20) private String ruc;
    @NotBlank @Size(max = 200) private String razonSocial;
    private String tipo = "PRIVADA";
}
EOF

cat > $B/dto/request/CrearColaboradorRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;
import java.util.UUID;

@Data
public class CrearColaboradorRequest {
    @NotBlank @Size(min = 10, max = 20) private String cedula;
    @NotBlank @Size(max = 150) private String nombreCompleto;
    @NotBlank private String tipo;
    @Size(max = 100) private String titulo;
    @NotBlank @Email @Size(max = 150) private String correo;
    @Size(max = 20) private String telefono;
    private UUID empresaId;
    private LocalDate fechaNacimiento;
    private String password;
    private Boolean esSuperUsuario = false;
}
EOF

cat > $B/dto/request/CrearContratoRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;
import java.util.UUID;

@Data
public class CrearContratoRequest {
    @NotBlank @Size(max = 50) private String nroContrato;
    @NotBlank @Size(max = 200) private String cliente;
    @NotBlank @Size(max = 50) private String tipoProyecto;
    @NotNull private LocalDate fechaInicio;
    @NotNull @Positive private Integer plazoDias;
    private UUID administradorId;
    @Size(max = 150) private String correoAdmin;
    private UUID empresaContratadaId;
    private String objetoContrato;
}
EOF

cat > $B/dto/request/CrearEquipoRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.UUID;

@Data
public class CrearEquipoRequest {
    @NotBlank @Size(max = 100) private String nombre;
    @NotNull private UUID contratoId;
    @Size(max = 300) private String descripcion;
}
EOF

cat > $B/dto/request/AsignarEquipoRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class AsignarEquipoRequest {
    @NotNull private UUID colaboradorId;
    @NotBlank private String rolEquipo;
}
EOF

cat > $B/dto/request/CrearTareaRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;
import java.util.UUID;

@Data
public class CrearTareaRequest {
    @NotNull private UUID contratoId;
    @NotNull private UUID equipoId;
    @NotBlank private String categoria;
    @NotBlank @Size(max = 200) private String titulo;
    private String descripcion;
    @NotBlank private String prioridad;
    private UUID asignadoAId;
    @NotNull private LocalDate fechaEstimadaFin;
    private String observaciones;
}
EOF

cat > $B/dto/request/CambiarEstadoRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CambiarEstadoRequest {
    @NotBlank private String nuevoEstado;
    private String comentario;
    private Integer porcentajeAvance;
}
EOF

cat > $B/dto/request/ActualizarTareaRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class ActualizarTareaRequest {
    private String titulo;
    private String descripcion;
    private String prioridad;
    private String categoria;
    private UUID asignadoAId;
    private LocalDate fechaEstimadaFin;
    private Integer porcentajeAvance;
    private String observaciones;
}
EOF

cat > $B/dto/request/CrearComentarioRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CrearComentarioRequest {
    @NotBlank private String contenido;
    private String tipo = "COMENTARIO";
}
EOF

cat > $B/dto/request/EnviarMensajeRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.UUID;

@Data
public class EnviarMensajeRequest {
    private UUID destinatarioId;
    private UUID equipoId;
    private UUID contratoId;
    @Size(max = 200) private String asunto;
    @NotBlank private String contenido;
    @NotBlank private String tipo;
}
EOF

echo "✅ DTOs request completados (11 archivos)"

# =============================================================
#  PARTE 4: DTOs RESPONSE
# =============================================================
echo "📦 Creando DTOs response..."

cat > $B/dto/response/ApiResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {
    private boolean success;
    private String message;
    private T data;
    private Object errors;

    public static <T> ApiResponse<T> ok(T data) { return ApiResponse.<T>builder().success(true).data(data).build(); }
    public static <T> ApiResponse<T> ok(T data, String msg) { return ApiResponse.<T>builder().success(true).data(data).message(msg).build(); }
    public static <T> ApiResponse<T> error(String msg) { return ApiResponse.<T>builder().success(false).message(msg).build(); }
    public static <T> ApiResponse<T> error(String msg, Object errors) { return ApiResponse.<T>builder().success(false).message(msg).errors(errors).build(); }
}
EOF

cat > $B/dto/response/PageResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.*;
import org.springframework.data.domain.Page;
import java.util.List;
import java.util.function.Function;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class PageResponse<T> {
    private List<T> content;
    private int page;
    private int size;
    private long totalElements;
    private int totalPages;
    private boolean first;
    private boolean last;

    public static <E, T> PageResponse<T> of(Page<E> page, Function<E, T> mapper) {
        return PageResponse.<T>builder()
                .content(page.getContent().stream().map(mapper).toList())
                .page(page.getNumber()).size(page.getSize())
                .totalElements(page.getTotalElements()).totalPages(page.getTotalPages())
                .first(page.isFirst()).last(page.isLast()).build();
    }
}
EOF

cat > $B/dto/response/AuthResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.*;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class AuthResponse {
    private String token;
    private String tipo = "Bearer";
    private UUID colaboradorId;
    private String nombreCompleto;
    private String correo;
    private Boolean esSuperUsuario;
}
EOF

cat > $B/dto/response/EmpresaResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.util.UUID;

@Data
public class EmpresaResponse {
    private UUID id;
    private String ruc;
    private String razonSocial;
    private String tipo;
    private String estado;
}
EOF

cat > $B/dto/response/ColaboradorResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data @JsonInclude(JsonInclude.Include.NON_NULL)
public class ColaboradorResponse {
    private UUID id;
    private String cedula;
    private String nombreCompleto;
    private String tipo;
    private String titulo;
    private String correo;
    private String telefono;
    private UUID empresaId;
    private String empresaNombre;
    private LocalDate fechaNacimiento;
    private String estado;
    private Boolean esSuperUsuario;
}
EOF

cat > $B/dto/response/ColaboradorResumenResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.*;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor
public class ColaboradorResumenResponse {
    private UUID id;
    private String cedula;
    private String nombreCompleto;
    private String correo;
}
EOF

cat > $B/dto/response/ContratoResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data @JsonInclude(JsonInclude.Include.NON_NULL)
public class ContratoResponse {
    private UUID id;
    private String nroContrato;
    private String cliente;
    private String tipoProyecto;
    private LocalDate fechaInicio;
    private Integer plazoDias;
    private LocalDate fechaFin;
    private UUID administradorId;
    private String administradorNombre;
    private String correoAdmin;
    private UUID empresaContratadaId;
    private String empresaNombre;
    private String ultimaFase;
    private String estado;
    private String objetoContrato;
    private Integer diasRestantes;
}
EOF

cat > $B/dto/response/EquipoResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.util.UUID;

@Data
public class EquipoResponse {
    private UUID id;
    private String nombre;
    private UUID contratoId;
    private String contratoNro;
    private String descripcion;
    private String estado;
    private Long totalMiembros;
}
EOF

cat > $B/dto/response/AsignacionEquipoResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class AsignacionEquipoResponse {
    private UUID id;
    private UUID equipoId;
    private String equipoNombre;
    private UUID colaboradorId;
    private String colaboradorNombre;
    private String colaboradorCorreo;
    private String rolEquipo;
    private String rolNombre;
    private LocalDate fechaAsignacion;
    private String estado;
}
EOF

cat > $B/dto/response/TareaResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data @JsonInclude(JsonInclude.Include.NON_NULL)
public class TareaResponse {
    private UUID id;
    private String idTarea;
    private UUID contratoId;
    private String nroContrato;
    private String cliente;
    private UUID equipoId;
    private String equipoNombre;
    private String categoria;
    private String titulo;
    private String descripcion;
    private String prioridad;
    private String prioridadNombre;
    private String prioridadColor;
    private UUID asignadoAId;
    private String asignadoANombre;
    private UUID creadoPorId;
    private String creadoPorNombre;
    private LocalDate fechaAsignacion;
    private String estado;
    private String estadoNombre;
    private String estadoColor;
    private String estadoBgColor;
    private LocalDate fechaEstimadaFin;
    private Integer porcentajeAvance;
    private String observaciones;
    private Integer diasRestantes;
    private Boolean dentroDePlazo;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
}
EOF

cat > $B/dto/response/TareaDetalleResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import lombok.EqualsAndHashCode;
import java.util.List;

@Data @EqualsAndHashCode(callSuper = true)
public class TareaDetalleResponse extends TareaResponse {
    private List<HistoricoEstadoResponse> historial;
    private List<ComentarioResponse> comentarios;
    private List<AdjuntoResponse> adjuntos;
    private List<TransicionResponse> transicionesDisponibles;
    private long totalDevoluciones;
}
EOF

cat > $B/dto/response/TareaKanbanResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class TareaKanbanResponse {
    private UUID id;
    private String idTarea;
    private String titulo;
    private String estado;
    private String prioridad;
    private String prioridadColor;
    private String categoria;
    private UUID asignadoAId;
    private String asignadoANombre;
    private LocalDate fechaEstimadaFin;
    private Integer porcentajeAvance;
    private Integer diasRestantes;
    private Boolean dentroDePlazo;
}
EOF

cat > $B/dto/response/HistoricoEstadoResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class HistoricoEstadoResponse {
    private UUID id;
    private String estadoAnterior;
    private String estadoNuevo;
    private UUID cambiadoPorId;
    private String cambiadoPorNombre;
    private String comentario;
    private OffsetDateTime fecha;
}
EOF

cat > $B/dto/response/ComentarioResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class ComentarioResponse {
    private UUID id;
    private UUID autorId;
    private String autorNombre;
    private String contenido;
    private String tipo;
    private OffsetDateTime createdAt;
}
EOF

cat > $B/dto/response/AdjuntoResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class AdjuntoResponse {
    private UUID id;
    private String nombreArchivo;
    private String rutaArchivo;
    private String tipoMime;
    private Long tamanoBytes;
    private UUID subidoPorId;
    private String subidoPorNombre;
    private OffsetDateTime createdAt;
}
EOF

cat > $B/dto/response/MensajeResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class MensajeResponse {
    private UUID id;
    private UUID remitenteId;
    private String remitenteNombre;
    private UUID destinatarioId;
    private String destinatarioNombre;
    private UUID equipoId;
    private UUID contratoId;
    private String asunto;
    private String contenido;
    private String tipo;
    private Boolean leido;
    private OffsetDateTime createdAt;
}
EOF

cat > $B/dto/response/NotificacionResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class NotificacionResponse {
    private UUID id;
    private String tipo;
    private String referenciaTipo;
    private UUID referenciaId;
    private String titulo;
    private String mensaje;
    private Boolean leido;
    private String urlAccion;
    private OffsetDateTime createdAt;
}
EOF

cat > $B/dto/response/TransicionResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.*;
import java.util.List;

@Data @NoArgsConstructor @AllArgsConstructor
public class TransicionResponse {
    private String estadoDestino;
    private String accion;
    private List<String> rolesPermitidos;
    private String descripcion;
}
EOF

cat > $B/dto/response/DashboardSuperResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class DashboardSuperResponse {
    private UUID contratoId;
    private String nroContrato;
    private String cliente;
    private String tipoProyecto;
    private LocalDate fechaInicio;
    private LocalDate fechaFin;
    private String contratoEstado;
    private Integer diasRestantesContrato;
    private Long totalTareas;
    private Long tareasFinalizadas;
    private Long tareasFueraPlazo;
    private Long tareasActivas;
    private Long tareasSuspendidas;
    private Long tareasEnRevision;
    private Long tareasCriticas;
    private Long tareasVencidas;
    private BigDecimal porcentajeAvanceGlobal;
}
EOF

cat > $B/dto/response/DashboardEquipoResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.math.BigDecimal;
import java.util.UUID;

@Data
public class DashboardEquipoResponse {
    private UUID equipoId;
    private String equipoNombre;
    private UUID contratoId;
    private String nroContrato;
    private String cliente;
    private Long totalTareas;
    private Long backlog;
    private Long ejecutando;
    private Long enRevision;
    private Long finalizadas;
    private Long suspendidas;
    private Long fueraPlazo;
    private Long criticas;
    private Long vencidas;
    private Long totalMiembros;
    private BigDecimal avancePromedio;
}
EOF

cat > $B/dto/response/CargaColaboradorResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.util.UUID;

@Data
public class CargaColaboradorResponse {
    private UUID colaboradorId;
    private String nombreCompleto;
    private String correo;
    private UUID equipoId;
    private String rolEquipo;
    private String equipoNombre;
    private Long tareasActivas;
    private Long enRevision;
    private Long vencidas;
    private Long totalAsignadas;
}
EOF

cat > $B/dto/response/TareaAlertaSlaResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.Data;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class TareaAlertaSlaResponse {
    private UUID id;
    private String idTarea;
    private String titulo;
    private String estado;
    private String estadoNombre;
    private String estadoColor;
    private String estadoBg;
    private String prioridad;
    private String prioridadNombre;
    private String prioridadColor;
    private Integer prioridadPeso;
    private String categoria;
    private LocalDate fechaAsignacion;
    private LocalDate fechaEstimadaFin;
    private Integer porcentajeAvance;
    private UUID contratoId;
    private String nroContrato;
    private String cliente;
    private UUID equipoId;
    private String nombreEquipo;
    private UUID asignadoAId;
    private String asignadoANombre;
    private Integer diasRestantes;
    private String alertaSla;
    private Integer horasRestantesRevision;
}
EOF

cat > $B/dto/response/KanbanBoardResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.*;
import java.util.List;
import java.util.Map;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class KanbanBoardResponse {
    private Map<String, List<TareaKanbanResponse>> columnas;
    private Map<String, Long> conteos;
}
EOF

echo "✅ DTOs response completados (22 archivos)"

# =============================================================
#  PARTE 5: MAPPERS (MapStruct)
# =============================================================
echo "🔄 Creando MapStruct mappers..."

cat > $B/dto/mapper/EmpresaMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Empresa;
import ec.smartgob.gproyectos.dto.request.CrearEmpresaRequest;
import ec.smartgob.gproyectos.dto.response.EmpresaResponse;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

@Mapper(componentModel = "spring")
public interface EmpresaMapper {
    EmpresaResponse toResponse(Empresa entity);
    Empresa toEntity(CrearEmpresaRequest request);
    void updateEntity(CrearEmpresaRequest request, @MappingTarget Empresa entity);
}
EOF

cat > $B/dto/mapper/ColaboradorMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.dto.request.CrearColaboradorRequest;
import ec.smartgob.gproyectos.dto.response.ColaboradorResponse;
import ec.smartgob.gproyectos.dto.response.ColaboradorResumenResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

@Mapper(componentModel = "spring")
public interface ColaboradorMapper {

    @Mapping(source = "empresa.id", target = "empresaId")
    @Mapping(source = "empresa.razonSocial", target = "empresaNombre")
    ColaboradorResponse toResponse(Colaborador entity);

    ColaboradorResumenResponse toResumen(Colaborador entity);

    @Mapping(target = "empresa", ignore = true)
    @Mapping(target = "passwordHash", ignore = true)
    Colaborador toEntity(CrearColaboradorRequest request);

    @Mapping(target = "empresa", ignore = true)
    @Mapping(target = "passwordHash", ignore = true)
    @Mapping(target = "cedula", ignore = true)
    void updateEntity(CrearColaboradorRequest request, @MappingTarget Colaborador entity);
}
EOF

cat > $B/dto/mapper/ContratoMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Contrato;
import ec.smartgob.gproyectos.dto.request.CrearContratoRequest;
import ec.smartgob.gproyectos.dto.response.ContratoResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

@Mapper(componentModel = "spring", imports = {LocalDate.class, ChronoUnit.class})
public interface ContratoMapper {

    @Mapping(source = "administrador.id", target = "administradorId")
    @Mapping(source = "administrador.nombreCompleto", target = "administradorNombre")
    @Mapping(source = "empresaContratada.id", target = "empresaContratadaId")
    @Mapping(source = "empresaContratada.razonSocial", target = "empresaNombre")
    @Mapping(target = "diasRestantes", expression = "java((int) Math.max(0, ChronoUnit.DAYS.between(LocalDate.now(), entity.getFechaFin())))")
    ContratoResponse toResponse(Contrato entity);

    @Mapping(target = "administrador", ignore = true)
    @Mapping(target = "empresaContratada", ignore = true)
    @Mapping(target = "fechaFin", expression = "java(request.getFechaInicio().plusDays(request.getPlazoDias()))")
    Contrato toEntity(CrearContratoRequest request);

    @Mapping(target = "administrador", ignore = true)
    @Mapping(target = "empresaContratada", ignore = true)
    void updateEntity(CrearContratoRequest request, @MappingTarget Contrato entity);
}
EOF

cat > $B/dto/mapper/EquipoMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Equipo;
import ec.smartgob.gproyectos.dto.request.CrearEquipoRequest;
import ec.smartgob.gproyectos.dto.response.EquipoResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface EquipoMapper {

    @Mapping(source = "contrato.id", target = "contratoId")
    @Mapping(source = "contrato.nroContrato", target = "contratoNro")
    @Mapping(target = "totalMiembros", ignore = true)
    EquipoResponse toResponse(Equipo entity);

    @Mapping(target = "contrato", ignore = true)
    Equipo toEntity(CrearEquipoRequest request);
}
EOF

cat > $B/dto/mapper/AsignacionEquipoMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.enums.RolEquipo;
import ec.smartgob.gproyectos.domain.model.AsignacionEquipo;
import ec.smartgob.gproyectos.dto.response.AsignacionEquipoResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface AsignacionEquipoMapper {

    @Mapping(source = "equipo.id", target = "equipoId")
    @Mapping(source = "equipo.nombre", target = "equipoNombre")
    @Mapping(source = "colaborador.id", target = "colaboradorId")
    @Mapping(source = "colaborador.nombreCompleto", target = "colaboradorNombre")
    @Mapping(source = "colaborador.correo", target = "colaboradorCorreo")
    @Mapping(target = "rolNombre", expression = "java(resolverNombreRol(entity.getRolEquipo()))")
    AsignacionEquipoResponse toResponse(AsignacionEquipo entity);

    default String resolverNombreRol(String codigo) {
        try { return RolEquipo.valueOf(codigo).getNombre(); } catch (Exception e) { return codigo; }
    }
}
EOF

cat > $B/dto/mapper/TareaMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.enums.EstadoTarea;
import ec.smartgob.gproyectos.domain.enums.Prioridad;
import ec.smartgob.gproyectos.domain.model.Tarea;
import ec.smartgob.gproyectos.dto.response.TareaKanbanResponse;
import ec.smartgob.gproyectos.dto.response.TareaResponse;
import ec.smartgob.gproyectos.repository.projection.TareaAlertaSlaProjection;
import ec.smartgob.gproyectos.dto.response.TareaAlertaSlaResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface TareaMapper {

    @Mapping(source = "contrato.id", target = "contratoId")
    @Mapping(source = "contrato.nroContrato", target = "nroContrato")
    @Mapping(source = "contrato.cliente", target = "cliente")
    @Mapping(source = "equipo.id", target = "equipoId")
    @Mapping(source = "equipo.nombre", target = "equipoNombre")
    @Mapping(source = "asignadoA.id", target = "asignadoAId")
    @Mapping(source = "asignadoA.nombreCompleto", target = "asignadoANombre")
    @Mapping(source = "creadoPor.id", target = "creadoPorId")
    @Mapping(source = "creadoPor.nombreCompleto", target = "creadoPorNombre")
    @Mapping(target = "estadoNombre", expression = "java(resolverEstadoNombre(entity.getEstado()))")
    @Mapping(target = "estadoColor", expression = "java(resolverEstadoColor(entity.getEstado()))")
    @Mapping(target = "estadoBgColor", expression = "java(resolverEstadoBgColor(entity.getEstado()))")
    @Mapping(target = "prioridadNombre", expression = "java(resolverPrioridadNombre(entity.getPrioridad()))")
    @Mapping(target = "prioridadColor", expression = "java(resolverPrioridadColor(entity.getPrioridad()))")
    @Mapping(target = "diasRestantes", expression = "java(entity.getDiasRestantes())")
    @Mapping(target = "dentroDePlazo", expression = "java(entity.isDentroDePlazo())")
    TareaResponse toResponse(Tarea entity);

    @Mapping(source = "asignadoA.id", target = "asignadoAId")
    @Mapping(source = "asignadoA.nombreCompleto", target = "asignadoANombre")
    @Mapping(target = "prioridadColor", expression = "java(resolverPrioridadColor(entity.getPrioridad()))")
    @Mapping(target = "diasRestantes", expression = "java(entity.getDiasRestantes())")
    @Mapping(target = "dentroDePlazo", expression = "java(entity.isDentroDePlazo())")
    TareaKanbanResponse toKanban(Tarea entity);

    TareaAlertaSlaResponse toAlertaSlaResponse(TareaAlertaSlaProjection projection);

    default String resolverEstadoNombre(String c) { try { return EstadoTarea.valueOf(c).getNombre(); } catch (Exception e) { return c; } }
    default String resolverEstadoColor(String c) { try { return EstadoTarea.valueOf(c).getColorHex(); } catch (Exception e) { return "#6B7280"; } }
    default String resolverEstadoBgColor(String c) { try { return EstadoTarea.valueOf(c).getColorBgHex(); } catch (Exception e) { return "#F3F4F6"; } }
    default String resolverPrioridadNombre(String c) { try { return Prioridad.valueOf(c).getNombre(); } catch (Exception e) { return c; } }
    default String resolverPrioridadColor(String c) { try { return Prioridad.valueOf(c).getColorHex(); } catch (Exception e) { return "#6B7280"; } }
}
EOF

cat > $B/dto/mapper/HistoricoEstadoMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.HistoricoEstadoTarea;
import ec.smartgob.gproyectos.dto.response.HistoricoEstadoResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface HistoricoEstadoMapper {
    @Mapping(source = "cambiadoPor.id", target = "cambiadoPorId")
    @Mapping(source = "cambiadoPor.nombreCompleto", target = "cambiadoPorNombre")
    HistoricoEstadoResponse toResponse(HistoricoEstadoTarea entity);
}
EOF

cat > $B/dto/mapper/ComentarioMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.ComentarioTarea;
import ec.smartgob.gproyectos.dto.response.ComentarioResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface ComentarioMapper {
    @Mapping(source = "autor.id", target = "autorId")
    @Mapping(source = "autor.nombreCompleto", target = "autorNombre")
    ComentarioResponse toResponse(ComentarioTarea entity);
}
EOF

cat > $B/dto/mapper/AdjuntoMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.AdjuntoTarea;
import ec.smartgob.gproyectos.dto.response.AdjuntoResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface AdjuntoMapper {
    @Mapping(source = "subidoPor.id", target = "subidoPorId")
    @Mapping(source = "subidoPor.nombreCompleto", target = "subidoPorNombre")
    AdjuntoResponse toResponse(AdjuntoTarea entity);
}
EOF

cat > $B/dto/mapper/MensajeMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Mensaje;
import ec.smartgob.gproyectos.dto.response.MensajeResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface MensajeMapper {
    @Mapping(source = "remitente.id", target = "remitenteId")
    @Mapping(source = "remitente.nombreCompleto", target = "remitenteNombre")
    @Mapping(source = "destinatario.id", target = "destinatarioId")
    @Mapping(source = "destinatario.nombreCompleto", target = "destinatarioNombre")
    @Mapping(source = "equipo.id", target = "equipoId")
    @Mapping(source = "contrato.id", target = "contratoId")
    MensajeResponse toResponse(Mensaje entity);
}
EOF

cat > $B/dto/mapper/NotificacionMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.domain.model.Notificacion;
import ec.smartgob.gproyectos.dto.response.NotificacionResponse;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface NotificacionMapper {
    NotificacionResponse toResponse(Notificacion entity);
}
EOF

cat > $B/dto/mapper/DashboardMapper.java << 'EOF'
package ec.smartgob.gproyectos.dto.mapper;

import ec.smartgob.gproyectos.dto.response.CargaColaboradorResponse;
import ec.smartgob.gproyectos.dto.response.DashboardEquipoResponse;
import ec.smartgob.gproyectos.dto.response.DashboardSuperResponse;
import ec.smartgob.gproyectos.repository.projection.CargaColaboradorProjection;
import ec.smartgob.gproyectos.repository.projection.DashboardEquipoProjection;
import ec.smartgob.gproyectos.repository.projection.DashboardSuperProjection;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface DashboardMapper {
    DashboardSuperResponse toSuperResponse(DashboardSuperProjection projection);
    DashboardEquipoResponse toEquipoResponse(DashboardEquipoProjection projection);
    CargaColaboradorResponse toCargaResponse(CargaColaboradorProjection projection);
}
EOF

echo "✅ MapStruct mappers completados (12 archivos)"

# =============================================================
echo ""
echo "=========================================="
echo "✅ COMMIT 3 COMPLETADO"
echo "=========================================="
echo "  📁 Repositories:  12 archivos"
echo "  🔍 Proyecciones:   5 archivos"
echo "  📦 DTOs Request:  11 archivos"
echo "  📦 DTOs Response: 22 archivos"
echo "  🔄 Mappers:       12 archivos"
echo "  ─────────────────────────────"
echo "  TOTAL:            62 archivos"
echo "=========================================="
echo ""
echo "Siguiente paso:"
echo "  git add ."
echo "  git commit -m \"feat: repositories con queries custom, DTOs y MapStruct mappers\""
echo "  git push"

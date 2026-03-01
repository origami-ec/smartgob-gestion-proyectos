package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;

@Entity @Table(name = "tarea", schema = "gestion_proyectos",
    uniqueConstraints = @UniqueConstraint(columnNames = {"id_tarea", "contrato_id"}))
@SQLRestriction("deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Tarea extends BaseEntity {
    @Column(name = "id_tarea", nullable = false, length = 20) private String idTarea;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "contrato_id", nullable = false) private Contrato contrato;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "equipo_id", nullable = false) private Equipo equipo;
    @Column(nullable = false, length = 20) private String categoria;
    @Column(nullable = false, length = 200) private String titulo;
    @Column(columnDefinition = "TEXT") private String descripcion;
    @Column(nullable = false, length = 10) private String prioridad;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "asignado_a_id") private Colaborador asignadoA;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "creado_por_id", nullable = false) private Colaborador creadoPor;
    @Column(name = "fecha_asignacion", nullable = false) private LocalDate fechaAsignacion = LocalDate.now();
    @Column(nullable = false, length = 5) private String estado = "ASG";
    @Column(name = "fecha_estimada_fin", nullable = false) private LocalDate fechaEstimadaFin;
    @Column(name = "porcentaje_avance", nullable = false) private Integer porcentajeAvance = 0;
    @Column(columnDefinition = "TEXT") private String observaciones;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "revisado_por_id") private Colaborador revisadoPor;
    @Column(name = "fecha_revision") private OffsetDateTime fechaRevision;
    @Column(name = "process_instance_id", length = 100) private String processInstanceId;

    public Tarea(java.util.UUID id) { this.setId(id); }
    public int getDiasRestantes() { return Math.max(0, (int) ChronoUnit.DAYS.between(LocalDate.now(), fechaEstimadaFin)); }
    public boolean isDentroDePlazo() { return !LocalDate.now().isAfter(fechaEstimadaFin); }
}

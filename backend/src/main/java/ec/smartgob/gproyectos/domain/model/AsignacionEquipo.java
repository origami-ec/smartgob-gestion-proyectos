package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import java.time.LocalDate;

@Entity @Table(name = "asignacion_equipo", schema = "gestion_proyectos",
    uniqueConstraints = @UniqueConstraint(columnNames = {"equipo_id", "colaborador_id"}))
@SQLRestriction("deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AsignacionEquipo extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "equipo_id", nullable = false) private Equipo equipo;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "colaborador_id", nullable = false) private Colaborador colaborador;
    @Column(name = "rol_equipo", nullable = false, length = 5) private String rolEquipo;
    @Column(name = "fecha_asignacion", nullable = false) private LocalDate fechaAsignacion = LocalDate.now();
    @Column(length = 10) private String estado = "ACTIVO";
}

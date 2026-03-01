package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;

@Entity @Table(name = "equipo", schema = "gestion_proyectos",
    uniqueConstraints = @UniqueConstraint(columnNames = {"nombre", "contrato_id"}))
@SQLRestriction("deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Equipo extends BaseEntity {
    @Column(nullable = false, length = 100) private String nombre;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "contrato_id", nullable = false) private Contrato contrato;
    @Column(length = 300) private String descripcion;
    @Column(length = 10) private String estado = "ACTIVO";

    public Equipo(java.util.UUID id) { this.setId(id); }
}

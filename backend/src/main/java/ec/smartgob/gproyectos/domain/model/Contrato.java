package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import java.time.LocalDate;

@Entity @Table(name = "contrato", schema = "gestion_proyectos")
@SQLRestriction("deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Contrato extends BaseEntity {
    @Column(name = "nro_contrato", unique = true, nullable = false, length = 50) private String nroContrato;
    @Column(nullable = false, length = 200) private String cliente;
    @Column(name = "tipo_proyecto", nullable = false, length = 50) private String tipoProyecto;
    @Column(name = "fecha_inicio", nullable = false) private LocalDate fechaInicio;
    @Column(name = "plazo_dias", nullable = false) private Integer plazoDias;
    @Column(name = "fecha_fin", nullable = false) private LocalDate fechaFin;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "administrador_id") private Colaborador administrador;
    @Column(name = "correo_admin", length = 150) private String correoAdmin;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "empresa_contratada_id") private Empresa empresaContratada;
    @Column(name = "ultima_fase", length = 100) private String ultimaFase;
    @Column(length = 20) private String estado = "ACTIVO";
    @Column(name = "objeto_contrato", columnDefinition = "TEXT") private String objetoContrato;

    public Contrato(java.util.UUID id) { this.setId(id); }
}

package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "notificacion", schema = "gestion_proyectos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Notificacion {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "destinatario_id", nullable = false) private Colaborador destinatario;
    @Column(nullable = false, length = 30) private String tipo;
    @Column(name = "referencia_tipo", length = 30) private String referenciaTipo;
    @Column(name = "referencia_id") private UUID referenciaId;
    @Column(nullable = false, length = 200) private String titulo;
    @Column(nullable = false, columnDefinition = "TEXT") private String mensaje;
    private Boolean leido = false;
    @Column(name = "url_accion", length = 500) private String urlAccion;
    @Column(name = "created_at", nullable = false) private OffsetDateTime createdAt = OffsetDateTime.now();
    public Notificacion(java.util.UUID id) { this.setId(id); }
}

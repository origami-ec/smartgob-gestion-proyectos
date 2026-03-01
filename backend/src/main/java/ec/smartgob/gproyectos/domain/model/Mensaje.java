package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "mensaje", schema = "gestion_proyectos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Mensaje {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "remitente_id", nullable = false) private Colaborador remitente;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "destinatario_id") private Colaborador destinatario;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "equipo_id") private Equipo equipo;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "contrato_id") private Contrato contrato;
    @Column(length = 200) private String asunto;
    @Column(nullable = false, columnDefinition = "TEXT") private String contenido;
    @Column(length = 20) private String tipo = "DIRECTO";
    private Boolean leido = false;
    @Column(name = "created_at", nullable = false) private OffsetDateTime createdAt = OffsetDateTime.now();
}

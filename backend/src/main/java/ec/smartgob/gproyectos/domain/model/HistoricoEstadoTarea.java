package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "historico_estado_tarea", schema = "gestion_proyectos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class HistoricoEstadoTarea {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "tarea_id", nullable = false) private Tarea tarea;
    @Column(name = "estado_anterior", length = 5) private String estadoAnterior;
    @Column(name = "estado_nuevo", nullable = false, length = 5) private String estadoNuevo;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "cambiado_por_id", nullable = false) private Colaborador cambiadoPor;
    @Column(columnDefinition = "TEXT") private String comentario;
    @Column(nullable = false) private OffsetDateTime fecha = OffsetDateTime.now();
}

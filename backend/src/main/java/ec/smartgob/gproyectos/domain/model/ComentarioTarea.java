package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "comentario_tarea", schema = "gestion_proyectos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ComentarioTarea {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "tarea_id", nullable = false) private Tarea tarea;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "autor_id", nullable = false) private Colaborador autor;
    @Column(nullable = false, columnDefinition = "TEXT") private String contenido;
    @Column(length = 20) private String tipo = "COMENTARIO";
    @Column(name = "created_at", nullable = false) private OffsetDateTime createdAt = OffsetDateTime.now();
}

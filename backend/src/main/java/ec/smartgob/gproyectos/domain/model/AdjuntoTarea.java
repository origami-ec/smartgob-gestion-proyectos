package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "adjunto_tarea", schema = "gestion_proyectos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AdjuntoTarea {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "tarea_id", nullable = false) private Tarea tarea;
    @Column(name = "nombre_archivo", nullable = false, length = 300) private String nombreArchivo;
    @Column(name = "ruta_archivo", nullable = false, length = 500) private String rutaArchivo;
    @Column(name = "tipo_mime", length = 100) private String tipoMime;
    @Column(name = "tamano_bytes") private Long tamanoBytes;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "subido_por_id", nullable = false) private Colaborador subidoPor;
    @Column(name = "created_at", nullable = false) private OffsetDateTime createdAt = OffsetDateTime.now();
}

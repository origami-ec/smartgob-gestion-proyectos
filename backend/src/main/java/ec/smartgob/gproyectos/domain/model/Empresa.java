package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;

@Entity @Table(name = "empresa", schema = "gestion_proyectos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Empresa extends BaseEntity {
    @Column(unique = true, nullable = false, length = 20) private String ruc;
    @Column(name = "razon_social", nullable = false, length = 200) private String razonSocial;
    @Column(length = 20) private String tipo = "PRIVADA";
    @Column(length = 10) private String estado = "ACTIVO";
    public Empresa(java.util.UUID id) { this.setId(id); }
}

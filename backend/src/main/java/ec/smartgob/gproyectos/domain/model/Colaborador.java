package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import java.time.LocalDate;

@Entity @Table(name = "colaborador", schema = "gestion_proyectos")
@SQLRestriction("deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Colaborador extends BaseEntity {
    @Column(unique = true, nullable = false, length = 20) private String cedula;
    @Column(name = "nombre_completo", nullable = false, length = 150) private String nombreCompleto;
    @Column(nullable = false, length = 10) private String tipo;
    @Column(length = 100) private String titulo;
    @Column(nullable = false, length = 150) private String correo;
    @Column(length = 20) private String telefono;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "empresa_id") private Empresa empresa;
    @Column(name = "firma_electronica", length = 300) private String firmaElectronica;
    @Column(name = "fecha_nacimiento") private LocalDate fechaNacimiento;
    @Column(length = 10) private String estado = "ACTIVO";
    @Column(name = "usuario_smartgob_id", length = 100) private String usuarioSmartgobId;
    @Column(name = "password_hash") private String passwordHash;
    @Column(name = "es_super_usuario") private Boolean esSuperUsuario = false;

    public Colaborador(java.util.UUID id) { this.setId(id); }
}

package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;
import java.util.UUID;

@Data
public class CrearTareaRequest {
    @NotNull private UUID contratoId;
    @NotNull private UUID equipoId;
    @NotBlank private String categoria;
    @NotBlank @Size(max = 200) private String titulo;
    private String descripcion;
    @NotBlank private String prioridad;
    private UUID asignadoAId;
    @NotNull private LocalDate fechaEstimadaFin;
    private String observaciones;
}

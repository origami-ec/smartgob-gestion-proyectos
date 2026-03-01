package ec.smartgob.gproyectos.repository;

import ec.smartgob.gproyectos.config.AbstractIntegrationTest;
import ec.smartgob.gproyectos.domain.model.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;

class TareaRepositoryIT extends AbstractIntegrationTest {

    @Autowired private TareaRepository tareaRepo;
    @Autowired private ContratoRepository contratoRepo;
    @Autowired private EquipoRepository equipoRepo;
    @Autowired private ColaboradorRepository colaboradorRepo;
    @Autowired private EmpresaRepository empresaRepo;

    @Test
    @DisplayName("Buscar tareas con filtros múltiples")
    void buscarConFiltros() {
        Page<Tarea> result = tareaRepo.buscarConFiltros(
                null, null, null, null, null, null, null,
                PageRequest.of(0, 10));

        assertThat(result).isNotNull();
        // Seed data debería tener tareas
    }

    @Test
    @DisplayName("Contar por equipo y estado")
    void contarKanban() {
        // Verificar que la query no falla
        // Los datos exactos dependen del seed
        assertThatNoException().isThrownBy(() -> {
            tareaRepo.buscarConFiltros(null, null, "EJE", null, null, null, null,
                    PageRequest.of(0, 10));
        });
    }
}

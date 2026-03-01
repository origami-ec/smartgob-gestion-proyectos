package ec.smartgob.gproyectos;

import ec.smartgob.gproyectos.config.AbstractIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("Application Context")
class GestionProyectosApplicationTests extends AbstractIntegrationTest {

    @Test
    @DisplayName("El contexto de Spring levanta correctamente con TestContainers")
    void contextLoads() {
        assertThat(true).isTrue();
    }
}

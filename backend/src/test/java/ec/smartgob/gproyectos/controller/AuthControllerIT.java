package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.config.AbstractIntegrationTest;
import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.repository.ColaboradorRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@AutoConfigureMockMvc
class AuthControllerIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ColaboradorRepository colaboradorRepo;
    @Autowired private PasswordEncoder passwordEncoder;

    @BeforeEach
    void setUp() {
        // Seed data ya incluye un super usuario, pero creamos uno extra para test
        if (colaboradorRepo.findByCedulaAndEstado("9999999999", "ACTIVO").isEmpty()) {
            Colaborador c = new Colaborador();
            c.setCedula("9999999999");
            c.setCorreo("test-it@smartgob.ec");
            c.setNombreCompleto("Test IT User");
            c.setPasswordHash(passwordEncoder.encode("test123"));
            c.setTipo("INTERNO");
            c.setEstado("ACTIVO");
            c.setEsSuperUsuario(true);
            colaboradorRepo.save(c);
        }
    }

    @Test
    @DisplayName("POST /api/auth/login — login exitoso")
    void loginExitoso() throws Exception {
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"usuario":"9999999999","password":"test123"}
                    """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.token").isNotEmpty())
                .andExpect(jsonPath("$.data.nombreCompleto").value("Test IT User"));
    }

    @Test
    @DisplayName("POST /api/auth/login — credenciales inválidas")
    void loginFallido() throws Exception {
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"usuario":"9999999999","password":"wrongpass"}
                    """))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /api/auth/login — usuario no existe")
    void loginUsuarioNoExiste() throws Exception {
        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"usuario":"0000000000","password":"test"}
                    """))
                .andExpect(status().isNotFound());
    }
}

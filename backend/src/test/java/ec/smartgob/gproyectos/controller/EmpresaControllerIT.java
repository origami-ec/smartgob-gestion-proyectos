package ec.smartgob.gproyectos.controller;

import ec.smartgob.gproyectos.config.AbstractIntegrationTest;
import ec.smartgob.gproyectos.config.TestSecurityConfig;
import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.repository.ColaboradorRepository;
import ec.smartgob.gproyectos.security.JwtTokenProvider;
import ec.smartgob.gproyectos.security.SmartGobUserDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.*;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@AutoConfigureMockMvc
class EmpresaControllerIT extends AbstractIntegrationTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private JwtTokenProvider jwtProvider;
    @Autowired private ColaboradorRepository colaboradorRepo;

    private String token;

    @BeforeEach
    void setUp() {
        Colaborador admin = colaboradorRepo.findByCedulaAndEstado("9999999999", "ACTIVO")
                .orElseGet(() -> {
                    Colaborador c = new Colaborador();
                    c.setCedula("9999999999");
                    c.setCorreo("test-it@smartgob.ec");
                    c.setNombreCompleto("Test IT");
                    c.setPasswordHash("$2a$10$dummy");
                    c.setTipo("INTERNO");
                    c.setEstado("ACTIVO");
                    c.setEsSuperUsuario(true);
                    return colaboradorRepo.save(c);
                });

        SmartGobUserDetails user = TestSecurityConfig.createTestUser(admin.getId(), true);
        token = jwtProvider.generarToken(user);
    }

    @Test
    @DisplayName("GET /empresas/activas — retorna lista")
    void listarActivas() throws Exception {
        mockMvc.perform(get("/api/v1/gestion-proyectos/empresas/activas")
                .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("POST /empresas — crear empresa")
    void crearEmpresa() throws Exception {
        String ruc = "099" + System.currentTimeMillis() % 10000000 + "001";
        mockMvc.perform(post("/api/v1/gestion-proyectos/empresas")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format("""
                    {"ruc":"%s","razonSocial":"Test SA","tipo":"CONTRATADA"}
                    """, ruc)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.ruc").value(ruc));
    }

    @Test
    @DisplayName("Requiere autenticación")
    void sinAuth_401() throws Exception {
        mockMvc.perform(get("/api/v1/gestion-proyectos/empresas/activas"))
                .andExpect(status().isUnauthorized());
    }
}

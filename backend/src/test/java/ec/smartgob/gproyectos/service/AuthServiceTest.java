package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.AsignacionEquipo;
import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.Equipo;
import ec.smartgob.gproyectos.dto.request.LoginRequest;
import ec.smartgob.gproyectos.dto.response.AuthResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.repository.AsignacionEquipoRepository;
import ec.smartgob.gproyectos.repository.ColaboradorRepository;
import ec.smartgob.gproyectos.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock private ColaboradorRepository colaboradorRepo;
    @Mock private AsignacionEquipoRepository asignacionRepo;
    @Mock private JwtTokenProvider jwtProvider;
    @Mock private PasswordEncoder passwordEncoder;

    @InjectMocks private AuthService authService;

    private Colaborador colaborador;
    private UUID colaboradorId;

    @BeforeEach
    void setUp() {
        colaboradorId = UUID.randomUUID();
        colaborador = new Colaborador();
        colaborador.setId(colaboradorId);
        colaborador.setCedula("0900000001");
        colaborador.setCorreo("admin@test.ec");
        colaborador.setNombreCompleto("Admin Test");
        colaborador.setPasswordHash("$2a$10$encoded");
        colaborador.setEsSuperUsuario(false);
        colaborador.setEstado("ACTIVO");
    }

    @Nested
    @DisplayName("Login")
    class LoginTests {

        @Test
        @DisplayName("Login exitoso con cédula")
        void loginConCedula_exito() {
            LoginRequest request = new LoginRequest();
            request.setUsuario("0900000001");
            request.setPassword("password123");

            when(colaboradorRepo.findByCedulaAndEstado("0900000001", "ACTIVO"))
                    .thenReturn(Optional.of(colaborador));
            when(passwordEncoder.matches("password123", "$2a$10$encoded")).thenReturn(true);
            when(asignacionRepo.findByColaboradorId(colaboradorId)).thenReturn(List.of());
            when(jwtProvider.generarToken(any())).thenReturn("jwt-token-test");

            AuthResponse response = authService.login(request);

            assertThat(response).isNotNull();
            assertThat(response.getToken()).isEqualTo("jwt-token-test");
            assertThat(response.getColaboradorId()).isEqualTo(colaboradorId.toString());
            assertThat(response.getNombreCompleto()).isEqualTo("Admin Test");
        }

        @Test
        @DisplayName("Login con correo electrónico")
        void loginConCorreo_exito() {
            LoginRequest request = new LoginRequest();
            request.setUsuario("admin@test.ec");
            request.setPassword("password123");

            when(colaboradorRepo.findByCedulaAndEstado("admin@test.ec", "ACTIVO"))
                    .thenReturn(Optional.empty());
            when(colaboradorRepo.findByCorreoAndEstado("admin@test.ec", "ACTIVO"))
                    .thenReturn(Optional.of(colaborador));
            when(passwordEncoder.matches("password123", "$2a$10$encoded")).thenReturn(true);
            when(asignacionRepo.findByColaboradorId(colaboradorId)).thenReturn(List.of());
            when(jwtProvider.generarToken(any())).thenReturn("jwt-token-test");

            AuthResponse response = authService.login(request);

            assertThat(response).isNotNull();
            assertThat(response.getToken()).isEqualTo("jwt-token-test");
        }

        @Test
        @DisplayName("Login falla — usuario no encontrado")
        void loginUsuarioNoExiste_error() {
            LoginRequest request = new LoginRequest();
            request.setUsuario("noexiste");
            request.setPassword("pass");

            when(colaboradorRepo.findByCedulaAndEstado("noexiste", "ACTIVO")).thenReturn(Optional.empty());
            when(colaboradorRepo.findByCorreoAndEstado("noexiste", "ACTIVO")).thenReturn(Optional.empty());

            assertThatThrownBy(() -> authService.login(request))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        @Test
        @DisplayName("Login falla — contraseña incorrecta")
        void loginPasswordIncorrecto_error() {
            LoginRequest request = new LoginRequest();
            request.setUsuario("0900000001");
            request.setPassword("wrongpass");

            when(colaboradorRepo.findByCedulaAndEstado("0900000001", "ACTIVO"))
                    .thenReturn(Optional.of(colaborador));
            when(passwordEncoder.matches("wrongpass", "$2a$10$encoded")).thenReturn(false);

            assertThatThrownBy(() -> authService.login(request))
                    .isInstanceOf(BusinessException.class);
        }

        @Test
        @DisplayName("Login con roles de equipo incluidos")
        void loginConRoles_incluyeRoles() {
            LoginRequest request = new LoginRequest();
            request.setUsuario("0900000001");
            request.setPassword("password123");

            UUID equipoId = UUID.randomUUID();
            Equipo equipo = new Equipo();
            equipo.setId(equipoId);
            equipo.setNombre("Equipo Dev");

            AsignacionEquipo asignacion = new AsignacionEquipo();
            asignacion.setColaborador(colaborador);
            asignacion.setEquipo(equipo);
            asignacion.setRol("DEV");

            when(colaboradorRepo.findByCedulaAndEstado("0900000001", "ACTIVO"))
                    .thenReturn(Optional.of(colaborador));
            when(passwordEncoder.matches("password123", "$2a$10$encoded")).thenReturn(true);
            when(asignacionRepo.findByColaboradorId(colaboradorId)).thenReturn(List.of(asignacion));
            when(jwtProvider.generarToken(any())).thenReturn("jwt-token");

            AuthResponse response = authService.login(request);

            assertThat(response.getRoles()).hasSize(1);
            assertThat(response.getRoles().get(0).getRol()).isEqualTo("DEV");
        }
    }
}

#!/bin/bash
# ============================================================
# COMMIT 9: Tests — Unit (Mockito) + Integration (TestContainers)
# Ejecutar desde raíz: smartgob-gestion-proyectos/
# ============================================================

set -e
B="backend/src/test/java/ec/smartgob/gproyectos"
R="backend/src/test/resources"
echo "📦 Commit 9: Tests (Unit + Integration + TestContainers)"

mkdir -p $B/{service,controller,repository,security,config}
mkdir -p $R

# =============================================================
# 1. POM: agregar dependencias de test
# =============================================================
echo "  📋 Actualizando pom.xml con TestContainers..."

# Patch pom.xml: insertar testcontainers BOM y deps antes de </dependencies>
POMFILE="backend/pom.xml"

# Add testcontainers version property if not exists
if ! grep -q "testcontainers.version" $POMFILE; then
  sed -i 's|</properties>|        <testcontainers.version>1.20.4</testcontainers.version>\n    </properties>|' $POMFILE
fi

# Add testcontainers dependencies before closing </dependencies>
if ! grep -q "testcontainers" $POMFILE; then
  sed -i 's|</dependencies>|        <dependency><groupId>org.testcontainers</groupId><artifactId>testcontainers</artifactId><version>${testcontainers.version}</version><scope>test</scope></dependency>\n        <dependency><groupId>org.testcontainers</groupId><artifactId>postgresql</artifactId><version>${testcontainers.version}</version><scope>test</scope></dependency>\n        <dependency><groupId>org.testcontainers</groupId><artifactId>junit-jupiter</artifactId><version>${testcontainers.version}</version><scope>test</scope></dependency>\n    </dependencies>|' $POMFILE
fi

# =============================================================
# 2. Test application.yml
# =============================================================
echo "  ⚙️  application-test.yml..."

cat > $R/application-test.yml << 'EOF'
spring:
  datasource:
    url: jdbc:tc:postgresql:16-alpine:///smartgob_gproyectos_test
    username: test
    password: test
    driver-class-name: org.testcontainers.jdbc.ContainerDatabaseDriver
  jpa:
    hibernate:
      ddl-auto: none
    properties:
      hibernate:
        default_schema: gestion_proyectos
    show-sql: false
  flyway:
    enabled: true
    locations: classpath:db/migration
    schemas: gestion_proyectos
    baseline-on-migrate: true

app:
  security:
    jwt:
      secret: testSecretKey256BitsLongForJwtTokenSigningInTests!!
      expiration-ms: 3600000
      refresh-expiration-ms: 86400000
    cors:
      allowed-origins: http://localhost:3000
  timezone: America/Guayaquil
  sla:
    check-interval-minutes: 30
    vencimiento-alerta-horas: 72
    revision-max-horas: 72

logging:
  level:
    root: WARN
    ec.smartgob: DEBUG
    org.testcontainers: INFO
EOF

# =============================================================
# 3. Test Config Base — PostgreSQL TestContainer
# =============================================================
echo "  🐘 AbstractIntegrationTest..."

cat > $B/config/AbstractIntegrationTest.java << 'EOF'
package ec.smartgob.gproyectos.config;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Clase base para tests de integración con PostgreSQL TestContainer.
 * Levanta un PostgreSQL 16 real, ejecuta Flyway y permite tests completos.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
public abstract class AbstractIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("smartgob_gproyectos_test")
            .withUsername("test")
            .withPassword("test")
            .withReuse(true);

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
}
EOF

cat > $B/config/TestSecurityConfig.java << 'EOF'
package ec.smartgob.gproyectos.config;

import ec.smartgob.gproyectos.security.SmartGobUserDetails;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.*;

/**
 * Helpers para simular autenticación en tests.
 */
@TestConfiguration
public class TestSecurityConfig {

    public static SmartGobUserDetails createTestUser(UUID colaboradorId, boolean superUsuario) {
        Map<UUID, String> rolesPorEquipo = new HashMap<>();
        Set<UUID> contratosAccesibles = new HashSet<>();

        return new SmartGobUserDetails(
                colaboradorId,
                "test@smartgob.ec",
                "Test User",
                "$2a$10$test",
                superUsuario,
                rolesPorEquipo,
                contratosAccesibles,
                List.of(new SimpleGrantedAuthority("ROLE_USER"))
        );
    }

    public static SmartGobUserDetails createTestUserWithRole(UUID colaboradorId, UUID equipoId, String rol) {
        Map<UUID, String> rolesPorEquipo = Map.of(equipoId, rol);
        Set<UUID> contratosAccesibles = new HashSet<>();

        return new SmartGobUserDetails(
                colaboradorId,
                "test@smartgob.ec",
                "Test User",
                "$2a$10$test",
                false,
                rolesPorEquipo,
                contratosAccesibles,
                List.of(new SimpleGrantedAuthority("ROLE_USER"))
        );
    }

    public static void authenticateAs(SmartGobUserDetails userDetails) {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        SecurityContext ctx = SecurityContextHolder.createEmptyContext();
        ctx.setAuthentication(auth);
        SecurityContextHolder.setContext(ctx);
    }

    public static void clearAuth() {
        SecurityContextHolder.clearContext();
    }
}
EOF

# =============================================================
# 4. UNIT TESTS — Services (Mockito)
# =============================================================
echo "  🧪 Unit Tests: Services..."

cat > $B/service/AuthServiceTest.java << 'EOF'
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
EOF

cat > $B/service/TareaServiceTest.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.*;
import ec.smartgob.gproyectos.dto.mapper.TareaMapper;
import ec.smartgob.gproyectos.dto.request.CambiarEstadoRequest;
import ec.smartgob.gproyectos.dto.request.CrearTareaRequest;
import ec.smartgob.gproyectos.dto.response.TareaResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.exception.ResourceNotFoundException;
import ec.smartgob.gproyectos.exception.UnauthorizedTransitionException;
import ec.smartgob.gproyectos.repository.*;
import ec.smartgob.gproyectos.security.SmartGobUserDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.time.LocalDate;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TareaServiceTest {

    @Mock private TareaRepository tareaRepo;
    @Mock private ContratoRepository contratoRepo;
    @Mock private EquipoRepository equipoRepo;
    @Mock private ColaboradorRepository colaboradorRepo;
    @Mock private AsignacionEquipoRepository asignacionRepo;
    @Mock private HistoricoEstadoTareaRepository historicoRepo;
    @Mock private ComentarioTareaRepository comentarioRepo;
    @Mock private AdjuntoTareaRepository adjuntoRepo;
    @Mock private TransicionEstadoRepository transicionRepo;
    @Mock private TareaMapper mapper;
    @Mock private ApplicationEventPublisher eventPublisher;

    @InjectMocks private TareaService tareaService;

    private UUID tareaId, contratoId, equipoId, colaboradorId;
    private Tarea tarea;
    private SmartGobUserDetails superUser;

    @BeforeEach
    void setUp() {
        tareaId = UUID.randomUUID();
        contratoId = UUID.randomUUID();
        equipoId = UUID.randomUUID();
        colaboradorId = UUID.randomUUID();

        Contrato contrato = new Contrato();
        contrato.setId(contratoId);

        Equipo equipo = new Equipo();
        equipo.setId(equipoId);

        Colaborador colab = new Colaborador();
        colab.setId(colaboradorId);

        tarea = new Tarea();
        tarea.setId(tareaId);
        tarea.setIdTarea("T-001");
        tarea.setTitulo("Tarea de prueba");
        tarea.setEstado("ASG");
        tarea.setContrato(contrato);
        tarea.setEquipo(equipo);
        tarea.setAsignadoA(colab);
        tarea.setCreadoPor(colab);
        tarea.setPrioridad("MEDIA");
        tarea.setCategoria("DESARROLLO");
        tarea.setPorcentajeAvance(0);
        tarea.setFechaEstimadaFin(LocalDate.now().plusDays(10));

        superUser = new SmartGobUserDetails(
                colaboradorId, "admin@test.ec", "Admin", "$2a$10$x",
                true, Map.of(), Set.of(), List.of());
    }

    @Nested
    @DisplayName("obtenerPorId")
    class ObtenerTests {

        @Test
        @DisplayName("Obtiene tarea existente")
        void obtener_exito() {
            TareaResponse expected = new TareaResponse();
            expected.setId(tareaId.toString());

            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.of(tarea));
            when(comentarioRepo.countByTareaId(tareaId)).thenReturn(3L);
            when(adjuntoRepo.countByTareaId(tareaId)).thenReturn(1L);
            when(mapper.toResponse(tarea)).thenReturn(expected);

            TareaResponse result = tareaService.obtenerPorId(tareaId);

            assertThat(result).isNotNull();
            assertThat(result.getId()).isEqualTo(tareaId.toString());
        }

        @Test
        @DisplayName("Lanza excepción si no existe")
        void obtener_noExiste() {
            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> tareaService.obtenerPorId(tareaId))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Nested
    @DisplayName("cambiarEstado")
    class CambiarEstadoTests {

        @Test
        @DisplayName("Transición válida ASG → EJE por super usuario")
        void transicionValida() {
            CambiarEstadoRequest request = new CambiarEstadoRequest();
            request.setEstadoDestino("EJE");
            request.setComentario("Iniciando ejecución");

            TareaResponse expected = new TareaResponse();
            expected.setId(tareaId.toString());

            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.of(tarea));
            when(transicionRepo.existeTransicion("ASG", "EJE")).thenReturn(true);
            when(transicionRepo.puedeTransicionar(eq("ASG"), eq("EJE"), any())).thenReturn(true);
            when(tareaRepo.save(any())).thenReturn(tarea);
            when(comentarioRepo.countByTareaId(tareaId)).thenReturn(0L);
            when(adjuntoRepo.countByTareaId(tareaId)).thenReturn(0L);
            when(mapper.toResponse(any())).thenReturn(expected);

            TareaResponse result = tareaService.cambiarEstado(tareaId, request, superUser);

            assertThat(result).isNotNull();
            verify(historicoRepo).save(any());
            verify(eventPublisher).publishEvent(any());
        }

        @Test
        @DisplayName("Transición inválida lanza excepción")
        void transicionInvalida() {
            CambiarEstadoRequest request = new CambiarEstadoRequest();
            request.setEstadoDestino("FIN");

            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.of(tarea));
            when(transicionRepo.existeTransicion("ASG", "FIN")).thenReturn(false);

            assertThatThrownBy(() -> tareaService.cambiarEstado(tareaId, request, superUser))
                    .isInstanceOf(UnauthorizedTransitionException.class);
        }
    }

    @Nested
    @DisplayName("actualizarAvance")
    class AvanceTests {

        @Test
        @DisplayName("Actualiza avance correctamente")
        void actualizarAvance_exito() {
            TareaResponse expected = new TareaResponse();
            expected.setPorcentajeAvance(75);

            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.of(tarea));
            when(tareaRepo.save(any())).thenReturn(tarea);
            when(comentarioRepo.countByTareaId(tareaId)).thenReturn(0L);
            when(adjuntoRepo.countByTareaId(tareaId)).thenReturn(0L);
            when(mapper.toResponse(any())).thenReturn(expected);

            TareaResponse result = tareaService.actualizarAvance(tareaId, 75, "Avanzando", superUser);

            assertThat(result.getPorcentajeAvance()).isEqualTo(75);
        }

        @Test
        @DisplayName("Rechaza avance fuera de rango")
        void actualizarAvance_fueraRango() {
            when(tareaRepo.findByIdConRelaciones(tareaId)).thenReturn(Optional.of(tarea));

            assertThatThrownBy(() -> tareaService.actualizarAvance(tareaId, 150, null, superUser))
                    .isInstanceOf(BusinessException.class);
        }
    }
}
EOF

cat > $B/service/EmpresaServiceTest.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Empresa;
import ec.smartgob.gproyectos.dto.mapper.EmpresaMapper;
import ec.smartgob.gproyectos.dto.request.CrearEmpresaRequest;
import ec.smartgob.gproyectos.dto.response.EmpresaResponse;
import ec.smartgob.gproyectos.exception.BusinessException;
import ec.smartgob.gproyectos.repository.EmpresaRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EmpresaServiceTest {

    @Mock private EmpresaRepository empresaRepo;
    @Mock private EmpresaMapper mapper;

    @InjectMocks private EmpresaService empresaService;

    @Test
    @DisplayName("Crear empresa con RUC único")
    void crearEmpresa_exito() {
        CrearEmpresaRequest request = new CrearEmpresaRequest();
        request.setRuc("0990000001001");
        request.setRazonSocial("TECH2GO S.A.");
        request.setTipo("CONTRATADA");

        Empresa empresa = new Empresa();
        empresa.setId(UUID.randomUUID());

        EmpresaResponse expected = new EmpresaResponse();
        expected.setRuc("0990000001001");

        when(empresaRepo.existsByRuc("0990000001001")).thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(empresa);
        when(empresaRepo.save(any())).thenReturn(empresa);
        when(mapper.toResponse(any())).thenReturn(expected);

        EmpresaResponse result = empresaService.crear(request);

        assertThat(result.getRuc()).isEqualTo("0990000001001");
        verify(empresaRepo).save(any());
    }

    @Test
    @DisplayName("Crear empresa con RUC duplicado falla")
    void crearEmpresa_rucDuplicado() {
        CrearEmpresaRequest request = new CrearEmpresaRequest();
        request.setRuc("0990000001001");

        when(empresaRepo.existsByRuc("0990000001001")).thenReturn(true);

        assertThatThrownBy(() -> empresaService.crear(request))
                .isInstanceOf(BusinessException.class);
    }
}
EOF

cat > $B/service/NotificacionServiceTest.java << 'EOF'
package ec.smartgob.gproyectos.service;

import ec.smartgob.gproyectos.domain.model.Colaborador;
import ec.smartgob.gproyectos.domain.model.Notificacion;
import ec.smartgob.gproyectos.repository.ColaboradorRepository;
import ec.smartgob.gproyectos.repository.NotificacionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificacionServiceTest {

    @Mock private NotificacionRepository notificacionRepo;
    @Mock private ColaboradorRepository colaboradorRepo;

    @InjectMocks private NotificacionService notificacionService;

    @Test
    @DisplayName("Crear notificación sin duplicados")
    void crearNotificacion_sinDuplicado() {
        UUID destinatarioId = UUID.randomUUID();
        UUID referenciaId = UUID.randomUUID();
        Colaborador dest = new Colaborador();
        dest.setId(destinatarioId);

        when(colaboradorRepo.findById(destinatarioId)).thenReturn(Optional.of(dest));
        when(notificacionRepo.existsByDestinatarioIdAndTipoAndReferenciaId(destinatarioId, "TAREA_ASIGNADA", referenciaId))
                .thenReturn(false);

        notificacionService.crearNotificacion(destinatarioId, "TAREA_ASIGNADA", "TAREA", referenciaId,
                "Nueva tarea", "Tienes una nueva tarea", "/tareas/123");

        verify(notificacionRepo).save(any(Notificacion.class));
    }

    @Test
    @DisplayName("Deduplicar notificaciones del mismo tipo")
    void crearNotificacion_duplicadaIgnorada() {
        UUID destinatarioId = UUID.randomUUID();
        UUID referenciaId = UUID.randomUUID();

        when(notificacionRepo.existsByDestinatarioIdAndTipoAndReferenciaId(destinatarioId, "TAREA_ASIGNADA", referenciaId))
                .thenReturn(true);

        notificacionService.crearNotificacion(destinatarioId, "TAREA_ASIGNADA", "TAREA", referenciaId,
                "Nueva tarea", "Tienes una nueva tarea", "/tareas/123");

        verify(notificacionRepo, never()).save(any());
    }
}
EOF

# =============================================================
# 5. UNIT TESTS — Security
# =============================================================
echo "  🔐 Unit Tests: Security..."

cat > $B/security/JwtTokenProviderTest.java << 'EOF'
package ec.smartgob.gproyectos.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.*;

import static org.assertj.core.api.Assertions.*;

class JwtTokenProviderTest {

    private JwtTokenProvider jwtProvider;

    @BeforeEach
    void setUp() {
        jwtProvider = new JwtTokenProvider();
        // Simular propiedades — en prod vienen de application.yml
        jwtProvider.setSecret("testSecretKey256BitsLongForJwtTokenSigningInTests!!");
        jwtProvider.setExpirationMs(3600000L);
    }

    @Test
    @DisplayName("Genera y valida token JWT")
    void generarYValidar() {
        UUID userId = UUID.randomUUID();
        SmartGobUserDetails user = new SmartGobUserDetails(
                userId, "test@test.ec", "Test", "$2a$10$x", false,
                Map.of(), Set.of(), List.of(new SimpleGrantedAuthority("ROLE_USER")));

        String token = jwtProvider.generarToken(user);

        assertThat(token).isNotBlank();
        assertThat(jwtProvider.validarToken(token)).isTrue();
        assertThat(jwtProvider.extraerColaboradorId(token)).isEqualTo(userId.toString());
    }

    @Test
    @DisplayName("Token expirado es inválido")
    void tokenExpirado() {
        jwtProvider.setExpirationMs(-1000L); // ya expirado
        UUID userId = UUID.randomUUID();
        SmartGobUserDetails user = new SmartGobUserDetails(
                userId, "test@test.ec", "Test", "$2a$10$x", false,
                Map.of(), Set.of(), List.of());

        String token = jwtProvider.generarToken(user);

        assertThat(jwtProvider.validarToken(token)).isFalse();
    }

    @Test
    @DisplayName("Token malformado es inválido")
    void tokenMalformado() {
        assertThat(jwtProvider.validarToken("esto-no-es-un-jwt")).isFalse();
        assertThat(jwtProvider.validarToken("")).isFalse();
        assertThat(jwtProvider.validarToken(null)).isFalse();
    }
}
EOF

# =============================================================
# 6. INTEGRATION TESTS — Controllers
# =============================================================
echo "  🔌 Integration Tests: Controllers..."

cat > $B/controller/AuthControllerIT.java << 'EOF'
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
EOF

cat > $B/controller/EmpresaControllerIT.java << 'EOF'
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
EOF

# =============================================================
# 7. INTEGRATION TEST — Repository
# =============================================================
echo "  📊 Integration Tests: Repository..."

cat > $B/repository/TareaRepositoryIT.java << 'EOF'
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
EOF

# =============================================================
# 8. Application Tests update
# =============================================================
echo "  🏗️  ApplicationTests..."

cat > $B/GestionProyectosApplicationTests.java << 'EOF'
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
EOF

# =============================================================
echo ""
echo "✅ Commit 9 completado."
echo ""
echo "Archivos creados:"
echo ""
echo "  ⚙️  Configuración:"
echo "    • application-test.yml               — TestContainers JDBC driver"
echo "    • pom.xml actualizado                 — testcontainers 1.20.4"
echo ""
echo "  🏗️  Base:"
echo "    • config/AbstractIntegrationTest      — PostgreSQL TestContainer base class"
echo "    • config/TestSecurityConfig            — helpers autenticación test"
echo ""
echo "  🧪 Unit Tests (Mockito):"
echo "    • AuthServiceTest                     — 5 tests (login cédula/correo, errores, roles)"
echo "    • TareaServiceTest                    — 5 tests (obtener, cambiar estado, avance)"
echo "    • EmpresaServiceTest                  — 2 tests (crear, RUC duplicado)"
echo "    • NotificacionServiceTest             — 2 tests (crear, deduplicar)"
echo "    • JwtTokenProviderTest                — 3 tests (generar/validar, expirado, malformado)"
echo ""
echo "  🔌 Integration Tests (TestContainers):"
echo "    • AuthControllerIT                    — 3 tests (login ok/fail/noexiste)"
echo "    • EmpresaControllerIT                 — 3 tests (listar, crear, 401)"
echo "    • TareaRepositoryIT                   — 2 tests (filtros, kanban)"
echo "    • GestionProyectosApplicationTests    — 1 test (context loads)"
echo ""
echo "  Total: 26 tests en 9 archivos"
echo ""
echo "Para ejecutar:"
echo "  cd backend && mvn test"
echo "  cd backend && mvn test -Dtest=AuthServiceTest      # solo un test"
echo "  cd backend && mvn verify                           # unit + integration"

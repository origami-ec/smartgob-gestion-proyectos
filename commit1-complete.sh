#!/bin/bash
# ============================================================
# SMARTGOB - GESTIÓN DE PROYECTOS
# Commit 1: Scaffold completo (estructura + config + security + entidades)
# 
# USO:
#   chmod +x commit1.sh && ./commit1.sh
#   cd smartgob-gestion-proyectos
#   git init && git add . && git commit -m "feat: scaffold inicial"
#   git branch -M main
#   git remote add origin https://github.com/origami-ec/smartgob-gestion-proyectos.git
#   git push -u origin main
# ============================================================

set -e
PROJECT="smartgob-gestion-proyectos"
echo "🚀 Creando proyecto: $PROJECT"
mkdir -p $PROJECT && cd $PROJECT

# === VARIABLES DE RUTA ===
B="backend/src/main/java/ec/smartgob/gproyectos"
R="backend/src/main/resources"
T="backend/src/test/java/ec/smartgob/gproyectos"

# === CREAR DIRECTORIOS ===
echo "📁 Creando estructura de directorios..."
mkdir -p $B/{config,security,domain/{model,enums,event},repository,service,bpm/{listener,delegate},controller,dto/{request,response,mapper},exception,scheduler}
mkdir -p $R/{db/migration,processes}
mkdir -p $T/{service,controller,integration}
mkdir -p frontend/src/{api,hooks,store,components/{layout,kanban,dashboard,tareas,mensajeria,common,tester},pages,types,utils,constants}
mkdir -p frontend/public

# =============================================================
# ARCHIVOS RAÍZ
# =============================================================
echo "📝 Archivos raíz..."

cat > .gitignore << 'EOF'
# Java/Maven
backend/target/
*.class
*.jar
*.war
*.log
.mvn/wrapper/maven-wrapper.jar

# Node/React
frontend/node_modules/
frontend/dist/
frontend/.env.local

# IDE
.idea/
*.iml
.vscode/
*.swp
.DS_Store

# Docker
*.env.local

# Uploads
uploads/
EOF

cat > README.md << 'EOF'
# SmartGob — Gestión de Proyectos

Módulo empresarial de Gestión de Proyectos, Equipos y Tareas integrado al ecosistema SmartGob.

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| **Backend** | Java 21, Spring Boot 3.4.3, Activiti 6 BPM |
| **Base de Datos** | PostgreSQL 16 |
| **Frontend** | React 19, TypeScript, TanStack Query, Tailwind CSS |
| **Seguridad** | JWT/OAuth2, RBAC |
| **DevOps** | Docker Compose, Flyway, Actuator/Prometheus |

## Arquitectura
```
┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│  React SPA  │────▶│  Spring Boot API │────▶│  PostgreSQL  │
│  (Port 3000)│◀────│  + Activiti BPM  │◀────│  (Port 5432) │
└─────────────┘     │  (Port 8081)     │     └──────────────┘
                    └──────────────────┘
```

## Inicio Rápido

```bash
# Levantar infraestructura
docker-compose up -d

# Backend (desarrollo)
cd backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# Frontend (desarrollo)
cd frontend && npm install && npm run dev
```

## Endpoints
- API: http://localhost:8081/api/v1/gestion-proyectos
- Swagger: http://localhost:8081/swagger-ui.html
- Frontend: http://localhost:3000

## Roles
| Rol | Código | Permisos |
|-----|--------|----------|
| Súper Usuario | SU | Control total |
| Líder | LDR | Gestión equipo, asignar/suspender tareas |
| Administrador | ADM | Igual que Líder en su equipo |
| Desarrollador | DEV | Ejecutar tareas asignadas |
| Tester | TST | Revisar y aprobar/devolver tareas |
| Documentador | DOC | Ejecutar tareas de documentación |

## Flujo de Tareas (BPM)
```
ASG → EJE → TER/TER-T → REV → FIN
       ↕                       │
      SUS        (devuelto) ◄──┘
```

© TECH2GO S.A. 2026
EOF

cat > docker-compose.yml << 'EOF'
version: '3.9'
services:
  postgres:
    image: postgres:16-alpine
    container_name: smartgob-gproyectos-db
    environment:
      POSTGRES_DB: ${DB_NAME:-smartgob_gproyectos}
      POSTGRES_USER: ${DB_USER:-smartgob}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-SmartG0b2026!}
    ports:
      - "${DB_PORT:-5432}:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-smartgob}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - smartgob-net

  backend:
    build: ./backend
    container_name: smartgob-gproyectos-api
    environment:
      SPRING_PROFILES_ACTIVE: prod
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ${DB_NAME:-smartgob_gproyectos}
      DB_USER: ${DB_USER:-smartgob}
      DB_PASSWORD: ${DB_PASSWORD:-SmartG0b2026!}
      JWT_SECRET: ${JWT_SECRET:-cH4nG3tH1sS3cr3tK3y!SmartGob2026MustBe256BitsLong!!}
      APP_TIMEZONE: ${APP_TIMEZONE:-America/Guayaquil}
      CORS_ORIGINS: ${CORS_ORIGINS:-http://localhost:3000}
    ports:
      - "${API_PORT:-8081}:8081"
    depends_on:
      postgres: { condition: service_healthy }
    networks:
      - smartgob-net

  frontend:
    build: ./frontend
    container_name: smartgob-gproyectos-ui
    ports:
      - "${UI_PORT:-3000}:80"
    depends_on:
      - backend
    networks:
      - smartgob-net

volumes:
  pgdata:
networks:
  smartgob-net:
    driver: bridge
EOF

cat > .env.example << 'EOF'
DB_NAME=smartgob_gproyectos
DB_USER=smartgob
DB_PASSWORD=SmartG0b2026!
DB_PORT=5432
API_PORT=8081
JWT_SECRET=cH4nG3tH1sS3cr3tK3y!SmartGob2026MustBe256BitsLong!!
APP_TIMEZONE=America/Guayaquil
CORS_ORIGINS=http://localhost:3000
UI_PORT=3000
EOF

# =============================================================
# BACKEND — pom.xml
# =============================================================
echo "📝 pom.xml..."

cat > backend/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.4.3</version>
        <relativePath/>
    </parent>
    <groupId>ec.smartgob</groupId>
    <artifactId>gestion-proyectos</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <name>SmartGob Gestion Proyectos</name>
    <properties>
        <java.version>21</java.version>
        <activiti.version>6.0.0</activiti.version>
        <jjwt.version>0.12.6</jjwt.version>
        <springdoc.version>2.8.4</springdoc.version>
        <mapstruct.version>1.6.3</mapstruct.version>
    </properties>
    <dependencies>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-validation</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-security</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-websocket</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-actuator</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-mail</artifactId></dependency>
        <dependency><groupId>org.activiti</groupId><artifactId>activiti-spring-boot-starter-basic</artifactId><version>${activiti.version}</version></dependency>
        <dependency><groupId>org.postgresql</groupId><artifactId>postgresql</artifactId><scope>runtime</scope></dependency>
        <dependency><groupId>org.flywaydb</groupId><artifactId>flyway-core</artifactId></dependency>
        <dependency><groupId>org.flywaydb</groupId><artifactId>flyway-database-postgresql</artifactId></dependency>
        <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-api</artifactId><version>${jjwt.version}</version></dependency>
        <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-impl</artifactId><version>${jjwt.version}</version><scope>runtime</scope></dependency>
        <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-jackson</artifactId><version>${jjwt.version}</version><scope>runtime</scope></dependency>
        <dependency><groupId>org.springdoc</groupId><artifactId>springdoc-openapi-starter-webmvc-ui</artifactId><version>${springdoc.version}</version></dependency>
        <dependency><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId><optional>true</optional></dependency>
        <dependency><groupId>org.mapstruct</groupId><artifactId>mapstruct</artifactId><version>${mapstruct.version}</version></dependency>
        <dependency><groupId>io.micrometer</groupId><artifactId>micrometer-registry-prometheus</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>
        <dependency><groupId>org.springframework.security</groupId><artifactId>spring-security-test</artifactId><scope>test</scope></dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes><exclude><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId></exclude></excludes>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <annotationProcessorPaths>
                        <path><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId><version>${lombok.version}</version></path>
                        <path><groupId>org.projectlombok</groupId><artifactId>lombok-mapstruct-binding</artifactId><version>0.2.0</version></path>
                        <path><groupId>org.mapstruct</groupId><artifactId>mapstruct-processor</artifactId><version>${mapstruct.version}</version></path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# === Backend Dockerfile ===
cat > backend/Dockerfile << 'EOF'
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY src src
RUN apk add --no-cache maven && mvn package -DskipTests -B

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S spring && adduser -S spring -G spring
COPY --from=build /app/target/*.jar app.jar
USER spring:spring
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

# =============================================================
# BACKEND — application.yml
# =============================================================
echo "📝 application.yml..."

cat > $R/application.yml << 'EOF'
server:
  port: 8081

spring:
  application:
    name: smartgob-gestion-proyectos
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:smartgob_gproyectos}
    username: ${DB_USER:smartgob}
    password: ${DB_PASSWORD:SmartG0b2026!}
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        default_schema: gestion_proyectos
        jdbc.time_zone: UTC
    open-in-view: false
  flyway:
    enabled: true
    locations: classpath:db/migration
    schemas: gestion_proyectos
    baseline-on-migrate: true
  jackson:
    serialization.write-dates-as-timestamps: false
    default-property-inclusion: non_null
    time-zone: UTC

app:
  security:
    jwt:
      secret: ${JWT_SECRET:cH4nG3tH1sS3cr3tK3y!SmartGob2026MustBe256BitsLong!!}
      expiration-ms: ${JWT_EXPIRATION:900000}
      refresh-expiration-ms: ${JWT_REFRESH_EXPIRATION:86400000}
    cors:
      allowed-origins: ${CORS_ORIGINS:http://localhost:3000,http://localhost:5173}
  timezone: ${APP_TIMEZONE:America/Guayaquil}
  sla:
    check-interval-minutes: 30
    vencimiento-alerta-horas: 72
    revision-max-horas: 72

management:
  endpoints.web.exposure.include: health,info,prometheus
EOF

cat > $R/application-dev.yml << 'EOF'
spring:
  jpa.show-sql: true
logging:
  level:
    ec.smartgob.gproyectos: DEBUG
    org.hibernate.SQL: DEBUG
EOF

cat > $R/application-prod.yml << 'EOF'
spring:
  jpa.show-sql: false
logging:
  level:
    root: WARN
    ec.smartgob.gproyectos: INFO
EOF

# =============================================================
# BACKEND — MAIN APPLICATION
# =============================================================
echo "📝 Clases Java - Main + Config..."

cat > $B/GestionProyectosApplication.java << 'EOF'
package ec.smartgob.gproyectos;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableScheduling
@EnableAsync
@EnableJpaAuditing(auditorAwareRef = "auditorProvider")
public class GestionProyectosApplication {
    public static void main(String[] args) {
        SpringApplication.run(GestionProyectosApplication.class, args);
    }
}
EOF

# =============================================================
# CONFIG CLASSES
# =============================================================

cat > $B/config/AuditConfig.java << 'EOF'
package ec.smartgob.gproyectos.config;

import ec.smartgob.gproyectos.security.SmartGobUserDetails;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

@Configuration
public class AuditConfig {

    @Bean
    public AuditorAware<String> auditorProvider() {
        return () -> {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null || !auth.isAuthenticated()
                    || "anonymousUser".equals(auth.getPrincipal())) {
                return Optional.of("SYSTEM");
            }
            if (auth.getPrincipal() instanceof SmartGobUserDetails ud) {
                return Optional.of(ud.getColaboradorId().toString());
            }
            return Optional.of(auth.getName());
        };
    }
}
EOF

cat > $B/config/WebConfig.java << 'EOF'
package ec.smartgob.gproyectos.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.security.cors.allowed-origins:http://localhost:3000}")
    private String allowedOrigins;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins(allowedOrigins.split(","))
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }
}
EOF

cat > $B/config/WebSocketConfig.java << 'EOF'
package ec.smartgob.gproyectos.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Value("${app.security.cors.allowed-origins:http://localhost:3000}")
    private String allowedOrigins;

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
        config.setUserDestinationPrefix("/user");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOrigins(allowedOrigins.split(","))
                .withSockJS();
    }
}
EOF

cat > $B/config/OpenApiConfig.java << 'EOF'
package ec.smartgob.gproyectos.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        final String scheme = "bearerAuth";
        return new OpenAPI()
            .info(new Info()
                .title("SmartGob - Gestión de Proyectos API")
                .version("1.0.0")
                .description("API REST del módulo de Gestión de Proyectos integrado a SmartGob")
                .contact(new Contact().name("TECH2GO S.A.").email("soporte@tech2go.ec")))
            .addSecurityItem(new SecurityRequirement().addList(scheme))
            .components(new Components().addSecuritySchemes(scheme,
                new SecurityScheme().type(SecurityScheme.Type.HTTP)
                    .scheme("bearer").bearerFormat("JWT")));
    }
}
EOF

cat > $B/config/SchedulerConfig.java << 'EOF'
package ec.smartgob.gproyectos.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;

@Configuration
public class SchedulerConfig {

    @Bean
    public ThreadPoolTaskScheduler taskScheduler() {
        ThreadPoolTaskScheduler scheduler = new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(4);
        scheduler.setThreadNamePrefix("smartgob-sla-");
        scheduler.setErrorHandler(t ->
            org.slf4j.LoggerFactory.getLogger("SLAScheduler")
                .error("Error en job: {}", t.getMessage(), t));
        return scheduler;
    }
}
EOF

cat > $B/config/ActivitiConfig.java << 'EOF'
package ec.smartgob.gproyectos.config;

import org.activiti.engine.*;
import org.activiti.spring.ProcessEngineFactoryBean;
import org.activiti.spring.SpringProcessEngineConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;
import java.io.IOException;

@Configuration
public class ActivitiConfig {

    @Bean
    public SpringProcessEngineConfiguration processEngineConfiguration(
            DataSource dataSource, PlatformTransactionManager txManager) throws IOException {

        SpringProcessEngineConfiguration config = new SpringProcessEngineConfiguration();
        config.setDataSource(dataSource);
        config.setTransactionManager(txManager);
        config.setDatabaseSchemaUpdate("true");
        config.setHistoryLevel(org.activiti.engine.impl.history.HistoryLevel.FULL);
        config.setAsyncExecutorActivate(true);

        Resource[] bpmn = new PathMatchingResourcePatternResolver()
                .getResources("classpath:/processes/*.bpmn20.xml");
        config.setDeploymentResources(bpmn);

        return config;
    }

    @Bean
    public ProcessEngineFactoryBean processEngine(SpringProcessEngineConfiguration config) {
        ProcessEngineFactoryBean factory = new ProcessEngineFactoryBean();
        factory.setProcessEngineConfiguration(config);
        return factory;
    }

    @Bean public RuntimeService runtimeService(ProcessEngine pe) { return pe.getRuntimeService(); }
    @Bean public TaskService taskService(ProcessEngine pe) { return pe.getTaskService(); }
    @Bean public HistoryService historyService(ProcessEngine pe) { return pe.getHistoryService(); }
    @Bean public RepositoryService repositoryService(ProcessEngine pe) { return pe.getRepositoryService(); }
}
EOF

cat > $B/config/SecurityConfig.java << 'EOF'
package ec.smartgob.gproyectos.config;

import ec.smartgob.gproyectos.security.JwtAuthFilter;
import ec.smartgob.gproyectos.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtTokenProvider tokenProvider;

    private static final String[] PUBLIC = {
        "/api/auth/**", "/actuator/health", "/actuator/info",
        "/swagger-ui/**", "/swagger-ui.html", "/v3/api-docs/**", "/ws/**"
    };

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(c -> c.disable())
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(PUBLIC).permitAll()
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers("/api/v1/gestion-proyectos/admin/**").hasRole("SUPER_USUARIO")
                .anyRequest().authenticated())
            .addFilterBefore(new JwtAuthFilter(tokenProvider), UsernamePasswordAuthenticationFilter.class)
            .headers(h -> h.frameOptions(f -> f.sameOrigin()))
            .build();
    }

    @Bean public PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(12); }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration c) throws Exception {
        return c.getAuthenticationManager();
    }
}
EOF

# =============================================================
# SECURITY CLASSES
# =============================================================
echo "📝 Clases Java - Security..."

cat > $B/security/RoleConstants.java << 'EOF'
package ec.smartgob.gproyectos.security;

public final class RoleConstants {
    private RoleConstants() {}

    public static final String SUPER_USUARIO = "SUPER_USUARIO";
    public static final String LIDER         = "LDR";
    public static final String ADMINISTRADOR = "ADM";
    public static final String DESARROLLADOR = "DEV";
    public static final String TESTER        = "TST";
    public static final String DOCUMENTADOR  = "DOC";

    public static boolean esRolGestion(String rol) {
        return LIDER.equals(rol) || ADMINISTRADOR.equals(rol);
    }
    public static boolean esRolEjecucion(String rol) {
        return DESARROLLADOR.equals(rol) || DOCUMENTADOR.equals(rol);
    }
}
EOF

cat > $B/security/SmartGobUserDetails.java << 'EOF'
package ec.smartgob.gproyectos.security;

import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.*;
import java.util.stream.Collectors;

@Getter
public class SmartGobUserDetails implements UserDetails {

    private final UUID colaboradorId;
    private final String cedula;
    private final String nombreCompleto;
    private final String correo;
    private final String password;
    private final boolean esSuperUsuario;
    private final Map<UUID, String> rolesPorEquipo;
    private final Map<UUID, Set<UUID>> contratosAccesibles;
    private final Collection<? extends GrantedAuthority> authorities;

    public SmartGobUserDetails(UUID colaboradorId, String cedula, String nombreCompleto,
                                String correo, String password, boolean esSuperUsuario,
                                Map<UUID, String> rolesPorEquipo,
                                Map<UUID, Set<UUID>> contratosAccesibles) {
        this.colaboradorId = colaboradorId;
        this.cedula = cedula;
        this.nombreCompleto = nombreCompleto;
        this.correo = correo;
        this.password = password;
        this.esSuperUsuario = esSuperUsuario;
        this.rolesPorEquipo = rolesPorEquipo != null ? rolesPorEquipo : Map.of();
        this.contratosAccesibles = contratosAccesibles != null ? contratosAccesibles : Map.of();

        Set<GrantedAuthority> auths = new HashSet<>();
        if (esSuperUsuario) auths.add(new SimpleGrantedAuthority("ROLE_SUPER_USUARIO"));
        this.rolesPorEquipo.values().stream().distinct()
            .forEach(r -> auths.add(new SimpleGrantedAuthority("ROLE_" + r)));
        this.authorities = Collections.unmodifiableSet(auths);
    }

    @Override public String getUsername() { return cedula; }
    @Override public boolean isAccountNonExpired() { return true; }
    @Override public boolean isAccountNonLocked() { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled() { return true; }

    public Optional<String> getRolEnEquipo(UUID equipoId) {
        if (esSuperUsuario) return Optional.of(RoleConstants.SUPER_USUARIO);
        return Optional.ofNullable(rolesPorEquipo.get(equipoId));
    }

    public boolean tieneAccesoContrato(UUID contratoId) {
        return esSuperUsuario || contratosAccesibles.containsKey(contratoId);
    }

    public boolean esGestorEnEquipo(UUID equipoId) {
        if (esSuperUsuario) return true;
        return RoleConstants.esRolGestion(rolesPorEquipo.get(equipoId));
    }
}
EOF

cat > $B/security/JwtTokenProvider.java << 'EOF'
package ec.smartgob.gproyectos.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;

@Component
@Slf4j
public class JwtTokenProvider {

    @Value("${app.security.jwt.secret}")
    private String jwtSecret;

    @Value("${app.security.jwt.expiration-ms}")
    private long jwtExpirationMs;

    @Value("${app.security.jwt.refresh-expiration-ms}")
    private long refreshExpirationMs;

    private SecretKey key;

    @PostConstruct
    public void init() {
        this.key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
    }

    public String generateToken(SmartGobUserDetails user) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("colaboradorId", user.getColaboradorId().toString());
        claims.put("nombre", user.getNombreCompleto());
        claims.put("correo", user.getCorreo());
        claims.put("superUsuario", user.isEsSuperUsuario());
        claims.put("roles", user.getAuthorities().stream().map(Object::toString).toList());
        claims.put("rolesPorEquipo", user.getRolesPorEquipo().entrySet().stream()
                .collect(Collectors.toMap(e -> e.getKey().toString(), Map.Entry::getValue)));

        Date now = new Date();
        return Jwts.builder()
                .subject(user.getCedula())
                .claims(claims)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + jwtExpirationMs))
                .signWith(key, Jwts.SIG.HS256)
                .compact();
    }

    public String generateRefreshToken(String cedula) {
        Date now = new Date();
        return Jwts.builder()
                .subject(cedula).claim("type", "refresh")
                .issuedAt(now).expiration(new Date(now.getTime() + refreshExpirationMs))
                .signWith(key, Jwts.SIG.HS256).compact();
    }

    @SuppressWarnings("unchecked")
    public Authentication getAuthentication(String token) {
        Claims claims = parseClaims(token);
        UUID colabId = UUID.fromString(claims.get("colaboradorId", String.class));
        boolean su = Boolean.TRUE.equals(claims.get("superUsuario", Boolean.class));

        List<String> roles = claims.get("roles", List.class);
        var auths = roles.stream().map(SimpleGrantedAuthority::new).collect(Collectors.toList());

        Map<String, String> rpeStr = claims.get("rolesPorEquipo", Map.class);
        Map<UUID, String> rpe = new HashMap<>();
        if (rpeStr != null) rpeStr.forEach((k, v) -> rpe.put(UUID.fromString(k), v));

        SmartGobUserDetails ud = new SmartGobUserDetails(
            colabId, claims.getSubject(), claims.get("nombre", String.class),
            claims.get("correo", String.class), "", su, rpe, Map.of());

        return new UsernamePasswordAuthenticationToken(ud, null, auths);
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("JWT inválido: {}", e.getMessage());
        }
        return false;
    }

    private Claims parseClaims(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    }
}
EOF

cat > $B/security/JwtAuthFilter.java << 'EOF'
package ec.smartgob.gproyectos.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@RequiredArgsConstructor
@Slf4j
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                     FilterChain chain) throws ServletException, IOException {
        try {
            String bearer = request.getHeader("Authorization");
            if (StringUtils.hasText(bearer) && bearer.startsWith("Bearer ")) {
                String token = bearer.substring(7);
                if (tokenProvider.validateToken(token)) {
                    Authentication auth = tokenProvider.getAuthentication(token);
                    SecurityContextHolder.getContext().setAuthentication(auth);
                    org.slf4j.MDC.put("userId",
                        ((SmartGobUserDetails) auth.getPrincipal()).getColaboradorId().toString());
                }
            }
        } catch (Exception e) {
            log.error("Error procesando JWT: {}", e.getMessage());
            SecurityContextHolder.clearContext();
        }
        chain.doFilter(request, response);
        org.slf4j.MDC.remove("userId");
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return request.getServletPath().startsWith("/ws");
    }
}
EOF

# =============================================================
# ENUMS
# =============================================================
echo "📝 Clases Java - Enums..."

cat > $B/domain/enums/EstadoTarea.java << 'EOF'
package ec.smartgob.gproyectos.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum EstadoTarea {
    ASG("Asignado", "#3B82F6", "#DBEAFE"),
    EJE("Ejecutando", "#F59E0B", "#FEF3C7"),
    SUS("Suspendido", "#6B7280", "#F3F4F6"),
    TER("Terminada", "#10B981", "#D1FAE5"),
    TERT("Terminada fuera plazo", "#EF4444", "#FEE2E2"),
    REV("En Revisión", "#8B5CF6", "#EDE9FE"),
    FIN("Finalizada", "#059669", "#ECFDF5");

    private final String nombre;
    private final String colorHex;
    private final String colorBgHex;
}
EOF

cat > $B/domain/enums/RolEquipo.java << 'EOF'
package ec.smartgob.gproyectos.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum RolEquipo {
    LDR("Líder"), ADM("Administrador"), DEV("Desarrollador"),
    TST("Tester"), DOC("Documentador");

    private final String nombre;

    public boolean esGestion() { return this == LDR || this == ADM; }
    public boolean esEjecucion() { return this == DEV || this == DOC; }
}
EOF

cat > $B/domain/enums/Prioridad.java << 'EOF'
package ec.smartgob.gproyectos.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum Prioridad {
    CRITICA("Crítica", "#DC2626", 4), ALTA("Alta", "#F97316", 3),
    MEDIA("Media", "#EAB308", 2), BAJA("Baja", "#6B7280", 1);

    private final String nombre;
    private final String colorHex;
    private final int peso;
}
EOF

cat > $B/domain/enums/CategoriaTarea.java << 'EOF'
package ec.smartgob.gproyectos.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum CategoriaTarea {
    DESARROLLO("Desarrollo"), DISENO("Diseño"),
    DOCUMENTACION("Documentación"), PRUEBAS("Pruebas");

    private final String nombre;
}
EOF

cat > $B/domain/enums/TipoColaborador.java << 'EOF'
package ec.smartgob.gproyectos.domain.enums;

public enum TipoColaborador { INTERNO, EXTERNO }
EOF

# =============================================================
# DOMAIN ENTITIES
# =============================================================
echo "📝 Clases Java - Entidades..."

cat > $B/domain/model/BaseEntity.java << 'EOF'
package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedBy;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.OffsetDateTime;
import java.util.UUID;

@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter
public abstract class BaseEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private Boolean deleted = false;

    @CreatedDate @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @LastModifiedDate @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @CreatedBy @Column(name = "created_by", length = 50)
    private String createdBy;

    @LastModifiedBy @Column(name = "updated_by", length = 50)
    private String updatedBy;
}
EOF

cat > $B/domain/model/Empresa.java << 'EOF'
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
}
EOF

cat > $B/domain/model/Colaborador.java << 'EOF'
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
EOF

cat > $B/domain/model/Contrato.java << 'EOF'
package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import java.time.LocalDate;

@Entity @Table(name = "contrato", schema = "gestion_proyectos")
@SQLRestriction("deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Contrato extends BaseEntity {
    @Column(name = "nro_contrato", unique = true, nullable = false, length = 50) private String nroContrato;
    @Column(nullable = false, length = 200) private String cliente;
    @Column(name = "tipo_proyecto", nullable = false, length = 50) private String tipoProyecto;
    @Column(name = "fecha_inicio", nullable = false) private LocalDate fechaInicio;
    @Column(name = "plazo_dias", nullable = false) private Integer plazoDias;
    @Column(name = "fecha_fin", nullable = false) private LocalDate fechaFin;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "administrador_id") private Colaborador administrador;
    @Column(name = "correo_admin", length = 150) private String correoAdmin;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "empresa_contratada_id") private Empresa empresaContratada;
    @Column(name = "ultima_fase", length = 100) private String ultimaFase;
    @Column(length = 20) private String estado = "ACTIVO";
    @Column(name = "objeto_contrato", columnDefinition = "TEXT") private String objetoContrato;

    public Contrato(java.util.UUID id) { this.setId(id); }
}
EOF

cat > $B/domain/model/Equipo.java << 'EOF'
package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;

@Entity @Table(name = "equipo", schema = "gestion_proyectos",
    uniqueConstraints = @UniqueConstraint(columnNames = {"nombre", "contrato_id"}))
@SQLRestriction("deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Equipo extends BaseEntity {
    @Column(nullable = false, length = 100) private String nombre;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "contrato_id", nullable = false) private Contrato contrato;
    @Column(length = 300) private String descripcion;
    @Column(length = 10) private String estado = "ACTIVO";

    public Equipo(java.util.UUID id) { this.setId(id); }
}
EOF

cat > $B/domain/model/AsignacionEquipo.java << 'EOF'
package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import java.time.LocalDate;

@Entity @Table(name = "asignacion_equipo", schema = "gestion_proyectos",
    uniqueConstraints = @UniqueConstraint(columnNames = {"equipo_id", "colaborador_id"}))
@SQLRestriction("deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AsignacionEquipo extends BaseEntity {
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "equipo_id", nullable = false) private Equipo equipo;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "colaborador_id", nullable = false) private Colaborador colaborador;
    @Column(name = "rol_equipo", nullable = false, length = 5) private String rolEquipo;
    @Column(name = "fecha_asignacion", nullable = false) private LocalDate fechaAsignacion = LocalDate.now();
    @Column(length = 10) private String estado = "ACTIVO";
}
EOF

cat > $B/domain/model/Tarea.java << 'EOF'
package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLRestriction;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;

@Entity @Table(name = "tarea", schema = "gestion_proyectos",
    uniqueConstraints = @UniqueConstraint(columnNames = {"id_tarea", "contrato_id"}))
@SQLRestriction("deleted = false")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Tarea extends BaseEntity {
    @Column(name = "id_tarea", nullable = false, length = 20) private String idTarea;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "contrato_id", nullable = false) private Contrato contrato;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "equipo_id", nullable = false) private Equipo equipo;
    @Column(nullable = false, length = 20) private String categoria;
    @Column(nullable = false, length = 200) private String titulo;
    @Column(columnDefinition = "TEXT") private String descripcion;
    @Column(nullable = false, length = 10) private String prioridad;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "asignado_a_id") private Colaborador asignadoA;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "creado_por_id", nullable = false) private Colaborador creadoPor;
    @Column(name = "fecha_asignacion", nullable = false) private LocalDate fechaAsignacion = LocalDate.now();
    @Column(nullable = false, length = 5) private String estado = "ASG";
    @Column(name = "fecha_estimada_fin", nullable = false) private LocalDate fechaEstimadaFin;
    @Column(name = "porcentaje_avance", nullable = false) private Integer porcentajeAvance = 0;
    @Column(columnDefinition = "TEXT") private String observaciones;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "revisado_por_id") private Colaborador revisadoPor;
    @Column(name = "fecha_revision") private OffsetDateTime fechaRevision;
    @Column(name = "process_instance_id", length = 100) private String processInstanceId;

    public Tarea(java.util.UUID id) { this.setId(id); }
    public int getDiasRestantes() { return Math.max(0, (int) ChronoUnit.DAYS.between(LocalDate.now(), fechaEstimadaFin)); }
    public boolean isDentroDePlazo() { return !LocalDate.now().isAfter(fechaEstimadaFin); }
}
EOF

cat > $B/domain/model/HistoricoEstadoTarea.java << 'EOF'
package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "historico_estado_tarea", schema = "gestion_proyectos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class HistoricoEstadoTarea {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "tarea_id", nullable = false) private Tarea tarea;
    @Column(name = "estado_anterior", length = 5) private String estadoAnterior;
    @Column(name = "estado_nuevo", nullable = false, length = 5) private String estadoNuevo;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "cambiado_por_id", nullable = false) private Colaborador cambiadoPor;
    @Column(columnDefinition = "TEXT") private String comentario;
    @Column(nullable = false) private OffsetDateTime fecha = OffsetDateTime.now();
}
EOF

cat > $B/domain/model/ComentarioTarea.java << 'EOF'
package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "comentario_tarea", schema = "gestion_proyectos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ComentarioTarea {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "tarea_id", nullable = false) private Tarea tarea;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "autor_id", nullable = false) private Colaborador autor;
    @Column(nullable = false, columnDefinition = "TEXT") private String contenido;
    @Column(length = 20) private String tipo = "COMENTARIO";
    @Column(name = "created_at", nullable = false) private OffsetDateTime createdAt = OffsetDateTime.now();
}
EOF

cat > $B/domain/model/AdjuntoTarea.java << 'EOF'
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
EOF

cat > $B/domain/model/Mensaje.java << 'EOF'
package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "mensaje", schema = "gestion_proyectos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Mensaje {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "remitente_id", nullable = false) private Colaborador remitente;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "destinatario_id") private Colaborador destinatario;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "equipo_id") private Equipo equipo;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "contrato_id") private Contrato contrato;
    @Column(length = 200) private String asunto;
    @Column(nullable = false, columnDefinition = "TEXT") private String contenido;
    @Column(length = 20) private String tipo = "DIRECTO";
    private Boolean leido = false;
    @Column(name = "created_at", nullable = false) private OffsetDateTime createdAt = OffsetDateTime.now();
}
EOF

cat > $B/domain/model/Notificacion.java << 'EOF'
package ec.smartgob.gproyectos.domain.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity @Table(name = "notificacion", schema = "gestion_proyectos")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Notificacion {
    @Id @GeneratedValue(strategy = GenerationType.UUID) private UUID id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "destinatario_id", nullable = false) private Colaborador destinatario;
    @Column(nullable = false, length = 30) private String tipo;
    @Column(name = "referencia_tipo", length = 30) private String referenciaTipo;
    @Column(name = "referencia_id") private UUID referenciaId;
    @Column(nullable = false, length = 200) private String titulo;
    @Column(nullable = false, columnDefinition = "TEXT") private String mensaje;
    private Boolean leido = false;
    @Column(name = "url_accion", length = 500) private String urlAccion;
    @Column(name = "created_at", nullable = false) private OffsetDateTime createdAt = OffsetDateTime.now();
}
EOF

# === DOMAIN EVENT ===
cat > $B/domain/event/TareaEstadoCambiadoEvent.java << 'EOF'
package ec.smartgob.gproyectos.domain.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;
import java.util.UUID;

@Getter
public class TareaEstadoCambiadoEvent extends ApplicationEvent {
    private final UUID tareaId;
    private final String estadoAnterior;
    private final String estadoNuevo;
    private final UUID cambiadoPorId;

    public TareaEstadoCambiadoEvent(Object source, UUID tareaId,
            String estadoAnterior, String estadoNuevo, UUID cambiadoPorId) {
        super(source);
        this.tareaId = tareaId;
        this.estadoAnterior = estadoAnterior;
        this.estadoNuevo = estadoNuevo;
        this.cambiadoPorId = cambiadoPorId;
    }
}
EOF

# === EXCEPTIONS ===
cat > $B/exception/BusinessException.java << 'EOF'
package ec.smartgob.gproyectos.exception;

public class BusinessException extends RuntimeException {
    public BusinessException(String message) { super(message); }
}
EOF

cat > $B/exception/ResourceNotFoundException.java << 'EOF'
package ec.smartgob.gproyectos.exception;

public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String resource, Object id) {
        super(String.format("%s no encontrado con id: %s", resource, id));
    }
}
EOF

cat > $B/exception/UnauthorizedTransitionException.java << 'EOF'
package ec.smartgob.gproyectos.exception;

public class UnauthorizedTransitionException extends RuntimeException {
    public UnauthorizedTransitionException(String message) { super(message); }
}
EOF

cat > $B/exception/GlobalExceptionHandler.java << 'EOF'
package ec.smartgob.gproyectos.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.net.URI;
import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ProblemDetail handleBusiness(BusinessException ex) {
        log.warn("Negocio: {}", ex.getMessage());
        var pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, ex.getMessage());
        pd.setTitle("Error de Negocio");
        pd.setProperty("timestamp", OffsetDateTime.now());
        return pd;
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ProblemDetail handleNotFound(ResourceNotFoundException ex) {
        var pd = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        pd.setTitle("No Encontrado");
        pd.setProperty("timestamp", OffsetDateTime.now());
        return pd;
    }

    @ExceptionHandler(UnauthorizedTransitionException.class)
    public ProblemDetail handleUnauthorized(UnauthorizedTransitionException ex) {
        log.warn("Transición no autorizada: {}", ex.getMessage());
        var pd = ProblemDetail.forStatusAndDetail(HttpStatus.FORBIDDEN, ex.getMessage());
        pd.setTitle("Transición No Autorizada");
        pd.setProperty("timestamp", OffsetDateTime.now());
        return pd;
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ProblemDetail handleAccess(AccessDeniedException ex) {
        var pd = ProblemDetail.forStatusAndDetail(HttpStatus.FORBIDDEN, "Sin permisos");
        pd.setTitle("Acceso Denegado");
        pd.setProperty("timestamp", OffsetDateTime.now());
        return pd;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        for (FieldError e : ex.getBindingResult().getFieldErrors())
            errors.put(e.getField(), e.getDefaultMessage());
        var pd = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Error de validación");
        pd.setTitle("Validación");
        pd.setProperty("errores", errors);
        pd.setProperty("timestamp", OffsetDateTime.now());
        return pd;
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleGeneral(Exception ex) {
        log.error("Error inesperado: {}", ex.getMessage(), ex);
        var pd = ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR, "Error interno");
        pd.setTitle("Error Interno");
        pd.setProperty("timestamp", OffsetDateTime.now());
        return pd;
    }
}
EOF

# === PLACEHOLDER para BPMN ===
cat > $R/processes/tarea-lifecycle.bpmn20.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!-- BPMN se completará en Commit 4 -->
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"
    targetNamespace="http://smartgob.tech2go.ec/gestion-proyectos">
</definitions>
EOF

# === PLACEHOLDER Flyway ===
cat > $R/db/migration/V1__create_schema.sql << 'EOF'
-- Flyway V1: Schema y parametrización
-- Se completará en Commit 2
CREATE SCHEMA IF NOT EXISTS gestion_proyectos;
EOF

# === TEST ===
cat > $T/GestionProyectosApplicationTests.java << 'EOF'
package ec.smartgob.gproyectos;

import org.junit.jupiter.api.Test;

class GestionProyectosApplicationTests {
    @Test
    void contextLoads() {
        // Verificación básica de que las clases compilan
    }
}
EOF

# === FRONTEND PLACEHOLDERS ===
cat > frontend/package.json << 'EOF'
{
  "name": "smartgob-gproyectos-ui",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@vitejs/plugin-react": "^4.3.0",
    "typescript": "^5.7.0",
    "vite": "^6.2.0"
  }
}
EOF

cat > frontend/Dockerfile << 'EOF'
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json .
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

echo ""
echo "============================================================"
echo "✅ COMMIT 1 COMPLETO"
echo "============================================================"
echo ""
echo "Archivos creados:"
find . -type f | head -60
echo ""
echo "📋 Ejecuta estos comandos:"
echo ""
echo "  cd $(pwd)"
echo "  git init"
echo "  git add ."
echo '  git commit -m "feat: scaffold inicial - estructura, config, security, entidades JPA"'
echo "  git branch -M main"
echo "  git remote add origin https://github.com/origami-ec/smartgob-gestion-proyectos.git"
echo "  git push -u origin main"
echo ""
echo "============================================================"

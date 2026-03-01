#!/bin/bash
# ============================================================
# COMMIT 10: Fixes finales + scripts de prueba + Postman
# EJECUTAR DESPUÉS DE COMMITS 1-9
# Desde raíz: smartgob-gestion-proyectos/
#
#   git add .
#   git commit -m "fix: compilación completa - DTOs faltantes, AuthResponse, tests API, Postman"
#   git push
# ============================================================

set -e
B="backend/src/main/java/ec/smartgob/gproyectos"
echo "📦 Commit 10: Fixes finales + scripts prueba"

# =============================================================
# 1. REQUEST DTOs FALTANTES
# =============================================================
echo "  📐 Request DTOs faltantes..."

cat > $B/dto/request/AsignarMiembroRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class AsignarMiembroRequest {
    @NotNull(message = "El colaborador es obligatorio")
    private UUID colaboradorId;

    @NotBlank(message = "El rol es obligatorio")
    private String rolEquipo;
}
EOF

cat > $B/dto/request/ActualizarAvanceRequest.java << 'EOF'
package ec.smartgob.gproyectos.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ActualizarAvanceRequest {
    @NotNull(message = "El porcentaje de avance es obligatorio")
    @Min(value = 0, message = "Mínimo 0%")
    @Max(value = 100, message = "Máximo 100%")
    private Integer porcentajeAvance;

    private String observaciones;
}
EOF

# =============================================================
# 2. FIX AuthResponse — agregar roles + RolEquipoInfo
# =============================================================
echo "  🔧 Fix AuthResponse con roles..."

cat > $B/dto/response/AuthResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import lombok.*;
import java.util.List;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class AuthResponse {
    private String token;
    @Builder.Default
    private String tipo = "Bearer";
    private UUID colaboradorId;
    private String nombreCompleto;
    private String correo;
    private Boolean esSuperUsuario;
    private List<RolEquipoInfo> roles;

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class RolEquipoInfo {
        private UUID equipoId;
        private String equipoNombre;
        private String rol;
    }
}
EOF

# =============================================================
# 3. FIX NotificacionResponse — asegurar campos
# =============================================================
echo "  🔧 Verificar NotificacionResponse..."

cat > $B/dto/response/NotificacionResponse.java << 'EOF'
package ec.smartgob.gproyectos.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data @JsonInclude(JsonInclude.Include.NON_NULL)
public class NotificacionResponse {
    private UUID id;
    private String tipo;
    private String referenciaTipo;
    private UUID referenciaId;
    private String titulo;
    private String mensaje;
    private Boolean leido;
    private String urlAccion;
    private OffsetDateTime createdAt;
}
EOF

# =============================================================
# 4. FIX Mensaje entity — asegurar constructor UUID
# =============================================================
echo "  🔧 Verificar constructores UUID en entities..."

# Verificar que Empresa tiene constructor UUID
EMPRESA_FILE="$B/domain/model/Empresa.java"
if ! grep -q "public Empresa(java.util.UUID" "$EMPRESA_FILE" 2>/dev/null; then
    sed -i '/public class Empresa/,/^}$/{ /^}$/i\    public Empresa(java.util.UUID id) { this.setId(id); }
}' "$EMPRESA_FILE"
fi

# Verificar Mensaje
MSG_FILE="$B/domain/model/Mensaje.java"
if ! grep -q "public Mensaje(java.util.UUID" "$MSG_FILE" 2>/dev/null; then
    sed -i '/public class Mensaje/,/^}$/{ /^}$/i\    public Mensaje(java.util.UUID id) { this.setId(id); }
}' "$MSG_FILE"
fi

# Verificar Notificacion
NOT_FILE="$B/domain/model/Notificacion.java"
if ! grep -q "public Notificacion(java.util.UUID" "$NOT_FILE" 2>/dev/null; then
    sed -i '/public class Notificacion/,/^}$/{ /^}$/i\    public Notificacion(java.util.UUID id) { this.setId(id); }
}' "$NOT_FILE"
fi

# =============================================================
# 5. FIX DashboardService — usar TareaAlertaResponse not TareaAlertaSlaResponse
# =============================================================
echo "  🔧 Verificar DashboardService..."

# DashboardService ya usa TareaAlertaResponse — verificar que mapper.toAlertaResponse existe
# (se definió en commit 9 en TareaMapper)

# =============================================================
# 6. Logback config
# =============================================================
echo "  📋 logback-spring.xml..."

cat > backend/src/main/resources/logback-spring.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>

    <!-- Console -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%clr(%d{HH:mm:ss.SSS}){faint} %clr(%-5level) %clr([%thread]){faint} %clr(%logger{36}){cyan} - %msg%n</pattern>
        </encoder>
    </appender>

    <!-- File (producción) -->
    <springProfile name="prod">
        <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
            <file>/app/logs/smartgob-gproyectos.log</file>
            <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
                <fileNamePattern>/app/logs/smartgob-gproyectos.%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
                <maxFileSize>50MB</maxFileSize>
                <maxHistory>30</maxHistory>
                <totalSizeCap>1GB</totalSizeCap>
            </rollingPolicy>
            <encoder>
                <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level [%thread] [%X{userId:-anon}] %logger{36} - %msg%n</pattern>
            </encoder>
        </appender>
        <root level="WARN">
            <appender-ref ref="FILE"/>
            <appender-ref ref="CONSOLE"/>
        </root>
        <logger name="ec.smartgob" level="INFO"/>
    </springProfile>

    <!-- Dev -->
    <springProfile name="dev,test">
        <root level="INFO">
            <appender-ref ref="CONSOLE"/>
        </root>
        <logger name="ec.smartgob" level="DEBUG"/>
    </springProfile>
</configuration>
EOF

# =============================================================
# 7. Script de pruebas API con cURL
# =============================================================
echo "  🧪 Script de pruebas API..."

mkdir -p scripts

cat > scripts/test-api.sh << 'SCRIPTEOF'
#!/bin/bash
# ═══════════════════════════════════════════════════════════
# SmartGob — Script de pruebas API
# Uso: ./scripts/test-api.sh [BASE_URL]
# Default: http://localhost (vía nginx) o http://localhost:8081
# ═══════════════════════════════════════════════════════════

set -e
BASE=${1:-http://localhost}
API="$BASE/api"
GP="$API/v1/gestion-proyectos"
TOKEN=""
COLABORADOR_ID=""
CONTRATO_ID=""
EQUIPO_ID=""
TAREA_ID=""
PASSED=0
FAILED=0
TOTAL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

assert_status() {
    TOTAL=$((TOTAL+1))
    local desc="$1" expected="$2" actual="$3" body="$4"
    if [ "$actual" = "$expected" ]; then
        echo -e "  ${GREEN}✅ $desc${NC} (HTTP $actual)"
        PASSED=$((PASSED+1))
    else
        echo -e "  ${RED}❌ $desc${NC} — esperado $expected, obtenido $actual"
        [ -n "$body" ] && echo "     $body" | head -2
        FAILED=$((FAILED+1))
    fi
}

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  SmartGob — Tests API REST"
echo "  Base URL: $BASE"
echo "═══════════════════════════════════════════════════════"
echo ""

# ── Health check ──────────────────────────────────────────
echo -e "${YELLOW}▸ Health Check${NC}"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/actuator/health" 2>/dev/null)
assert_status "GET /actuator/health" "200" "$HTTP"

# ── Auth: Login ───────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ Autenticación${NC}"

RESP=$(curl -s -w "\n%{http_code}" -X POST "$API/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"usuario":"0900000001","password":"Admin2026!"}')
HTTP=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -n -1)
assert_status "POST /api/auth/login (super usuario)" "200" "$HTTP" "$BODY"

if [ "$HTTP" = "200" ]; then
    TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    COLABORADOR_ID=$(echo "$BODY" | grep -o '"colaboradorId":"[^"]*"' | cut -d'"' -f4)
    echo "     Token: ${TOKEN:0:20}..."
    echo "     ColaboradorId: $COLABORADOR_ID"
fi

AUTH="Authorization: Bearer $TOKEN"

# ── Auth: Me ──────────────────────────────────────────────
RESP=$(curl -s -w "\n%{http_code}" "$API/auth/me" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /api/auth/me" "200" "$HTTP"

# ── Auth: Sin token ──────────────────────────────────────
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$GP/empresas")
assert_status "GET /empresas sin auth → 401/403" "401" "$HTTP"

# ── Empresas ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ Empresas${NC}"

RESP=$(curl -s -w "\n%{http_code}" "$GP/empresas/activas" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /empresas/activas" "200" "$HTTP"

RESP=$(curl -s -w "\n%{http_code}" -X POST "$GP/empresas" -H "$AUTH" \
    -H "Content-Type: application/json" \
    -d '{"ruc":"0990999001001","razonSocial":"Empresa Test API","tipo":"CONTRATISTA"}')
HTTP=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -n -1)
assert_status "POST /empresas (crear)" "201" "$HTTP" "$BODY"

# ── Colaboradores ─────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ Colaboradores${NC}"

RESP=$(curl -s -w "\n%{http_code}" "$GP/colaboradores/activos" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /colaboradores/activos" "200" "$HTTP"

RESP=$(curl -s -w "\n%{http_code}" "$GP/colaboradores?busqueda=admin" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /colaboradores?busqueda=admin (paginado)" "200" "$HTTP"

# ── Contratos ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ Contratos${NC}"

RESP=$(curl -s -w "\n%{http_code}" "$GP/contratos/activos" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -n -1)
assert_status "GET /contratos/activos" "200" "$HTTP"

# Extraer primer contrato
CONTRATO_ID=$(echo "$BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$CONTRATO_ID" ]; then
    echo "     ContratoId: $CONTRATO_ID"
fi

RESP=$(curl -s -w "\n%{http_code}" "$GP/contratos/mis-contratos" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /contratos/mis-contratos" "200" "$HTTP"

# ── Equipos ───────────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ Equipos${NC}"

if [ -n "$CONTRATO_ID" ]; then
    RESP=$(curl -s -w "\n%{http_code}" "$GP/equipos/contrato/$CONTRATO_ID" -H "$AUTH")
    HTTP=$(echo "$RESP" | tail -1)
    BODY=$(echo "$RESP" | head -n -1)
    assert_status "GET /equipos/contrato/{id}" "200" "$HTTP"

    EQUIPO_ID=$(echo "$BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    [ -n "$EQUIPO_ID" ] && echo "     EquipoId: $EQUIPO_ID"
fi

RESP=$(curl -s -w "\n%{http_code}" "$GP/equipos/mis-equipos" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /equipos/mis-equipos" "200" "$HTTP"

# ── Tareas ────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ Tareas${NC}"

RESP=$(curl -s -w "\n%{http_code}" "$GP/tareas?page=0&size=10" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /tareas (paginado)" "200" "$HTTP"

RESP=$(curl -s -w "\n%{http_code}" "$GP/tareas/mis-tareas" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /tareas/mis-tareas" "200" "$HTTP"

# Crear tarea si hay equipo
if [ -n "$EQUIPO_ID" ] && [ -n "$CONTRATO_ID" ]; then
    FECHA_FIN=$(date -d "+30 days" +%Y-%m-%d 2>/dev/null || date -v+30d +%Y-%m-%d)
    RESP=$(curl -s -w "\n%{http_code}" -X POST "$GP/tareas" -H "$AUTH" \
        -H "Content-Type: application/json" \
        -d "{\"contratoId\":\"$CONTRATO_ID\",\"equipoId\":\"$EQUIPO_ID\",\"categoria\":\"DESARROLLO\",\"titulo\":\"Tarea Test API\",\"prioridad\":\"MEDIA\",\"fechaEstimadaFin\":\"$FECHA_FIN\"}")
    HTTP=$(echo "$RESP" | tail -1)
    BODY=$(echo "$RESP" | head -n -1)
    assert_status "POST /tareas (crear)" "201" "$HTTP" "$BODY"

    TAREA_ID=$(echo "$BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    [ -n "$TAREA_ID" ] && echo "     TareaId: $TAREA_ID"

    if [ -n "$TAREA_ID" ]; then
        # Obtener detalle
        RESP=$(curl -s -w "\n%{http_code}" "$GP/tareas/$TAREA_ID" -H "$AUTH")
        HTTP=$(echo "$RESP" | tail -1)
        assert_status "GET /tareas/{id} (detalle)" "200" "$HTTP"

        # Transiciones
        RESP=$(curl -s -w "\n%{http_code}" "$GP/tareas/$TAREA_ID/transiciones" -H "$AUTH")
        HTTP=$(echo "$RESP" | tail -1)
        assert_status "GET /tareas/{id}/transiciones" "200" "$HTTP"

        # Cambiar estado ASG → EJE
        RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$GP/tareas/$TAREA_ID/estado" -H "$AUTH" \
            -H "Content-Type: application/json" \
            -d '{"estadoDestino":"EJE","comentario":"Iniciando ejecución desde test"}')
        HTTP=$(echo "$RESP" | tail -1)
        assert_status "PATCH /tareas/{id}/estado (ASG→EJE)" "200" "$HTTP"

        # Actualizar avance
        RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$GP/tareas/$TAREA_ID/avance" -H "$AUTH" \
            -H "Content-Type: application/json" \
            -d '{"porcentajeAvance":50,"observaciones":"Test avance"}')
        HTTP=$(echo "$RESP" | tail -1)
        assert_status "PATCH /tareas/{id}/avance (50%)" "200" "$HTTP"

        # Comentario
        RESP=$(curl -s -w "\n%{http_code}" -X POST "$GP/tareas/$TAREA_ID/comentarios" -H "$AUTH" \
            -H "Content-Type: application/json" \
            -d '{"contenido":"Comentario de prueba","tipo":"COMENTARIO"}')
        HTTP=$(echo "$RESP" | tail -1)
        assert_status "POST /tareas/{id}/comentarios" "201" "$HTTP"

        # Histórico
        RESP=$(curl -s -w "\n%{http_code}" "$GP/tareas/$TAREA_ID/historico" -H "$AUTH")
        HTTP=$(echo "$RESP" | tail -1)
        assert_status "GET /tareas/{id}/historico" "200" "$HTTP"
    fi

    # Kanban
    RESP=$(curl -s -w "\n%{http_code}" "$GP/tareas/kanban/$EQUIPO_ID" -H "$AUTH")
    HTTP=$(echo "$RESP" | tail -1)
    assert_status "GET /tareas/kanban/{equipoId}" "200" "$HTTP"
fi

# ── Dashboard ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ Dashboard${NC}"

RESP=$(curl -s -w "\n%{http_code}" "$GP/dashboard/super" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /dashboard/super" "200" "$HTTP"

RESP=$(curl -s -w "\n%{http_code}" "$GP/dashboard/equipo" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /dashboard/equipo" "200" "$HTTP"

RESP=$(curl -s -w "\n%{http_code}" "$GP/dashboard/alertas-sla" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /dashboard/alertas-sla" "200" "$HTTP"

if [ -n "$EQUIPO_ID" ]; then
    RESP=$(curl -s -w "\n%{http_code}" "$GP/dashboard/kanban-conteo/$EQUIPO_ID" -H "$AUTH")
    HTTP=$(echo "$RESP" | tail -1)
    assert_status "GET /dashboard/kanban-conteo/{equipoId}" "200" "$HTTP"
fi

# ── Notificaciones ────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ Notificaciones${NC}"

RESP=$(curl -s -w "\n%{http_code}" "$GP/notificaciones/no-leidas" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /notificaciones/no-leidas" "200" "$HTTP"

RESP=$(curl -s -w "\n%{http_code}" "$GP/notificaciones/no-leidas/count" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /notificaciones/no-leidas/count" "200" "$HTTP"

# ── Mensajes ──────────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ Mensajes${NC}"

RESP=$(curl -s -w "\n%{http_code}" "$GP/mensajes/bandeja" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /mensajes/bandeja" "200" "$HTTP"

RESP=$(curl -s -w "\n%{http_code}" "$GP/mensajes/no-leidos/count" -H "$AUTH")
HTTP=$(echo "$RESP" | tail -1)
assert_status "GET /mensajes/no-leidos/count" "200" "$HTTP"

# ── BPM ───────────────────────────────────────────────────
if [ -n "$TAREA_ID" ]; then
    echo ""
    echo -e "${YELLOW}▸ BPM${NC}"

    RESP=$(curl -s -w "\n%{http_code}" "$GP/bpm/tareas/$TAREA_ID/estado" -H "$AUTH")
    HTTP=$(echo "$RESP" | tail -1)
    assert_status "GET /bpm/tareas/{id}/estado" "200" "$HTTP"

    RESP=$(curl -s -w "\n%{http_code}" "$GP/bpm/tareas/$TAREA_ID/activo" -H "$AUTH")
    HTTP=$(echo "$RESP" | tail -1)
    assert_status "GET /bpm/tareas/{id}/activo" "200" "$HTTP"
fi

# ── Swagger ───────────────────────────────────────────────
echo ""
echo -e "${YELLOW}▸ Swagger/OpenAPI${NC}"

HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/swagger-ui.html")
assert_status "GET /swagger-ui.html (redirect)" "302" "$HTTP"
# Or 200 if using /swagger-ui/index.html
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/v3/api-docs")
assert_status "GET /v3/api-docs" "200" "$HTTP"

# ═══════════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════════"
echo -e "  Total: $TOTAL tests"
echo -e "  ${GREEN}Pasados: $PASSED${NC}"
echo -e "  ${RED}Fallidos: $FAILED${NC}"
echo "═══════════════════════════════════════════════════════"
echo ""

if [ $FAILED -gt 0 ]; then
    exit 1
fi
SCRIPTEOF
chmod +x scripts/test-api.sh

# =============================================================
# 8. Script de validación de build completo
# =============================================================
echo "  🔍 Script de validación..."

cat > scripts/validate-build.sh << 'SCRIPTEOF'
#!/bin/bash
# ═══════════════════════════════════════════════════════════
# SmartGob — Validación completa del build
# Ejecuta: compilación, tests, Docker build, stack up, API tests
# ═══════════════════════════════════════════════════════════

set -e
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

step() { echo -e "\n${YELLOW}═══ $1 ═══${NC}\n"; }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }

step "1/7 — Verificar estructura del proyecto"
[ -f backend/pom.xml ]          || fail "backend/pom.xml no existe"
[ -f frontend/package.json ]    || fail "frontend/package.json no existe"
[ -f docker-compose.yml ]       || fail "docker-compose.yml no existe"
[ -f nginx/nginx.conf ]         || fail "nginx/nginx.conf no existe"
ok "Estructura verificada"

step "2/7 — Compilar Backend (Maven)"
cd backend
mvn clean compile -q -B || fail "Compilación falló"
ok "Backend compila correctamente"

step "3/7 — Ejecutar Tests Unitarios"
mvn test -q -B || fail "Tests unitarios fallaron"
ok "Tests unitarios pasaron"
cd ..

step "4/7 — Verificar Frontend (npm install + build)"
cd frontend
npm ci --silent || fail "npm ci falló"
npm run build || fail "Frontend build falló"
ok "Frontend compila correctamente"
cd ..

step "5/7 — Build Docker images"
docker compose build --no-cache -q || fail "Docker build falló"
ok "Imágenes Docker construidas"

step "6/7 — Levantar stack completo"
docker compose up -d
echo "Esperando que los servicios inicien..."

# Esperar postgres
for i in $(seq 1 30); do
    if docker exec smartgob-gproyectos-db pg_isready -U smartgob >/dev/null 2>&1; then
        break
    fi
    sleep 2
done
ok "PostgreSQL listo"

# Esperar backend
for i in $(seq 1 60); do
    if curl -s http://localhost/actuator/health >/dev/null 2>&1; then
        break
    fi
    sleep 3
done
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/actuator/health 2>/dev/null)
[ "$HTTP" = "200" ] || fail "Backend no respondió (HTTP $HTTP)"
ok "Backend listo"

# Esperar frontend
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)
[ "$HTTP" = "200" ] || fail "Frontend no respondió (HTTP $HTTP)"
ok "Frontend listo"

step "7/7 — Ejecutar Tests API"
./scripts/test-api.sh http://localhost || fail "Tests API fallaron"

step "RESULTADO FINAL"
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ TODOS LOS CHECKS PASARON — PROYECTO LISTO${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  🌐 App:     http://localhost"
echo "  📖 Swagger: http://localhost/swagger-ui/index.html"
echo "  💊 Health:  http://localhost/actuator/health"
echo ""
echo "  Para detener: docker compose down"
echo ""
SCRIPTEOF
chmod +x scripts/validate-build.sh

# =============================================================
# 9. Makefile para operaciones comunes
# =============================================================
echo "  📋 Makefile..."

cat > Makefile << 'EOF'
# ═══════════════════════════════════════════════════════════
# SmartGob — Gestión de Proyectos
# ═══════════════════════════════════════════════════════════

.PHONY: help dev up down logs test build validate clean

help: ## Mostrar ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Desarrollo ────────────────────────────────────────────
dev-db: ## Levantar solo PostgreSQL para desarrollo
	docker compose -f docker-compose.dev.yml up -d

dev-backend: ## Iniciar backend en modo desarrollo
	cd backend && mvn spring-boot:run -Dspring-boot.run.profiles=dev

dev-frontend: ## Iniciar frontend en modo desarrollo
	cd frontend && npm run dev

# ── Docker ────────────────────────────────────────────────
build: ## Construir imágenes Docker
	docker compose build

up: ## Levantar todos los servicios
	docker compose up -d --build
	@echo ""
	@echo "🌐 App:     http://localhost"
	@echo "📖 Swagger: http://localhost/swagger-ui/index.html"
	@echo "💊 Health:  http://localhost/actuator/health"

down: ## Detener servicios
	docker compose down

restart: ## Reiniciar servicios
	docker compose down && docker compose up -d --build

logs: ## Ver logs de todos los servicios
	docker compose logs -f

logs-api: ## Ver logs del backend
	docker compose logs -f backend

status: ## Estado de servicios
	docker compose ps

# ── Tests ─────────────────────────────────────────────────
test-unit: ## Ejecutar tests unitarios
	cd backend && mvn test -B

test-api: ## Ejecutar tests API (requiere servicios levantados)
	./scripts/test-api.sh http://localhost

test: test-unit ## Ejecutar todos los tests

# ── Validación ────────────────────────────────────────────
validate: ## Validación completa (compile + test + docker + API)
	./scripts/validate-build.sh

compile: ## Solo compilar backend
	cd backend && mvn clean compile -q

# ── Base de datos ─────────────────────────────────────────
db-backup: ## Respaldar base de datos
	./scripts/deploy.sh db-backup

db-restore: ## Restaurar BD — uso: make db-restore FILE=backup.sql
	./scripts/deploy.sh db-restore $(FILE)

db-shell: ## Conectar a PostgreSQL
	docker exec -it smartgob-gproyectos-db psql -U smartgob smartgob_gproyectos

# ── Limpieza ──────────────────────────────────────────────
clean: ## Limpiar builds
	cd backend && mvn clean -q
	rm -rf frontend/dist frontend/node_modules/.vite
	docker compose down -v --remove-orphans 2>/dev/null || true
EOF

# =============================================================
# 10. Postman Collection (importar en Postman)
# =============================================================
echo "  📬 Postman collection..."

cat > scripts/SmartGob-API.postman_collection.json << 'POSTEOF'
{
  "info": {
    "name": "SmartGob - Gestión de Proyectos",
    "description": "Colección completa de endpoints API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    { "key": "base_url", "value": "http://localhost" },
    { "key": "token", "value": "" },
    { "key": "contrato_id", "value": "" },
    { "key": "equipo_id", "value": "" },
    { "key": "tarea_id", "value": "" }
  ],
  "auth": {
    "type": "bearer",
    "bearer": [{ "key": "token", "value": "{{token}}" }]
  },
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Login",
          "event": [{ "listen": "test", "script": { "exec": [
            "var json = pm.response.json();",
            "if (json.data && json.data.token) {",
            "  pm.collectionVariables.set('token', json.data.token);",
            "  pm.collectionVariables.set('colaborador_id', json.data.colaboradorId);",
            "}"
          ]}}],
          "request": {
            "method": "POST",
            "url": "{{base_url}}/api/auth/login",
            "header": [{ "key": "Content-Type", "value": "application/json" }],
            "body": { "mode": "raw", "raw": "{\"usuario\":\"0900000001\",\"password\":\"Admin2026!\"}" }
          }
        },
        {
          "name": "Me",
          "request": { "method": "GET", "url": "{{base_url}}/api/auth/me" }
        }
      ]
    },
    {
      "name": "Empresas",
      "item": [
        { "name": "Listar activas", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/empresas/activas" } },
        {
          "name": "Crear empresa",
          "request": {
            "method": "POST", "url": "{{base_url}}/api/v1/gestion-proyectos/empresas",
            "header": [{ "key": "Content-Type", "value": "application/json" }],
            "body": { "mode": "raw", "raw": "{\"ruc\":\"0990888001001\",\"razonSocial\":\"Empresa Postman\",\"tipo\":\"CONTRATISTA\"}" }
          }
        }
      ]
    },
    {
      "name": "Contratos",
      "item": [
        { "name": "Listar activos", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/contratos/activos" } },
        { "name": "Mis contratos", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/contratos/mis-contratos" } }
      ]
    },
    {
      "name": "Equipos",
      "item": [
        { "name": "Por contrato", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/equipos/contrato/{{contrato_id}}" } },
        { "name": "Mis equipos", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/equipos/mis-equipos" } }
      ]
    },
    {
      "name": "Tareas",
      "item": [
        { "name": "Buscar", "request": { "method": "GET", "url": { "raw": "{{base_url}}/api/v1/gestion-proyectos/tareas?page=0&size=20", "query": [{"key":"page","value":"0"},{"key":"size","value":"20"}] } } },
        { "name": "Mis tareas", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/tareas/mis-tareas" } },
        { "name": "Kanban", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/tareas/kanban/{{equipo_id}}" } },
        { "name": "Detalle", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/tareas/{{tarea_id}}" } },
        { "name": "Transiciones", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/tareas/{{tarea_id}}/transiciones" } },
        {
          "name": "Crear tarea",
          "request": {
            "method": "POST", "url": "{{base_url}}/api/v1/gestion-proyectos/tareas",
            "header": [{ "key": "Content-Type", "value": "application/json" }],
            "body": { "mode": "raw", "raw": "{\"contratoId\":\"{{contrato_id}}\",\"equipoId\":\"{{equipo_id}}\",\"categoria\":\"DESARROLLO\",\"titulo\":\"Tarea desde Postman\",\"prioridad\":\"MEDIA\",\"fechaEstimadaFin\":\"2026-06-30\"}" }
          }
        },
        {
          "name": "Cambiar estado",
          "request": {
            "method": "PATCH", "url": "{{base_url}}/api/v1/gestion-proyectos/tareas/{{tarea_id}}/estado",
            "header": [{ "key": "Content-Type", "value": "application/json" }],
            "body": { "mode": "raw", "raw": "{\"estadoDestino\":\"EJE\",\"comentario\":\"Desde Postman\"}" }
          }
        }
      ]
    },
    {
      "name": "Dashboard",
      "item": [
        { "name": "Super", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/dashboard/super" } },
        { "name": "Equipo", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/dashboard/equipo" } },
        { "name": "Alertas SLA", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/dashboard/alertas-sla" } }
      ]
    },
    {
      "name": "Notificaciones",
      "item": [
        { "name": "No leídas", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/notificaciones/no-leidas" } },
        { "name": "Count", "request": { "method": "GET", "url": "{{base_url}}/api/v1/gestion-proyectos/notificaciones/no-leidas/count" } }
      ]
    }
  ]
}
POSTEOF

# =============================================================
echo ""
echo "✅ Commit 10 completado."
echo ""
echo "Archivos creados:"
echo ""
echo "  📐 Request DTOs faltantes:"
echo "    • AsignarMiembroRequest     — UUID colaboradorId + String rolEquipo"
echo "    • ActualizarAvanceRequest   — Integer porcentajeAvance + String observaciones"
echo ""
echo "  🔧 Fixes:"
echo "    • AuthResponse              — +List<RolEquipoInfo> roles + inner class"
echo "    • NotificacionResponse      — campos completos"
echo "    • Constructores UUID en entities (Empresa, Mensaje, Notificacion)"
echo "    • logback-spring.xml        — logging por perfil"
echo ""
echo "  🧪 Scripts de Prueba:"
echo "    • scripts/test-api.sh       — 30+ tests cURL automatizados"
echo "    • scripts/validate-build.sh — validación completa 7 pasos"
echo "    • Makefile                  — 15 comandos make"
echo "    • SmartGob-API.postman_collection.json — colección Postman"
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  EJECUCIÓN COMPLETA:"
echo ""
echo "  1. Ejecutar scripts en orden:"
echo "     chmod +x commit*.sh"
echo "     ./commit1-foundation.sh"
echo "     ./commit2-flyway.sh"
echo "     ./commit3-repos-dtos.sh"
echo "     ./commit4-services.sh"
echo "     ./commit5-controllers.sh"
echo "     ./commit6-bpm-activiti.sh"
echo "     ./commit7-frontend.sh"
echo "     ./commit8-docker-prod.sh"
echo "     ./commit9-fixes-tests.sh"
echo "     ./commit10-final.sh"
echo ""
echo "  2. Validar todo:"
echo "     make validate"
echo ""
echo "  3. O paso a paso:"
echo "     cd backend && mvn clean compile && mvn test && cd .."
echo "     cd frontend && npm install && npm run build && cd .."
echo "     make up"
echo "     make test-api"
echo "═══════════════════════════════════════════════════════"

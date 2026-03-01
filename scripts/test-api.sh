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

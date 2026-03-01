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

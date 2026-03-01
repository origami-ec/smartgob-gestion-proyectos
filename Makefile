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

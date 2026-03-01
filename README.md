# SmartGob — Gestión de Proyectos

Sistema integral de gestión de proyectos para gobiernos municipales del Ecuador.

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| **Backend** | Spring Boot 3.4.3, Java 21, JPA/Hibernate, Flyway, Activiti BPM 6, MapStruct |
| **Frontend** | React 19, TypeScript, Vite, Tailwind CSS, Zustand, Recharts |
| **Base de datos** | PostgreSQL 16 |
| **Infraestructura** | Docker, nginx reverse proxy |

## Inicio Rápido

### Producción (Docker)

```bash
# Clonar y configurar
cp .env.example .env
# Editar .env con valores de producción

# Desplegar
./scripts/deploy.sh up

# Acceder: http://localhost
```

### Desarrollo Local

```bash
# 1. Levantar PostgreSQL
./scripts/init-dev.sh

# 2. Backend (terminal 1)
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 3. Frontend (terminal 2)
cd frontend
npm run dev

# Acceder: http://localhost:3000
```

## Arquitectura

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   nginx:80  │────▶│ frontend:80  │     │ postgres:5432│
│  (proxy)    │     │  (React SPA) │     │  (PostgreSQL)│
│             │────▶│ backend:8081 │────▶│              │
└─────────────┘     │ (Spring Boot)│     └──────────────┘
                    └──────────────┘
```

## Módulos

- **Gestión de Contratos**: registro, plazos, administradores
- **Equipos de Trabajo**: asignación de miembros con roles (LDR, ADM, DEV, TST, DOC)
- **Tareas con Flujo BPM**: ASG → EJE → TER/TERT → REV → FIN
- **Tablero Kanban**: vista drag-and-drop por equipo
- **Dashboard**: KPIs, gráficos, alertas SLA
- **Notificaciones**: automáticas por cambios de estado
- **Mensajería**: directa, por equipo, por contrato

## Scripts

| Comando | Descripción |
|---------|-------------|
| `./scripts/deploy.sh up` | Levantar todos los servicios |
| `./scripts/deploy.sh down` | Detener servicios |
| `./scripts/deploy.sh logs [servicio]` | Ver logs |
| `./scripts/deploy.sh status` | Estado y recursos |
| `./scripts/deploy.sh db-backup` | Respaldo de BD |
| `./scripts/deploy.sh db-restore <file>` | Restaurar BD |

## API Endpoints

Base: `/api/v1/gestion-proyectos`

| Recurso | Endpoints |
|---------|-----------|
| Auth | `POST /api/auth/login`, `GET /api/auth/me` |
| Empresas | CRUD `/empresas` |
| Colaboradores | CRUD `/colaboradores` |
| Contratos | CRUD `/contratos` |
| Equipos | CRUD `/equipos`, `POST /{id}/miembros` |
| Tareas | CRUD `/tareas`, `/kanban/{equipoId}`, `/mis-tareas` |
| Dashboard | `/dashboard/super`, `/dashboard/equipo`, `/dashboard/alertas-sla` |
| Notificaciones | `/notificaciones`, `/notificaciones/no-leidas` |
| BPM | `/bpm/tareas/{id}/estado`, `/bpm/tareas/{id}/claim` |

## Licencia

Propiedad de TECH2GO S.A. — Todos los derechos reservados.

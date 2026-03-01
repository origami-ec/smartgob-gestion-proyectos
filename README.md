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

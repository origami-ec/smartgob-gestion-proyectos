#!/bin/bash
# ============================================================
# COMMIT 8: Docker producción — nginx reverse proxy, perfiles,
#           .env, scripts de despliegue
# Ejecutar desde la raíz del proyecto: smartgob-gestion-proyectos/
#
# Después:
#   git add .
#   git commit -m "feat: Docker producción - nginx proxy, perfiles, scripts deploy"
#   git push
# ============================================================

set -e
echo "📦 Commit 8: Docker producción"

# =============================================================
# 1. .env.example
# =============================================================
echo "  📋 .env.example..."

cat > .env.example << 'EOF'
# ══════════════════════════════════════════════════════════════
# SmartGob — Gestión de Proyectos  |  Variables de entorno
# Copiar a .env y ajustar valores para cada ambiente
# ══════════════════════════════════════════════════════════════

# ── Base de datos ─────────────────────────────────────────
DB_HOST=postgres
DB_PORT=5432
DB_NAME=smartgob_gproyectos
DB_USER=smartgob
DB_PASSWORD=SmartG0b2026!

# ── Backend API ───────────────────────────────────────────
API_PORT=8081
SPRING_PROFILES_ACTIVE=prod
APP_TIMEZONE=America/Guayaquil

# ── JWT ───────────────────────────────────────────────────
JWT_SECRET=cH4nG3tH1sS3cr3tK3y!SmartGob2026MustBe256BitsLong!!
JWT_EXPIRATION=900000
JWT_REFRESH_EXPIRATION=86400000

# ── CORS ──────────────────────────────────────────────────
CORS_ORIGINS=http://localhost:3000,http://localhost

# ── Frontend ──────────────────────────────────────────────
UI_PORT=3000
VITE_API_URL=http://localhost/api

# ── nginx ─────────────────────────────────────────────────
NGINX_PORT=80
NGINX_SSL_PORT=443

# ── SLA ───────────────────────────────────────────────────
SLA_DIAS_ALERTA=3
SLA_HORAS_REVISION=48
NOTIFICACIONES_DIAS_RETENER=30

# ── Uploads ───────────────────────────────────────────────
UPLOADS_PATH=/app/uploads
UPLOADS_MAX_SIZE_MB=10
EOF

cat > .env << 'EOF'
DB_HOST=postgres
DB_PORT=5432
DB_NAME=smartgob_gproyectos
DB_USER=smartgob
DB_PASSWORD=SmartG0b2026!
API_PORT=8081
SPRING_PROFILES_ACTIVE=prod
APP_TIMEZONE=America/Guayaquil
JWT_SECRET=cH4nG3tH1sS3cr3tK3y!SmartGob2026MustBe256BitsLong!!
JWT_EXPIRATION=900000
JWT_REFRESH_EXPIRATION=86400000
CORS_ORIGINS=http://localhost:3000,http://localhost
UI_PORT=3000
NGINX_PORT=80
SLA_DIAS_ALERTA=3
SLA_HORAS_REVISION=48
NOTIFICACIONES_DIAS_RETENER=30
UPLOADS_PATH=/app/uploads
UPLOADS_MAX_SIZE_MB=10
EOF

# =============================================================
# 2. .dockerignore files
# =============================================================
echo "  🚫 .dockerignore..."

cat > backend/.dockerignore << 'EOF'
target/
.idea/
*.iml
.git/
.env
logs/
uploads/
EOF

cat > frontend/.dockerignore << 'EOF'
node_modules/
dist/
.git/
.env*
EOF

# =============================================================
# 3. NGINX config
# =============================================================
echo "  🌐 nginx configs..."

mkdir -p nginx/conf.d nginx/ssl

cat > nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript
               application/xml+rss application/atom+xml image/svg+xml;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    include /etc/nginx/conf.d/*.conf;
}
EOF

cat > nginx/conf.d/default.conf << 'EOF'
upstream backend_api {
    server backend:8081;
    keepalive 32;
}

server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # ── API proxy ──────────────────────────────────────────
    location /api/ {
        proxy_pass http://backend_api;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";

        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # CORS headers (backup, Spring ya maneja CORS)
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;

        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Authorization, Content-Type";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }

    # ── Actuator health (sin auth) ─────────────────────────
    location /actuator/ {
        proxy_pass http://backend_api;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    # ── WebSocket (futuro) ─────────────────────────────────
    location /ws/ {
        proxy_pass http://backend_api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # ── Static assets (cache largo) ────────────────────────
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # ── SPA fallback ───────────────────────────────────────
    location / {
        try_files $uri $uri/ /index.html;
    }

    # ── Health check endpoint ──────────────────────────────
    location = /health {
        access_log off;
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
EOF

# =============================================================
# 4. Dockerfiles mejorados
# =============================================================
echo "  🐳 Dockerfiles mejorados..."

cat > backend/Dockerfile << 'EOF'
# ═══════════════════════════════════════════════════════════
# SmartGob Gestión Proyectos — Backend
# Multi-stage: build con Maven → runtime JRE Alpine
# ═══════════════════════════════════════════════════════════
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app

# Cache de dependencias Maven
COPY pom.xml .
RUN apk add --no-cache maven \
    && mvn dependency:go-offline -B

# Build
COPY src src
RUN mvn package -DskipTests -B -q

# ── Runtime ────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring \
    && mkdir -p /app/uploads /app/logs \
    && chown -R spring:spring /app

COPY --from=build /app/target/*.jar app.jar

USER spring:spring

ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD wget -q --spider http://localhost:8081/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -jar app.jar"]
EOF

cat > frontend/Dockerfile << 'EOF'
# ═══════════════════════════════════════════════════════════
# SmartGob Gestión Proyectos — Frontend
# Multi-stage: build con Node → serve con nginx
# ═══════════════════════════════════════════════════════════
FROM node:22-alpine AS build
WORKDIR /app

# Cache de dependencias
COPY package.json package-lock.json* ./
RUN npm ci --silent

# Build
COPY . .
RUN npm run build

# ── Runtime ────────────────────────────────────────────────
FROM nginx:1.27-alpine

# Copiar build
COPY --from=build /app/dist /usr/share/nginx/html

# Config nginx para SPA
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx-spa.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget -q --spider http://localhost:80/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
EOF

cat > frontend/nginx-spa.conf << 'EOF'
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location = /health {
        access_log off;
        return 200 'OK';
        add_header Content-Type text/plain;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# =============================================================
# 5. docker-compose.yml mejorado con nginx
# =============================================================
echo "  📦 docker-compose.yml..."

cat > docker-compose.yml << 'EOF'
version: '3.9'

services:
  # ── PostgreSQL ──────────────────────────────────────────
  postgres:
    image: postgres:16-alpine
    container_name: smartgob-gproyectos-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME:-smartgob_gproyectos}
      POSTGRES_USER: ${DB_USER:-smartgob}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-SmartG0b2026!}
      TZ: ${APP_TIMEZONE:-America/Guayaquil}
    ports:
      - "${DB_PORT:-5432}:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-smartgob} -d ${DB_NAME:-smartgob_gproyectos}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - smartgob-net

  # ── Backend Spring Boot ─────────────────────────────────
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: smartgob-gproyectos-api
    restart: unless-stopped
    environment:
      SPRING_PROFILES_ACTIVE: ${SPRING_PROFILES_ACTIVE:-prod}
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ${DB_NAME:-smartgob_gproyectos}
      DB_USER: ${DB_USER:-smartgob}
      DB_PASSWORD: ${DB_PASSWORD:-SmartG0b2026!}
      JWT_SECRET: ${JWT_SECRET:-cH4nG3tH1sS3cr3tK3y!SmartGob2026MustBe256BitsLong!!}
      JWT_EXPIRATION: ${JWT_EXPIRATION:-900000}
      JWT_REFRESH_EXPIRATION: ${JWT_REFRESH_EXPIRATION:-86400000}
      APP_TIMEZONE: ${APP_TIMEZONE:-America/Guayaquil}
      CORS_ORIGINS: ${CORS_ORIGINS:-http://localhost:3000,http://localhost}
      SLA_DIAS_ALERTA: ${SLA_DIAS_ALERTA:-3}
      SLA_HORAS_REVISION: ${SLA_HORAS_REVISION:-48}
      NOTIFICACIONES_DIAS_RETENER: ${NOTIFICACIONES_DIAS_RETENER:-30}
      UPLOADS_PATH: ${UPLOADS_PATH:-/app/uploads}
      UPLOADS_MAX_SIZE_MB: ${UPLOADS_MAX_SIZE_MB:-10}
    volumes:
      - uploads:/app/uploads
      - backend-logs:/app/logs
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - smartgob-net

  # ── Frontend React (build estático) ─────────────────────
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: smartgob-gproyectos-ui
    restart: unless-stopped
    networks:
      - smartgob-net

  # ── Nginx Reverse Proxy ─────────────────────────────────
  nginx:
    image: nginx:1.27-alpine
    container_name: smartgob-gproyectos-proxy
    restart: unless-stopped
    ports:
      - "${NGINX_PORT:-80}:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - nginx-logs:/var/log/nginx
    depends_on:
      - backend
      - frontend
    networks:
      - smartgob-net
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  pgdata:
    name: smartgob-gproyectos-pgdata
  uploads:
    name: smartgob-gproyectos-uploads
  backend-logs:
    name: smartgob-gproyectos-logs
  nginx-logs:
    name: smartgob-gproyectos-nginx-logs

networks:
  smartgob-net:
    name: smartgob-gproyectos-network
    driver: bridge
EOF

# docker-compose para desarrollo local (sin nginx proxy)
cat > docker-compose.dev.yml << 'EOF'
version: '3.9'

services:
  postgres:
    image: postgres:16-alpine
    container_name: smartgob-gproyectos-db-dev
    environment:
      POSTGRES_DB: smartgob_gproyectos
      POSTGRES_USER: smartgob
      POSTGRES_PASSWORD: SmartG0b2026!
      TZ: America/Guayaquil
    ports:
      - "5432:5432"
    volumes:
      - pgdata-dev:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U smartgob"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pgdata-dev:
EOF

# =============================================================
# 6. Application profiles
# =============================================================
echo "  ⚙️  Application profiles..."

cat > backend/src/main/resources/application-prod.yml << 'EOF'
# ═══════════════════════════════════════════════════════════
# Perfil: PRODUCCIÓN
# ═══════════════════════════════════════════════════════════
server:
  port: 8081
  tomcat:
    max-threads: 200
    accept-count: 100

spring:
  datasource:
    hikari:
      maximum-pool-size: 30
      minimum-idle: 10
      connection-timeout: 20000
      idle-timeout: 300000
      max-lifetime: 600000
  jpa:
    show-sql: false
    properties:
      hibernate:
        generate_statistics: false
        format_sql: false

logging:
  level:
    root: WARN
    ec.smartgob: INFO
    org.springframework: WARN
    org.hibernate: WARN
    org.activiti: WARN
  file:
    name: /app/logs/smartgob-gproyectos.log
  logback:
    rollingpolicy:
      max-file-size: 50MB
      max-history: 30

app:
  uploads:
    path: ${UPLOADS_PATH:/app/uploads}
    max-size-mb: ${UPLOADS_MAX_SIZE_MB:10}
  sla:
    dias-alerta: ${SLA_DIAS_ALERTA:3}
    horas-revision: ${SLA_HORAS_REVISION:48}
  notificaciones:
    dias-retener: ${NOTIFICACIONES_DIAS_RETENER:30}
EOF

cat > backend/src/main/resources/application-dev.yml << 'EOF'
# ═══════════════════════════════════════════════════════════
# Perfil: DESARROLLO
# ═══════════════════════════════════════════════════════════
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/smartgob_gproyectos
    hikari:
      maximum-pool-size: 10
  jpa:
    show-sql: true
    properties:
      hibernate:
        format_sql: true

logging:
  level:
    root: INFO
    ec.smartgob: DEBUG
    org.springframework.web: DEBUG
    org.hibernate.SQL: DEBUG
    org.activiti: DEBUG

app:
  uploads:
    path: ./uploads
    max-size-mb: 10
  sla:
    dias-alerta: 3
    horas-revision: 48
  notificaciones:
    dias-retener: 30
EOF

# =============================================================
# 7. Scripts de despliegue
# =============================================================
echo "  🚀 Scripts de despliegue..."

mkdir -p scripts

cat > scripts/deploy.sh << 'SCRIPTEOF'
#!/bin/bash
# ═══════════════════════════════════════════════════════════
# SmartGob — Script de despliegue
# Uso: ./scripts/deploy.sh [build|up|down|logs|restart|status]
# ═══════════════════════════════════════════════════════════

set -e
COMPOSE="docker compose"
PROJECT="smartgob-gproyectos"

if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado"
    exit 1
fi

case "${1:-up}" in
    build)
        echo "🔨 Construyendo imágenes..."
        $COMPOSE build --no-cache
        echo "✅ Build completado"
        ;;
    up)
        echo "🚀 Iniciando servicios..."
        $COMPOSE up -d --build
        echo ""
        echo "✅ Servicios iniciados:"
        echo "   🌐 App:        http://localhost:${NGINX_PORT:-80}"
        echo "   🔌 API:        http://localhost:${NGINX_PORT:-80}/api"
        echo "   💊 Health:     http://localhost:${NGINX_PORT:-80}/actuator/health"
        echo "   🐘 PostgreSQL: localhost:${DB_PORT:-5432}"
        ;;
    down)
        echo "🛑 Deteniendo servicios..."
        $COMPOSE down
        echo "✅ Servicios detenidos"
        ;;
    restart)
        echo "🔄 Reiniciando..."
        $COMPOSE down
        $COMPOSE up -d --build
        echo "✅ Servicios reiniciados"
        ;;
    logs)
        $COMPOSE logs -f ${2:-}
        ;;
    status)
        echo "📊 Estado de servicios:"
        $COMPOSE ps
        echo ""
        echo "📊 Uso de recursos:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
            $(docker compose ps -q 2>/dev/null) 2>/dev/null || true
        ;;
    db-backup)
        BACKUP_FILE="backup_${PROJECT}_$(date +%Y%m%d_%H%M%S).sql"
        echo "💾 Respaldando base de datos → $BACKUP_FILE"
        docker exec smartgob-gproyectos-db pg_dump -U ${DB_USER:-smartgob} \
            ${DB_NAME:-smartgob_gproyectos} > "$BACKUP_FILE"
        echo "✅ Backup completado: $BACKUP_FILE"
        ;;
    db-restore)
        if [ -z "$2" ]; then echo "Uso: $0 db-restore <archivo.sql>"; exit 1; fi
        echo "📥 Restaurando desde $2..."
        cat "$2" | docker exec -i smartgob-gproyectos-db psql -U ${DB_USER:-smartgob} \
            ${DB_NAME:-smartgob_gproyectos}
        echo "✅ Restauración completada"
        ;;
    *)
        echo "Uso: $0 {build|up|down|restart|logs|status|db-backup|db-restore}"
        exit 1
        ;;
esac
SCRIPTEOF
chmod +x scripts/deploy.sh

cat > scripts/init-dev.sh << 'SCRIPTEOF'
#!/bin/bash
# ═══════════════════════════════════════════════════════════
# SmartGob — Inicializar entorno de desarrollo
# ═══════════════════════════════════════════════════════════

set -e
echo "🛠️  Inicializando entorno de desarrollo SmartGob..."

# 1. Levantar solo PostgreSQL
echo "🐘 Levantando PostgreSQL..."
docker compose -f docker-compose.dev.yml up -d
sleep 3

# 2. Verificar conexión
echo "🔍 Verificando conexión..."
until docker exec smartgob-gproyectos-db-dev pg_isready -U smartgob 2>/dev/null; do
    echo "   Esperando PostgreSQL..."
    sleep 2
done
echo "✅ PostgreSQL listo"

# 3. Instalar dependencias frontend
if [ -d "frontend" ]; then
    echo "📦 Instalando dependencias frontend..."
    cd frontend && npm install && cd ..
fi

echo ""
echo "✅ Entorno listo. Para iniciar:"
echo "   Backend:  cd backend && mvn spring-boot:run -Dspring-boot.run.profiles=dev"
echo "   Frontend: cd frontend && npm run dev"
echo "   DB:       localhost:5432 / smartgob / SmartG0b2026!"
SCRIPTEOF
chmod +x scripts/init-dev.sh

# =============================================================
# 8. .gitignore actualizado
# =============================================================
echo "  📝 .gitignore..."

cat > .gitignore << 'EOF'
# ── IDE ───────────────────────────────────────────────────
.idea/
*.iml
.vscode/
*.swp
*.swo
.DS_Store

# ── Java / Maven ──────────────────────────────────────────
backend/target/
*.class
*.jar
*.war

# ── Node ──────────────────────────────────────────────────
frontend/node_modules/
frontend/dist/
frontend/.vite/

# ── Environment ───────────────────────────────────────────
.env
.env.local
.env.production

# ── Docker ────────────────────────────────────────────────
docker-compose.override.yml

# ── Uploads / Logs ────────────────────────────────────────
uploads/
logs/
*.log

# ── Backups ───────────────────────────────────────────────
backup_*.sql
*.dump

# ── SSL certs ─────────────────────────────────────────────
nginx/ssl/*.pem
nginx/ssl/*.key
nginx/ssl/*.crt
EOF

# =============================================================
# 9. README.md
# =============================================================
echo "  📖 README.md..."

cat > README.md << 'READMEEOF'
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
READMEEOF

# =============================================================
# 10. Actualizar nginx default.conf para copiar static del frontend
# =============================================================
echo "  📋 Actualizando nginx para servir frontend build..."

cat > nginx/conf.d/default.conf << 'EOF'
upstream backend_api {
    server backend:8081;
    keepalive 32;
}

upstream frontend_spa {
    server frontend:80;
}

server {
    listen 80;
    server_name _;

    # ── API proxy ──────────────────────────────────────────
    location /api/ {
        proxy_pass http://backend_api;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_connect_timeout 30s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # ── Actuator ───────────────────────────────────────────
    location /actuator/ {
        proxy_pass http://backend_api;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    # ── WebSocket ──────────────────────────────────────────
    location /ws/ {
        proxy_pass http://backend_api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # ── Frontend SPA (proxy al container frontend) ─────────
    location / {
        proxy_pass http://frontend_spa;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # ── Health check ───────────────────────────────────────
    location = /health {
        access_log off;
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
EOF

# =============================================================
echo ""
echo "✅ Commit 8 completado."
echo ""
echo "Archivos creados/actualizados:"
echo ""
echo "  📋 Configuración:"
echo "    • .env.example          — plantilla de variables"
echo "    • .env                  — valores por defecto"
echo "    • .gitignore            — completo"
echo "    • README.md             — documentación del proyecto"
echo ""
echo "  🐳 Docker:"
echo "    • backend/Dockerfile    — multi-stage, healthcheck, JVM tuning"
echo "    • frontend/Dockerfile   — multi-stage, nginx SPA"
echo "    • frontend/nginx-spa.conf"
echo "    • backend/.dockerignore"
echo "    • frontend/.dockerignore"
echo ""
echo "  📦 Docker Compose:"
echo "    • docker-compose.yml       — prod: postgres + backend + frontend + nginx"
echo "    • docker-compose.dev.yml   — dev: solo postgres"
echo ""
echo "  🌐 Nginx:"
echo "    • nginx/nginx.conf          — config principal (gzip, security headers)"
echo "    • nginx/conf.d/default.conf — reverse proxy: /api → backend, / → frontend"
echo ""
echo "  ⚙️  Spring Profiles:"
echo "    • application-prod.yml  — pool 30, logs file, SLA config"
echo "    • application-dev.yml   — SQL debug, pool 10"
echo ""
echo "  🚀 Scripts:"
echo "    • scripts/deploy.sh     — up/down/logs/status/db-backup/db-restore"
echo "    • scripts/init-dev.sh   — setup entorno desarrollo"
echo ""
echo "Siguiente paso:"
echo "  git add ."
echo "  git commit -m \"feat: Docker producción - nginx proxy, perfiles, scripts deploy\""
echo "  git push"

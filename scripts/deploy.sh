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

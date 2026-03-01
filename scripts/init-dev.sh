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

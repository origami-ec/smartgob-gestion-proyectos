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

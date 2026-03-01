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

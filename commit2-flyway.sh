#!/bin/bash
# ============================================================
# COMMIT 2: Migraciones Flyway — DDL completo PostgreSQL
# Ejecutar desde la raíz del proyecto: smartgob-gestion-proyectos/
#
# Después:
#   git add .
#   git commit -m "feat: migraciones Flyway - DDL completo, parametrización, vistas, triggers"
#   git push
# ============================================================

set -e
MIGRATIONS="backend/src/main/resources/db/migration"
echo "📝 Generando migraciones Flyway..."

# =============================================================
# V1 — SCHEMA + EXTENSIONES + PARAMETRIZACIÓN
# =============================================================

cat > $MIGRATIONS/V1__schema_and_params.sql << 'SQLEOF'
-- ============================================================
-- V1: Schema, extensiones y tablas de parametrización
-- SmartGob - Gestión de Proyectos
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE SCHEMA IF NOT EXISTS gestion_proyectos;
SET search_path TO gestion_proyectos;

-- ============================================================
-- PARAMETRIZACIÓN: ESTADOS DE TAREA
-- ============================================================
CREATE TABLE param_estado_tarea (
    codigo          VARCHAR(5) PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    descripcion     VARCHAR(200),
    color_hex       VARCHAR(7) NOT NULL DEFAULT '#6B7280',
    color_bg_hex    VARCHAR(7) NOT NULL DEFAULT '#F3F4F6',
    orden           SMALLINT NOT NULL DEFAULT 0,
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO param_estado_tarea (codigo, nombre, color_hex, color_bg_hex, orden) VALUES
    ('ASG',  'Asignado',               '#3B82F6', '#DBEAFE', 1),
    ('EJE',  'Ejecutando',             '#F59E0B', '#FEF3C7', 2),
    ('SUS',  'Suspendido',             '#6B7280', '#F3F4F6', 3),
    ('TER',  'Terminada',              '#10B981', '#D1FAE5', 4),
    ('TERT', 'Terminada fuera plazo',  '#EF4444', '#FEE2E2', 5),
    ('REV',  'En Revisión',            '#8B5CF6', '#EDE9FE', 6),
    ('FIN',  'Finalizada',             '#059669', '#ECFDF5', 7);

-- ============================================================
-- PARAMETRIZACIÓN: ROLES DE EQUIPO
-- ============================================================
CREATE TABLE param_rol_equipo (
    codigo          VARCHAR(5) PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    descripcion     VARCHAR(200),
    permisos_json   JSONB,
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO param_rol_equipo (codigo, nombre, descripcion, permisos_json) VALUES
    ('LDR', 'Líder',         'Líder técnico del equipo',
        '{"crear_tarea":true,"asignar_tarea":true,"suspender_tarea":true,"ver_dashboard":true}'),
    ('ADM', 'Administrador', 'Administrador del equipo',
        '{"crear_tarea":true,"asignar_tarea":true,"suspender_tarea":true,"ver_dashboard":true}'),
    ('DEV', 'Desarrollador', 'Desarrollador de software',
        '{"crear_tarea":false,"asignar_tarea":false,"suspender_tarea":false,"ver_dashboard":false}'),
    ('TST', 'Tester',        'Responsable de pruebas y revisión',
        '{"crear_tarea":false,"asignar_tarea":false,"suspender_tarea":false,"revisar_tarea":true}'),
    ('DOC', 'Documentador',  'Responsable de documentación',
        '{"crear_tarea":false,"asignar_tarea":false,"suspender_tarea":false,"ver_dashboard":false}');

-- ============================================================
-- PARAMETRIZACIÓN: PRIORIDADES
-- ============================================================
CREATE TABLE param_prioridad (
    codigo          VARCHAR(10) PRIMARY KEY,
    nombre          VARCHAR(30) NOT NULL,
    color_hex       VARCHAR(7) NOT NULL,
    peso            SMALLINT NOT NULL DEFAULT 0,
    activo          BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO param_prioridad (codigo, nombre, color_hex, peso) VALUES
    ('CRITICA', 'Crítica', '#DC2626', 4),
    ('ALTA',    'Alta',    '#F97316', 3),
    ('MEDIA',   'Media',   '#EAB308', 2),
    ('BAJA',    'Baja',    '#6B7280', 1);

-- ============================================================
-- PARAMETRIZACIÓN: CATEGORÍAS DE TAREA
-- ============================================================
CREATE TABLE param_categoria_tarea (
    codigo          VARCHAR(20) PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    icono           VARCHAR(50),
    activo          BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO param_categoria_tarea (codigo, nombre, icono) VALUES
    ('DESARROLLO',    'Desarrollo',     'code'),
    ('DISENO',        'Diseño',         'palette'),
    ('DOCUMENTACION', 'Documentación',  'file-text'),
    ('PRUEBAS',       'Pruebas',        'check-circle');

-- ============================================================
-- PARAMETRIZACIÓN: SLA
-- ============================================================
CREATE TABLE param_sla (
    id              SERIAL PRIMARY KEY,
    codigo          VARCHAR(30) UNIQUE NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    horas           INTEGER NOT NULL,
    descripcion     VARCHAR(300),
    activo          BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO param_sla (codigo, nombre, horas, descripcion) VALUES
    ('VENCIMIENTO_TAREA', 'Alerta pre-vencimiento de tarea', 72,
        'Notificar cuando falten 72 horas para que venza la fecha estimada de finalización'),
    ('REVISION_TESTER',   'Plazo máximo revisión Tester',    72,
        'El Tester tiene máximo 72 horas para revisar una tarea desde que la recibe');

-- ============================================================
-- PARAMETRIZACIÓN: ALERTAS VISUALES
-- ============================================================
CREATE TABLE param_alerta_visual (
    id              SERIAL PRIMARY KEY,
    condicion       VARCHAR(100) NOT NULL,
    color_hex       VARCHAR(7) NOT NULL,
    color_bg_hex    VARCHAR(7) NOT NULL,
    icono           VARCHAR(50),
    mensaje         VARCHAR(200),
    activo          BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO param_alerta_visual (condicion, color_hex, color_bg_hex, icono, mensaje) VALUES
    ('VENCIMIENTO_72H',      '#F59E0B', '#FEF3C7', 'clock',       'A 72 horas de vencer'),
    ('VENCIDA_SIN_TERMINAR', '#DC2626', '#FEE2E2', 'alert-circle','Vencida sin terminar'),
    ('EN_REVISION',          '#8B5CF6', '#EDE9FE', 'eye',         'En revisión por Tester'),
    ('REVISION_VENCIDA',     '#DC2626', '#FEE2E2', 'alert-triangle','Revisión excedió 72h'),
    ('FINALIZADA',           '#059669', '#ECFDF5', 'check-circle','Tarea finalizada'),
    ('CONTRATO_30D',         '#F97316', '#FFEDD5', 'calendar',    'Contrato vence en < 30 días');

-- ============================================================
-- PARAMETRIZACIÓN: TRANSICIONES PERMITIDAS
-- ============================================================
CREATE TABLE param_transicion_estado (
    id              SERIAL PRIMARY KEY,
    estado_origen   VARCHAR(5) NOT NULL REFERENCES param_estado_tarea(codigo),
    estado_destino  VARCHAR(5) NOT NULL REFERENCES param_estado_tarea(codigo),
    roles_permitidos VARCHAR(50) NOT NULL,
    accion          VARCHAR(30) NOT NULL,
    descripcion     VARCHAR(200),
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(estado_origen, estado_destino)
);

INSERT INTO param_transicion_estado (estado_origen, estado_destino, roles_permitidos, accion, descripcion) VALUES
    ('ASG',  'EJE',  'DEV,DOC,LDR,ADM', 'INICIAR',    'Iniciar ejecución de tarea'),
    ('EJE',  'TER',  'DEV,DOC,LDR,ADM', 'TERMINAR',   'Marcar como terminada (dentro de plazo)'),
    ('EJE',  'TERT', 'DEV,DOC,LDR,ADM', 'TERMINAR',   'Marcar como terminada (fuera de plazo)'),
    ('EJE',  'SUS',  'LDR,ADM',         'SUSPENDER',   'Suspender tarea'),
    ('SUS',  'EJE',  'LDR,ADM',         'REACTIVAR',   'Reactivar tarea suspendida'),
    ('TER',  'REV',  'SYSTEM',           'REVISAR',     'Enviar automáticamente a revisión'),
    ('TERT', 'REV',  'SYSTEM',           'REVISAR',     'Enviar automáticamente a revisión'),
    ('REV',  'FIN',  'TST',              'APROBAR',     'Aprobar y finalizar tarea'),
    ('REV',  'ASG',  'TST',              'DEVOLVER',    'Devolver con observaciones'),
    ('REV',  'EJE',  'TST',              'DEVOLVER',    'Devolver a ejecución con observaciones');
SQLEOF

echo "  ✅ V1 - Schema y parametrización"

# =============================================================
# V2 — TABLAS DE NEGOCIO
# =============================================================

cat > $MIGRATIONS/V2__business_tables.sql << 'SQLEOF'
-- ============================================================
-- V2: Tablas de negocio
-- SmartGob - Gestión de Proyectos
-- ============================================================

SET search_path TO gestion_proyectos;

-- ============================================================
-- EMPRESA
-- ============================================================
CREATE TABLE empresa (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ruc             VARCHAR(20) UNIQUE NOT NULL,
    razon_social    VARCHAR(200) NOT NULL,
    tipo            VARCHAR(20) NOT NULL DEFAULT 'PRIVADA',
    estado          VARCHAR(10) NOT NULL DEFAULT 'ACTIVO',
    deleted         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      VARCHAR(50),
    updated_by      VARCHAR(50)
);

-- ============================================================
-- COLABORADOR
-- ============================================================
CREATE TABLE colaborador (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cedula              VARCHAR(20) UNIQUE NOT NULL,
    nombre_completo     VARCHAR(150) NOT NULL,
    tipo                VARCHAR(10) NOT NULL CHECK (tipo IN ('INTERNO','EXTERNO')),
    titulo              VARCHAR(100),
    correo              VARCHAR(150) NOT NULL,
    telefono            VARCHAR(20),
    empresa_id          UUID REFERENCES empresa(id),
    firma_electronica   VARCHAR(300),
    fecha_nacimiento    DATE,
    estado              VARCHAR(10) NOT NULL DEFAULT 'ACTIVO',
    usuario_smartgob_id VARCHAR(100),
    password_hash       VARCHAR(300),
    es_super_usuario    BOOLEAN NOT NULL DEFAULT FALSE,
    deleted             BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by          VARCHAR(50),
    updated_by          VARCHAR(50)
);

CREATE INDEX idx_colaborador_cedula    ON colaborador(cedula);
CREATE INDEX idx_colaborador_empresa   ON colaborador(empresa_id);
CREATE INDEX idx_colaborador_correo    ON colaborador(correo);
CREATE INDEX idx_colaborador_estado    ON colaborador(estado) WHERE deleted = FALSE;

-- ============================================================
-- CONTRATO / PROYECTO
-- ============================================================
CREATE TABLE contrato (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nro_contrato          VARCHAR(50) UNIQUE NOT NULL,
    cliente               VARCHAR(200) NOT NULL,
    tipo_proyecto         VARCHAR(50) NOT NULL,
    fecha_inicio          DATE NOT NULL,
    plazo_dias            INTEGER NOT NULL,
    fecha_fin             DATE NOT NULL,
    administrador_id      UUID REFERENCES colaborador(id),
    correo_admin          VARCHAR(150),
    empresa_contratada_id UUID REFERENCES empresa(id),
    ultima_fase           VARCHAR(100),
    estado                VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
    objeto_contrato       TEXT,
    deleted               BOOLEAN NOT NULL DEFAULT FALSE,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by            VARCHAR(50),
    updated_by            VARCHAR(50)
);

CREATE INDEX idx_contrato_nro       ON contrato(nro_contrato);
CREATE INDEX idx_contrato_estado    ON contrato(estado) WHERE deleted = FALSE;
CREATE INDEX idx_contrato_empresa   ON contrato(empresa_contratada_id);
CREATE INDEX idx_contrato_fecha_fin ON contrato(fecha_fin);
CREATE INDEX idx_contrato_admin     ON contrato(administrador_id);

-- ============================================================
-- EQUIPO
-- ============================================================
CREATE TABLE equipo (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre          VARCHAR(100) NOT NULL,
    contrato_id     UUID NOT NULL REFERENCES contrato(id),
    descripcion     VARCHAR(300),
    estado          VARCHAR(10) NOT NULL DEFAULT 'ACTIVO',
    deleted         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      VARCHAR(50),
    updated_by      VARCHAR(50),
    UNIQUE(nombre, contrato_id)
);

CREATE INDEX idx_equipo_contrato ON equipo(contrato_id);

-- ============================================================
-- ASIGNACIÓN EQUIPO (colaborador ↔ equipo + rol)
-- ============================================================
CREATE TABLE asignacion_equipo (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    equipo_id        UUID NOT NULL REFERENCES equipo(id),
    colaborador_id   UUID NOT NULL REFERENCES colaborador(id),
    rol_equipo       VARCHAR(5) NOT NULL REFERENCES param_rol_equipo(codigo),
    fecha_asignacion DATE NOT NULL DEFAULT CURRENT_DATE,
    estado           VARCHAR(10) NOT NULL DEFAULT 'ACTIVO',
    deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by       VARCHAR(50),
    updated_by       VARCHAR(50),
    UNIQUE(equipo_id, colaborador_id)
);

CREATE INDEX idx_asig_equipo       ON asignacion_equipo(equipo_id);
CREATE INDEX idx_asig_colaborador  ON asignacion_equipo(colaborador_id);
CREATE INDEX idx_asig_rol          ON asignacion_equipo(rol_equipo);

-- ============================================================
-- TAREA
-- ============================================================
CREATE TABLE tarea (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_tarea             VARCHAR(20) NOT NULL,
    contrato_id          UUID NOT NULL REFERENCES contrato(id),
    equipo_id            UUID NOT NULL REFERENCES equipo(id),
    categoria            VARCHAR(20) NOT NULL REFERENCES param_categoria_tarea(codigo),
    titulo               VARCHAR(200) NOT NULL,
    descripcion          TEXT,
    prioridad            VARCHAR(10) NOT NULL REFERENCES param_prioridad(codigo),
    asignado_a_id        UUID REFERENCES colaborador(id),
    creado_por_id        UUID NOT NULL REFERENCES colaborador(id),
    fecha_asignacion     DATE NOT NULL DEFAULT CURRENT_DATE,
    estado               VARCHAR(5) NOT NULL DEFAULT 'ASG' REFERENCES param_estado_tarea(codigo),
    fecha_estimada_fin   DATE NOT NULL,
    porcentaje_avance    SMALLINT NOT NULL DEFAULT 0 CHECK (porcentaje_avance BETWEEN 0 AND 100),
    observaciones        TEXT,
    revisado_por_id      UUID REFERENCES colaborador(id),
    fecha_revision       TIMESTAMPTZ,
    process_instance_id  VARCHAR(100),
    deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by           VARCHAR(50),
    updated_by           VARCHAR(50),
    UNIQUE(id_tarea, contrato_id)
);

CREATE INDEX idx_tarea_contrato    ON tarea(contrato_id);
CREATE INDEX idx_tarea_equipo      ON tarea(equipo_id);
CREATE INDEX idx_tarea_asignado    ON tarea(asignado_a_id);
CREATE INDEX idx_tarea_estado      ON tarea(estado) WHERE deleted = FALSE;
CREATE INDEX idx_tarea_prioridad   ON tarea(prioridad);
CREATE INDEX idx_tarea_fecha_fin   ON tarea(fecha_estimada_fin);
CREATE INDEX idx_tarea_vencimiento ON tarea(fecha_estimada_fin, estado)
    WHERE estado NOT IN ('FIN','SUS') AND deleted = FALSE;
CREATE INDEX idx_tarea_process     ON tarea(process_instance_id);
CREATE INDEX idx_tarea_creado_por  ON tarea(creado_por_id);

-- ============================================================
-- HISTÓRICO DE ESTADOS (TRAZABILIDAD)
-- ============================================================
CREATE TABLE historico_estado_tarea (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tarea_id         UUID NOT NULL REFERENCES tarea(id),
    estado_anterior  VARCHAR(5) REFERENCES param_estado_tarea(codigo),
    estado_nuevo     VARCHAR(5) NOT NULL REFERENCES param_estado_tarea(codigo),
    cambiado_por_id  UUID NOT NULL REFERENCES colaborador(id),
    comentario       TEXT,
    fecha            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hist_tarea ON historico_estado_tarea(tarea_id);
CREATE INDEX idx_hist_fecha ON historico_estado_tarea(fecha);

-- ============================================================
-- COMENTARIOS DE TAREA
-- ============================================================
CREATE TABLE comentario_tarea (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tarea_id    UUID NOT NULL REFERENCES tarea(id),
    autor_id    UUID NOT NULL REFERENCES colaborador(id),
    contenido   TEXT NOT NULL,
    tipo        VARCHAR(20) NOT NULL DEFAULT 'COMENTARIO'
                CHECK (tipo IN ('COMENTARIO','OBSERVACION_REVISION','SISTEMA')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_comentario_tarea ON comentario_tarea(tarea_id);

-- ============================================================
-- ADJUNTOS DE TAREA
-- ============================================================
CREATE TABLE adjunto_tarea (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tarea_id        UUID NOT NULL REFERENCES tarea(id),
    nombre_archivo  VARCHAR(300) NOT NULL,
    ruta_archivo    VARCHAR(500) NOT NULL,
    tipo_mime       VARCHAR(100),
    tamano_bytes    BIGINT,
    subido_por_id   UUID NOT NULL REFERENCES colaborador(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_adjunto_tarea ON adjunto_tarea(tarea_id);

-- ============================================================
-- MENSAJERÍA
-- ============================================================
CREATE TABLE mensaje (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    remitente_id     UUID NOT NULL REFERENCES colaborador(id),
    destinatario_id  UUID REFERENCES colaborador(id),
    equipo_id        UUID REFERENCES equipo(id),
    contrato_id      UUID REFERENCES contrato(id),
    asunto           VARCHAR(200),
    contenido        TEXT NOT NULL,
    tipo             VARCHAR(20) NOT NULL DEFAULT 'DIRECTO'
                     CHECK (tipo IN ('DIRECTO','EQUIPO','PROYECTO')),
    leido            BOOLEAN NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_msg_destinatario ON mensaje(destinatario_id, leido);
CREATE INDEX idx_msg_equipo       ON mensaje(equipo_id);
CREATE INDEX idx_msg_contrato     ON mensaje(contrato_id);
CREATE INDEX idx_msg_remitente    ON mensaje(remitente_id);
CREATE INDEX idx_msg_fecha        ON mensaje(created_at);

-- ============================================================
-- NOTIFICACIONES
-- ============================================================
CREATE TABLE notificacion (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    destinatario_id  UUID NOT NULL REFERENCES colaborador(id),
    tipo             VARCHAR(30) NOT NULL,
    referencia_tipo  VARCHAR(30),
    referencia_id    UUID,
    titulo           VARCHAR(200) NOT NULL,
    mensaje          TEXT NOT NULL,
    leido            BOOLEAN NOT NULL DEFAULT FALSE,
    url_accion       VARCHAR(500),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notif_dest   ON notificacion(destinatario_id, leido);
CREATE INDEX idx_notif_fecha  ON notificacion(created_at);
CREATE INDEX idx_notif_tipo   ON notificacion(tipo);

-- ============================================================
-- AUDITORÍA GENERAL
-- ============================================================
CREATE TABLE auditoria (
    id                BIGSERIAL PRIMARY KEY,
    tabla             VARCHAR(50) NOT NULL,
    registro_id       UUID NOT NULL,
    accion            VARCHAR(10) NOT NULL CHECK (accion IN ('INSERT','UPDATE','DELETE')),
    datos_anteriores  JSONB,
    datos_nuevos      JSONB,
    usuario_id        VARCHAR(100),
    ip_origen         VARCHAR(50),
    fecha             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_tabla ON auditoria(tabla, registro_id);
CREATE INDEX idx_audit_fecha ON auditoria(fecha);
CREATE INDEX idx_audit_user  ON auditoria(usuario_id);
SQLEOF

echo "  ✅ V2 - Tablas de negocio"

# =============================================================
# V3 — VISTAS, FUNCIONES Y TRIGGERS
# =============================================================

cat > $MIGRATIONS/V3__views_functions_triggers.sql << 'SQLEOF'
-- ============================================================
-- V3: Vistas, funciones y triggers de auditoría
-- SmartGob - Gestión de Proyectos
-- ============================================================

SET search_path TO gestion_proyectos;

-- ============================================================
-- VISTA: Tareas con alertas SLA
-- ============================================================
CREATE OR REPLACE VIEW v_tareas_alerta_sla AS
SELECT
    t.id,
    t.id_tarea,
    t.titulo,
    t.estado,
    t.prioridad,
    t.categoria,
    t.fecha_asignacion,
    t.fecha_estimada_fin,
    t.porcentaje_avance,
    t.observaciones,
    t.created_at,
    t.updated_at,
    t.contrato_id,
    t.equipo_id,
    t.asignado_a_id,
    t.creado_por_id,
    t.revisado_por_id,
    c.nro_contrato,
    c.cliente,
    e.nombre                AS nombre_equipo,
    col_asig.nombre_completo AS asignado_a_nombre,
    col_asig.correo          AS asignado_a_correo,
    col_crea.nombre_completo AS creado_por_nombre,
    pet.color_hex            AS estado_color,
    pet.color_bg_hex         AS estado_bg,
    pet.nombre               AS estado_nombre,
    pp.color_hex             AS prioridad_color,
    pp.nombre                AS prioridad_nombre,
    pp.peso                  AS prioridad_peso,
    -- Días restantes
    GREATEST(0, t.fecha_estimada_fin - CURRENT_DATE) AS dias_restantes,
    -- Alerta SLA
    CASE
        WHEN t.estado NOT IN ('FIN','SUS') AND t.fecha_estimada_fin < CURRENT_DATE
            THEN 'VENCIDA'
        WHEN t.estado NOT IN ('FIN','SUS') AND t.fecha_estimada_fin <= CURRENT_DATE + INTERVAL '3 days'
            THEN 'PROXIMA_VENCER'
        WHEN t.estado = 'REV' AND t.updated_at + INTERVAL '72 hours' < NOW()
            THEN 'REVISION_VENCIDA'
        WHEN t.estado = 'REV'
            THEN 'EN_REVISION'
        WHEN t.estado = 'FIN'
            THEN 'FINALIZADA'
        ELSE 'NORMAL'
    END AS alerta_sla,
    -- Horas restantes para revisión (solo si está en REV)
    CASE
        WHEN t.estado = 'REV' THEN
            GREATEST(0, EXTRACT(EPOCH FROM (t.updated_at + INTERVAL '72 hours' - NOW())) / 3600)::INTEGER
        ELSE NULL
    END AS horas_restantes_revision
FROM tarea t
    JOIN contrato c          ON t.contrato_id = c.id
    JOIN equipo e            ON t.equipo_id = e.id
    LEFT JOIN colaborador col_asig ON t.asignado_a_id = col_asig.id
    LEFT JOIN colaborador col_crea ON t.creado_por_id = col_crea.id
    JOIN param_estado_tarea pet ON t.estado = pet.codigo
    JOIN param_prioridad pp     ON t.prioridad = pp.codigo
WHERE t.deleted = FALSE;

-- ============================================================
-- VISTA: Dashboard Súper Usuario
-- ============================================================
CREATE OR REPLACE VIEW v_dashboard_super AS
SELECT
    c.id                    AS contrato_id,
    c.nro_contrato,
    c.cliente,
    c.tipo_proyecto,
    c.fecha_inicio,
    c.fecha_fin,
    c.estado                AS contrato_estado,
    (c.fecha_fin - CURRENT_DATE)  AS dias_restantes_contrato,
    -- Conteos
    COUNT(t.id)                                               AS total_tareas,
    COUNT(t.id) FILTER (WHERE t.estado = 'FIN')               AS tareas_finalizadas,
    COUNT(t.id) FILTER (WHERE t.estado = 'TERT')              AS tareas_fuera_plazo,
    COUNT(t.id) FILTER (WHERE t.estado IN ('ASG','EJE'))      AS tareas_activas,
    COUNT(t.id) FILTER (WHERE t.estado = 'SUS')               AS tareas_suspendidas,
    COUNT(t.id) FILTER (WHERE t.estado = 'REV')               AS tareas_en_revision,
    COUNT(t.id) FILTER (WHERE t.prioridad = 'CRITICA'
                          AND t.estado NOT IN ('FIN','SUS'))   AS tareas_criticas,
    -- Vencidas sin terminar
    COUNT(t.id) FILTER (WHERE t.estado NOT IN ('FIN','SUS','TER','TERT','REV')
                          AND t.fecha_estimada_fin < CURRENT_DATE) AS tareas_vencidas,
    -- Porcentaje avance global
    CASE
        WHEN COUNT(t.id) > 0
        THEN ROUND(COUNT(t.id) FILTER (WHERE t.estado = 'FIN')::NUMERIC / COUNT(t.id) * 100, 1)
        ELSE 0
    END AS porcentaje_avance_global
FROM contrato c
    LEFT JOIN tarea t ON c.id = t.contrato_id AND t.deleted = FALSE
WHERE c.deleted = FALSE
GROUP BY c.id, c.nro_contrato, c.cliente, c.tipo_proyecto,
         c.fecha_inicio, c.fecha_fin, c.estado;

-- ============================================================
-- VISTA: Dashboard Líder/Administrador por equipo
-- ============================================================
CREATE OR REPLACE VIEW v_dashboard_equipo AS
SELECT
    e.id                    AS equipo_id,
    e.nombre                AS equipo_nombre,
    e.contrato_id,
    c.nro_contrato,
    c.cliente,
    -- Conteos
    COUNT(t.id)                                               AS total_tareas,
    COUNT(t.id) FILTER (WHERE t.estado = 'ASG')               AS backlog,
    COUNT(t.id) FILTER (WHERE t.estado = 'EJE')               AS ejecutando,
    COUNT(t.id) FILTER (WHERE t.estado = 'REV')               AS en_revision,
    COUNT(t.id) FILTER (WHERE t.estado = 'FIN')               AS finalizadas,
    COUNT(t.id) FILTER (WHERE t.estado = 'SUS')               AS suspendidas,
    COUNT(t.id) FILTER (WHERE t.estado = 'TERT')              AS fuera_plazo,
    COUNT(t.id) FILTER (WHERE t.prioridad = 'CRITICA'
                          AND t.estado NOT IN ('FIN','SUS'))   AS criticas,
    -- Vencidas
    COUNT(t.id) FILTER (WHERE t.estado NOT IN ('FIN','SUS','TER','TERT','REV')
                          AND t.fecha_estimada_fin < CURRENT_DATE) AS vencidas,
    -- Miembros del equipo
    (SELECT COUNT(*) FROM asignacion_equipo ae
     WHERE ae.equipo_id = e.id AND ae.deleted = FALSE AND ae.estado = 'ACTIVO') AS total_miembros,
    -- Avance
    CASE
        WHEN COUNT(t.id) > 0
        THEN ROUND(AVG(t.porcentaje_avance), 1)
        ELSE 0
    END AS avance_promedio
FROM equipo e
    JOIN contrato c ON e.contrato_id = c.id
    LEFT JOIN tarea t ON e.id = t.equipo_id AND t.deleted = FALSE
WHERE e.deleted = FALSE
GROUP BY e.id, e.nombre, e.contrato_id, c.nro_contrato, c.cliente;

-- ============================================================
-- VISTA: Carga de trabajo por colaborador
-- ============================================================
CREATE OR REPLACE VIEW v_carga_colaborador AS
SELECT
    col.id                  AS colaborador_id,
    col.nombre_completo,
    col.correo,
    ae.equipo_id,
    ae.rol_equipo,
    e.nombre                AS equipo_nombre,
    COUNT(t.id) FILTER (WHERE t.estado IN ('ASG','EJE'))  AS tareas_activas,
    COUNT(t.id) FILTER (WHERE t.estado = 'REV')           AS en_revision,
    COUNT(t.id) FILTER (WHERE t.estado NOT IN ('FIN','SUS')
                          AND t.fecha_estimada_fin < CURRENT_DATE) AS vencidas,
    COUNT(t.id)                                            AS total_asignadas
FROM colaborador col
    JOIN asignacion_equipo ae ON col.id = ae.colaborador_id AND ae.deleted = FALSE
    JOIN equipo e ON ae.equipo_id = e.id
    LEFT JOIN tarea t ON col.id = t.asignado_a_id AND t.deleted = FALSE AND t.equipo_id = e.id
WHERE col.deleted = FALSE
GROUP BY col.id, col.nombre_completo, col.correo, ae.equipo_id, ae.rol_equipo, e.nombre;

-- ============================================================
-- FUNCIÓN: Trigger de auditoría genérico
-- ============================================================
CREATE OR REPLACE FUNCTION fn_auditoria_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO gestion_proyectos.auditoria(tabla, registro_id, accion, datos_nuevos, usuario_id)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW),
                current_setting('app.current_user', TRUE));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO gestion_proyectos.auditoria(tabla, registro_id, accion, datos_anteriores, datos_nuevos, usuario_id)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW),
                current_setting('app.current_user', TRUE));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO gestion_proyectos.auditoria(tabla, registro_id, accion, datos_anteriores, usuario_id)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD),
                current_setting('app.current_user', TRUE));
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- FUNCIÓN: Actualizar updated_at automáticamente
-- ============================================================
CREATE OR REPLACE FUNCTION fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TRIGGERS DE AUDITORÍA
-- ============================================================
CREATE TRIGGER trg_audit_tarea
    AFTER INSERT OR UPDATE OR DELETE ON tarea
    FOR EACH ROW EXECUTE FUNCTION fn_auditoria_trigger();

CREATE TRIGGER trg_audit_contrato
    AFTER INSERT OR UPDATE OR DELETE ON contrato
    FOR EACH ROW EXECUTE FUNCTION fn_auditoria_trigger();

CREATE TRIGGER trg_audit_equipo
    AFTER INSERT OR UPDATE OR DELETE ON equipo
    FOR EACH ROW EXECUTE FUNCTION fn_auditoria_trigger();

CREATE TRIGGER trg_audit_asignacion
    AFTER INSERT OR UPDATE OR DELETE ON asignacion_equipo
    FOR EACH ROW EXECUTE FUNCTION fn_auditoria_trigger();

CREATE TRIGGER trg_audit_colaborador
    AFTER INSERT OR UPDATE OR DELETE ON colaborador
    FOR EACH ROW EXECUTE FUNCTION fn_auditoria_trigger();

-- ============================================================
-- TRIGGERS DE UPDATED_AT
-- ============================================================
CREATE TRIGGER trg_upd_empresa      BEFORE UPDATE ON empresa           FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_upd_colaborador  BEFORE UPDATE ON colaborador       FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_upd_contrato     BEFORE UPDATE ON contrato          FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_upd_equipo       BEFORE UPDATE ON equipo            FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_upd_asignacion   BEFORE UPDATE ON asignacion_equipo FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
CREATE TRIGGER trg_upd_tarea        BEFORE UPDATE ON tarea             FOR EACH ROW EXECUTE FUNCTION fn_update_timestamp();
SQLEOF

echo "  ✅ V3 - Vistas, funciones y triggers"

# =============================================================
# V4 — DATOS INICIALES (Super Usuario + Empresa demo)
# =============================================================

cat > $MIGRATIONS/V4__seed_data.sql << 'SQLEOF'
-- ============================================================
-- V4: Datos iniciales (Super Usuario + datos demo)
-- SmartGob - Gestión de Proyectos
-- Password: Admin2026! (BCrypt hash)
-- ============================================================

SET search_path TO gestion_proyectos;

-- Empresa TECH2GO
INSERT INTO empresa (id, ruc, razon_social, tipo, estado) VALUES
    ('a0000000-0000-0000-0000-000000000001', '0992999999001', 'TECH2GO S.A.', 'PRIVADA', 'ACTIVO');

-- Súper Usuario
INSERT INTO colaborador (id, cedula, nombre_completo, tipo, titulo, correo, telefono,
    empresa_id, estado, password_hash, es_super_usuario) VALUES
    ('b0000000-0000-0000-0000-000000000001',
     '0900000001',
     'Administrador SmartGob',
     'INTERNO',
     'Ing. Sistemas',
     'admin@smartgob.ec',
     '0999999999',
     'a0000000-0000-0000-0000-000000000001',
     'ACTIVO',
     -- BCrypt de 'Admin2026!'
     '$2a$12$LJ3m4ys3Hz.GA4RI5gBkuOUgR6IhMQrsVGnBgEXXDZD8FGY4m.KJG',
     TRUE);

-- Colaboradores demo
INSERT INTO colaborador (id, cedula, nombre_completo, tipo, titulo, correo, empresa_id, estado, password_hash, es_super_usuario) VALUES
    ('b0000000-0000-0000-0000-000000000002', '0900000002', 'María García López',   'INTERNO', 'Ing. Software',    'maria.garcia@tech2go.ec',   'a0000000-0000-0000-0000-000000000001', 'ACTIVO', '$2a$12$LJ3m4ys3Hz.GA4RI5gBkuOUgR6IhMQrsVGnBgEXXDZD8FGY4m.KJG', FALSE),
    ('b0000000-0000-0000-0000-000000000003', '0900000003', 'Carlos Pérez Ruiz',    'INTERNO', 'Ing. Sistemas',    'carlos.perez@tech2go.ec',   'a0000000-0000-0000-0000-000000000001', 'ACTIVO', '$2a$12$LJ3m4ys3Hz.GA4RI5gBkuOUgR6IhMQrsVGnBgEXXDZD8FGY4m.KJG', FALSE),
    ('b0000000-0000-0000-0000-000000000004', '0900000004', 'Ana Torres Medina',    'INTERNO', 'QA Engineer',      'ana.torres@tech2go.ec',     'a0000000-0000-0000-0000-000000000001', 'ACTIVO', '$2a$12$LJ3m4ys3Hz.GA4RI5gBkuOUgR6IhMQrsVGnBgEXXDZD8FGY4m.KJG', FALSE),
    ('b0000000-0000-0000-0000-000000000005', '0900000005', 'Luis Mendoza Castro',  'INTERNO', 'Documentador',     'luis.mendoza@tech2go.ec',   'a0000000-0000-0000-0000-000000000001', 'ACTIVO', '$2a$12$LJ3m4ys3Hz.GA4RI5gBkuOUgR6IhMQrsVGnBgEXXDZD8FGY4m.KJG', FALSE),
    ('b0000000-0000-0000-0000-000000000006', '0900000006', 'Roberto Sánchez Vega', 'EXTERNO', 'Dev Full Stack',   'roberto.sanchez@extern.ec', 'a0000000-0000-0000-0000-000000000001', 'ACTIVO', '$2a$12$LJ3m4ys3Hz.GA4RI5gBkuOUgR6IhMQrsVGnBgEXXDZD8FGY4m.KJG', FALSE);

-- Contrato demo
INSERT INTO contrato (id, nro_contrato, cliente, tipo_proyecto, fecha_inicio, plazo_dias, fecha_fin,
    administrador_id, correo_admin, empresa_contratada_id, ultima_fase, estado, objeto_contrato) VALUES
    ('c0000000-0000-0000-0000-000000000001',
     'CONT-2026-001',
     'GAD Municipal del Cantón Daule',
     'Desarrollo Software',
     '2026-01-15', 180, '2026-07-14',
     'b0000000-0000-0000-0000-000000000002',
     'maria.garcia@tech2go.ec',
     'a0000000-0000-0000-0000-000000000001',
     'Desarrollo',
     'ACTIVO',
     'Desarrollo e implementación del Sistema de Catastro Municipal integrado a SmartGob');

-- Equipo demo
INSERT INTO equipo (id, nombre, contrato_id, descripcion, estado) VALUES
    ('d0000000-0000-0000-0000-000000000001',
     'Backend Core',
     'c0000000-0000-0000-0000-000000000001',
     'Equipo de desarrollo backend - APIs y servicios',
     'ACTIVO');

-- Asignaciones al equipo
INSERT INTO asignacion_equipo (equipo_id, colaborador_id, rol_equipo, fecha_asignacion) VALUES
    ('d0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'LDR', '2026-01-15'),
    ('d0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', 'DEV', '2026-01-15'),
    ('d0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000004', 'TST', '2026-01-15'),
    ('d0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000005', 'DOC', '2026-01-15'),
    ('d0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000006', 'DEV', '2026-01-20');

-- Tareas demo
INSERT INTO tarea (id, id_tarea, contrato_id, equipo_id, categoria, titulo, descripcion,
    prioridad, asignado_a_id, creado_por_id, fecha_asignacion, estado, fecha_estimada_fin, porcentaje_avance) VALUES
    ('e0000000-0000-0000-0000-000000000001', 'T-001', 'c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001',
     'DESARROLLO', 'Diseñar API REST de catastro', 'Definir endpoints, DTOs y documentación Swagger para el módulo de catastro',
     'CRITICA', 'b0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000002',
     '2026-02-01', 'EJE', '2026-03-15', 60),
    ('e0000000-0000-0000-0000-000000000002', 'T-002', 'c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001',
     'DESARROLLO', 'Implementar módulo de pagos', 'Integración con Nuvei/Paymentez para pagos municipales',
     'ALTA', 'b0000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000002',
     '2026-02-10', 'ASG', '2026-03-20', 0),
    ('e0000000-0000-0000-0000-000000000003', 'T-003', 'c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001',
     'DOCUMENTACION', 'Manual de usuario catastro', 'Elaborar manual de usuario para el módulo de catastro',
     'MEDIA', 'b0000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000002',
     '2026-02-15', 'ASG', '2026-04-01', 0),
    ('e0000000-0000-0000-0000-000000000004', 'T-004', 'c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001',
     'PRUEBAS', 'Pruebas de integración pagos', 'Ejecutar pruebas end-to-end del flujo de pagos',
     'ALTA', 'b0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000002',
     '2026-02-20', 'ASG', '2026-03-25', 0),
    ('e0000000-0000-0000-0000-000000000005', 'T-005', 'c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001',
     'DESARROLLO', 'Configurar nginx proxy', 'Configuración de nginx como reverse proxy para APIs de producción',
     'BAJA', 'b0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000002',
     '2026-02-25', 'EJE', '2026-03-05', 80);

-- Histórico para tareas que ya tienen estado != ASG
INSERT INTO historico_estado_tarea (tarea_id, estado_anterior, estado_nuevo, cambiado_por_id, comentario) VALUES
    ('e0000000-0000-0000-0000-000000000001', NULL,  'ASG', 'b0000000-0000-0000-0000-000000000002', 'Tarea creada y asignada'),
    ('e0000000-0000-0000-0000-000000000001', 'ASG', 'EJE', 'b0000000-0000-0000-0000-000000000003', 'Iniciando diseño de API'),
    ('e0000000-0000-0000-0000-000000000005', NULL,  'ASG', 'b0000000-0000-0000-0000-000000000002', 'Tarea creada y asignada'),
    ('e0000000-0000-0000-0000-000000000005', 'ASG', 'EJE', 'b0000000-0000-0000-0000-000000000003', 'Configuración iniciada');
SQLEOF

echo "  ✅ V4 - Datos iniciales (seed)"

# === Eliminar el placeholder V1 anterior ===
rm -f $MIGRATIONS/V1__create_schema.sql

echo ""
echo "============================================================"
echo "✅ COMMIT 2 COMPLETO — Migraciones Flyway"
echo "============================================================"
echo ""
echo "Archivos generados:"
ls -la $MIGRATIONS/
echo ""
echo "📋 Ejecuta:"
echo "  git add ."
echo '  git commit -m "feat: migraciones Flyway V1-V4 - DDL, parametrización, vistas, triggers, seed"'
echo "  git push"
echo ""
echo "📌 CREDENCIALES DE PRUEBA:"
echo "  Usuario: admin@smartgob.ec / 0900000001"
echo "  Password: Admin2026!"
echo ""
echo "📌 Para probar la BD localmente:"
echo "  docker-compose up -d postgres"
echo "  # La BD se creará automáticamente al iniciar el backend con Flyway"
echo ""

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

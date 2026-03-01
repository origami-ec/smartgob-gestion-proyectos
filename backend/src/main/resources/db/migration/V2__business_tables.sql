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

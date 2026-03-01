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

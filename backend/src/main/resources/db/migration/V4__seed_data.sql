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

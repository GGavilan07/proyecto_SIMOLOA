INSERT INTO nivel_educativo (id_nivel, nombre_nivel) VALUES 
('N-1', '7mo Básico'), ('N-2', '8vo Básico'), ('N-3', '1ro Medio'), 
('N-4', '2do Medio'), ('N-5', '3ro Medio'), ('N-6', '4to Medio');

INSERT INTO asignaturas (id_asignatura, nombre_asignatura) VALUES 
('A-1', 'Lenguaje'), ('A-2', 'Matemática'), ('A-3', 'Historia'), ('A-4', 'Ciencias'),
('A-5', 'Inglés'), ('A-6', 'Educ. Física'), ('A-7', 'Artes'), ('A-8', 'Tecnología');

INSERT INTO tipo_recurso (id_tipo_recurso, nombre_tipo) VALUES 
('TR-1', 'Guía de Trabajo'), ('TR-2', 'Video Didáctico'), 
('TR-3', 'Presentación PPT'), ('TR-4', 'Evaluación Formativa');

INSERT INTO docente (id_docente, nombre, apellido, correo)
SELECT 
    'DOC-' || i,
    (ARRAY['Juan', 'María', 'Carlos', 'Ana', 'Luis', 'Pedro', 'Laura', 'Sofía', 'Diego', 'Valentina'])[floor(random() * 10 + 1)::int],
    (ARRAY['Pérez', 'Soto', 'Gómez', 'Silva', 'Rojas', 'Contreras', 'Morales', 'Sepúlveda', 'Muñoz', 'Díaz'])[floor(random() * 10 + 1)::int],
    'docente.' || i || '@simoloa.cl'
FROM generate_series(1, 40) s(i);

INSERT INTO cursos (id_curso, nombre_curso, id_nivel, ano_academico)
SELECT 
    'CUR-' || n.id_nivel || '-' || letra,
    n.nombre_nivel || ' ' || letra,
    n.id_nivel,
    2026
FROM nivel_educativo n
CROSS JOIN unnest(ARRAY['A', 'B', 'C', 'D']) AS letra;

INSERT INTO asignacion_academica (id_asignacion, id_docente, id_curso, id_asignatura)
SELECT 
    'AA-' || row_number() over (),
    'DOC-' || floor(random() * 40 + 1)::int,
    c.id_curso,
    a.id_asignatura
FROM cursos c
CROSS JOIN asignaturas a;

INSERT INTO objetivos_aprendizaje (id_objetivos, descripcion, id_nivel, id_asignatura)
SELECT 
    'OA-' || n.id_nivel || '-' || a.id_asignatura || '-' || i,
    'Comprender y aplicar conceptos clave de la unidad ' || i || ' en ' || a.nombre_asignatura,
    n.id_nivel,
    a.id_asignatura
FROM nivel_educativo n
CROSS JOIN asignaturas a
CROSS JOIN generate_series(1, 3) s(i);

INSERT INTO contenidos_curriculares (id_contenido, descripcion, id_asignatura, id_nivel, id_objetivos)
SELECT 
    'CONT-' || oa.id_objetivos || '-' || j,
    'Desarrollo temático ' || j || ' correspondiente al ' || oa.id_objetivos,
    oa.id_asignatura,
    oa.id_nivel,
    oa.id_objetivos
FROM objetivos_aprendizaje oa
CROSS JOIN generate_series(1, 4) s(j);

INSERT INTO planificaciones (id_planificacion, id_asignacion, estado, fecha_creacion)
SELECT 
    'PLAN-' || id_asignacion,
    id_asignacion,
    (ARRAY['pendiente', 'aprobada', 'aprobada', 'aprobada'])[floor(random() * 4 + 1)::int],
    date '2026-03-01' + (random() * 15)::int
FROM asignacion_academica;

INSERT INTO planificacion_detalle (id_planificacion, id_contenido)
SELECT DISTINCT p.id_planificacion, c.id_contenido
FROM planificaciones p
JOIN asignacion_academica aa ON p.id_asignacion = aa.id_asignacion
JOIN contenidos_curriculares c ON c.id_asignatura = aa.id_asignatura AND c.id_nivel = (SELECT id_nivel FROM cursos WHERE id_curso = aa.id_curso)
ON CONFLICT DO NOTHING;

INSERT INTO clases (id_clase, id_planificacion, fecha_clase, periodo_academico)
SELECT 
    'CLA-' || p.id_planificacion || '-' || i,
    p.id_planificacion,
    p.fecha_creacion + (i * 7),
    'Primer Semestre'
FROM planificaciones p
CROSS JOIN generate_series(1, 15) s(i);

INSERT INTO clase_contenido (id_clase, id_contenido)
SELECT DISTINCT cl.id_clase, pd.id_contenido
FROM clases cl
JOIN planificaciones p ON cl.id_planificacion = p.id_planificacion
JOIN planificacion_detalle pd ON p.id_planificacion = pd.id_planificacion
WHERE random() > 0.6
ON CONFLICT DO NOTHING;

INSERT INTO preguntas (id_pregunta, enunciado, id_asignatura, id_nivel, id_contenido, id_objetivos)
SELECT 
    'PREG-' || c.id_contenido || '-' || i,
    'Pregunta tipo evaluación número ' || i || ' sobre ' || c.descripcion,
    c.id_asignatura,
    c.id_nivel,
    c.id_contenido,
    c.id_objetivos
FROM contenidos_curriculares c
CROSS JOIN generate_series(1, 3) s(i);

INSERT INTO evaluaciones (id_evaluacion, id_docente, id_curso, id_asignatura, fecha_realizacion)
SELECT 
    'EVAL-' || row_number() over(),
    id_docente,
    id_curso,
    id_asignatura,
    date '2026-04-01' + (random() * 60)::int
FROM asignacion_academica
CROSS JOIN generate_series(1, 2) s(i);

INSERT INTO evaluacion_pregunta (id_evaluacion, id_pregunta)
SELECT DISTINCT e.id_evaluacion, p.id_pregunta
FROM evaluaciones e
JOIN preguntas p ON e.id_asignatura = p.id_asignatura AND (random() > 0.8)
ON CONFLICT DO NOTHING;

INSERT INTO recurso_pedagogico (id_recurso, titulo_recurso, id_tipo_recurso, id_asignatura, id_contenido, id_objetivo, url_archivo)
SELECT 
    'REC-' || c.id_contenido || '-' || i,
    'Material de apoyo ' || i || ' - ' || c.descripcion,
    'TR-' || floor(random() * 4 + 1)::int,
    c.id_asignatura,
    c.id_contenido,
    c.id_objetivos,
    'https://simoloa.cl/files/' || c.id_contenido || '_' || i || '.zip'
FROM contenidos_curriculares c
CROSS JOIN generate_series(1, 2) s(i);

INSERT INTO registro_recursos (id_uso, id_recurso, id_docente, fecha_uso)
SELECT 
    'USO-' || row_number() over (),
    r.id_recurso,
    'DOC-' || floor(random() * 40 + 1)::int,
    date '2026-03-01' + (random() * 120)::int
FROM recurso_pedagogico r
CROSS JOIN generate_series(1, 5) s(i);

-- Historial: registro de creación (estado_anterior NULL -> 'pendiente') para TODAS las planificaciones
INSERT INTO historial_planificacion (id_historial, id_planificacion, estado_anterior, estado_nuevo, fecha_cambio, usuario_responsable)
SELECT 
    'HIST-' || p.id_planificacion || '-1',
    p.id_planificacion,
    NULL,
    'pendiente',
    p.fecha_creacion::timestamp,
    aa.id_docente
FROM planificaciones p
JOIN asignacion_academica aa ON aa.id_asignacion = p.id_asignacion;

INSERT INTO historial_planificacion (id_historial, id_planificacion, estado_anterior, estado_nuevo, fecha_cambio, usuario_responsable)
SELECT 
    'HIST-' || p.id_planificacion || '-2',
    p.id_planificacion,
    'pendiente',
    p.estado,
    (p.fecha_creacion + (floor(random() * 10) + 1)::int)::timestamp,
    'DOC-' || floor(random() * 40 + 1)::int
FROM planificaciones p
WHERE p.estado <> 'pendiente';
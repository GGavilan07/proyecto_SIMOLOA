--1.Obtener el listado de docentes registrados en el sistema junto con las asignaturas y cursos asociados.

select docente.nombre, docente.apellido, asignaturas.nombre_asignatura, cursos.nombre_curso from asignacion_academica 
join docente on docente.id_docente=asignacion_academica.id_docente
join asignaturas on asignaturas.id_asignatura=asignacion_academica.id_asignatura
join cursos on cursos.id_curso=asignacion_academica.id_curso;

--2.Consultar las planificaciones curriculares registradas para cada docente, curso y asignatura.

SELECT p.id_planificacion, p.estado, d.nombre, d.apellido, c.nombre_curso, a.nombre_asignatura
FROM planificaciones p
JOIN asignacion_academica aa ON p.id_asignacion = aa.id_asignacion
JOIN docente d ON aa.id_docente = d.id_docente
JOIN cursos c ON aa.id_curso = c.id_curso
JOIN asignaturas a ON aa.id_asignatura = a.id_asignatura;

--3.Identificar las planificaciones curriculares que se encuentren pendientes de aprobacion por parte de la Unidad Tecnico Pedagogica

select p.id_planificacion,d.nombre,d.apellido,c.nombre_curso,p.fecha_creacion from planificaciones p
join asignacion_academica aa on aa.id_asignacion=p.id_asignacion
join docente d on d.id_docente=aa.id_docente
join cursos c on c.id_curso=aa.id_curso
where p.estado='pendiente';

--4.Visualizar los contenidos curriculares planificados para una asignatura y nivel educativo especıfico.

select cc.descripcion, a.nombre_asignatura, ne.nombre_nivel
from contenidos_curriculares cc
join asignaturas a on cc.id_asignatura = a.id_asignatura
join nivel_educativo ne on cc.id_nivel = ne.id_nivel
where a.nombre_asignatura = 'Matemática' and ne.nombre_nivel = '1ro Medio';

--5.Consultar las clases realizadas por cada docente durante un perıodo academico determinado.

select cl.id_clase, cl.fecha_clase, d.nombre, d.apellido, cl.periodo_academico from clases cl
join planificaciones p on cl.id_planificacion = p.id_planificacion
join asignacion_academica aa on p.id_asignacion = aa.id_asignacion
join docente d on aa.id_docente = d.id_docente
where cl.periodo_academico = 'Primer Semestre';

--6. Obtener los contenidos efectivamente impartidos en cada clase registrada
select cl.id_clase, cl.fecha_clase, cc.descripcion from clases cl
join clase_contenido clc on cl.id_clase = clc.id_clase
join contenidos_curriculares cc on clc.id_contenido = cc.id_contenido;
--7. Comparar los contenidos planificados con los contenidos efectivamente impartidos.
select pd.id_planificacion, pd.id_contenido
from planificacion_detalle pd
left join clases cl on cl.id_planificacion = pd.id_planificacion
left join clase_contenido clc 
    on clc.id_clase = cl.id_clase 
    and clc.id_contenido = pd.id_contenido
where clc.id_contenido is null;
--8. Generar reportes de avance curricular por docente, curso y asignatura
select d.nombre, d.apellido, c.nombre_curso, a.nombre_asignatura,
count(distinct pd.id_contenido) as total_planificado,
count(distinct clc.id_contenido) as total_impartido,
round((count(distinct clc.id_contenido)::decimal / nullif(count(distinct pd.id_contenido), 0)) * 100, 2) as porcentaje_avance
from planificaciones p
join asignacion_academica aa on aa.id_asignacion = p.id_asignacion
join docente d on d.id_docente = aa.id_docente
join cursos c on c.id_curso = aa.id_curso
join asignaturas a on a.id_asignatura = aa.id_asignatura
join planificacion_detalle pd on pd.id_planificacion = p.id_planificacion
left join clases cl on cl.id_planificacion = p.id_planificacion
left join clase_contenido clc on clc.id_clase = cl.id_clase
and clc.id_contenido = pd.id_contenido
group by d.nombre, d.apellido, c.nombre_curso, a.nombre_asignatura;
--9. Identificar los objetivos de aprendizaje trabajados en cada nivel educativo
select distinct oa.id_objetivos, oa.descripcion, ne.nombre_nivel from objetivos_aprendizaje oa
join nivel_educativo ne on ne.id_nivel = oa.id_nivel;
--10. Consultar evaluaciones generadas por los docentes durante un período académico específico
select d.nombre, d.apellido, ev.id_evaluacion, c.nombre_curso from evaluaciones ev
join docente d on d.id_docente = ev.id_docente
join cursos c on c.id_curso = ev.id_curso
where fecha_realizacion between '2026-05-23' and '2026-12-23';
-- 11. Obtener el listado de preguntas asociadas a un contenido curricular determinado
select p.id_pregunta, cc.id_contenido, cc.descripcion, cc.id_asignatura from preguntas p
join contenidos_curriculares cc on cc.id_contenido = p.id_contenido
where cc.id_contenido = 'CONT-OA-N-1-A-1-1-1';
--12. Consultar preguntas clasificadas según asignatura, nivel educativo y objetivo de aprendizaje
select p.id_pregunta, p.enunciado, a.id_asignatura, a.nombre_asignatura, ne.id_nivel, ne.nombre_nivel, oa.id_objetivos, oa.descripcion from preguntas p 
join asignaturas a on a.id_asignatura = p.id_asignatura
join nivel_educativo ne on ne.id_nivel = p.id_nivel
join objetivos_aprendizaje oa on oa.id_objetivos = p.id_objetivos
where a.nombre_asignatura = 'Matemática' and
ne.nombre_nivel = '8vo Básico' and
oa.descripcion ='Comprender y aplicar conceptos clave de la unidad 1 en Matemática';
-- 13. Identificar las evaluaciones que contengan preguntas asociadas a determinados objetivos de aprendizaje
select ev.id_evaluacion, p.id_pregunta, p.enunciado, p.id_objetivos from evaluaciones ev
join evaluacion_pregunta evp on evp.id_evaluacion = ev.id_evaluacion
join preguntas p on p.id_pregunta = evp.id_pregunta
where p.id_objetivos = 'OA-N-6-A-2-2';
--14. Obtener el número de evaluaciones generadas por cada docente
select d.id_docente, d.nombre, d.apellido, count(ev.id_evaluacion) as total_evaluaciones from docente d
left join evaluaciones ev on ev.id_docente = d.id_docente
group by d.id_docente, d.nombre, d.apellido;
--15.  Consultar recursos pedagógicos asociados a una asignatura específica.
select a.nombre_asignatura, rp.titulo_recurso, cc.descripcion as descripcion_contenido, rp.url_archivo from recurso_pedagogico rp
join asignaturas a on a.id_asignatura = rp.id_asignatura
join contenidos_curriculares cc on cc.id_contenido = rp.id_contenido
where a.nombre_asignatura = 'Matemática';
--16. Obtener recursos pedagógicos relacionados con un contenido curricular u objetivo de aprendizaje determinado
select rp.id_recurso, rp.titulo_recurso, rp.id_contenido, rp.id_objetivos, rp.url_archivo from recurso_pedagogico rp
where rp.id_contenido = 'CONT-OA-N-1-A-1-1-1' or rp.id_objetivos = 'OA-N-1-A-1-1';
--17. Identificar los recursos pedagógicos más utilizados por los docentes.
select count(*) as total_usos, rp.titulo_recurso from registro_recursos rr
join recurso_pedagogico rp on rp.id_recurso = rr.id_recurso
group by rp.id_recurso, rp.titulo_recurso
order by total_usos desc;
--18. Consultar el historial de modificaciones realizadas sobre las planificaciones curriculares
select hp.id_planificacion, hp.estado_anterior, hp.estado_nuevo, hp.fecha_cambio, hp.usuario_responsable, c.id_curso, a.id_asignatura, c.ano_academico from historial_planificacion hp
join planificaciones p on p.id_planificacion = hp.id_planificacion
join asignacion_academica aa on aa.id_asignacion = p.id_asignacion
join docente d on d.id_docente = aa.id_docente
join cursos c on c.id_curso = aa.id_curso
join asignaturas a on a.id_asignatura = aa.id_asignatura
order by hp.id_planificacion, hp.fecha_cambio;
--19. Obtener reportes relacionados con el cumplimiento de las planificaciones curriculares por curso y docente
select d.nombre, d.apellido, c.nombre_curso, p.estado, count(*) as total from planificaciones p
join asignacion_academica aa on aa.id_asignacion = p.id_asignacion
join docente d on d.id_docente = aa.id_docente
join cursos c on c.id_curso = aa.id_curso
group by d.nombre, d.apellido, c.nombre_curso, p.estado;
--20. Consultar los recursos disponibles en el Baúl de Contenidos según tipo de recurso educativo.
select rp.id_recurso, rp.titulo_recurso, rp.id_asignatura, rp.id_contenido, rp.url_archivo, tr.id_tipo_recurso, tr.nombre_tipo from recurso_pedagogico rp
join tipo_recurso tr on tr.id_tipo_recurso = rp.id_tipo_recurso
where tr.nombre_tipo = 'Guía de Trabajo';
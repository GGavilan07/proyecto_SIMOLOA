create table nivel_educativo (
    id_nivel varchar primary key,
    nombre_nivel varchar not null
);

create table docente (
    id_docente varchar primary key,
    nombre varchar not null,
    apellido varchar not null,
    correo varchar unique not null
);

create table asignaturas (
    id_asignatura varchar primary key,
    nombre_asignatura varchar not null
);
-- 1. forzar el correo del docente a minusculas
create or replace function trg_formato_correo() returns trigger as $$
begin
    new.correo := lower(new.correo);
    return new;
end;
$$ language plpgsql;

create trigger tr_formato_correo
before insert or update on docente
for each row execute function trg_formato_correo();

-- 2. evitar fechas de clases en el futuro
create or replace function trg_fecha_clase() returns trigger as $$
begin
    if new.fecha_clase > current_date then
        raise exception 'error: la fecha de la clase no puede ser mayor a la fecha actual.';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger tr_fecha_clase
before insert or update on clases
for each row execute function trg_fecha_clase();

-- 3. evitar fechas de evaluaciones en el futuro
create or replace function trg_fecha_evaluacion() returns trigger as $$
begin
    if new.fecha_realizacion > current_date then
        raise exception 'error: la fecha de realizacion de la evaluacion no puede ser futura.';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger tr_fecha_evaluacion
before insert or update on evaluaciones
for each row execute function trg_fecha_evaluacion();

-- 4. validar que el año academico sea logico
create or replace function trg_validar_ano() returns trigger as $$
begin
    if new.ano_academico < 2000 then
        raise exception 'error: el año academico ingresado no es valido.';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger tr_validar_ano
before insert or update on cursos
for each row execute function trg_validar_ano();

-- 5. bloquear clases con planificaciones no aprobadas
create or replace function trg_clase_planificacion_aprobada() returns trigger as $$
declare
    v_estado varchar;
begin
    select estado into v_estado from planificaciones where id_planificacion = new.id_planificacion;
    
    if v_estado != 'aprobada' then
        raise exception 'error: no se puede registrar una clase si su planificacion esta %.', v_estado;
    end if;
    
    return new;
end;
$$ language plpgsql;

create trigger tr_clase_planificacion_aprobada
before insert on clases
for each row execute function trg_clase_planificacion_aprobada();

--procedimiento 1: aprobar una planificacion
create or replace procedure aprobarplanificacion(in p_id_plan varchar)
language plpgsql
as $$
begin
    update planificaciones
    set estado = 'aprobada'
    where id_planificacion = p_id_plan;
end;
$$;

--procedimiento 2: registrar una nueva planificacion
create or replace procedure registrarplanificacion(in p_id_plan varchar, in p_id_asig varchar)
language plpgsql
as $$
begin
    insert into planificaciones (id_planificacion, id_asignacion, estado, fecha_creacion)
    values (p_id_plan, p_id_asig, 'pendiente', current_date);
end;
$$;

--procedimiento 3: registrar una nueva clase
create or replace procedure registrarclase(in p_id_clase varchar, in p_id_plan varchar, in p_fecha date, in p_periodo varchar)
language plpgsql
as $$
begin
    insert into clases (id_clase, id_planificacion, fecha_clase, periodo_academico)
    values (p_id_clase, p_id_plan, p_fecha, p_periodo);
end;
$$;

create table tipo_recurso (
    id_tipo_recurso varchar primary key,
    nombre_tipo varchar not null
);

create table cursos (
    id_curso varchar primary key,
    nombre_curso varchar not null,
    id_nivel varchar not null references nivel_educativo(id_nivel),
    ano_academico int not null
);

create table asignacion_academica (
    id_asignacion varchar primary key,
    id_docente varchar not null references docente(id_docente),
    id_curso varchar not null references cursos(id_curso),
    id_asignatura varchar not null references asignaturas(id_asignatura)
);

create table objetivos_aprendizaje (
    id_objetivos varchar primary key,
    descripcion text not null,
    id_nivel varchar not null references nivel_educativo(id_nivel),
    id_asignatura varchar not null references asignaturas(id_asignatura)
);

create table contenidos_curriculares (
    id_contenido varchar primary key,
    descripcion text not null,
    id_asignatura varchar not null references asignaturas(id_asignatura),
    id_nivel varchar not null references nivel_educativo(id_nivel),
	id_objetivos varchar references objetivos_aprendizaje(id_objetivos)
);

create table planificaciones (
    id_planificacion varchar primary key,
    id_asignacion varchar not null references asignacion_academica(id_asignacion),
    estado varchar not null check (estado in ('pendiente', 'aprobada', 'rechazada')),
    fecha_creacion date not null
);

create table planificacion_detalle (
    id_planificacion varchar not null references planificaciones(id_planificacion),
    id_contenido varchar not null references contenidos_curriculares(id_contenido),
	primary key (id_planificacion, id_contenido)
);

create table clases (
    id_clase varchar primary key,
    id_planificacion varchar not null references planificaciones(id_planificacion),
    fecha_clase date not null,
    periodo_academico varchar not null
);

create table clase_contenido (
    id_clase varchar not null references clases(id_clase),
    id_contenido varchar not null references contenidos_curriculares(id_contenido),
	primary key (id_clase, id_contenido)
);

create table preguntas (
    id_pregunta varchar primary key,
    enunciado text not null,
    id_asignatura varchar not null references asignaturas(id_asignatura),
    id_nivel varchar not null references nivel_educativo(id_nivel),
    id_contenido varchar not null references contenidos_curriculares(id_contenido),
    id_objetivos varchar not null references objetivos_aprendizaje(id_objetivos)
);

create table evaluaciones (
    id_evaluacion varchar primary key,
    id_docente varchar not null references docente(id_docente),
    id_curso varchar not null references cursos(id_curso),
    id_asignatura varchar not null references asignaturas(id_asignatura),
    fecha_realizacion date not null
);

create table evaluacion_pregunta (
    id_evaluacion varchar not null references evaluaciones(id_evaluacion),
    id_pregunta varchar not null references preguntas(id_pregunta),
	primary key (id_evaluacion, id_pregunta)
);

create table recurso_pedagogico (
    id_recurso varchar primary key,
    titulo_recurso varchar not null,
    id_tipo_recurso varchar not null references tipo_recurso(id_tipo_recurso),
    id_asignatura varchar not null references asignaturas(id_asignatura),
    id_contenido varchar not null references contenidos_curriculares(id_contenido),
    id_objetivos varchar not null references objetivos_aprendizaje(id_objetivos),
    url_archivo varchar not null
);

create table registro_recursos (
    id_uso varchar primary key,
    id_recurso varchar not null references recurso_pedagogico(id_recurso),
    id_docente varchar not null references docente(id_docente),
    fecha_uso date not null
);

create table historial_planificacion (
    id_historial varchar primary key,
    id_planificacion varchar not null references planificaciones(id_planificacion),
    estado_anterior varchar,
    estado_nuevo varchar not null,
    fecha_cambio timestamp not null,
    usuario_responsable varchar
);


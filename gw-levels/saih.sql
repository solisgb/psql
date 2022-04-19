- ===========================importar datos saih============================================
create schema saih;

create table saih.est (
	id varchar primary key,
	"name" varchar unique,
	x float4,
	y float4,
	z float4,
	z2 float4,
	tm varchar,
	prov varchar
)
;

select AddGeometryColumn ('saih', 'est', 'geom', 25830, 'POINT',2);

create index on saih.est using gist (geom);

update saih.est set geom = st_setsrid(st_makepoint(x, y), 25830);

alter table saih.est drop column x, drop column y;

copy saih.est from 'H:\LSGB\20220324_informe_pz\data_chs\saih\saih.csv' with CSV header delimiter ',' encoding 'UTF-8';

comment on table saih.est is 'Estaciones saih';
comment on column saih.est.id is 'Identificados único de la estación';
comment on column saih.est.name is 'Nombre';
comment on column saih.est.z is 'Z m s.n.m.';
comment on column saih.est.z2 is 'Z borde de la entubación m s.n.m.';
comment on column saih.est.tm is 'Término municipal';
comment on column saih.est.prov is 'Provincia';
comment on column saih.est.geom is 'Geometría epsg 25830';

alter table saih.est add column tipo varchar;
comment on column saih.est.tipo is 'Tipo de estación según los datos que mide';

update saih.est 
set tipo = 'pz_calidad'
where id <> '06a03'
returning *
;

create table saih.hgeo (
	id varchar,
	fecha timestamp,
	cnp real,
	t real,
	conduc real,
	salinidad real,
	tsd real,
	primary key (id, fecha)
);

comment on table saih.hgeo is 'Estaciones con sensores hidrogeológicos en un sondeo';
comment on column saih.hgeo.id is 'Identificados único de la estación';
comment on column saih.hgeo.fecha is 'Fcha tipo timestamp';
comment on column saih.hgeo.cnp is 'Cota piezométrica m s.n.m.';
comment on column saih.hgeo.t is 'Temperatura del agua ºC';
comment on column saih.hgeo.conduc is 'Conductividad del agua microS/cm';
comment on column saih.hgeo.salinidad is 'Salininidad del agua mg/l';
comment on column saih.hgeo.tsd is 'Total sólidos disueltos mg/l';


create table tmp.hgeo (
	id varchar,
	fecha timestamp,
	cnp real,
	t real,
	conduc real,
	salinidad real,
	tsd real
);


copy tmp.hgeo from 'H:\LSGB\20220324_informe_pz\data_chs\saih_another_format\SAIH_pz_Mar_Menor_20220303_2db.csv' 
	with CSV header delimiter ',' encoding 'UTF-8';

insert into saih.hgeo
select t.id, t.fecha, max(t.cnp) cnp, max(t.t) t, max(t.conduc) conduc, max(t.salinidad) salinidad, max(t.tsd) tsd
from tmp.hgeo t
group by t.id, t.fecha
;

create table saih.pp (
	id varchar,
	fecha timestamp,
	pp real,
	primary key (id, fecha)
);

comment on table saih.pp is 'Estaciones con sensores precipitacióno';
comment on column saih.pp.id is 'Identificados único de la estación';
comment on column saih.pp.fecha is 'Fecha timestamp de la medida';
comment on column saih.pp.pp is 'Precipitación mm';


create table tmp.pp (
	id varchar,
	fecha timestamp,
	pp real
);

copy tmp.pp from 'H:\LSGB\20220324_informe_pz\data_chs\saih\pp_mmenor_saih.csv' with CSV header delimiter ',' encoding 'UTF-8';

insert into saih.pp
select t.id , t.fecha, max(t.pp) pp
from tmp.pp t
group by t.id , t.fecha
;

select *
from saih.hgeo
where id = 'SM01'
;

--update saih.hgeo 
set id = '06z21'
where id = 'SM21'
;

insert into saih.est
values
	('06P05', 'San Javier El Mirador', 73, NULL, 'San Javier', 'Murcia', st_setsrid(st_makepoint(686931, 4189742), 25830), 'pp'),
	('06A01', 'Rambla del Albujón La Puebla', 19, NULL, 'Cartagena', 'Murcia', st_setsrid(st_makepoint(683796, 4176860), 25830), 'pp')
;

update saih.est 
set id = lower(id) ;


with pz as (
select id, geom 
from est 
where tipo ~ 'pz'), 
pp as (
select id, geom 
from est 
where tipo = 'pp')
select t1.id piez, t2.id , st_distance(t1.geom, t2.geom) 
from pz t1, pp t2
order by t1.id, st_distance(t1.geom, t2.geom)
;


with pz as (
select id, geom 
from est 
where tipo ~ 'pz'), 
pp as (
select id, geom 
from est 
where tipo = 'pp')
select t1.id piez, 
	split_part(min(concat(st_distance(t1.geom, t2.geom), ' - ', t2.id)), ' - ', 2) pp, 
	split_part(min(concat(st_distance(t1.geom, t2.geom), ' - ', t2.id)), ' - ', 1) distance
from pz t1, pp t2
group by t1.id
order by t1.id
;


create table saih.pz_pp_min_distance as 
with pz as (
select id, geom 
from est 
where tipo ~ 'pz'), 
pp as (
select id, geom 
from est 
where tipo = 'pp')
select t1.id piez, 
	split_part(min(concat(st_distance(t1.geom, t2.geom), ' - ', t2.id)), ' - ', 2) pp, 
	split_part(min(concat(st_distance(t1.geom, t2.geom), ' - ', t2.id)), ' - ', 1) distance
from pz t1, pp t2
group by t1.id
order by t1.id
;

comment on table saih.pz_pp_min_distance is 'Distancia mínima entre sondeos y estaciones pluviométricas';
comment on column saih.pz_pp_min_distance.piez is 'Identicador del sondeo';
comment on column saih.pz_pp_min_distance.pp is 'Identicador del pluviómetro';
comment on column saih.pz_pp_min_distance.distance is 'Distancia m';

select t.id, min(t.fecha), max(t.fecha) , count(*)
from saih.pp t
group by t.id ;

-- update saih.pp
set id = lower(id) 
;

select t.fecha, t.pp
from saih.pp t
where id = '06a18p01' and fecha > '2020-01-01' and  fecha < '2022-01-01'
order by t.fecha;

create table saih.ed (
	id varchar,
	fecha date,
	pp real not null,
	primary key (id, fecha)
);

comment on table saih.pp is 'Eventos de precipitación en id';
comment on column saih.pp.id is 'Identificados único de la estación';
comment on column saih.pp.fecha is 'Fecha -date- de la medida';
comment on column saih.pp.pp is 'Precipitación mm';

copy saih.ed from 'H:\LSGB\20220324_informe_pz\data_chs\saih\newfmt\data_events.csv' with CSV header delimiter ',' encoding 'UTF-8';

update saih.ed t 
set id = lower(id)
;


select id, fecha , round((cnp/1000.)::numeric, 2)
from saih.hgeo
where id = '06z01'
order by fecha;


update saih.hgeo
set cnp = round((cnp/1000.)::numeric, 2)
;


- ====================Preparación de las select para el gráfico=========================================
-- puntos que voy representar
select id, name, st_x(geom) x, st_y(geom) y
from saih.est e 
where e.tipo = 'pz_calidad'
;

-- datos piezométricos de un punto
select fecha::date, avg(cnp) cnp
from saih.hgeo t2 
where id = '06z03'
group by fecha::date
order by fecha::date --to_char("fecha", 'YYYY-MM-DD')
;

-- pluviómetro relacionado
select t.pp 
from saih.pz_pp_min_distance t
where t.piez = '06z07'
;

-- compruebo las estaciones de eventos de pp
select distinct t.pp 
from saih.pz_pp_min_distance t 
order by t.pp ;

-- datos pluviométricos
select t.fecha , t.pp 
from saih.ed t
where t.id = '06p05' and t.fecha > '2019-01-01' and t.fecha < '2022-01-01'
order by t.fecha 
;

select *
from saih.est e 
order by id;

update saih.est
set "name" = 'sm21'
where "name" = 'sm021'
returning *
;

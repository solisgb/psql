/* importaci�n de datos de calidad de aguas superficiales de la p�g. web de la CHS
   los datos que se descargan de la web tienen filas repetidas


Cabeceras de columnas en los ficheros de la CHS y sus equivalentes en la tabla de informaci�n
C�d. Par�metro   id_par
Nombre Par�metro par_name
UTMX_ETRS89      x
UTMY_ETRS89      y
Cod. Masa        id_mas
Nombre Masa      mas_name
ANSPFMUES        fmues
PMSPCOD          id_punto
PMSPNOM          punto_name
DESPVALORN       valorn
DESPVALORT       valort
Unidades         uds
Matriz           matriz
Profundidad      prof
*/


-- Creo una tabla para almacenar los ficheros csv
create table if not exists tmp.casup (
	gid serial primary key,
	"id_par" varchar not null,
	"par_name" varchar,
	"x" float4 not null,
	"y" float4 not null,
	"id_mas" varchar not null,
	"mas_name" varchar,
	"fmues" varchar,
	"id_punto" varchar not null,
	"punto_name" varchar,
	"valorn" varchar not null,
	"valort" varchar,
	"uds" varchar not null,
	"matriz" varchar,
	"prof" float4 
)
;

-- compruebo OK
select column_name , data_type 
from information_schema.columns 
where table_name = 'casup' and table_schema = 'tmp'
;

/* La importaci�n se realiza desde ficheros csv con psql
   \copy tmp.casup from 'H:\IGME2020\20220311_Se_Comisaria_CHS\datos_desde_1985\andalucia_fq_1985_2021.csv' with CSV header delimiter ',' encoding 'UTF-8'
 */ 

-- 1.- creo la tabla geoespacial de puntos de toma en aguas superficiales
create table quim.w2_puntos_sup(
	gid serial primary key,
	id varchar unique,
	"name" varchar,  
	x float4,
	y float4,
	id_mas varchar
)
;

comment on table quim.w2_puntos_sup is 'Puntos de toma de aguas superficiales red de control CHS';
comment on column quim.w2_puntos_sup.gid is 'Idetificados �nico';
comment on column quim.w2_puntos_sup.id is 'C�digo del pnto de toma';
comment on column quim.w2_puntos_sup.name is 'Nombre';
comment on column quim.w2_puntos_sup.gid is 'Masa de agua superficial asignada por CHS';


insert into quim.w2_puntos_sup (id, name, x, y, id_mas)
	select lower(trim(p.id_punto)) id, max(p.punto_name) name , avg(p.x) x , avg(p.y) y , max(lower(trim(p.id_mas))) id_mas
	from tmp.casup p 
	group by lower(trim(p.id_punto))
	order by lower(trim(p.id_punto))
on conflict 
	do nothing
;

-- creo una columna espacial (postgis)
select AddGeometryColumn ('quim', 'w2_puntos_sup', 'geom',25830, 'POINT', 2);

-- la relleno
update quim.w2_puntos_sup
set geom = st_setsrid(st_makepoint(x, y), 25830)
;

-- creo el �ndice
create index on quim.w2_puntos_sup using gist (geom)
;

-- elimino las columnas x y
alter table quim.w2_puntos_sup
	drop column x,
	drop column y
;

/* 2. Creo tabla de par�metros 
 * El mismo par�metro puede tener determinaciones con uds distintas;
 * Mantengo los valores de los par�etros sin tocar y las uds las dejo en la tabla de determinaciones
 * Hay par�metros con unidades qe difieren s�lo en min�culas/may�scula, por ejemplo mg/l y mg/l
 */

select lower(trim(t.id_par)) id, max(trim(t.par_name)) "name" 
from tmp.casup t
group by lower(trim(t.id_par))
order by lower(trim(t.id_par))
;

select max(length(t.id_par))
from tmp.casup t
;

create table quim.w2_parametros_sup (
	id varchar primary key,
	"name" varchar unique 
)
;

comment on table quim.w2_parametros_sup is 'Par�metros medidos en la red de control CHS de calidad de aguas superficiales';
comment on column quim.w2_parametros_sup.id is 'Idetificados �nico';
comment on column quim.w2_parametros_sup.name is 'Decriptos del identificador';

insert into quim.w2_parametros_sup
	select lower(trim(t.id_par)) id, max(trim(t.par_name)) "name" 
	from tmp.casup t
	group by lower(trim(t.id_par))
	order by lower(trim(t.id_par))
on conflict 
	do nothing
;

/* 3. Creao la tabla de masas de agua superfical 
 * Los c�digos no coinciden exactamente con los que se indican en la tabla albergada en idee)
 */

select lower(trim(t.id_mas)) id, max(trim(t.mas_name)) "name" 
from tmp.casup t
group by lower(trim(t.id_mas))
order by lower(trim(t.id_mas))
;

select max(length(lower(trim(t.id_mas))))
from tmp.quim_asup t
;

create table quim.w2_masup (
	id varchar primary key,
	"name" varchar unique 
)
;

comment on table quim.w2_masup is 'Masas de agua superficial con puntos de muestreo en la red de control CHS de calidad de aguas superficiales';
comment on column quim.w2_masup.id is 'Idetificados �nico';
comment on column quim.w2_masup.name is 'Descriptor del identificador';

insert into quim.w2_masup
	select lower(trim(t.id_mas)) id, max(trim(t.mas_name)) "name" 
	from tmp.casup t
	group by lower(trim(t.id_mas))
	order by lower(trim(t.id_mas))
on conflict 
	do nothing
;


/* 4. Creo tabla de determinaciones f�sico qu�micas en las masas de agua superfical de la CHS 
Esta tabla tiene problemas de unicidad
Considerando como restricci�n unique las columnas 
id_punto, fmues, id_par, valort , uds , prof
nos encontramos filas repetidas con valores DIFERENTES de la columna valorn
El total de filas repetidas (algunas m�s de dos veces, es de 401 y se localizan en 70 estaciones de 
control  
Tambi�n encuentro caso de que el valorn y el valort (sin considerar los
que contienen un valor < al principio) son diferentes

Lo anterior se pone de manifiesto en la siguiente select

Pendiente: hay par�metros que tienen determinaciones en diferentes unidades, habr�a que poner todas
las determinaciones de cada par�metro en las mismas unidades, eliminar la columna uds de esta tabla y
a�adirla a determinaciones
*/

select lower(trim(t.id_punto)) id_punto , t.fmues::date fmuestreo, lower(trim(t.id_par)) id_par , 
	replace(replace(t.valort,'.',''), ',','.') valort , lower(trim(t.uds)) uds , t.prof ,
	max(replace(replace(t.valorn,'.',''), ',','.'))::float4 valorn, 
	min(replace(replace(t.valorn,'.',''), ',','.'))::float4, 
	max(replace(replace(t.valorn,'.',''), ',','.')::float4) - min(replace(replace(t.valorn,'.',''), ',','.'))::float4 diferencia,
	count(*)
from tmp.casup t
group by lower(trim(t.id_punto)) , t.fmues::date, lower(trim(t.id_par)) , 
	replace(replace(t.valort,'.',''), ',','.') , lower(trim(t.uds)) , t.prof
having max(replace(replace(t.valorn,'.',''), ',','.'))::float4 - min(replace(replace(t.valorn,'.',''), ',','.'))::float4 > 0.1
order by count(*) desc
;

-- Voy a probar igualando el valorn al valorn cuando no contiene el s�mbolo <
-- para lo que primero a�ado una columna
alter table tmp.casup 
add column valort_original varchar 
;

-- La relleno con los valores originales (que despu�s voy a modificar)
update tmp.casup
set valort_original = trim(valort)
;

update tmp.casup
set valort =  valorn
where substring(valort_original, 1, 1) <> '<'
;

-- Al ejecutar la select arriba comrpruebo que todos los registros son diferentes con 
-- la condici�n unique id_punto, fmues, id_par, valort , uds , prof

-- Ahora ya puedo crear la tabla

create table quim.w2_det_sup (
	id serial primary key,
	id_punto varchar,
	fecha date,
	id_par varchar,
	valort varchar,
	uds varchar,
	prof varchar,
	matriz varchar,
	valorn real,
	unique (id_punto, fecha, id_par, valort, uds, prof)
)
;

comment on table quim.w2_det_sup is 'Determinaciones anal�ticas en aguas superficiales CHS';
comment on column quim.w2_det_sup.id is 'Autonum�rico clave principal';
comment on column quim.w2_det_sup.id_punto is 'Identificados del punto de toma';
comment on column quim.w2_det_sup.fecha is 'Fecha de muestreo';
comment on column quim.w2_det_sup.id_par is 'Identificador del par�metro analizado';
comment on column quim.w2_det_sup.valort is 'Valor de la determinaci�n de id_par como texto; incluye unmbral de detecci�n como <0.1 e incluso alguna otra aclaraci�n';
comment on column quim.w2_det_sup.prof is 'Profundidad a la que se toma la muestra desde la superficie del agua, posiblemente en metros';
comment on column quim.w2_det_sup.matriz is 'Matriz de la muestra';
comment on column quim.w2_det_sup.valorn is 'Valor num�rico de valort';

insert into quim.w2_det_sup (id_punto, fecha, id_par, valort, uds, prof, valorn, matriz) 
	select lower(trim(t.id_punto)) id , t.fmues::date fmuestreo, lower(trim(t.id_par)) id_par , 
		replace(replace(t.valort,'.',''), ',','.') valort , lower(trim(t.uds)) uds , t.prof ,
		replace(replace(t.valorn,'.',''), ',','.')::float4 valorn, lower(trim(t.matriz)) matriz
	from tmp.casup t
on conflict 
	do nothing
;

select count(*)
from quim.w2_det_sup
;

-- las profundidades de toma se dan como valores negativos, lo que supondr�a que se toma
-- la muestra fuera del agua, por lo que lo paso a valores positivos 
select count(*)
from quim.w2_det_sup
where prof::float<0 
;

update quim.w2_det_sup
set prof = trim(replace(prof,'-',''))
where prof::float<0 
;

/* Integridades referenciales
 */
alter table quim.w2_puntos_sup 
add foreign key (id_mas) 
references quim.w2_masup (id)
;

alter table quim.w2_det_sup 
add foreign key (id_par) 
references quim.w2_parametros_sup (id)
;

alter table quim.w2_det_sup 
add foreign key (id_punto) 
references quim.w2_puntos_sup (id)
;

-- 5. 1. Arreglar unidades
select t.id_par , t.uds , count(*)
from quim.w2_det_sup t
group by t.id_par , t.uds 
order by t.id_par , t.uds
;

update quim.w2_det_sup t
set uds = '�c'
where t.id_par = 'temper' and t.uds = '�s/cm'
returning *
;

-- Homogeneizar unidades 
with p as (
	select t.id_par , t.uds
	from quim.w2_det_sup t
	group by t.id_par , t.uds 
	order by t.id_par , t.uds
)
select p.id_par, count(p.id_par)
from p
group by p.id_par 
having count(p.id_par) > 1
order by p.id_par
;

/* Los par�metros con distintas unidades son
"id_par","count"
b,2
cn,2
fluoru_2,2
nitrat_2,2
nitrit_2,2
phcamp,2
*/

select t.id_par , t.uds, min(t.fecha) , max(t.fecha) , min(t.valort) t , max(t.valort ) t, count(*)
from quim.w2_det_sup t
where t.id_par = 'b'
group by t.id_par , t.uds 
order by t.id_par , t.uds
;

/*
Resultado
|id_par|uds |min       |max       |min|max  |count|
|------|----|----------|----------|---|-----|-----|
|b     |�g/l|1993-04-20|2021-08-16|0  |8,390|3,879|
|b     |mg/l|2021-08-05|2021-11-23|0  |6,400|27   |

*
*
**/
select t.valort, t.valorn 
from quim.w2_det_sup t
where t.id_par = 'b' and t.uds = '�g/l' and t.valort ~ '^<'
group by t.valort, t.valorn
;






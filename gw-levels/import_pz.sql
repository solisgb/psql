-- piezometria 2021 CHS

-- 1.- Datos meteorologicos (p mes)

-- Últimos datos cargados
select t.indic , t.fecha , t.prec 
from met.pmes t 
order by t.fecha desc limit 25
;

-- 2. Datos piezométricos

/*
 
Fichero csv              | Nombre columna
------------------------------------------
MASA                     | mas
Masa de Agua             | name_mas
Cod. MITERD              | id
COD_OPH                  | id_oph
Nombre                   | name_id
Demarcación Hidrográfica | dh
Fecha Alta               | freg
Profundidad obra (m)     | prof_obra
Municipio                | tm
Cota                     | z_ref
X(ETRS89)                | x
Y(ETRS89)                | y
Fecha                    | fmed
Nivel                    | pnp
PNP                      | cnp
                         | strmp
*/

drop table if exists tmp.chspz;

create table if not exists tmp.chspz (
	mas varchar,
	name_mas varchar,
	id varchar,
	id_oph varchar,
	name_id varchar,
	dh varchar,
	freg date,
	prof_obra varchar,
	tm varchar,
	z_ref float4,
	x float4,
	y float4,
	fmed varchar,
	pnp varchar,
	cnp varchar,
	strtmp varchar
)
;

-- importo datos
delete from tmp.chspz;

copy tmp.chspz 
from 'H:\IGME2020\_pz_manzano\20220324_informe_pz\data_chs\Piezometria_Red_oficial_a_28_02_2022.csv' 
with CSV header delimiter ',' 
encoding 'UTF-8'
;

-- Revisión de columnas numéricas prof y pnp
select *
from tmp.chspz t 
where t.pnp !~ '^[0-9\.]+$'
order by t.fmed  desc
;

update tmp.chspz t
set prof_obra = null
where t.prof_obra !~ '^[0-9\.]+$'
;

delete from tmp.chspz
where pnp !~ '^[0-9\.]+$'
returning *
;

-- Arreglo de la columna fmed , el problema es que las fechas están formadas de 2 maneras diferentes
select concat(split_part(fmed, '/', 3), '-', split_part(fmed, '/', 1), '-', split_part(fmed, '/', 2), ' 00:00:00')::timestamp fmed1 
from tmp.chspz t
where fmed ~ '/' --mm/dd/yyyy
;

update tmp.chspz t 
set strtmp = concat(split_part(fmed, '/', 3), '-', split_part(fmed, '/', 1), '-', split_part(fmed, '/', 2), ' 00:00:00')
where fmed ~ '/'
returning strtmp::timestamp 
;

select concat(split_part(fmed, '-', 3), '-', split_part(fmed, '-', 2), '-', trim(split_part(fmed, '-', 1)), ' 00:00:00')::timestamp fmed1
from tmp.chspz t
where fmed ~ '-' --dd/mm/yyyy
;

update tmp.chspz t 
set strtmp = concat(split_part(fmed, '-', 3), '-', split_part(fmed, '-', 2), '-', trim(split_part(fmed, '-', 1)), ' 00:00:00')
where fmed ~ '-'
returning strtmp::timestamp 
;

select t.strtmp:: timestamptz fmed1 
from tmp.chspz t
;

-- table intermedia
create table tmp.ipa2 as 
select *
from ipas.ipa2 
with no data
;

alter table tmp.ipa2
add primary key (cod, fecha)
;

-- primero relleno la tabla ipa2 en el esquema tmp a partir de los datos facilitados en hoja de cálculo 
insert into tmp.ipa2 (cod, fecha, situacion, pnp, instalado, tuboguia, tr, proyecto, codigosonda, medidor, pnp_original)
select t.id , t.strtmp::timestamp , 'e', t.pnp::real , 't', 't', 0, 'chs_red_pz', NULL, NULL, t.pnp::real
from tmp.chspz t
on conflict do nothing
;

update tmp.ipa2
set cod = trim(cod) 
;

-- ahora tengo que sustituir id oficial por id tipo igme

-- primero veo si están todos
select t1.cod , t1.cod_red , t1.red , t1.fecha_alta , t1.fecha_baja 
from ipas.ipa1_red_control t1 
where t1.red = 'chspz'
;

select distinct t.cod, t1.cod  
from tmp.ipa2 t
	left join ipas.ipa1_red_control t1 on (t.cod = t1.cod_red) 
where t1.red = 'chspz'
order by t.cod 
;

-- están todos, ahora puedo insertar los datos en ipa2

-- veo un resumen de lo último que tengo cargado
select extract(year from t.fecha) "year", extract(month from t.fecha) "month" , count(*)
from ipas.ipa2 t
where t.fecha > '2020-06-06'
group by extract(year from t.fecha), extract(month from t.fecha)
order by extract(year from t.fecha), extract(month from t.fecha)
;
/*
|year |month|count|
|-----|-----|-----|
|2,020|6    |82   |
|2,020|7    |124  |
|2,020|8    |127  |
|2,020|9    |64   |
|2,020|10   |116  |
|2,020|11   |81   |
|2,020|12   |109  |
|2,021|1    |81   |
|2,021|2    |95   |
|2,021|3    |130  |
|2,021|4    |106  |
|2,021|5    |109  |
|2,021|6    |43   |
|2,021|7    |121  |
|2,021|8    |119  |
|2,021|9    |31   |
 */


-- lo que voya insertar
select t1.cod , t2.fecha , t2.situacion , t2.pnp , t2.instalado , t2.tuboguia , t2.tr ,
	t2.proyecto , t2.pnp_original 
from tmp.ipa2 t2
	left join ipas.ipa1_red_control t1 on (t2.cod = t1.cod_red) 
where t1.red = 'chspz' and t2.fecha > '2020-01-01'
;

-- ahora inserto
insert into ipas.ipa2 (cod , fecha , situacion , pnp , instalado , tuboguia , tr ,
	proyecto , pnp_original) 
	select t1.cod , t2.fecha , t2.situacion , t2.pnp , t2.instalado , t2.tuboguia , t2.tr ,
		t2.proyecto , t2.pnp_original 
	from tmp.ipa2 t2
		left join ipas.ipa1_red_control t1 on (t2.cod = t1.cod_red) 
	where t1.red = 'chspz' and t2.fecha > '2020-01-01'
on conflict on constraint ipa2_pkey
do update set pnp_original = excluded.pnp 
;

-- piezometros chs mar menor
create table if not exists ipas.ipa1_pzchsmm (
	id varchar primary key,
	name varchar,
	x real,
	y real,
	z real,
	zref real,
	"ref" varchar,
	tm	varchar,
	prov varchar
)
;

copy ipas.ipa1_pzchsmm
from 'H:\IGME2020\data2db\sondeos_red_control_mm.csv' 
with CSV header delimiter ';' 
encoding 'UTF-8'
;

select AddGeometryColumn ('ipas','ipa1_pzchsmm','geom', 25830,'POINT',2);
create index on ipas.ipa1_pzchsmm using gist (geom);
update ipas.ipa1_pzchsmm set geom = st_setsrid(st_makepoint(x, y), 25830);

alter table ipas.ipa1_pzchsmm drop column x;

alter table ipas.ipa1_pzchsmm drop column y;

select *
from ipas.ipa1_pzchsmm
;






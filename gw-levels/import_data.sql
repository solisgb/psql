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

-- ahora tengo que sustituir id oficial por id tipo igme


-- primero veo si están todos
select 
from tmp.ipa2 i 
	join 




--insert into tmp.ipa2 (cod, fecha, situacion, pnp, instalado, tuboguia, tr, proyecto, codigosonda, medidor, pnp_original) 
select t.cod, t2.fecha, t2.situacion, t2.pnp, t2.instalacionsn, t2.tuboguiasn, t2.tr, t2.proyecto, t2.codigosonda, t2.observ, t2.medidor, t2.pnp_original 
from tmp.ipa2 t
on conflict on constraint ipa2_pkey
do update set pnp_original = t.excluded.pnp_original
;





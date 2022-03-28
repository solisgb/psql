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

-- Ahora toca arreglar 
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








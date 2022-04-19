--================== INFORME PIEZO AÑO 2021 ===========================

-- Los datos piezométricos los tengo en dos tablas diferentes ipas.ipa2 y saih.hgeo
-- medidas read manual
select i2.cod, i2.fecha, i2.situacion, i2.pnp, i2.pnp_original original
from ipas.ipa2 i2 
where i2.fecha>'2021-01-01' AND i2.fecha < '2022-01-01' and i2.proyecto = 'chs_red_pz' and i2.situacion!='no'
order by i2.cod, i2.fecha 
;

-- pnp medio red manual
select msb.cod_mas masub , msb.nombre_mas nombre, rc.cod_red id, avg(i2.pnp) pnp, stddev(i2.pnp) sdev, count(*) n_medidas, 'red manual' red
from ipas.ipa1 i1 
	join ipas.ipa2 i2 using(cod) 
	join ipas.ipa1_red_control rc using(cod)
	join idee.masub1621dhs msb on (i1.masub=msb.cod_mas)
where i2.fecha>'2021-01-01' AND i2.fecha < '2022-01-01' and i2.proyecto = 'chs_red_pz' and
	i2.situacion != 'no' and i2.situacion != 'd' and rc.red = 'chspz'
group by msb.cod_mas , msb.nombre_mas , rc.cod_red
order by msb.cod_mas , msb.nombre_mas , rc.cod_red --avg(i2.pnp) desc 
;

-- pnp medio red saih
select '070.052' masub, 'Campo de Cartagena' nombre, t1.id, avg(t1.z - t2.cnp) pnp,
	stddev(t1.z - t2.cnp) sdev, count(*) n_medidas, 'red saih' red 
from saih.est t1
	join saih.hgeo t2 using(id)
where t2.fecha >= '2021-01-01' and t2.fecha <= '2021-12-31'
group by t1.id
order by t1.id
;

-- ============ CONSULTA CONJUNTA ======================
-- creo una tabla temporal con la estructura deseada
create temp table if not exists ipa2_2021 (
masub character varying,
nombre character varying,
id character varying primary key,
pnp real not null,
sdev real,
n_medidas int,
red text
)
;

select column_name,data_type 
from information_schema.columns 
where table_name = 'ipa2_2021';

-- constraints 
select con.* 
from pg_catalog.pg_constraint con
	inner join pg_catalog.pg_class rel on rel.oid = con.conrelid
    inner join pg_catalog.pg_namespace nsp on nsp.oid = connamespace
where e = 'public' and rel.relname = 'ipa2_2021'
;

-- inserto los datos de las 2 tablas
insert into ipa2_2021
select msb.cod_mas masub , msb.nombre_mas nombre, rc.cod_red id, 
	avg(i2.pnp) pnp, stddev(i2.pnp) sdev, count(*) n_medidas, 'red manual' red
from ipas.ipa1 i1 
	join ipas.ipa2 i2 using(cod) 
	join ipas.ipa1_red_control rc using(cod)
	join idee.masub1621dhs msb on (i1.masub=msb.cod_mas)
where i2.fecha>'2021-01-01' AND i2.fecha < '2022-01-01' and i2.proyecto = 'chs_red_pz' and
	i2.situacion != 'no' and i2.situacion != 'd' and rc.red = 'chspz'
group by msb.cod_mas , msb.nombre_mas , rc.cod_red
order by msb.cod_mas , msb.nombre_mas , rc.cod_red
on conflict on constraint ipa2_2021_pkey do nothing
;

insert into ipa2_2021
select '070.052' masub, 'Campo de Cartagena' nombre, t1.id, avg(t1.z - t2.cnp) pnp,
	stddev(t1.z - t2.cnp) sdev, count(*) n_medidas, 'red saih' red 
from saih.est t1
	join saih.hgeo t2 using(id)
where t2.fecha >= '2021-01-01' and t2.fecha <= '2021-12-31'
group by t1.id
order by t1.id
on conflict on constraint ipa2_2021_pkey do nothing
;

-- num medidas por meses red manual
select extract(year from i2.fecha) año, extract(month from i2.fecha) mes, count(*)
from ipas.ipa2 i2 
where i2.fecha>'2021-01-01' AND i2.fecha < '2022-01-01' and i2.proyecto = 'chs_red_pz' and i2.situacion!='no'
group by extract(year from i2.fecha), extract(month from i2.fecha)
order by extract(year from i2.fecha), extract(month from i2.fecha)
;
/*
|año  |mes|count|
|-----|---|-----|
|2,021|1  |80   |
|2,021|2  |96   |
|2,021|3  |135  |
|2,021|4  |105  |
|2,021|5  |109  |
|2,021|6  |43   |
|2,021|7  |120  |
|2,021|8  |117  |
|2,021|9  |31   |
|2,021|10 |91   |
|2,021|11 |90   |
|2,021|12 |98   |
*/

-- num medidas totales = 1115 red manual
select count(*)
from ipas.ipa2 i2 
where i2.fecha>'2021-01-01' AND i2.fecha < '2022-01-01' and i2.proyecto = 'chs_red_pz' and i2.situacion!='no'
;

-- sondeos medidos en 2021 com geometría
-- de esta consulta se puede extraer profundidad del agua en los sondeos de la red 
with s1 as (
select distinct i2.cod, max(i2.pnp) max_pnp, min(i2.pnp) min_pnp, avg(i2.pnp) avg_pnp, count(*) nmedidas, max(i2.proyecto) 
from ipas.ipa2 i2 
where i2.fecha>'2021-01-01' AND i2.fecha < '2022-01-01' and i2.proyecto = 'chs_red_pz' and i2.situacion!='no'
group by i2.cod
)
select distinct irc.cod_red , s1.cod, i1.z-s1.max_pnp max_cnp, s1.max_pnp,
	i1.z-s1.min_pnp min_cnp, s1.min_pnp,
	i1.z-s1.avg_pnp avg_cnp, s1.avg_pnp,
	i1.geom
from ipas.ipa1 i1
	join s1 using(cod)
	left join ipas.ipa1_red_control irc using(cod)
where irc.red = 'chspz'
order by cod
;


-- profundidad media sondeos saih mar manor en 2021
select t1.id , t1.name, avg(t1.z - t2.cnp) avg_pnp_21 , max(t1.geom) geom 
from saih.est t1
	join saih.hgeo t2 using(id)
where t2.fecha >= '2021-01-01' and t2.fecha <= '2021-12-31'
group by t1.id , t1.name 
order by t1.id
;


-- Profundidad media en los sondeos medidos en 2021 com geometría en las MASUB
with s1 as (
select distinct i2.cod, max(i2.pnp) max_pnp, min(i2.pnp) min_pnp, avg(i2.pnp) avg_pnp, count(*) nmedidas, max(i2.proyecto) 
from ipas.ipa2 i2 
where i2.fecha>'2021-01-01' AND i2.fecha < '2022-01-01' and i2.proyecto = 'chs_red_pz' and i2.situacion!='no'
group by i2.cod
)
select distinct md.cod_mas , max(i1.z-s1.max_pnp) max_cnp, max(s1.max_pnp),
	max(i1.z-s1.min_pnp) min_cnp, max(s1.min_pnp),
	max(i1.z-s1.avg_pnp) avg_cnp, max(s1.avg_pnp),
	max(md.geom) geom
from ipas.ipa1 i1
	join s1 using(cod)
	left join ipas.ipa1_red_control irc using(cod)
	join idee.masub1621dhs md on(i1.masub=md.cod_mas)
where irc.red = 'chspz'
group by md.cod_mas
order by md.cod_mas
;

-- =============== VARIACIONES PIEZOMETRICAS MEDIAS ============================
-- ====================== 2021 - 2020 ==========================================
-- variación del pnp medio entre 2021 y 2020 con geometría; red manual
with s1 as ( 
select i2.cod cod, avg(i2.pnp) pnp_avg_2020
from ipas.ipa2 i2 
where i2.fecha>='2020-01-01' and i2.fecha<'2021-01-01' and i2.proyecto = 'chs_red_pz' and
	(i2.situacion!='no' or i2.situacion!='d')
group by i2.cod
order by i2.cod
),
s2 as (
select i2.cod cod, avg(i2.pnp) pnp_avg_2021
from ipas.ipa2 i2 
where i2.fecha>='2021-01-01' and i2.fecha<'2022-01-01' and i2.proyecto = 'chs_red_pz' and i2.situacion!='no'
group by i2.cod
order by i2.cod
)
select msb.cod_mas masub , msb.nombre_mas nombre , rc.cod_red sondeo, s2.pnp_avg_2021-pnp_avg_2020 pnp_var_2021_2020,
	i1.geom 
from ipas.ipa1 i1
	join s1 using(cod)
	join s2 using(cod)
	join idee.masub1621dhs msb on (i1.masub=msb.cod_mas)
	join ipas.ipa1_red_control rc using(cod)
where rc.red = 'chspz'	
order by msb.cod_mas , msb.nombre_mas , s2.cod
;

-- variación del pnp medio entre 2021 y 2020 con geometría; red saih mar menor
with s1 as ( 
select t2.id id, avg(t1.z - t2.cnp) pnp_avg_2020
from saih.est t1
	join saih.hgeo t2 using(id) 
where t2.fecha>='2020-01-01' and t2.fecha<'2021-01-01'
group by t2.id
order by t2.id
),
s2 as (
select t2.id id, avg(t1.z - t2.cnp) pnp_avg_20201
from saih.est t1
	join saih.hgeo t2 using(id) 
where t2.fecha>='2021-01-01' and t2.fecha<'2022-01-01'
group by t2.id
order by t2.id
)
select '070.052' masub, 'Campo de Cartagena' nombre, t1.id sondeo, s2.pnp_avg_20201 - s1.pnp_avg_2020 pnp_var_2021_2020,
	t1.geom 
from saih.est t1
	join s1 using(id)
	join s2 using(id)
order by t1.id --s2.pnp_avg_20201 - s1.pnp_avg_2020 --
;

-- ==================== 2021 - 2016 =============================
-- variación del pnp medio entre 2021 y 2016 con geometría; red manual
--                  en 2016 no había red saih
with s1 as ( 
select i2.cod cod, avg(i2.pnp) pnp_avg_2016
from ipas.ipa2 i2 
where i2.fecha>='2016-01-01' and i2.fecha<='2016-12-31' and i2.proyecto = 'chs_red_pz' and
	i2.situacion != 'no' and i2.situacion != 'd'
group by i2.cod
order by i2.cod
),
s2 as (
select i2.cod cod, avg(i2.pnp) pnp_avg_2021
from ipas.ipa2 i2 
where i2.fecha>='2021-01-01' and i2.fecha<='2021-12-31' and i2.proyecto = 'chs_red_pz' and 
	i2.situacion != 'no' and i2.situacion != 'd'
group by i2.cod
order by i2.cod
)
select msb.cod_mas masub , msb.nombre_mas nombre , rc.cod_red sondeo, 
	s2.pnp_avg_2021 - s1.pnp_avg_2016 as pnp_var_2021_16,
	i1.geom 
from ipas.ipa1 i1
	join s1 using(cod)
	join s2 using(cod)
	join idee.masub1621dhs msb on (i1.masub=msb.cod_mas)
	join ipas.ipa1_red_control rc using(cod)
where rc.red = 'chspz'	
order by msb.cod_mas , msb.nombre_mas , s2.cod
;

-- ===== VARIACIONES PIEZOMETRICAS MEDIAS MASUB (TABLAS SINTESIS)=====




-- ====================== 2021 - 2020 red manual======================
--              Esta select no incluye los sondeos del saih

with s1 as ( 
select i1.masub , avg(i2.pnp) pnp_avg_2020
from ipas.ipa1 i1
	join ipas.ipa2 i2 using(cod)
where i2.fecha>='2020-01-01' and i2.fecha<'2021-01-01' and i2.proyecto = 'chs_red_pz' and
	(i2.situacion!='no' or i2.situacion!='d')
group by i1.masub
order by i1.masub
),
s2 as (
select i1.masub, avg(i2.pnp) pnp_avg_2021
from ipas.ipa1 i1
	join ipas.ipa2 i2 using(cod)
where i2.fecha>='2021-01-01' and i2.fecha<'2022-01-01' and i2.proyecto = 'chs_red_pz' and i2.situacion!='no'
group by i1.masub
order by i1.masub
)
select msb.cod_mas , msb.nombre_mas ,
	s2.pnp_avg_2021-pnp_avg_2020 pnp_var_2021_2020, msb.geom
from idee.masub1621dhs msb
	join s1 on (msb.cod_mas = s1.masub)
	join s2 on (msb.cod_mas = s2.masub)
order by s1.masub
;

-- ============ sondeos saih (todos 070.052 ======================
-- ====================== 2021 - 2020 =====l======================
with s1 as ( 
select avg(t1.z - t2.cnp) pnp_avg_2020
from saih.est t1
	join saih.hgeo t2 using(id) 
where t2.fecha>='2020-01-01' and t2.fecha<'2021-01-01'
),
s2 as (
select avg(t1.z - t2.cnp) pnp_avg_20201
from saih.est t1
	join saih.hgeo t2 using(id) 
where t2.fecha>='2021-01-01' and t2.fecha<'2022-01-01'
)
select s2.pnp_avg_20201 - s1.pnp_avg_2020 pnp_var_2021_2020
from s1, s2
;

-- ============== VARIACIONES PIEZOMÉTRICAS EN LAS MASUB ==============
-- ====================== 2021 - 20216 red manual======================
--              En 2016 no funcionaban los sondeos del saih

with s1 as ( 
select i1.masub , avg(i2.pnp) pnp_avg_2016
from ipas.ipa1 i1
	join ipas.ipa2 i2 using(cod)
where i2.fecha>='2016-01-01' and i2.fecha<='2016-12-31' and i2.proyecto = 'chs_red_pz' and
	(i2.situacion!='no' or i2.situacion!='d')
group by i1.masub
order by i1.masub
),
s2 as (
select i1.masub, avg(i2.pnp) pnp_avg_2021
from ipas.ipa1 i1
	join ipas.ipa2 i2 using(cod)
where i2.fecha>='2021-01-01' and i2.fecha<'2022-01-01' and i2.proyecto = 'chs_red_pz' and i2.situacion!='no'
group by i1.masub
order by i1.masub
)
select msb.cod_mas , msb.nombre_mas ,
	s2.pnp_avg_2021 - pnp_avg_2016 pnp_var_2021_2016, msb.geom
from idee.masub1621dhs msb
	join s1 on (msb.cod_mas = s1.masub)
	join s2 on (msb.cod_mas = s2.masub)
order by s1.masub
; 

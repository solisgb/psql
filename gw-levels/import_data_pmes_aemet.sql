-- importar datos de p mensual facilitados por aemet a CCHH

create table if not exists tmp.aemet_2_oph_chs (
	indicativo varchar,
	año integer,
	mes integer,
	nombre varchar,
	altitud float,
	c_x float,
	c_y float,
	nom_prov varchar,
	pmes77 real
);

comment on table tmp.aemet_2_oph_chs is 'tabla con las  mismas columas que los ficheros csv que aemet envía a oph chs; los importo uno a uno y por orden de envío';

-- Iteraction: import files one by one and upsert

delete from tmp.aemet_2_oph_chs;

-- H:\IGME2020\_pz_manzano\20220324_informe_pz\aemet\2021_09_08_07_PrecMesSeg_utf8.csv
copy tmp.aemet_2_oph_chs from 'H:\IGME2020\_pz_manzano\20220324_informe_pz\aemet\2021_09_08_07_PrecMesSeg_utf8.csv' with CSV header delimiter ';' encoding 'UTF-8'

-- inspecciono la importación
select *
from tmp.aemet_2_oph_chs t
order by t.indicativo , t.año , t.mes
;

select t.año , t.mes , count(*)
from tmp.aemet_2_oph_chs t
group by t.año , t.mes 
order by t.año , t.mes
;

-- compruebo que todas las estaciones importadas está dadas de alta
select distinct t.indicativo , t2.indic 
from tmp.aemet_2_oph_chs t
	left join met.pexistencias t2 on(t.indicativo=t2.indic)
where t2.indic = NULL
order by t.indicativo , t2.indic
;

-- actualizo la table de datos

-- comruebo que la select de actualización está bien construida
select t.indicativo , (date_trunc('month', make_date(t.año , t.mes , 1)) + interval '1 month' - interval '1 day')::date as fecha , t.pmes77
from tmp.aemet_2_oph_chs t
order by t.indicativo , (date_trunc('month', make_date(t.año , t.mes , 1)) + interval '1 month' - interval '1 day')::date
;

-- upsert
insert into met.pmes (indic, fecha, prec) 
	select t.indicativo , (date_trunc('month', make_date(t.año , t.mes , 1)) + interval '1 month' - interval '1 day')::date as fecha , t.pmes77
	from tmp.aemet_2_oph_chs t
	order by t.indicativo , (date_trunc('month', make_date(t.año , t.mes , 1)) + interval '1 month' - interval '1 day')::date
on conflict on constraint pmes_pkey
do update set prec = excluded.prec
;

/*
Resto de ficheros a importar
H:\IGME2020\_pz_manzano\20220324_informe_pz\aemet\2021_10_09_08_PrecMesSeg_utf8.csv
H:\IGME2020\_pz_manzano\20220324_informe_pz\aemet\2021_11_10_09_PrecMesSeg_utf8.csv
H:\IGME2020\_pz_manzano\20220324_informe_pz\aemet\2021_12_11_10_PrecMesSeg_utf8.csv
H:\IGME2020\_pz_manzano\20220324_informe_pz\aemet\2022_01_12_11_PrecMesSeg_utf8.csv
H:\IGME2020\_pz_manzano\20220324_informe_pz\aemet\2022_02_01_12_PrecMesSeg_utf8.csv
*/



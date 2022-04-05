-- interpolacion de pmes en centroides de masub

--ultimos datos
select p.fecha "fecha pmes", count(*) as "#data"
from met.pmes p 
group by p.fecha 
order by p.fecha desc
;

select t.fecha "fecha masub", count(*) "n interpolaciones"
from met.interpolated_tseries t 
group by t.fecha 
order by t.fecha desc 
;

select m.masub , m.x_utm , m.y_utm 
from ipas.masub m
where m.dhs = 7 and masub>0
order by m.masub 
;

/* una vez electadas las interpolaciones por el método idw de los centroides de las masub
realizo un upsert en la tabla ipas.masubc_pm
*/

--creo la tabla
create table tmp.masubc_interpol (
	fid int2,
	fecha timestamp,
	valor float4,
	primary key (fid, fecha)
);

-- inserto los datos
copy tmp.masubc_interpol from 'H:\IGME2020\_pz_manzano\20220324_informe_pz\interpol\out\pd_idw.csv' 
with CSV header delimiter ';' encoding 'UTF-8';

-- datos para el upser
select concat('070.', lpad(t.fid ::text, 3, '0')) fid , 'pmes' pmes, t.fecha::date fecha , t.valor value, 'idw' idw
from tmp.masubc_interpol t
;

-- upsert
insert into met.interpolated_tseries 
	select concat('070.', lpad(t.fid ::text, 3, '0')) fid , 'pmes' pmes, t.fecha::date fecha ,
		t.valor value, 'idw' idw
	from tmp.masubc_interpol t
on conflict on constraint interpolated_tseries_pkey
do update set value=excluded.value
;


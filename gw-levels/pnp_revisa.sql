-- repaso del algunas medidas

select *
from ipas.ipa2 t 
where t.cod = '254020026'
order by t.fecha desc
;

update ipas.ipa2 
set situacion = 'no'
where cod = '254020026' and fecha > '2016-06-07'
returning *
;

select *
from ipas.ipa2
where cod = '254020026' and fecha > '2016-06-07'
;

select t2.cod, t2.fecha, t2.pnp , t1.z-t2.pnp cnp, t2.situacion, t2.proyecto 
from ipas.ipa1 t1
join ipas.ipa2 t2 using(cod) 
where cod = '283750074' -- and t1.z-t2.pnp > 917
order by fecha desc
;

select t.id , t.name_id , t.x , t.y , t.z_ref , t.name_mas 
from tmp.chspz t
where t.name_mas ~* '.guilas'
group by t.id , t.name_id , t.x , t.y , t.z_ref , t.name_mas
order by t.name_mas, t.id
;

--delete from ipas.ipa2 
where cod = '253530016' and fecha = '1996-12-11 00:00:00.000 +0100'
returning *
;

--update ipas.ipa2 
set pnp = 186.28
where cod = '243650002' and fecha = '2018-07-10 00:00:00.000 +0200'
;

select *
from saih
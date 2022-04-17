-- prof media agua (y más) 2021
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
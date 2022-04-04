create or replace force view scott.v_privs_for_saldo as
select
 p.lsk, sum(p.summa) as summa, p.usl_id as usl, t.fk_org2 as org, 0 as id_region
  from privs p, params m, kart r, nabor k, t_org t
 where r.lsk = p.lsk
   and r.lsk = k.lsk
   and k.usl = p.usl_id
   and k.org=t.id
   and not exists
 (select e.usl_id from usl_excl e where e.usl_id = p.usl_id)
 group by p.lsk, p.usl_id, t.fk_org2;


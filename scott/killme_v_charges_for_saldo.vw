create or replace force view scott.killme_v_charges_for_saldo as
select /*+ ORDERED */
 p.lsk, sum(p.summa) as summa, p.usl, k.org
  from c_charge p, kart r, nabor k, sprorg t, params m
 where r.lsk = p.lsk
   and p.type = 1
   and r.lsk = k.lsk
   and k.usl = p.usl
   and t.kod = k.org
   and not exists
 (select e.usl_id from usl_excl e where e.usl_id = p.usl)
 group by p.lsk, p.usl, k.org;


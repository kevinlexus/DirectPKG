create or replace force view scott.v_subsidii_for_saldo as
select p.lsk, sum(p.summa) as summa, p.usl, k.org
  from nabor k, kart r, subsidii p, params m
 where r.lsk = k.lsk
   and r.lsk = p.lsk
   and k.usl = p.usl
 group by p.lsk, p.usl, k.org;


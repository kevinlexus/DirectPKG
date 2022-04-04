create or replace force view scott.v_penya_for_saldo as
select p.lsk, sum(p.summa) as summa, p.usl, p.org
  from kwtp_day p
 where p.priznak=0
   and not exists
 (select e.usl_id from usl_excl e where e.usl_id = p.usl)
   and p.dtek between init.get_dt_start and init.get_dt_end
 group by p.lsk, p.usl, p.org;


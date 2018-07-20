create or replace force view scott.v_chargepay as
select t.lsk, t.mg, t.period, sum(decode(t.type,0,summa,-1*summa)) as summa
 from C_CHARGEPAY t
 group by t.lsk, t.mg, t.period;


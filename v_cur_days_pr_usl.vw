create or replace force view scott.v_cur_days_pr_usl as
select c.lsk, c.id, a.dat, u.usl, u.fk_calc_tp from
(select to_date(p.period||case when length(to_char(rownum))=1
       then '0'||to_char(rownum)
       else to_char(rownum) end ,'YYYYMMDD') as dat
     from (select level from dual connect by level < 32), params p
where rownum<=to_char(last_day(to_date(p.period||'01','YYYYMMDD')),'DD')) a, c_kart_pr c, usl u;


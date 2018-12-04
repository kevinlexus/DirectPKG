create or replace package body scott.rep_lsk is
procedure rep(p_rep_cd in varchar2, --CD отчёта
              p_lsk in kart.lsk%type, --лиц.счет.
              p_mg1 in varchar2, --начало периода
              p_mg2 in varchar2, --окончание периода
              prep_refcursor in out rep_refcursor
              ) is
begin
  if p_rep_cd='93' then
    --отчет по текущей пене
    open prep_refcursor for

      with r as (select t.mg1 as mg_ord, substr(t.mg1,5,2)||'.'||substr(t.mg1,1,4) as mg1, t.curdays, t.summa2, t.penya, 
                        s.partrate, s.rate, t.dt1, t.dt2, t.fk_stav,
                        t.dt1 as dt_ord, to_char(t.dt1,'YYYYMM') as mg_grp
         from a_pen_cur t join stav_r s
         on t.fk_stav=s.id and t.mg between p_mg1 and p_mg2 
          join params p on t.mg <> p.period and t.lsk=p_lsk
      union all
      select t.mg1 as mg_ord, substr(t.mg1,5,2)||'.'||substr(t.mg1,1,4) as mg1, t.curdays, t.summa2, t.penya, 
                        s.partrate, s.rate, t.dt1, t.dt2, t.fk_stav,
                        t.dt1 as dt_ord, to_char(t.dt1,'YYYYMM') as mg_grp
         from c_pen_cur t join stav_r s
         on t.fk_stav=s.id 
          join params p on p.period = p_mg2 and t.lsk=p_lsk)

      select a.mg_ord, a.mg1, sum(curdays) as curdays, sum(a.summa2) as summa2, sum(a.penya) as penya, 
             round(sum(a.penya),2) as penyar, min(a.dt1) as dt1, max(a.dt2) as dt2, a.partrate, a.rate
          from (select t.*, 
                       row_number() over(order by t.mg_ord, t.dt1, t.fk_stav) - row_number()
                       over(partition by mg1, fk_stav order by t.mg_ord, t.dt1, t.fk_stav) as grp
                       from r t) a
          group by a.grp, a.mg_ord, a.mg1, a.partrate, a.rate
          order by mg_ord, dt1;

  else 
    Raise_application_error(-20000, 'Некорректный вариант отчета!');
  end if;
end;

end rep_lsk;
/


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
  elsif p_rep_cd='95' then
    --отчет по оборотам по лиц.счету
    -- Пришлось использовать Dynamic SQL, так как Oracle неэффективно получает данные по этому запросу! - ред. 06.12.2018
    open prep_refcursor for
    'select u.usl || '' - '' || u.nm as usl_name, to_char(o.id) || '' - '' || o.name as org_name, substr(x.mg,
               5,
               2) || ''.'' ||
        substr(x.mg,
               1,
               4) as period,
               x.indebet, x.inkredit, x.charges, x.changes, x.payment, x.pn, x.outdebet, x.outkredit, x.privs, x.privs_city, x.ch_full, x.changes2, x.poutsal, 
               x.changes3, x.pinsal, x.pcur, x.pay_corr, x.penya_corr
  from (select usl, org, mg, sum(indebet) as indebet, sum(inkredit) as inkredit, sum(charges) as charges, sum(changes) as changes, sum(payment) as payment, 
  sum(pn) as pn, sum(outdebet) as outdebet, sum(outkredit) as outkredit, sum(privs) as privs, sum(privs_city) as privs_city, sum(ch_full) as ch_full, 
  sum(changes2) as changes2, sum(poutsal) as poutsal, sum(changes3) as changes3, sum(pinsal) as pinsal, sum(pcur) as pcur, sum(pay_corr) as pay_corr, sum(penya_corr) as penya_corr
           from (select t.mg, t.usl, t.org, indebet, inkredit, charges, changes, payment, pn, outdebet, outkredit, privs, privs_city, ch_full, changes2, poutsal, 
           changes3, pinsal, pcur, null as pay_corr, null as penya_corr
                    from scott.xitog3_lsk t
                   where t.lsk = '''||p_lsk||'''
                     and t.mg between '''||p_mg1||''' and '''||p_mg2||'''
                  union all
                  select t.mg, t.usl, t.org, null as indebet, null as inkredit, null as charges, null as changes, null as payment, null as pn, 
                  null as outdebet, null as outkredit, null as privs, null as privs_city, null as ch_full, null as changes2, null as poutsal, 
                  null as changes3, null as pinsal, null as pcur, t.summa as pay_corr, null as penya_corr
                    from scott.t_corrects_payments t
                   where t.lsk = '''||p_lsk||'''
                     and t.mg between '''||p_mg1||''' and '''||p_mg2||'''
                  union all
                  select t.mg, t.usl, t.org, null as indebet, null as inkredit, null as charges, null as changes, null as payment, null as pn,
                   null as outdebet, null as outkredit, null as privs, null as privs_city, null as ch_full, null as changes2, null as poutsal, 
                   null as changes3, null as pinsal, null as pcur, null as pay_corr, t.penya as penya_corr
                    from scott.a_pen_corr t
                   where t.lsk = '''||p_lsk||'''
                     and t.mg between '''||p_mg1||''' and '''||p_mg2||'''
)
          group by usl, org, mg) x
  join scott.usl u
    on x.usl = u.usl
  join scott.t_org o
    on x.org = o.id
 order by x.mg, x.usl, x.org';

    
  else 
    Raise_application_error(-20000, 'Некорректный вариант отчета!');
  end if;
end;

end rep_lsk;
/


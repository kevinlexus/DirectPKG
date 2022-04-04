create or replace force view scott.v_cur_charge_itg as
select lsk, sum(summa) as summa
           from (select lsk, summa
                    from c_charge t
                   where t.type = 1 and t.usl<>'024'
                  union all
                  select lsk, -1 * summa
                    from c_charge t
                   where t.type = 2 and t.usl<>'024'
                  union all
                  select lsk, -1 * summa
                    from c_charge t
                   where t.type = 4 and t.usl<>'024'
                  union all
                  select lsk, summa --учитываем текущие разовые изменения
                    from c_change t, params p where t.usl<>'024' and t.mgchange=p.period and
                    to_char(t.dtek,'YYYYMM')=p.period
                   ) a
          group by lsk
         having sum(summa) <> 0
;


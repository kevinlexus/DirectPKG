create or replace force view scott.v_cur_charge as
select lsk, usl, mg, sum(summa) as summa
           from (select lsk, usl, summa, p.period as mg
                    from c_charge t, params p
                   where t.type = 1 and t.usl<>'024'
                  union all
                  select lsk, usl, -1 * summa, p.period as mg
                    from c_charge t, params p
                   where t.type = 2 and t.usl<>'024'
                  union all
                  select lsk, usl, -1 * summa, p.period as mg
                    from c_charge t, params p
                   where t.type = 4 and t.usl<>'024'
                  union all
                  select lsk, usl, summa, p.period as mg --учитываем текущие разовые изменения
                    from c_change t, params p where t.usl<>'024' and t.mgchange=p.period and
                    to_char(t.dtek,'YYYYMM')=p.period
                   ) a
          group by lsk, usl, mg
         having sum(summa) <> 0
;


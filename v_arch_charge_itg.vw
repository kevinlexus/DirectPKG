create or replace force view scott.v_arch_charge_itg as
select lsk, mg, sum(summa) as summa from (
          select lsk, usl, mg, abs(sum(summa)) as summa
           from ( select lsk, usl_id as usl, mg, summa_it as summa
                    from arch_charges t where t.usl_id<>'024'
                  union all
                  select lsk, usl_id, mg, -1 * summa
                    from arch_subsidii t where t.usl_id<>'024'
                  union all
                  select lsk, usl_id, mg, -1 * summa
                    from arch_privs t where t.usl_id<>'024'
                  union all
                  select lsk, usl_id, mg, summa
                    from arch_changes t where t.usl_id<>'024'
                  union all
                  select lsk, usl, mgchange, summa --учитываем текущие разовые изменения
                    from c_change t, params p where t.usl<>'024' and t.mgchange<>p.period and
                    to_char(t.dtek,'YYYYMM')=p.period
                    ) a
          group by lsk, usl, mg
         having sum(summa) <> 0) group by lsk, mg
;


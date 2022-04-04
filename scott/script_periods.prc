create or replace procedure scott.script_periods is
c_lsk_id_ kart.c_lsk_id%TYPE;
begin
for ff in (select lsk from kart where lsk='00043489')
loop
  select max(k.c_lsk_id) into c_lsk_id_
   from arch_kart k where k.lsk=ff.lsk and lsk=ff.lsk and mg='200804';

  delete from c_chargepay where period='200804' and type=1 and lsk=ff.lsk;

  insert into c_chargepay (lsk, summa, type, mg, period, c_lsk_id)
  select a.lsk, sum(summa) as summa, 1, mg, '200804', c_lsk_id_
           from (select c.lsk, c.summa,
                c.dopl as mg
                    from a_kwtp_mg c where c.lsk = ff.lsk and
                     to_char(c.dtek , 'YYYYMM')='200804' and c.mg='200804'
                  union all
                  select c.lsk, c.summa, c.mg --из старого периода берем оплату
                    from c_chargepay c where c.lsk = ff.lsk
                    and c.period='200803'
                    and c.type=1
                    ) a
                  group by a.lsk, mg
                  having sum(summa) <>0;
  commit;
end loop;
end script_periods;
/


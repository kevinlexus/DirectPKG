create or replace procedure scott.script_corr_chargepay is
  mg_ params.period%TYPE;
  oldmg_ params.period%TYPE;
begin

--исправление c_chargepay

mg_:='200804';
oldmg_:='200803';
execute immediate 'truncate table dub_charge';
insert into dub_charge (lsk, summa, type, mg, period, c_lsk_id)
 select c.lsk, c.summa, c.type, c.mg, c.period, c.c_lsk_id --из старого периода берем начисление (все периоды)
                    from tmp_chargepay c where c.type=0 and c.period < mg_;
insert into dub_charge (lsk, summa, type, mg, period, c_lsk_id)
 select c.lsk, c.summa, c.type, c.mg, c.period, c.c_lsk_id --из старого периода берем оплату (до периода mg_)
                    from tmp_chargepay c where c.type=1 and c.period < mg_;
commit;

insert into dub_charge (lsk, summa, type, mg, period, c_lsk_id)
select a.lsk, sum(summa) as summa, 0, mg, mg_, c_lsk_id
           from (select c.lsk, c.summa, mg_ as mg, k.c_lsk_id
                    from kart k, a_charge c where c.lsk=k.lsk
                    and c.type=1 and c.mg=mg_ --начисление
                    and c.usl not in (select usl_id from usl_excl)
                  union all
                  select c.lsk, c.summa, c.mgchange as mg, k.c_lsk_id
                    from kart k, a_change c where c.lsk=k.lsk and
                    c.mg=mg_ and c.usl not in (select usl_id from usl_excl)
                    and to_char(c.dtek , 'YYYYMM')=mg_
                  union all
                  select c.lsk, c.summa * -1, mg_ as mg, k.c_lsk_id
                    from kart k, a_charge c where c.lsk=k.lsk
                    and c.mg=mg_ and c.type=2 --субсидии
                    and c.usl not in (select usl_id from usl_excl)
                  union all
                  select c.lsk, c.summa * -1, mg_ as mg, k.c_lsk_id
                    from kart k, a_charge c where c.lsk=k.lsk
                    and c.mg=mg_ and c.type=4 --льготы
                    and c.usl not in (select usl_id from usl_excl)
                  union all
                  select c.lsk, c.summa, c.mg, c.c_lsk_id --из старого периода берем начисление
                    from dub_charge c
                    where c.period=oldmg_
                    and c.type=0
                    ) a
                  group by a.lsk, mg, mg_, c_lsk_id
                  having sum(summa) <>0;
commit;

insert into dub_charge (lsk, summa, type, mg, period, c_lsk_id)
select a.lsk, sum(a.summa) as summa, 1, a.mg, mg_, a.c_lsk_id
           from (select c.lsk, k.c_lsk_id, c.summa, c.dopl as mg
                    from kart k, a_kwtp_mg c where k.lsk=c.lsk and
                     to_char(c.dtek , 'YYYYMM')=mg_ and c.mg=mg_
                  union all
                  select c.lsk, c.c_lsk_id, c.summa, c.mg --из старого периода берем оплату
                    from dub_charge c where c.period=oldmg_
                    and c.type=1
                    ) a
                  group by a.lsk, a.c_lsk_id, a.mg
                  having sum(summa) <>0;
commit;
mg_:='200805';
oldmg_:='200804';
insert into dub_charge (lsk, summa, type, mg, period, c_lsk_id)
select a.lsk, sum(a.summa) as summa, 1, a.mg, mg_, a.c_lsk_id
           from (select c.lsk, k.c_lsk_id, c.summa, c.dopl as mg
                    from kart k, a_kwtp_mg c where k.lsk=c.lsk and
                     to_char(c.dtek , 'YYYYMM')=mg_ and c.mg=mg_
                  union all
                  select c.lsk, c.c_lsk_id, c.summa, c.mg --из старого периода берем оплату
                    from dub_charge c where c.period=oldmg_
                    and c.type=1
                    ) a
                  group by a.lsk, a.c_lsk_id, a.mg
                  having sum(summa) <>0;
commit;
insert into dub_charge (lsk, summa, type, mg, period, c_lsk_id)
select a.lsk, sum(summa) as summa, 0, mg, mg_, c_lsk_id
           from (select c.lsk, c.summa, mg_ as mg, k.c_lsk_id
                    from kart k, a_charge c where c.lsk=k.lsk
                    and c.type=1 and c.mg=mg_ --начисление
                    and c.usl not in (select usl_id from usl_excl)
                  union all
                  select c.lsk, c.summa, c.mgchange as mg, k.c_lsk_id
                    from kart k, a_change c where c.lsk=k.lsk and
                    c.mg=mg_ and c.usl not in (select usl_id from usl_excl)
                    and to_char(c.dtek , 'YYYYMM')=mg_
                  union all
                  select c.lsk, c.summa * -1, mg_ as mg, k.c_lsk_id
                    from kart k, a_charge c where c.lsk=k.lsk
                    and c.mg=mg_ and c.type=2 --субсидии
                    and c.usl not in (select usl_id from usl_excl)
                  union all
                  select c.lsk, c.summa * -1, mg_ as mg, k.c_lsk_id
                    from kart k, a_charge c where c.lsk=k.lsk
                    and c.mg=mg_ and c.type=4 --льготы
                    and c.usl not in (select usl_id from usl_excl)
                  union all
                  select c.lsk, c.summa, c.mg, c.c_lsk_id --из старого периода берем начисление
                    from dub_charge c
                    where c.period=oldmg_
                    and c.type=0
                    ) a
                  group by a.lsk, mg, mg_, c_lsk_id
                  having sum(summa) <>0;
commit;
mg_:='200806';
oldmg_:='200805';
insert into dub_charge (lsk, summa, type, mg, period, c_lsk_id)
select a.lsk, sum(a.summa) as summa, 1, a.mg, mg_, a.c_lsk_id
           from (select c.lsk, k.c_lsk_id, c.summa, c.dopl as mg
                    from kart k, a_kwtp_mg c where k.lsk=c.lsk and
                     to_char(c.dtek , 'YYYYMM')=mg_ and c.mg=mg_
                  union all
                  select c.lsk, c.c_lsk_id, c.summa, c.mg --из старого периода берем оплату
                    from dub_charge c where c.period=oldmg_
                    and c.type=1
                    ) a
                  group by a.lsk, a.c_lsk_id, a.mg
                  having sum(summa) <>0;
commit;
insert into dub_charge (lsk, summa, type, mg, period, c_lsk_id)
select a.lsk, sum(summa) as summa, 0, mg, mg_, c_lsk_id
           from (select c.lsk, c.summa, mg_ as mg, k.c_lsk_id
                    from kart k, a_charge c where c.lsk=k.lsk
                    and c.type=1 and c.mg=mg_ --начисление
                    and c.usl not in (select usl_id from usl_excl)
                  union all
                  select c.lsk, c.summa, c.mgchange as mg, k.c_lsk_id
                    from kart k, a_change c where c.lsk=k.lsk and
                    c.mg=mg_ and c.usl not in (select usl_id from usl_excl)
                    and to_char(c.dtek , 'YYYYMM')=mg_
                  union all
                  select c.lsk, c.summa * -1, mg_ as mg, k.c_lsk_id
                    from kart k, a_charge c where c.lsk=k.lsk
                    and c.mg=mg_ and c.type=2 --субсидии
                    and c.usl not in (select usl_id from usl_excl)
                  union all
                  select c.lsk, c.summa * -1, mg_ as mg, k.c_lsk_id
                    from kart k, a_charge c where c.lsk=k.lsk
                    and c.mg=mg_ and c.type=4 --льготы
                    and c.usl not in (select usl_id from usl_excl)
                  union all
                  select c.lsk, c.summa, c.mg, c.c_lsk_id --из старого периода берем начисление
                    from dub_charge c
                    where c.period=oldmg_
                    and c.type=0
                    ) a
                  group by a.lsk, mg, mg_, c_lsk_id
                  having sum(summa) <>0;
commit;

end script_corr_chargepay;
/


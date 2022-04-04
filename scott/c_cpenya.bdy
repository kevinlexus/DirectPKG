create or replace package body scott.C_CPENYA is

--обертка
procedure gen_charge_pay_pen is
begin
  gen_charge_pay_pen(p_dt => null);
end;

--еще одна обертка, для старых вызовов
procedure gen_charge_pay_pen(p_dt in date) is
begin
  gen_charge_pay_pen(null, p_dt, 1);
end;

--формирование по домам, в потоках
procedure gen_charge_pay_pen_house(p_house in number) is
 l_is_lstdt number;
begin
  -- здесь всегда по концу месяца
  l_is_lstdt:=1;
  logger.log_(time_, 'gen_charge_pay_pen_house начало: p_house='||p_house);

  for c in (select lsk from kart k where k.house_id=p_house) loop
    --пеня, на дату, с коммитом
    --движение работает внутри
    --logger.log_(time_, 'gen_charge_pay_pen_house начало: p_lsk='||c.lsk);
    gen_penya(lsk_ => c.lsk, dat_ => null, islastmonth_ => l_is_lstdt, p_commit => 1);
    --logger.log_(time_, 'gen_charge_pay_pen_house окончание: p_lsk='||c.lsk);
  end loop;
  logger.log_(time_, 'gen_charge_pay_pen_house окончание: p_house='||p_house);

end;

--процедура распределения начисленной пени по исх.сальдо - обертка
procedure gen_charge_pay_pen(
                             p_dt in date, --дата формир.
                             p_var in number --формировать пеню? (0-нет, 1-да (старый вызов)
          ) is
begin
  gen_charge_pay_pen(null, p_dt, p_var);
end;

--процедура распределения начисленной пени по исх.сальдо
--сделано так, потому что не ведётся начисление пени по услугам (если вести - то надо учитывать округления и т.п.)
procedure gen_charge_pay_pen(p_lsk in kart.lsk%type, -- лиц счет (если null - то все лиц.счета)
                             p_dt in date, --дата формир.
                             p_var in number --формировать пеню? (0-нет, 1-да (старый вызов)
          ) is
  l_usl_dst usl.usl%type;
  l_org_dst number;
  l_mg params.period%type;
  l_mg2 params.period%type;
  l_mg_back params.period%type;
  t_summ  tab_summ;
  l_err number;
  l_dt date;
begin
  time_ := sysdate;
  select p.period, p.period1, p.period3 into l_mg, l_mg2, l_mg_back
    from v_params p;
  if p_dt is null then
    l_dt:=init.get_dt_end;
  else
    l_dt:=p_dt;
  end if;
  if p_var=1 then
    for c in (select lsk from kart t where nvl(p_lsk, t.lsk) = t.lsk) loop
      --пеня, на дату, с коммитом
      --движение работает внутри
      gen_penya(lsk_ => c.lsk, dat_ => l_dt, islastmonth_ => 0, p_commit => 1);
    end loop;
  end if;

  -- после формирования начисления пени, распределяем её по услугам
  -- ПЕНЯ РАСПРЕДЕЛИТСЯ СТРОГО НА УСЛУГИ УКАЗАННЫЕ процедурой c_gen_pay.redirect
  if p_lsk is null then
    delete from t_chpenya_for_saldo t; -- текущая, начисленная пеня с учетом корректировок по пене!
    delete from temp_chpenya;
  else
    delete from t_chpenya_for_saldo t where t.lsk=p_lsk; -- текущая, начисленная пеня с учетом корректировок по пене!
    delete from temp_chpenya t where t.lsk=p_lsk;
  end if;

  for c in (select t.reu, t.lsk, t.tp, t.penya, coalesce(b.deb_summa,0) as deb_summa, coalesce(b.kr_summa,0) as kr_summa, t.pen_sign
   from (select k.reu, tp.cd as tp, d.lsk, sum(d.penya) as penya, sign(sum(d.penya)) as pen_sign
    from kart k, v_lsk_tp tp, (select r.lsk, sum(r.penya) as penya from (
      select c.lsk, c.mg1, round(sum(penya),2) as penya from c_pen_cur c where nvl(p_lsk,c.lsk)=c.lsk
        group by c.lsk, c.mg1       -- текущее начисление пени
      union all
     select c.lsk, c.dopl, c.penya  -- прибавить корректировку пени за месяц (не разбитую по услугам)
          from c_pen_corr c where nvl(p_lsk,c.lsk)=c.lsk and c.usl is null
        ) r group by r.lsk
      ) d
    where nvl(p_lsk,k.lsk)=k.lsk and k.lsk=d.lsk and k.fk_tp=tp.id
    group by k.reu, d.lsk, tp.cd
    having sum(d.penya)<>0) t left join
   (select d.lsk, sum(case when d.poutsal > 0 then d.poutsal else 0 end) as deb_summa,
                  sum(case when d.poutsal < 0 then d.poutsal else 0 end) as kr_summa
    from (select a.lsk, a.usl, a.org, sum(a.poutsal) as poutsal from (
           select s.lsk, s.usl, s.org, s.poutsal from xitog3_lsk s where s.mg=l_mg_back -- входящее сальдо по пене
           and nvl(p_lsk,s.lsk)=s.lsk
           --union all ### убрал 31.12.2019 - это влияет на распределение, и невозможно исправить исх сальдо по пене
           --select s.lsk, s.usl, s.org, s.penya from c_pen_corr s where s.usl is not null
           --and nvl(p_lsk,s.lsk)=s.lsk -- корректировка, разбитая по услугам (для исключения распределения по необходимым услугам) (ниже добавляется)
           ) a group by a.lsk, a.usl, a.org) d
     group by d.lsk) b on t.lsk=b.lsk and t.penya <> 0
       order by t.lsk)
  loop
    --распределение на услуги
    if c.pen_sign > 0 and c.deb_summa <> 0 then
        -- 1. распределить по дебет сальдо пени - положительное значение пени
        select rec_summ(t.usl, t.org, t.poutsal, 0) bulk collect
          into t_summ from
          (select a.usl, a.org, sum(a.poutsal) as poutsal from (
           select s.usl, s.org, s.poutsal from xitog3_lsk s where s.lsk=c.lsk and s.mg=l_mg_back -- сальдо по пене
           --union all ### убрал 31.12.2019 - это влияет на распределение, и невозможно исправить исх сальдо по пене
           --select s.usl, s.org, s.penya from c_pen_corr s where s.lsk=c.lsk and s.usl is not null
           ) a group by a.usl, a.org -- корректировка, разбитая по услугам (для исключения распределения по необходимым услугам) (ниже добавляется)
           ) t
          where t.poutsal > 0;
    elsif c.pen_sign > 0 and c.kr_summa <> 0 then
        -- 2. распределить по кредит сальдо пени - положительное значение пени, если не найдено по 1 пункту
        select rec_summ(t.usl, t.org, t.poutsal*-1, 0) bulk collect
          into t_summ from
           (select a.usl, a.org, sum(a.poutsal) as poutsal from (
           select s.usl, s.org, s.poutsal from xitog3_lsk s where s.lsk=c.lsk and s.mg=l_mg_back -- сальдо по пене
           --union all ### убрал 31.12.2019 - это влияет на распределение, и невозможно исправить исх сальдо по пене
           --select s.usl, s.org, s.penya from c_pen_corr s where s.lsk=c.lsk and s.usl is not null
           ) a group by a.usl, a.org -- корректировка, разбитая по услугам (для исключения распределения по необходимым услугам) (ниже добавляется)
           ) t
          where t.poutsal < 0;
    elsif c.pen_sign > 0 and c.deb_summa = 0 and c.kr_summa = 0 then
        -- 3. распределить по начислению положительное значение пени, если сальдо=0, если не найдено по предыдущим пунктам
        select rec_summ(n.usl, n.org, t.summa, 0) bulk collect
          into t_summ from
           c_charge t, nabor n
          where t.lsk=c.lsk and t.summa > 0 and t.type=1
          and t.lsk=n.lsk and t.usl=n.usl;
        if sql%rowcount = 0 then --не найдено начисление, распределить по наборам (типа на 100 руб)
            if c.tp='LSK_TP_MAIN' then
              -- основной лс
            select rec_summ(t.usl, t.org, 100, 0) bulk collect
              into t_summ from nabor t where t.lsk=c.lsk and t.usl='003';
            else
              -- капрем
            select rec_summ(t.usl, t.org, 100, 0) bulk collect
              into t_summ from nabor t where t.lsk=c.lsk and t.usl='033';
            end if;

            if sql%rowcount = 0 then
              -- если и в наборах нет записи по usl=003 или 033 то по любым услугам из наборов
              select rec_summ(t.usl, t.org, 100, 0) bulk collect
                into t_summ from nabor t where t.lsk=c.lsk;
            end if;

            if sql%rowcount = 0 then
              -- если и в наборах вообще нет записей, то попробовать распределить по дебет сальдо
              select rec_summ(t.usl, t.org, t.summa, 0) bulk collect
                into t_summ from saldo_usl t where t.lsk=c.lsk and t.mg=l_mg and t.summa>0;
            end if;

            if sql%rowcount = 0 then
              -- если и в сальдо нет записей по дебету, то попробовать распределить по кредит сальдо
              select rec_summ(t.usl, t.org, t.summa*-1, 0) bulk collect
                into t_summ from saldo_usl t where t.lsk=c.lsk and t.mg=l_mg and t.summa<0;
            end if;

            if sql%rowcount = 0 then
              -- если и в сальдо нет записей - САМЫЙ ПЛОХОЙ СЛУЧАЙ РАСПРЕДЕЛЕНИЯ!
              select rec_summ('003', t.id, 100, 0) bulk collect
                into t_summ from t_org t where t.reu=c.reu;
            end if;
        end if;
    elsif c.pen_sign < 0 and c.deb_summa <> 0 then
        -- 4. распределить по дебет сальдо пени - отрицательное значение пени
        select rec_summ(t.usl, t.org, t.poutsal, 0) bulk collect
          into t_summ from
           (select a.usl, a.org, sum(a.poutsal) as poutsal from (
           select s.usl, s.org, s.poutsal from xitog3_lsk s where s.lsk=c.lsk and s.mg=l_mg_back -- сальдо по пене
           --union all  ### убрал 31.12.2019 - это влияет на распределение, и невозможно исправить исх сальдо по пене
           --select s.usl, s.org, s.penya from c_pen_corr s where s.lsk=c.lsk and s.usl is not null
           ) a group by a.usl, a.org -- корректировка, разбитая по услугам (для исключения распределения по необходимым услугам) (ниже добавляется)
           ) t
          where t.poutsal > 0;
    elsif c.pen_sign < 0 and c.kr_summa <> 0 then -- ред.26.11.2019 - была найдена ошибка, этот пункт выполнялся первым, что вызывало дополнительное снятие сальдо по пене с Кредита по пене!
        -- 5. распределить по кредит сальдо пени - отрицательное значение пени, если не найдено по 4 пункту
        select rec_summ(t.usl, t.org, t.poutsal*-1, 0) bulk collect
          into t_summ from
           (select a.usl, a.org, sum(a.poutsal) as poutsal from (
           select s.usl, s.org, s.poutsal from xitog3_lsk s where s.lsk=c.lsk and s.mg=l_mg_back -- сальдо по пене
           --union all  ### убрал 31.12.2019 - это влияет на распределение, и невозможно исправить исх сальдо по пене
           --select s.usl, s.org, s.penya from c_pen_corr s where s.lsk=c.lsk and s.usl is not null
           ) a group by a.usl, a.org -- корректировка, разбитая по услугам (для исключения распределения по необходимым услугам) (ниже добавляется)
           ) t
          where t.poutsal < 0;
    elsif c.pen_sign < 0 and c.deb_summa = 0 and c.kr_summa = 0 then
        --распределить по начислению отрицательное значение пени, если сальдо=0, если не найдено по предыдущим пунктам
        select rec_summ(n.usl, n.org, t.summa, 0) bulk collect
          into t_summ from
           c_charge t, nabor n
          where t.lsk=c.lsk and t.summa > 0 and t.type=1
          and t.lsk=n.lsk and t.usl=n.usl;
          if sql%rowcount = 0 then --не найдено начисление, распределить по наборам (типа на 100 руб)
            if c.tp='LSK_TP_MAIN' then
              -- основной лс
              select rec_summ(t.usl, t.org, 100, 0) bulk collect
                into t_summ from nabor t where t.lsk=c.lsk and t.usl='003';
              else
                -- капрем
              select rec_summ(t.usl, t.org, 100, 0) bulk collect
                into t_summ from nabor t where t.lsk=c.lsk and t.usl='033';
            end if;

            if sql%rowcount = 0 then
              -- если уж и в наборах нет записи по usl=003 или 033 то по любым услугам
              select rec_summ(t.usl, t.org, 100, 0) bulk collect
                into t_summ from nabor t where t.lsk=c.lsk;
            end if;

            if sql%rowcount = 0 then
              -- если уж и в наборах вообще нет записей то...
              select rec_summ('003', t.id, 100, 0) bulk collect
                into t_summ from t_org t where t.reu=c.reu;
            end if;
          end if;
    end if;


    l_err := c_prep.dist_summa_full(p_sum  => c.penya,
                         t_summ => t_summ);
    if l_err <> 0 then
      Raise_application_error(-20000, 'Ошибка при распределении пени в лиц.счете:'||c.lsk);
    end if;

    delete from temp_prep;

    -- перенаправление пени, на нужную услугу и организацию
    for c2 in (select t.summa as summa, t.fk_cd as usl, t.fk_id as org
       from table(t_summ) t
             where t.tp = 1
             )
    loop
      c_gen_pay.redirect(p_tp => 0, p_reu => c.reu,
        p_usl_src => c2.usl, p_usl_dst => l_usl_dst, p_org_src => c2.org, p_org_dst => l_org_dst);

      insert into temp_prep(usl, org, summa)
        values (l_usl_dst, l_org_dst, c2.summa);

    end loop;

    -- добавляем во временную таблицу
      begin
    insert into temp_chpenya (lsk, usl, org, summa)
      select c.lsk, t.usl, t.org, summa as summa
      from temp_prep t;
        exception when others then
          for c3 in (select * from temp_prep t) loop
          Raise_application_error(-20000, 'lsk='||c.lsk||' c2.usl='||c3.usl||' c2.org='||c3.org);
          end loop;
      end;
  end loop;

    -- добавить корректировку, разбитую по услугам
  if p_lsk is null then
    insert into t_chpenya_for_saldo (lsk, usl, org, summa)
    select lsk, usl, org, sum(penya) from (
    select t.lsk, t.usl, t.org, t.penya from c_pen_corr t
     where t.usl is not null -- корректировка разбитая по услугам! сумма по ней должна обязательно давать 0 в контексте лиц.счета ред.22.09.20
    union all
    select t.lsk, t.usl, t.org, t.summa from temp_chpenya t -- начисленная и распределенная пеня
    ) group by lsk, usl, org;
  else
    insert into t_chpenya_for_saldo (lsk, usl, org, summa)
    select lsk, usl, org, sum(penya) from (
    select t.lsk, t.usl, t.org, t.penya from c_pen_corr t
     where t.lsk=p_lsk and t.usl is not null -- корректировка разбитая по услугам! сумма по ней должна обязательно давать 0 в контексте лиц.счета ред.22.09.20
    union all
    select t.lsk, t.usl, t.org, t.summa from temp_chpenya t -- начисленная и распределенная пеня
     where t.lsk=p_lsk
    ) group by lsk, usl, org;
  end if;

  commit;
 logger.log_(time_, 'c_penya.gen_charge_pay_pen');
end;

PROCEDURE gen_charge_pay_full is
--заполнение c_chargepay
--делать, ДО расчета пени
  l_Java_deb_pen number;
begin
    l_Java_deb_pen := utils.get_int_param('JAVA_DEB_PEN');
    if l_Java_deb_pen=1 then
      -- не должно использоваться, если установлен параметр Java начисления пени
      Raise_application_error(-20000, 'Процедура не должна использоваться!');
    end if;

  for c in (select k.lsk from kart k)
  loop
    gen_charge_pay(c.lsk, 1);
  end loop;
end;

--обертка под старый вызов
PROCEDURE gen_charge_pay(lsk_ in kart.lsk%type, iscommit_ in number) is
begin
  gen_charge_pay(lsk_ => lsk_, iscommit_ => iscommit_, p_dt => null);
end;

-- заполнение c_chargepay нового периода
-- выполняется из Java, многопоточно, в расчете пени (но не используется в самом расчете) ред.15.03.21
PROCEDURE gen_charge_pay(lsk_ in kart.lsk%type, --лиц счет
                         iscommit_ in number,   --ставить ли коммит
                         p_dt in date           --дата по которую принимать транзакции
                        ) is
  period_ PARAMS.period%TYPE;
  newperiod_ PARAMS.period%TYPE;
  oldperiod_ PARAMS.period%TYPE;
begin

SELECT v.period, v.period1,TO_CHAR(ADD_MONTHS(TO_DATE(period || '01', 'YYYYMMDD'), -1), 'YYYYMM')
 INTO period_, newperiod_, oldperiod_ FROM v_params v;
--для расчета пени

delete from c_chargepay2 c where period_ between c.mgFrom and c.mgTo and c.lsk=lsk_;--coalesce(lsk_,c.lsk) неэффективный запрос становится! ред.06.03.21
   --and not exists (select * from kart_ext e where e.lsk=c.lsk); -- исключить внешние лиц.сч., они загружаются в gen.load_ext_saldo

--начисление
insert into c_chargepay2 (summa, type, mg, mgFrom, mgTo, lsk)
select sum(summa) as summa, 0, mg, period_ as mgFrom, period_ as mgTo, lsk_
           from (select c.lsk, c.summa, period_ as mg
                    from c_charge c where c.lsk = lsk_ --coalesce(lsk_,c.lsk) неэффективный запрос становится! ред.06.03.21
                    and c.type=1 --начисление
                    and c.usl not in (select usl_id from usl_excl)
                    and not exists (select * from kart_ext e where e.lsk=c.lsk) -- исключить внешние лиц.сч.
                  union all
                  select c.lsk, c.summa, c.mgchange as mg
                    from c_change c where c.lsk = lsk_ --coalesce(lsk_,c.lsk) неэффективный запрос становится! ред.06.03.21
                    and c.usl not in (select usl_id from usl_excl)
                    and c.dtek <= nvl(p_dt, c.dtek) --ограничить, если надо
                    and c.dtek between init.g_dt_start and init.g_dt_end
                    and c.show_bill is null --ред.01.03.13 - show_bill используется возможно, тогда когда сумма переброски по раз изм = 0 (внутри, по услугам)
                    and not exists (select * from kart_ext e where e.lsk=c.lsk) -- исключить внешние лиц.сч.
                  union all
                  select c.lsk, c.summa, c.mg --из старого периода берем начисление
                    from c_chargepay2 c where c.lsk = lsk_ --coalesce(lsk_,c.lsk) неэффективный запрос становится! ред.06.03.21
                    and oldperiod_ between c.mgFrom and c.mgTo
                    and c.type=0
                    --and not exists (select * from kart_ext e where e.lsk=c.lsk) -- исключить внешние лиц.сч.
                    ) a
                  group by a.lsk, a.mg
                  having sum(summa) <>0;

--оплата
if init.g_dt_start is null or init.g_dt_end is null then
  Raise_application_error(-20000, 'Сообщите программисту код ошибки #5');
end if;

if to_char(init.g_dt_start,'YYYYMM')<>period_ or to_char(init.g_dt_end,'YYYYMM')<>period_ then
  Raise_application_error(-20000, 'Сообщите программисту код ошибки #6 init.g_dt_start='||to_char(init.g_dt_start,'YYYYMM')||' period='||period_);
end if;

insert into c_chargepay2 (summa, summap, type, mg, mgFrom, mgTo, lsk)
select sum(summa) as summa, sum(summap), 1, mg, period_ as mgFrom, period_ as mgTo, a.lsk
           from (select c.lsk, c.summa, c.penya as summap,
                c.dopl as mg
                    from c_kwtp_mg c where c.lsk = lsk_ --coalesce(lsk_,c.lsk) неэффективный запрос становится! ред.06.03.21
                    and c.dtek <= nvl(p_dt, c.dtek) --ограничить, если надо
                    and (c.dat_ink is null and c.dtek <= init.g_dt_end or --ДА ДА сделал пока так странно (учитывать все платежи меньше или = границы периода) ред.02.09.14
                        c.dat_ink between init.g_dt_start and init.g_dt_end)
                    and not exists (select * from kart_ext e where e.lsk=c.lsk) -- исключить внешние лиц.сч.
                  union all
                select c.lsk, c.summa, null as summap,
                  c.dopl
                 --корректировки оплаты
                    from t_corrects_payments c, params p
                     where c.lsk = lsk_ --coalesce(lsk_,c.lsk) неэффективный запрос становится! ред.06.03.21
                     and c.mg=p.period and not exists (select * from kart_ext e where e.lsk=c.lsk) -- исключить внешние лиц.сч.
                    and not exists (select * from kart_ext e where e.lsk=c.lsk) -- исключить внешние лиц.сч.
                  union all
                  select c.lsk, c.summa, c.summap, c.mg --из старого периода берем оплату
                    from c_chargepay2 c where c.lsk = lsk_ --coalesce(lsk_,c.lsk) неэффективный запрос становится! ред.06.03.21
                    and oldperiod_ between c.mgFrom and c.mgTo
                    and c.type=1
                    and not exists (select * from kart_ext e where e.lsk=c.lsk) -- исключить внешние лиц.сч.
                    ) a
                  group by a.lsk, a.mg
                  having sum(summa) <>0 or sum(summap) <>0;
  if iscommit_ = 1 then
   commit;
  end if;
end;

PROCEDURE gen_penya(lsk_ in kart.lsk%type, islastmonth_ in number, p_commit in number) is
begin
  --перегруженная функция формирования пени
  gen_penya(lsk_, null, islastmonth_, p_commit);
end;


PROCEDURE gen_penya(lsk_ in kart.lsk%type, dat_ in date, islastmonth_ in number, p_commit in number) is
 l_pn_dt kart.pn_dt%type; --ограничение пени датой
 l_datpen date;
 l_mg params.period%type;
 l_mg_back params.period%type;
 --для расчета пени
 l_summa number; --сумма долга
 l_ovrpay number; --перплата (перенести на будущий период)
 --для расчета долга (сделал, так как для расчета долга надо, чтоб учитывалось поступление оплаты за текущий день, а для расчета пени - нет
 l_summa_deb number; --сумма долга
 l_ovrpay_deb number; --перплата (перенести на будущий период)

 l_lsk_tp number; --тип лицевого счета (основной/дополнительный)
 l_day_iter date; --день итерации расчета
 l_reu kart.reu%type;
 l_iter number; -- id расчета
 l_klsk_id number;
 l_Java_deb_pen number;
 l_dummy number;
begin
  --выполнять строго после gen_charge_pay
  --выполнять строго после gen.gen_sal/do (при формировании за месяц)

    --текущая пеня
    if dat_ is null then
      if islastmonth_ = 0 then --текущая пеня
        l_datpen:=init.get_date();
      else --пеня по концу месяца
        l_datpen:=init.get_cur_dt_end;
      end if;
    else --пеня на конкретную дату
      if dat_ < init.get_cur_dt_start then
        l_datpen:=init.get_cur_dt_start;
      else
        l_datpen:=dat_;
      end if;
    end if;

    l_Java_deb_pen := utils.get_int_param('JAVA_DEB_PEN');
    if l_Java_deb_pen=1 then
      -- вызов Java начисления пени
      if lsk_ is not null then
        select k.k_lsk_id into l_klsk_id from kart k where k.lsk=lsk_;
      else
          Raise_application_error(-20000, 'lsk_ должен быть заполнен!');
      end if;
      l_dummy:=p_java.gen(p_tp        => 1,
                 p_house_id  => null,
                 p_vvod_id   => null,
                 p_usl_id    => null,
                 p_klsk_id   => l_klsk_id,
                 p_debug_lvl => 0,
                 p_gen_dt    => l_datpen,
                 p_stop      => 0);
      return;
    else
          Raise_application_error(-20000, 'Расчет пени, производится только в Java!');
    end if;
end;


--корректировка на ноль входящего сальдо по пене из меню движение по л/с
function corr_sal_pen(p_lsk in kart.lsk%type, p_mg in c_pen_corr.dopl%type)
    return number is
  l_id number;
  l_user number;
  l_comm c_change_docs.text%type;
begin
  select u.id into l_user from t_user u where u.cd=user;
  l_comm:='Корректировка вх.сальдо по пене';
  insert into c_change_docs
    (mgchange, dtek, ts, user_id, text)
  values
    (p_mg, init.get_date, sysdate, l_user, l_comm)
  returning id into l_id;

  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select a.lsk, -1*sum(penya) as penya, a.dopl, init.get_date as dtek, sysdate as ts,
     l_user as fk_user, l_id as fk_doc
  from (
  select t.lsk, t.penya as penya, p_mg as dopl
    from a_penya t where t.lsk=p_lsk and t.mg1=p_mg
    and t.mg=utils.add_months_pr(init.get_period,-1)
  union all
  select t.lsk, t.penya, t.dopl from c_pen_corr t where t.lsk=p_lsk and t.dopl=p_mg
  ) a
  group by a.lsk, a.dopl
  having sum(penya) > 0;

  if sql%rowcount = 0 then
    return 1;
  else
    return 0;
  end if;
end;

--корректировка на ноль ВСЕГО входящего сальдо по пене из меню движение по л/с
function corr_all_sal_pen(p_lsk in kart.lsk%type)
    return number is
  l_id number;
  l_user number;
  l_comm c_change_docs.text%type;
  l_mg params.period%type;
begin
  select u.id, p.period into l_user, l_mg from t_user u, params p where u.cd=user;
  l_comm:='Корректировка вх.сальдо по пене';
  insert into c_change_docs
    (mgchange, dtek, ts, user_id, text)
  values
    (l_mg, init.get_date, sysdate, l_user, l_comm)
  returning id into l_id;

  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select a.lsk, -1*sum(penya) as penya, a.dopl, init.get_date as dtek, sysdate as ts,
     l_user as fk_user, l_id as fk_doc
  from (
  select t.lsk, t.penya as penya, t.mg1 as dopl
    from a_penya t where t.lsk=p_lsk
    and t.mg=utils.add_months_pr(init.get_period,-1)
  union all
  select t.lsk, t.penya, t.dopl from c_pen_corr t where t.lsk=p_lsk
  ) a
  group by a.lsk, a.dopl
  having sum(penya) > 0;

  if sql%rowcount = 0 then
    return 1;
  else
    return 0;
  end if;
end;

--перенос ВСЕГО входящего сальдо по пене из меню движение по л/с на другой л/c
function corr_sal_pen2(p_lsk in kart.lsk%type, p_lsk2 in kart.lsk%type)
    return number is
  l_id number;
  l_user number;
  l_comm c_change_docs.text%type;
  l_ret number;
  l_mg params.period%type;
begin
  select u.id, p.period into l_user, l_mg from t_user u, params p where u.cd=user;
  l_comm:='Корректировка вх.сальдо по пене';
  insert into c_change_docs
    (mgchange, dtek, ts, user_id, text)
  values
    (l_mg, init.get_date, sysdate, l_user, l_comm)
  returning id into l_id;

  --перенести на другой л/c
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select p_lsk2 as lsk, sum(penya) as penya, a.dopl, init.get_date as dtek, sysdate as ts,
     l_user as fk_user, l_id as fk_doc
  from (
  select t.lsk, t.penya as penya, t.mg1 as dopl
    from a_penya t where t.lsk=p_lsk
    and t.mg=utils.add_months_pr(init.get_period,-1)
  union all
  select t.lsk, t.penya, t.dopl from c_pen_corr t where t.lsk=p_lsk
  ) a
  group by a.dopl
  having sum(penya) > 0;

  l_ret:= sql%rowcount;

  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select a.lsk, -1*sum(penya) as penya, a.dopl, init.get_date as dtek, sysdate as ts,
     l_user as fk_user, l_id as fk_doc
  from (
  select t.lsk, t.penya as penya, t.mg1 as dopl
    from a_penya t where t.lsk=p_lsk
    and t.mg=utils.add_months_pr(init.get_period,-1)
  union all
  select t.lsk, t.penya, t.dopl from c_pen_corr t where t.lsk=p_lsk
  ) a
  group by a.lsk, a.dopl
  having sum(penya) > 0;

  if l_ret =0 or sql%rowcount = 0 then
    Raise_application_error(-20000, '1='||l_ret||', '||sql%rowcount);
    return 1;
  else
    return 0;
  end if;
end;

end C_CPENYA;
/


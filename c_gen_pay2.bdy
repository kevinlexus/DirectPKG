create or replace package body scott.C_GEN_PAY2 is

procedure dist_all is
  l_mg params.period%type; --период месяц +1
begin
  l_mg:='201511';
  loop
      
    dist_mg(l_mg);
    l_mg:=utils.add_months_pr(l_mg, 1);
    exit when l_mg > '201608';
  end loop;      
            

end;

-- пакет предназначен для перераспределения оплат необходимых периодов (для последующего анализа)
-- распределить все платежи периода
procedure dist_mg (p_mg in params.period%type) is
  l_mg1 params.period%type; --период месяц +1
begin
  -- Внимание! предварительно загрузить вх.сальдо на период

  g_mg:=p_mg;
  l_mg1:=utils.add_months_pr(p_mg, 1);
  --почистить loader1.a_kwtp_day
  delete from loader1.kwtp_day t where t.mg=p_mg;

  --почистить loader1.a_saldo_usl (исх сальдо всё!)
  delete from loader1.a_saldo_usl t where t.mg=l_mg1;

  for c in (select t.lsk, t.summa, t.penya, t.oper, t.dopl, t.nink, t.nkom, t.dtek, t.nkvit,
                   t.dat_ink, t.ts, t.c_kwtp_id, t.rasp_id, t.mg, t.cnt_sch, t.cnt_sch0, t.id
                    from a_kwtp_mg t, kart k where t.lsk=k.lsk and k.reu in ('14','13') and t.mg=p_mg 
                    and t.lsk<>'77001395'
                    order by t.id) loop
    c_gen_pay2.dist_pay_lsk(c, 0);

  end loop;

  for c in (select distinct k.lsk
                    from arch_kart k where k.reu in ('14','13') and k.mg=p_mg 
                    and k.lsk<>'77001395'
                    ) loop
    --добавить корректировки оплаты 
    insert into loader1.kwtp_day
        (fk_distr, kwtp_id, lsk, summa, oper, dopl, nkom, nink, dat_ink, priznak, usl, org, dtek, mg)
       select decode(t.var,0,4,1,4, 12, 12, 4) as fk_distr, null, t.lsk, t.summa, '99' as oper,
         t.dopl,
         c.nkom, c.nink, t.dat, 1, t.usl, t.org, t.dat, p_mg as mg
         from t_corrects_payments t, c_comps c where c.nkom='999' and t.mg=p_mg and t.lsk=c.lsk
         and nvl(t.var,0)=0;
     
    --сформировать исх сальдо
    insert into loader1.a_saldo_usl(lsk, usl, org, summa, mg, uslm)
      select a.lsk, a.usl, a.org, sum(a.summa), l_mg1, u.uslm from (
      select t.lsk, t.usl, t.org, t.summa from loader1.a_saldo_usl t where t.mg=p_mg and t.lsk=c.lsk --вх.сальдо
      union all
      select t.lsk, t.usl, t.org, t.charges from scott.xitog3_lsk t where t.mg=p_mg and t.lsk=c.lsk --перерасчеты в т.ч.
      union all
      select t.lsk, t.usl, t.org, -1*t.summa from loader1.kwtp_day t where t.lsk=c.lsk and t.priznak=1 --новая оплата
       and t.mg=p_mg
       and t.mg=p_mg
      ) a join usl u on a.usl=u.usl
      group by a.lsk, a.usl, a.org, u.uslm;
      
  end loop;

        

  commit;
end;


-- распределение одного платежа
procedure dist_pay_lsk(rec2_ in a_kwtp_mg%rowtype, --строка из c_kwtp_mg
                       itr_ in number --номер итерации
                      ) is
  mg_ params.period%type;
  itg_ number;
  kr_ number;
  dt_ number;
  itr2_ number;
  excl_usl_ oper.fk_usl%type;
  chk_summa_ number;
  chk_penya_ number;
  l_reu kart.reu%type;
  --l_flag number;
begin
--ОПИСАНИЕ FK_DISTR
--распределение оплаты:
--0 полностью нулевое сальдо, распределить  по тек. начислению;
--1 полностью кредитовое сальдо, распределить  по тек. начислению;
--2  полностью дебетовое сальдо, распределить  по нему;
--3 корректирующая ПРОВОДКА - смешанное кредит/дебет сальдо
--4 корректировка из t_corrects_payment
--5 экслюзивное распределение оплаты на определенную услугу (Э+)

--6 - резерв C_DIST_PAY
--7 - резерв C_DIST_PAY
--8 - резерв C_DIST_PAY
--9 - резерв C_DIST_PAY

--10 - распределено в ручную из формы распределения оплаты
--11 полностью кредитовое сальдо, НО сумма снятия отрицательная (снять по кредитовому сальдо)
--13 обратный платёж, выполненный в c_get_pay.reverse_pay

--распределение оплаты по сальдо (версия от 10.04.12)
--текущий период
mg_:=g_mg;

--ВНИМАНИЕ! не осуществляется удаление строк из loader1.kwtp_day!!!
--(учитывать при возможном перераспределении средств)
--сделано для увеличения производительности процедуры

--№ итерации рекурсии
itr2_:=itr_;
if itr_ > 2 then
  Raise_application_error(-20000, 'Кол-во итераций по платежу с Л/C '||rec2_.lsk||' превысило 2!');
end if;

  --найти код РЭУ
  select k.reu into l_reu from kart k where k.lsk=rec2_.lsk;

  --взять только необходимую составляющую сальдо, если платёж <> 0
  --если не нулевой платёж (от корректировки по скрипту), а обычный платёж
  if itr_ = 0 then
    --почистить на 1-ой итерации (иначе, с предыдущ лицевых цепляется инфа)
    delete from temp_prep;
  end if;

  delete from temp_saldo;
  insert into temp_saldo
  (org, usl, summa)
  select a.org, a.usl, sum(a.summa)
  from (
  select s.org, s.usl, s.summa
            from loader1.a_saldo_usl s
           where mg = mg_ and s.lsk=rec2_.lsk
  union all
  select t.org, t.usl, -1*t.summa -- добавить уже сделанные в прошлых платежах корректировочные проводки!
            from loader1.kwtp_day t
            where t.fk_distr in (3,4) and t.lsk=rec2_.lsk
            and t.mg=mg_ --and t.kwtp_id <> rec2_.id
            ) a
   group by a.org, a.usl;

  --узнать какое сальдо
  select nvl(sum(summa),0) as itg, nvl(sum(decode(sign(t.summa), -1, t.summa, 0)),0) as kr,
  nvl(sum(decode(sign(t.summa), 1, t.summa, 0)),0) as dt into itg_, kr_, dt_
  from temp_saldo t;

  --проверка эксклюзивной услуги по операции
  select o.fk_usl into excl_usl_ from oper o where o.oper=rec2_.oper;

  if excl_usl_ is not null then
    --5 экслюзивное распределение оплаты на определенную услугу (Э+)
    dist_pay_var(l_reu, excl_usl_, rec2_, 3, 5);
  elsif itg_ = 0 and kr_ =0 and dt_=0 then
    --0 полностью нулевое сальдо, распределить  по тек. начислению;
    dist_pay_var(l_reu, null, rec2_, 0, 0);
  elsif kr_ <> 0 and dt_ <> 0 then
    --3 корректирующая ПРОВОДКА (специально для распределения вручную)
      dist_pay_var(l_reu, null, rec2_, 2, 3);
      --рекурсивный вызов себя же
      dist_pay_lsk(rec2_, itr2_+1);
  elsif kr_ = 0 and dt_ <> 0 then
    --2  полностью дебетовое сальдо, распределить  по нему;
   dist_pay_var(l_reu, null, rec2_, 1, 2);
  elsif kr_ <> 0 and dt_ = 0 and rec2_.summa >= 0 then
    --1 полностью кредитовое сальдо, сумма оплаты > 0 распределить  по тек. начислению (пени надеюсь нет при кредитовом сальдо)
   dist_pay_var(l_reu, null, rec2_, 0, 1);
  elsif kr_ <> 0 and dt_ = 0 and rec2_.summa < 0 then
    --11 полностью кредитовое сальдо, сумма оплаты < 0 распределить кредитовому сальдо (пени надеюсь нет при кредитовом сальдо)
   dist_pay_var(l_reu, null, rec2_, 11, 11);
  end if;
  --проверка распределения. отключить после выявления ошибки!
  --ред 04.05.12
  select nvl(sum(decode(t.priznak,1,summa,0)),0),
         nvl(sum(decode(t.priznak,0,summa,0)),0) into chk_summa_, chk_penya_
    from loader1.kwtp_day t where t.kwtp_id=rec2_.id and t.mg=g_mg;
  if chk_summa_ <> nvl(rec2_.summa,0) then
   -- rollback;  роллбэк в триггере не производится!
    Raise_application_error(-20000, 'Оплата не прошла! сумма1='||chk_summa_||', сумма2='||nvl(rec2_.summa,0)||' Сообщите программисту код ошибки C_GEN_PAY строка 127');
  end if;
  if chk_penya_ <> nvl(rec2_.penya,0) then
   -- rollback;  роллбэк в триггере не производится!
   Raise_application_error(-20000, 'Пеня не прошла! сумма1='||chk_penya_||', сумма2='||nvl(rec2_.penya,0)||' Сообщите программисту код ошибки C_GEN_PAY строка 130');
  end if;
--коммит не ставится, так как всё в триггере крутится...
--commit;
end;

procedure dist_pay_var(p_reu in varchar2, excl_usl_ in oper.fk_usl%type, rec_ in a_kwtp_mg%rowtype, var_ in number, fk_distr_ in number)
  is
  itgchrg_ number;
  summa_ number;
  summa_itg_ number;
  summap_ number;
  summap_itg_ number;
  last_id_ loader1.kwtp_day.id%type;
  lastp_id_ loader1.kwtp_day.id%type;
  org_ a_nabor2.org%type;
  trgt_usl_ usl.usl%type;
  l_sum_test number;
  l_sum_test2 number;
  l_cnt_tst number;
  l_last_org loader1.kwtp_day.org%type;
  l_last_usl loader1.kwtp_day.usl%type;
begin
  --"новое" распределение оплаты и пени ред 16.04.12
  --услуга, на которую распр пеня и оплата, неудачно распределившаяся
  trgt_usl_:=utils.get_str_param('ZERO_SAL');
  if trgt_usl_ is null then
    Raise_application_error(-20000, 'Параметр ZERO_SAL равен пустому значению!');
  end if;
  --варианты распределения оплаты/пени
  if var_ = 3 then
  --экслюзивное распределение оплаты на определенную услугу (Э+)
    begin
    select t.fk_org2 into org_ from a_nabor2 n, t_org t
           where n.usl = excl_usl_
             and n.lsk=rec_.lsk
             and n.org=t.id
             and g_mg between n.mgFrom and n.mgTo;
    exception
      when no_data_found then
      select t.fk_org2 into org_ from kart k, t_org t
             where k.reu=t.reu
               and k.lsk=rec_.lsk;
    end;
    if rec_.summa <> 0 then
    --сумма оплаты
      insert into loader1.kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek, mg)
      values
        (fk_distr_, rec_.id, rec_.lsk, excl_usl_, org_, rec_.summa, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek, g_mg)
      returning id into last_id_;
    end if;
    --пеня здесь никуда не перераспределяется
    if rec_.penya <> 0 then
      insert into loader1.kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek, mg)
      values
        (fk_distr_, rec_.id, rec_.lsk, excl_usl_, org_, rec_.penya, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 0, rec_.dtek, g_mg)
      returning id into last_id_;
    end if;
  elsif var_ = 2 then
  --корректирующая проводка
  --переносим с кредита на дебет

  --загружаем на обработку массив кредитового сальдо
    delete from temp_prep;
    insert into temp_prep
      (usl, org, summa, tp_cd)
    select s.usl, s.org, s.summa, 0 as tp_cd
      from temp_saldo s;
    --обрабатываем
    c_prep.dist_summa;
    --получаем обработанный массив (корректировки)
    insert into loader1.kwtp_day
      (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek, mg)
    select
      fk_distr_, rec_.id, rec_.lsk, t.usl, t.org, -1*t.summa, rec_.oper, rec_.dopl,
      rec_.nkom, rec_.nink, rec_.dat_ink, 1 as priznak, rec_.dtek, g_mg
      from temp_prep t where t.tp_cd in (3,4)
      and t.summa <> 0;

  elsif var_ in (11) then
  --отрицательную сумму по кредитовому сальдо
    if rec_.summa <> 0 then
      l_sum_test:=rec_.summa;
      l_cnt_tst:=0;
      --попытка распределить оплату меньше чем за 10000 циклов
      while l_sum_test <> 0 and l_cnt_tst < 10000
      loop
        dist_pay_prep(rec_, l_sum_test, fk_distr_, l_sum_test2, 1, null);
        l_sum_test:=l_sum_test-l_sum_test2;
        l_cnt_tst:=l_cnt_tst+1;
      end loop;

      --если не распределилось
      if l_sum_test <> 0 then
        --попытка принудительно распределить по дебетовому сальдо
        l_sum_test:=rec_.summa;
        l_cnt_tst:=0;
        --попытка распределить оплату меньше чем за 10000 циклов
        while l_sum_test <> 0 and l_cnt_tst < 10000
        loop
          dist_pay_prep(rec_, l_sum_test, fk_distr_, l_sum_test2, 1, 1);
          l_sum_test:=l_sum_test-l_sum_test2;
          l_cnt_tst:=l_cnt_tst+1;
        end loop;
      end if;

      --получаем обработанный массив (корректировки)
      if l_sum_test <> 0 then
        Raise_application_error(-20000, 'Большое кол-во циклов распределения оплаты в л/c, '||rec_.lsk||' период:'||rec_.mg);
      end if;

    end if;

    --тоже по пене (НО её не должно быть, по лс. с кредит.сальдо!!!!)
    --положительная или отрицательная пеня может быть,
    --если проводят корректировку - и + по оплате и пене соответственно
    if rec_.penya <> 0 then
    --если пеня положительная-
    --распределить по дебетовому сальдо
    --отрицательную - по кредитовому
      l_sum_test:=rec_.penya;
      l_cnt_tst:=0;
      --попытка распределить оплату меньше чем за 10000 циклов
      while l_sum_test <> 0 and l_cnt_tst < 10000
      loop
        dist_pay_prep(rec_, l_sum_test, fk_distr_, l_sum_test2, 0, null);
        l_sum_test:=l_sum_test-l_sum_test2;
        l_cnt_tst:=l_cnt_tst+1;
      end loop;

      --если не распределилось
      if l_sum_test <> 0 then
        --попытка принудительно распределить по дебетовому сальдо
        l_sum_test:=rec_.penya;
        l_cnt_tst:=0;
        --попытка распределить оплату меньше чем за 10000 циклов
        while l_sum_test <> 0 and l_cnt_tst < 10000
        loop
          if rec_.penya > 0 then
            dist_pay_prep(rec_, l_sum_test, fk_distr_, l_sum_test2, 0, -1);
          else
            dist_pay_prep(rec_, l_sum_test, fk_distr_, l_sum_test2, 0, 1);
          end if;
          l_sum_test:=l_sum_test-l_sum_test2;
          l_cnt_tst:=l_cnt_tst+1;
        end loop;
      end if;

      if l_sum_test <> 0 then
        Raise_application_error(-20000, 'Ошибка распределения пени в л/c '||rec_.lsk);
      end if;
    end if;


  elsif var_ in (0,1) then
  if var_ = 0 then
  --по начислению
      delete from temp_charge;

      insert into temp_charge
        (summa, org, usl)
        select
          sum(p.summa) as summa, t.fk_org2, p.usl
          from a_charge2 p, a_nabor2 k, t_org t
         where p.type = 1
           and k.usl = p.usl
           and k.lsk=p.lsk
           and p.lsk=rec_.lsk
           and k.org=t.id
           and g_mg between p.mgFrom and p.mgTo
           and g_mg between k.mgFrom and k.mgTo
         group by t.fk_org2, p.usl
         having sum(p.summa) <> 0;

      select nvl(sum(summa),0) into itgchrg_ from
         temp_charge;

  elsif var_ = 1 then
  --по дебетовому сальдо
      select nvl(sum(summa),0) into itgchrg_ from
         temp_saldo;

  end if;

  summa_:=0;
  summa_itg_:=0;
  summap_:=0;
  summap_itg_:=0;
  if itgchrg_ <> 0 then
  --есть начисление/сальдо
  for c2 in (select org, usl, summa from temp_charge t where var_=0
        union all
        select org, usl, summa from temp_saldo t where var_=1)
  loop
    summa_:=round(c2.summa/itgchrg_ * rec_.summa,2);
    summa_itg_:=summa_itg_+summa_;
    summap_:=round(c2.summa/itgchrg_ * rec_.penya,2);
    summap_itg_:=summap_itg_+summap_;
    --запомнить последние услугу и орг. с перенаправлением
    redirect(p_tp => 1, p_reu => p_reu, p_usl_src => c2.usl, p_usl_dst => l_last_usl, p_org_src => c2.org, p_org_dst => l_last_org);
    --оплата
    if summa_ <> 0 then
      --перенаправление оплаты
      redirect(p_tp => 1, p_reu => p_reu, p_usl_src => c2.usl, p_usl_dst => trgt_usl_, p_org_src => c2.org, p_org_dst => org_);
      insert into loader1.kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek, mg)
      values
        (fk_distr_, rec_.id, rec_.lsk, trgt_usl_, org_, summa_, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek, g_mg)
      returning id into last_id_;
    end if;

    --пеня
    if rec_.penya <> 0 then
      --перенаправление пени
      redirect(p_tp => 0, p_reu => p_reu, p_usl_src => c2.usl, p_usl_dst => trgt_usl_, p_org_src => c2.org, p_org_dst => org_);
      if summap_ <> 0 then
        insert into loader1.kwtp_day
          (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek, mg)
        values
          (fk_distr_, rec_.id, rec_.lsk,  trgt_usl_, org_, summap_, rec_.oper, rec_.dopl,
          rec_.nkom, rec_.nink, rec_.dat_ink, 0, rec_.dtek, g_mg)
        returning id into lastp_id_;
      end if;

    end if;

  end loop;
  if summa_itg_ <> rec_.summa and last_id_ is not null then
     --остаток на последнюю строку распределения
     c_get_pay.g_flag_upd:=1;
     update loader1.kwtp_day t set t.summa=t.summa+(rec_.summa-summa_itg_)
      where t.id=last_id_ and t.mg=g_mg;
     c_get_pay.g_flag_upd:=0;

     summa_itg_:=summa_itg_+(rec_.summa-summa_itg_);
   elsif summa_itg_ <> rec_.summa and last_id_ is null then
     --если программа вообще не заходила в цикл (выше) - бывает при распр. 0.01 руб
      insert into loader1.kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek, mg)
      values
        (fk_distr_, rec_.id, rec_.lsk, l_last_usl, l_last_org, rec_.summa-summa_itg_,
         rec_.oper, rec_.dopl,
         rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek, g_mg);
     summa_itg_:=summa_itg_+(rec_.summa-summa_itg_);
  end if;

  if summap_itg_ <> rec_.penya and lastp_id_ is not null then
   --остаток на последнюю строку распределения
   c_get_pay.g_flag_upd:=1;
   update loader1.kwtp_day t set t.summa=t.summa+(rec_.penya-summap_itg_)
    where t.id=lastp_id_ and t.mg=g_mg;
      summap_itg_:=summap_itg_+(rec_.penya-summap_itg_);
   c_get_pay.g_flag_upd:=0;

   elsif summap_itg_ <> rec_.penya and lastp_id_ is null then
     --если программа вообще не заходила в цикл (выше) - бывает при распр. 0.01 руб
      insert into loader1.kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek, mg)
      values
        (fk_distr_, rec_.id, rec_.lsk, trgt_usl_, org_, rec_.penya-summap_itg_,
         rec_.oper, rec_.dopl,
         rec_.nkom, rec_.nink, rec_.dat_ink, 0, rec_.dtek, g_mg);
      summap_itg_:=summap_itg_+(rec_.penya-summap_itg_);
  end if;

  else
    --нет начисления/сальдо, для распределения, устанавливаем всю оплату на trgt_usl_ услугу, поставщика - УК в фонде
    if rec_.summa <> 0 then
      insert into loader1.kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek, mg)
      select
        fk_distr_, rec_.id, rec_.lsk, trgt_usl_, t.fk_org2, rec_.summa, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek, g_mg from t_org t, kart k
        where t.reu=k.reu and k.lsk=rec_.lsk;
      summa_itg_:=summa_itg_+rec_.summa;

    end if;

    --пеня
    if rec_.penya <> 0 then
      insert into loader1.kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek, mg)
      select
        fk_distr_, rec_.id, rec_.lsk, trgt_usl_, t.fk_org2, rec_.penya, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 0, rec_.dtek, g_mg from t_org t, kart k
        where t.reu=k.reu and k.lsk=rec_.lsk;
      summap_itg_:=summap_itg_+rec_.penya;

    end if;

  end if;

  --проверка распределения оплаты
  if summa_itg_ <> rec_.summa then
    Raise_application_error(-20000, 'Ошибка распределения оплаты в л/c '||rec_.lsk);
  end if;


  if summap_itg_ <> rec_.penya then
    Raise_application_error(-20000, 'Ошибка распределения пени в л/c '||rec_.lsk);
  end if;

end if;

end;

procedure dist_pay_prep(rec_ in a_kwtp_mg%rowtype, l_summa in number,
  fk_distr_ in number, l_itg out number, l_priznak in loader1.kwtp_day.priznak%type,
  l_forсesign in number) is
l_sign number;
l_add_sign number;
begin
--подготовка к распределению
--l_summa - если отрицательная, то распределять по кредитовому сальдо
--если положительное, то распределять по дебетовому сальдо...

  --принудительно распределить по кредитовому (l_forсesign=-1)
  --или дебетовому (l_forсesign=1) сальдо

  if l_forсesign is not null then
    l_sign:=sign(l_forсesign);
    l_add_sign:=sign(l_forсesign);
  else
    l_sign:=sign(l_summa);
    l_add_sign:=1;
  end if;

  delete from temp_prep;
  insert into temp_prep
    (usl, org, summa, tp_cd)
  select s.usl, s.org, s.summa, 0 as tp_cd
    from temp_saldo s
     where l_sign < 0 and s.summa < 0 or l_sign >= 0 and s.summa > 0
    union all
    select 'XXX' as usl, -1, l_add_sign*-1*l_summa, 0 as tp_cd
    from dual;
  --обрабатываем
  c_prep.dist_summa;

  if l_priznak=1 then
    --оплата
    insert into loader1.kwtp_day
      (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek, mg)
    select
      fk_distr_, rec_.id, rec_.lsk, t.usl, t.org, l_add_sign*-1*t.summa, rec_.oper, rec_.dopl,
      rec_.nkom, rec_.nink, rec_.dat_ink, l_priznak, rec_.dtek, g_mg
      from temp_prep t where t.tp_cd in (3,4) and t.usl <> 'XXX';

    select nvl(sum(l_add_sign*-1*t.summa),0) into l_itg
           from temp_prep t
           where t.tp_cd in (3,4) and t.usl <> 'XXX'
           and t.summa <> 0;
  elsif l_priznak=0 then
    --пеня
    insert into loader1.kwtp_day
      (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek, mg)
    select
      fk_distr_, rec_.id, rec_.lsk, u.fk_usl_pen,
        case when t.usl <> u.fk_usl_pen then o.fk_org2 --есть перенаправление услуги
             when t.usl = u.fk_usl_pen then t.org --нет перенаправления услуг
             end as org,
       l_add_sign*-1*t.summa, rec_.oper, rec_.dopl,
      rec_.nkom, rec_.nink, rec_.dat_ink, l_priznak, rec_.dtek, g_mg
      from kart k, temp_prep t, usl u, t_org o where t.tp_cd in (3,4) and t.usl <> 'XXX'
      and t.usl=u.usl
      and k.lsk=rec_.lsk
      and k.reu=o.reu;

    select nvl(sum(l_add_sign*-1*t.summa),0) into l_itg
           from temp_prep t
           where t.tp_cd in (3,4) and t.usl <> 'XXX'
           and t.summa <> 0;

  end if;

end;

--редирект оплаты/пени
procedure redirect (p_tp in number, --1-оплата, 0 - пеня
                        p_reu in varchar2, --код РЭУ
                        p_usl_src in varchar2, --исходная услуга
                        p_usl_dst out varchar2, --исходная орг.
                        p_org_src in number, --перенаправленная услуга
                        p_org_dst out number --перенаправленная орг.
                        ) is
  l_usl_flag number; --флаг состоявшегося переноса по услуге
  l_org_flag number; --флаг состоявшегося переноса по организации
begin

l_usl_flag:=0;
l_org_flag:=0;
p_usl_dst:=p_usl_src;
p_org_dst:=p_org_src;

for c in (select * from redir_pay t where
                                  nvl(t.reu, p_reu)=p_reu and --либо заполненное РЭУ=вход.РЭУ, либо пусто (редирект для всех РЭУ)
                                  nvl(t.fk_usl_src, p_usl_src)=p_usl_src and --либо заполненное УСЛ=вход.УСЛ, либо пусто (редирект для всех услуг)
                                  nvl(t.fk_org_src, p_org_src)=p_org_src --либо заполненное ОРГ=вход.ОРГ, либо пусто (редирект для всех организаций)
                                  and t.tp=p_tp
                                  order by
                                  case when t.reu=p_reu then 0 else 1 end,
                                  case when t.fk_usl_src=p_usl_src then 0 else 1 end,
                                  case when t.fk_org_src=p_org_src then 0 else 1 end
             ) loop

  if c.fk_usl_dst is not null then
    p_usl_dst:=c.fk_usl_dst;
    l_usl_flag:=1;
  end if;
  if c.fk_org_dst is not null then
    if c.fk_org_dst=-1 then --перенаправить на организацию, обслуживающую фонд
       select o.id into p_org_dst from t_org o
          where o.reu=p_reu;
    else
       p_org_dst:=c.fk_org_dst;
    end if;
    l_org_flag:=1;
  end if;

  if l_usl_flag=1 and l_org_flag=1 then
    exit; --нашли все переносы
  end if;

end loop;

end;

end C_GEN_PAY2;
/


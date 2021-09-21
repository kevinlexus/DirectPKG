create or replace package body scott.c_gen_pay is

PROCEDURE distrib_payment_mg IS
  l_Java_deb_pen number;
begin
--распределение оплаты по периодам
--подправить newreu
l_Java_deb_pen := utils.get_int_param('JAVA_DEB_PEN');
for c in (select * from c_kwtp t where exists
(select * from c_kwtp_mg m where m.c_kwtp_id=t.id and m.lsk in
(select substr(t.comments,1,8) as lsk from log t where to_char(t.timestampm,'DDMMYYYYHH')='0102201009' or
to_char(t.timestampm,'DDMMYYYYHH')='0102201010')))
loop
   logger.log_(null,
          'распределяем: ' || c.lsk);
  c_get_pay.get_payment_mg(c.id, c.nkvit,
  c.lsk, c.summa, c.penya, c.oper, c.dopl, c.iscorrect, c.nkom, c.dtek, c.nink, c.dat_ink, l_Java_deb_pen);
  commit;
end loop;
end;

PROCEDURE distrib_days(dat1_ in date, dat2_ in date) IS
begin
--распределялка по дням
 for c in (select distinct dat_ink from c_kwtp_mg t where t.dat_ink between dat1_ and dat2_
  order by t.dat_ink)
 loop
   distrib_days(c.dat_ink, c.dat_ink);
   logger.log_(null,
          'c_gen_pay.distrib_payment ' || to_char(c.dat_ink,'DD-MM-YYYY'));
 end loop;

end;

--распределение оплаты
procedure dist_pay_lsk(rec2_ in c_kwtp_mg%rowtype, --строка из c_kwtp_mg
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
  l_flag number;
begin
/*
    TODO: owner="lev" created="10.04.2012"
    text="сделать очистку kwtp_day по концу месяца"
*/

--ОПИСАНИЕ FK_DISTR
--распределение оплаты:
--0 полностью нулевое сальдо, распределить  по тек. начислению;
--1 полностью кредитовое сальдо, распределить  по тек. начислению;
--2	полностью дебетовое сальдо, распределить  по нему;
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
select p.period into mg_ from params p;

--ВНИМАНИЕ! не осуществляется удаление строк из kwtp_day!!!
--(учитывать при возможном перераспределении средств)
--сделано для увеличения производительности процедуры

--№ итерации рекурсии
itr2_:=itr_;
if itr_ > 2 then
  Raise_application_error(-20000, 'Кол-во итераций по платежу с Л/C '||rec2_.lsk||' превысило 2!');
end if;

  --найти код РЭУ
  select k.reu into l_reu from kart k where k.lsk=rec2_.lsk;
  
  --предварительно узнать, какое сальдо
  select nvl(sum(summa),0) as itg, nvl(sum(decode(sign(t.summa), -1, t.summa, 0)),0) as kr,
   nvl(sum(decode(sign(t.summa), 1, t.summa, 0)),0) as dt into itg_, kr_, dt_
   from saldo_usl t
   where t.mg = mg_ and t.lsk=rec2_.lsk;

  if abs(kr_) <> 0 and abs(dt_) <> 0 and rec2_.summa < 0 then --если присут. и дебет и кредит сальдо и сумма оплаты < 0
    l_flag:=1;
  elsif abs(kr_) <> 0 and abs(dt_) <> 0 and rec2_.summa > 0 then --если присут. и дебет и кредит сальдо и сумма оплаты > 0
    l_flag:=2;
  else 
    l_flag:=0;
  end if;
   
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
            from saldo_usl s
           where mg = mg_ and s.lsk=rec2_.lsk
  union all
  select t.org, t.usl, t.summa
            from temp_prep t
            where t.tp_cd in (3,4)) a
   group by a.org, a.usl
   having (l_flag = 1 and sum(a.summa) < 0 or  --взять отрицат
          l_flag in (0,2) and sum(a.summa) > 0 --взять положит.
          or (nvl(rec2_.summa,0) = 0 and nvl(rec2_.penya,0) = 0) --взять все, если распределяется нулевое значение
          );
  --еще раз узнать какое сальдо
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
    --3 корректирующая ПРОВОДКА - смешанное кредит/дебет сальдо (только из скрипта! и только НУЛЕВУЮ сумму!) 
    if nvl(rec2_.summa,0) = 0 and nvl(rec2_.penya,0) = 0 then
      dist_pay_var(l_reu, null, rec2_, 2, 3);
      --рекурсивный вызов себя же
      dist_pay_lsk(rec2_, itr2_+1);
    else 
      Raise_application_error(-20000, 'Error #1'); --отменить корректирующую проводку
    end if;
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
    from kwtp_day t where t.kwtp_id=rec2_.id;
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

procedure dist_pay_var(p_reu in varchar2, excl_usl_ in oper.fk_usl%type, rec_ in c_kwtp_mg%rowtype, var_ in number, fk_distr_ in number)
  is
  itgchrg_ number;
  summa_ number;
  summa_itg_ number;
  summap_ number;
  summap_itg_ number;
  kr_summa_ number;
  last_id_ kwtp_day.id%type;
  lastp_id_ kwtp_day.id%type;
  org_ nabor.org%type;
  trgt_usl_ usl.usl%type;
  l_sum_test number;
  l_sum_test2 number;
  l_cnt_tst number;
  l_last_org kwtp_day.org%type;
  l_last_usl kwtp_day.usl%type;
  l_org_uk number;
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
    select t.fk_org2 into org_ from nabor n, t_org t
           where n.usl = excl_usl_
             and n.lsk=rec_.lsk
             and n.org=t.id;
    exception
      when no_data_found then
      select t.fk_org2 into org_ from kart k, t_org t
             where k.reu=t.reu
               and k.lsk=rec_.lsk;
    end;
    if rec_.summa <> 0 then
    --сумма оплаты
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      values
        (fk_distr_, rec_.id, rec_.lsk, excl_usl_, org_, rec_.summa, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek)
      returning id into last_id_;
    end if;
    --пеня здесь никуда не перераспределяется
    if rec_.penya <> 0 then
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      values
        (fk_distr_, rec_.id, rec_.lsk, excl_usl_, org_, rec_.penya, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 0, rec_.dtek)
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
    insert into kwtp_day
      (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
    select
      fk_distr_, rec_.id, rec_.lsk, t.usl, t.org, -1*t.summa, rec_.oper, rec_.dopl,
      rec_.nkom, rec_.nink, rec_.dat_ink, 1 as priznak, rec_.dtek
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
        Raise_application_error(-20000, 'Большое кол-во циклов распределения оплаты в л/c '||rec_.lsk);
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
          from c_charge p, nabor k, t_org t
         where p.type = 1
           and k.usl = p.usl
           and k.lsk=p.lsk
           and p.lsk=rec_.lsk
           and k.org=t.id
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
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      values
        (fk_distr_, rec_.id, rec_.lsk, trgt_usl_, org_, summa_, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek)
      returning id into last_id_;
    end if;

    --пеня
    if rec_.penya <> 0 then
      --перенаправление пени
      redirect(p_tp => 0, p_reu => p_reu, p_usl_src => c2.usl, p_usl_dst => trgt_usl_, p_org_src => c2.org, p_org_dst => org_);
      if summap_ <> 0 then
        insert into kwtp_day
          (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
        values
          (fk_distr_, rec_.id, rec_.lsk,  trgt_usl_, org_, summap_, rec_.oper, rec_.dopl,
          rec_.nkom, rec_.nink, rec_.dat_ink, 0, rec_.dtek)
        returning id into lastp_id_;
      end if;

    end if;

  end loop;
  if summa_itg_ <> rec_.summa and last_id_ is not null then
     --остаток на последнюю строку распределения
     c_get_pay.g_flag_upd:=1;
     update kwtp_day t set t.summa=t.summa+(rec_.summa-summa_itg_)
      where t.id=last_id_;
     c_get_pay.g_flag_upd:=0;
     
     summa_itg_:=summa_itg_+(rec_.summa-summa_itg_);
   elsif summa_itg_ <> rec_.summa and last_id_ is null then
     --если программа вообще не заходила в цикл (выше) - бывает при распр. 0.01 руб
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      values
        (fk_distr_, rec_.id, rec_.lsk, l_last_usl, l_last_org, rec_.summa-summa_itg_,
         rec_.oper, rec_.dopl,
         rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek);
     summa_itg_:=summa_itg_+(rec_.summa-summa_itg_);
  end if;

  if summap_itg_ <> rec_.penya and lastp_id_ is not null then
   --остаток на последнюю строку распределения
   c_get_pay.g_flag_upd:=1;
   update kwtp_day t set t.summa=t.summa+(rec_.penya-summap_itg_)
    where t.id=lastp_id_;
      summap_itg_:=summap_itg_+(rec_.penya-summap_itg_);
   c_get_pay.g_flag_upd:=0;
      
   elsif summap_itg_ <> rec_.penya and lastp_id_ is null then
     --если программа вообще не заходила в цикл (выше) - бывает при распр. 0.01 руб
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      values
        (fk_distr_, rec_.id, rec_.lsk, trgt_usl_, org_, rec_.penya-summap_itg_,
         rec_.oper, rec_.dopl,
         rec_.nkom, rec_.nink, rec_.dat_ink, 0, rec_.dtek);
      summap_itg_:=summap_itg_+(rec_.penya-summap_itg_);
  end if;

  else
    --нет начисления/сальдо, для распределения, устанавливаем всю оплату на trgt_usl_ услугу, поставщика - УК в фонде
    if rec_.summa <> 0 then
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      select
        fk_distr_, rec_.id, rec_.lsk, trgt_usl_, t.fk_org2, rec_.summa, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek from t_org t, kart k
        where t.reu=k.reu and k.lsk=rec_.lsk;
      summa_itg_:=summa_itg_+rec_.summa;

    end if;

    --пеня
    if rec_.penya <> 0 then
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      select
        fk_distr_, rec_.id, rec_.lsk, trgt_usl_, t.fk_org2, rec_.penya, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 0, rec_.dtek from t_org t, kart k
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

procedure dist_pay_prep(rec_ in c_kwtp_mg%rowtype, l_summa in number,
  fk_distr_ in number, l_itg out number, l_priznak in kwtp_day.priznak%type,
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
    insert into kwtp_day
      (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
    select
      fk_distr_, rec_.id, rec_.lsk, t.usl, t.org, l_add_sign*-1*t.summa, rec_.oper, rec_.dopl,
      rec_.nkom, rec_.nink, rec_.dat_ink, l_priznak, rec_.dtek
      from temp_prep t where t.tp_cd in (3,4) and t.usl <> 'XXX';

    select nvl(sum(l_add_sign*-1*t.summa),0) into l_itg
           from temp_prep t
           where t.tp_cd in (3,4) and t.usl <> 'XXX'
           and t.summa <> 0;
  elsif l_priznak=0 then
    --пеня
    insert into kwtp_day
      (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
    select
      fk_distr_, rec_.id, rec_.lsk, u.fk_usl_pen,
        case when t.usl <> u.fk_usl_pen then o.fk_org2 --есть перенаправление услуги
             when t.usl = u.fk_usl_pen then t.org --нет перенаправления услуг
             end as org,
       l_add_sign*-1*t.summa, rec_.oper, rec_.dopl,
      rec_.nkom, rec_.nink, rec_.dat_ink, l_priznak, rec_.dtek
      from kart k, temp_prep t, usl u, t_org o where t.tp_cd in (3,4) and t.usl <> 'XXX'
      and t.usl=u.usl
      and k.lsk=rec_.lsk
      and k.reu=o.reu;

    select nvl(sum(l_add_sign*-1*t.summa),0) into l_itg
           from temp_prep t
           where t.tp_cd in (3,4) and t.usl <> 'XXX'
           and t.summa <> 0;

  end if;

/*    if rec_.penya <> 0 then
    begin
      select o.fk_org2, s.fk_usl_pen into org_, trgt_usl_ from kart k, t_org o, usl s
          where k.lsk=rec_.lsk and k.reu=o.reu and s.usl=c2.usl
          and not exists --где пеня перенаправляется на trgt_usl_
           (select * from usl u where u.fk_usl_pen=c2.usl and u.usl=c2.usl);

--ред. 19.04.12
--      select o.fk_org2 into org_ from kart k, t_org o
--            where k.lsk=rec_.lsk and k.reu=o.reu;
    exception
     when no_data_found then
       --нет перенаправления пени
       org_:=c2.org;
       trgt_usl_:=c2.usl;
    end;*/


end;

procedure dist_pay_var2(excl_usl_ in oper.fk_usl%type, rec_ in c_kwtp_mg%rowtype, var_ in number, fk_distr_ in number)
  is
  itgchrg_ number;
  summa_ number;
  summa_itg_ number;
  summap_ number;
  summap_itg_ number;
  kr_summa_ number;
  last_id_ kwtp_day.id%type;
  lastp_id_ kwtp_day.id%type;
  org_ nabor.org%type;
  trgt_usl_ usl.usl%type;
begin
  --"новое" распределение оплаты и пени ред 16.04.12
  Raise_application_error(-20000, 'СТАРЫЙ ВАРИАНТ, ДО 26.03.13');

  --услуга, на которую распр пеня и оплата, неудачно распределившаяся
  trgt_usl_:=utils.get_str_param('ZERO_SAL');
  if trgt_usl_ is null then
    Raise_application_error(-20000, 'Параметр ZERO_SAL равен пустому значению!');
  end if;
  --варианты распределения оплаты/пени
  if var_ = 3 then
  --экслюзивное распределение оплаты на определенную услугу (Э+)
    begin
    select t.fk_org2 into org_ from nabor n, t_org t
           where n.usl = excl_usl_
             and n.lsk=rec_.lsk
             and n.org=t.id;
    exception
      when no_data_found then
      select t.fk_org2 into org_ from kart k, t_org t
             where k.reu=t.reu
               and k.lsk=rec_.lsk;
    end;
    if rec_.summa <> 0 then
    --сумма оплаты
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      values
        (fk_distr_, rec_.id, rec_.lsk, excl_usl_, org_, rec_.summa, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek)
      returning id into last_id_;
    end if;
    --пеня здесь никуда не перераспределяется
    if rec_.penya <> 0 then
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      values
        (fk_distr_, rec_.id, rec_.lsk, excl_usl_, org_, rec_.penya, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 0, rec_.dtek)
      returning id into last_id_;
    end if;
  elsif var_ = 2 then
  --корректирующая проводка
  --переносим с кредита на дебет
  for kr in (select s.org, s.usl, s.summa--кредитовое сальдо
                      from temp_saldo s
              where s.summa < 0) --ред 03.06.12
    /*
    select s.org, s.usl, s.summa
                      from temp_saldo s --кредитовое сальдо
                     where s.summa < 0)*/

  loop
  kr_summa_:=abs(kr.summa);
  while kr_summa_ <> 0
  loop
  for dt in (select t.org,
                 t.usl,
                 sum(t.summa) as summa
            from (select s.org, s.usl, s.summa
                    from temp_saldo s
                  union all
                select t.org, t.usl, -1*t.summa
                  from kwtp_day t-- учёт корректир проводки (здесь надо учесть иначе перекредитуешь!!!)
                 where t.fk_distr=3 and t.priznak=1 and t.kwtp_id=rec_.id
                 /*and t.dat_ink between init.g_dt_cur_start and init.g_dt_cur_end*/) t
           group by t.org, t.usl
           having sum(t.summa)>0 )
  loop

    if kr_summa_ > dt.summa then
        insert into kwtp_day
          (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
        values
          (fk_distr_, rec_.id, rec_.lsk, kr.usl, kr.org, -1 * dt.summa, rec_.oper, rec_.dopl,
          rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek);

        insert into kwtp_day
          (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
        values
          (fk_distr_, rec_.id, rec_.lsk, dt.usl, dt.org, dt.summa, rec_.oper, rec_.dopl,
          rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek);

        kr_summa_:=kr_summa_-dt.summa;
--        commit;
    elsif kr_summa_ <= dt.summa then
        insert into kwtp_day
          (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
        values
          (fk_distr_, rec_.id, rec_.lsk, kr.usl, kr.org, -1 * kr_summa_, rec_.oper, rec_.dopl,
          rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek);

        insert into kwtp_day
          (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
        values
          (fk_distr_, rec_.id, rec_.lsk, dt.usl, dt.org, kr_summa_, rec_.oper, rec_.dopl,
          rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek);

        kr_summa_:=0;
--        commit;

    end if;
    if kr_summa_ = 0 then
     --выйти из цикла погашения кредит.сальдо
     exit;
    end if;


  end loop;

  if kr_summa_ <>0 then
  --кредитовая сумма не смогла погаситься полностью, выход (результат- всё сальдо кредитовое)
   exit;
  end if;


  end loop;


  end loop;


  elsif var_ in (0,1) then
  if var_ = 0 then
  --по начислению
      delete from temp_charge;

      insert into temp_charge
        (summa, org, usl)
        select
          sum(p.summa) as summa, t.fk_org2, p.usl
          from c_charge p, nabor k, t_org t
         where p.type = 1
           and k.usl = p.usl
           and k.lsk=p.lsk
           and p.lsk=rec_.lsk
           and k.org=t.id
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
    --оплата
    if rec_.summa <> 0 then
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      values
        (fk_distr_, rec_.id, rec_.lsk, c2.usl, c2.org, summa_, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek)
      returning id into last_id_;

    end if;

    --пеня
    if rec_.penya <> 0 then
    begin
      select o.fk_org2, s.fk_usl_pen into org_, trgt_usl_ from kart k, t_org o, usl s
          where k.lsk=rec_.lsk and k.reu=o.reu and s.usl=c2.usl
          and not exists --где пеня перенаправляется на trgt_usl_
           (select * from usl u where u.fk_usl_pen=c2.usl and u.usl=c2.usl);

--ред. 19.04.12
--      select o.fk_org2 into org_ from kart k, t_org o
--            where k.lsk=rec_.lsk and k.reu=o.reu;
    exception
     when no_data_found then
       --нет перенаправления пени
       org_:=c2.org;
       trgt_usl_:=c2.usl;
    end;


      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      values
        (fk_distr_, rec_.id, rec_.lsk,  trgt_usl_, org_, summap_, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 0, rec_.dtek)
      returning id into lastp_id_;

    end if;

  end loop;
  if summa_itg_ <> rec_.summa then
   --остаток на последнюю строку распределения
   c_get_pay.g_flag_upd:=1;
   update kwtp_day t set t.summa=t.summa+(rec_.summa-summa_itg_)
    where t.id=last_id_;
   c_get_pay.g_flag_upd:=0;

   summa_itg_:=summa_itg_+(rec_.summa-summa_itg_);
  end if;

  if summap_itg_ <> rec_.penya then
   --остаток на последнюю строку распределения
   c_get_pay.g_flag_upd:=1;
   update kwtp_day t set t.summa=t.summa+(rec_.penya-summap_itg_)
    where t.id=lastp_id_;
   c_get_pay.g_flag_upd:=0;

    summap_itg_:=summap_itg_+(rec_.penya-summap_itg_);
  end if;

  else
    --нет начисления/сальдо, для распределения, устанавливаем всю оплату на trgt_usl_ услугу, поставщика - УК в фонде
    if rec_.summa <> 0 then
      summa_itg_:=summa_itg_+rec_.summa;
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      select
        fk_distr_, rec_.id, rec_.lsk, trgt_usl_, t.fk_org2, rec_.summa, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 1, rec_.dtek from t_org t, kart k
        where t.reu=k.reu and k.lsk=rec_.lsk;

    end if;

    --пеня
    if rec_.penya <> 0 then
      summap_itg_:=summap_itg_+rec_.penya;
      insert into kwtp_day
        (fk_distr, kwtp_id, lsk, usl, org, summa, oper, dopl, nkom, nink, dat_ink, priznak, dtek)
      select
        fk_distr_, rec_.id, rec_.lsk, trgt_usl_, t.fk_org2, rec_.penya, rec_.oper, rec_.dopl,
        rec_.nkom, rec_.nink, rec_.dat_ink, 0, rec_.dtek from t_org t, kart k
        where t.reu=k.reu and k.lsk=rec_.lsk;

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


/*procedure dist_pay_add_corr is
begin
--добавляем корректировки
--4 корректировка из t_corrects_payment
delete from kwtp_day t where t.nkom='999' and t.kwtp_id is null;
insert into kwtp_day
  (fk_distr, kwtp_id, lsk, summa, oper, dopl, nkom, nink, dat_ink, priznak, usl, org)
 select 4, null, t.lsk, t.summa, '99' as oper, t.dopl, c.nkom, c.nink, t.dat, 1, t.usl, t.org
   from t_corrects_payments t, c_comps c, params p where c.nkom='999' and t.mg=p.period
   and nvl(t.var,0) = 0;
end;
*/


procedure dist_pay_lsk_force is
rec_ c_kwtp_mg%rowtype;

begin
--принудительное распределение платежей
for c in (select t.* into rec_ from c_kwtp_mg t where
 not exists (select * from kwtp_day k where k.kwtp_id=t.id))
loop
  dist_pay_lsk(rec2_ => c, itr_ => 0);
commit;

end loop;

end;


-- загрузка внешней оплаты (ФКР)
procedure load_ext_pay is
  l_last_day_month date;
  l_period params.period%type;
begin
  select last_day(to_date(p.period||'01','YYYYMMDD')), p.period into l_last_day_month, l_period from params p;
  delete from c_kwtp t where t.nkom='904';
  delete from c_kwtp_mg t where t.nkom='904';
  delete from kwtp_day t where t.nkom='904';
  -- загрузка оплаты по внешним лиц.счетам, где установлен формат обмена, с получением вх.сальдо (Кис.ФКР), ред.13.05.21
  insert into c_kwtp(lsk,
                     summa,
                     penya,
                     oper,
                     dopl,
                     nink,
                     nkom,
                     dtek,
                     nkvit,
                     dat_ink,
                     ts,
                     iscorrect)
    select k.lsk, e.payment as summa, 0 as penya,
     c.fk_oper as oper, l_period as dopl,
     c.nink, c.nkom, l_last_day_month as dtek, 1 as nkvit, l_last_day_month as dat_ink, sysdate as ts, 
     1 as iscorrect
  from kart k join kart_ext e on k.lsk=e.lsk 
                       join t_org o on k.reu=o.reu and o.is_exchange_ext=1 and o.ext_lsk_format_tp=1
                       join c_comps c on c.nkom='904';
                         
  insert into c_kwtp_mg(lsk,
                        summa,
                        penya,
                        oper,
                        dopl,
                        nink,
                        nkom,
                        dtek,
                        nkvit,
                        dat_ink,
                        ts,
                        c_kwtp_id,
                        is_dist)
  select t.lsk, t.summa, t.penya, t.oper, t.dopl, t.nink, t.nkom, t.dtek, t.nkvit, t.dat_ink, t.ts, t.id as c_kwtp_id, 1 as is_dist
   from c_kwtp t where t.nkom='904';                                           

  insert into kwtp_day
      (fk_distr, kwtp_id, lsk, summa, oper, dopl, nkom, nink, dat_ink, priznak, usl, org, dtek)
  select 4 as fk_distr, t.id as kwtp_id, t.lsk, t.summa as summa,
   t.oper as oper, t.dopl,
   t.nkom, t.nink, t.dat_ink, 1 as priznak, 
   o.usl_for_create_ext_lsk as usl, o.id as org, l_last_day_month as dtek
   from c_kwtp_mg t join kart k on t.lsk=k.lsk
   join t_org o on k.reu=o.reu
   where t.nkom='904';                                           
  logger.log_(time_,'c_gen_pay.load_ext_pay');
end;  

procedure dist_pay_del_corr(p_lsk in kart.lsk%type default null) is
time_ date;

begin
  --удаление корректировок оплаты
  time_:=sysdate;
  if p_lsk is null then 
    delete from kwtp_day t where t.nkom in ('999');
    logger.log_(time_,'c_gen_pay.dist_pay_del_corr');
  else 
    delete from kwtp_day t where t.nkom in ('999') and t.lsk=p_lsk;
  end if;  
  commit;
end;


procedure dist_pay_add_corr(var_ in number, p_lsk in kart.lsk%type default null) is
time_ date;
l_last_day_month date;
l_period params.period%type;
begin
  -- убрал все эти var_=1!!! ред. 09.10.2017
  time_:=sysdate;
  select last_day(to_date(p.period||'01','YYYYMMDD')), p.period into l_last_day_month, l_period from params p;
  --добавляем корректировки оплаты
  --тип-4 корректировка из t_corrects_payment (либо var_=0,null - до предварительного форм.сальдо, 1- после)
  --тип-11 корректировка которая НЕ должна пройти в c_deb_usl
  if p_lsk is null then   
    insert into kwtp_day
    (fk_distr, kwtp_id, lsk, summa, oper, dopl, nkom, nink, dat_ink, priznak, usl, org, dtek)
    select decode(t.var,0,4,1,4, 12, 12, 4) as fk_distr, null, t.lsk, t.summa,
     decode(utils.get_int_param('IS_LONG_OPER_CODE'),1,'099','99') as oper,
    t.dopl,
    c.nkom, c.nink, t.dat, 1, t.usl, t.org, t.dat
    from t_corrects_payments t, c_comps c, params p where c.nkom='999' and t.mg=p.period;
    
    logger.log_(time_,'c_gen_pay.dist_pay_add_corr');
  else
    insert into kwtp_day
    (fk_distr, kwtp_id, lsk, summa, oper, dopl, nkom, nink, dat_ink, priznak, usl, org, dtek)
    select decode(t.var,0,4,1,4, 12, 12, 4) as fk_distr, null, t.lsk, t.summa, 
    decode(utils.get_int_param('IS_LONG_OPER_CODE'),1,'099','99') as oper,
    t.dopl,
    c.nkom, c.nink, t.dat, 1, t.usl, t.org, t.dat
    from t_corrects_payments t, c_comps c, params p where c.nkom='999' and t.mg=p.period and t.lsk=p_lsk;

  end if;  
  commit;
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

procedure dist_sal_corr is
mg_ params.period%type;
period_ params.period%type;
mgchange_ params.period%type;
kr_summa_ number;
rec_ c_kwtp_mg%rowtype;
changes_id_ number;
user_id_ number;
comment_ c_change_docs.text%type;
cd_tp_ c_change_docs.cd_tp%type;
dat_ date;

begin
  --корректирующая проводка
  --ВЫПОЛНЯЕТСЯ ТОЛЬКО если установлен параметр закрывать сальдо - CLOSE_SAL!

  --корректировка сальдо проводками оплаты
  --(переносим с кредита на дебет)
  select p.period1, p.period,
   last_day(to_date(p.period||'01','YYYYMMDD')) into mg_, period_, dat_ from v_params p;

  --ID документа
  select changes_id.nextval into changes_id_ from dual;

  mgchange_:=period_;
  user_id_:=uid;
  comment_:='Закрытие сальдо за период '||period_;
  --удаление предыдущего закрытия сальдо за текущий период
  delete from t_corrects_payments t where exists
   (select * from c_change_docs d where d.cd_tp='PAY_SAL' and d.id=t.fk_doc
    and to_char(d.dtek,'YYYYMM')=period_);

  delete from c_change_docs d where d.cd_tp='PAY_SAL' and
   to_char(d.dtek,'YYYYMM')=period_;



  insert into c_change_docs (id, mgchange, dtek, ts, user_id, text, cd_tp)
  values (changes_id_, mgchange_, trunc(dat_), sysdate, user_id_, comment_, 'PAY_SAL');


  for c in (select distinct t.lsk --л.с. со "смешанным" исходящим сальдо
           from saldo_usl t
           where t.mg = mg_ and
             nvl(t.summa,0) < 0-- and t.lsk='01003333'
            and exists
           (select * from saldo_usl s where s.lsk=t.lsk and t.mg = mg_ and
             s.mg=t.mg and s.summa > 0)
          )
  loop
  for kr in (select s.org, s.usl, s.summa
                      from saldo_usl s --кредитовое исходящее сальдо
                     where s.summa < 0 and s.mg = mg_
                     and s.lsk=c.lsk)
  loop
  kr_summa_:=abs(kr.summa);
  while kr_summa_ <> 0
  loop
  for dt in (select t.org, t.usl, sum(t.summa) as summa
              from (select s.org, s.usl, s.summa
                      from saldo_usl s where s.mg = mg_
                     and s.lsk=c.lsk
                     union all
                    select s.org, s.usl, -1*s.summa
                      from t_corrects_payments s where s.mg = period_
                     and s.lsk=c.lsk and s.fk_doc=changes_id_
                      ) t
             group by t.org, t.usl
             having sum(t.summa) > 0)
  loop

    if kr_summa_ > dt.summa then
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
       values (
         c.lsk, kr.usl, kr.org, -1 * dt.summa, user_id_, dat_, period_, period_, changes_id_, 1);

      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
       values (
         c.lsk, dt.usl, dt.org, dt.summa, user_id_, dat_, period_, period_, changes_id_, 1);

--      commit;

      kr_summa_:=kr_summa_-dt.summa;
    elsif kr.summa <= dt.summa then
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
       values (
         c.lsk, kr.usl, kr.org, -1 * kr_summa_, user_id_, dat_, period_, period_, changes_id_, 1);

      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
       values (
         c.lsk, dt.usl, dt.org, kr_summa_, user_id_, dat_, period_, period_, changes_id_, 1);

--      commit;
      kr_summa_:=0;

    end if;
     if kr_summa_ = 0 then
      exit;
     end if;

  end loop;


  if kr_summa_ <>0 then
  --кредитовая сумма не смогла погаситься полностью, выход (результат- всё сальдо кредитовое)
   exit;
  end if;


  end loop;


  end loop;

  end loop;

  commit;
end;

end c_gen_pay;
/


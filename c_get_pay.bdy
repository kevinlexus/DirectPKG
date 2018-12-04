create or replace package body scott.C_GET_PAY is

function get_payment_bank_date
  return date
is
  dtek_ date;
begin
--возвращает дату пакета, принятого от банка
  select max(dtek) into dtek_ from load_bank t where t.nkom=init.get_nkom;
  return dtek_;
end;

function check_payment_bank_date
  return number
is
  cnt_ number;
begin
--проверяет, принимался ли уже пакет банка за данную дату
--возвращает кол-во записей
  select count(*) into cnt_ from c_kwtp c
    where exists (select * from load_bank t where t.nkom=c.nkom and c.dat_ink=init.get_date
      and t.nkom=init.get_nkom);
  return cnt_;
end;

function check_payment_bank_nink(nink_ in c_kwtp.nink%type)
  return number
is
  cnt_ number;
begin
--проверяет, принимался ли уже пакет банка c данным номером
--возвращает кол-во записей
  select count(*) into cnt_ from c_kwtp c
      where c.nkom=init.get_nkom and c.nink=nink_;
  return cnt_;
end;


function get_payment_bank_summa
  return number
is
  summa_ number;
begin
--возвращает сумму платежей пакета, принятого от банка
  select sum(summa) into summa_ from load_bank t where t.nkom=init.get_nkom
    and t.code='01';
  return summa_;
end;

function get_payment_bank_summp
  return number
is
  summap_ number;
begin
--возвращает сумму пени пакета, принятого от банка
  select sum(summa) into summap_ from load_bank t where t.nkom=init.get_nkom
    and t.code='02';
  return summap_;
end;

procedure cur_payment_bank (id_ in number, prep_refcursor in out rep_refcursor) is
begin
--выводит список не прошедших проверку платежей банка
if id_ =1 then
   open prep_refcursor for select t.* from c_comps t where
     t.nkom=init.get_nkom and t.fk_oper is null;
elsif id_ =2 then
   open prep_refcursor for select t.* from load_bank t where
     t.nkom=init.get_nkom and
     not exists (select * from kart k where k.lsk=t.lsk);

elsif id_=3 then
    open prep_refcursor for select t.* from load_bank t where
  t.nkom=init.get_nkom and t.code not in ('01','02') ;

/* --ред.05.03.12
elsif id_=4 then
   open prep_refcursor for select t.* from load_bank t, params p
    where t.nkom=init.get_nkom and to_char(t.dtek,'YYYYMM')<>p.period;
  */
elsif id_=5 then
   open prep_refcursor for select t.* from load_bank t where
  t.nkom=init.get_nkom and not exists --лёгкий бред
  (select * from c_chargepay c, params p where c.period=p.period
   and c.mg=t.dopl);
end if;

end;

function recv_payment_bank(nink_ in c_kwtp.nink%type)
 return number
is
  oper_ oper.oper%type;
  cnt_ number;
  distrib_pay_ number;
begin
--оплата из внешних источников (банк, почта)
  select fk_oper into oper_
    from c_comps c where c.nkom=init.get_nkom;
  if oper_ is null then
  --не найден экслюзивный код операции поставщика оплаты в справочнике c_comps
    return 1;
  end if;

--распределять ли оплату по периодам (обычно: 6-кисел, 4-полыс)
  select nvl(p.distrib_pay,0) into distrib_pay_
    from params p;

 select nvl(count(*),0) into cnt_ from load_bank t where
  t.nkom=init.get_nkom and
  not exists (select * from kart k where k.lsk=t.lsk);
 if cnt_ <> 0 then
   --Файл платежей содержит лицевые счета не соответствующие лицевым счетам базы!
     return 2;
 end if;

 select nvl(count(*),0) into cnt_ from load_bank t where
  t.nkom=init.get_nkom and t.code not in ('01','02') ;
 if cnt_ <> 0 then
    return 3;
  -- 'Файл платежей содержит недопустимый код операции!');
 end if;


 select nvl(count(*),0) into cnt_ from load_bank t where
  t.nkom=init.get_nkom and not exists --лёгкий бред
  (select * from c_chargepay c, params p where c.period=p.period
   and c.mg=t.dopl);
 if cnt_ <> 0 then
    return 5;
  -- 'Файл платежей содержит недопустимый период оплаты !');
 end if;

  --ред 05.03.12 снят контроль на дату платежа, - главное дата инкассации

if nvl(nink_,0) <> 0 then
  --чистим платежи, если принудительно указан номер инкассации
  delete from c_kwtp_mg c where c.nkom=init.get_nkom and c.nink=nink_;
  delete from c_kwtp c where c.nkom=init.get_nkom and c.nink=nink_;
  --сommit - иначе deadlock в c_valid! ред 02.12.12
  commit;
end if;

for c in (select * from load_bank t where t.nkom=init.get_nkom)
loop

  --не допустить принятие платежей за период больше чем текущая дата инкассации банковского реестра ред.02.09.14
  if c.dtek > init.get_date then
     -- 'Файл платежей содержит недопустимую дату оплаты!');
     return 4;
  end if;
  if c.code = '01' then
    if distrib_pay_ = 1 then
      --платёж не распределять по периодам
      get_payment(c.dtek, c.lsk, c.summa, null, oper_, c.dopl, distrib_pay_, null, 0, null, null);
    elsif distrib_pay_ = 4 then
      --платёж распределять по периодам, как единый платеж
      get_payment(c.dtek, c.lsk, c.summa, null, oper_, c.dopl, distrib_pay_, null, 0, null, null);
    elsif distrib_pay_ = 6 then
      --платёж распределять по периодам, как единый платеж сперва долги, потом пеню
      get_payment(c.dtek, c.lsk, c.summa, null, oper_, c.dopl, distrib_pay_, null, 0, null, null);
/*    else
      --платёж распределять по периодам
      get_payment(c.dtek, c.lsk, c.summa, null, oper_, null, distrib_pay_, null, 0, null, null);*/
    end if;
  elsif c.code = '02' then
    if distrib_pay_ = 1 then
      --пеню не распределять по периодам
      get_payment(c.dtek, c.lsk, null, c.summa, oper_, c.dopl, distrib_pay_, null, 0, null, null);
/*    elsif distrib_pay_ in (4, then
      --распределение пени, в едином платеже не производится
      null;
    else
      --пеню распределять по периодам
      get_payment(c.dtek, c.lsk, null, c.summa, oper_, null, 0, null, 0, null, null);*/
    end if;
  end if;
end loop;
--чистим файл с принятым пакетом
delete from load_bank t where t.nkom=init.get_nkom;
--выполнение инкассации, текущим компьютером, текущей датой
make_inkass;
commit;
--всё выполнено успешно
return 0;
end;

procedure get_payment(dtek_ in c_kwtp.dtek%type, lsk_ in c_kwtp.lsk%type, summa_ in c_kwtp.summa%type,
  penya_ in c_kwtp.penya%type, oper_ in c_kwtp.oper%type, dopl_ in c_kwtp.dopl%type, iscorrect_ number,
   nkvit1_ in c_kwtp.nkvit%type, iscommit_ in number,
   num_doc_ in c_kwtp.num_doc%type, dat_doc_ in c_kwtp.dat_doc%type) is
  nkvit_ number;
  id_ number;
  dtplat_ c_kwtp.dtek%type;
begin
--прием оплаты
if lsk_ is null then
  Raise_application_error(-20000, 'Получен пустой лицевой счет!');
end if;

if dtek_ is null then
  --если платеж с пустой датой - установить текущую
  --от банков могут приходить платежи с месяцем <> текущему
  dtplat_:=init.get_date();
  else
  dtplat_:=dtek_;
end if;

if nvl(iscorrect_,0) = 3 then --наличка
  nkvit_:=nkvit1_;
else
  select nkvit into nkvit_ from c_comps t
        where t.nkom=init.get_nkom();
end if;

if nvl(iscorrect_,0) in (0,1,2,3,4,6,7) then 
  select c_kwtp_id.nextval into id_ from dual;
end if;

if nvl(iscorrect_,0) = 1 then --корректировка оплаты
  insert into c_kwtp
    (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, id, iscorrect,
    num_doc, dat_doc)
  values
    (lpad(lsk_,8,'0'), summa_, penya_, oper_, dopl_,
     0, init.get_nkom(), dtplat_, nkvit_, sysdate,
     id_, iscorrect_, num_doc_, dat_doc_);
 elsif nvl(iscorrect_,0) = 2 then --распределение оплаты
  insert into c_kwtp
    (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, id, iscorrect,
    num_doc, dat_doc)
  values
    (lpad(lsk_,8,'0'), summa_, penya_, oper_, dopl_,
     0, init.get_nkom(), dtplat_, nkvit_, sysdate,
     id_, iscorrect_, num_doc_, dat_doc_);
 elsif nvl(iscorrect_,0) = 3 then --наличка
  insert into c_kwtp
    (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, id, iscorrect,
    num_doc, dat_doc)
  values
    (lpad(lsk_,8,'0'), summa_, penya_, oper_, dopl_,
     0, init.get_nkom(), dtplat_, nkvit_, sysdate,
     id_, iscorrect_, num_doc_, dat_doc_);
 elsif nvl(iscorrect_,0) in (5) then --комплексный платёж - не делается здесь строчка!
  null;
 elsif nvl(iscorrect_,0) in (4, 6, 7) then --единой суммой, единой суммой распр. наоборот
  --здесь пеня не выделяется (только в c_kwtp_mg)
  insert into c_kwtp
    (lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, ts, id, iscorrect,
    num_doc, dat_doc)
  values
    (lpad(lsk_,8,'0'), summa_, oper_, dopl_,
     0, init.get_nkom(), dtplat_, nkvit_, sysdate,
     id_, iscorrect_, num_doc_, dat_doc_);
else -- обычная оплата (0)
  insert into c_kwtp
    (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, id, iscorrect,
    num_doc, dat_doc)
  values
    (lpad(lsk_,8,'0'), summa_, penya_, oper_, (select period from params),
     0, init.get_nkom(), dtplat_, nkvit_, sysdate,
     id_, iscorrect_, num_doc_, dat_doc_);
 end if;
 --распределяем оплату по периодам
 get_payment_mg(id_, nkvit_, lsk_, summa_, penya_, oper_, dopl_, nvl(iscorrect_,0), init.get_nkom(), dtplat_, 0);

 update c_comps c set c.nkvit = nkvit_+1
        where c.nkom = init.get_nkom();
 if nvl(iscommit_,0)=1 then
   commit;
 end if;
end;

procedure get_payment_mg(id_ in c_kwtp.id%type, nkvit_ in c_kwtp.nkvit%type,
  lsk_ in c_kwtp.lsk%type, summa_ in c_kwtp.summa%type,
  penya_ in c_kwtp.penya%type, oper_ in c_kwtp.oper%type,
  dopl_ in c_kwtp.dopl%type, p_pay_tp in number, nkom_ in c_kwtp.nkom%type,
  dtek_ in c_kwtp.dtek%type, nink_ in c_kwtp.nink%type) is

t_lsk tab_lsk;
summa_pay_ number;
summa_pn_ number;

--задолжность по основному долгу
saldo_ number;
--задолжность по пене
saldo_pen_ number;
--переплата по основному долгу
saldo_cr_ number;
--переплата по пене
saldo_pen_cr_ number;

l_proc_summa number;
l_summa number;
l_penya number;
saldo_amnt_ number;

l_kwtp_id number;
l_tp number;
l_pay_tp number;
l_lsk_old kart.lsk%type;
--курсор распределения по c_penya (общий вариант)
  cursor c is
    select t.lsk, t.mg1 as mg,
      nvl(t.summa,0) as summa, nvl(t.penya,0) as penya
      from c_penya t
      where t.lsk = lpad(lsk_,8,'0')
     order by t.mg1;
  rec_ c%rowtype;

--курсор распределения по c_penya, по основному и дополнительному лиц счетам 
  cursor c2 is
    select t.lsk, t.mg1 as mg,
      nvl(t.summa,0) as summa, nvl(t.penya,0) as penya
      from c_penya t, temp_lsk s
      where t.lsk=s.lsk 
     order by t.mg1, t.lsk;
  rec_all_lsk c2%rowtype;

--курсор распределения по c_chargepay (особое распределение)
  cursor r is
    select *
      from (select c.lsk, c.mg, sum(decode(type, 1, -1 * summa, summa)) as summa
               from c_chargepay c, params p
              where c.period = p.period and
                c.lsk = lpad(lsk_,8,'0')
                and c.type in (0, 1)
                and c.mg <= dopl_
              group by c.lsk, c.mg --сначала старые периоды платим (начиная с самых новых к старым)
              order by c.mg desc, c.lsk);
  rec_r_ r%rowtype;

--курсор для распределения сперва долгов, потом пени (для 6 типа платежей)
  cursor c3(p_tp in number) is
    select t.lsk, t.mg1 as mg,
      case when p_tp=0 then nvl(t.summa,0)
        else 0 end as summa, 
      case when p_tp=1 then nvl(t.penya,0)
        else 0 end as penya
      from c_penya t, params p
      where t.lsk = lpad(lsk_,8,'0')
           and t.mg1 < p.period --кроме текущего
     order by t.mg1;

--курсор для распределения сперва тек. начисления, потом долгов, потом пени (для 7 типа платежей)
  cursor c4(p_tp in number) is
    select t.lsk, t.mg1 as mg,
      case when p_tp=0 then nvl(t.summa,0)
        else 0 end as summa, 
      case when p_tp=1 then nvl(t.penya,0)
        else 0 end as penya
      from c_penya t, params p
      where t.lsk = lpad(lsk_,8,'0')
           and t.mg1 < p.period --кроме текущего
     order by t.mg1 desc;

begin
 --тип оплаты
  l_pay_tp:=p_pay_tp;
 --ввод оплаты, пени
  summa_pay_:=nvl(summa_,0);
  summa_pn_:=nvl(penya_,0);
  --выйти, если нулевые суммы
  if summa_pay_ = 0 and summa_pn_ = 0 then
    return;
  end if;

if nvl(l_pay_tp,0) in (0, 2, 4, 6, 7) then
  --выполняется только в случае платежа, необходимого для распределения платежей по периодам
  --начисление без коммита - зачем нужно, если оно посчитано...ред 16.04.12
  --cnt_:=c_charges.gen_charges(lsk_, lsk_, null, 0, 0);
  --движение без коммита и пеня на текущую дату, чтобы правильно посчитать периоды задолжн
  --ред 16.04.12
  --c_cpenya.gen_charge_pay(lsk_, 0); --убрал, считается в gen_penya 28.12.2015
  
  
  -- ВНИМАНИЕ! ОЧЕНЬ ВАЖНО! ЗДЕСЬ МЕНЯЕТСЯ СПОСОБ РАСПРЕДЕЛЕНИЯ ПРИНУДИТЕЛЬНО! 
  --определить вид платёжа, если указан, то этим способом распределять!
  select nvl(h.fk_typespay, l_pay_tp) into l_pay_tp 
    from kart k join c_houses h on k.house_id=h.id and k.lsk=lpad(lsk_,8,'0');
    
  c_cpenya.gen_penya(lsk_ => lpad(lsk_,8,'0'),
                     dat_ => dtek_,
                     islastmonth_ => 0,
                     p_commit => 0);
                     
--  c_cpenya.gen_penya(lpad(lsk_,8,'0'), 0, 0);
elsif nvl(l_pay_tp,0) = 5 then
  --комплексный платёж (основной и дополнительный (капрем) долги 
  --рассчитать долг и пеню по каждому л.с.
  --t_lsk-коллекция, - работает медленно в выражении table(t_lsk), пришлось отказаться 
  delete from temp_lsk;
  t_lsk:=p_houses.get_other_lsk(lpad(lsk_,8,'0'));   
  if t_lsk.count > 0 then
    for i in t_lsk.first..t_lsk.last loop
      insert into temp_lsk (lsk) --t_lsk-коллекция, - работает медленно в выражении table(t_lsk), пришлось ввести temp_lsk (бред конечно)
       values(t_lsk(i).lsk);
      c_cpenya.gen_penya(lsk_ => t_lsk(i).lsk,
                         dat_ => dtek_,
                         islastmonth_ => 0,
                         p_commit => 0);
      --c_cpenya.gen_penya(t_lsk(i).lsk, 0, 0);
    end loop;
  end if;
  
end if;


saldo_:=0;
saldo_pen_:=0;
saldo_cr_:=0;
saldo_pen_cr_:=0;
saldo_amnt_:=0;

if nvl(l_pay_tp,0) = 0 then --обычный платёж  --распределение со старых периодов (нового л.с.) к новым
open c;
loop
  fetch c into rec_;
  exit when c%notfound or summa_pay_ = 0;
  if rec_.summa+saldo_ <= 0 then --если переплата, перенести на след. период.
    saldo_:=rec_.summa+saldo_;
  elsif summa_pay_ <= rec_.summa+saldo_ then
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, summa_pay_, summa_pn_, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=0;
   summa_pn_:=0; --пеня принимается первым периодом
  else
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, rec_.summa+saldo_, summa_pn_, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=summa_pay_-(rec_.summa+saldo_);
   saldo_:=0;
   summa_pn_:=0; --пеня принимается первым периодом
  end if;

end loop;
close c;

--если оплата не обработалась, ставим её на текущий период (Нового ЛИЦЕВОГО СЧЕТА!!!)
if summa_pay_ <>0 or summa_pn_ <>0 then
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      select k.lsk, summa_pay_, summa_pn_, oper_, p.period, nink_,
          nkom_, dtek_, nkvit_, sysdate, id_
        from kart k, params p where
                k.c_lsk_id = (select max(c_lsk_id) from kart t where
                 t.lsk=lpad(lsk_,8,'0')) and rownum = 1;
end if;

elsif nvl(l_pay_tp,0) = 4 then
--Единый платёж  --распределение со старых периодов (нового л.с.) к новым
--и распределение на оплату и пеню
--ред 29.08.13
open c;
loop
  fetch c into rec_;
  exit when c%notfound or summa_pay_ = 0;
  l_summa := 0;
  l_penya := 0;

  -- задолженность с учетом переплаты предыдущ. периода
  saldo_:=rec_.summa+saldo_cr_;
  saldo_pen_:=rec_.penya+saldo_pen_cr_;

  --если переплата, перенести на след. период.
  if saldo_ < 0 then
    saldo_cr_:=saldo_;
  else
    saldo_cr_:=0;
  end if;
  if saldo_pen_ < 0 then
    saldo_pen_cr_:=saldo_pen_;
  else
    saldo_pen_cr_:=0;
  end if;
  saldo_amnt_:=saldo_+saldo_pen_;
  
  if saldo_ > 0 or saldo_pen_ > 0 then
    -- есть задолженность, распределить
    if saldo_ > 0 and saldo_pen_ > 0 then
      -- есть основной долг и долг пени
      l_proc_summa:=saldo_/saldo_amnt_;
      if summa_pay_ <= saldo_amnt_ then
        -- сумма оплаты меньше совокупного долга
        l_summa:= round(l_proc_summa * summa_pay_ ,2);
        l_penya:= summa_pay_ - l_summa;
      else 
        -- сумма оплаты больше совокупного долга
        l_summa:= round(l_proc_summa * saldo_amnt_ ,2);
        l_penya:= saldo_amnt_ - l_summa;
      end if;
    elsif saldo_ > 0 and saldo_pen_ <= 0 then
      -- есть только основной долг и переплата пени
      if summa_pay_ <= saldo_ then
        -- сумма оплаты меньше долга
        l_summa:= summa_pay_;
        l_penya:= 0;
      else 
        -- сумма оплаты больше совокупного долга
        l_summa:= saldo_;
        l_penya:= 0;
      end if;
    elsif saldo_ <= 0 and saldo_pen_ > 0 then
      -- есть переплата по долгу и долг пени
      if summa_pay_ <= saldo_pen_ then
        -- сумма оплаты меньше долга
        l_summa:= 0;
        l_penya:= summa_pay_;
      else 
        -- сумма оплаты больше совокупного долга
        l_summa:= 0;
        l_penya:= saldo_pen_;
      end if;
    end if;
  end if;
  
  if l_summa !=0 or l_penya !=0 then
    -- остаток
    summa_pay_:=summa_pay_-(l_summa+l_penya);
    -- распределены средства, сохранить
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
  end if;
/*
  if rec_.summa+rec_.penya+saldo_ <= 0 then --если переплата, перенести на след. период.
    saldo_:=rec_.summa+rec_.penya+saldo_;
  elsif summa_pay_ <= rec_.summa+rec_.penya+saldo_ then
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    l_summa:= round(l_proc_summa * summa_pay_,2);
    l_penya:= summa_pay_ - l_summa;

    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=0;
  else
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    --здесь перенос с прошлых периодов распределяем пропорционально долгу и пени
    l_summa:= rec_.summa+round(saldo_*l_proc_summa,2);
    l_penya:= rec_.penya+(saldo_-round(saldo_*l_proc_summa,2));
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=summa_pay_-(l_summa+l_penya);
   saldo_:=0;
  end if;
*/
end loop;
close c;

--если оплата не обработалась, ставим её на текущий период, на основной долг
if summa_pay_ <>0 then
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      select k.lsk, summa_pay_, 0, oper_, p.period, nink_,
          nkom_, dtek_, nkvit_, sysdate, id_
        from kart k, params p where
                k.lsk=lpad(lsk_,8,'0') and rownum = 1;
end if;


elsif nvl(l_pay_tp,0) = 6 then
--Единый платёж  --распределение: сначала долги, потом пеню
--ред 21.01.2016
--распределение оплаты
open c3(0);
loop
  fetch c3 into rec_;
  exit when c3%notfound or summa_pay_ = 0;
  if rec_.summa+rec_.penya+saldo_ <= 0 then --если переплата, перенести на след. период.
    saldo_:=rec_.summa+rec_.penya+saldo_;
  elsif summa_pay_ <= rec_.summa+rec_.penya+saldo_ then
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    l_summa:= round(l_proc_summa * summa_pay_,2);
    l_penya:= summa_pay_ - l_summa;

    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=0;
  else
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    --здесь перенос с прошлых периодов распределяем пропорционально долгу и пени
    l_summa:= rec_.summa+round(saldo_*l_proc_summa,2);
    l_penya:= rec_.penya+(saldo_-round(saldo_*l_proc_summa,2));
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=summa_pay_-(l_summa+l_penya);
   saldo_:=0;
  end if;

end loop;
close c3;

--распределение пени
open c3(1);
loop
  fetch c3 into rec_;
  exit when c3%notfound or summa_pay_ = 0;
  if rec_.summa+rec_.penya+saldo_ <= 0 then --если переплата, перенести на след. период.
    saldo_:=rec_.summa+rec_.penya+saldo_;
  elsif summa_pay_ <= rec_.summa+rec_.penya+saldo_ then
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    l_summa:= round(l_proc_summa * summa_pay_,2);
    l_penya:= summa_pay_ - l_summa;

    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=0;
  else
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    --здесь перенос с прошлых периодов распределяем пропорционально долгу и пени
    l_summa:= rec_.summa+round(saldo_*l_proc_summa,2);
    l_penya:= rec_.penya+(saldo_-round(saldo_*l_proc_summa,2));
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=summa_pay_-(l_summa+l_penya);
   saldo_:=0;
  end if;

end loop;
close c3;

--если оплата не обработалась, ставим её на текущий период
if summa_pay_ <>0 then
    insert into c_kwtp_mg
      (lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      select k.lsk, summa_pay_, oper_, p.period, nink_,
          nkom_, dtek_, nkvit_, sysdate, id_
        from kart k, params p where
                k.lsk=lpad(lsk_,8,'0') and rownum = 1;

end if;

elsif nvl(l_pay_tp,0) = 7 then
--Единый платёж  --распределение: сначала текущее начисление, затем долги, потом пеню,- в обратном порядке
--ред 16.01.2017
open c4(0);
loop
  fetch c4 into rec_;
  exit when c4%notfound or summa_pay_ = 0;
  if rec_.summa+rec_.penya+saldo_ <= 0 then --если переплата, перенести на след. период.
    saldo_:=rec_.summa+rec_.penya+saldo_;
  elsif summa_pay_ <= rec_.summa+rec_.penya+saldo_ then
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    l_summa:= round(l_proc_summa * summa_pay_,2);
    l_penya:= summa_pay_ - l_summa;

    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=0;
  else
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    --здесь перенос с прошлых периодов распределяем пропорционально долгу и пени
    l_summa:= rec_.summa+round(saldo_*l_proc_summa,2);
    l_penya:= rec_.penya+(saldo_-round(saldo_*l_proc_summa,2));
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=summa_pay_-(l_summa+l_penya);
   saldo_:=0;
  end if;

end loop;
close c4;

--распределение пени
open c3(1);
loop
  fetch c3 into rec_;
  exit when c3%notfound or summa_pay_ = 0;
  if rec_.summa+rec_.penya+saldo_ <= 0 then --если переплата, перенести на след. период.
    saldo_:=rec_.summa+rec_.penya+saldo_;
  elsif summa_pay_ <= rec_.summa+rec_.penya+saldo_ then
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    l_summa:= round(l_proc_summa * summa_pay_,2);
    l_penya:= summa_pay_ - l_summa;

    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=0;
  else
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    --здесь перенос с прошлых периодов распределяем пропорционально долгу и пени
    l_summa:= rec_.summa+round(saldo_*l_proc_summa,2);
    l_penya:= rec_.penya+(saldo_-round(saldo_*l_proc_summa,2));
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=summa_pay_-(l_summa+l_penya);
   saldo_:=0;
  end if;

end loop;
close c3;

--если оплата не обработалась, ставим её на текущий период
if summa_pay_ <>0 then
    insert into c_kwtp_mg
      (lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      select k.lsk, summa_pay_, oper_, p.period, nink_,
          nkom_, dtek_, nkvit_, sysdate, id_
        from kart k, params p where
                k.lsk=lpad(lsk_,8,'0') and rownum = 1;

end if;

elsif nvl(l_pay_tp,0) = 5 then
--Комплексный платёж  --распределение со старых периодов к новым по основному и дополнительному лс
--и распределение на оплату и пеню
--ред 01.01.2016

/*  insert into c_kwtp
    (lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, ts, id, iscorrect,
    num_doc, dat_doc)
  values
    (lpad(lsk_,8,'0'), summa_, oper_, dopl_,
     0, init.get_nkom(), dtplat_, nkvit_, sysdate,
     id_, iscorrect_, num_doc_, dat_doc_); */

l_lsk_old:='xxx';
delete from temp_kwtp_mg;
open c2;
loop
  fetch c2 into rec_;
  exit when c2%notfound or summa_pay_ = 0;
  if l_lsk_old <> rec_.lsk then --если другой лиц.счет, то убрать переплату с прошлого
    saldo_:=0;    
  end if;
  if rec_.summa+rec_.penya+saldo_ <= 0 then --если переплата, перенести на след. период.
    saldo_:=rec_.summa+rec_.penya+saldo_;
  elsif summa_pay_ <= rec_.summa+rec_.penya+saldo_ then
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    l_summa:= round(l_proc_summa * summa_pay_,2);
    l_penya:= summa_pay_ - l_summa;

    insert into temp_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate/*,
          id_*/);
   summa_pay_:=0;
  else
    l_proc_summa:=rec_.summa/(rec_.summa+rec_.penya);
    --здесь перенос с прошлых периодов распределяем пропорционально долгу и пени
    l_summa:= rec_.summa+round(saldo_*l_proc_summa,2);
    l_penya:= rec_.penya+(saldo_-round(saldo_*l_proc_summa,2));
    insert into temp_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts)
      values
        (rec_.lsk, l_summa, l_penya, oper_, rec_.mg, nink_, nkom_, dtek_, nkvit_, sysdate);
   summa_pay_:=summa_pay_-(l_summa+l_penya);
   saldo_:=0;
  end if;

end loop;
close c2;

--если оплата не обработалась, ставим её на текущий период в пропорции от начисления
if summa_pay_ <>0 then
    for c in (select t.lsk, t.summa/ (sum(t.summa) over (partition by 0)) as proc
          from (select a.lsk, sum(a.summa) as summa from c_charge a, temp_lsk s
          where a.lsk=s.lsk and a.type=1
          group by a.lsk
          having nvl(sum(a.summa),0)<>0
          ) t
          ) loop

      insert into temp_kwtp_mg
        (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts)
        select k.lsk, round(summa_pay_ * c.proc,2), null, oper_, p.period, nink_,
            nkom_, dtek_, nkvit_, sysdate
          from kart k, params p where
                  k.lsk=c.lsk;

       summa_pay_:=summa_pay_-round(summa_pay_ * c.proc,2);
    end loop;
end if;

--если остаток остался, то кинуть на любой л.с.
if nvl(summa_pay_,0) <>0 then
   update temp_kwtp_mg t set t.summa=nvl(t.summa,0)+summa_pay_
     where rowid=
       (select max(rowid) from temp_kwtp_mg k where k.summa>=summa_pay_);
end if;


--а теперь добавляем заголовок платежа, и детали
for c in (select distinct t.lsk from temp_kwtp_mg t)
  loop
    select c_kwtp_id.nextval into l_kwtp_id from dual;
    insert into c_kwtp
        (id, lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, iscorrect)
      select l_kwtp_id, lsk, sum(summa) as summa, sum(penya) as penya, oper_, dopl_, 0, init.get_nkom(), dtek_, nkvit_, sysdate,
         l_pay_tp
         from temp_kwtp_mg t
         where t.lsk=c.lsk
         group by t.lsk;
         
    if sql%rowcount = 0 then
      Raise_application_error(-20000, 'Комплексный платёж не прошёл, проверьте наличие задолжности по лиц.счету!');
    end if;     
    
    insert into c_kwtp_mg
        (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
    select t.lsk, t.summa, t.penya, t.oper, t.dopl, t.nink, t.nkom, t.dtek, t.nkvit, t.ts, l_kwtp_id
          from temp_kwtp_mg t where t.lsk=c.lsk;

  end loop;
elsif nvl(l_pay_tp,0) = 2 then --распределение со старых периодов к новым
--смысл? так и не понял... переговорить с кис и удалить ветку (ред 16.04.12) - бывает иногда нужно!!!
open r;
loop
  fetch r into rec_r_;
  exit when r%notfound or summa_pay_ = 0;
  if rec_r_.summa+saldo_ <= 0 then --если переплата, перенести на след. период.
    saldo_:=rec_r_.summa+saldo_;
  elsif summa_pay_ <= rec_r_.summa+saldo_ then
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_r_.lsk, summa_pay_, summa_pn_, oper_, rec_r_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=0;
   summa_pn_:=0; --пеня принимается первым периодом
  else
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      values
        (rec_r_.lsk, rec_r_.summa+saldo_, summa_pn_, oper_, rec_r_.mg, nink_, nkom_, dtek_, nkvit_, sysdate,
          id_);
   summa_pay_:=summa_pay_-(rec_r_.summa+saldo_);
   saldo_:=0;
   summa_pn_:=0; --пеня принимается первым периодом
  end if;

end loop;
close r;

--если оплата не обработалась, ставим её на текущий период (Нового ЛИЦЕВОГО СЧЕТА!!!)
if summa_pay_ <>0 or summa_pn_ <>0 then
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
      select k.lsk, summa_pay_, summa_pn_, oper_, p.period, nink_,
          nkom_, dtek_, nkvit_, sysdate, id_
        from kart k, params p where
                k.c_lsk_id = (select max(c_lsk_id) from kart t where
                 t.lsk=lpad(lsk_,8,'0')) and rownum = 1;
end if;

else --корректировка оплаты
  insert into c_kwtp_mg
    (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, ts, c_kwtp_id)
    values
      (lpad(lsk_,8,'0'), summa_pay_, summa_pn_, oper_, dopl_, nink_, nkom_,
        dtek_, nkvit_, sysdate,
        id_);
        
        
        
end if;

end;

function get_tails
  return number is
 summa_ number;
begin
 -- остаток в кассе по текущему компьютеру
 select nvl(sum(nvl(summa,0)+nvl(penya,0)),0) into summa_
        from c_kwtp t
        where t.nkom=init.get_nkom() and nvl(nink,0) = 0
          /*and t.dtek between init.g_dt_cur_start and init.g_dt_cur_end*/; --надо чтобы была видна вся оплата
 return summa_;
end;

function dst_money_cur_month(summa_ number)
   return number
 is
maxmg_ c_kwtp_temp_dolg.mg%type;
begin
--распределение излишне оплаченной суммы (чтобы не давать сдачу)
begin
select trim(max(t.mg)) into maxmg_ from c_kwtp_temp_dolg t;
exception when others then
  Raise; -- не понял... в Рябинке вылетает
  Raise_application_error(-20000, maxmg_);
end;
if maxmg_ is not null then
  --распределяем на последний месяц оплаты
  update c_kwtp_temp_dolg t set t.summa=nvl(t.summa,0)+summa_, t.itog=nvl(t.itog,0)+summa_
    where t.mg=maxmg_;

  update c_kwtp_temp t set t.summa=nvl(t.summa,0)+summa_, t.itog=nvl(t.itog,0)+summa_
    where exists (select * from oper o where o.oper=t.oper and nvl(o.iscounter,0) =0);
  return 0;
else
  return 1;
end if;

end;

function get_money_nal(lsk_ in kart.lsk%type)
  return c_kwtp.id%type is
 nkvit_ number;
 cnt_ number;
 id_ c_kwtp.id%type;
 c_kwtp_summa_ number;
 c_kwtp_mg_summa_ number;
 summa_mg_ number;
begin
  --ввод оплаты, наличкой


  select nvl(count(*),0) into cnt_ from (
  select count(*) as cnt, t.oper from c_kwtp_temp t
  group by t.oper
  ) where cnt > 1;
  if cnt_ > 1 then
    Raise_application_error(-20001,
     'Внимание! Дублируется код операции, отмена!');
  end if;

  --номер квитанции
  select nkvit into nkvit_ from c_comps t
        where t.nkom=init.get_nkom();
  update c_comps c set c.nkvit = nkvit_+1
        where c.nkom = init.get_nkom();
  select c_kwtp_id.nextval into id_
    from dual;


  insert into c_kwtp
    (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, id, iscorrect)
  select lpad(lsk_,8,'0'), sum(t.summa), sum(t.penya), null, null, 0, init.get_nkom(), init.get_date(),
     nkvit_, null, sysdate, id_, 3
    from c_kwtp_temp t where nvl(t.summa,0) <> 0 or nvl(t.penya,0) <> 0;

  select nvl(sum(t.summa),0)+nvl(sum(t.penya),0) into c_kwtp_summa_
    from c_kwtp_temp t where nvl(t.summa,0) <> 0 or nvl(t.penya,0) <> 0;

  summa_mg_:=0;
  c_kwtp_mg_summa_:=0;
  for c in (select t.*, nvl(o.iscounter,0) as iscounter, trim(u.counter) as counter
     from c_kwtp_temp t , oper o, usl u where t.oper=o.oper and o.fk_usl_chk=u.usl(+))
  loop
    if c.iscounter = 0 then
      --например 01 - опер, квартплата
      insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, c_kwtp_id)
      select lpad(lsk_,8,'0'), t.summa, t.penya, c.oper, t.mg, 0, init.get_nkom(), init.get_date(),
       nkvit_, null, sysdate, id_
       from c_kwtp_temp_dolg t where (nvl(t.summa,0) <> 0 or nvl(t.penya,0) <> 0);

      if SQL%ROWCOUNT = 0 then
        rollback;
        logger.log_(null, 'C_GET_PAY.GET_MONEY_NAL, Ошибка при вводе оплаты! Повторить ввод!');
        Raise_application_error(-20000, 'Ошибка при вводе оплаты! Повторить ввод!'||c_kwtp_summa_||' '||c_kwtp_mg_summa_);
      end if;
      select nvl(sum(t.summa),0)+nvl(sum(t.penya),0) into summa_mg_
        from c_kwtp_temp_dolg t where nvl(t.summa,0) <> 0 or nvl(t.penya,0) <> 0;
    elsif c.iscounter <> 0  and c.counter is not null then
      --расход
      --последние показания по х.воде-г.воде (обраб в триггере)
      execute immediate 'update kart k set k.'||c.counter||'=:cnt_ where k.lsk=lpad(:lsk_,8,''0'')'
      using c.cnt_sch, lsk_;
      insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, cnt_sch, cnt_sch0, nink, nkom, dtek, nkvit, dat_ink, ts, c_kwtp_id)
      select lpad(lsk_,8,'0'), t.summa, t.penya, c.oper, p.period, t.cnt_sch, c.cnt_sch0, 0, init.get_nkom(), init.get_date(),
       nkvit_, null, sysdate, id_
       from c_kwtp_temp t, params p where t.oper=c.oper and (nvl(t.summa,0) <> 0 or nvl(t.penya,0) <> 0);
      if SQL%ROWCOUNT = 0 then
        rollback;
        logger.log_(null, 'C_GET_PAY.GET_MONEY_NAL, Ошибка при вводе оплаты! Повторить ввод!');
        Raise_application_error(-20000, 'Ошибка при вводе оплаты! Повторить ввод!'||c_kwtp_summa_||' '||c_kwtp_mg_summa_);
      end if;

      select nvl(sum(t.summa),0)+nvl(sum(t.penya),0) into summa_mg_
        from c_kwtp_temp t where t.oper=c.oper and (nvl(t.summa,0) <> 0 or nvl(t.penya,0) <> 0);
    elsif c.iscounter = 2 then
      --например каб.тел
      insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, cnt_sch, cnt_sch0, nink, nkom, dtek, nkvit, dat_ink, ts, c_kwtp_id)
      select lpad(lsk_,8,'0'), t.summa, t.penya, c.oper, p.period, t.cnt_sch, c.cnt_sch0, 0, init.get_nkom(), init.get_date(),
       nkvit_, null, sysdate, id_
       from c_kwtp_temp t, params p where t.oper=c.oper and (nvl(t.summa,0) <> 0 or nvl(t.penya,0) <> 0);
      if SQL%ROWCOUNT = 0 then
        rollback;
        logger.log_(null, 'C_GET_PAY.GET_MONEY_NAL, Ошибка при вводе оплаты! Повторить ввод!');
        Raise_application_error(-20000, 'Ошибка при вводе оплаты! Повторить ввод!'||c_kwtp_summa_||' '||c_kwtp_mg_summa_);
      end if;

      select nvl(sum(t.summa),0)+nvl(sum(t.penya),0) into summa_mg_
        from c_kwtp_temp t where t.oper=c.oper and (nvl(t.summa,0) <> 0 or nvl(t.penya,0) <> 0);
    else
      Raise_application_error(-20000, 'Не корректно настроен справочник операций!');
    end if;
    c_kwtp_mg_summa_:=c_kwtp_mg_summa_+summa_mg_;
  end loop;
  if nvl(c_kwtp_summa_,0) <> nvl(c_kwtp_mg_summa_,0) then
    rollback;
    logger.log_(null, 'C_GET_PAY.GET_MONEY_NAL, Ошибка при вводе оплаты! Повторить ввод!');
    Raise_application_error(-20000, 'Ошибка при вводе оплаты! Повторить ввод!'||c_kwtp_summa_||' '||c_kwtp_mg_summa_);
--  else
--    commit;
  end if;
  --начислить, чтобы объемы осели в начислении
  --cnt2_:=c_charges.gen_charges(lpad(lsk_,8,'0'), lpad(lsk_,8,'0'), null, 0, 0);

  return id_;
end;

procedure make_inkass is
  nink_ number;
begin
 --инкассация
 select nvl(nink,0) into nink_ from c_comps t
        where t.nkom=init.get_nkom();

 update kwtp_day t set t.nink = nink_, t.dat_ink = init.get_date()
        where exists (select * from c_kwtp_mg c
          where c.nkom = init.get_nkom() and nvl(c.nink,0) = 0
        and t.kwtp_id=c.id
        /*and c.dtek between init.g_dt_cur_start and init.g_dt_cur_end*/);

 update c_kwtp c set c.nink = nink_, c.dat_ink = init.get_date()
        where c.nkom = init.get_nkom() and nvl(c.nink,0) = 0
        /*and c.dtek between init.g_dt_cur_start and init.g_dt_cur_end*/;

 update c_kwtp_mg c set c.nink = nink_, c.dat_ink = init.get_date()
        where c.nkom = init.get_nkom() and nvl(c.nink,0) = 0
        /*and c.dtek between init.g_dt_cur_start and init.g_dt_cur_end*/;


 update c_comps c set c.nink = nink_+1
        where c.nkom = init.get_nkom();
--Без коммита (он - на стороне клиента)
-- commit;
end;

procedure init_c_kwtp_temp_dolg (lsk_ in kart.lsk%type) is
  lsk_new_ c_kwtp.lsk%type;
  a number;
begin
  lsk_new_:=lpad(lsk_,8,'0');
  -- начисление
  a:=c_charges.gen_charges(lsk_ => lsk_new_, lsk_end_ => lsk_new_, 
                             house_id_ => null, p_vvod => null, iscommit_ => 0, sendmsg_ => null);
  -- текущее движение по л.с.
  c_cpenya.gen_charge_pay(lsk_new_, 0);
  -- пеня обязательно!
  c_cpenya.gen_penya(lsk_new_, 0, 0);

  delete from c_kwtp_temp_dolg;
  insert into c_kwtp_temp_dolg
  (mg, charge, payment, summa, penya, sal, itog)
  select a.mg,
         nvl(b.summa,0) as charge,
         nvl(c.summa,0) as payment,
         d.summa as summa,
         nvl(d.penya,0) as penya,
         nvl(e.summa,0) as sal,
         d.summa + nvl(d.penya,0) as itog
    from scott.long_table a, params p,
         (select mg, sum(summa) as summa
            from scott.c_chargepay
           where period = (select period from scott.params)
             and lsk = lsk_new_
             and type = 0
           group by mg) b,
         (select mg, sum(summa) as summa
            from scott.c_chargepay
           where period = (select period from scott.params)
             and lsk = lsk_new_
             and type = 1
           group by mg) c,
           (select t.mg1, 
            case when t.penya >= 0 then t.penya else 0 end as penya,
            case when t.summa >= 0 then t.summa else 0 end as summa
            from c_penya t where lsk = lsk_new_) d,
            (select sum(summa) as summa from c_penya where lsk = lsk_new_) e--совокупный долг
   where a.mg = b.mg(+)
     and a.mg = c.mg(+)
     and a.mg = d.mg1(+)
     and ((nvl(b.summa,0) = 0 and p.period=a.mg) or
         nvl(b.summa,0) <> 0 or
         nvl(d.summa,0) <> 0 or
         nvl(c.summa,0) <> 0);

end;

procedure remove_pay(id_ in c_kwtp.id%type) is
begin
--удаление неправильных оплат из ввода списком
  delete from c_kwtp_mg t where t.c_kwtp_id=id_;
  delete from c_kwtp t where t.id=id_;
--  без коммита
--  commit;
end;

procedure remove_inkass(nkom_ in c_kwtp.nkom%type, nink_ in c_kwtp.nink%type) is
begin
--удаление неправильных инкассаций...
--кассовый аппарат - в пролёте?))
  delete from c_kwtp_mg t where t.nkom=nkom_ and nvl(t.nink,0)=nvl(nink_,0);
  delete from c_kwtp t where t.nkom=nkom_ and nvl(t.nink,0)=nvl(nink_,0);
  commit;
end;

function reverse_pay(p_kwtp_id in c_kwtp.id%type) return number is
l_id number;
l_id2 number;
l_dt date;
--текущий № комп.
l_nkom c_kwtp.nkom%type;
l_nkvit c_kwtp.nkvit%type;
begin
--обратный платёж (провести зеркально сумму, в тек.периоде,
--в точности как была, только с обратным знаком)
  l_dt:=init.get_date;
  l_nkom:=init.get_nkom;
  select scott.c_kwtp_id.nextval into l_id from dual;
  select nkvit into l_nkvit from c_comps t
    where t.nkom=l_nkom;
  update c_comps c set c.nkvit = l_nkvit+1
        where c.nkom = init.get_nkom();

  insert into c_kwtp
    (lsk, summa, penya, oper, dopl, nink,
     nkom, dtek, nkvit, id,
     iscorrect, num_doc, dat_doc)
  select t.lsk, -1*nvl(t.summa,0) as summa, -1*nvl(t.penya,0) as penya,
     t.oper, t.dopl, 0 as nink,
     l_nkom as nkom, l_dt as dtek, l_nkvit, l_id,
     t.iscorrect, t.num_doc, t.dat_doc
  from a_kwtp t
  where t.id=p_kwtp_id;
  if SQL%ROWCOUNT = 0 then
    --не успешно
    --rollback;
    return 1;
  end if;

for c in (select t.lsk, -1*nvl(summa,0) as summa, -1*nvl(penya,0) as penya,
    t.oper, t.dopl, null as nink,
    l_nkom as nkom, l_dt as dtek, l_nkvit as nkvit,
    t.cnt_sch, t.cnt_sch0, t.id
  from a_kwtp_mg t
  where t.c_kwtp_id=p_kwtp_id)
loop
  insert into c_kwtp_mg
    (lsk, summa, penya, oper, dopl,
    nkom, dtek, nkvit, c_kwtp_id,
    cnt_sch, cnt_sch0, is_dist, nink)
  values
    (c.lsk, c.summa, c.penya, c.oper, c.dopl,
    c.nkom, c.dtek, c.nkvit, l_id,
    c.cnt_sch, c.cnt_sch0, 1, --is_dist=1 - оплата уже распределена (чтоб повторно не распределялась в триггере)
    0
    )
   returning id into l_id2;
  if SQL%ROWCOUNT = 0 then
    --не успешно
    --rollback;
    return 2;
  end if;

  insert into kwtp_day
    (summa, lsk, oper, dopl, nkom, nink,
    dat_ink, priznak, usl, org, fk_distr, sum_distr, kwtp_id, dtek)
  select -1*nvl(t.summa,0) as summa,
    t.lsk, t.oper, t.dopl, l_nkom as nkom, 0 as nink,
    null as dat_ink, t.priznak, t.usl, t.org, 13 as fk_distr, --12 тип (обратный платёж)
    t.sum_distr,
    l_id2 as kwtp_id,
    init.get_date
    from a_kwtp_day t
    where t.kwtp_id=c.id;
  if SQL%ROWCOUNT = 0 then
    --не успешно
    --rollback;
    return 3;
  end if;
end loop;

--commit;
--успешно
return 0;

end;

/** Создать извещение об оплате в ГИС.
    Отрабатывается по триггеру на insert C_KWTP_MG
 **/
/*procedure create_notification_gis(rec c_kwtp_mg%rowtype) is 
begin
  -- оплата + пеня? (в гисе проводится всё в одном ПД и квитируется видимо пропорционально)
  insert into exs.notif(fk_pdoc, summa, dt, fk_kwtp_mg)
  select p.id, nvl(rec.summa,0)+nvl(rec.penya,0) as summa, 
         rec.dtek, rec.id from exs.pdoc p join exs.eolink e on
         p.fk_eolink=e.id and e.lsk=rec.lsk and to_char(p.dt,'YYYYMM')=rec.dopl -- по периоду
         and nvl(rec.summa,0)+nvl(rec.penya,0)<>0
         and p.status=1 and p.v=1;

end;  

\** Создать извещение об оплате в ГИС по всем необработанным платежам текущего периода
 **\
procedure create_notification_gis_all is 
begin
  for c in (select * from scott.c_kwtp_mg t 
      where not exists (select * from exs.notif n where n.fk_kwtp_mg=t.id)) loop
    create_notification_gis(c);
  end loop;    

end;  
*/
end C_GET_PAY;
/


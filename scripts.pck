create or replace package scott.scripts is
  procedure swap_payment;
  procedure swap_payment9;
  procedure swap_payment7;
  procedure swap_payment2;
  procedure swap_payment3;
  procedure gen_del_add_partitions;
  procedure new_usl(usl_ in varchar2);
  procedure script_renumber(oldreu_ in kart.reu%type,
                            reu_    in kart.reu%type);
  procedure create_uk(newreu_ in kart.reu%type,
                      nreu_   in varchar2,
                      mg1_    in params.period%type,
                      mg2_    in params.period%type);
  procedure close_uk(newreu_ in kart.reu%type, mg2_ in params.period%type);
  procedure clear_tables;
  procedure saldo_uk_div;
  procedure swap_payment4(reu_ in varchar2, newreu_ in varchar2);
  procedure swap_payment5;
  procedure swap_changes;
  procedure upd_nabor(oldorg_ in number, org_ in number, newreu_ in kart.reu%type);
  procedure go_back_month;
  procedure create_killme;
  procedure swap_oborot;
  procedure ins_vvod;
  procedure create_kart;
  procedure find_table;
  procedure swap_payment8;
  procedure set_sal_mg;
  procedure swap_oborot2;
  procedure swap_oborot3;
  procedure close_sal;
  procedure close_sal2;
  procedure close_sal3;
  procedure swap_sal1;
  procedure swap_sal_MAIN;
  procedure swap_sal_MAIN_BY_LSK;
  procedure create_uk_new_SPECIAL(newreu_ in kart.reu%type);
  procedure swap_sal2;
  procedure swap_sal3;
  procedure swap_sal4;
  --снятие сальдо "в никуда"
  procedure swap_sal_TO_NOTHING;
  procedure swap_sal_chpay;
  procedure swap_sal_chpay2;
  procedure swap_sal_chpay3;
procedure CREATE_UK_NEW2(p_reu_dst          in kart.reu%type, -- код УК назначения (вместо бывшего new_reu_), если не заполнен, то возьмется из лиц.счета источника
                         p_reu_src          in varchar2, -- код УК источника (если не заполнено, то любое) Заполняется если переносятся ЛС из РСО в другую РСО
                         p_lsk_tp_src       in varchar2, -- С какого типа счетов перенос, если не указано - будет взято по наличию p_remove_nabor_usl
                         p_house_src        in varchar2, -- House_id через запятую, например '3256,5656,7778,'
                         p_get_all          in number, -- признак какие брать лс (1 - все лс, в т.ч. закрытые, 0-только открытые)
                         p_close_src        in number, -- закрывать лс. источника (mg2='999999') 1-да,0-нет,2-закрывать только если не ОСНОВНОЙ счет
                         p_close_dst        in number, -- закрывать лс. назначения (mg2='999999') 1-да,0-нет
                         p_move_resident    in number, -- переносить проживающих? 1-да,0-нет
                         p_forced_status    in number, -- установить новый статус счета (0-открытый, NULL - такой же как был в счете источника)
                         p_forced_tp        in varchar2, -- установить новый тип счета (NULL-взять из источника, например 'LSK_TP_RSO' - РСО)
                         p_tp_sal           in number, --признак как переносить сальдо 0-не переносить, 2 - переносить и дебет и кредит, 1-только дебет, 3 - только кредит
                         p_special_tp       in varchar2, -- создать дополнительный лиц.счет в добавок к вновь созданному (NULL- не создавать, 'LSK_TP_ADDIT' - капремонт)
                         p_special_reu      in varchar2, -- УК дополнительного лиц.счета
                         p_mg_sal           in c_change.mgchange%type, -- период сальдо
                         p_remove_nabor_usl in varchar2 default null, -- переместить данные услуги (задавать как '033,034,035)
                         p_forced_usl       in varchar2 default null, -- установить данную услугу в назначении (если не указано, взять из источника)
                         p_forced_org       in number default null, -- установить организацию в наборе назначения (null - брать из источника)
                         p_mg_pen           in c_change.mgchange%type, -- период по которому перенести пеню. null - не переносить (обычно месяц назад)
                         p_move_meter       in number default 0,-- перемещать показания счетчиков (Обычно Полыс) 1-да,0-нет - при перемещении на РСО - не надо включать
                         p_cpn              in number default 0-- начислять пеню в новых лиц счетах? (0, null, -да, 1 - нет)
                         );
  --перенос информации по закрытым лиц.счетам
  procedure transfer_closed_all(p_reu in kart.reu%type,  -- рэу назначения
                              p_lsk_recommend in kart.lsk%type); -- рекоммендуемый лиц.счет, для начала или Null);
  --перенос информации по закрытому лиц.счету
  procedure transfer_closed_lsk(p_lsk in kart.lsk%type, --лиц счет
                       p_reu in kart.reu%type, --рэу назначения
                       p_cd in varchar2, --CD
                       p_lsk_recommend in kart.lsk%type -- рекоммендуемый лиц.счет, для начала или Null
                       );
  procedure swap_sal_chpay4;
  --перебросить сальдо с одной группы орг (кредитовое) на другую
  procedure swap_sal_chpay5;
end scripts;
/

create or replace package body scott.scripts is

procedure swap_payment
is
  mg_ params.period%type;
  usl_ usl.usl%type;
  usl_sv_ usl.usl%type;
  last_usl_ usl.usl%type;
  last_org_ sprorg.kod%type;
  summa_ number;
  id_ number;
  dat_ date;

begin
--переброска кредитового сальдо по капремонту
--ПРЕДВАРИТЕЛЬНО ВЫПОЛНИТЬ ПОДГОТОВКУ АРХИВОВ! (для a_nabor)
select period into mg_ from params;
dat_:=to_date('20110730','YYYYMMDD');
id_:=1;
delete from t_corrects_payments t where t.mg=mg_ and t.id=id_;

usl_:='033';
usl_sv_:='034';
--вариант - снимать по оплате
--проставить в WORK_HOUSES.NEWREU=1  по домам для переноса!!!!
/*for c in (select k.c_lsk_id, t.*, a.org from arch_kwtp t, a_nabor a, kart k
    where k.lsk=t.lsk and t.lsk=a.lsk and k.reu in ('11', '12')
    and (t.mg between '200806' and '200809')
    and exists (select * from work_houses w where
      w.reu=k.reu and w.kul=k.kul and w.nd=k.nd)
    and t.mg=a.mg
    and t.usl_id=a.usl
    and usl_id in (usl_, usl_sv_))*/
--вариант - снимать по сальдо
for c in (select t.* from saldo_usl t,
(select t.lsk,sum(summa) as summa from saldo_usl t, params p where t.mg=p.period
  and t.usl not in (usl_, usl_sv_)
  group by t.lsk) a,
  params p where t.mg=p.period and t.summa<0
  and t.usl in (usl_, usl_sv_)
  and t.lsk=a.lsk(+)
  and exists
  (select * from kart k, work_houses h where h.id=k.house_id
  and k.lsk=t.lsk and h.newreu is not null)
  and (nvl(a.summa,0)=0 or abs(t.summa)/abs(nvl(a.summa,0)) > 0.044)

  ) --высчитанный %
loop
  --снимаем оплату
  summa_:=0;
  last_usl_:=null;
  last_org_:=null;
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
    values
    (c.lsk, c.usl, c.org, c.summa, uid, dat_, mg_, c.mg, id_);

  for s in (select s.usl, s.org,
    round(c.summa*nvl(s.summa,0)/nvl(d.summa,0),2) *-1 as summa
            from saldo_usl s,
             (select sum(summa) as summa from saldo_usl s1
              where s1.lsk=c.lsk and s1.summa>0 and s1.mg=mg_
              and s1.usl not in (usl_, usl_sv_)) d where s.mg=mg_
            and s.usl not in (usl_, usl_sv_) and s.lsk=c.lsk
            and round(c.summa*nvl(s.summa,0)/nvl(d.summa,0),2)<>0
            and s.summa > 0)
  loop
  --распределяем оплату по сальдо
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
    values
    (c.lsk, s.usl, s.org, s.summa, uid, dat_, mg_, mg_, id_);

  last_usl_:=s.usl;
  last_org_:=s.org;
  summa_:=summa_+s.summa;
  end loop;

  if c.summa*-1-nvl(summa_,0) <> 0 then
  --остаток на последнюю услугу, на последн орг.
  select org into last_org_ from a_nabor2 n where
   c.mg between n.mgFrom and n.mgTo and n.usl=usl_ and n.lsk=c.lsk;
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
    values --ниже ошибка была? стояло вместо last_usl_ - usl_ ред.22.12.2011
    (c.lsk, last_usl_, last_org_, c.summa*-1-nvl(summa_,0), uid, dat_, mg_, c.mg, id_);
  end if;
end loop;
commit;
end;

procedure swap_payment9
is
  mg_ params.period%type;
  last_usl_ usl.usl%type;
  last_org_ sprorg.kod%type;
  summa_ number;
  id_ number;
  dat_ date;
  tst_ number;

begin
--переброска кредитового сальдо по выбранным организациям
--ПРЕДВАРИТЕЛЬНО ВЫПОЛНИТЬ ПОДГОТОВКУ АРХИВОВ! (для a_nabor)
select period into mg_ from params;
dat_:=to_date('20111222','YYYYMMDD');
id_:=2;
delete from t_corrects_payments t where t.mg=mg_ and t.id=id_;
--вариант - снимать по сальдо
for c in (select t.* from saldo_usl t,
(select t.lsk,sum(summa) as summa from saldo_usl t, params p
where t.mg=p.period
  and t.org not in (2, 23, 27, 41)
  group by t.lsk) a,
  params p where t.mg=p.period and t.summa<0
  and t.org in (2, 23, 27, 41)
  and t.lsk=a.lsk(+)
  and exists
  (select * from kart k where
  k.lsk=t.lsk and k.reu in ('14','15')
/*  and exists
  (select sum(x.summa), x.lsk from saldo_usl x, params p
   where x.mg=p.period and x.lsk=k.lsk
   group by x.lsk
   having abs(sum(x.summa) )>0.05
   )*/
  )
  and nvl(a.summa,0) > 0
  )
loop
  if c.lsk='14040068' then
    null;
  end if;
  --снимаем оплату
  summa_:=0;
  last_usl_:=null;
  last_org_:=null;
  tst_:=0;

  for s in (select s.usl, s.org,
    round(c.summa*nvl(s.summa,0)/nvl(d.summa,0),2) *-1 as summa
            from saldo_usl s,
             (select sum(summa) as summa from saldo_usl s1
              where s1.lsk=c.lsk and s1.summa>0 and s1.mg=mg_
              and s1.org not in (2, 23, 27, 41)) d where s.mg=mg_
            and s.org not in (2, 23, 27, 41) and s.lsk=c.lsk
            and round(c.summa*nvl(s.summa,0)/nvl(d.summa,0),2)<>0
            and s.summa > 0)
  loop
    tst_:=1;
    --распределяем оплату по сальдо
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
      values
      (c.lsk, s.usl, s.org, s.summa, uid, dat_, mg_, mg_, id_);

    last_usl_:=s.usl;
    last_org_:=s.org;
    summa_:=summa_+s.summa;
  end loop;

  if tst_ = 1 then
    insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
    values
    (c.lsk, c.usl, c.org, c.summa, uid, dat_, mg_, c.mg, id_);
  end if;

  if tst_ = 1 and c.summa*-1-nvl(summa_,0) <> 0 then
  --остаток на последнюю услугу, на последн орг.
    begin
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
        values
        (c.lsk, last_usl_, last_org_, c.summa*-1-nvl(summa_,0), uid, dat_, mg_, c.mg, id_);
    exception
      when others then
      Raise_application_error(-20000, c.lsk);
    end;
  end if;
end loop;
commit;
end;
procedure swap_payment7
is
  mg_ params.period%type;
  mg1_ params.period%type;
  last_usl_ usl.usl%type;
  last_org_ sprorg.kod%type;
  summa_ number;
  id_ number;
  id2_ number;
  id3_ number;
  --тип сальдо для переброски
  sign_ number;

begin
--переброска мелкого кредитового или дебетового сальдо
--ред. от 27.04.2011
--ПРЕДВАРИТЕЛЬНО ВЫПОЛНИТЬ ИТОГОВОЕ! (Сальдо, ПОДГОТОВКУ АРХИВОВ! (для a_nabor))
--select period into mg_ from params;
--берем исх сальдо, вместо входящего

--!!!!!!тип сальдо для переброски!!!! -1 - кредитовое, 1 - дебетовое
sign_:=1;
select period, period1 into mg_, mg1_ from v_params;

id_:=2;
id2_:=3;
id3_:=4;
delete from t_corrects_payments t where t.mg=mg1_ and t.id in (id_, id2_, id3_);

--МНЕ НЕ НРАВИТСЯ КАК ЗДЕСЬ СДЕЛАНО, МОЖЕТ ПРОИЗОЙТИ (И ПРОИСХОДИТ)
--ПЕРЕКРЕДИТОВАНИЕ ПО УСЛУГЕ. ИСПРАВИТЬ РЕД. 29.06.2011
--выборка мелкого кредитового (дебетового) сальдо
for c in (select x.lsk, x.summa, x.usl, x.org, x.mg from scott.saldo_usl x where
   x.mg=mg_ and ((sign_ = -1 and x.summa < 0) or (sign_ = 1 and x.summa > 0))
and exists
(select * from (select t.lsk, t.mg
 from scott.saldo_usl t
 where t.mg = mg_ and exists
 (select * from scott.saldo_usl s where s.lsk=t.lsk and
   s.mg=t.mg and ((sign_ = -1 and s.summa < 0) or (sign_ = 1 and s.summa > 0)) )
  group by t.lsk, t.mg
 having sum(decode(sign(summa), (-1*sign_), summa, 0))<>0
 and abs(sum(decode(sign(summa), sign_, summa, 0))/
 sum(decode(sign(summa), (-1*sign_), summa, 0))) between 0.001 and 0.99
 ) a where a.lsk=x.lsk)
order by x.lsk, x.org, x.usl) --высчитанный %
loop
  --снимаем оплату
  summa_:=0;
  last_usl_:=null;
  last_org_:=null;

  for s in (select s.usl, s.org,
    round( c.summa *nvl(s.summa,0)/nvl(d.summa,0),2) as summa
            from (select lsk, usl, org, sum(summa) as summa from (
                  select lsk, usl, org, summa from saldo_usl
                  where mg=mg_
                   union all
                  select lsk, usl, org, summa from t_corrects_payments
                  where mg=mg1_)
                  group by lsk, usl, org)  s,
             (select sum(summa) as summa from saldo_usl s1
              where s1.lsk=c.lsk
               and ((sign_ = -1 and s1.summa > 0) or (sign_ = 1 and s1.summa < 0))
               and s1.mg=mg_
              and s1.usl <> c.usl and s1.org <> c.org) d where
              s.usl <> c.usl and s.org <> c.org and s.lsk=c.lsk
            and round(c.summa*nvl(s.summa,0)/nvl(d.summa,0),2)<>0
            and ((sign_ = -1 and s.summa > 0) or (sign_ = 1 and s.summa < 0)))
  loop
  --распределяем оплату по вх сальдо
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
      values
      (c.lsk, s.usl, s.org, -1 * s.summa, uid, trunc(sysdate), mg1_, mg_, id2_);

    last_usl_:=s.usl;
    last_org_:=s.org;
    summa_:=summa_+s.summa*-1;
  end loop;

  if last_usl_ is not null and last_org_ is not null then
  --снимаем оплату
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
      values
      (c.lsk, c.usl, c.org, c.summa, uid, trunc(sysdate), mg1_, c.mg, id_);
  end if;

  if last_usl_ is not null and last_org_ is not null and
      (nvl(summa_,0)+c.summa) <> 0 then
      --остаток на последнюю услугу, на последн орг.
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
        values
        (c.lsk, last_usl_, last_org_, -1*(nvl(summa_,0)+c.summa), uid, trunc(sysdate), mg1_, c.mg, id3_);
   end if;
end loop;
commit;
end;


procedure swap_payment2
is
begin
--перенос оплаты по тульской-23
for c in (select a.lsk, a.summa, a.penya, a.oper, '200911' as dopl,
  trunc(sysdate) as dtek, a.nkvit, trunc(sysdate) as dat_ink,
  sysdate as ts, 0 as nink, '999' as nkom
   from a_kwtp_mg a
  where a.mg in ('200909', '200910', '200911', '200912')
  and exists (select * from kart k where k.reu='40'
   and k.kul='0020' and k.nd='000023'
   and k.lsk=a.lsk))
loop

insert into c_kwtp
  (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, id, iscorrect)
  values
  (c.lsk, -1*c.summa, -1*c.penya, c.oper, c.dopl, c.nink, c.nkom, c.dtek, c.nkvit,
     c.dat_ink, c.ts, c_kwtp_id.nextval, 3);

insert into c_kwtp_mg
  (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit,
     dat_ink, ts, c_kwtp_id)
  values
  (c.lsk, -1*c.summa, -1*c.penya, c.oper, c.dopl, c.nink, c.nkom, c.dtek, c.nkvit,
     c.dat_ink, c.ts, c_kwtp_id.currval);
end loop;

for c in (select m.lsk, a.summa, a.penya, a.oper, '200911' as dopl,
  trunc(sysdate) as dtek, a.nkvit, trunc(sysdate) as dat_ink,
  sysdate as ts, 0 as nink, '999' as nkom
   from a_kwtp_mg a, kart t, kart m
  where a.lsk=t.lsk and t.k_lsk_id=m.k_lsk_id
   and m.psch <> 8 and a.mg in ('200909', '200910', '200911', '200912')
  and exists (select * from kart k where k.reu='40'
   and k.kul='0020' and k.nd='000023'
   and k.lsk=a.lsk))
loop

insert into c_kwtp
  (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, id, iscorrect)
  values
  (c.lsk, c.summa, c.penya, c.oper, c.dopl, c.nink, c.nkom, c.dtek, c.nkvit,
     c.dat_ink, c.ts, c_kwtp_id.nextval, 3);

insert into c_kwtp_mg
  (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit,
     dat_ink, ts, c_kwtp_id)
  values
  (c.lsk, c.summa, c.penya, c.oper, c.dopl, c.nink, c.nkom, c.dtek, c.nkvit,
     c.dat_ink, c.ts, c_kwtp_id.currval);
end loop;
commit;

end;

procedure swap_payment3
is
  mg_ params.period%type;
  dopl_ params.period%type;
  newreu_ kart.reu%type;
  summa_ number;
  dat_ date;
  old_lsk_ kart.lsk%type;
  last_lsk_ kart.lsk%type;
  last_usl_ usl.usl%type;
  last_org_ sprorg.kod%type;
  last_old_org_ sprorg.kod%type;
begin
--перенос кредитового сальда оплатой
--ред. от 27.04.2010

select period into mg_ from params;
dat_:=to_date('02012010','DDMMYYYY');
delete from t_corrects_payments t where t.mg=mg_ and t.dat=dat_;
mg_:='201001';
dopl_:='201001';

last_lsk_:=null;
for c in (select s.lsk, m.lsk as lsk_new, s.usl, s.org, n.org as org_new, s.summa
     from saldo_usl s ,
     (select lsk, sum(summa) as summa from saldo_usl
      where mg='201002' group by lsk) a,
     (select lsk, sum(summa) as summa from saldo_usl
      where mg='201002' and summa < 0 group by lsk) c,
      kart k,
      nabor n,
      (select lsk,k_lsk_id from kart where psch <> 8) m
    where k.lsk=s.lsk and m.k_lsk_id=k.k_lsk_id and s.lsk=n.lsk(+) and s.usl=n.usl(+)
    and s.mg='201002' and s.summa<0 and s.lsk=a.lsk and s.lsk=c.lsk(+)
    and exists (select * from kart k where k.lsk=s.lsk and k.psch=8)
    and exists
    (select t.lsk,sum(summa) from saldo_usl t where t.mg='201002' and t.lsk=s.lsk
     group by t.lsk
     having sum(summa) < 0)
    order by s.lsk)
loop
  --снимаем оплату
  if nvl(last_lsk_,'') <> c.lsk and nvl(summa_,0) <> 0  then
   --остаток от пред л.с. закинуть
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl)
      values
      (last_lsk_, last_usl_, last_old_org_, summa_, uid, dat_, mg_, dopl_);

    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl)
      values
      (last_lsk_, last_usl_, last_org_, summa_*-1, uid, dat_, mg_, dopl_);
  else
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl)
      values
      (c.lsk, c.usl, c.org, c.summa, uid, dat_, mg_, dopl_);
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl)
      values
      (c.lsk_new, c.usl, c.org_new, c.summa*-1, uid, dat_, mg_, dopl_);
    last_lsk_:=c.lsk_new;
    last_usl_:=c.usl;
    last_org_:=c.org_new;
    last_old_org_:=c.org;

  end if;
end loop;
commit;
end;


procedure gen_del_add_partitions
is
  mg_ number;
begin
--скрипт удаление не нужных партиций (для уменьшения dumpa)
--ВО ВСЕХ ТАБЛИЦАХ схемы scott
return;
--убери return;

for c in (select table_name
  from all_tables t where t.partitioned ='YES' and t.owner='SCOTT')
loop
mg_:=200701;
loop
  exit when mg_>200807;
  gen.drop_part(c.table_name, to_char(mg_));
  mg_:=mg_+1;
end loop;
end loop;


end gen_del_add_partitions;

procedure new_usl(usl_ in varchar2)
is
  usl_from_ char(3);
begin
--ввод новой услуги
usl_from_:='003';

delete from prices c where c.usl=usl_;
insert into prices
  (usl, summa, summa2)
  select usl_, summa, summa2 from prices c where c.usl=usl_from_;

delete from nabor c where c.usl=usl_;

insert into nabor
  (lsk, usl, org, koeff, norm)
  select lsk, usl_, org, 0, 0 from nabor n where n.usl=usl_from_;

delete from c_spk_usl c where c.usl_id=usl_;

insert into c_spk_usl
  (spk_id, usl_id, koef, dop_pl, prioritet, charge_part)
  select spk_id, usl_, koef, dop_pl, prioritet, charge_part from
    c_spk_usl s where s.usl_id=usl_from_;

commit;
end;

procedure script_renumber(oldreu_ in kart.reu%type, reu_ in kart.reu%type) is

  lsk1_ kart.lsk%type;
begin
  --скрипт для присоединения УК к существующим УК
  --к которому присоединится
--  oldreu_:='34';
  --из которого присоединится
--  reu_:='15';

Raise_application_error(-20000, 'Не работает по причине REU в C_HOUSES');
update kart t set t.polis = null;
update kart t set t.polis =
  lpad((select max(lsk)
   from kart k where k.reu = oldreu_)+rownum,8,'0')
    where t.reu = reu_;
update kart t set t.lsk=t.polis, t.polis=t.lsk
 where t.reu = reu_;
 update c_kart_pr t set t.lsk= (select k.lsk from kart k where k.polis=t.lsk
   and k.reu = reu_)
   where exists (select * from kart k where k.polis=t.lsk
   and k.reu = reu_);
 update saldo_usl t set t.lsk= (select k.lsk from kart k where k.polis=t.lsk
   and k.reu = reu_)
   where exists (select * from kart k where k.polis=t.lsk
   and k.reu = reu_);
 update nabor t set t.lsk= (select k.lsk from kart k where k.polis=t.lsk
   and k.reu = reu_)
   where exists (select * from kart k where k.polis=t.lsk
   and k.reu = reu_);

 update c_charge t set t.lsk= (select k.lsk from kart k where k.polis=t.lsk
   and k.reu = reu_)
    where exists (select * from kart k where k.polis=t.lsk
   and k.reu = reu_);

 update c_chargepay t set t.lsk= (select k.lsk from kart k where k.polis=t.lsk
   and k.reu = reu_)
    where exists (select * from kart k where k.polis=t.lsk
   and k.reu = reu_);

--update c_houses t set t.reu =oldreu_
-- where t.reu = reu_;
update kart t set t.reu =oldreu_
 where t.reu = reu_;


 commit;
end script_renumber;


procedure create_uk(newreu_ in kart.reu%type, nreu_ in varchar2,
  mg1_ in params.period%type, mg2_ in params.period%type) is
--создание нового УК по таблице work_houses
--Выполнять во 2 ю очередь

--ВНИМАНИЕ! ЗАКРЫТИЕ ЛИЦЕВЫХ СЧЕТОВ ДЕЛАТЬ ОТДЕЛЬНО, ПОСЛЕ ГАРАНТИРОВАННОГО
--ПЕРЕНОСА ЛИЦЕВЫХ В УК!!!
begin

Raise_application_error(-20000, 'Проверить выполнение скрипта!');
--mg1_:='200901'; --новый период работы лицевого
--mg2_:='999999';  --заключительный период работы лицевого
--newreu_:='29';
--nreu_:='0029';
delete from nabor t where
  exists (select * from kart k where k.lsk=t.lsk and k.reu = newreu_);
delete from kart where reu=newreu_;

--delete from c_houses c where c.reu=newreu_;
/*insert into c_houses
  (id, reu, kul, nd, uch, maxlsk, kw, minlsk, house_type, opl)
  select c_house_id.nextval, newreu_, kul, nd, uch, maxlsk, kw, minlsk, house_type, opl
   from c_houses h where exists
   (select * from work_houses c where c.id=h.id and c.newreu = newreu_);
*/

/*--вводы  --УБРАЛ ДОБАВЛЕНИЕ ВВОДОВ... СТАВИТЬ В РУЧНУЮ...
update c_vvod k set k.flag=rownum;
--по х.воде
update kart k set k.flag=(select c.flag from c_vvod c where c.type=0 and c.id=k.c_vvod_hw_id);
--по г.воде
update kart k set k.flag1=(select c.flag from c_vvod c where c.type=1 and c.id=k.c_vvod_gw_id);

delete from c_vvod t where
  exists (select * from c_houses c where c.id=t.house_id and c.reu = newreu_);

--по х.воде
insert into c_vvod
  (flag, house_id, id, kub, type, kub_man, kpr, kub_sch, sch_cnt, sch_kpr, cnt_lsk, user_id, usl_032)
  select t.flag, v.id, c_vvod_id.nextval, t.kub, t.type, t.kub_man, t.kpr, t.kub_sch, t.sch_cnt, t.sch_kpr,
    t.cnt_lsk, t.user_id, t.usl_032
   from c_vvod t, c_houses h, c_houses v where
   t.house_id = h.id and h.kul=v.kul and h.nd=v.nd and v.reu=newreu_ and
   t.type=0 and
  exists
   (select * from work_houses c where c.id=t.house_id and c.newreu = newreu_);

--по г.воде
insert into c_vvod
  (flag, house_id, id, kub, type, kub_man, kpr, kub_sch, sch_cnt, sch_kpr, cnt_lsk, user_id, usl_032)
  select t.flag, v.id, c_vvod_id.nextval, t.kub, t.type, t.kub_man, t.kpr, t.kub_sch, t.sch_cnt, t.sch_kpr,
    t.cnt_lsk, t.user_id, t.usl_032
   from c_vvod t, c_houses h, c_houses v where
   t.house_id = h.id and h.kul=v.kul and h.nd=v.nd and v.reu=newreu_ and
   t.type=1 and
  exists
   (select * from work_houses c where c.id=t.house_id and c.newreu = newreu_);

--по 032 услуге
insert into c_vvod
  (house_id, id, kub, type, kub_man, kpr, kub_sch, sch_cnt, sch_kpr, cnt_lsk, user_id, usl_032)
  select v.id, c_vvod_id.nextval, t.kub, t.type, t.kub_man, t.kpr, t.kub_sch, t.sch_cnt, t.sch_kpr,
    t.cnt_lsk, t.user_id, t.usl_032
   from c_vvod t, c_houses h, c_houses v where
   t.house_id = h.id and h.kul=v.kul and h.nd=v.nd and v.reu=newreu_ and
   t.type=2 and
  exists
   (select * from work_houses c where c.id=t.house_id and c.newreu = newreu_);
*/
--лицевые
insert into kart
  (k_lsk_id, c_lsk_id, lsk, flag, flag1, kul, nd, kw, fio, kpr, kpr_wr, kpr_ot, kpr_cem, kpr_s, opl,
  ppl, pldop, ki, psch, psch_dt,  status, kwt,
  lodpl, bekpl, balpl, komn, et,
  kfg, kfot, phw, mhw, pgw, mgw, pel, mel,
  sub_nach, subsidii, sub_data, polis, sch_el,
  reu, text,
  schel_dt, eksub1, eksub2, kran, kran1, el,
   el1, sgku, doppl, subs_cor, subs_cur, house_id, kan_sch, mg1, mg2, sel1)
select t.k_lsk_id, t.c_lsk_id, nreu_||lpad(rownum,4,'0') as lsk,
 t.flag, t.flag1, t.kul, t.nd, t.kw, fio, kpr, kpr_wr, kpr_ot,
 kpr_cem, kpr_s, t.opl, ppl, pldop, ki,
 t.psch, psch_dt, status, kwt,
 lodpl, bekpl, balpl, komn, et, kfg, kfot, phw, mhw,
 pgw, mgw, pel, mel, sub_nach, subsidii, sub_data,
 polis, sch_el, newreu_, text,
 schel_dt, eksub1, eksub2, kran, t.kran1, el, el1,
 sgku, doppl, subs_cor, subs_cur,
 c.id as house_id, kan_sch, mg1_, mg2_, t.sel1 from kart t, work_houses c where
  c.newreu = newreu_ and t.kul=c.kul and t.nd=c.nd
 order by t.kul, t.nd, t.kw;

--опять вводы))
--по х.воде
--update kart t set t.c_vvod_hw_id=(select id from c_vvod c where c.flag=t.flag and c.house_id=
--  t.house_id)
--  where exists (select * from c_houses c where c.id=t.house_id and c.reu = newreu_);

--по г.воде
--update kart t set t.c_vvod_gw_id=(select id from c_vvod c where c.flag=t.flag1 and c.house_id=
--  t.house_id)
--  where exists (select * from c_houses c where c.id=t.house_id and c.reu = newreu_);

--по 032 услуге
--ID на ввод проставлять не нужно (в данной версии)

--выполняется каскадно
--delete from c_kart_pr t

insert into c_kart_pr
  (id, old_id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n, dok_d, dok_v, dat_prop, dat_ub, relat_id)
 select kart_pr_id.nextval, p.id, t.lsk, p.fio, p.status, p.dat_rog, p.pol, p.dok,
   p.dok_c, p.dok_n, p.dok_d, p.dok_v, p.dat_prop, p.dat_ub, p.relat_id
 from c_kart_pr p, kart k, kart t where p.lsk=k.lsk and k.c_lsk_id=t.c_lsk_id and k.lsk <> t.lsk and
  exists (select * from work_houses c where c.id=k.house_id and c.newreu = newreu_);
--выполняется каскадно
--delete from c_lg_docs t

insert into c_lg_docs
  (id, old_id, c_kart_pr_id, doc, dat_begin, main, dat_end)
 select c_lg_docs_id.nextval, c.id, p.id, c.doc, c.dat_begin, c.main, c.dat_end
 from c_lg_docs c, c_kart_pr p, kart k
  where k.lsk=p.lsk and p.old_id=c.c_kart_pr_id and
  exists (select * from work_houses c where c.id=k.house_id and c.newreu = newreu_);

--выполняется каскадно
--delete from c_lg_pr t

insert into c_lg_pr
  (c_lg_docs_id, spk_id, type)
 select c.id, r.spk_id, r.type
 from c_lg_pr r, c_lg_docs c, c_kart_pr p, kart k
  where k.lsk=p.lsk and p.id=c.c_kart_pr_id and c.old_id=r.c_lg_docs_id and
  exists (select * from work_houses w where w.id=k.house_id and w.newreu = newreu_);


insert into nabor
  (lsk, usl, org, koeff, norm)
 select t.lsk, n.usl, n.org, n.koeff, n.norm from nabor n, kart k, kart t
   where n.lsk=k.lsk and k.c_lsk_id=t.c_lsk_id and k.lsk <> t.lsk and t.psch <>8
     and exists (select * from work_houses c where c.id=k.house_id and c.newreu = newreu_);

 commit;

end create_uk;

/*procedure saldo_c_lsk(newreu_ in kart.reu%type) is
begin
--отделение сальдо от прошлых периодов (создание нового c_lsk_id)
--(для ТСЖ)

for c in (select k.lsk from kart k where exists
  (select * from c_houses c where c.id=k.house_id and c.reu = newreu_))
loop
  insert into c_lsk (id)
   values (c_lsk_id.nextval);

  update kart t set t.c_lsk_id=c_lsk_id.currval
    where t.lsk=c.lsk;
end loop;
commit;
end;
*/


procedure close_uk(newreu_ in kart.reu%type, mg2_ in params.period%type) is
--закрытие старого фонда 8 -ками.
--Отменить не возможно!!!
--выполнять в 4 ю очередь
begin
-- newreu_:='29';
 --Последний период работы лицевых
-- mg2_:='200812';

 update kart k set k.psch = 8, k.mg2=mg2_ where exists
   (select * from work_houses c where c.id=k.house_id and c.newreu = newreu_);

 commit;
end close_uk;

/*procedure replace_uk_new(newreu_ in kart.reu%type) is
begin
--дома
 update c_houses h set h.reu=newreu_
  where exists
   (select * from work_houses c where c.id=h.id and c.newreu = newreu_);

 update kart h set h.reu=newreu_
  where exists
   (select * from work_houses c where c.id=h.house_id and c.newreu = newreu_);
 commit;
end;*/


procedure clear_tables
is
  mg_ number;
begin
--скрипт удаление не нужных партиций (для уменьшения dumpa)
--убери return;
return;

for c in (select table_name
  from all_tables t where t.owner='SCOTT'
   and t.table_name like 'X%')
loop
  execute immediate 'truncate table '||c.table_name;
end loop;
end clear_tables;


procedure saldo_uk_div
is
  mg_ number;
  var_ number;
  count_ INTEGER;
  c_lsk_id_ number;
  TYPE cv_type IS REF CURSOR;
   cv cv_type;
begin
--скрипт на разделение сальдо по УК 11-21
--убери return;
--return;
/*     OPEN cv FOR 'select count(*) from '||c.table_name||' t
      where t.c_lsk_id=0 and t.lsk=''''';
     LOOP
        FETCH cv INTO count_;
        EXIT WHEN cv%NOTFOUND;
     END LOOP;
     CLOSE cv; */
--создаем индексы
for c in (select table_name
  from all_tables t where t.owner='SCOTT' and t.table_name
    not in ('C_PENYA', 'A_PENYA'))
loop
  var_:=0;
  begin
     OPEN cv FOR 'select count(*) from '||c.table_name||' t
      where t.c_lsk_id=0 and t.lsk=''''';
     LOOP
        FETCH cv INTO count_;
        EXIT WHEN cv%NOTFOUND;
     END LOOP;
     CLOSE cv;
  exception
    when others then
  var_:=1;
  end;
  if var_ = 0 then
  begin
    execute immediate 'drop index tmp$$$_'||c.table_name;
  exception
    when others then
  null;
  end;
  begin
    execute immediate 'create index tmp$$$_'||c.table_name||' on '||c.table_name||' (lsk)';
  exception
    when others then
  null;
  end;
  end if;
end loop;

--обрабатываем таблицы
for m in (select lsk from kart k where exists
(select *
  from kart t where t.reu between '11' and '21'
  and t.c_lsk_id=k.c_lsk_id)
  and k.psch = 8)
loop
  select c_lsk_id.nextval into c_lsk_id_ from dual;
  insert into c_lsk(id)
    values (c_lsk_id_);
  for c in (select table_name
    from all_tables t where t.owner='SCOTT' and t.table_name
      not in ('C_PENYA', 'A_PENYA'))
  loop
  --  logger.log_(null, 'Разделение id, таблица: '||c.table_name);
    begin
     execute immediate 'update '||c.table_name||' t set t.c_lsk_id = '||c_lsk_id_||'
       where t.lsk='''||m.lsk||'''';
    -- logger.log_(null, 'Таблица разделена: '||c.table_name);
    exception
      when others then
      var_:=1;
  --   logger.log_(null, 'Ошибка разделения таблицы: '||c.table_name);
    end;

/*    begin
      execute immediate 'update '||c.table_name||' t set t.c_lsk_id = 0
       where t.lsk='''||m.lsk||'';
    exception
      when others then
      rollback;
      logger.log_(null, 'Ошибка разделения таблицы: '||c.table_name);
    end;
    rollback;
*/

  end loop;
  commit;
end loop;
  return;

end saldo_uk_div;

procedure swap_payment4(reu_ in varchar2, newreu_ in varchar2) is
begin

delete from c_kwtp_mg t where t.nkom='999';
delete from c_kwtp t where t.nkom='999';

--перенос оплаты с УК reu_ на УК newreu_
for c in (select k.lsk, k1.lsk as newlsk, s.summa as summa, s.penya, s.oper,
     s.dopl as DOPL, 999 as nink, '999' as nkom,
     trunc(sysdate) as dtek, s.nkvit, trunc(sysdate) as dat_ink, sysdate as ts
     from c_kwtp_mg s, kart k, kart k1
    where k.reu=reu_ and k.lsk=s.lsk
    and k.k_lsk_id=k1.k_lsk_id
    and k1.psch <> 8 and k1.reu=newreu_
    and (s.summa <> 0 or s.penya <> 0))
loop

insert into c_kwtp
  (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit,
  dat_ink, ts, id, iscorrect)
  values
  (c.lsk, -1*c.summa, -1*c.penya, c.oper, c.dopl, c.nink, c.nkom, c.dtek, c.nkvit,
  c.dat_ink, c.ts, c_kwtp_id.nextval, 1);

insert into c_kwtp
  (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit,
  dat_ink, ts, id, iscorrect)
  values
  (c.newlsk, c.summa, c.penya, c.oper, c.dopl, c.nink, c.nkom, c.dtek, c.nkvit,
  c.dat_ink, c.ts, c_kwtp_id.nextval, 1);

insert into c_kwtp_mg
  (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit,
  dat_ink, ts, c_kwtp_id)
  values
  (c.lsk, -1*c.summa, -1*c.penya, c.oper, c.dopl, c.nink, c.nkom, c.dtek, c.nkvit,
  c.dat_ink, c.ts, c_kwtp_id.currval);

insert into c_kwtp_mg
  (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit,
  dat_ink, ts, c_kwtp_id)
  values
  (c.newlsk, c.summa, c.penya, c.oper, c.dopl, c.nink, c.nkom, c.dtek, c.nkvit,
  c.dat_ink, c.ts, c_kwtp_id.currval);

end loop;
commit;

end swap_payment4;

procedure swap_changes is
  mgchange_ c_change.mgchange%type;
  comment_ c_change_docs.text%type;
  mg_ params.period%type;
  user_id_ number;
  cd_ c_change_docs.text%type;
begin

--период, которым провести изменения
mgchange_:='201004';
--период, сальдо по которому смотрим переплату
mg_:='201004';
--комментарий
comment_:='Переброска кредитового сальдо на УК ';
--Уникальный номер переброски
cd_:='02';

select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from c_change t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.doc_id);
delete from c_change_docs t where t.user_id=user_id_ and t.text=cd_;

insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
select changes_id.nextval, mgchange_, trunc(sysdate), sysdate, user_id_, cd_
 from dual;

--перенос кредитового сальдо с УК на Новый УК ИЗМЕНЕНИЯМИ!!!
for c in (select k.lsk, k1.lsk as newlsk, s2.usl, s2.summa as summa,
     mgchange_ as mgchange
     from (select lsk, sum(summa) as summa from saldo_usl where
      mg=mg_
      group by lsk) s,(select usl, lsk, sum(summa) as summa from saldo_usl where
      mg=mg_
      group by usl, lsk) s2, kart k, kart k1
    where exists
    (select * from work_houses w where w.newreu in ('12') --список новых УК для переброски
     and w.id=k.house_id)
    and k.lsk=s.lsk
    and k.lsk=s2.lsk
    and k.k_lsk_id=k1.k_lsk_id
    and k1.psch <> 8
    and s.summa < 0)
loop

--по старым л.с.
insert into c_change (lsk, usl, summa, mgchange, type, dtek, ts,
user_id, doc_id)
select c.lsk, c.usl, -1*c.summa as summa,
 c.mgchange, 1, trunc(sysdate), sysdate, user_id_, changes_id.currval
 from dual;

--по новым л.с.
insert into c_change (lsk, usl, summa, mgchange, type, dtek, ts,
user_id, doc_id)
select c.newlsk, c.usl, c.summa as summa,
 c.mgchange, 1, trunc(sysdate), sysdate, user_id_, changes_id.currval
 from dual;

end loop;
commit;

end swap_changes;

procedure swap_payment5 is
  dopl_ c_kwtp_mg.dopl%type;
  mg_ params.period%type;
  user_id_ number;
  dat_ date;
  fk_doc_ number;
begin

--перенос переплаты (не кредитового сальдо выборочно по услугам!)
-- с УК на Новый УК Оплатой!!!

--период, которым провести оплату
dopl_:='201702';
--период, по которому смотрим переплату по сальдо
mg_:='201702';
--Дата переброски
dat_:=to_date('02022017','DDMMYYYY');

select t.id into user_id_ from t_user t where t.cd='SCOTT';

insert into c_change_docs
  (mgchange, dtek, ts, user_id, text)
values
  (dopl_, dat_, sysdate, user_id_, 'Перенос кредитового сальдо - оплатой')
  returning id into fk_doc_;

delete from t_corrects_payments t where t.mg=mg_ and t.dat=dat_ and t.id=fk_doc_;

for c in (select k.lsk, s2.org as old_org, s2.usl as old_usl, n.org, n.usl,
   k1.lsk as newlsk, s2.summa as summa
     from (select lsk, sum(summa) as summa from saldo_usl where
      mg=mg_
      group by lsk) s,(select usl, org, lsk, sum(summa) as summa from saldo_usl where
      mg=mg_
      group by usl, org, lsk) s2, kart k, kart k1, nabor n
    where --exists
    --(select * from work_houses w where w.newreu in ('01') --список новых УК для переброски
    -- and w.id=k.house_id)
    k.house_id=37295
    and k.lsk=s.lsk
    and k.lsk=s2.lsk
    and k1.lsk=n.lsk and s2.usl=n.usl
    and k.k_lsk_id=k1.k_lsk_id
    and k1.psch <> 8
    and s.summa < 0)
loop

--по старым л.с.
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
    values
    (c.lsk, c.old_usl, c.old_org, c.summa, user_id_, dat_, mg_, dopl_, fk_doc_);

--по новым л.с.
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
    values
    (c.newlsk, c.usl, c.org, -1 * c.summa, user_id_, dat_, mg_, dopl_, fk_doc_);

end loop;

  -- провести в kwtp_day
  c_gen_pay.dist_pay_del_corr;
  c_gen_pay.dist_pay_add_corr(var_ => 0);
commit;

end swap_payment5;

procedure upd_nabor(oldorg_ in number, org_ in number, newreu_ in kart.reu%type) is
begin
--обновление кода предприятия на новый, после переброски фонда из УК в УК
update nabor n set n.org=org_
 where exists (select * from kart k
 where k.lsk=n.lsk and k.reu=newreu_)
 and n.org=oldorg_; --список услуг, по которым обновить
commit;

end;

procedure go_back_month is
  mg_ params.period%type;
begin
--возвращение назад месяца из архива (специально для полыс)
--внимание! до выполнения отключить все триггеры!!!
mg_:='201005';
update params p set p.period=mg_;
generator.disable_keys(null);

  delete from kart;
  delete from c_kart_pr;
  delete from c_lg_docs;
  delete from c_lg_pr;
  delete from nabor;
  delete from c_kwtp;
  delete from c_kwtp_mg;
  delete from c_change_docs;
  delete from c_change;
  delete from c_vvod;
  delete from c_houses;
  commit;

  insert into kart
    (lsk, kul, nd, kw, fio, kpr, kpr_wr, kpr_ot,
    kpr_cem, kpr_s, opl, ppl, pldop, ki, psch,
    psch_dt, status, kwt, lodpl, bekpl, balpl,
    komn, et, kfg, kfot, phw, mhw,
    pgw, mgw, pel, mel, sub_nach, subsidii,
    sub_data, polis, sch_el, reu, text, schel_dt,
    eksub1, eksub2, kran, kran1, el, el1, sgku,
    doppl, subs_cor, house_id, c_lsk_id,
    mg1, mg2, kan_sch, subs_inf,
    k_lsk_id, dog_num, schel_end, fk_deb_org,
    subs_cur, k_fam, k_im, k_ot, memo, fk_distr,
    law_doc, fk_pasp_org)
    select
    k.lsk, k.kul, k.nd, k.kw, k.fio, k.kpr, k.kpr_wr, k.kpr_ot,
    k.kpr_cem, k.kpr_s, k.opl, k.ppl, k.pldop, k.ki, k.psch,
    k.psch_dt, k.status, k.kwt, k.lodpl, k.bekpl, k.balpl,
    k.komn, k.et, k.kfg, k.kfot, k.phw, k.mhw,
    k.pgw, k.mgw, k.pel, k.mel, k.sub_nach, k.subsidii,
    k.sub_data, k.polis, k.sch_el, k.reu, k.text, k.schel_dt,
    k.eksub1, k.eksub2, k.kran, k.kran1, k.el, k.el1, k.sgku,
    k.doppl, k.subs_cor, k.house_id, k.c_lsk_id,
    k.mg1, k.mg2, k.kan_sch, k.subs_inf,
    k.k_lsk_id, k.dog_num, k.schel_end, k.fk_deb_org,
    k.subs_cur, k.k_fam, k.k_im, k.k_ot, k.memo, k.fk_distr,
    k.law_doc, k.fk_pasp_org
    from arch_kart k where k.mg=mg_;
  commit;


  insert into c_kart_pr
    (id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n,
    dok_d, dok_v, dat_prop, dat_ub, relat_id,
    status_dat, status_chng, k_fam, k_im, k_ot,
    fk_doc_tp, fk_nac, b_place, fk_frm_cntr, fk_frm_regn,
    fk_frm_distr, frm_town, frm_dat, fk_frm_kul, frm_nd,
    frm_kw, w_place, fk_ub, fk_to_cntr, fk_to_regn,
    fk_to_distr, to_town, fk_to_kul, to_nd, to_kw,
    fk_citiz, fk_milit, fk_milit_regn)
    select c.id, c.lsk, c.fio, c.status, c.dat_rog, c.pol, c.dok, c.dok_c, c.dok_n,
      c.dok_d, c.dok_v, c.dat_prop, c.dat_ub, c.relat_id,
      c.status_dat, c.status_chng, c.k_fam, c.k_im, c.k_ot,
      c.fk_doc_tp, c.fk_nac, c.b_place, c.fk_frm_cntr, c.fk_frm_regn,
      c.fk_frm_distr, c.frm_town, c.frm_dat, c.fk_frm_kul, c.frm_nd,
      c.frm_kw, c.w_place, c.fk_ub, c.fk_to_cntr, c.fk_to_regn,
      c.fk_to_distr, c.to_town, c.fk_to_kul, c.to_nd, c.to_kw,
      c.fk_citiz, c.fk_milit, c.fk_milit_regn
    from a_kart_pr c where c.mg=mg_;
  commit;

  insert into c_lg_docs
    (id, c_kart_pr_id, doc, dat_begin, dat_end, main)
    select c.id,
           c.c_kart_pr_id,
           c.doc,
           c.dat_begin,
           c.dat_end,
           c.main
      from a_lg_docs c where c.mg=mg_;
  commit;

  insert into c_lg_pr
    (c_lg_docs_id, spk_id, type)
    select c.c_lg_docs_id, c.spk_id, c.type
      from a_lg_pr c where c.mg=mg_;
  commit;

  insert into nabor
    (lsk, usl, org, koeff, norm, fk_vvod,  vol)
    select c.lsk, c.usl, c.org, c.koeff, c.norm,
      c.fk_vvod, c.vol
      from a_nabor2 c where mg_ between c.mgFrom and c.mgTo;
  commit;

  insert into c_kwtp
    (lsk,
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
     id,
     iscorrect)
    select c.lsk,
           c.summa,
           c.penya,
           c.oper,
           c.dopl,
           c.nink,
           c.nkom,
           c.dtek,
           c.nkvit,
           c.dat_ink,
           c.ts,
           c.id,
           c.iscorrect
      from a_kwtp c where c.mg=mg_;
  commit;

  insert into c_kwtp_mg
    (lsk,
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
     c_kwtp_id)
    select c.lsk,
           c.summa,
           c.penya,
           c.oper,
           c.dopl,
           c.nink,
           c.nkom,
           c.dtek,
           c.nkvit,
           c.dat_ink,
           c.ts,
           c.c_kwtp_id
      from a_kwtp_mg c where c.mg=mg_;
  commit;

  insert into c_change
    (lsk,
     usl,
     summa,
     proc,
     mgchange,
     nkom,
     org,
     type,
     dtek,
     ts,
     user_id,
     doc_id,
     cnt_days,
     show_bill)
    select c.lsk,
           c.usl,
           c.summa,
           c.proc,
           c.mgchange,
           c.nkom,
           c.org,
           c.type,
           c.dtek,
           c.ts,
           c.user_id,
           c.doc_id,
           c.cnt_days,
           c.show_bill
      from a_change c where c.mg=mg_;
  commit;

  insert into c_change_docs
    (id, mgchange, dtek, ts, user_id, text)
    select c.id, c.mgchange, c.dtek, c.ts, c.user_id, c.text
      from a_change_docs c
      where c.mg=mg_;
  commit;

  insert into c_houses
    (id, kul, nd, uch, house_type, fk_pasp_org)
    select c.id, c.kul, c.nd, c.uch, c.house_type, c.fk_pasp_org
      from a_houses c
      where c.mg=mg_;
  commit;

  insert into c_vvod
    (house_id,
     id,
     kub,
     usl,
     kub_man,
     kpr,
     kub_sch,
     sch_cnt,
     sch_kpr,
     cnt_lsk,
     vvod_num)
    select c.house_id,
           c.id,
           c.kub,
           c.usl,
           c.kub_man,
           c.kpr,
           c.kub_sch,
           c.sch_cnt,
           c.sch_kpr,
           c.cnt_lsk,
           c.vvod_num
      from a_vvod c where c.mg=mg_;
 commit;
 generator.enable_keys(null);
end;

procedure create_killme is
--KILLME
begin
--лицевые
delete from c_kart_pr p where exists
 (select * from kart k where k.lsk=p.lsk and k.psch <> 8 and
    exists (select * from work_houses c where
      c.kul=k.kul and c.nd=k.nd and c.newreu is not null)
    );

 for c in (select k.lsk as new_lsk, t.lsk as old_lsk, t.k_lsk_id, t.c_lsk_id,
   t.flag, t.flag1, t.kul, t.nd, t.kw,
   t.kan_sch, p.period as mg1, '999999' as mg2 from kart t, kart k,
   params p where t.psch = 8 and t.k_lsk_id=k.k_lsk_id and k.psch <> 8 and
    '201004' between t.mg1 and t.mg2 and
    exists (select * from work_houses c where c.id=t.house_id and c.newreu is not null)
    order by t.kul, t.nd, t.kw)
 loop
for t in (select p.id,
   p.fio, p.k_fam, p.k_im, p.k_ot, p.status, p.dat_rog, p.pol, p.dok,
   p.dok_c, p.dok_n, p.dok_d, p.dok_v, p.dat_prop, p.dat_ub, p.relat_id
    from c_kart_pr p where p.lsk=c.old_lsk)
loop
  insert into c_kart_pr
  (id, lsk, fio, k_fam, k_im, k_ot, status, dat_rog, pol, dok, dok_c, dok_n,
   dok_d, dok_v, dat_prop, dat_ub, relat_id)
  values
  (kart_pr_id.nextval, c.new_lsk,
   t.fio, t.k_fam, t.k_im, t.k_ot, t.status, t.dat_rog, t.pol, t.dok, t.dok_c, t.dok_n,
   t.dok_d, t.dok_v, t.dat_prop, t.dat_ub, t.relat_id);

  for d in (select c.id, c.doc, c.dat_begin, c.main, c.dat_end
   from c_lg_docs c
    where c.c_kart_pr_id=t.id)
  loop
  insert into c_lg_docs
    (id, c_kart_pr_id, doc, dat_begin, main, dat_end)
   values
   (c_lg_docs_id.nextval, kart_pr_id.currval, d.doc, d.dat_begin, d.main, d.dat_end);

  insert into c_lg_pr
    (c_lg_docs_id, spk_id, type)
   select c_lg_docs_id.currval, r.spk_id, r.type
   from c_lg_pr r
    where r.c_lg_docs_id=d.id;
  end loop;
end loop;

 end loop;

 commit;

end create_killme;

procedure swap_oborot is
  mgchange_ c_change.mgchange%type;
  comment_ c_change_docs.text%type;
  mg_ params.period%type;
  user_id_ number;
  cd_ c_change_docs.text%type;
  old_org_ number;
  new_org_ number;
  dat_ c_change.dtek%type;
  id_ number;
begin
--Переброска оборотов (коррекция тем самым сальдо)
--Оплатой и начислением
--по Шукшина-31 (полыс)

--период, которым провести изменения
mgchange_:='201005';
--комментарий
comment_:='Коррекция сальдо по Шукшина-31';
--Уникальный номер переброски
cd_:='02';
--Дата переброски
dat_:=to_date('31052010','DDMMYYYY');
--ID операции
id_:=2;
old_org_:=3;
new_org_:=78;


select t.id into user_id_ from t_user t where t.cd='SCOTT';
delete from t_corrects_payments t where t.mg=mg_ and t.dat=dat_ and t.id=id_;

delete from c_change t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.doc_id);
delete from c_change_docs t where t.user_id=user_id_ and t.text=cd_;

insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
select changes_id.nextval, mgchange_, dat_, sysdate, user_id_, cd_
 from dual;


for c in (select lsk, usl, sum(charges) as charges,sum(payment) as payment
   from xitog3_lsk t where
  t.mg='201004' and
  exists
  (select * from kart k where k.lsk=t.lsk
  and k.house_id=37525)
  and t.org=3
  group by lsk, usl)
loop

--раз изм
--1-орг
if c.charges is not null then
  insert into c_change (lsk, org, usl, summa, mgchange, type, dtek, ts,
  user_id, doc_id)
  select c.lsk, old_org_, c.usl, -1 * c.charges as summa,
   mgchange_, 1, dat_, sysdate, user_id_, changes_id.currval
   from dual;
  --2-орг
  insert into c_change (lsk, org, usl, summa, mgchange, type, dtek, ts,
  user_id, doc_id)
  select c.lsk, new_org_, c.usl, c.charges as summa,
   mgchange_, 1, dat_, sysdate, user_id_, changes_id.currval
   from dual;
end if;

--оплата
--1-орг
if c.payment is not null then
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
    values
    (c.lsk, c.usl, old_org_, -1 * c.payment, user_id_, dat_, mgchange_, mgchange_, id_);
--оплата
--2-орг
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
    values
    (c.lsk, c.usl, new_org_, c.payment, user_id_, dat_, mgchange_, mgchange_, id_);
end if;
end loop;

commit;
end swap_oborot;

procedure ins_vvod is
 usl_ usl.usl%type;
 id_ c_vvod.id%type;
begin
--добавление вводов по услугам корректировка х.в. и корректировка г.в.
usl_:='055';
for c in (select * from c_houses h where not exists
    (select * from kart k, nabor n, c_vvod c
     where k.lsk=n.lsk and n.fk_vvod=c.id and c.house_id=h.id and c.usl=usl_))
loop
 insert into c_vvod
   (house_id, id, usl, vvod_num)
   values
   (c.id, c_vvod_id.nextval, usl_, 1);
 update nabor n set n.fk_vvod=c_vvod_id.currval
  where n.usl = usl_ and
  exists (select * from kart k where k.lsk=n.lsk and k.house_id=c.id);

end loop;
commit;
end;

procedure create_kart is
maxlsk_ varchar2(8);
nd_ varchar2(6);
house_id_ number;
i number;
begin
--создание базы небольшого ТСЖ
--отключить предварительно триггеры!!!
/*delete from nabor;
delete from c_lg_pr;
delete from c_lg_docs;
delete from c_kart_pr;
delete from c_kwtp_mg;
delete from c_kwtp;
delete from kart;
commit;

for c in (select * from killme_imp)
loop
 insert into k_lsk (id, v, fk_addrtp)
  values (k_lsk_id.nextval, 1, null);
 insert into c_lsk (id)
  values (c_lsk_id.nextval);

   select lpad(max(lsk)+1,8,'0') into maxlsk_ from
     kart k;
   if maxlsk_ is null then
     maxlsk_:='00000001';
   end if;

if c.house is null then
  nd_:='00010а';
  house_id_:=37386;
else
  nd_:='000038';
  house_id_:=37387;
end if;

 insert into kart k (lsk, sch_el, reu, opl, fio, k_fam, k_im, kul, nd, kw, psch, kpr, kpr_wr,
   kpr_ot, status, kfg, kfot, house_id, k_lsk_id, c_lsk_id, mg1, mg2, fk_pasp_org)
 select maxlsk_, 1, '01', c.opl, c.fio, substr(c.fio,1,instr(c.fio,' ',1)),
 substr(c.fio, instr(c.fio,' ',1), length(trim(c.fio))),
 '0001', lpad(nd_,6,'0'), lpad(to_char(c.n),7,'0'),
    1, nvl(c.kpr,0), 0, 0, 2, 2, 2, house_id_, k_lsk_id.currval, c_lsk_id.currval, p.period, '999999',
    t.id
    from params p, t_org t, t_org_tp tp
    where tp.cd='Паспортный стол' and tp.id=t.fk_orgtp;
--содерж
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='003';
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='004';
--отопл
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='007';
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='008';
--х.в.
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 7.9
   from usl u
   where u.usl='011';
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='012';
--г.в.
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 3.6
   from usl u
   where u.usl='015';
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='016';
--канал
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 11.5
   from usl u
   where u.usl='013';
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='014';
--Эл.энерг
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='038';
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='039';

--Эл.энерг гараж
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    decode(nvl(c.el,0), 0, 0, 1), decode(nvl(c.el,0), 0, 0, c.el)
   from usl u
   where u.usl='060';

--Кап.рем
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='033';
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='034';
--ТБО
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='031';
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, 1
   from usl u
   where u.usl='046';
--Антенна
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    1, decode(c.anten, 65, 1, 0)
   from usl u
   where u.usl='043';
--Код.замки
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    decode(c.kodzam,35,1,0), decode(c.kodzam,35,1,0)
   from usl u
   where u.usl='044';
--Код.замки-2
 insert into nabor n (lsk, usl, org, koeff, norm)
  select maxlsk_, u.usl, (select min(kod) from sprorg),
    decode(c.kodzam,27,1,0), decode(c.kodzam,27,1,0)
   from usl u
   where u.usl='045';

i:=1;
while i<=nvl(c.kpr,0)
loop
--проживающие
insert into c_kart_pr
  (id, lsk, fio, status)
values
  (kart_pr_id.nextval, maxlsk_, null, 1);
--документы льгот
insert into c_lg_docs
  (id, c_kart_pr_id, main)
values
  (c_lg_docs_id.nextval, kart_pr_id.currval, 0);
--льготы
insert into c_lg_pr
  (c_lg_docs_id, spk_id, type)
values
  (c_lg_docs_id.currval, 1, 0);
insert into c_lg_pr
  (c_lg_docs_id, spk_id, type)
values
  (c_lg_docs_id.currval, 1, 1);
  i:=i+1;
end loop;
end loop;*/
commit;
end;


procedure find_table is
 tname_ varchar2(255);
 s1 number;
 s2 number;
 s3 number;
begin
--поиск таблиц с определенными критериями

delete from tmp;
--найти все таблицы пользователя scott, с полями кода организации
for c in (select * from all_tables s where s.owner ='SCOTT')
loop
  s1:=0;
  s2:=0;
  s3:=0;
  tname_:=c.table_name;
 begin
   execute immediate 'update '||tname_||' t set t.org=1 where rownum=1';
 exception
    when others then
  s1:=1;
 end;

 begin
   execute immediate 'update '||tname_||' t set t.kod=1 where rownum=1';
 exception
    when others then
  s2:=1;
 end;

 begin
   execute immediate 'update '||tname_||' t set t.fk_org=1 where rownum=1';
 exception
    when others then
  s3:=1;
 end;
 if s1 =0 or s2 =0 or s3 =0 then
  insert into tmp(txt2)
  values (tname_);
 end if;
end loop;
commit;
end;

procedure swap_payment8
is
  mg_ params.period%type;
  mg1_ params.period%type;
  dopl_ params.period%type;
  last_usl_ usl.usl%type;
  last_org_ sprorg.kod%type;
  dbsum_ number;
  crsum_ number;
  summa_ number;
  id_ number;
  id2_ number;

begin
--переброска мелкого кредитового или дебетового сальдо
--ред. от 30.08.2011
--ПРЕДВАРИТЕЛЬНО ВЫПОЛНИТЬ ИТОГОВОЕ! (Сальдо, ПОДГОТОВКУ АРХИВОВ! (для a_nabor))
--берем исх сальдо

select period1, period into mg_, mg1_ from v_params;

id_:=17;
id2_:=18;
delete from t_corrects_payments t where t.mg=mg1_ and t.id in (id_, id2_);

--Выбираем мелкое кредитовое сальдо, где так же превальирует дебетовое сальдо
for c in (select s.lsk, s.org, s.usl, s.summa as crsal,
  a.summa as dbsum from saldo_usl s,
 (select d.lsk, sum(summa) as summa from saldo_usl d where d.mg=mg_
   and d.summa > 0
   group by d.lsk) a
 where s.mg=mg_ and s.lsk=a.lsk(+)
 and
 exists
 (select * from saldo_usl t
  where t.lsk=s.lsk and t.mg=mg_
  and t.summa < 0)
 and
 exists
 (select lsk, sum(summa) from saldo_usl t
  where t.lsk=s.lsk and t.mg=mg_
  group by lsk
  having nvl(sum(summa),0)>0)
 and s.summa < 0 )
loop
dbsum_:=nvl(c.dbsum,0);
crsum_:=nvl(c.crsal,0);

           --находим дебетовое сальдо, на которое надо распределить кредитовое по этому л/c
for d in ( -- с учётом уже проведенных корректировок
    select lsk, org, usl, sum(summa) as summa from (
    select s.lsk, s.org, s.usl, s.summa as summa from saldo_usl s
   where s.lsk=c.lsk and s.mg=mg_
    union all
    select s.lsk, s.org, s.usl, -1 * s.summa as summa from t_corrects_payments s
   where s.lsk=c.lsk and s.mg=mg_ and s.id=id_)
    having sum(summa) > 0
    group by lsk, org, usl
    )
loop
  exit when crsum_ >= 0 or dbsum_<=0;
  --распределяем оплату по вх сальдо
  if abs(crsum_) <= d.summa then
    --ставим на дебетовое
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
      values
      (d.lsk, d.usl, d.org, -1 * crsum_, uid, trunc(sysdate), mg1_, mg_, id_);
    --снимаем с кредитового
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
      values
      (c.lsk, c.usl, c.org, crsum_, uid, trunc(sysdate), mg1_, mg_, id2_);
    dbsum_:=dbsum_-(-1 * c.crsal);
    crsum_:=crsum_+(-1 * c.crsal);
  else
    --ставим на дебетовое
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
      values
      (d.lsk, d.usl, d.org, d.summa, uid, trunc(sysdate), mg1_, mg_, id_);
    --снимаем с кредитового
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, id)
      values
      (c.lsk, c.usl, c.org, -1 * d.summa, uid, trunc(sysdate), mg1_, mg_, id2_);
    dbsum_:=dbsum_-d.summa;
    crsum_:=crsum_+d.summa;
  end if;
end loop;


end loop;
commit;
end;

procedure set_sal_mg
is
--old_mg_ saldo_usl.mg%type;
begin
--инициализация таблицы для по-сальдо-периодному распределению

--old_mg_:=to_char(add_months(to_date(c.mg||'01','YYYYMMDD'),-1), 'YYYYMM');

execute immediate 'truncate table deb_usl_mg';

insert into deb_usl_mg
  (lsk, usl, org, summa, mg, period)
select t.lsk, t.usl, t.org, sum(t.summa) as summa, '000000' as mg,
  to_char(add_months(to_date(p.period||'01','YYYYMMDD'),-1), 'YYYYMM') as period from
  saldo_usl t, params p where t.mg=p.period
  group by t.lsk, t.usl, t.org, t.mg,
  to_char(add_months(to_date(p.period||'01','YYYYMMDD'),-1), 'YYYYMM'); --вх сальдо текущего периода, в кач-ве свернутой задолженности
                                        --прошлых периодов
commit;
end;

procedure swap_oborot2 is
  mgchange_ c_change.mgchange%type;
  comment_ c_change_docs.text%type;
  mg_ params.period%type;
  user_id_ number;
  cd_ c_change_docs.text%type;
  dat_ c_change.dtek%type;
  changes_id_ number;
begin
--Переброска сальдо по ТСЖ (Кис)
--c одной орг. на другую
--период, которым провести изменения
mgchange_:='201209';
--комментарий
comment_:='Коррекция сальдо по УК';
--Уникальный номер переброски
cd_:='01';
--Дата переброски
dat_:=to_date('19092012','DDMMYYYY');
select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from c_change t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.doc_id);
delete from c_change_docs t where t.user_id=user_id_ and t.text=cd_;

select changes_id.nextval into changes_id_ from dual;

insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
select changes_id_, mgchange_, dat_, sysdate, user_id_, cd_
 from dual;

  insert into c_change (lsk, org, usl, summa, mgchange, type, dtek, ts,
  user_id, doc_id)
  select s.lsk, s.org, s.usl, -1 * s.summa as summa,
   mgchange_, 1, dat_, sysdate, user_id_, changes_id_
   from saldo_usl s, kart k, t_org o
    where s.lsk=k.lsk and k.reu=o.reu and o.parent_id=626
    and s.usl in ('035','036') and s.org=51
    and s.mg=mgchange_
    union all
  select s.lsk, 723 as org, s.usl,  s.summa as summa,
   mgchange_, 1, dat_, sysdate, user_id_, changes_id_
   from saldo_usl s, kart k, t_org o
    where s.lsk=k.lsk and k.reu=o.reu and o.parent_id=626
    and s.usl in ('035','036') and s.org=51
    and s.mg=mgchange_;

commit;
end swap_oborot2;
procedure swap_oborot3 is
  mgchange_ c_change.mgchange%type;
  comment_ c_change_docs.text%type;
  mg_ params.period%type;
  user_id_ number;
  cd_ c_change_docs.text%type;
  dat_ c_change.dtek%type;
  changes_id_ number;
begin
--Переброска сальдо по УК (Полыс)
--c одной орг. на другую
--период, которым провести изменения
mgchange_:='201209';
--комментарий
comment_:='Коррекция сальдо по УК';
--Уникальный номер переброски
cd_:='01';
--Дата переброски
dat_:=to_date('19092012','DDMMYYYY');
select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from c_change t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.doc_id);
delete from c_change_docs t where t.user_id=user_id_ and t.text=cd_;

select changes_id.nextval into changes_id_ from dual;

insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
select changes_id_, mgchange_, dat_, sysdate, user_id_, cd_
 from dual;

  insert into c_change (lsk, org, usl, summa, mgchange, type, dtek, ts,
  user_id, doc_id)
  select s.lsk, s.org, s.usl, -1 * s.summa as summa,
   mgchange_, null, dat_, sysdate, user_id_, changes_id_
   from saldo_usl s, kart k, t_org o, work_houses h
    where s.lsk=k.lsk and k.reu=o.reu
    and s.mg=mgchange_ and h.id=k.house_id
    union all
  select s.lsk, s.org, s.usl, s.summa as summa,
   mgchange_, null, dat_, sysdate, user_id_, changes_id_
   from saldo_usl s, kart k, kart k2, t_org o, work_houses h
    where s.lsk=k.lsk and k.reu=o.reu
    and s.mg=mgchange_ and h.id=k.house_id
    and k.k_lsk_id = k2.k_lsk_id
    and k2.psch <>8;


commit;
end swap_oborot3;


procedure close_sal is
l_mg params.period%type;
l_mg1 params.period%type;
l_dt date;
l_id c_change_docs.id%type;
l_cd_tp c_change_docs.cd_tp%type;
begin
--закрытие сальдо ОПЛАТОЙ, по закрытым лицевым определенного периода
--и определенных УК
l_mg:= '201301';
l_mg1:= '201212';
l_dt:=to_date('20130113','YYYYMMDD');
l_cd_tp:='PAY_SAL2';

delete from t_corrects_payments t where mg=l_mg
 and exists (select * from c_change_docs d where
  d.cd_tp=l_cd_tp and d.id=t.fk_doc);

delete from c_change_docs t where t.cd_tp=l_cd_tp;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, text, cd_tp)
  values (l_mg, l_dt, sysdate, uid, 'Коррекция сальдо по закрытым л/c', l_cd_tp)
returning id into l_id;

for c in (
  select t.lsk
     from saldo_usl t where t.mg=l_mg
     and exists (select * from arch_kart k where
     k.mg=l_mg1
     and k.lsk=t.lsk and k.psch in (8,9)
     and exists (select * from s_reu_trest s where s.reu=k.reu
      and s.trest='03')
     )
     group by t.lsk
     having nvl(sum(t.summa),0)= 0
     and nvl(count(*),0) <> 0


 )
loop
  delete from temp_prep;
  insert into temp_prep
  (usl, org, summa, tp_cd)
  select t.usl, t.org, t.summa, 0 as tp_cd
     from saldo_usl t where t.mg=l_mg
     and t.lsk=c.lsk;

  --закрываем суммы сальдо
  c_prep.dist_summa;

--загружаем корректировки c обратным знаком
insert into t_corrects_payments
  (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
  select c.lsk, t.usl, t.org, -1*t.summa, uid, l_dt, l_mg, l_mg, l_id, 0
   from temp_prep t where
     t.tp_cd in (3,4);
  commit;
end loop;

commit;
end;

procedure close_sal2 is
l_mg params.period%type;
l_dt date;
l_id c_change_docs.id%type;
l_cd_tp c_change_docs.cd_tp%type;
l_user_id t_user.id%type;
begin
--закрытие сальдо ИЗМЕНЕНИЯМИ, по условию
l_mg:= '201307';
l_dt:=to_date('20130725','YYYYMMDD');
l_cd_tp:='PAY_SAL2';
select t.id into l_user_id
 from t_user t where t.cd=user;

delete from c_change_docs t where t.cd_tp=l_cd_tp;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, text, cd_tp)
  values (l_mg, l_dt, sysdate, uid, 'Коррекция сальдо по закрытым л/c', l_cd_tp)
returning id into l_id;

for c in (
  select t.lsk
     from saldo_usl t where t.mg=l_mg
     and exists (select * from kart k where
       k.lsk=t.lsk and k.psch in (8,9)
--       and k.reu='' and k.kul=''
--       and k.nd in ('','','')
     )
     group by t.lsk
     having nvl(sum(t.summa),0)= 0
     and nvl(count(*),0) <> 0


 )
loop
  delete from temp_prep;
  insert into temp_prep
  (usl, org, summa, tp_cd)
  select t.usl, t.org, t.summa, 0 as tp_cd
     from saldo_usl t where t.mg=l_mg
     and t.lsk=c.lsk;

  --закрываем суммы сальдо
  c_prep.dist_summa;

--загружаем корректировки
insert into c_change
  (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id,
   doc_id)
  select c.lsk, t.usl, t.org, t.summa, l_mg as mgchange, '999' as nkom, 0 as type,
   l_dt, sysdate, l_user_id, l_id
   from temp_prep t where
     t.tp_cd in (3,4);
  commit;
end loop;

commit;
end;

procedure close_sal3 is
l_mg params.period%type;
l_dt date;
l_id c_change_docs.id%type;
l_cd_tp c_change_docs.cd_tp%type;
l_var number;
begin
--закрытие сальдо ОПЛАТОЙ, НЕ для корректировки c_deb_usl, а для корректировки saldo_usl
l_mg:= '201408';
l_dt:=to_date('20140821','YYYYMMDD');
l_cd_tp:='PAY_SAL1';
l_var:=12; --12 корректировка не для c_deb_usl (полыс)

delete from t_corrects_payments t where mg=l_mg
 and exists (select * from c_change_docs d where
  d.cd_tp=l_cd_tp and d.id=t.fk_doc);

delete from c_change_docs t where t.cd_tp=l_cd_tp;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, text, cd_tp)
  values (l_mg, l_dt, sysdate, uid, 'Коррекция сальдо', l_cd_tp)
returning id into l_id;

for c in (
  select distinct t.lsk --найти кредитовое сальдо (входящее) при наличии дебетового
     from saldo_usl t where t.mg=l_mg
     and t.summa<0 and exists
     (select * from saldo_usl s where s.mg=t.mg
       and s.lsk=t.lsk
       and s.summa>0)
 )
loop
  delete from temp_prep;
  insert into temp_prep
  (usl, org, summa, tp_cd)
  select t.usl, t.org, t.summa, 0 as tp_cd
     from saldo_usl t where t.mg=l_mg
     and t.lsk=c.lsk;

  --закрываем суммы сальдо
  c_prep.dist_summa;

--загружаем корректировки c обратным знаком
insert into t_corrects_payments
  (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
  select c.lsk, t.usl, t.org, -1*t.summa, uid, l_dt, l_mg, l_mg, l_id, l_var
   from temp_prep t where
     t.tp_cd in (3,4);
  commit;
end loop;

--
--В этом периоде еще и свыше с.н. перекинуть на норму (только для полыс)
/*003 004 Cодер/соц.нор.
004 004 Cодер/св.нор
005 006 Экспл.лифт./соц.нор.
006 006 Экспл.лифт./св.нор
007 008 Отопление
008 008 Отопление/св.нор
009 010 Содерж.лифта/соц.нор.
010 010 Содерж.лифта/св.нор
011 012 Холодная вода
012 012 Холодн.вода /св.нор
013 014 Канализование
014 014 Канализован /св.нор
015 016 Горячая вода
016 016 Горячая вода /св.нор
026 026 Плата/найм
031 046 Вывоз ТБО/соц.нор.
033 034 Кап.ремонт/соц.нор.
034 034 Кап.ремонт/св.нор.
038 039 Эл.эн.
039 039 Эл.эн./св.нор
046 046 Вывоз ТБО/св.нор.
052 052 Очистка   выгр.ям/соц.нор.
053 053 ОДН-Эл.эн.
054 054 Утилизация
055 055 Текущий ремонт
056   Отопление, 0 зарег.   */

/*insert into t_corrects_payments
  (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
  select t.lsk, t.usl, t.org, t.summa, uid, l_dt, l_mg, l_mg, l_id, l_var
   from saldo_usl t, usl u where t.usl=u.usl_p and
     t.usl in ('004','006','010','034','046') and t.mg=l_mg
     and t.summa<0
  union all
  select t.lsk, u.usl, t.org, -1*t.summa, uid, l_dt, l_mg, l_mg, l_id, l_var
   from saldo_usl t, usl u where t.usl=u.usl_p and
     t.usl in ('004','006','010','034','046') and t.mg=l_mg
     and t.summa<0;
  */
  commit;
--В этом периоде еще и свыше с.н. перекинуть на норму (только для полыс)
--

commit;
end;

--переброска сальдо по выбранной услуге, посредством проводки нулевой суммы (сальдо с кредита перейдёт на дебет)
--ред 25.11.2014
procedure swap_sal1 is
  l_uslm usl.uslm%type;
  l_mg params.period%type;
  l_dt date;
  l_id number;
  l_oper oper.oper%type;
  l_nkom c_comps.nkom%type;
  l_org number;
begin
select p.period into l_mg from params p;
l_dt:=gdt(31,0,0); --28 числа, текущего, по params периода
l_oper:='99';
l_nkom:='999';
--например капремонт
l_uslm:='023';
l_org:=43;

Raise_application_error(-20000, 'НЕ РАБОТАЕТ, ИСПОЛЬЗОВАТЬ scripts2.swap_ZERO!');
--удаляется 99 операция!!!
delete from c_kwtp t where t.oper='99';

for c in (select distinct t.lsk from kart k, saldo_usl t where k.reu in ('85')
--    and exists (select * from usl u where u.uslm = l_uslm and u.usl=t.usl)
    and k.lsk=t.lsk and t.mg=to_char(l_dt, 'YYYYMM')
    --and t.org=l_org
    and t.summa<0 --где есть кредитовые суммы 
    )
loop
  
  --установка нулевых сумм, автоматическое перераспределение внутри
  insert into c_kwtp
    (lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, iscorrect)
    values 
    (c.lsk, 0, l_oper, l_mg, 1, l_nkom, l_dt, 1, l_dt, sysdate, 0)
    returning id into l_id;

  insert into c_kwtp_mg
    (lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, c_kwtp_id)
  values
    (c.lsk, 0, l_oper, l_mg, 1, l_nkom, l_dt, 1, l_dt, sysdate, l_id); --is_dist=0 - распределить! (распределится в триггере)

end loop;    

commit;
end;


--ОСНОВНОЙ скрипт переноски всего сальдо с помощью перерасчета 
--а так же текущей оплаты, поступившей в этом периоде!!! ред 03.02.2016
--по основному или дополнительному счетам на открытый ЛС в любом УК!
procedure swap_sal_MAIN is
  dopl_ c_kwtp_mg.dopl%type;
  mg_ params.period%type;
  l_mg_back params.period%type;
  user_id_ number;
  dat_ date;
  fk_doc_ number;
  l_lsk_tp_cd v_lsk_tp.cd%type;
  l_cd c_change_docs.cd_tp%type;
  l_mg_frwrd params.period%type;
a number;
begin
--период, которым провести оплату
dopl_:='201703';
--период, сальдо по которому смотрим
mg_:='201610';
--период на месяц назад
l_mg_back:=utils.add_months_pr(mg_,-1);
--период на месяц вперед
l_mg_frwrd:=utils.add_months_pr(mg_,1);
--Дата переброски
dat_:=to_date('31032017','DDMMYYYY');
--тип счетов
l_lsk_tp_cd:='LSK_TP_MAIN'; --LSK_TP_ADDIT
--CD переброски
l_cd:='сал.'||l_lsk_tp_cd||to_char(dat_,'DDMMYYYY')||'_2';

a:=init.set_date(dat_);

select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from t_corrects_payments t where t.mg=dopl_ 
 and exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);
delete from c_change t where
  exists (select * from c_change_docs d where d.id=t.doc_id and
  d.cd_tp=l_cd);
delete from c_pen_corr t where
  exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);

delete from c_change_docs t where t.cd_tp=l_cd;

--return ;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (dopl_, dat_, sysdate, user_id_, l_cd)
  returning id into fk_doc_;


for c in (select k.lsk, s2.org, s2.usl,
   k1.lsk as newlsk, s2.summa as summa
     from (select usl, org, lsk, sum(summa) as summa from saldo_usl where
      mg=mg_ --взять сальдо
      group by usl, org, lsk) s2, kart k, kart k1, v_lsk_tp tp
    where 
    k.lsk=s2.lsk
    and k.k_lsk_id=k1.k_lsk_id
    and tp.cd=l_lsk_tp_cd
    and k1.reu='91' -- УК назначения
    and exists (select * from prep_lsk t where t.lsk=k.lsk) -- ЛС источника
    and k.fk_tp=tp.id
    and k1.fk_tp=tp.id
    and k1.psch in (8)
    and nvl(s2.summa,0) <> 0
    )
loop

--по старым л.с.
  insert into c_change
    (lsk, usl, org, summa, user_id, dtek, mg2, mgchange, doc_id, ts)
    values
    (c.lsk, c.usl, c.org, -1*c.summa, user_id_, dat_, dopl_, dopl_, fk_doc_, sysdate);

--по новым л.с.
  insert into c_change
    (lsk, usl, org, summa, user_id, dtek, mg2, mgchange, doc_id, ts)
    values
    (c.newlsk, c.usl, c.org, c.summa, user_id_, dat_, dopl_, dopl_, fk_doc_, sysdate);

end loop;

--commit;

/*
for c in (select k.lsk, s2.org as org, s2.usl as usl, s2.dopl,
   k1.lsk as newlsk, s2.summa as summa
     from (select t.usl, t.org, t.lsk, m.dopl, sum(t.summa) as summa from c_kwtp_mg m, kwtp_day t
      where to_char(t.dat_ink,'YYYYMM')=dopl_ and m.id=t.kwtp_id
      group by t.usl, t.org, m.dopl, t.lsk) s2, kart k, kart k1, v_lsk_tp tp
    where 
    k.lsk=s2.lsk
    and k.k_lsk_id=k1.k_lsk_id
    --and k.house_id in (4942)
    and k.reu='88'
    and k1.reu='12'
    --and k1.psch <> 8 
    and tp.cd=l_lsk_tp_cd
    and k.fk_tp=tp.id
    and k1.fk_tp=tp.id
    )
loop

--по старым л.с.
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc)
    values
    (c.lsk, c.usl, c.org, -1*c.summa, user_id_, dat_, dopl_, c.dopl, fk_doc_);--здесь снимаем с конкретного периода

--по новым л.с.
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc)
    values
    (c.newlsk, c.usl, c.org, c.summa, user_id_, dat_, dopl_, dopl_, fk_doc_); --здесь ставим на текущий период

null;
end loop;
*/

--сальдо по пене и текущую пеню
for c in (select k.lsk,
   k1.lsk as newlsk
     from (select t.lsk, sum(t.penya) as penya from a_penya t 
      where t.mg=l_mg_back
      group by t.lsk
      having sum(t.penya)<>0) s2, kart k, kart k1, v_lsk_tp tp
    where 
    k.lsk=s2.lsk
    and k.k_lsk_id=k1.k_lsk_id
    and k1.reu='91'
    and exists (select * from prep_lsk t where t.lsk=k.lsk) -- ЛС источника
    and tp.cd=l_lsk_tp_cd
    and k.fk_tp=tp.id
    and k1.fk_tp=tp.id
    and k1.psch in (8) -- в данном случае по закрытым лс
    )
loop
  --генерить пеню по старым лс на дату переброски
  c_cpenya.gen_penya(c.lsk, dat_, 0, 0);
  
--по старым л.с. -снять
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select t.lsk, -1*t.penya, t.mg1 as dopl, dat_ as dtek,  
   sysdate as ts, u.id as fk_user, fk_doc_ from 
   a_penya t, t_user u where t.mg=l_mg_back --вх.сальдо по пене
   and t.lsk=c.lsk and u.cd=user
  union all
  select t.lsk, -1*sum(t.penya), t.mg1 as dopl, dat_ as dtek,  
   sysdate as ts, u.id as fk_user, fk_doc_ from 
   c_pen_cur t, t_user u where 
   t.lsk=c.lsk and u.cd=user
   group by t.lsk, u.id, t.mg1
   having sum(t.penya)<>0;

--по новым л.с. - поставить
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select c.newlsk, sum(t.penya) as penya, dopl_ as dopl, 
   dat_ as dtek, sysdate as ts, u.id as fk_user, fk_doc_ from 
   a_penya t, t_user u where t.mg=l_mg_back --вх.сальдо по пене
   and t.lsk=c.lsk and u.cd=user
   group by c.newlsk, u.id
   having sum(t.penya)<>0
  union all
  select c.newlsk, sum(t.penya), t.mg1 as dopl, dat_ as dtek,  
   sysdate as ts, u.id as fk_user, fk_doc_ from 
   c_pen_cur t, t_user u where 
   t.lsk=c.lsk and u.cd=user
   group by c.newlsk, u.id, t.mg1
   having sum(t.penya)<>0;

end loop;


--определённые перерасчеты перенести
for c in (select s2.id, k.lsk,
   k1.lsk as newlsk
     from (select t.id, t.lsk, sum(t.summa) as summa from c_change t 
      where t.user_id in (16,43)
      group by t.id, t.lsk
      having sum(t.summa)<>0) s2, kart k, kart k1, v_lsk_tp tp
    where 
    k.lsk=s2.lsk
    and k.k_lsk_id=k1.k_lsk_id
    and k.house_id in (4942)
    and k1.psch <> 8 
    and tp.cd=l_lsk_tp_cd
    and k.fk_tp=tp.id
    and k1.fk_tp=tp.id
    )
loop

--по старым л.с. --снять
/*  insert into c_change
    (lsk, usl, org, summa, user_id, dtek, mg2, mgchange, doc_id, ts)
  select t.lsk, t.usl, t.org, -1*t.summa as summa, u.id as user_id, dat_ as dtek, t.mgchange as mg2, t.mgchange,  
   fk_doc_, sysdate as ts from 
   c_change t, t_user u where 
    t.lsk=c.lsk and u.cd=user
    and t.id=c.id;

--по новым л.с., свернуть период, поставить сумму
  insert into c_change
    (lsk, usl, org, summa, user_id, dtek, mg2, mgchange, doc_id, ts)
  select c.newlsk, t.usl, t.org, t.summa as summa, u.id as user_id, dat_ as dtek, t.mgchange as mg2, t.mgchange,  
   fk_doc_, sysdate as ts from 
   c_change t, t_user u where 
    t.lsk=c.lsk and u.cd=user
    and t.id=c.id;*/
    null;

end loop;

commit;

end swap_sal_MAIN;


--ПО ЛИЦ.СЧЕТАМ В KMP_LSK
--ОСНОВНОЙ скрипт переноски всего сальдо с помощью перерасчета 
--а так же текущей оплаты, поступившей в этом периоде!!! ред 03.02.2016
--по основному или дополнительному счетам на открытый л.с. в целевом УК!
procedure swap_sal_MAIN_BY_LSK is
  l_reu_dst t_org.reu%type;
  dopl_ c_kwtp_mg.dopl%type;
  mg_ params.period%type;
  l_mg_back params.period%type;
  user_id_ number;
  dat_ date;
  fk_doc_ number;
  l_lsk_tp_cd v_lsk_tp.cd%type;
  l_cd c_change_docs.cd_tp%type;
  l_mg_frwrd params.period%type;
a number;
begin
--период, которым провести изменение
dopl_:='201802';
--период, сальдо по которому смотрим
mg_:='201803';
--период для сальдо по пене
l_mg_back:='201801';
--период на месяц вперед
l_mg_frwrd:=utils.add_months_pr(mg_,1);
--Дата переброски
dat_:=to_date('28022018','DDMMYYYY');
--тип счетов
l_lsk_tp_cd:='LSK_TP_ADDIT'; --LSK_TP_ADDIT
--CD переброски
l_cd:=l_lsk_tp_cd||'20180228_1';
--целевой УК
l_reu_dst:='96';

a:=init.set_date(dat_);

select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from t_corrects_payments t where t.mg=dopl_ 
 and exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);
delete from c_change t where
  exists (select * from c_change_docs d where d.id=t.doc_id and
  d.cd_tp=l_cd);
delete from c_pen_corr t where
  exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);

delete from c_change_docs t where t.cd_tp=l_cd;

--return ;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (dopl_, dat_, sysdate, user_id_, l_cd)
  returning id into fk_doc_;


for c in (select k.lsk, s2.org, s2.usl,
   k1.lsk as newlsk, s2.summa as summa
     from (select usl, org, lsk, sum(summa) as summa from saldo_usl where
      mg=mg_ 
      group by usl, org, lsk) s2, kart k, kart k1, v_lsk_tp tp--, kmp_houses x
    where 
    k.lsk=s2.lsk
    and k1.reu=l_reu_dst
    and k.k_lsk_id=k1.k_lsk_id
    and k.house_id in (12160,12127,12134,12164,12143,12162,12163,12161,10935,10841)
    --and k.house_id=x.old_id
    --and k1.house_id=x.id
    and tp.cd=l_lsk_tp_cd
    --and exists (select * from kmp_lsk m where k.lsk=m.lsk)
    and k.fk_tp=tp.id
    and k1.fk_tp=tp.id
    )
loop
if c.lsk='80001506' then
  null;
end if;
--по старым л.с.
  insert into c_change
    (lsk, usl, org, summa, user_id, dtek, mg2, mgchange, doc_id, ts)
    values
    (c.lsk, c.usl, c.org, -1*c.summa, user_id_, dat_, dopl_, dopl_, fk_doc_, sysdate);

--по новым л.с.
  insert into c_change
    (lsk, usl, org, summa, user_id, dtek, mg2, mgchange, doc_id, ts)
    values
    (c.newlsk, c.usl, c.org, c.summa, user_id_, dat_, dopl_, dopl_, fk_doc_, sysdate);

end loop;

-- оплата
/*for c in (select k.lsk, s2.org as org, s2.usl as usl, s2.dopl,
   k1.lsk as newlsk, s2.summa as summa
     from (select t.usl, t.org, t.lsk, m.dopl, sum(t.summa) as summa from c_kwtp_mg m, kwtp_day t
      where to_char(t.dat_ink,'YYYYMM')=dopl_ and m.id=t.kwtp_id
      group by t.usl, t.org, m.dopl, t.lsk) s2, kart k, kart k1, v_lsk_tp tp--, kmp_houses x
    where 
    k.lsk=s2.lsk
    and k1.reu=l_reu_dst
    and k.k_lsk_id=k1.k_lsk_id
    and exists (select * from kmp_lsk m where k.lsk=m.lsk)
    --and k.house_id=x.old_id
    --and k1.house_id=x.id
    and tp.cd=l_lsk_tp_cd
    and k.fk_tp=tp.id
    and k1.fk_tp=tp.id
    )
loop

--по старым л.с.
 insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc)
    values
    (c.lsk, c.usl, c.org, -1*c.summa, user_id_, dat_, dopl_, c.dopl, fk_doc_);--здесь снимаем с конкретного периода

--по новым л.с.
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc)
    values
    (c.newlsk, c.usl, c.org, c.summa, user_id_, dat_, dopl_, dopl_, fk_doc_); --здесь ставим на текущий период

null;
end loop;*/

--сальдо по пене и текущую пеню
for c in (select k.lsk,
   k1.lsk as newlsk
     from (select t.lsk, sum(t.penya) as penya from a_penya t 
      where t.mg=l_mg_back
      group by t.lsk
      having sum(t.penya)<>0) s2, kart k, kart k1, v_lsk_tp tp--, kmp_houses x
    where 
    k.lsk=s2.lsk
    and k1.reu=l_reu_dst
    and k.k_lsk_id=k1.k_lsk_id
    and k.house_id in (12160,12127,12134,12164,12143,12162,12163,12161,10935,10841)
    --and exists (select * from kmp_lsk m where k.lsk=m.lsk)
    --and k.house_id=x.old_id
    --and k1.house_id=x.id
    and tp.cd=l_lsk_tp_cd
    and k.fk_tp=tp.id
    and k1.fk_tp=tp.id
    )
loop
  --генерить пеню по старым лс на дату переброски
  c_cpenya.gen_penya(c.lsk, dat_, 0, 0);
  
--по старым л.с. -снять
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select t.lsk, -1*t.penya, t.mg1 as dopl, dat_ as dtek,  
   sysdate as ts, u.id as fk_user, fk_doc_ from 
   a_penya t, t_user u where t.mg=l_mg_back --вх.сальдо по пене
   and t.lsk=c.lsk and u.cd=user
  union all
  select t.lsk, -1*sum(t.penya), t.mg1 as dopl, dat_ as dtek,  
   sysdate as ts, u.id as fk_user, fk_doc_ from 
   c_pen_cur t, t_user u where 
   t.lsk=c.lsk and u.cd=user
   group by t.lsk, u.id, t.mg1
   having sum(t.penya)<>0;

--по новым л.с. - поставить
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
  select c.newlsk, sum(t.penya) as penya, dopl_ as dopl, 
   dat_ as dtek, sysdate as ts, u.id as fk_user, fk_doc_ from 
   a_penya t, t_user u where t.mg=l_mg_back --вх.сальдо по пене
   and t.lsk=c.lsk and u.cd=user
   group by c.newlsk, u.id
   having sum(t.penya)<>0
  union all
  select c.newlsk, sum(t.penya), t.mg1 as dopl, dat_ as dtek,  
   sysdate as ts, u.id as fk_user, fk_doc_ from 
   c_pen_cur t, t_user u where 
   t.lsk=c.lsk and u.cd=user
   group by c.newlsk, u.id, t.mg1
   having sum(t.penya)<>0;

end loop;



commit;

end swap_sal_MAIN_BY_LSK;

--перенос оплаты, начисления на другую организацию по определенному л.с. и периоду
--с использованием xitog3_lsk!- договорились 03.02.2016 больше не выполнять этот скрипт,
--так как приводит к массовому появлению ненужных строк!
procedure create_uk_new_SPECIAL(newreu_ in kart.reu%type) is
  maxlsk_ number;
  mgchange_ c_change.mgchange%type;
  comment_ c_change_docs.text%type;
  mg_ params.period%type;
  mg_close_ params.period%type;
  period_ params.period%type;
  user_id_ number;
  changes_id_ c_change_docs.id%type;
  cnt_ number;
  l_tp_sal number;
  l_par number;
  l_id number;
begin
/*
select period into period_ from params p;
select period3 into mg_close_ from v_params;
  for c in (select t.reu, s.name, t.kul, t.nd from c_houses t, spul s
    where nvl(t.psch,0)<>1 and t.kul=s.id
    group by t.reu,s.name,t.kul,t.nd
    having count(*)>1)
  loop
   Raise_application_error(-20000,
     'Отмена, найдено два открытых дома с одним адресом: REU='||c.reu||', KUL='||c.kul||', Ул='||c.name||', ND='||c.nd);
  end loop;

--установка флага переноса, т.е. записи инсертятся через скрипт переноса домов
c_charges.scr_flag_:=1;
--ВНИМАНИЕ если type_=1 то переносятся все дома и закрытые и не закрытые
--использовать этот параметр, только в определенных случаях (ред.19.09.12)

--дома
delete from kmp_houses;

insert into kmp_houses
  (id, old_id, reu, kul, nd, uch, maxlsk, kw, minlsk, house_type, opl)
  select c_house_id.nextval, id, newreu_, kul, nd, uch, maxlsk, kw, minlsk, house_type, opl
   from c_houses h where exists
   (select * from work_houses c where c.id=h.id and c.newreu = newreu_);

insert into c_houses
  (id, reu, kul, nd, uch, maxlsk, kw, minlsk, house_type, opl)
select id, reu, kul, nd, uch, maxlsk, kw, minlsk, house_type, opl
from kmp_houses;

--перенести необходимые параметры дома
for c in (select h.k_lsk_id from c_houses h
    where exists
   (select * from work_houses c where c.id=h.id and c.newreu = newreu_))
loop
  l_par:=c_obj_par.get_num_param(p_k_lsk_id => c.k_lsk_id,
    p_lsk => null, p_cd => 'area_general_property');
  l_id := c_obj_par.set_num_param(p_k_lsk_id => c.k_lsk_id,
                                     p_lsk => null,
                                     p_cd => 'area_general_property',
                                     p_val => l_par\*,
                                     p_cdtp => 'house_params'*\);
end loop;

--отмечаем дома закрытым признаком, с которых переносим
update c_houses t set t.psch=1 where exists
 (select * from work_houses c where c.id=t.id and c.newreu = newreu_);

--лицевые
--присоединение к УК
--проверка
select max(to_number(t.lsk)) into maxlsk_ from kart t where
t.reu=newreu_;
if nvl(maxlsk_,0) = 0 then
 Raise_application_error(-20001,
   'Не к чему присоединяться!');
end if;

 for c in (select t.lsk as old_lsk, t.k_lsk_id, t.c_lsk_id,
   t.flag, t.flag1, t.kul, t.nd, t.kw, fio, k_fam, k_im, k_ot, kpr, kpr_wr, kpr_ot,
   kpr_cem, kpr_s, t.opl, ppl, pldop, ki,
   t.psch, psch_dt, status, kwt,
   lodpl, bekpl, balpl, komn, et, kfg, kfot, phw, mhw,
   pgw, mgw, pel, mel, sub_nach, subsidii, sub_data,
   polis,
   sch_el, newreu_ as reu, text,
   schel_dt, eksub1, eksub2, kran, t.kran1, el, el1,
   sgku, doppl, subs_cor, subs_cur,
   x.id as house_id, t.kan_sch, period_ as mg1, period_ as mg2, t.fk_tp
        from kart t,
   kmp_houses x where 
    exists (select * from work_houses c where c.id=t.house_id and c.newreu = newreu_)
      and t.house_id=x.old_id
    and exists (select * from kmp_lsk m where t.lsk=m.lsk)
    order by t.kul, t.nd, t.kw)
 loop
  --получить новый, уникальный лс
  maxlsk_:=p_houses.find_unq_lsk(newreu_, null);
  insert into c_lsk (id)
   values (c_lsk_id.nextval);

  insert into kart
   (k_lsk_id, c_lsk_id, lsk, flag, flag1, kul, nd, kw, fio, k_fam, k_im, k_ot, kpr, kpr_wr, kpr_ot, kpr_cem, kpr_s, opl,
   ppl, pldop, ki, psch, psch_dt,  status, kwt,
   lodpl, bekpl, balpl, komn,  et,
   kfg, kfot, phw, mhw, pgw, mgw, pel, mel,
   sub_nach, subsidii, sub_data,
   polis,
   reu, text,
    schel_dt, eksub1, eksub2, kran, kran1, el,
    el1, sgku, doppl, subs_cor, subs_cur, house_id, kan_sch, mg1, mg2, fk_tp)
  values
   (c.k_lsk_id, c_lsk_id.currval, lpad(to_char(maxlsk_),8,'0'), c.flag, c.flag1, c.kul, c.nd, c.kw,
   c.fio, c.k_fam, c.k_im, c.k_ot, c.kpr, c.kpr_wr, c.kpr_ot, c.kpr_cem, c.kpr_s, c.opl,
   c.ppl, c.pldop, c.ki, c.psch, c.psch_dt, c. status, c.kwt,
   c.lodpl, c.bekpl, c.balpl, c.komn, c.et,
   c.kfg, c.kfot, c.phw, c.mhw, c.pgw, c.mgw, c.pel, c.mel,
   c.sub_nach, c.subsidii, c.sub_data,
   c.polis,
   newreu_, c.text,
   c.schel_dt, c.eksub1, c.eksub2, c.kran, c.kran1, c.el,
    c.el1, c.sgku, c.doppl, c.subs_cor, c.subs_cur, c.house_id, c.kan_sch, c.mg1, c.mg2, c.fk_tp);

   --переносим действующие статусы счетов в новые счета...
   insert into c_states_sch
     (lsk, fk_status, dt1, dt2)
   select lpad(to_char(maxlsk_),8,'0'), t.fk_status, t.dt1, t.dt2
   from c_states_sch t
   where t.lsk=c.old_lsk;

--проживающие
for t in (
  select id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n, dok_d, dok_v,
  dat_prop, dat_ub, relat_id, old_id, status_dat, status_chng, k_fam,
  k_im, k_ot, fk_doc_tp, fk_nac, b_place, fk_frm_cntr, fk_frm_regn,
  fk_frm_distr, frm_town, frm_dat, fk_frm_kul, frm_nd, frm_kw, w_place,
  fk_ub, fk_to_cntr, fk_to_regn, fk_to_distr, to_town, fk_to_kul, to_nd,
  to_kw, fk_citiz, fk_milit, fk_milit_regn
    from c_kart_pr p where p.lsk=c.old_lsk)
loop
insert into c_kart_pr
  (id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n, dok_d,
  dok_v, dat_prop, dat_ub, relat_id, old_id, status_dat,
  status_chng, k_fam, k_im, k_ot, fk_doc_tp, fk_nac, b_place,
  fk_frm_cntr, fk_frm_regn, fk_frm_distr, frm_town, frm_dat,
  fk_frm_kul, frm_nd, frm_kw, w_place, fk_ub, fk_to_cntr,
  fk_to_regn, fk_to_distr, to_town, fk_to_kul, to_nd, to_kw,
  fk_citiz, fk_milit, fk_milit_regn)
values
  (kart_pr_id.nextval, lpad(to_char(maxlsk_),8,'0'),
  t.fio, t.status, t.dat_rog, t.pol, t.dok, t.dok_c, t.dok_n, t.dok_d, t.dok_v,
  t.dat_prop, t.dat_ub, t.relat_id, t.old_id, t.status_dat, t.status_chng,
  t.k_fam, t.k_im, t.k_ot, t.fk_doc_tp, t.fk_nac, t.b_place,
  t.fk_frm_cntr, t.fk_frm_regn, t.fk_frm_distr, t.frm_town, t.frm_dat,
  t.fk_frm_kul, t.frm_nd, t.frm_kw, t.w_place, t.fk_ub, t.fk_to_cntr,
  t.fk_to_regn, t.fk_to_distr, t.to_town, t.fk_to_kul, t.to_nd, t.to_kw,
  t.fk_citiz, t.fk_milit, t.fk_milit_regn);

  --переносим ВСЕ статусы проживающего в новые счета...
  insert into c_states_pr
    (fk_status, fk_kart_pr, dt1, dt2, fk_tp)
  select p.fk_status, kart_pr_id.currval, p.dt1, p.dt2, p.fk_tp
  from c_states_pr p
  where p.fk_kart_pr=t.id;

  for d in (select c.id, c.doc, c.dat_begin, c.main, c.dat_end
   from c_lg_docs c
    where c.c_kart_pr_id=t.id)
  loop
  insert into c_lg_docs
    (id, c_kart_pr_id, doc, dat_begin, main, dat_end)
   values
   (c_lg_docs_id.nextval, kart_pr_id.currval, d.doc, d.dat_begin, d.main, d.dat_end);

  insert into c_lg_pr
    (c_lg_docs_id, spk_id, type)
   select c_lg_docs_id.currval, r.spk_id, r.type
   from c_lg_pr r
    where r.c_lg_docs_id=d.id;
  end loop;
end loop;

--теряется информация по вводам... вручную добавлять...
  insert into nabor
    (lsk, usl, org, koeff, norm)
   select lpad(to_char(maxlsk_),8,'0'), n.usl, n.org, n.koeff, n.norm from nabor n
      where n.lsk=c.old_lsk;
 end loop;

 --закрытие старого фонда
 --сохраняем старые признаки счетчиков

--  зачем флаги эти ставить? update kart k set k.flag = k.psch where exists
--   (select * from work_houses c where c.id=k.house_id and c.newreu = newreu_);

  --устанавливаем период закрытия
  update kart k set k.mg2=mg_close_ where k.mg1 < mg_ and exists
     (select * from work_houses c where c.id=k.house_id and c.newreu = newreu_);

  --для тех л.с. которые были закрытыми и которые успели побыть открытыми в тек месяце (бывает такое)
  update kart k set k.mg2=period_ where k.mg1=period_ and k.psch in (8,9) and exists
     (select * from work_houses c where c.id=k.house_id and c.newreu = newreu_);

  --psch в kart проставится здесь, в триггерах
  --удаляем движение в статусах счета
  delete from c_states_sch k
  where exists
              (select * from kart r,
              work_houses c where c.id=r.house_id and c.newreu = newreu_
              and r.lsk=k.lsk);

   --устанавливаем новый "закрытый" статус счета
   insert into c_states_sch
     (lsk, fk_status, dt1, dt2)
   select k.lsk, 8, to_date(period_||'01','YYYYMMDD'), null
   from kart k
   where exists
   (select * from kart r,
              work_houses c where c.id=r.house_id and c.newreu = newreu_
              and r.lsk=k.lsk);

commit;

--снятие флага переноса
c_charges.scr_flag_:=0;

*/
null;
end create_uk_new_SPECIAL;


--например для переброски домов
procedure swap_sal2 is
l_mg params.period%type;
l_mg1 params.period%type;
l_mg2 params.period%type;
l_dt date;
l_user number;
l_cd_tp c_change_docs.cd_tp%type;
l_fk_doc number;
l_usl usl.usl%type;

--орг. источник - назначение
l_src number;
l_dst number;
begin
  
l_mg1:='201412';
l_mg2:='201504';
l_mg:='201505';

l_dt:=gdt(31,5,15);
l_cd_tp:='SWPSAL';

l_usl:='033';
l_src:=801;
l_dst:=801;


select t.id into l_user
  from t_user t where t.cd='SCOTT';

delete from t_corrects_payments t where t.mg=l_mg 
 and exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd_tp);
delete from c_change t where
  exists (select * from c_change_docs d where d.id=t.doc_id and
  d.cd_tp=l_cd_tp);

delete from c_change_docs t where t.cd_tp=l_cd_tp;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (l_mg, l_dt, sysdate, l_user, l_cd_tp)
  returning id into l_fk_doc;


for c in (select * from kart k where k.house_id in (
    5502, 10321, 4739, 3613, 3956, 10322, 3966, 5968, 5977, 5978, 5980, 3930, 4331, 3753, 3770, 
     3755, 3759, 3765, 3754, 3771, 4300, 4296, 4402, 6761, 6762, 6763, 6764, 5081, 4299, 3774, 
     3766, 4298, 4301, 5083, 4295, 4294, 4401, 5883, 5882, 3937,  10328, 3938, 6923, 6924, 3618, 
     3987, 3984, 4867, 10661, 10345, 6921, 3589, 3614, 3612, 10323, 10324, 3953, 3590, 3609, 3965, 
     5996, 5997, 6922, 3586, 3621, 3611, 3588, 3967, 6005, 6002, 10325, 3595, 3940, 10327, 3941, 
     10326, 3958, 3581, 3615, 3585, 3979, 3968, 3591, 3954, 3606, 3622, 3946, 6361, 6421, 4692,4693,
     4694,4690,4696,4691,4697,3540,4275,3530,4701,3531,3541,3537,7021,3539,10262,10261,
      3796,3808,4276,3535,4272,4266,4262,4244,4245,4703,4247,3536,3542,4722,3456,4248,4706,10201,
      3817,10642,3474,3487,10144,10143,4267,6904,3457,3458,3471,3485,4283,10145,10146,3472,10148,
      10147,3463,3473,3464,4712,3476,4284,4713,3819,3810,3462,3797,3798,4715,4711,4699,4700,4242,
      3799,5141,4717,3543,3538,4716,4263,3466,3811,5501,3483,3465,3481,3822,3800,10142,4249,4708,
      4258,4707,6901,4259,3821,3813,3805,3814,3812,3532,3533,6902,6903,3467,3488,3816,3534,4260,
      3468,4282,4271,10641,3807,10141,3824,6241,3478,3469,4261,4265,10745, 5407, 5413, 5436, 5429, 
      5479, 5437, 4785, 5401, 5467, 5402, 5403, 5404, 5459, 5445, 5431, 5405, 5424, 5460, 5406, 
      5425, 5432, 5446, 5433, 5448, 5409, 5434, 5410, 5411, 5435, 5428, 5458, 5412, 5440, 5420, 
      5415, 5441, 5449, 5450, 5453, 5416, 5456, 5455, 5438, 5417, 5418, 5439, 5480, 5430, 5443, 
      5421, 5422, 5444, 5447, 5427, 5408, 5452, 5454, 5442, 5472, 5414, 4790, 5474, 4792, 4793, 
      4795, 4796, 4798, 4800, 4801, 4802, 5466, 5476, 4812, 5473, 4805, 5465, 5471, 5464, 4809, 
      4810, 5462, 4811, 5463, 5477, 5461, 5423, 5478, 4807, 4814, 4815, 4816, 4819, 6121, 6123, 
      6126, 6128, 6129, 10746, 4788
  )) --<-- здесь определить id домов
  loop
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
       select t.lsk, t.usl, t.org, -1*nvl(t.payment,0), l_user, l_dt, l_mg, t.mg as dopl, l_fk_doc, null as var
            from xitog3_lsk t where t.mg between l_mg1 and l_mg2
            and t.lsk=c.lsk and t.usl=l_usl
            and t.org=l_src ;
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
       select t.lsk, t.usl, l_dst as org, nvl(t.payment,0), l_user, l_dt, l_mg, t.mg as dopl, l_fk_doc, null as var
            from xitog3_lsk t where t.mg between l_mg1 and l_mg2
            and t.lsk=c.lsk and t.usl=l_usl
            and t.org=l_src;

    insert into c_change
      (lsk, usl, org, summa, mgchange, nkom, dtek, ts, user_id, doc_id, mg2)
       select t.lsk, t.usl, t.org, -1*(nvl(t.charges,0)+nvl(t.changes,0)) as summa, t.mg, '999' as nkom,
           l_dt, sysdate, l_user, l_fk_doc, t.mg
            from xitog3_lsk t where t.mg between l_mg1 and l_mg2
            and t.lsk=c.lsk and t.usl=l_usl
            and t.org=l_src;

    insert into c_change
      (lsk, usl, org, summa, mgchange, nkom, dtek, ts, user_id, doc_id, mg2)
       select t.lsk, t.usl, l_dst as org, (nvl(t.charges,0)+nvl(t.changes,0)) as summa, t.mg, '999' as nkom,
           l_dt, sysdate, l_user, l_fk_doc, t.mg
            from xitog3_lsk t where t.mg between l_mg1 and l_mg2
            and t.lsk=c.lsk and t.usl=l_usl
            and t.org=l_src;

  end loop;         

commit;
end;

--перенос оплаты, начисления с доп л.с. на доп л.с. другой компании
--с использованием xitog3_lsk!
--для отмены переброски, сделанной в марте - договорились 03.02.2016 больше не выполнять этот скрипт,
--так как приводит к массовому появлению ненужных строк!
procedure swap_sal3 is
l_mg params.period%type;
l_mg1 params.period%type;
l_mg2 params.period%type;
l_dt date;
l_user number;
l_cd_tp c_change_docs.cd_tp%type;
l_fk_doc number;
l_usl usl.usl%type;

begin
  
l_mg1:='201412';
l_mg2:='201508';
l_mg:='201509';

l_dt:=gdt(30,9,15); --дата проводки
l_cd_tp:='SWPSAL2'; --маркер проводки

l_usl:='033';


select t.id into l_user
  from t_user t where t.cd='SCOTT';

delete from t_corrects_payments t where t.mg=l_mg 
 and exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd_tp);
delete from c_change t where
  exists (select * from c_change_docs d where d.id=t.doc_id and
  d.cd_tp=l_cd_tp);

delete from c_change_docs t where t.cd_tp=l_cd_tp;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (l_mg, l_dt, sysdate, l_user, l_cd_tp)
  returning id into l_fk_doc;

for c in (select k.lsk as lsk_old, k2.lsk as lsk_new
    from kart k, kart k2, v_lsk_tp tp1, v_lsk_tp tp2
    where k.house_id in (
    10981)
    and k.k_lsk_id=k2.k_lsk_id
    and k.psch = 8 and k.fk_tp=tp1.id and tp1.cd='LSK_TP_ADDIT' --с закрытого доп.
    and k2.psch <> 8 and k2.fk_tp=tp2.id and tp2.cd='LSK_TP_ADDIT' --на открытый доп.
  ) --<-- здесь определить id домов
  loop

/*    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
       select t.lsk, t.usl, t.org, -1*nvl(t.summa,0), l_user, l_dt, l_mg, t.dopl as dopl, l_fk_doc, null as var
            from a_kwtp_day t where t.mg ='201503'
            and t.lsk in (c.lsk_old, c.lsk_new) and t.usl=l_usl
            and t.oper='99' and t.dtek=gdt(30,3,15);*/

    --оплата в архиве, кроме текущей
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
       select t.lsk, t.usl, t.org, -1*nvl(t.summa,0), l_user, l_dt, l_mg, t.dopl as dopl, l_fk_doc, null as var
            from a_kwtp_day t where t.mg between l_mg1 and l_mg2 and t.mg<>l_mg
            and t.lsk=c.lsk_old and t.usl=l_usl
            and t.oper<>'99';
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
       select c.lsk_new, t.usl, t.org as org, nvl(t.summa,0), l_user, l_dt, l_mg, t.dopl as dopl, l_fk_doc, null as var
            from a_kwtp_day t where t.mg between l_mg1 and l_mg2 and t.mg<>l_mg
            and t.lsk=c.lsk_old and t.usl=l_usl
            and t.oper<>'99';

    --текущая оплата        
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
       select t.lsk, t.usl, t.org, -1*nvl(t.summa,0), l_user, l_dt, l_mg, t.dopl as dopl, l_fk_doc, null as var
            from kwtp_day t where t.lsk=c.lsk_old and t.usl=l_usl
            and t.oper<>'99' and to_char(t.dtek,'YYYYMM')=l_mg;
    insert into t_corrects_payments
      (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
       select c.lsk_new, t.usl, t.org as org, nvl(t.summa,0), l_user, l_dt, l_mg, t.dopl as dopl, l_fk_doc, null as var
            from kwtp_day t where t.lsk=c.lsk_old and t.usl=l_usl
            and t.oper<>'99' and to_char(t.dtek,'YYYYMM')=l_mg;

    insert into c_change
      (lsk, usl, org, summa, mgchange, nkom, dtek, ts, user_id, doc_id, mg2)
       select t.lsk, t.usl, t.org, -1*(nvl(t.charges,0)) as summa, t.mg, '999' as nkom,
           l_dt, sysdate, l_user, l_fk_doc, t.mg
            from xitog3_lsk t where t.mg between l_mg1 and l_mg2
            and t.lsk=c.lsk_old and t.usl=l_usl
            ;

    insert into c_change
      (lsk, usl, org, summa, mgchange, nkom, dtek, ts, user_id, doc_id, mg2)
       select c.lsk_new, t.usl, t.org as org, (nvl(t.charges,0)) as summa, t.mg, '999' as nkom,
           l_dt, sysdate, l_user, l_fk_doc, t.mg
            from xitog3_lsk t where t.mg between l_mg1 and l_mg2
            and t.lsk=c.lsk_old and t.usl=l_usl
            ;

  end loop;         

commit;
end;

--переброска сальдо (деб и кредит) перерасчетом
procedure swap_sal4 is
  mgchange_ c_change.mgchange%type;
  comment_ c_change_docs.text%type;
  mg_ params.period%type;
  user_id_ number;
  cd_ c_change_docs.text%type;
  l_id number;
begin

--период, которым провести изменения
mgchange_:='201701';
--период, сальдо по которому смотрим переплату
mg_:='201701';
--комментарий
comment_:='Переброска кред/деб сальдо на УК ';
--Уникальный номер переброски
cd_:='20170110';

select t.id into user_id_ from t_user t where t.cd='SCOTT';
select changes_id.nextval into l_id from dual;

delete from c_change t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.doc_id);
delete from c_change_docs t where t.user_id=user_id_ and t.text=cd_;

insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
select l_id as id, mgchange_, trunc(sysdate), sysdate, user_id_, cd_
 from dual;

--перенос сальдо с УК на Новый УК ИЗМЕНЕНИЯМИ!!!
for c in (select k.lsk, k1.lsk as newlsk, s2.usl, s2.org, s2.summa as summa,
     mgchange_ as mgchange
     from (select lsk, sum(summa) as summa from saldo_usl where
      mg=mg_
      group by lsk) s,(select usl, org, lsk, sum(summa) as summa from saldo_usl where
      mg=mg_
      group by usl, org, lsk) s2, kart k, kart k1, v_lsk_tp tp
    where --k.house_id in (5004,5503,6701,10381,6885,5764,5142,6681)
    k.reu in ('22')
    and k1.reu in ('85')
    and k.fk_tp=tp.id
    and k1.fk_tp=tp.id
    and tp.cd='LSK_TP_ADDIT'
    and k.lsk=s.lsk
    and k.lsk=s2.lsk
    and k.k_lsk_id=k1.k_lsk_id
    and k.fk_tp=k1.fk_tp
    and k1.psch <> 8
    and s.summa <> 0
    order by k1.lsk)
loop

--по старым л.с.
insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
user_id, doc_id)
select c.lsk, c.usl, c.org, -1*c.summa as summa,
 c.mgchange, 1, trunc(sysdate), sysdate, user_id_, l_id
 from dual;

--по новым л.с.
insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
user_id, doc_id)
select c.newlsk, c.usl, c.org, c.summa as summa,
 c.mgchange, 1, trunc(sysdate), sysdate, user_id_, l_id
 from dual;

end loop;
commit;

end swap_sal4;


--снятие сальдо "в никуда", предварительно сформировать сальдо!
procedure swap_sal_TO_NOTHING is
  mgchange_ c_change.mgchange%type;
  comment_ c_change_docs.text%type;
  l_mg params.period%type;
  l_mg_sal params.period%type;
  l_mg_back params.period%type;
  user_id_ number;
  cd_ c_change_docs.text%type;
  l_id number;
  l_dt date;
begin  
--период, которым провести изменения
mgchange_:='201910';
--период, по которому смотрим сальдо
l_mg_sal:='201910';
--текущий месяц
l_mg:='201910';
--месяц назад
l_mg_back:='201909';
--дата, которой провести
l_dt:=to_date('20191001','YYYYMMDD');
--комментарий
comment_:='Снятие сальдо и пени по выборочным лиц счетам';
--Уникальный id переброски
cd_:='swp_sal_nothing_201910_1';

select t.id into user_id_ from t_user t where t.cd='SCOTT';
select changes_id.nextval into l_id from dual;

delete from c_change t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.doc_id);
 
delete from t_corrects_payments t where t.user_id=user_id_
 and exists (select * from
 c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.fk_doc);

delete from c_pen_corr t where 
 exists (select * from
   c_change_docs d where d.user_id=user_id_ and d.text=cd_ and d.id=t.fk_doc);

delete from c_change_docs t where t.user_id=user_id_ and t.text=cd_;


insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
select l_id as id, mgchange_, trunc(sysdate), sysdate, user_id_, cd_
 from dual;

insert into c_pen_corr
  (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
select s.lsk, s.penya*-1, s.mg1, l_dt, sysdate, user_id_, l_id
 from a_penya s, kart k where
   s.lsk=k.lsk --and k.lsk in (select lsk from kmp_lsk)
    and k.reu='066'
    and s.mg=l_mg_back; 

insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
user_id, doc_id)
select s.lsk, s.usl, s.org, -1*s.summa as summa,
 mgchange_, 1, l_dt, sysdate, user_id_, l_id
 from saldo_usl s, kart k where
   s.lsk=k.lsk and k.lsk in (select lsk from kmp_lsk)
   and s.mg=l_mg_sal;

/*insert into t_corrects_payments
  (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc)
select s.lsk, s.usl, s.org, s.summa as summa, user_id_, l_dt, 
 mgchange_, mgchange_, l_id
 from saldo_usl_script s, kart k where
   s.lsk=k.lsk --and k.lsk in (select lsk from kmp_lsk)
   and k.reu='036'
   and s.mg=l_mg_sal;
*/
commit;

end swap_sal_TO_NOTHING;



--переброска сальдо, с распределением дебетового по периодам задолжности
procedure swap_sal_chpay is
 l_mg params.period%type;
 l_mg2 params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
begin

--ПРОЦЕДУРА ВРЕМЕННО НЕ ИСПОЛЬЗУЕТСЯ (передумал применять!)
Raise_application_error(-20000, 'ПРОЦЕДУРА ВРЕМЕННО НЕ ИСПОЛЬЗУЕТСЯ');
  l_mg:='201505'; --тек.период
  l_mg2:=utils.add_months_pr(l_mg,-1); --месяц назад
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед
  l_cd:='swap_sal_chpay';
  l_mgchange:=l_mg;
  l_dt:=to_date('20150531','YYYYMMDD');

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from c_change t where t.user_id=l_user
   and exists (select * from
  c_change_docs d where d.user_id=l_user and d.text=l_cd and d.id=t.doc_id);
   delete from c_change_docs t where t.user_id=l_user and t.text=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;
 
 for c in (select k.lsk as lsk_old, k2.lsk as lsk_new from kart k
    join kart k2 on k.lsk='12012885' and k.k_lsk_id=k2.k_lsk_id and k.reu='12' and k2.reu='86'
      and k2.psch not in (8,9)
    join v_lsk_tp tp on k.fk_tp=k2.fk_tp and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
                  ) 
 loop
    
  delete from temp_prep;
  insert into temp_prep
  (usl, org, summa, tp_cd)
  select t.usl, t.org, -1*t.summa, 0 as tp_cd
     from saldo_usl t where t.mg=l_mg
     and t.lsk=c.lsk_old and t.summa>0; --дебет.сальдо

/*  insert into temp_prep
  (mg, summa, tp_cd)
  select t.mg, sum(decode(t.type,0,t.summa,-1*t.summa)) as summa, 0 as tp_cd
     from c_chargepay t where t.period='201503'
     and t.lsk=c.lsk_old
     group by t.mg
     having sum(decode(t.type,0,t.summa,-1*t.summa))>0;*/

  insert into temp_prep
  (mg, summa, tp_cd)
  select a.mg, sum(summa), a.tp_cd from (
  select t.mg1 as mg, summa, 0 as tp_cd from a_penya t 
   where t.lsk=c.lsk_old
   and t.mg=l_mg--l_mg2
   union all
  select l_mg, -1*t.summa, 0 as tp_cd --убрать кредит сальдо, чтоб перенести потом отдельно
     from saldo_usl t where t.mg=l_mg3
     and t.lsk=c.lsk_old and t.summa<0) a
     group by a.mg, a.tp_cd
     having sum(summa)>0;  

  --закрываем суммы сальдо
  c_prep.dist_summa2;
 
  --по старым л.с. - снятие
  insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
  user_id, doc_id)
  select c.lsk_old, t.usl, t.org, sum(t.summa), t.mg, 1 as type, l_dt,
   sysdate, l_user, l_id from temp_prep t where t.tp_cd in (3,4)
  group by t.mg, t.org, t.usl
  having sum(t.summa)<0; 

  --по новым л.с. - установка
  insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
  user_id, doc_id)
  select c.lsk_new, t.usl, t.org, -1*sum(t.summa), t.mg, 1 as type, l_dt,
   sysdate, l_user, l_id from temp_prep t where t.tp_cd in (3,4)
  group by t.mg, t.org, t.usl
  having sum(t.summa)<0; 
  
  --кредитовое сальдо - только в текущий период
  
  --по старым л.с. - снятие
  insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
    user_id, doc_id)
  select c.lsk_old, t.usl, t.org, -1*t.summa, l_mg, 1 as type, l_dt,
     sysdate, l_user, l_id 
     from saldo_usl t where t.mg=l_mg3--l_mg
     and t.lsk=c.lsk_old and t.summa<0; --кредит.сальдо
  
  --по новым л.с. - установка
  insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
    user_id, doc_id)
  select c.lsk_new, t.usl, t.org, t.summa, l_mg, 1 as type, l_dt,
     sysdate, l_user, l_id 
     from saldo_usl t where t.mg=l_mg3--l_mg
     and t.lsk=c.lsk_old and t.summa<0; --кредит.сальдо
 end loop;
 
commit; 
end swap_sal_chpay;


--Переброска всего итогового сальдо (исх.на текущий период) на новый УК
--ВНИМАНИЕ! Обязательно сформировать оборотку ДО
procedure swap_sal_chpay2 is
 l_mg params.period%type;
 l_mg2 params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
begin
  l_mg:='201701'; --тек.период
  l_mg2:=utils.add_months_pr(l_mg,-1); --месяц назад
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед
  l_cd:='swap_sal_chpay-20170131';
  l_mgchange:=l_mg;
  l_dt:=to_date('20170131','YYYYMMDD');

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from c_change t where t.user_id=l_user
   and exists (select * from
  c_change_docs d where d.user_id=l_user and d.text=l_cd and d.id=t.doc_id);
   delete from c_change_docs t where t.user_id=l_user and t.text=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;
 
 for c in (select k.lsk as lsk_old, k2.lsk as lsk_new from kart k
    join kart k2 on k.k_lsk_id=k2.k_lsk_id and k.reu in ('12','41') and k2.reu in ('86','85')
      and k2.psch not in (8,9)
    join v_lsk_tp tp on k.fk_tp=k2.fk_tp and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
                  ) 
 loop
    
  --по старым л.с. - снятие
  insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
    user_id, doc_id)
  select c.lsk_old, t.usl, t.org, -1*t.summa, l_mg, 1 as type, l_dt,
     sysdate, l_user, l_id 
     from saldo_usl t where t.mg=l_mg3--l_mg
     and t.lsk=c.lsk_old
     and t.usl in ('003','004','035','036','019','047'); 
  
  --по новым л.с. - установка
  insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
    user_id, doc_id)
  select c.lsk_new, t.usl, t.org, t.summa, l_mg, 1 as type, l_dt,
     sysdate, l_user, l_id 
     from saldo_usl t where t.mg=l_mg3--l_mg
     and t.lsk=c.lsk_old 
     and t.usl in ('003','004','035','036','019','047'); 
 end loop;
 
commit; 
end swap_sal_chpay2;

--Переброска всего выборочного итогового сальдо (исх.на текущий период) на новый УК по определенной услуге!
--ВНИМАНИЕ! Обязательно сформировать оборотку ДО
procedure swap_sal_chpay3 is
 l_mg params.period%type;
 l_mg2 params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
begin
  l_mg:='201506'; --тек.период
  l_mg2:=utils.add_months_pr(l_mg,-1); --месяц назад
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед
  l_cd:='swap_sal_chpay2';
  l_mgchange:=l_mg;
  l_dt:=to_date('20150630','YYYYMMDD');

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from c_change t where t.user_id=l_user
   and exists (select * from
  c_change_docs d where d.user_id=l_user and d.text=l_cd and d.id=t.doc_id);
   delete from c_change_docs t where t.user_id=l_user and t.text=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;
 
 for c in (select k.lsk as lsk_old, k2.lsk as lsk_new from kart k
    join kart k2 on k.k_lsk_id=k2.k_lsk_id and k.reu in ('12','41') and k2.reu in ('86','85')
      and k2.psch not in (8,9)
    join v_lsk_tp tp on k.fk_tp=k2.fk_tp and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
    join (select * from saldo_usl s where s.mg=l_mg3 and s.usl='033' and s.summa<0
                 and exists (select s2.lsk, sum(s2.summa) from saldo_usl s2 where s2.lsk=s.lsk and s2.mg=s.mg
                              group by s2.lsk
                              having sum(s2.summa)<0) --если кредитовое сальдо по капрем, а так же кредитовое вообще по всему счету
                                                      --то - перенести
                  ) a on k.lsk=a.lsk)
 loop
    
  --по старым л.с. - снятие
  insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
    user_id, doc_id)
  select c.lsk_old, t.usl, t.org, -1*t.summa, l_mg, 1 as type, l_dt,
     sysdate, l_user, l_id 
     from saldo_usl t where t.mg=l_mg3--l_mg
     and t.lsk=c.lsk_old
     and t.usl in ('033','034');
  
  --по новым л.с. - установка
  insert into c_change (lsk, usl, org, summa, mgchange, type, dtek, ts,
    user_id, doc_id)
  select c.lsk_new, t.usl, t.org, t.summa, l_mg, 1 as type, l_dt,
     sysdate, l_user, l_id 
     from saldo_usl t where t.mg=l_mg3--l_mg
     and t.lsk=c.lsk_old
     and t.usl in ('033','034');
 end loop;
 
commit; 
end swap_sal_chpay3;


-- перенос лиц.счетов и сальдо
-- описание здесь https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
procedure CREATE_UK_NEW2(p_reu_dst          in kart.reu%type, -- код УК назначения (вместо бывшего new_reu_), если не заполнен, то возьмется из лиц.счета источника
                         p_reu_src          in varchar2, -- код УК источника (если не заполнено, то любое) Заполняется если переносятся ЛС из РСО в другую РСО
                         p_lsk_tp_src       in varchar2, -- С какого типа счетов перенос, если не указано - будет взято по наличию p_remove_nabor_usl
                         p_house_src        in varchar2, -- House_id через запятую, например '3256,5656,7778,'
                         p_get_all          in number, -- признак какие брать лс (1 - все лс, в т.ч. закрытые, 0-только открытые)
                         p_close_src        in number, -- закрывать лс. источника (mg2='999999') 1-да,0-нет,2-закрывать только если не ОСНОВНОЙ счет
                         p_close_dst        in number, -- закрывать лс. назначения (mg2='999999') 1-да,0-нет
                         p_move_resident    in number, -- переносить проживающих? 1-да,0-нет
                         p_forced_status    in number, -- установить новый статус счета (0-открытый, NULL - такой же как был в счете источника)
                         p_forced_tp        in varchar2, -- установить новый тип счета (NULL-взять из источника, например 'LSK_TP_RSO' - РСО)
                         p_tp_sal           in number, --признак как переносить сальдо 0-не переносить, 2 - переносить и дебет и кредит, 1-только дебет, 3 - только кредит
                         p_special_tp       in varchar2, -- создать дополнительный лиц.счет в добавок к вновь созданному (NULL- не создавать, 'LSK_TP_ADDIT' - капремонт)
                         p_special_reu      in varchar2, -- УК дополнительного лиц.счета
                         p_mg_sal           in c_change.mgchange%type, -- период сальдо
                         p_remove_nabor_usl in varchar2 default null, -- переместить данные услуги (задавать как '033,034,035)
                         p_forced_usl       in varchar2 default null, -- установить данную услугу в назначении (если не указано, взять из источника)
                         p_forced_org       in number default null, -- установить организацию в наборе назначения (null - брать из источника)
                         p_mg_pen           in c_change.mgchange%type, -- период по которому перенести пеню. null - не переносить (обычно месяц назад)
                         p_move_meter       in number default 0,-- перемещать показания счетчиков (Обычно Полыс) 1-да,0-нет - при перемещении на РСО - не надо включать
                         p_cpn              in number default 0-- начислять пеню в новых лиц счетах? (0, null, -да, 1 - нет)
                         ) is
  maxlsk_     number;
  comment_    c_change_docs.text%type;
  mg_         params.period%type;
  mg_close_   params.period%type;
  period_     params.period%type;
  user_id_    number;
  changes_id_ c_change_docs.id%type;
  cnt_        number;
  l_tp_sal    number;
  l_par       number;
  l_id        number;
  l_cd_tp     varchar2(256);
  -- дата переброски сальдо, для корректировок
  l_dt        date;
  l_lsk_new   kart.lsk%type;
  l_ret       number;
  l_forced_tp number;
  l_flag      number;
  i           number;
begin
  --признак как переносить сальдо
  --0-не переносить, 2 - переносить и дебет и кредит,
  --1-только дебет
  l_tp_sal := nvl(p_tp_sal, 0);
  -- дата переброски сальдо, для корректировок
  l_dt := gdt(30, 0, 0);
  select period into period_ from params p;
  select period3 into mg_close_ from v_params;
  --установка флага переноса, т.е. записи инсертятся через скрипт переноса домов
  c_charges.scr_flag_ := 1;

  if l_tp_sal in (1, 2, 3) then
    --если требуется перенести 1- дебетовое (или 2-всё) сальдо
  
    --период, сальдо по которому смотрим переплату
    select p.period into mg_ from params p;
    --комментарий
    comment_ := 'Переброска Cальдо на УК=' || nvl(p_reu_dst,' взять из источника');
    l_cd_tp  := 'TRANSF_28112018_1';
    --Уникальный номер переброски
    select changes_id.nextval into changes_id_ from dual;
  
    select t.id into user_id_ from t_user t where t.cd = 'SCOTT';
    delete from t_corrects_payments t
     where exists (select *
              from c_change_docs t
             where t.cd_tp = l_cd_tp
               and t.id = t.fk_doc);
    delete from c_change_docs t where t.cd_tp = l_cd_tp;
  
    insert into c_change_docs
      (id, mgchange, dtek, ts, user_id, text, cd_tp)
      select changes_id_, mg_, trunc(l_dt), sysdate, user_id_, comment_, l_cd_tp
        from dual;
  end if;
  -- задать тип счета для новых лс
  l_forced_tp := null;
  if p_forced_tp is not null then
    select tp.id
      into l_forced_tp
      from v_lsk_tp tp
     where tp.cd = p_forced_tp;
  end if;

  l_flag := 0;
  i      := 0;
  for c in (select t.lsk as old_lsk, t.k_lsk_id, t.c_lsk_id, t.flag, t.flag1, t.kul, t.nd, t.kw, fio, 
    k_fam, k_im, k_ot, kpr, kpr_wr, kpr_ot, kpr_cem, kpr_s, t.opl, ppl, pldop, ki, t.psch, psch_dt, 
    status, kwt, lodpl, bekpl, balpl, komn, et, kfg, kfot, 
    decode(p_move_meter, 1, phw, null) as phw, decode(p_move_meter, 1, mhw, null) as mhw, 
    decode(p_move_meter, 1, pgw, null) as pgw, decode(p_move_meter, 1, mgw, null) as mgw, 
    decode(p_move_meter, 1, pel, null) as pel, decode(p_move_meter, 1, mel, null) as mel, 
    sub_nach, subsidii, sub_data, polis, sch_el, 
    nvl(p_reu_dst, t.reu) as reu, -- взять из источника, если не заполнено
    text, schel_dt, eksub1, eksub2, kran, t.kran1, el, el1, sgku, doppl, subs_cor, subs_cur, t.house_id, t.kan_sch, period_ as mg1,case
                     when nvl(p_close_dst, 0) = 1 then
                      period_
                     else
                      '999999'
                   end as mg2, t.fk_tp, t.entr, t.fk_pasp_org, tp.cd as tp_cd, t.fk_klsk_premise
              from kart t, v_lsk_tp tp
             where 
             case
               when nvl(p_get_all, 0) = 1 then
                0 -- или брать все
               else
                t.psch
             end not in (8, 9)
         and -- или брать только открытые
             regexp_instr(p_house_src,
                          '(^|,|;)' || t.house_id || '($|,|;)') > 0
            --and t.reu in ('084')
            --exists (select * from work_houses h where h.id=t.house_id)
            --exists (select * from kmp_lsk h where h.lsk=t.lsk)
         and t.fk_tp = tp.id and
         -- если заполнен код УК источника лиц.счетов (обычно при переносе из РСО в РСО)
         (p_reu_src is null or t.reu = p_reu_src) and 
         -- если заполнены услуги для переноса (обычно при создании лиц.счетов РСО), то искать лс, содержащие данные услуги
         (p_remove_nabor_usl is null or exists (select * from nabor n where n.lsk=t.lsk
         and regexp_instr(p_remove_nabor_usl,
             '(^|,|;)' || n.usl || '($|,|;)') > 0))

         and (p_lsk_tp_src is null or tp.cd in (p_lsk_tp_src)) -- тип лиц.счета - источника
             order by t.kul, t.nd, t.kw) loop
    i := i + 1;
    --получить новый, уникальный лс
    maxlsk_   := p_houses.find_unq_lsk(p_reu_dst, null);
    l_lsk_new := lpad(to_char(maxlsk_), 8, '0');
    insert into c_lsk (id) values (c_lsk_id.nextval);
  
    insert into kart
      (k_lsk_id, c_lsk_id, lsk, flag, flag1, kul, nd, kw, fio, k_fam, k_im, k_ot, kpr, kpr_wr, 
      kpr_ot, kpr_cem, kpr_s, opl, ppl, pldop, ki, psch, psch_dt, status, kwt, lodpl, bekpl, balpl, 
      komn, et, kfg, kfot, phw, mhw, pgw, mgw, pel, mel, sub_nach, subsidii, sub_data, polis, reu, 
      text, schel_dt, eksub1, eksub2, kran, kran1, el, el1, sgku, doppl, subs_cor, subs_cur, house_id, 
      kan_sch, mg1, mg2, fk_tp, entr, fk_pasp_org, fk_klsk_premise, cpn)
    values
      (c.k_lsk_id, c_lsk_id.currval, l_lsk_new, c.flag, c.flag1, c.kul, c.nd, c.kw, c.fio, c.k_fam, 
      c.k_im, c.k_ot, c.kpr, c.kpr_wr, c.kpr_ot, c.kpr_cem, c.kpr_s, c.opl, c.ppl, c.pldop, c.ki, 
      c.psch, c.psch_dt, c.status, c.kwt, c.lodpl, c.bekpl, c.balpl, c.komn, c.et, c.kfg, c.kfot, 
      c.phw, c.mhw, c.pgw, c.mgw, c.pel, c.mel, c.sub_nach, c.subsidii, c.sub_data, c.polis, c.reu,
       c.text, c.schel_dt, c.eksub1, c.eksub2, c.kran, c.kran1, c.el, c.el1, c.sgku, c.doppl, c.subs_cor,
        c.subs_cur, c.house_id, c.kan_sch, c.mg1, c.mg2, nvl(l_forced_tp,
            c.fk_tp), c.entr, c.fk_pasp_org, c.fk_klsk_premise, p_cpn);
    insert into kart_detail(lsk)
    values (l_lsk_new);
    --Проставить статус счета
    insert into c_states_sch
      (lsk, fk_status, dt1, dt2)
      select l_lsk_new, nvl(p_forced_status, c.psch) as fk_status, -- если статус не установлен принудительно
             init.get_dt_start, null
        from dual;
  
    -- создать лицевой счет дополнительно к новому (например специальный РСО ред. 07.08.2018)
/*    if p_special_tp is not null then
      l_ret := p_houses.kart_lsk_special_add(l_lsk_new,
                                             p_special_tp,
                                             l_lsk_new
                                             null,
                                             0,
                                             0,
                                             p_special_reu);
      if l_ret != 0 then
        Raise_application_error(-20000,
                                'Ошибка создания ДОПОЛНИТЕЛЬНОГО лиц.счета с типом:' ||
                                p_special_tp);
      end if;
    end if; */
  
    --проживающих переносим, (обычно если не переброска закрытых лиц.счетов)
    if nvl(p_move_resident, 0) = 1 then
      for t in (select id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n, dok_d, dok_v, dat_prop, dat_ub, relat_id, old_id, status_dat, status_chng, k_fam, k_im, k_ot, fk_doc_tp, fk_nac, b_place, fk_frm_cntr, fk_frm_regn, fk_frm_distr, frm_town, frm_dat, fk_frm_kul, frm_nd, frm_kw, w_place, fk_ub, fk_to_cntr, fk_to_regn, fk_to_distr, to_town, fk_to_kul, to_nd, to_kw, fk_citiz, fk_milit, fk_milit_regn
                  from c_kart_pr p
                 where p.lsk = c.old_lsk) loop
        insert into c_kart_pr
          (id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n, dok_d, dok_v, dat_prop, dat_ub, relat_id, old_id, status_dat, status_chng, k_fam, k_im, k_ot, fk_doc_tp, fk_nac, b_place, fk_frm_cntr, fk_frm_regn, fk_frm_distr, frm_town, frm_dat, fk_frm_kul, frm_nd, frm_kw, w_place, fk_ub, fk_to_cntr, fk_to_regn, fk_to_distr, to_town, fk_to_kul, to_nd, to_kw, fk_citiz, fk_milit, fk_milit_regn)
        values
          (kart_pr_id.nextval, l_lsk_new, t.fio, t.status, t.dat_rog, t.pol, t.dok, t.dok_c, t.dok_n, t.dok_d, t.dok_v, t.dat_prop, t.dat_ub, t.relat_id, t.old_id, t.status_dat, t.status_chng, t.k_fam, t.k_im, t.k_ot, t.fk_doc_tp, t.fk_nac, t.b_place, t.fk_frm_cntr, t.fk_frm_regn, t.fk_frm_distr, t.frm_town, t.frm_dat, t.fk_frm_kul, t.frm_nd, t.frm_kw, t.w_place, t.fk_ub, t.fk_to_cntr, t.fk_to_regn, t.fk_to_distr, t.to_town, t.fk_to_kul, t.to_nd, t.to_kw, t.fk_citiz, t.fk_milit, t.fk_milit_regn);
      
        --переносим ВСЕ статусы проживающего в новые счета...
        insert into c_states_pr
          (fk_status, fk_kart_pr, dt1, dt2) -- временно тут ошибка, надо в январе разобраться с полем fk_tp!
          select p.fk_status, kart_pr_id.currval, p.dt1, p.dt2
            from c_states_pr p
           where p.fk_kart_pr = t.id;
      
        for d in (select c.id, c.doc, c.dat_begin, c.main, c.dat_end
                    from c_lg_docs c
                   where c.c_kart_pr_id = t.id) loop
          insert into c_lg_docs
            (id, c_kart_pr_id, doc, dat_begin, main, dat_end)
          values
            (c_lg_docs_id.nextval, kart_pr_id.currval, d.doc, d.dat_begin, d.main, d.dat_end);
        
          insert into c_lg_pr
            (c_lg_docs_id, spk_id, type)
            select c_lg_docs_id.currval, r.spk_id, r.type
              from c_lg_pr r
             where r.c_lg_docs_id = d.id;
        end loop;
      end loop;
    end if;
  
    -- наборы услуг
    if p_remove_nabor_usl is not null then
      insert into nabor
        (lsk, usl, org, koeff, norm, fk_vvod)
        select l_lsk_new, nvl(p_forced_usl, n.usl) as usl, nvl(p_forced_org, n.org), n.koeff, n.norm, n.fk_vvod -- n.fk_vvod ред. 03.07.2018 странно, раньше было n.fk_vvod
          from nabor n
         where n.lsk = c.old_lsk
           and regexp_instr(p_remove_nabor_usl,
                            '(^|,|;)' || n.usl || '($|,|;)') > 0;
      -- удалить заданную услугу в ЛС - источника
      delete from nabor n
       where regexp_instr(p_remove_nabor_usl,
                          '(^|,|;)' || n.usl || '($|,|;)') > 0
         and n.lsk = c.old_lsk;
    else
      insert into nabor
        (lsk, usl, org, koeff, norm, fk_vvod)
        select l_lsk_new, n.usl, nvl(p_forced_org, n.org), n.koeff, n.norm, n.fk_vvod -- n.fk_vvod ред. 03.07.2018 странно, раньше было n.fk_vvod
          from nabor n
         where n.lsk = c.old_lsk;
    end if;
  
    if nvl(p_close_src, 0) = 1 or nvl(p_close_src, 0) = 2 and c.tp_cd <> 'LSK_TP_MAIN' then
      --закрытие старого фонда
      --сохраняем старые признаки счетчиков
    
      --устанавливаем период закрытия
      update kart k
         set k.mg2 = mg_close_
       where k.mg1 < mg_
         and k.lsk = c.old_lsk
         and k.mg2 = '999999';
    
      -- ВЫРУБИЛ НА ФИГ ЭТУ ПРОВЕРКУ последний лс на котором сработало 80000452 ред. 01.03.2018   
      --if sql%rowcount = 0 or mg_close_='999999' then
      --  Raise_application_error(-20000, 'Проверить закрытие месяца в лиц счете:'||c.old_lsk||' mg_close='||mg_close_);
      --end if;   
    
      --для тех л.с. которые успели побыть открытыми в тек месяце (бывает такое)
      update kart k
         set k.mg2 = period_
       where k.mg1 = period_ /* and k.psch in (8,9)*/
         and k.lsk = c.old_lsk
         and k.mg2 = '999999';
    
      --psch в kart проставится здесь, в триггерах
      --удаляем движение в статусах старого счета
      delete from c_states_sch k where k.lsk = c.old_lsk;
    
      --устанавливаем новый "закрытый" статус старого счета
      insert into c_states_sch
        (lsk, fk_status, dt1, dt2, fk_close_reason)
        select k.lsk, 8 as fk_status, to_date(period_ || '01', 'YYYYMMDD') as dt1, null as dt2, a.id as fk_close_reson
          from kart k
          join (select u.id, s.name
                  from exs.u_list u
                  join exs.u_list s
                    on u.id = s.parent_id
                  join exs.u_listtp t
                    on s.fk_listtp = t.id
                 where t.cd = 'GIS_NSI_22'
                   and s.s1 = 'Смена исполнителя жилищно-коммунальных услуг') a
            on 1 = 1
         where k.lsk = c.old_lsk;
    end if;
  
    -- сальдо переносим в конце!
    if l_tp_sal in (1, 2, 3) then
      -- расчет начисления и сальдо по старому лс
      cnt_ := c_charges.gen_charges(c.old_lsk, c.old_lsk, null, null, 1, 0);
      gen.gen_saldo(c.old_lsk);
    
      --если требуется перенести сальдо
      --по старым л.с.
      --снимаем сальдо
      insert into t_corrects_payments
        (lsk, usl, summa, org, user_id, dat, mg, dopl, fk_doc)
        select s.lsk, s.usl, s.summa, s.org, d.user_id, d.dtek, mg_, mg_, d.id
          from c_change_docs d, saldo_usl s, (select m.lsk, sum(summa) as summa
                   from saldo_usl m
                  where m.mg = p_mg_sal
                    and m.lsk = c.old_lsk
                       --###2 Маркер для документирования https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
                    and regexp_instr(p_remove_nabor_usl,
                                     '(^|,|;)' ||
                                     m.usl ||
                                     '($|,|;)') > 0
                  group by m.lsk) a
         where s.mg = p_mg_sal
           and s.lsk = a.lsk
           and case
                 when l_tp_sal = 1 and nvl(a.summa, 0) > 0 then
                  1 -- только дебет
                 when l_tp_sal = 3 and nvl(a.summa, 0) < 0 then
                  1 -- только кредит
                 when l_tp_sal = 2 then
                  1 -- всё сальдо
                 else
                  0
               end = 1
              --###2 Маркер для документирования https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
           and regexp_instr(p_remove_nabor_usl,
                            '(^|,|;)' || s.usl || '($|,|;)') > 0
           and d.id = changes_id_
           and s.lsk = c.old_lsk;
    
      --устанавливаем сальдо
      insert into t_corrects_payments
        (lsk, usl, summa, org, user_id, dat, mg, dopl, fk_doc)
        select l_lsk_new as lsk, s.usl, -1 * s.summa, s.org, d.user_id, d.dtek, mg_, mg_, d.id
          from c_change_docs d, saldo_usl s, (select m.lsk, sum(summa) as summa
                   from saldo_usl m
                  where m.mg = p_mg_sal
                    and m.lsk = c.old_lsk
                       --###2 Маркер для документирования https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
                    and regexp_instr(p_remove_nabor_usl,
                                     '(^|,|;)' ||
                                     m.usl ||
                                     '($|,|;)') > 0
                  group by m.lsk) a
         where s.mg = p_mg_sal
           and s.lsk = a.lsk
           and case
                 when l_tp_sal = 1 and nvl(a.summa, 0) > 0 then
                  1
                 when l_tp_sal = 3 and nvl(a.summa, 0) < 0 then
                  1
                 when l_tp_sal = 2 then
                  1
                 else
                  0
               end = 1
              --###2 Маркер для документирования https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
           and regexp_instr(p_remove_nabor_usl,
                            '(^|,|;)' || s.usl || '($|,|;)') > 0
           and d.id = changes_id_
           and s.lsk = c.old_lsk;
    
    end if;
  
    -- перенос пени
    if p_mg_pen is not null then
      -- ВЫБОРОЧНО ПО УСЛУГЕ
      --снять
      insert into c_pen_corr
        (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
        select t.lsk, -1 * t.poutsal as penya, mg_close_ as dopl, l_dt as dtek, sysdate, d.user_id, d.id as fk_doc, t.usl, t.org
          from xitog3_lsk t
          join c_change_docs d
            on d.id = changes_id_
         where t.lsk = c.old_lsk
           and t.mg = p_mg_pen
              --###2 Маркер для документирования https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
           and nvl(t.poutsal, 0) <> 0
           and regexp_instr(p_remove_nabor_usl,
                            '(^|,|;)' || t.usl || '($|,|;)') > 0;
      --поставить
      insert into c_pen_corr
        (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
        select l_lsk_new as lsk, t.poutsal as penya, mg_close_ as dopl, l_dt as dtek, sysdate, d.user_id, d.id as fk_doc, t.usl, t.org
          from xitog3_lsk t
          join c_change_docs d
            on d.id = changes_id_
         where t.lsk = c.old_lsk
           and t.mg = p_mg_pen
              --###2 Маркер для документирования https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
           and nvl(t.poutsal, 0) <> 0
           and regexp_instr(p_remove_nabor_usl,
                            '(^|,|;)' || t.usl || '($|,|;)') > 0;
    end if;
    l_flag := 1;
  end loop;

  if l_flag = 0 then
    Raise_application_error(-20000,
                            'Ошибка! Не обработано ни одной записи!');
  end if;
  --пересчет коэфф. прожив и текущего начисления по старым и новым л.с.
  /*for c in (select r.lsk from kart r,
                work_houses t where t.kul=r.kul and t.nd=r.nd and t.newreu = newreu_
                )
  loop
    cnt_:=c_charges.gen_charges(c.lsk, c.lsk, null, null, 1, 0);
  end loop;*/

  commit;

  --снятие флага переноса
  c_charges.scr_flag_ := 0;

  Raise_application_error(-20000,
                          'Перенесено ' || i || ' лицевых счетов');

end create_uk_new2;


-- перенос информации по закрытым лиц.счетам
-- задокументировано здесь: https://docs.google.com/document/d/18qo3GBuWkrtsQThg4E7P9MXYmImM0nQrhdtLdKw-mPY/edit
procedure transfer_closed_all(p_reu in kart.reu%type,  -- рэу назначения
                              p_lsk_recommend in kart.lsk%type -- рекоммендуемый лиц.счет, для начала или Null
                             ) is
l_cd c_change_docs.cd_tp%type;
begin
  l_cd:='closed_20180531_2'; 
  
  delete from c_change t where exists
  (select * from c_change_docs d where t.doc_id=d.id and d.text=l_cd);
  delete from c_change_docs t where t.text=l_cd;
  delete from c_pen_corr t where exists
  (select * from c_change_docs d where t.fk_doc=d.id and d.text=l_cd);
  --почистить (все уровни kwtp почистятся каскадом)
  delete from c_kwtp t where exists
  (select * from c_change_docs d where t.fk_doc=d.id and d.text=l_cd);

  for c in (select t.lsk from kmp_lsk t) loop
      
    transfer_closed_lsk(p_lsk => c.lsk, p_reu => p_reu, p_cd => l_cd, p_lsk_recommend => p_lsk_recommend);

  end loop;

  commit;

end;                             

--перенос информации по закрытому лиц.счету
procedure transfer_closed_lsk(p_lsk in kart.lsk%type, --лиц счет
                       p_reu in kart.reu%type, --рэу назначения
                       p_cd in varchar2, --CD
                       p_lsk_recommend in kart.lsk%type 
                       ) is
  l_mg params.period%type;
  l_mg_back params.period%type;
  l_lsk_new kart.lsk%type;
  l_kwtp_id number;
  l_kwtp_mg_id number;
  l_changes_id number;
  l_user number;
  l_dt date; --дата, которой перенести
  l_dt_stop_pen date; --дата, которой остановить начисление пени
  l_psch number;
  a number;
begin
l_dt:=to_date('20180531', 'YYYYMMDD');
l_dt_stop_pen:=to_date('20180531', 'YYYYMMDD');
  
a:=init.set_date(l_dt);
--генерить пеню по старым лс на дату переброски
c_cpenya.gen_penya(p_lsk, l_dt, 0, 0);
  
select p.period, p.period3 into l_mg, l_mg_back
  from v_params p;
--получить новый лс
l_lsk_new:=p_houses.find_unq_lsk(p_reu => p_reu, p_lsk => p_lsk_recommend);
logger.log_(null, 'transfer_closed_lsk, old lsk:'||p_lsk||' new lsk:'||l_lsk_new);

--перенести лс
insert into c_lsk (id)
 values (c_lsk_id.nextval);

for c in (select * from kart k where k.lsk=p_lsk) loop
insert into kart
 (k_lsk_id, c_lsk_id, lsk, flag, flag1, kul, nd, kw, fio, k_fam, k_im, k_ot, kpr, kpr_wr, kpr_ot, kpr_cem, kpr_s, opl,
 ppl, pldop, ki, psch, psch_dt,  status, kwt,
 lodpl, bekpl, balpl, komn,  et,
 kfg, kfot, phw, mhw, pgw, mgw, pel, mel,
 sub_nach, subsidii, sub_data,
 polis,
 reu, text,
  schel_dt, eksub1, eksub2, kran, kran1, el,
  el1, sgku, doppl, subs_cor, subs_cur, house_id, kan_sch, mg1, mg2, fk_tp)
values
 (c.k_lsk_id, c_lsk_id.currval, l_lsk_new, c.flag, c.flag1, c.kul, c.nd, c.kw,
 c.fio, c.k_fam, c.k_im, c.k_ot, 0, 0, 0, 0, 0, c.opl,
 c.ppl, c.pldop, c.ki, c.psch, c.psch_dt, c. status, c.kwt,
 c.lodpl, c.bekpl, c.balpl, c.komn, c.et,
 c.kfg, c.kfot, c.phw, c.mhw, c.pgw, c.mgw, c.pel, c.mel,
 c.sub_nach, c.subsidii, c.sub_data,
 c.polis,
 p_reu, c.text,
 c.schel_dt, c.eksub1, c.eksub2, c.kran, c.kran1, c.el,
  c.el1, c.sgku, c.doppl, c.subs_cor, c.subs_cur, c.house_id, c.kan_sch, l_mg, l_mg, c.fk_tp); --период один и тот же (так как в закрытый л.с. переносим)

 --переносим действующие статусы счетов в новые счета... - если надо
 /*insert into c_states_sch
   (lsk, fk_status, dt1, dt2)
 select l_lsk_new as lsk, t.fk_status, t.dt1, t.dt2 --to_date(period_||'01','YYYYMMDD'), null
 from c_states_sch t
 where t.lsk=p_lsk;*/
 l_psch:=c.psch;
end loop;


--Уникальный номер переброски
select changes_id.nextval into l_changes_id from dual;
select t.id into l_user from t_user t where t.cd='SCOTT';

insert into c_change_docs (id, mgchange, dtek, ts, user_id, text)
select l_changes_id, l_mg, l_dt, sysdate, l_user, p_cd
 from dual;


--перенести сальдо "как есть"
  --снять с УК
  insert into c_change
    (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id,
     doc_id)
    select t.lsk, t.usl, t.org, -1*t.summa, l_mg as mgchange, '999' as nkom, 0 as type,
     l_dt, sysdate, l_user, l_changes_id
     from saldo_usl t where t.lsk=p_lsk and t.mg=l_mg
     -- ###1
     and t.usl='026'
     ;
     
  --поставить на новый лс в УК
  insert into c_change
    (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id,
     doc_id)
    select l_lsk_new, t.usl, t.org, t.summa, l_mg as mgchange, '999' as nkom, 0 as type,
     l_dt, sysdate, l_user, l_changes_id
     from saldo_usl t where t.lsk=p_lsk and t.mg=l_mg
     -- ###1
     and t.usl='026'
     ;

  -- остановить начисление пени по старому лс - иногда включают
/*  update kart k set k.pn_dt=l_dt_stop_pen
         where k.lsk=p_lsk and k.pn_dt is null;
*/
--перенести сальдо с распределением
--подготовить для перерасчета перенос сальдо
/*c_prep.dist_summa3(p_lsk => p_lsk,
                   p_mg => l_mg,
                   p_mg_back => l_mg_back);
                     
--снимаем сальдо
insert into c_change
 (lsk, usl, summa, mgchange, mg2, nkom, org, type, dtek, ts, user_id, doc_id)
select p_lsk as lsk, s.usl, -1*s.summa, s.mg as mgchange, s.mg as mg2, '999', s.org, 0, d.dtek,
 sysdate, d.user_id, d.id
 from c_change_docs d, temp_prep s
  where d.id=l_changes_id;

--устанавливаем сальдо
insert into c_change
 (lsk, usl, summa, mgchange, mg2, nkom, org, type, dtek, ts, user_id, doc_id)
select l_lsk_new as lsk, s.usl, s.summa,
 s.mg as mgchange, s.mg as mg2, '999', s.org, 0, d.dtek, sysdate, d.user_id, d.id
 from c_change_docs d, temp_prep s
 where d.id=l_changes_id;
*/
--перенести вх.сальдо по пене

-- ###1
-- ВЫБОРОЧНО ПО УСЛУГЕ
--снять
insert into c_pen_corr
  (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
select t.lsk, -1*t.poutsal as penya, l_mg_back as dopl, l_dt as dtek, sysdate, l_user, l_changes_id as fk_doc
  from xitog3_lsk t where t.lsk=p_lsk and t.mg=l_mg_back
  and nvl(t.poutsal,0)<>0 and t.usl='026';
  
--поставить
insert into c_pen_corr
  (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
select l_lsk_new as lsk, t.poutsal as penya, l_mg_back as dopl, l_dt as dtek, sysdate, l_user, l_changes_id as fk_doc
  from xitog3_lsk t where t.lsk=p_lsk and t.mg=l_mg_back
  and nvl(t.poutsal,0)<>0 and t.usl='026';
  
  
/*
-- ###2
-- ОБЩЕЕ САЛЬДО
--снять
insert into c_pen_corr
  (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
select t.lsk, -1*t.penya, t.mg1, l_dt as dtek, sysdate, l_user, l_changes_id as fk_doc
  from a_penya t where t.lsk=p_lsk and t.mg=l_mg_back;
  
--поставить
insert into c_pen_corr
  (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
select l_lsk_new as lsk, t.penya, t.mg1, l_dt as dtek, sysdate, l_user, l_changes_id as fk_doc
  from a_penya t where t.lsk=p_lsk and t.mg=l_mg_back;
*/

--наборы
/*insert into nabor
  (lsk, usl, org, koeff, norm)
 select l_lsk_new as lsk, n.usl, n.org, n.koeff, n.norm from nabor n
    where n.lsk=p_lsk;
*/

--перенести оплату и оплату пени (всё что принято в тек.месяце)

/*for c in (select t.* from c_kwtp t where t.lsk=p_lsk) loop

  --старый лс-снимаем
  select c_kwtp_id.nextval into l_kwtp_id from dual;
  insert into c_kwtp
    (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, id, iscorrect, num_doc, dat_doc)
  values
    (c.lsk, -1*c.summa, -1*c.penya, c.oper, c.dopl, c.nink, '999', 
     c.dtek, c.nkvit, c.dat_ink, sysdate, l_kwtp_id, c.iscorrect, c.num_doc, c.dat_doc);

  for c2 in (select t.* from c_kwtp_mg t where t.c_kwtp_id=c.id) loop

    select c_kwtp_mg_id.nextval into l_kwtp_mg_id from dual;
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, c_kwtp_id, cnt_sch, cnt_sch0, id, is_dist)
    values
      (c2.lsk, -1*c2.summa, -1*c2.penya, c2.oper, c2.dopl, c2.nink, '999', 
       c2.dtek, c2.nkvit, c2.dat_ink, sysdate, l_kwtp_id, 
       c2.cnt_sch, c2.cnt_sch0, l_kwtp_mg_id, 1);

    insert into kwtp_day
      (kwtp_id, summa, lsk, oper, dopl, nkom, nink, dat_ink, priznak, usl, org, fk_distr, sum_distr, dtek)
    select l_kwtp_mg_id, -1*summa, lsk, oper, dopl, '999' as nkom, nink, dat_ink, priznak, usl, org, fk_distr, sum_distr, dtek
      from kwtp_day t where t.kwtp_id=c2.id; 

  end loop;

  --новый лс-ставим
  select c_kwtp_id.nextval into l_kwtp_id from dual;
  insert into c_kwtp
    (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, id, iscorrect, num_doc, dat_doc)
  values
    (l_lsk_new, c.summa, c.penya, c.oper, c.dopl, c.nink, '999', 
     c.dtek, c.nkvit, c.dat_ink, sysdate, l_kwtp_id, c.iscorrect, c.num_doc, c.dat_doc);

  for c2 in (select t.* from c_kwtp_mg t where t.c_kwtp_id=c.id) loop

    select c_kwtp_mg_id.nextval into l_kwtp_mg_id from dual;
    insert into c_kwtp_mg
      (lsk, summa, penya, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, c_kwtp_id, cnt_sch, cnt_sch0, id, is_dist)
    values
      (l_lsk_new, c2.summa, c2.penya, c2.oper, c2.dopl, c2.nink, '999', 
       c2.dtek, c2.nkvit, c2.dat_ink, sysdate, l_kwtp_id, 
       c2.cnt_sch, c2.cnt_sch0, l_kwtp_mg_id, 1);

    insert into kwtp_day
      (kwtp_id, summa, lsk, oper, dopl, nkom, nink, dat_ink, priznak, usl, org, fk_distr, sum_distr, dtek)
    select l_kwtp_mg_id, summa, l_lsk_new, oper, dopl, '999' as nkom, nink, dat_ink, priznak, usl, org, fk_distr, sum_distr, dtek
      from kwtp_day t where t.kwtp_id=c2.id; 

  end loop;

end loop;
*/

end;

--перебросить сальдо с одной группы орг (кредитовое) на другую
--Полысаево! Рабочая процедура!
procedure swap_sal_chpay4 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201710'; --тек.период
  l_cd:='swap_sal_chpay4_20171009';
  l_mgchange:=l_mg;
  l_dt:=to_date('20171009','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед

  dbms_output.enable;

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

--  delete from c_change t where t.user_id=l_user
--   and exists (select * from
--  c_change_docs d where d.user_id=l_user and d.text=l_cd and d.id=t.doc_id);
  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  for c in (select s.lsk, s.usl, s.org, s.summa, s.mg, u2.uslm
         from saldo_usl s join usl u2
        on s.summa < 0 and s.mg=l_mg3 and s.usl=u2.usl
        --and s.org in (677, 7,9,10,19,20) --по этим орг
        and s.usl in ('004','046','034')
        and exists
        (select t.*
         from saldo_usl t, usl u --в рамках тех же услуг, других орг.
         where t.mg=s.mg and t.lsk=s.lsk
          and s.org=t.org and t.usl<>u.usl and u.uslm=u2.uslm
          and t.summa > 0
        )
        --where s.lsk='02002310'
        )
  loop

  --абс.величина кредит сальдо
  l_kr:=abs(c.summa);

  --сформировать сальдо
  gen.gen_saldo(c.lsk);

  --найти абс деб сальдо
  select abs(nvl(sum(t.summa),0)) into l_deb
         from saldo_usl t, usl u
         where t.mg=c.mg and t.lsk=c.lsk
          and t.org = c.org and t.usl<>u.usl
          and u.uslm=c.uslm
          --and t.org not in (677, 7,9,10,19,20) --не по этим орг
          and t.summa > 0;
  --ограничить сумму по дебет.сальдо
  if l_kr >= l_deb then
    l_kr:=l_deb;
  end if;

  --выполнить перенос кредит. сальдо,
  --в рамках тех же услуг, но на другие, дебетовые орг.
  select rec_summ(t.usl, t.org, t.summa, 0)
         bulk collect into t_summ
         from saldo_usl t, usl u
         where t.mg=c.mg and t.lsk=c.lsk
          and t.org = c.org and t.usl<>u.usl
          and u.uslm=c.uslm
          --and t.org not in (677, 7,9,10,19,20) --не по этим орг
          and t.summa > 0;

  if t_summ.count > 0 then
    l_ret:=c_prep.dist_summa_full(p_sum => l_kr, t_summ => t_summ);
    for c2 in (select * from table(t_summ) t where t.tp=1)
    loop
      --снять с кредита
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c.usl, c.org, -1*c2.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from dual;

      --поставить на дебет
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c2.fk_cd, c2.fk_id, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from dual;
    end loop;
  else
    dbms_output.put_line('не найден дебет по л.с.'||c.lsk);
  end if;
  end loop;
commit;
end swap_sal_chpay4;

--перебросить сальдо с одной группы орг (кредитовое) на другую
procedure swap_sal_chpay5 is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
begin
  l_mg:='201808'; --тек.период
  l_cd:='swap_sal_chpay5_20180831';
  l_mgchange:=l_mg;
  l_dt:=to_date('20180831','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед

  dbms_output.enable;

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

--  delete from c_change t where t.user_id=l_user
--   and exists (select * from
--  c_change_docs d where d.user_id=l_user and d.text=l_cd and d.id=t.doc_id);

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);
  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;



  for c in (select t.lsk, t.usl, t.org, sum(summa) as summa from saldo_usl_script t where t.mg='201809'
                  and t.usl in ('093','095') and t.summa<0
                  group by t.lsk, t.usl, t.org
        )
  loop

      --поставить на дебет (на текущую орг в лиц.сч.)
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, n.usl, n.org, -1*c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from nabor n
            where n.lsk=c.lsk and n.usl=decode(c.usl, '093', '011', '095', '015', null);
      if sql%rowcount  =1 then
      --снять с кредита, если поставилось на дебет
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c.usl, c.org, c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from dual;
      end if;
              
           
  end loop;
commit;
end swap_sal_chpay5;

end scripts;
/


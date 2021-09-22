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


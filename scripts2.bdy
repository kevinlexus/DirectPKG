create or replace package body scott.scripts2 is
--НОВЫЕ СКРИПТЫ!

--перебросить сальдо с одной группы орг (кредитовое) на другую
procedure swap_sal_chpay6 is
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
  l_mg:='201610'; --тек.период
  l_cd:='swap_sal_chpay5_20161028_1';
  l_mgchange:=l_mg;
  l_dt:=to_date('20161028','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед

  dbms_output.enable;

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;


  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);
  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select t.lsk, t.org, t.usl, abs(t.summa) as summa from saldo_usl t, usl u where t.mg='201611'
            and t.org in (2) and t.summa<0
            and t.usl=u.usl and u.usl in  ('005', '006')
        )
  loop
      --поставить на дебет (на текущую орг в лиц.сч.)
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, n.usl , n.org, c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from nabor n where n.lsk=c.lsk and n.usl='009'; /* переадресация услуг*/
      if sql%notfound then
        dbms_output.put_line('check lsk='||c.lsk||' usl='||c.usl);
      else
        --снять с кредита, если успешно постановка на дебет
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lsk, c.usl, c.org, -1*c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
             from dual;
      end if;

  end loop;
commit;
end swap_sal_chpay6;


--перебросить сальдо с одной группы орг (кредитовое) на другую
procedure swap_sal_chpay7 is
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
  l_mg:='201610'; --тек.период
  l_cd:='swap_sal_chpay5_20161028_2';
  l_mgchange:=l_mg;
  l_dt:=to_date('20161028','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед

  dbms_output.enable;

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;


  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);
  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select t.lsk, t.org, t.usl, abs(t.summa) as summa from saldo_usl t, usl u where t.mg='201611'
            and t.org in (76) and t.summa<0
            and t.usl=u.usl and u.usl in  ('031', '046')
        )
  loop

      --поставить на дебет
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, n.usl , n.org, c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from nabor n where n.lsk=c.lsk and n.usl=c.usl
           and n.org=650;
      if sql%notfound then
        dbms_output.put_line('check lsk='||c.lsk||' usl='||c.usl);
      else
        --снять с кредита, если успешно постановка на дебет
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lsk, c.usl, c.org, -1*c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
             from dual;
      end if;

  end loop;
commit;
end swap_sal_chpay7;

--перебросить сальдо с одной группы орг (кредитовое) на другую
procedure swap_sal_chpay8 is
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
  l_mg:='201610'; --тек.период
  l_cd:='swap_sal_chpay5_20161028_3';
  l_mgchange:=l_mg;
  l_dt:=to_date('20161028','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед

  dbms_output.enable(1000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;


  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);
  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select k.k_lsk_id, t.lsk, t.org, t.usl, abs(t.summa) as summa from kart k, saldo_usl t, usl u, v_lsk_tp tp where t.mg='201610'
            and t.summa<0 and k.lsk=t.lsk and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
            and t.usl=u.usl and u.usl in  ('033', '034')
        )
  loop

      --поставить на дебет (на текущую орг в лиц.сч.)
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select k.lsk, n.usl , n.org, c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
           from kart k, nabor n, v_lsk_tp tp where k.k_lsk_id=c.k_lsk_id and n.usl='033'
           and k.lsk<>c.lsk and k.psch not in (8,9)
           and k.lsk=n.lsk and k.fk_tp=tp.id and tp.cd='LSK_TP_ADDIT';
      if sql%notfound then
        dbms_output.put_line('check lsk='||c.lsk||' usl='||c.usl);
      else
        --снять с кредита, если успешно постановка на дебет
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lsk, c.usl, c.org, -1*c.summa, uid, l_dt, l_mg, l_mg, l_id, 0 as var
             from dual;
      end if;

  end loop;
commit;
end swap_sal_chpay8;


--распределить кредитовое сальдо с одной группы усл(орг) на другую группу
procedure swap_sal_chpay9 is
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
  l_mg:='201704'; --тек.период
  l_cd:='swap_sal_chpay1_20170417';
  l_mgchange:=l_mg;
  l_dt:=to_date('20170414','YYYYMMDD');
--  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед
  l_mg3:=l_mg; --месяц вперед

  dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

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
        and s.usl in ('015', '016', '058', '007', '008', '056') --по этим услугам
        and s.org=2
        join kart k on s.lsk=k.lsk
             --and k.house_id=39766 --по этому дому
        and exists
        (select t.*
         from saldo_usl t-- где есть дебет.сальдо по другим услугам
         where t.mg=s.mg and t.lsk=s.lsk
          --and s.org<>t.org and t.usl=u.usl and u.uslm=u2.uslm
          --and t.usl in ('054','026','055','007','008','056','011','012','031','046') --на другие услуги
          and t.org=677
          and t.summa > 0
        )
        )
  loop

  --абс.величина кредит сальдо
  l_kr:=abs(c.summa);

  --сформировать сальдо
  gen.gen_saldo(c.lsk);

  --найти абс деб сальдо
  select abs(nvl(sum(t.summa),0)) into l_deb
         from saldo_usl t--, usl u
         where t.mg=c.mg and t.lsk=c.lsk
          --and t.org <> c.org and t.usl=u.usl
          --and u.uslm=c.uslm
          --and t.usl in ('054','026','055','007','008','056','011','012','031','046') --на другие услуги
          and t.org=677
          and t.summa > 0;
  --ограничить сумму по дебет.сальдо
  if l_kr >= l_deb then
    l_kr:=l_deb;
  end if;

  --выполнить перенос кредит. сальдо,
  --на другие, дебетовые услуги
  select rec_summ(t.usl, t.org, t.summa, 0)
         bulk collect into t_summ
         from saldo_usl t--, usl u
         where t.mg=c.mg and t.lsk=c.lsk
          --and t.org <> c.org and t.usl=u.usl
          --and u.uslm=c.uslm
          --and t.usl in ('054','026','055','007','008','056','011','012','031','046') --на другие услуги
          and t.org=677
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
end swap_sal_chpay9;

--распределить кредитовое сальдо с одной группы усл(орг) на другую группу
--перебросить сальдо с одной группы орг (кредитовое) на другую
procedure swap_sal_with_pen10 is
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
 l_lsk_tp number;
begin
  l_mg:='201612'; --тек.период
  l_cd:='swap_sal_with_pen10_20161212';
  l_mgchange:=l_mg;
  l_dt:=to_date('20161212','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,-1); --месяц назад

  select t.id into l_lsk_tp from v_lsk_tp t where t.cd='LSK_TP_MAIN';
  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;
  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  delete from c_change t where t.doc_id=l_id;
  delete from c_pen_corr t where t.fk_doc=l_id;

  --сальдо
  --снять с УК
  insert into c_change
    (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id,
     doc_id)
    select k.lsk, t.usl, t.org, -1*t.summa, l_mg as mgchange, '999' as nkom, 0 as type,
     l_dt, sysdate, l_user, l_id
     from saldo_usl t, kart k where t.lsk=k.lsk and k.reu in ('88') and
       t.mg=l_mg and k.fk_tp=l_lsk_tp;
  --поставить на УК
  insert into c_change
    (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id,
     doc_id)
    select k2.lsk, t.usl, t.org, t.summa, l_mg as mgchange, '999' as nkom, 0 as type,
     l_dt, sysdate, l_user, l_id
     from saldo_usl t, kart k, kart k2 where t.lsk=k.lsk and k.reu in ('88')
       and k.k_lsk_id=k2.k_lsk_id and k2.reu in ('41') and
       t.mg=l_mg and k.fk_tp=l_lsk_tp and k2.fk_tp=l_lsk_tp;

  --пеня
  --снять с УК
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
    select k.lsk, -1*t.penya, t.mg1, l_dt, sysdate, l_user, l_id
     from a_penya t, kart k where t.lsk=k.lsk and k.reu in ('88') and
       t.mg=l_mg3 and k.fk_tp=l_lsk_tp;
  --поставить на УК
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc)
    select k2.lsk, t.penya, t.mg1, l_dt, sysdate, l_user, l_id
     from a_penya t, kart k, kart k2 where t.lsk=k.lsk and k.reu in ('88') and
       k.k_lsk_id=k2.k_lsk_id and k2.reu in ('41') and
       t.mg=l_mg3 and k.fk_tp=l_lsk_tp and k2.fk_tp=l_lsk_tp;

commit;
end swap_sal_with_pen10;

--распределить кредитовое сальдо по дебетовому - для Кис.
procedure sub_ZERO_kis is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 l_kr2 number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
 l_coeff number;
 l_coeff2 number;
 l_itg_kr number;
 l_itg_db number;
 l_old_usl_kr usl.usl%type;
 l_old_org_kr number;
 l_old_usl_db usl.usl%type;
 l_old_org_db number;
begin
  l_mg:='201811'; --тек.период
  l_cd:='swap_ZERO_kis_20181129';
  l_mgchange:=l_mg;
  l_dt:=to_date('20181129','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед, если надо для по исх сальдо

  --l_mg3 := l_mg; -- сальдо - вх.на текущий месяц

  dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select distinct s.lsk, s.mg
         from saldo_usl s join usl u2
        on s.mg=l_mg3 and s.usl=u2.usl
        join kart k on s.lsk=k.lsk
        --and s.org = 676 -- региональный оператор
        and k.reu in (
        '094','109','103','059','017','041','104','102','014','105','106','073','012','063',
        '015','096','080','095','107','108','077','019','070','084','006','007','036','035','078','052','081','100','101'
        ) --по этим УК
        --and k.reu not in ('87','82','73','80','76','85','86','84')
        --and k.house_id =39666 --по этому дому
        and s.summa < 0
        --and s.usl in ('007','008','056') --по этим услугам
             --and k.lsk='14040757'
        --and exists (select * from a_kwtp_day d where d.mg between '201701' and '201702'
        --                     and d.lsk=k.lsk and d.fk_distr=15)
        and exists
        (select t.*
         from saldo_usl t-- где есть дебет.сальдо по другим услугам 14040763
         where t.mg=s.mg and t.lsk=s.lsk
          and t.summa > 0
          --and t.org<>677
        )
        )
  loop

  --найти абс кред и деб сальдо
  select abs(nvl(sum(case when t.summa < 0 then t.summa else 0 end),0)),
         nvl(sum(case when t.summa > 0 then t.summa else 0 end),0)
          into l_kr2, l_deb
         from saldo_usl t
         where t.mg=c.mg
         and t.lsk=c.lsk
         --and (t.summa < 0 and t.usl in ('007','008','056') or t.summa > 0 and t.org <> 677)-- региональный оператор УБРАТЬ СТРОКУ, если перераспр все услуги сальдо!
         ;

  --ограничить кредит сумму по дебет.сальдо
  if l_kr2 > l_deb then
    l_kr:=l_deb;
  else
    l_kr:=l_kr2;
  end if;

  -- найти коэфф ограничения снятия с кредита
  l_coeff2:=l_kr/l_kr2;

  -- найти коэфф установки на дебет
  l_coeff:=l_kr/l_deb;

  --снять с кредита
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff2,2) as summa from saldo_usl t
                 where t.mg=c.mg
                 and t.summa < 0
                 and t.lsk=c.lsk
                 --and t.org = 676 -- региональный оператор УБРАТЬ СТРОКУ, если перераспр все услуги сальдо!
                 --and (t.summa < 0 and t.usl in ('007','008','056') or t.summa > 0 and t.org <> 677)-- региональный оператор УБРАТЬ СТРОКУ, если перераспр все услуги сальдо!
                 and round(t.summa*l_coeff2,2) <> 0
                 ) loop

      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 1 as var
           from dual;
        l_old_usl_kr:=c2.usl;
        l_old_org_kr:=c2.org;

  end loop;

  --поставить на дебет
  l_old_usl_db:=null;
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff,2) as summa from saldo_usl t
                 where t.mg=c.mg
                 and t.summa > 0
                 and t.lsk=c.lsk
                 and round(t.summa*l_coeff,2) <> 0
                 ) loop
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 2 as var
           from dual;
        l_old_usl_db:=c2.usl;
        l_old_org_db:=c2.org;

  end loop;

  -- не было найдено вхождение в установку на дебет (обычно если кредит =0.01 руб)
  if l_old_usl_db is null then
    for c3 in (select t.usl, t.org from saldo_usl t
           where t.lsk=c.lsk and t.mg=c.mg
           and t.summa > 0
           --and t.org <> 677
            order by t.summa desc) loop
      l_old_usl_db:=c3.usl;
      l_old_org_db:=c3.org;
      exit;
    end loop;
  end if;

  select sum(decode(t.var,1,t.summa,0)), sum(decode(t.var,2,t.summa,0))
      into l_itg_kr, l_itg_db
      from t_corrects_payments t where t.fk_doc=l_id
      and t.lsk=c.lsk;
  -- округлить
  if l_kr=l_kr2 then
    -- если сальдо меньше или равно дебетовому
    -- надо снять в ноль!
    for c2 in (
          select a.usl, a.org, sum(a.summa) as summa from (
          select t.usl, t.org, t.summa from saldo_usl t where
                       t.mg=c.mg
                       and t.summa < 0 -- кредит.сальдо
                       --and t.usl in ('007','008','056')
                       and t.lsk=c.lsk
                       --and t.org = 676-- региональный оператор УБРАТЬ СТРОКУ, если перераспр все услуги сальдо!

          union all
          select t.usl, t.org, -1*t.summa from t_corrects_payments t where
                       t.mg=l_mg
                       and t.lsk=c.lsk -- корректировку как оплату
                       and t.fk_doc=l_id
                       and t.var=1) a
          group by a.usl, a.org
          having sum(a.summa) <> 0 )
           loop
          -- сальдо закрылось не полностью, снять еще
          if abs(c2.summa) <> 0.01 then
            Raise_application_error(-20000, 'Некорректное округление #1! лс='||c.lsk||' summa='||to_char(c2.summa));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, -1 as var
               from dual;
    end loop;
  else
    -- сальдо ограничено по дебетовому
    if (-1*l_kr <> l_itg_kr) then
    --поставить или снять полностью сумму расхождения
          if abs(-1*l_kr - l_itg_kr) > 0.05 then
            Raise_application_error(-20000, 'Некорректное округление #2! лс='||c.lsk||' summa='||to_char(-1*l_kr - l_itg_kr));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, l_old_usl_kr, l_old_org_kr, (-1*l_kr - l_itg_kr), uid, l_dt, l_mg, l_mg, l_id, -1 as var
               from dual;
    end if;
  end if;

  -- проверить установку дебетового сальдо
    if (l_kr <> l_itg_db) then
    --поставить или снять полностью сумму расхождения
          if abs(l_kr - l_itg_db) > 0.05 then
            Raise_application_error(-20000, 'Некорректное округление #3! лс='||c.lsk||' summa='||to_char(l_kr - l_itg_db));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, l_old_usl_db, l_old_org_db, (l_kr - l_itg_db), uid, l_dt, l_mg, l_mg, l_id, -2 as var
               from dual;
    end if;

  commit;

  -- еще раз проверить
  select sum(decode(t.var,1,t.summa,-1,t.summa,0)), sum(decode(t.var,2,t.summa,-2,t.summa,0))
      into l_itg_kr, l_itg_db
      from t_corrects_payments t where t.mg=l_mg and t.fk_doc=l_id
      and t.lsk=c.lsk;

    if (abs(l_itg_kr) <> abs(l_itg_db)) then
      Raise_application_error(-20000, 'Некорректное округление #4! лс='||c.lsk||' summa='||to_char(abs(l_itg_kr) -  abs(l_itg_db)));
    end if;


  end loop;

  -- вернуть обратно var
  update t_corrects_payments t set t.var=0
    where t.mg=l_mg and t.fk_doc=l_id;

  -- провести в kwtp_day
  c_gen_pay.dist_pay_del_corr;
  c_gen_pay.dist_pay_add_corr(var_ => 0);

commit;
end sub_ZERO_kis;

-- НЕРАБОЧАЯ ЧУШЬ !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--распределить кредитовое сальдо по дебетовому - для Полыс.
procedure sub_ZERO_polis is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 l_kr2 number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
 l_coeff number;
 l_coeff2 number;
 l_itg_kr number;
 l_itg_db number;
 l_old_usl_kr usl.usl%type;
 l_old_org_kr number;
 l_old_usl_db usl.usl%type;
 l_old_org_db number;
begin
  l_mg:='201812'; --тек.период
  l_cd:='swap_ZERO_polis_201812';
  l_mgchange:=l_mg;
  l_dt:=to_date('20181224','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед, если надо для по исх сальдо

  --l_mg3 := l_mg; -- сальдо - вх.на текущий месяц

  dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select distinct s.lsk, s.mg
         from saldo_usl_script s join usl u2
        on s.mg=l_mg3 and s.usl=u2.usl
        join kart k on s.lsk=k.lsk
        --and k.reu in ('35') --по этим УК
        and s.summa < 0
        --and s.usl in ('007','056') --по этим услугам
        and exists
        (select t.*
         from saldo_usl_script t-- где есть дебет.сальдо по другим услугам
         where t.mg=s.mg and t.lsk=s.lsk
          and t.summa > 0
          --and t.usl in ('007','056') --по этим услугам
        )
        )
  loop

  --найти абс кред и деб сальдо
  select abs(nvl(sum(case when t.summa < 0 then t.summa else 0 end),0)),
         nvl(sum(case when t.summa > 0 then t.summa else 0 end),0)
          into l_kr2, l_deb
         from saldo_usl_script t
         where t.mg=c.mg
         and t.lsk=c.lsk
          --and t.usl in ('007','056') --по этим услугам
         ;

  --ограничить кредит сумму по дебет.сальдо
  if l_kr2 > l_deb then
    l_kr:=l_deb;
  else
    l_kr:=l_kr2;
  end if;

  -- найти коэфф ограничения снятия с кредита
  l_coeff2:=l_kr/l_kr2;

  -- найти коэфф установки на дебет
  l_coeff:=l_kr/l_deb;

  --снять с кредита
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff2,2) as summa from saldo_usl_script t
                 where t.mg=c.mg
                 and t.summa < 0
                 and t.lsk=c.lsk
                 --and t.usl in ('007','056') --по этим услугам
                 and round(t.summa*l_coeff2,2) <> 0
                 ) loop

      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 1 as var
           from dual;
        l_old_usl_kr:=c2.usl;
        l_old_org_kr:=c2.org;

  end loop;

  --поставить на дебет
  l_old_usl_db:=null;
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff,2) as summa from saldo_usl_script t
                 where t.mg=c.mg
                 and t.summa > 0
                 and t.lsk=c.lsk
                 --and t.usl in ('007','056') --по этим услугам
                 and round(t.summa*l_coeff,2) <> 0
                 ) loop
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 2 as var
           from dual;
        l_old_usl_db:=c2.usl;
        l_old_org_db:=c2.org;

  end loop;

  -- не было найдено вхождение в установку на дебет (обычно если кредит =0.01 руб)
  if l_old_usl_db is null then
    for c3 in (select t.usl, t.org from saldo_usl_script t
           where t.lsk=c.lsk and t.mg=c.mg
           and t.summa > 0
           --and t.org <> 677
            order by t.summa desc) loop
      l_old_usl_db:=c3.usl;
      l_old_org_db:=c3.org;
      exit;
    end loop;
  end if;

  select sum(decode(t.var,1,t.summa,0)), sum(decode(t.var,2,t.summa,0))
      into l_itg_kr, l_itg_db
      from t_corrects_payments t where t.fk_doc=l_id
      and t.lsk=c.lsk;
  -- округлить
  if l_kr=l_kr2 then
    -- если сальдо меньше или равно дебетовому
    -- надо снять в ноль!
    for c2 in (
          select a.usl, a.org, sum(a.summa) as summa from (
          select t.usl, t.org, t.summa from saldo_usl_script t where
                       t.mg=c.mg
                       and t.summa < 0 -- кредит.сальдо
                       and t.lsk=c.lsk
          union all
          select t.usl, t.org, -1*t.summa from t_corrects_payments t where
                       t.mg=l_mg
                       and t.lsk=c.lsk -- корректировку как оплату
                       and t.fk_doc=l_id
                       and t.var=1) a
          group by a.usl, a.org
          having sum(a.summa) <> 0 )
           loop
          -- сальдо закрылось не полностью, снять еще
          if abs(c2.summa) <> 0.01 then
            Raise_application_error(-20000, 'Некорректное округление #1! лс='||c.lsk||' summa='||to_char(c2.summa));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, -1 as var
               from dual;
    end loop;
  else
    -- сальдо ограничено по дебетовому
    if (-1*l_kr <> l_itg_kr) then
    --поставить или снять полностью сумму расхождения
          if abs(-1*l_kr - l_itg_kr) > 0.05 then
            Raise_application_error(-20000, 'Некорректное округление #2! лс='||c.lsk||' summa='||to_char(-1*l_kr - l_itg_kr));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, l_old_usl_kr, l_old_org_kr, (-1*l_kr - l_itg_kr), uid, l_dt, l_mg, l_mg, l_id, -1 as var
               from dual;
    end if;
  end if;

  -- проверить установку дебетового сальдо
    if (l_kr <> l_itg_db) then
    --поставить или снять полностью сумму расхождения
          if abs(l_kr - l_itg_db) > 0.05 then
            Raise_application_error(-20000, 'Некорректное округление #3! лс='||c.lsk||' summa='||to_char(l_kr - l_itg_db));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
            select c.lsk, l_old_usl_db, l_old_org_db, (l_kr - l_itg_db), uid, l_dt, l_mg, l_mg, l_id, -2 as var
               from dual;
    end if;

  commit;

  -- еще раз проверить
  select sum(decode(t.var,1,t.summa,-1,t.summa,0)), sum(decode(t.var,2,t.summa,-2,t.summa,0))
      into l_itg_kr, l_itg_db
      from t_corrects_payments t where t.mg=l_mg and t.fk_doc=l_id
      and t.lsk=c.lsk;

    if (abs(l_itg_kr) <> abs(l_itg_db)) then
      Raise_application_error(-20000, 'Некорректное округление #4! лс='||c.lsk||' summa='||to_char(abs(l_itg_kr) -  abs(l_itg_db)));
    end if;


  end loop;

  -- вернуть обратно var
  update t_corrects_payments t set t.var=0
    where t.mg=l_mg and t.fk_doc=l_id;

  -- провести в kwtp_day
  --c_gen_pay.dist_pay_del_corr;
  --c_gen_pay.dist_pay_add_corr(var_ => 0);

commit;
end sub_ZERO_polis;


-- распределить кредитовое сальдо по дебетовому - для Полыс.
-- по определенным услугам и орг - главная процедура
-- ПРЕДВАРИТЕЛЬНО заполнить saldo_usl_script
-- исходящим сальдо!!!
-- например вот таким скриптом:
/*delete from SALDO_USL_SCRIPT t;
insert into SALDO_USL_SCRIPT
  (lsk, usl, org, summa, mg, uslm)
select lsk, usl, org, summa, mg, uslm
from saldo_usl t where t.mg='201806'*/
procedure sub_ZERO_polis_main is
  -- временные коллекции, для разных нужд
  t_tmp_reu scott.tab_tmp;
  t_tmp_usl scott.tab_tmp;
  t_tmp_org scott.tab_tmp;
begin
  dbms_output.enable(2000000);


  for c in (select distinct org from (
            select a.lsk, a.org, a.uslm, count(*) as cnt from
            (
              select t.lsk, t.org, u.uslm, u.usl, sum(t.summa) as summa
                from saldo_usl_script t, usl u where
                t.usl=u.usl
              group by t.lsk, t.org, u.uslm, u.usl
              having sum(t.summa)<>0
              ) a
              group by a.lsk, a.org, a.uslm
              having count(*)>1
            )) loop
    sub_ZERO_polis_usl(t_tmp_usl, t_tmp_org, t_tmp_reu,
      c.org, c.org, '201807', gdt(30,0,0));
  end loop;

end;

-- распределить кредитовое сальдо по дебетовому - для Полыс. по определенным услугам и орг
procedure sub_ZERO_polis_usl(p_tmp_usl in scott.tab_tmp, -- список услуг (ПОКА НЕ ИСПОЛЬЗУЕТСЯ)
                             p_tmp_org in scott.tab_tmp,  -- список организаций (ПОКА НЕ ИСПОЛЬЗУЕТСЯ)
                             p_tmp_reu in scott.tab_tmp,  -- список УК  (ПОКА НЕ ИСПОЛЬЗУЕТСЯ)
                             p_org in number,  -- организация
                             p_mark in varchar2, -- маркер
                             p_mg in varchar2, -- текущий период,
                             p_dat in date -- дата проводки
                             ) is
 l_mg params.period%type;
 l_mg3 params.period%type;
 l_user number;
 l_id number;
 l_cd c_change_docs.text%type;
 l_mgchange c_change_docs.mgchange%type;
 l_dt date;
 l_kr number;
 l_kr2 number;
 t_summ tab_summ;
 l_ret number;
 l_deb number;
 l_coeff number;
 l_coeff2 number;
 l_itg_kr number;
 l_itg_db number;
 l_old_usl_kr usl.usl%type;
 l_old_org_kr number;
 l_old_usl_db usl.usl%type;
 l_old_org_db number;
 l_iter number;
begin
  l_mg:=p_mg; --тек.период
  l_cd:='SWP_ZR_p_usl_'||to_char(p_dat,'YYYYMMDD')||'_'||p_mark;
  l_mgchange:=l_mg;
  l_dt:=p_dat;
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед, если надо по исх сальдо

  --l_mg3 := l_mg; -- сальдо - вх.на текущий месяц

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  dbms_output.put_line('p_org='||p_org);
  l_iter:=0;
  for c in (select distinct s.lsk, s.mg, u2.uslm
         from saldo_usl_script s join usl u2
        on s.mg=l_mg3 and s.usl=u2.usl
        join kart k on s.lsk=k.lsk
        --and k.reu in ('35') --по этим УК
        and s.summa < 0
        and s.org=p_org
        and exists
        (select t.*
         from saldo_usl_script t, usl m-- где есть дебет.сальдо по другим услугам, входящим в главную услугу
         where t.mg=s.mg and t.lsk=s.lsk
          and t.summa > 0

          and t.usl=m.usl
          and t.org=p_org
          and m.uslm=u2.uslm and m.usl<>u2.usl
        )
        )
  loop
  l_iter:=l_iter+1;

  dbms_output.put_line('lsk='||c.lsk||' iter='||l_iter);
  --найти абс кред и деб сальдо
  select abs(nvl(sum(case when t.summa < 0 then t.summa else 0 end),0)),
         nvl(sum(case when t.summa > 0 then t.summa else 0 end),0)
          into l_kr2, l_deb
         from saldo_usl_script t, usl m
         where t.mg=c.mg
         and t.lsk=c.lsk

          and t.org=p_org
          and t.usl=m.usl
          and m.uslm=c.uslm;

  --ограничить кредит сумму по дебет.сальдо
  if l_kr2 > l_deb then
    l_kr:=l_deb;
  else
    l_kr:=l_kr2;
  end if;

  -- найти коэфф ограничения снятия с кредита
  l_coeff2:=l_kr/l_kr2;

  -- найти коэфф установки на дебет
  l_coeff:=l_kr/l_deb;

  --снять с кредита
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff2,2) as summa
                 from saldo_usl_script t, usl m
                 where t.mg=c.mg
                 and t.summa < 0
                 and t.lsk=c.lsk

                  and t.org=p_org
                  and t.usl=m.usl
                  and m.uslm=c.uslm

                 and round(t.summa*l_coeff2,2) <> 0
                 ) loop

      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 1 as var, l_iter
           from dual;
        l_old_usl_kr:=c2.usl;
        l_old_org_kr:=c2.org;

  end loop;

  --поставить на дебет
  l_old_usl_db:=null;
  for c2 in (select t.lsk, t.usl, t.org, round(t.summa*l_coeff,2) as summa
                 from saldo_usl_script t, usl m
                 where t.mg=c.mg
                 and t.summa > 0
                 and t.lsk=c.lsk

                  and t.org=p_org
                  and t.usl=m.usl
                  and m.uslm=c.uslm

                 and round(t.summa*l_coeff,2) <> 0
                 ) loop
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
        select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, 2 as var, l_iter
           from dual;
        l_old_usl_db:=c2.usl;
        l_old_org_db:=c2.org;

  end loop;

  -- не было найдено вхождение в установку на дебет (обычно если кредит =0.01 руб)
  if l_old_usl_db is null then
    for c3 in (select t.usl, t.org from saldo_usl_script t, usl m
           where t.lsk=c.lsk and t.mg=c.mg

            and t.org=p_org
            and t.usl=m.usl
            and m.uslm=c.uslm

           and t.summa > 0
            order by t.summa desc) loop
      l_old_usl_db:=c3.usl;
      l_old_org_db:=c3.org;
      exit;
    end loop;
  end if;

  select sum(decode(t.var,1,t.summa,0)), sum(decode(t.var,2,t.summa,0))
      into l_itg_kr, l_itg_db
      from t_corrects_payments t where t.fk_doc=l_id
      and t.lsk=c.lsk and t.iter=l_iter;
  -- округлить
  if l_kr=l_kr2 then
    -- если сальдо меньше или равно дебетовому
    -- надо снять в ноль!
    for c2 in (
          select a.usl, a.org, sum(a.summa) as summa from (
          select t.usl, t.org, t.summa from saldo_usl_script t, usl m where
                       t.mg=c.mg
                       and t.summa < 0 -- кредит.сальдо

                        and t.org=p_org
                        and t.usl=m.usl
                        and m.uslm=c.uslm

                       and t.lsk=c.lsk
          union all
          select t.usl, t.org, -1*t.summa from t_corrects_payments t where
                       t.mg=l_mg
                       and t.lsk=c.lsk -- корректировку как оплату
                       and t.fk_doc=l_id
                       and t.var=1
                       and t.iter=l_iter
                       ) a
          group by a.usl, a.org
          having sum(a.summa) <> 0 )
           loop
          -- сальдо закрылось не полностью, снять еще
          if abs(c2.summa) <> 0.01 then
            Raise_application_error(-20000, 'Некорректное округление #1! лс='||c.lsk||' summa='||to_char(c2.summa));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
            select c.lsk, c2.usl, c2.org, c2.summa, uid, l_dt, l_mg, l_mg, l_id, -1 as var, l_iter
               from dual;
    end loop;
  else
    -- сальдо ограничено по дебетовому
    if (-1*l_kr <> l_itg_kr) then
    --поставить или снять полностью сумму расхождения
          if abs(-1*l_kr - l_itg_kr) > 0.05 then
            Raise_application_error(-20000, 'Некорректное округление #2! лс='||c.lsk||' summa='||to_char(-1*l_kr - l_itg_kr));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
            select c.lsk, l_old_usl_kr, l_old_org_kr, (-1*l_kr - l_itg_kr), uid, l_dt, l_mg, l_mg, l_id, -1 as var, l_iter
               from dual;
    end if;
  end if;

  -- проверить установку дебетового сальдо
    if (l_kr <> l_itg_db) then
    --поставить или снять полностью сумму расхождения
          if abs(l_kr - l_itg_db) > 0.05 then
            Raise_application_error(-20000, 'Некорректное округление #3! лс='||c.lsk||' summa='||to_char(l_kr - l_itg_db));
          end if;
          insert into t_corrects_payments
            (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
            select c.lsk, l_old_usl_db, l_old_org_db, (l_kr - l_itg_db), uid, l_dt, l_mg, l_mg, l_id, -2 as var, l_iter
               from dual;
    end if;

  commit;

  -- еще раз проверить
  select sum(decode(t.var,1,t.summa,-1,t.summa,0)), sum(decode(t.var,2,t.summa,-2,t.summa,0))
      into l_itg_kr, l_itg_db
      from t_corrects_payments t where t.mg=l_mg and t.fk_doc=l_id
      and t.lsk=c.lsk and t.iter=l_iter;

    if (abs(l_itg_kr) <> abs(l_itg_db)) then
      Raise_application_error(-20000, 'Некорректное округление #4! лс='||c.lsk||' summa='||to_char(abs(l_itg_kr) -  abs(l_itg_db)));
    end if;


  end loop;

  -- вернуть обратно var
  update t_corrects_payments t set t.var=0
    where t.mg=l_mg and t.fk_doc=l_id;

  -- провести в kwtp_day
  c_gen_pay.dist_pay_del_corr;
  c_gen_pay.dist_pay_add_corr(var_ => 0);

commit;
end sub_ZERO_polis_usl;

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
mgchange_:='201710';
--комментарий
comment_:='Коррекция сальдо по УК';
--Уникальный номер переброски
cd_:='01';
--Дата переброски
dat_:=to_date('11102017','DDMMYYYY');
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

-- выбрать услугу
function chooseUsl(p_usl in varchar2, p_usl1 in varchar2, p_usl2 in varchar2) return varchar2 is
 l_usl varchar2(3);
begin
  if p_usl =p_usl1 then
    l_usl:=p_usl2;
  else
    l_usl:=p_usl1;
  end if;
 return l_usl;
end;

-- перенести кредитовое сальдо с одной усл на другую (Полыс)
-- может работать по ИСХОДЯЩЕМУ сальдо, для этого нужно удалить эту корректировку,
-- сформировать пункт "Сальдо" в итоговом формировании, провести эту проводку, и опять сделать формирование сальдо
procedure swap_sal_chpay10 is
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
  l_mg:='201802'; --тек.период
  l_cd:='swap_sal_chpay10_20180227';
  l_mgchange:=l_mg;
  l_dt:=to_date('20180227','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед
  --l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


-- Кузбасс энерг.
  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('056', '007')
    where s.mg=l_mg3
    and s.usl in ('056', '007')
    and s.summa < 0
    and s.org = 677;

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '056', '007', '007', '056') ,s.org,
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('056', '007')
    where s.mg=l_mg3
    and s.usl in ('056', '007')
    and s.summa < 0
    and s.org = 677;

  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('058', '015')
    where s.mg=l_mg3
    and s.usl in ('058', '015')
    and s.summa < 0
    and s.org = 677;

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '058', '015', '015', '058') ,s.org,
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('058', '015')
    where s.mg=l_mg3
    and s.usl in ('058', '015')
    and s.summa < 0
    and s.org = 677;


-- УК хв. и канализ.
  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('057', '011')
    where s.mg=l_mg3
    and s.usl in ('057', '011')
    and s.summa < 0
    and s.org in (2,3,78,29);

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '057', '011', '011', '057') ,s.org,
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('057', '011')
    where s.mg=l_mg3
    and s.usl in ('057', '011')
    and s.summa < 0
    and s.org in (2,3,78,29);

  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('013', '059')
    where s.mg=l_mg3
    and s.usl in ('013', '059')
    and s.summa < 0
    and s.org in (2,3,78,29);

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '013', '059', '059', '013') ,s.org,
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('013', '059')
    where s.mg=l_mg3
    and s.usl in ('013', '059')
    and s.summa < 0
    and s.org in (2,3,78,29);



-- РСО Энерг.компания (отдельной корректировкой!!!)

  -- х.вода
  -- снять
/*  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('057', '011')
    where s.mg=l_mg3
    and s.usl in ('057', '011')
    and s.summa < 0
    and s.org in (7);

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '057', '011', '011', '057'), 29 as org,
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('057', '011')
    where s.mg=l_mg3
    and s.usl in ('057', '011')
    and s.summa < 0
    and s.org in (7);

  -- канализ
  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('059', '013')
    where s.mg=l_mg3
    and s.usl in ('059', '013')
    and s.summa < 0
    and s.org in (7);

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '059', '013', '013', '059'), 29 as org,
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('059', '013')
    where s.mg=l_mg3
    and s.usl in ('059', '013')
    and s.summa < 0
    and s.org in (7);
*/
-- Эл.эн и ОДН

  -- снять
/*  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    -1* case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
            and t.usl in ('103', '053')
    where s.mg=l_mg3
    and s.summa < 0
    and s.usl in ('103', '053');

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '103', '053', '053', '103') ,s.org,
    case when abs(nvl(s.summa,0)) > nvl(t.summa,0) then nvl(t.summa,0) else abs(nvl(s.summa,0)) end,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s
    join saldo_usl t
        on t.lsk=s.lsk and t.usl<>s.usl and t.org=s.org and t.mg=s.mg and t.summa > 0
          and t.usl in ('103', '053')
    where s.mg=l_mg3
    and s.summa < 0
    and s.usl in ('103', '053');
*/
--убрать нули
delete from t_corrects_payments t where t.summa = 0 and t.fk_doc=l_id;
commit;
end swap_sal_chpay10;


-- перенести сальдо с одной усл на другую (Полыс)
procedure swap_sal_chpay11 is
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
  l_mg:='201803'; --тек.период
  l_cd:='swap_sal_chpay11_20180328';
  l_mgchange:=l_mg;
  l_dt:=to_date('20180328','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед
  --l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select k.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl_script s, kart k, kart k2
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    and k.k_lsk_id=k2.k_lsk_id
    and k.house_id=39766
    and k.reu in ('01')
    and k2.reu in ('13')
    and s.usl in ('013', '014')
    and s.summa < 0
    and s.org = 7;

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select k2.lsk, s.usl ,s.org,
    -1*s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl_script s, kart k, kart k2
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    and k.k_lsk_id=k2.k_lsk_id
    and k.house_id=39766
    and k.reu in ('01')
    and k2.reu in ('13')
    and s.usl in ('013', '014')
    and s.summa < 0
    and s.org = 7;

commit;
end swap_sal_chpay11;


procedure swap_sal_chpay11_2 is
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
  l_mg:='201803'; --тек.период
  l_cd:='swap_sal_chpay11_2_20180328';
  l_mgchange:=l_mg;
  l_dt:=to_date('20180328','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед
  --l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl_script s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and k.house_id in (37865,37849,37879,37888,37896)
    and s.usl in ('095')
    and s.summa < 0
    and s.org = 78;

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, '003' as usl , s.org,
    -1*s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl_script s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and k.house_id in (37865,37849,37879,37888,37896)
    and s.usl in ('095')
    and s.summa < 0
    and s.org = 78;

commit;
end swap_sal_chpay11_2;

procedure swap_sal_chpay11_3 is
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
  l_mg:='201802'; --тек.период
  l_cd:='swap_sal_chpay11_20180228';
  l_mgchange:=l_mg;
  l_dt:=to_date('20180228','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед
  --l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and s.usl in ('056', '058')
    and s.summa < 0
    and s.org = 677;

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '056','007','058','015') as usl , s.org,
    -1*s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and s.usl in ('056', '058')
    and s.summa < 0
    and s.org = 677;

  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and s.usl in ('057', '059')
    and s.summa < 0
    and s.org in (78,2,3,29);

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, decode(s.usl, '057','011','059','013') as usl , s.org,
    -1*s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk --and k.psch not in (8,9)
    --and k.reu in ('01','13')
    and s.usl in ('057', '059')
    and s.summa < 0
    and s.org in (78,2,3,29);

commit;
end swap_sal_chpay11_3;

-- перенести дебет сальдо с одной усл на другую (Полыс)
procedure swap_sal_chpay12 is
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
  l_mg:='201711'; --тек.период
  l_cd:='swap_sal_chpay11_20171029';
  l_mgchange:=l_mg;
  l_dt:=to_date('20171129','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед
  --l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch not in (8,9)
    and s.usl in ('031')
    and s.summa < 0
    and s.org = 650;

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, '031' as usl , 690 as org,
    -1*s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch not in (8,9)
    and s.usl in ('031')
    and s.summa < 0
    and s.org = 650;

  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch not in (8,9)
    and s.usl in ('054')
    and s.summa < 0
    and s.org = 674;

 -- поставить
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, '054' as usl , 690 as org,
    -1*s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch not in (8,9)
    and s.usl in ('054')
    and s.summa < 0
    and s.org = 674;

--убрать нули
delete from t_corrects_payments t where t.summa = 0 and t.fk_doc=l_id;
commit;
end swap_sal_chpay12;

-- перенести кредит сальдо в никуда (Полыс)
procedure swap_sal_chpay13 is
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
  l_mg:='201712'; --тек.период
  l_cd:='swap_sal_chpay13_20171227';
  l_mgchange:=l_mg;
  l_dt:=to_date('20171227','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед
  l_mg3:=l_mg;
  --dbms_output.enable(2000000);

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;


  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('003','013','052')
    and s.summa < 0
    and s.org = 3;

  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('003','052')
    and s.summa < 0
    and s.org = 2;

  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('003','052')
    and s.summa < 0
    and s.org = 78;

  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('031')
    and s.summa < 0
    and s.org = 650;

  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('054')
    and s.summa < 0
    and s.org = 674;

  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select s.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl s, kart k
    where s.mg=l_mg3 and s.lsk=k.lsk and k.psch in (9)
    and s.usl in ('011','013')
    and s.summa < 0
    and s.org = 7;


commit;
end swap_sal_chpay13;

-- перенести кредитовое сальдо с одной усл на другую (Полыс)
-- по РСО организации
-- сформировать пункт "Сальдо" в итоговом формировании, провести эту проводку, и опять сделать формирование сальдо
-- перенести сальдо с одной усл на другую (Полыс)
procedure swap_sal_chpay14 is
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
  l_mg:='201810'; --тек.период
  l_cd:='swap_sal_RSO_20181030';
  l_mgchange:=l_mg;
  l_dt:=to_date('20181030','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  -- снять
  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select k.lsk, s.usl ,s.org,
    s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl_script s, kart k, v_lsk_tp tp
    where s.mg=l_mg3 and s.lsk=k.lsk
    and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
    and k.house_id in (36949,36950,36951,36934,36935,36943,37134,37136,36945,36987,36988,36952,36940,36946,36941)
    and s.usl in ('007','015','058','056')
    and s.summa < 0
    and s.org = 677;

  insert into t_corrects_payments
    (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
    select k2.lsk, s.usl, n.org,
    -1*s.summa,
    uid, l_dt, l_mg, l_mg, l_id, 0 as var
    from saldo_usl_script s, kart k, kart k2, v_lsk_tp tp, v_lsk_tp tp2, nabor n
    where s.mg=l_mg3 and s.lsk=k.lsk
    and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
    and k.k_lsk_id=k2.k_lsk_id and k2.fk_tp=tp2.id and tp2.cd='LSK_TP_RSO'
    and k2.lsk=n.lsk
    and s.usl=n.usl
    and k.house_id in (36949,36950,36951,36934,36935,36943,37134,37136,36945,36987,36988,36952,36940,36946,36941)
    and s.usl in ('007','015','058','056')
    and s.summa < 0
    and s.org = 677;

 -- поставить

commit;
end swap_sal_chpay14;


--создать новый период с fk_lsk_tp
procedure cr_new_xitog3(p_mg in params.period%type) is
begin
    delete from xitog3 where mg = p_mg;
    insert into xitog3 t
      (reu,
       trest,
       kul,
       nd,
       org,
       usl,
       uslm,
       status,
       indebet,
       inkredit,
       charges,
       poutsal,
       changes,
       ch_full,
       changes2,
       subsid,
       privs,
       payment,
       pn,
       outdebet,
       outkredit,
       fk_lsk_tp,
       mg)
      select s.reu,
             s.trest,
             k.kul,
             k.nd,
             x.org,
             x.usl,
             x.uslm,
             k.status,
             sum(x.indebet),
             sum(x.inkredit),
             sum(x.charges),
             sum(x.poutsal),
             sum(x.changes),
             sum(x.ch_full),
             sum(x.changes2),
             sum(x.subsid),
             sum(x.privs),
             sum(x.payment),
             sum(x.pn),
             sum(x.outdebet),
             sum(x.outkredit),
             k.fk_tp,
             x.mg
        from xitog3_lsk x, kart k, s_reu_trest s
       where x.mg = p_mg
         and x.lsk = k.lsk
         and k.reu = s.reu
       group by s.reu,
                s.trest,
                k.kul,
                k.nd,
                x.org,
                x.usl,
                x.uslm,
                k.status,
                x.mg,
                k.fk_tp;

    delete from t_saldo_reu_kul_nd_st;
    insert into t_saldo_reu_kul_nd_st
      (reu, kul, nd, status, org, usl, fk_lsk_tp)
      select distinct t.reu, t.kul, t.nd, t.status, t.org, t.usl, nvl(t.fk_lsk_tp,0) as fk_lsk_tp
        from xitog3 t;
    commit;
end;


--создать новые лицевые, перенести на них долг и пеню (не взлетело, использовал старый скрипт)
/*procedure cr_new_lsk_with_deb is
  l_mg params.period%type;
  l_mg_sal params.period%type;
  l_user number;
  l_id number;
  l_dt date;
  l_cd c_change_docs.cd_tp%type;
  l_dst_uk t_org.reu%type; -- УК назначения
  l_dst_lsk kart.lsk%type; --ЛС назначения
begin
  dbms_output.enable(1000000);

  l_mg:='201705'; --тек.период
  l_dt:=gdt(30,5,2017);
  l_cd:='swap_sal_chpay5_'||to_char(l_dt,'YYYYMMDD')||'_1';
  l_mg_sal:='201705'; --период по которому смотреть сальдо

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;


  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change a where exists
    (select * from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd and t.id=a.doc_id
                );
  delete from c_pen_corr a where exists
    (select * from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd and t.id=a.fk_doc
                );
  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mg, l_dt, sysdate, l_user, l_cd
   from dual;


  for c in (select t.* from saldo_usl t where t.mg=l_mg_sal and exists
                    (select * from kmp_lsk m where m.lsk=t.lsk)) loop


  --сальдо
  --снять с УК
  insert into c_change
    (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id,
     doc_id)
    select t.lsk, t.usl, t.org, -1*t.summa, l_mg as mgchange, '999' as nkom, 0 as type,
     l_dt, sysdate, l_user, l_id
     from saldo_usl t where t.lsk=c.lsk;

  l_dst_lsk:=p_houses.find_unq_lsk(p_reu => l_dst_uk, p_lsk => null);

  --поставить на новый лс в УК
  insert into c_change
    (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id,
     doc_id)
    select l_dst_lsk, t.usl, t.org, t.summa, l_mg as mgchange, '999' as nkom, 0 as type,
     l_dt, sysdate, l_user, l_id
     from saldo_usl t where t.lsk=c.lsk;



  null;

  end loop;

end;*/

/*procedure move_kart_pr(p_lsk in kart.lsk%type) is
begin

 for c in (select * from kart k, v_lsk_tp tp where
     k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
     ) loop
     move_kart_pr_lsk(c.lsk);

 end loop;


end;  */

-- перенести проживающих из основного лс. на дополнительный
/*procedure move_kart_pr_lsk(p_lsk in kart.lsk%type) is
begin

  delete from c_states_pr_kmp s;


  insert into c_states_pr_kmp
    (id, fk_status, fk_kart_pr, dt1, dt2, fk_tp)
  select id, fk_status, fk_kart_pr, dt1, dt2, fk_tp
  from c_states_pr s where exists
  (select t.* from c_KART_pr t where t.lsk=p_lsk
   and t.id=s.id
  );

  delete from c_kart_pr_kmp t where t.lsk=p_lsk;
  insert into c_kart_pr_kmp
  select id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n, dok_d, dok_v, dat_prop, dat_ub, relat_id, old_id, status_dat, status_chng, k_fam, k_im, k_ot, fk_doc_tp, fk_nac, b_place, fk_frm_cntr, fk_frm_regn, fk_frm_distr, frm_town, frm_dat, fk_frm_kul, frm_nd, frm_kw, w_place, fk_ub, fk_to_cntr, fk_to_regn, fk_to_distr, to_town, fk_to_kul, to_nd, to_kw, fk_citiz, fk_milit, fk_milit_regn, status_datb, fk_deb_org, priv_proc
  from c_kart_pr t where t.lsk=p_lsk;

  delete from c_states_sch s;
  delete from KART t where t.lsk=p_lsk;
  delete from arch_KART t where t.lsk=p_lsk and t.mg='201710';

  insert into C_KART_PR
  select
  t.id, k2.lsk, t.fio, t.status, t.dat_rog, t.pol, t.dok, t.dok_c, t.dok_n, t.dok_d, t.dok_v, t.dat_prop, t.dat_ub,
  t.relat_id, t.old_id, t.status_dat, t.status_chng, t.k_fam, t.k_im, t.k_ot, t.fk_doc_tp, t.fk_nac, t.b_place,
  t.fk_frm_cntr, t.fk_frm_regn, t.fk_frm_distr, t.frm_town, t.frm_dat, t.fk_frm_kul, t.frm_nd, t.frm_kw, t.w_place,
  t.fk_ub, t.fk_to_cntr, t.fk_to_regn, t.fk_to_distr, t.to_town, t.fk_to_kul, t.to_nd, t.to_kw, t.fk_citiz,
  t.fk_milit, t.fk_milit_regn, t.status_datb, t.fk_deb_org, t.priv_proc
  from C_KART_PR_kmp t, kart_kmp k, kart k2, v_lsk_tp tp
  where t.lsk=k.lsk and k.k_lsk_id=k2.k_lsk_id
  and k2.psch not in (8,9) and k2.fk_tp=tp.id
  and tp.cd='LSK_TP_ADDIT'
  and t.lsk=p_lsk;

  insert into c_states_pr
    (id, fk_status, fk_kart_pr, dt1, dt2, fk_tp)
  select id, fk_status, fk_kart_pr, dt1, dt2, fk_tp
  from c_states_pr_kmp s;


end;
*/

-- создать РСО лиц.счета по списку, внести сальдо
/*  Л.Н. я в Новую папку скинула файл "База из ЭкоТэк для обработки в Direct 1". 
Добавляем на новую УК ООО "ЭкоТек с типом РСО": Район, Улица, дом ,кв, ФИО(собственник), 
прописано(как договаривались добавляем пустые строчки П.З.), Сальдо на начало месяца (Сальдо вх.),
 Оплату (поидее нужно сделать зачетом операцией 84, если можно конечно, просто их там много, 
 если нет, то сами введем). В карточки добавить услугу 140 на поставщика 846. */
 
procedure cr_rso_lsk_by_list is 
 l_flag number;
 l_lsk kart.lsk%type;
 l_mg params.period%type;
 l_cd varchar2(100);
 l_dt date;
 l_user number;
 l_id number;
begin
  dbms_output.enable(100000000);
  l_mg:='201810'; --тек.период
  l_cd:='cr_rso_lsk_by_list1';
  l_dt:=to_date('20181031','YYYYMMDD');

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from c_change t where 
    exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.doc_id);
  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mg, l_dt, sysdate, l_user, l_cd
   from dual;

  for c in (select distinct t.kul2, t.nd2, t.kw2, t.fam, t.im, substr(t.ot,1,14) as ot, t.sal2, t.prop2 from kmp_lsk3 t 
    /*where 
      (t.kul='0127' and t.nd2='000003' and t.kw2='0000058' or
      t.kul='0150' and t.nd2='000002' and t.kw2='0000053')*/
      ) loop
    l_flag:=0;
    for c2 in (select * from kart k, v_lsk_tp tp
       where k.kul=c.kul2 and k.nd=c.nd2 and k.kw=c.kw2 and k.fk_tp=tp.id
        order by decode(k.psch,8,1,9,1,0), tp.npp -- приоритет - не закрытому и основному ЛС
         )  loop
      l_flag:=1;
      -- найдена квартира - создать лиц счет РСО
      l_lsk:=kart_lsk_special_add(c2.lsk, 'LSK_TP_RSO', 0, '108', null, null, null, null, null, null, c.prop2, c.sal2, l_id, l_user); 
      exit;
    end loop;
    if l_flag = 0 then
      -- не найдена квартира - создать
      l_lsk:=kart_lsk_special_add(null, 'LSK_TP_RSO', 0, '108', c.kul2, c.nd2, c.kw2, c.fam, c.im, c.ot, c.prop2, c.sal2, l_id, l_user); 
    end if;
    
  end loop;  

end;


function kart_lsk_special_add(p_lsk in kart.lsk%type,-- лс источника
         p_lsk_tp in varchar2, -- тип нового лс
         p_forced_status in number, -- принудительно установить статус (null - не устанавливать, 0-открытый и т.п.)
         p_reu in varchar2, -- применить данный код УК
         p_kul in varchar2,
         p_nd in varchar2,
         p_kw in varchar2,
         p_fam in varchar2,
         p_im in varchar2,
         p_ot in varchar2,
         p_cnt_prop in number, -- кол-во проживающих
         p_sal in number, -- начальное сальдо
         p_doc in number,
         p_user in number
         ) return kart.lsk%type is
  l_lsk kart.lsk%type;
  l_klsk kart.k_lsk_id%type;
  l_cnt number;
  i number;
  l_mg params.period%type;
  l_dt date;
begin
  l_mg:='201810'; --тек.период
  l_dt:=to_date('20181031','YYYYMMDD');
  
  if p_lsk is not null then
    select t.k_lsk_id into l_klsk from kart t where t.lsk=p_lsk;
  else
    l_klsk:=0;
  end if;    

  l_lsk:=p_houses.find_unq_lsk(p_reu, null);

  dbms_output.put_line(l_lsk);
  
  begin
    select 1 into l_cnt
     from dual where regexP_like(l_lsk,'[[:digit:]]{8}')
     and length(l_lsk)=8
     and not exists (select * from kart k where k.lsk=l_lsk);
  exception
    when no_data_found then
     Raise_application_error(-20000, 'Формат ЛС некорректный:'||l_klsk);
  end;
    
  --выполнить проверку на наличие открытого дополнительного счета в данном УК
  select count(*) into l_cnt from kart k, params p, v_lsk_tp tp
   where k.fk_tp=tp.id --and p.period between k.mg1 and k.mg2
   and k.k_lsk_id=l_klsk and k.psch not in (8,9)
   and tp.cd=p_lsk_tp and k.reu=p_reu;
  if l_cnt > 0 then
   Raise_application_error(-20000, 'По данному лиц.счету уже существует РСО:'||l_klsk);
  end if;
  
  if p_lsk is not null then
    -- присоединение к существующему лс
    insert into kart k (lsk, reu, kul, nd, kw, fio, k_fam, k_im, k_ot, psch, 
      status, kfg, kfot, house_id, k_lsk_id, c_lsk_id, mg1, mg2, fk_tp, kpr, kpr_wr, 
       kpr_ot, opl, entr, et)
    select l_lsk, p_reu, k.kul, k.nd, k.kw, k.fio, k.k_fam, k.k_im, k.k_ot,
      k.psch, k.status, 2 as kfg, 2 as kfot, k.house_id, k.k_lsk_id, k.c_lsk_id, 
      p.period as mg1, '999999' as mg2, tp.id as fk_tp, 0 as kpr, 0 as kpr_wr,
       0 as kpr_ot, k.opl, k.entr, k.et
      from kart k, params p, v_lsk_tp tp
      where k.lsk=p_lsk
      and tp.cd=p_lsk_tp;
  else 
    -- новый лс РСО
    insert into c_lsk (id)
      values (c_lsk_id.nextval);
    insert into k_lsk (id, fk_addrtp)
       select k_lsk_id.nextval, u.id
       from u_list u, u_listtp tp
       where
       u.cd='flat' and tp.cd='object_type';

    -- создать квартиру   
    insert into kart k (lsk, reu, kul, nd, kw, k_fam, k_im, k_ot, psch, 
      status, kfg, kfot, house_id, k_lsk_id, c_lsk_id, mg1, mg2, fk_tp, kpr, kpr_wr, 
       kpr_ot, opl)
    select l_lsk, p_reu, p_kul, p_nd, p_kw, p_fam, p_im, p_ot,
      0 as psch, 2 as status, 2 as kfg, 2 as kfot, h.id, k_lsk_id.currval, c_lsk_id.currval, 
      p.period as mg1, '999999' as mg2, tp.id as fk_tp, 0 as kpr, 0 as kpr_wr,
       0 as kpr_ot, 0 as opl
      from (select max(t.id) as id, t.kul, t.nd from c_houses t group by t.kul, t.nd) h, params p, v_lsk_tp tp
      where tp.cd=p_lsk_tp
      and h.kul=p_kul and h.nd=p_nd
      ;
      if sql%rowcount=0 then
       Raise_application_error(-20000, 'Добавление ЛС произошло неудачно, лиц.счет не добавлен! kul='||p_kul||' nd='||p_nd);
      end if;   

    -- добавить проживающих  
      i:=1;
      while i <= p_cnt_prop 
      loop
        if i=1 then
          -- собственник
          for c3 in (select * from relations r where trim(r.cd)='Собственник') loop
            insert into c_kart_pr
            (id, lsk, k_fam, k_im, k_ot, status, pol, relat_id)
            values
            (scott.kart_pr_id.nextval, l_lsk, p_fam, p_im, p_ot, 1, 1, c3.id);
          end loop;  
        else
          -- прочие проживающие
          for c3 in (select * from relations r where trim(r.cd)='Другие') loop
            insert into c_kart_pr
            (id, lsk, status, pol, relat_id)
            values
            (scott.kart_pr_id.nextval, l_lsk, 1, 1, c3.id);
          end loop;  
            
        end if;
         -- статусы прописки
         insert into c_states_pr
           (fk_status, fk_kart_pr, dt1, dt2)
         values
           (1, scott.kart_pr_id.currval, null, null);
        i:=i+1;          
        
      end loop;
      
      
  end if;    
  
   -- наборы услуг
   insert into nabor
      (lsk, usl, org, koeff, norm, fk_vvod)
   select l_lsk, '140' as usl, 846 as org, 1 as koeff, null as norm, null as fk_vvod
      from dual;

   -- начальное сальдо         
   insert into c_change(lsk,
                        usl,
                        summa,
                        mgchange,
                        nkom,
                        org,
                        type,
                        dtek,
                        ts,
                        user_id,
                        doc_id)
   select l_lsk, '140' as usl, p_sal, '201810', '999', 846 as org, 1 as type, l_dt, sysdate, p_user, p_doc
       from dual;

   -- установить статус нового лс (открытый, закрытый)
   if p_forced_status is not null then
     insert into c_states_sch
       (lsk, fk_status, dt1, dt2)
     select l_lsk, 
     p_forced_status as fk_status,
     init.get_dt_start, null
     from dual;
   end if;  
   return l_lsk;
end;


-- перенести сальдо по пене с УК на УК
procedure swap_sal_PEN is
  mg_ params.period%type;
  user_id_ number;
  dat_ date;
  fk_doc_ number;
  l_cd c_change_docs.cd_tp%type;
begin
--период, сальдо по которому смотрим
mg_:='201811';
--Дата переброски
dat_:=to_date('01122018','DDMMYYYY');
--CD переброски
l_cd:='swap_sal_PEN_'||to_char(dat_,'DDMMYYYY')||'_1';

select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from c_pen_corr t where
  exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);

delete from c_change_docs t where t.cd_tp=l_cd;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (mg_, dat_, sysdate, user_id_, l_cd)
  returning id into fk_doc_;

for c in (select k.lsk, s2.org, s2.usl,
   k1.lsk as newlsk, s2.summa as summa
     from (select usl, org, lsk, sum(t.poutsal) as summa from xitog3_lsk t where
      t.mg=mg_ --взять сальдо
      and t.usl='026'
      group by usl, org, lsk) s2, kart k, kart k1
    where 
    k.lsk=s2.lsk
    and k.k_lsk_id=k1.k_lsk_id
    and k1.reu='100' -- УК назначения
    and k1.psch not in (8,9)
    --and exists (select * from prep_lsk t where t.lsk=k.lsk) -- ЛС источника
    and k.reu in ('011','065','095','013','066','086','082','085','096','059','087','084',
      '073','014','015','024','076','090','038','063','036') -- УК источника
    and nvl(s2.summa,0) <> 0
    )
loop

--по старым л.с. -снять
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.lsk, -1*c.summa, mg_ as dopl, dat_ as dtek,  
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, c.org from 
   dual t, t_user u where u.cd=user;

--по новым л.с. - поставить
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.newlsk, c.summa, mg_ as dopl, dat_ as dtek,  
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, c.org from 
   dual t, t_user u where u.cd=user;

end loop;

 

commit;

end swap_sal_pen;

-- снять пеню или перенести на другое УК
procedure swap_sal_PEN2 is
  mg_ params.period%type;
  user_id_ number;
  dat_ date;
  fk_doc_ number;
  l_cd c_change_docs.cd_tp%type;
begin
--период, сальдо по которому смотрим
mg_:='201901';
--Дата переброски
dat_:=to_date('01012019','DDMMYYYY');
--CD переброски
l_cd:='swap_sal_PEN_'||to_char(dat_,'DDMMYYYY')||'_1';

select t.id into user_id_ from t_user t where t.cd='SCOTT';

delete from c_pen_corr t where
  exists (select * from c_change_docs d where d.id=t.fk_doc and
  d.cd_tp=l_cd);

delete from c_change_docs t where t.cd_tp=l_cd;

insert into c_change_docs
  (mgchange, dtek, ts, user_id, cd_tp)
values
  (mg_, dat_, sysdate, user_id_, l_cd)
  returning id into fk_doc_;

for c in (select k.lsk, s2.org, s2.usl,
   k1.lsk as newlsk, s2.summa as summa
     from (select usl, org, lsk, sum(t.poutsal) as summa from xitog3_lsk t where
      t.mg=mg_ --взять сальдо
      --and t.usl='026'
      group by usl, org, lsk) s2 join kart k on k.lsk=s2.lsk
      left join kart k1 on k.k_lsk_id=k1.k_lsk_id and k1.reu='XXX' and k1.psch not in (8,9) -- УК назначения, если стоит k1.reu='XXX', то снять в никуда
    where 
    exists (select * from kmp_lsk t where t.lsk=k.lsk) -- ЛС источника
    --and k.reu in ('011','065','095','013','066','086','082','085','096','059','087','084',
     -- '073','014','015','024','076','090','038','063','036') -- УК источника
    and nvl(s2.summa,0) <> 0
    )
loop

--по старым л.с. -снять
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.lsk, -1*c.summa, mg_ as dopl, dat_ as dtek,  
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, c.org from 
   dual t, t_user u where u.cd=user;

if c.newLsk is not null then
--по новым л.с. - поставить
  insert into c_pen_corr
    (lsk, penya, dopl, dtek, ts, fk_user, fk_doc, usl, org)
  select c.newlsk, c.summa, mg_ as dopl, dat_ as dtek,  
   sysdate as ts, u.id as fk_user, fk_doc_, c.usl, c.org from 
   dual t, t_user u where u.cd=user;
end if;

end loop;

 

commit;

end swap_sal_pen2;

-- перенести сальдо с Основного лиц.счета на счет РСО (Полыс)
-- ред. 26.12.18
procedure swap_sal_from_main_to_rso is
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
  l_mg:='201812'; --тек.период
  l_cd:='swap_sal_from_main_to_RSO_20181226';
  l_mgchange:=l_mg;
  l_dt:=to_date('20181226','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

  for c in (select k.lsk as lskFrom, k2.lsk as lskTo, a.usl as uslFrom, a.org as orgFrom, n.usl as uslTo, n.org as orgTo, 
        a.summa
         from kart k join kart k2 on k.k_lsk_id=k2.k_lsk_id and k2.psch not in (8,9) and k2.fk_tp=3861849
         join 
         (select s.lsk, s.usl, s.org, sum(s.summa) as summa from (
           select t.lsk, t.usl, t.org, t.summa from saldo_usl_script t where t.mg='201901'
           and t.usl in ('007','056','015','058') and t.org not in (2,7)
           union all
           select t.lsk, t.usl, t.org, -1*t.summa as summa from t_corrects_payments t join
              c_change_docs d on t.fk_doc=d.id and d.cd_tp='dist_saldo_polis_201812'
               where t.mg='201812' and t.usl in ('007','056','015','058') and t.org not in (2,7)
               ) s
          group by s.lsk, s.usl, s.org) a on k.lsk=a.lsk and a.summa<>0
         left join nabor n on k2.lsk=n.lsk and n.usl=a.usl
        where k.psch not in (8,9) and k.fk_tp=673012

        and not exists (select * from c_penya p  -- где нет задолженности ранее 2018.12
        where p.lsk=k.lsk and p.mg1<'201812' and p.summa > 0)) loop
        
      -- снять
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lskFrom, c.uslFrom, c.orgFrom,
        c.summa,
        uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
      -- поставить                  
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lskTo, c.uslTo, c.orgTo,
        -1*c.summa,
        uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
  end loop;      
commit;
end swap_sal_from_main_to_rso;


-- перенести сальдо с Основного лиц.счета на счет РСО (Полыс)
-- ред. 29.01.19
procedure swap_sal_from_main_to_rso2 is
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
  l_mg:='201901'; --тек.период
  l_cd:='swap_sal_from_main_to_RSO2_20190129';
  l_mgchange:=l_mg;
  l_dt:=to_date('20190129','YYYYMMDD');
  l_mg3:=utils.add_months_pr(l_mg,1); --месяц вперед

  select t.id into l_user from t_user t where t.cd='SCOTT';
  select changes_id.nextval into l_id from dual;

  delete from t_corrects_payments t where mg=l_mg
   and exists (select * from c_change_docs d where
    d.cd_tp=l_cd and d.id=t.fk_doc);

  delete from c_change_docs t where t.user_id=l_user and t.cd_tp=l_cd;

  insert into c_change_docs (id, mgchange, dtek, ts, user_id, cd_tp)
   select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd
   from dual;

for c in (select k.lsk as lskFrom, k2.lsk as lskTo, a.usl, a.org, 
        a.summa
         from kart k join kart k2 on k.k_lsk_id=k2.k_lsk_id and k2.psch not in (8,9) and k2.fk_tp=3861849 and k2.reu='014' -- на открытый, РСО
         join 
         (select s.lsk, s.usl, s.org, sum(s.summa) as summa from (
           select t.lsk, t.usl, t.org, t.summa from saldo_usl_script t where t.mg='201902'
           and t.usl in ('007','056','015','058')
               ) s
          group by s.lsk, s.usl, s.org) a on k.lsk=a.lsk and a.summa < 0
        where k.psch in (8,9) and k.fk_tp=673012 and k.reu='013' -- с закрытых, Основных
        and k.house_id in (40106, 40126)
) loop
        
      -- снять
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lskFrom, c.usl, c.org,
        c.summa,
        uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
      -- поставить                  
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lskTo, c.usl, 4 as org,
        -1*c.summa,
        uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
  end loop; 
  
for c in (select k.lsk as lskFrom, k2.lsk as lskTo, a.usl, a.org, 
        a.summa
         from kart k join kart k2 on k.k_lsk_id=k2.k_lsk_id and k2.psch not in (8,9) and k2.fk_tp=673012 and k2.reu='002' -- на открытый, Основной
         join 
         (select s.lsk, s.usl, s.org, sum(s.summa) as summa from (
           select t.lsk, t.usl, t.org, t.summa from saldo_usl_script t where t.mg='201902'
           and t.usl in ('011','057','013','059','104','105')
               ) s
          group by s.lsk, s.usl, s.org) a on k.lsk=a.lsk and a.summa < 0
        where k.psch in (8,9) and k.fk_tp=673012 and k.reu='013' -- с закрытых, Основных
        and k.house_id in (40106, 40126)
) loop
        
      -- снять
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lskFrom, c.usl, c.org,
        c.summa,
        uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
      -- поставить                  
      insert into t_corrects_payments
        (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        select c.lskTo, c.usl, case when c.usl in ('011','057','013','059') then 7 else 2 end as org,
        -1*c.summa,
        uid, l_dt, l_mg, l_mg, l_id, 0 as var from dual;
  end loop; 
  
       
commit;
end swap_sal_from_main_to_rso2;

end scripts2;
/


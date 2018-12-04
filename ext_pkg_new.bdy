CREATE OR REPLACE PACKAGE BODY SCOTT.ext_pkg_new

IS
--Пакет обмена с внешним сервером личного кабинета
--вызов из JOB:
--  begin
--
--   scott.ext_pkg_new.imp_vol_all;
--    scott.ext_pkg_new.exp_base(1, null, null);
--  end;
--для того чтобы новый л.с. появился в базе, необходимо
--чтобы отработали процедуры
--imp_vol_all
--exp_base(1, null, null)
--и опять imp_vol_all (чтобы уже загрузить показания счетчиков



procedure exp_base(var_ in number, p_mg1 in params.period%type, p_mg2 in params.period%type)
is
 org_ t_org.id%type;
 cd_org_ t_org.cd%type;
-- l_list u_list.id%type;
 l_cd_listtp u_listtp.cd%type;
 l_mg params.period%type;
 l_mg2 params.period%type;
 l_p_mg1 params.period%type;
 l_p_mg2 params.period%type;
 a number;
 l_cnt_new_lsk number;
-- type empcurtyp is ref cursor;
-- cur1 empcurtyp;

begin
begin

execute immediate'ALTER SESSION SET TIME_ZONE = ''+7:0''';

--ЕЖЕдневный/ежеминутный экспорт базы,
--Л/С, показаний счетчиков
--на удаленную систему APEX
init.set_user;

if utils.get_int_param('HAVE_LK') = 0 then
 --Если отсутствует функция личного кабинета - выход
  logger.log_(null, 'Apex_new: - Личный кабинет не установлен,- обмен запрещен!');
  return;
end if;


select o.id, o.cd into org_, cd_org_
 from scott.t_org o, scott.t_org_tp tp
where tp.id=o.fk_orgtp and tp.cd='РКЦ';

if ext_pkg_new.is_lst(cd_org_) = 1 and
   c_charges.trg_proc_next_month = 0 then
  --или последние 2 дня месяца И не идёт переход месяца!!!-  обмен запрещен!
  logger.log_(null, 'Apex_new: - база закрыта или последний день месяца,- обмен запрещен!');
  return;
end if;

--текущий период
select p.period into l_mg from scott.params p;

l_cd_listtp:='Параметры лиц.счета';

--тип параметра "пароль"
/*select u.id into l_list from scott.u_list u, scott.u_listtp tp
    where u.fk_listtp=tp.id
    and u.cd='pass'
    and tp.cd=l_cd_listtp;*/

--расчет долгов, пени по л/c
--выполнять - вначале (после приёмки счетчиков), так как нетранзакционно (коммит внутри)
--и счетчики должны быть учтены
--####
if to_char(trunc(sysdate),'YYYYMM') <> l_mg then
  a:=scott.init.set_date(last_day(to_date(l_mg||'01','YYYYMMDD'))); --последняя дата текущего периода...
else
  a:=scott.init.set_date(trunc(sysdate)); --текущая дата...
end if;


--получаем кол-во л.с. необходимых для обновления (новых)
execute immediate 'select nvl(count(*),0)
   from scott.kart k where
/*     exists
    (select * from scott.t_objxpar x where x.fk_k_lsk=k.k_lsk_id --только там, где установлен параметр login-pass  --УБРАЛ ЭТО Ред. 12.12.2014
     and x.fk_list=:l_list)
    and */not exists
    (select * from t_obj@Apex_new t, t_org@Apex_new o, t_org@Apex_new o2 where t.lsk=k.lsk
      and t.fk_org=o2.id and o2.parent_id=o.id
      and o.cd=:cd_org_)'
      into l_cnt_new_lsk using cd_org_ ;

if p_mg1 is not null then
  --если заданы принудительно периоды загрузки архива
   l_p_mg1:=p_mg1;
   l_p_mg2:=p_mg2;
elsif l_cnt_new_lsk <> 0 and 1=2 then  --пока отключил такую возможность, так как всегда грузится вся база! ред. 20.12.14
  --если не заданы принудительно периоды загрузки архива,
  --но найдены новые л.с. (получившие пароль), по которым нужно загрузить архив
  execute immediate
    'select min(t.mg), max(t.mg) from t_mg@Apex_new t, t_org@Apex_new o, scott.params p
       where t.mg<>p.period and t.fk_org=o.id
       and o.cd=:cd_org_'
    into l_p_mg1, l_p_mg2 using cd_org_;
end if;

logger.log_(null, 'Apex_new: подготовка начисления, задолжности по л/с-начало');
logger.log_(null, 'Apex_new: ОТЧКЛЮЧЕНА ПОДГОТОВКА НАЧИСЛЕНИЯ!!!!!!!!!!!');

for c in (select k.lsk
 from scott.kart k, scott.t_org o where k.reu=o.reu
/*   exists
  (select * from scott.t_objxpar x where x.fk_k_lsk=k.k_lsk_id --только там, где установлен параметр login-pass --УБРАЛ ЭТО Ред. 12.12.2014
   and x.fk_list=l_list) */
   )
loop --всё c коммитом, так как нет опасности потерять целостность информации по счетчикам!
/*  a:=scott.c_charges.gen_charges(c.lsk, c.lsk, null, null, 1, 0);
  scott.c_cpenya.gen_charge_pay(c.lsk, 1);
  scott.c_cpenya.gen_penya(c.lsk, 0, 1);
*/
null;
end loop;
logger.log_(null, 'Apex_new: подготовка начисления, задолжности по л/с-окончание');
--####

if var_ = 1 then
  --экспорт улиц
  --только ежедневный обмен
  logger.log_(null, 'Apex_new: экспорт справочника улиц-начало');
  execute immediate 'delete from imp_street@Apex_new t
   where t.cd_org=:cd_org_'
   using cd_org_;

  execute immediate 'insert into imp_street@Apex_new
    (kul, cd_org, name)
  select
    t.id, :cd_org_, t.name
    from scott.spul t'
   using cd_org_;
  logger.log_(null, 'Apex_new: экспорт справочника улиц-окончание, отправлено строк: '||to_char(SQL%ROWCOUNT));


  --экспорт справочника услуг
  logger.log_(null, 'Apex_new: экспорт справочника услуг-начало');

  execute immediate 'delete from imp_usl@Apex_new';
  execute immediate 'insert into imp_usl@Apex_new
    (uslm, usl, kartw, kwni, lpw, ed_izm, nm, nm1, usl_p, sptarn, usl_type, usl_plr, usl_norm, typ_usl, usl_order, usl_type2, usl_subs, nm2, nm3, cd, npp, fk_calc_tp, uslg, counter, have_vvod, n_progs, fk_usl_pen, can_vv, is_iter, max_vol, fk_usl_chld)
  select uslm, usl, kartw, kwni, lpw, ed_izm, nm, nm1, usl_p, sptarn, usl_type, usl_plr, usl_norm, typ_usl, usl_order, usl_type2, usl_subs, nm2, nm3, cd, npp, fk_calc_tp, uslg, counter, have_vvod, n_progs, fk_usl_pen, can_vv, is_iter, max_vol, fk_usl_chld
   from scott.usl';

  logger.log_(null, 'Apex_new: экспорт справочника услуг-окончание, отправлено строк: '||to_char(SQL%ROWCOUNT));

  --экспорт справочника организаций
  logger.log_(null, 'Apex_new: экспорт справочника организаций-начало');

  execute immediate 'delete from imp_t_org@Apex_new';
  execute immediate 'insert into imp_t_org@Apex_new
    (id, cd, fk_orgtp, name, npp, v, parent_id, reu, trest, uch, adr,
     inn, manager, buh, raschet_schet, k_schet, kod_okonh, kod_ogrn,
     bik, phone, kpp, bank, id_exp, adr_recip, authorized_dir, authorized_buh,
     auth_dir_doc, auth_buh_doc, okpo, ver_cd, full_name, phone2, parent_id2, fk_org2, bank_cd, email)
  select id, cd, fk_orgtp, name, npp, v, parent_id, reu, trest, uch, adr,
  inn, manager, buh, raschet_schet, k_schet, kod_okonh, kod_ogrn, bik, phone,
  kpp, bank, id_exp, adr_recip, authorized_dir, authorized_buh, auth_dir_doc,
  auth_buh_doc, okpo, ver_cd, full_name, phone2, parent_id2, fk_org2, bank_cd, email
  from scott.t_org';

  logger.log_(null, 'Apex_new: экспорт справочника организаций-окончание, отправлено строк: '||to_char(SQL%ROWCOUNT));

  --экспорт типов организаций
  --только ежедневный обмен
  logger.log_(null, 'Apex_new: экспорт справочника типов организаций');
  execute immediate 'delete from imp_t_org_tp@Apex_new t';

  execute immediate 'insert into imp_t_org_tp@Apex_new
    (id, cd, name, npp, v, parent_id, type, menu_id, name_0, name_1, comm)
  select id, cd, name, npp, v, parent_id, type, menu_id, name_0, name_1, comm
    from scott.t_org_tp t';
  logger.log_(null, 'Apex_new: экспорт справочника типов организаций-окончание, отправлено строк: '||to_char(SQL%ROWCOUNT));

  --экспорт справочника компьютеров
  logger.log_(null, 'Apex_new: экспорт справочника компьютеров-начало');

  execute immediate 'delete from imp_c_comps@Apex_new';
  execute immediate 'insert into imp_c_comps@Apex_new
  (nkom, nink, nkvit, cd, fk_oper, fk_org)
  select nkom, nink, nkvit, cd, fk_oper, fk_org
    from scott.c_comps';
   logger.log_(null, 'Apex_new: экспорт справочника компьютеров-окончание, отправлено строк: '||to_char(SQL%ROWCOUNT));


  --только ежедневный обмен
  logger.log_(null, 'Apex_new: экспорт параметров LSK, K_LSK-начало');

    delete from scott.exp_kartxpar;
    insert into scott.exp_kartxpar
    (cd_org, fk_k_lsk, cd_list, s1, d1, n1, c1, pass)
    select cd_org_, k.fk_k_lsk, u.cd, k.s1, k.d1, k.n1, k.c1, k.pass
     from scott.t_objxpar k, scott.u_list u, scott.u_listtp tp where
     k.fk_list=u.id and u.fk_listtp=tp.id
     and tp.cd=l_cd_listtp
/*     and exists
    (select * from scott.t_objxpar x where x.fk_k_lsk=k.fk_k_lsk --только там, где установлен параметр login-pass  --УБРАЛ ЭТО Ред. 12.12.2014
     and x.fk_list=l_list)*/
     ;

  execute immediate 'delete from imp_kartxpar@Apex_new t
   where t.cd_org=:cd_org_'
   using cd_org_;
  execute immediate 'insert into imp_kartxpar@Apex_new
    (cd_org, fk_k_lsk, cd_list, s1, d1, n1, c1, pass)
    select :cd_org_, fk_k_lsk, cd_list, s1, d1, n1, c1, pass
    from scott.exp_kartxpar t'
    using cd_org_;

  logger.log_(null, 'Apex_new: экспорт параметров LSK, K_LSK-окончание, отправлено строк: '||to_char(SQL%ROWCOUNT));

  logger.log_(null, 'Apex_new: экспорт наличия услуг-начало');
  delete from scott.exp_nabor;
  insert into scott.exp_nabor
   (lsk, cd_usl)
  select n.lsk, u.usl  from scott.kart k, scott.nabor n, scott.usl u
    where
    k.lsk = n.lsk and case
             when u.sptarn = 0 and nvl(n.koeff, 0) <> 0 then
              1 --определяем наличие услуги в л.с.
             when u.sptarn = 1 and nvl(n.norm, 0) <> 0 then
              1
             when u.sptarn = 2 and nvl(n.koeff, 0) <> 0 and nvl(n.norm, 0) <> 0 then
              1
             when u.sptarn = 3 and nvl(n.koeff, 0) <> 0 and nvl(n.norm, 0) <> 0 then
              1
             else
              0
           end = 1
    and n.usl=u.usl
    and case
    when u.cd = 'х.вода' and k.psch in (1,2) then 1
    when u.cd = 'г.вода' and k.psch in (1,3) then 1
    when u.cd = 'эл.энерг.' and k.psch not in (8,9) then 1
    when u.cd = 'эл.энерг.2' and k.psch not in (8,9) then 1
    else 0
    end =1
/*    and exists
    (select * from scott.t_objxpar x where x.fk_k_lsk=k.k_lsk_id
     and x.fk_list=l_list)*/ --УБРАЛ ЭТО Ред. 12.12.2014
     ;

  execute immediate 'delete from imp_nabor@Apex_new t
   where t.cd_org=:cd_org_'
   using cd_org_;

  execute immediate 'insert into imp_nabor@Apex_new t
   (lsk, cd_org, cd_usl)
   select n.lsk, :cd_org_, n.cd_usl from scott.exp_nabor n'
   using cd_org_;
  logger.log_(null, 'Apex_new: экспорт наличия услуг-окончание, отправлено строк: '||to_char(SQL%ROWCOUNT));

  logger.log_(null, 'Apex_new: загрузка текущих долгов по л/c-начало');
   --текущие долги, с пенёй на текущую дату
  --здесь должен быть где то расчёт пени на текущий день...
  execute immediate 'delete from imp_debit@Apex_new t';

  execute immediate 'insert into imp_debit@Apex_new t
   (lsk, db, pn, chrg, pay, paypn, mg)
   select m.lsk, t.summa as db, t.penya as pn, c.summa as chrg,
     c2.summa as pay, c2.summap as pay_pen, m.mg
      from (
      select k.lsk, t.mg from scott.kart k, scott.long_table t
/*        where exists
        (select * from scott.t_objxpar x where x.fk_k_lsk=k.k_lsk_id
          and x.fk_list=)*/  --только там, где установлен параметр login-pass --УБРАЛ ЭТО Ред. 12.12.2014
      ) m,
      scott.c_penya t,
      scott.c_chargepay c, scott.c_chargepay c2
      where
      m.mg=c.mg(+) and m.lsk=c.lsk(+) and c.type(+)=0 and c.period(+)='''||l_mg||'''
      and m.mg=c2.mg(+) and m.lsk=c2.lsk(+) and c2.type(+)=1 and c2.period(+)='''||l_mg||'''
      and m.mg=t.mg1(+) and m.lsk=t.lsk(+)';
  logger.log_(null, 'Apex_new: загрузка текущих долгов по л/c-окончание');

  logger.log_(null, 'Apex_new: загрузка движения по л/c-начало');

  --сперва чистим временные таблицы
  execute immediate 'delete from imp_a_charge@Apex_new t';
  execute immediate 'delete from imp_a_change@Apex_new t';
  execute immediate 'delete from imp_a_kwtp@Apex_new t';
  execute immediate 'delete from imp_xitog3_lsk@Apex_new t';
  --сперва текущее
  --начисление
  execute immediate 'insert into imp_a_charge@Apex_new t
    (lsk, usl, summa, kart_pr_id, spk_id, type, test_opl, test_cena, test_tarkoef,
      test_spk_koef, main, mg, lg_doc_id, npp, sch)
    select t.lsk, t.usl, t.summa, t.kart_pr_id, t.spk_id, t.type, t.test_opl,
        t.test_cena, t.test_tarkoef,
        t.test_spk_koef, t.main, p.period as mg, t.lg_doc_id, t.npp, t.sch
        from scott.c_charge t, scott.params p';
/*      where exists
        (select * from scott.t_objxpar x, scott.kart k where x.fk_k_lsk=k.k_lsk_id
          and k.lsk=t.lsk
          and x.fk_list=:l_list)*/ --только там, где установлен параметр login-pass  --УБРАЛ ЭТО Ред. 12.12.2014'
--  using l_list;

  logger.log_(null, 'Apex_new: загрузка движения по л/c-1');

  --изменения
  execute immediate 'insert into imp_a_change@Apex_new t
    (lsk, usl, summa, proc, mgchange, nkom, org, type, dtek,
      ts, user_id, mg, doc_id, cnt_days, show_bill, id)
    select t.lsk, t.usl, t.summa, t.proc, t.mgchange, t.nkom, t.org, t.type, t.dtek,
      t.ts, t.user_id, p.period as mg, t.doc_id, t.cnt_days, t.show_bill, t.id
        from scott.c_change t, scott.params p';
/*      where exists
        (select * from scott.t_objxpar x, scott.kart k where x.fk_k_lsk=k.k_lsk_id
          and k.lsk=t.lsk
          and x.fk_list=:l_list)*/ --только там, где установлен параметр login-pass --УБРАЛ ЭТО Ред. 12.12.2014'
--  using l_list;
  logger.log_(null, 'Apex_new: загрузка движения по л/c-2');
  --оплата
  execute immediate 'insert into imp_a_kwtp@Apex_new t
    (lsk, summa, penya, oper, dopl, nink, nkom, dtek,
      nkvit, dat_ink, ts, id, mg, iscorrect, num_doc, dat_doc)
    select t.lsk, t.summa, t.penya, t.oper, t.dopl, t.nink, t.nkom, t.dtek,
      t.nkvit, t.dat_ink, t.ts, t.id, p.period as mg, t.iscorrect, t.num_doc, t.dat_doc
        from scott.c_kwtp t, scott.params p';
--  using l_list;
  logger.log_(null, 'Apex_new: загрузка движения по л/c-3');


/*  logger.log_(null, 'Apex_new: загрузка оборотки xitog3 по л/c-начало');
  execute immediate 'insert into imp_xitog3_lsk@Apex_new
    (lsk, org, uslm, usl, status, indebet, inkredit, charges, changes, subsid,
    payment, pn, outdebet, outkredit, mg, privs, privs_city, ch_full, changes2, pcharges)
    select lsk, t.org, t.uslm, t.usl, t.status, t.indebet, t.inkredit, t.charges, t.changes, t.subsid, t.
      payment, t.pn, t.outdebet, t.outkredit, t.mg, t.privs, t.privs_city, t.ch_full, t.changes2, t.pcharges
    from scott.xitog3_lsk t, scott.params p where t.mg=p.period';
  logger.log_(null, 'Apex_new: загрузка оборотки xitog3 по л/c-окончание, передано строк='||sql%rowcount);
*/
  --затем архивное (если задано такое)
  l_mg2:=l_p_mg1;
  while l_mg2 <= l_p_mg2 and l_p_mg1 is not null --если задано архивное
  loop
    --начисление
      execute immediate 'insert into imp_a_charge@Apex_new t
        (lsk, usl, summa, kart_pr_id, spk_id, type, test_opl, test_cena, test_tarkoef,
          test_spk_koef, main, mg, lg_doc_id, npp, sch)
        select t.lsk, t.usl, t.summa, t.kart_pr_id, t.spk_id, t.type, t.test_opl,
            t.test_cena, t.test_tarkoef,
            t.test_spk_koef, t.main, :p_mg as mg, t.lg_doc_id, t.npp, t.sch
            from scott.a_charge t
            where t.mg=:p_mg'
    using l_mg2, l_mg2;
    --изменения
    execute immediate 'insert into imp_a_change@Apex_new t
      (lsk, usl, summa, proc, mgchange, nkom, org, type, dtek,
        ts, user_id, mg, doc_id, cnt_days, show_bill, id)
      select t.lsk, t.usl, t.summa, t.proc, t.mgchange, t.nkom, t.org, t.type, t.dtek,
        t.ts, t.user_id, :p_mg as mg, t.doc_id, t.cnt_days, t.show_bill, t.id
          from scott.a_change t
        where t.mg=:p_mg'
     using l_mg2, l_mg2;
  --оплата
  execute immediate 'insert into imp_a_kwtp@Apex_new t
    (lsk, summa, penya, oper, dopl, nink, nkom, dtek,
      nkvit, dat_ink, ts, id, mg, iscorrect, num_doc, dat_doc)
    select t.lsk, t.summa, t.penya, t.oper, t.dopl, t.nink, t.nkom, t.dtek,
      t.nkvit, t.dat_ink, t.ts, t.id, :p_mg as mg, t.iscorrect, t.num_doc, t.dat_doc
        from scott.a_kwtp t
      where t.mg=:p_mg'
     using l_mg2, l_mg2;
  logger.log_(null, 'Apex_new: загрузка движения за период: '||l_mg2||' Отправлено строк по оплате:'||to_char(SQL%ROWCOUNT));

  logger.log_(null, 'Apex_new: загрузка оборотки xitog3 по л/c-начало');
  execute immediate 'insert into imp_xitog3_lsk@Apex_new
    (lsk, org, uslm, usl, status, indebet, inkredit, charges, changes, subsid,
    payment, pn, outdebet, outkredit, mg, privs, privs_city, ch_full, changes2, pcharges)-- здесь пока не стал менять на poutsal ред. 15.01.18
    select lsk, t.org, t.uslm, t.usl, t.status, t.indebet, t.inkredit, t.charges, t.changes, t.subsid, t.
      payment, t.pn, t.outdebet, t.outkredit, t.mg, t.privs, t.privs_city, t.ch_full, t.changes2, t.poutsal
    from scott.xitog3_lsk t where t.mg=:p_mg'
    using l_mg2;
  logger.log_(null, 'Apex_new: загрузка оборотки xitog3 по л/c-окончание, Отправлено строк='||sql%rowcount);

  l_mg2:=to_char(add_months(to_date(l_mg2||'01','YYYYMMDD'), 1), 'YYYYMM');
  end loop;
  logger.log_(null, 'Apex_new: загрузка движения по л/c-окончание');
end if;

  --выполнение импорта на стороне ЛК
  --#################################
  --#################################
  logger.log_(null, 'Apex_new: выполнение импорта на стороне ЛК-начало');
  --загрузить архивную информацию, если это необходимо
  if l_p_mg1 is not null then
    execute immediate 'begin imp_frm_base.imp_all@Apex_new(:var_, :cd_org_, :l_p_mg1, :l_p_mg2); end;'
    using var_, cd_org_, l_p_mg1, l_p_mg2;
  end if;
  --и в любом случае загрузить текущую информацию
  execute immediate 'begin imp_frm_base.imp_all@Apex_new(:var_, :cd_org_, null, null); end;'
  using var_, cd_org_;

  logger.log_(null, 'Apex_new: выполнение импорта на стороне ЛК-окончание');
  --#################################
  --#################################
logger.log_(null, 'Apex_new: ## - ОКОНЧАНИЕ ОБМЕНА');

execute immediate 'begin c_logger.cr_event@Apex_new(:cd_org_,:cd_event, 0, :event_body); end;'
using cd_org_, 'Синхронизация с базой',
'ОКОНЧАНИЕ ОБМЕНА';

 exception when others then
  execute immediate 'begin c_logger.cr_event@Apex_new(:cd_org_,:cd_event, 1, :event_body); end;'
  using cd_org_, 'Синхронизация с базой',
  'Ошибка при получении информации из ЛК: ERRcode - '||SQLCODE||' -ERRmsg- '||SQLERRM;
  logger.raiseError('ext_pkg_new.exp_base');
--  Raise;
end;
commit;
--закрыть DBLINK, чтобы не было ошибки ORA-02049: timeout: distributed transaction waiting for lock

begin
 dbms_session.close_database_link('apex');
exception when others then 
   null; --Да! null!
end;

end;

procedure imp_vol_all is
 cd_org_ t_org.cd%type;
 l_cnt number;
begin
  Raise_application_error(-20000, 'пока закрыто!');

begin
--получение расхода по всем услугам/счетчикам из личного кабинета
execute immediate'ALTER SESSION SET TIME_ZONE = ''+7:0''';
select o.cd into cd_org_
 from scott.t_org o, scott.t_org_tp tp
where tp.id=o.fk_orgtp and tp.cd='РКЦ';

logger.log_(null, 'Apex_new: ## - НАЧАЛО ОБМЕНА');

execute immediate 'begin c_logger.cr_event@Apex_new(:cd_org_,:cd_event, 0, :event_body); end;'
using cd_org_, 'Синхронизация с базой', 'НАЧАЛО ОБМЕНА';

init.set_user;

if ext_pkg_new.is_lst(cd_org_) = 1 and c_charges.trg_proc_next_month = 0 then
  --или последние 2 дня месяца И не идёт переход месяца!!!-  обмен запрещен!
  logger.log_(null, 'Apex_new: - база закрыта или последний день месяца,- обмен запрещен!');
  return;
end if;

logger.log_(null, 'Apex_new: импорт расхода по счетчикам-начало');

--подготовка к выгрузке объемов на стороне ЛК
execute immediate 'begin exp_to_base.exp_sch_vol@Apex_new(:cd_org_); end;'
using cd_org_;

--загрузка расходов в промежуточную таблицу
delete from scott.imp_sch_vol t;

select nvl(count(*),0) into l_cnt from
  scott.imp_sch_vol;

if l_cnt <> 0 then
  logger.log_(null, 'Apex_new: ВНИМАНИЕ! scott.imp_sch_vol не почищен - ОБМЕН ПРЕКРАЩЕН!');
  return;
end if;

execute immediate 'insert into scott.imp_sch_vol t
 (lsk, cd_usl, vol)
 select t.lsk, t.cd_usl, t.vol from exp_sch_vol@Apex_new t
  where t.cd_org=:cd_org_'
 using cd_org_;


--выбираются только те услуги по которым заполнено поле COUNTER
for c in (select u.usl from scott.usl u where trim(u.counter) is not null
   )
loop
 --обновление расходов в kart
 imp_vol_usl(c.usl);

end loop;

--установка флага принятия объемов счетчиков
--выполняется позже в exp_base!!! (иначе пустые значения в ЛК!)
--execute immediate 'begin exp_to_base.acpt_sch_vol@Apex_new(:cd_org_); end;'
--using cd_org_;

 --тут же отправляем новые показания в ЛК, делаем коммит
 exp_vol_all;
exception when others then
  execute immediate 'begin c_logger.cr_event@Apex_new(:cd_org_,:cd_event, 1, :event_body); end;'
  using cd_org_, 'Синхронизация с базой',
  'Ошибка при получении информации из ЛК: в строке: ERRcode - '||SQLCODE||' -ERRmsg- '||SQLERRM;
--  Raise;
  logger.raiseError('ext_pkg_new.imp_vol_all');
end;
 --коммит
commit;

--Здесь это нельзя ставить, так как выполняется неявный коммит, и чистится темповая таблица
--закрыть DBLINK, чтобы не было ошибки ORA-02049: timeout: distributed transaction waiting for lock
--dbms_session.close_database_link('apex');

logger.log_(null, 'Apex_new: импорт расхода по счетчикам-окончание');
end;

procedure exp_vol_all is
-- l_list u_list.id%type;
 l_cd_listtp u_listtp.cd%type;
 cd_org_ t_org.cd%type;
begin
begin
--экспорт л/с, показаний счетчиков (ежедневный и так же и ежеминутный обмен)
--пришлось выгружать в промежуточную таблицу, после чего
--уже отправлять на удаленный сервер
--(на прямую не получилось из за искажения кодировки при использовании
--конструкции case when ....

l_cd_listtp:='Параметры лиц.счета';
select o.cd into cd_org_
 from scott.t_org o, scott.t_org_tp tp
where tp.id=o.fk_orgtp and tp.cd='РКЦ';

if ext_pkg_new.is_lst(cd_org_) = 1 and c_charges.trg_proc_next_month = 0 then
  --или последние 2 дня месяца И не идёт переход месяца!!!-  обмен запрещен!
  logger.log_(null, 'Apex_new: - база закрыта или последний день месяца,- обмен запрещен!');
  return;
end if;

--тип параметра "пароль"
/*select u.id into l_list from scott.u_list u, scott.u_listtp tp  --УБРАЛ ЭТО Ред. 12.12.2014'
    where u.fk_listtp=tp.id
    and u.cd='pass'
    and tp.cd=l_cd_listtp;*/

logger.log_(null, 'Apex_new: экспорт домов-начало');
--экспорт домов
delete from scott.exp_c_houses;
insert into scott.exp_c_houses
  (id, reu, kul, nd, k_lsk_id, cd_org)
select distinct h.id, a.reu, h.kul, h.nd, h.k_lsk_id, o.cd as cd_org
 from scott.c_houses h, scott.t_org o, scott.kart a where a.reu=o.reu
 and h.id=a.house_id;

execute immediate 'delete from imp_c_houses@Apex_new t';

execute immediate 'insert into imp_c_houses@Apex_new t
(id, reu, kul, nd, k_lsk_id, cd_org, psch)
select k.id, k.reu, k.kul, k.nd, k.k_lsk_id, k.cd_org, k.psch
 from scott.exp_c_houses k';
logger.log_(null, 'Apex_new: экспорт домов-окончание');


logger.log_(null, 'Apex_new: экспорт л/с-начало');

delete from scott.exp_kart;
insert into scott.exp_kart t
(k_lsk_id, lsk, cd_org, kul, nd, kw, phw, mhw, pgw, mgw, pel, mel, psch, house_id)
select k.k_lsk_id, k.lsk, o.cd, k.kul,
 k.nd, k.kw,
 k.phw, k.mhw, k.pgw, k.mgw, k.pel, k.mel, k.psch, k.house_id
 from scott.kart k, scott.t_org o where k.reu=o.reu;/* and
   exists
  (select * from scott.t_objxpar x where x.fk_k_lsk=k.k_lsk_id --только там, где установлен параметр login-pass --УБРАЛ ЭТО Ред. 12.12.2014'
   and x.fk_list=l_list);*/

execute immediate 'delete from imp_kart@Apex_new t';

execute immediate 'insert into imp_kart@Apex_new t
(k_lsk_id, lsk, cd_org, kul, nd, kw, phw, mhw, pgw, mgw, pel, mel, psch, house_id)
select k.k_lsk_id, k.lsk, k.cd_org, k.kul,
 k.nd, k.kw,
 k.phw, k.mhw, k.pgw, k.mgw, k.pel, k.mel, k.psch, k.house_id
 from scott.exp_kart k';

logger.log_(null, 'Apex_new: экспорт л/с, отправлено строк: '||to_char(SQL%ROWCOUNT));

logger.log_(null, 'Apex_new: выполнение импорта счетчиков на стороне ЛК-начало');
execute immediate 'begin imp_frm_base.imp_sch_cnt@Apex_new(:cd_org_); end;'
using cd_org_;
logger.log_(null, 'Apex_new: выполнение импорта счетчиков на стороне ЛК-окончание');

logger.log_(null, 'Apex_new: отметка о завершении приема счетчиков на стороне ЛК-начало');
execute immediate 'begin exp_to_base.acpt_sch_vol@Apex_new(:cd_org_); end;'
using cd_org_;
logger.log_(null, 'Apex_new: отметка о завершении приема счетчиков на стороне ЛК-окончание');

exception when others then
  execute immediate 'begin c_logger.cr_event@Apex_new(:cd_org_,:cd_event, 1, :event_body); end;'
  using cd_org_, 'Синхронизация с базой',
  'Ошибка при экспорте информации в ЛК: в строке: ERRcode - '||SQLCODE||' -ERRmsg- '||SQLERRM;
--  Raise;
  logger.raiseError('ext_pkg_new.exp_vol_all');
end;
end;

procedure imp_vol_usl(cd_usl_ in usl.cd%type) is
 fld_ usl.counter%type;
 l_usl_name usl.nm%type;
begin
--получение расхода по услуге/счетчику из ЛК
if utils.get_int_param('HAVE_LK') = 0 then
 --Если отсутствует функция личного кабинета - выход
  logger.log_(null, 'Apex_new: - Личный кабинет не установлен,- обмен запрещен!');
  return;
end if;


select
   u.counter, trim(u.nm) into fld_, l_usl_name
  from scott.usl u where u.usl=cd_usl_;

--проверка на повторный ввод расхода по л/c
logger.log_(null, 'Apex_new: - проверка на повторный ввод расхода по л/c');
for c in (select distinct s.lsk as lsk from scott.imp_sch_vol s,
  scott.t_objxpar t, scott.u_list u, scott.params p
  where t.ts between to_date(p.period||'01','YYYYMMDD') and
  last_day(to_date(p.period||'01','YYYYMMDD'))
  and t.fk_list=u.id
  and u.cd='ins_vol_sch'
  and t.fk_usl=cd_usl_
  and s.cd_usl=cd_usl_
  and s.lsk=t.fk_lsk
)
loop
  logger.log_(null, 'Apex_new: - ПРЕДУПРЕЖДЕНИЕ, по л/c:'||c.lsk||', услуге:'||cd_usl_||':'||trim(l_usl_name)||' в текущем периоде уже был введен расход!');
end loop;

execute immediate 'update scott.kart x
 set x.'||fld_||' = nvl(x.'||fld_||',0) +
  (select nvl(t.vol,0) from scott.imp_sch_vol t
    where t.lsk=x.lsk
    and t.cd_usl=:cd_usl_
    )
  where exists
  (select * from scott.imp_sch_vol t
    where t.lsk=x.lsk
    and t.cd_usl=:cd_usl_
    )'
using cd_usl_,cd_usl_;



end;

function is_lst(p_cd_org in varchar2) return number is
 l_ret number;
begin
--исполняется функция на стороне Apex, возвращается значение
execute immediate 'begin
                    :l_ret:=proc.is_lst_day@Apex_new(:cd_org_, -1);
                   end;'
using out l_ret, in p_cd_org;
return l_ret;
end;

procedure fill_table is
cnt_ number;
dat_ date;
a number;
begin
--тестовая процедура проверки dblink на mysql
--закомментировал, иначе не компилируется
/*
while true
loop
  delete from "test2"@mysql;

  a:=0;
  for c in (select t.id, t.fio as name from c_kart_pr t)
  loop

  insert into "test2"@mysql ("id", "Name")
   values (c.id, c.name);

  a:=a+1;
  if a = 100 then
    select max(t."id")+1 into cnt_ from "par"@mysql t;
    dat_:=sysdate;
    insert into "par"@mysql ("id", "d1")
     values (cnt_, dat_);
  a:=0;
  end if;

  end loop;
  commit;

end loop;
*/
null;
end fill_table;

END ext_pkg_new;
/


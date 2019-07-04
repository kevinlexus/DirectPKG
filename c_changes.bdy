create or replace package body scott.C_CHANGES is
  PROCEDURE clear_changes_proc is
  begin
    --чистка временной таблицы начислений +добавл. стандарных услуг
    delete from list_choices_changes c;
    insert into list_choices_changes (usl_id)
      select usl from usl t;-- where t.usl_norm=0;
  end;

  PROCEDURE gen_changes_proclsk(lsk_   in c_change.lsk%type,
                                summa_ in c_change.summa%type,
                                usl_   in c_change.usl%type,
                                mg_    in c_change.mgchange%type,
                                text_ in varchar2) is
  cnt_ number;
  id_   number;
  begin
  --ЧТО ЭТО?
    --изменения по текущему Л.С.
    --номер нового документа
    select changes_id.nextval into id_ from dual;

    insert into c_change_docs
     (id, mgchange, dtek, ts, user_id, text)
     values
      (id_, mg_, init.get_date(), sysdate, (select u.id
           from t_user u
          where u.cd = user), text_);

    insert into c_change
      (lsk, usl, summa, proc, mgchange, org, type, dtek, ts, user_id, doc_id)
    values
      (lsk_, usl_, summa_, 0, mg_, null, case when nvl(summa_, 0) < 0 then 1 when
        nvl(summa_, 0) > 0 then 2 end, init.get_date(), sysdate, (select u.id
           from t_user u
          where u.cd = user), id_);
    cnt_:=c_charges.gen_charges(lsk_, null, null, null, 0, 0); --пересчет начисления
    commit;
  end;

  FUNCTION test_abs_or_proc return number is
  TYPE rec_result IS RECORD (
      proc1     number,
      proc2     number,
      abs_set   number );
   rec_result_ rec_result;
  begin
    select sum(abs(c.proc1)) as proc1, sum(abs(c.proc2)) as proc2,
      sum(abs(c.abs_set)) as abs_set into rec_result_
      from list_choices_changes c;
    if rec_result_.proc1 <> 0 or rec_result_.proc2 <> 0 then
      return 0; --изменения по процентам
    elsif rec_result_.abs_set <> 0 then
      return 1; --изменения в абс суммах
    else
      return 2; --не заполнено
    end if;
  end;

PROCEDURE gen_changes_proc(lsk_start_ in c_change.lsk%type,
                            lsk_end_   in c_change.lsk%type,
                            mg_        in c_change.mgchange%type,
                            p_mg2        in c_change.mg2%type,
                            usl_add_ in number,
                            is_sch_ in number,
                            l_psch in number,
                            tst_ in number,
                            text_ in varchar2,
                            result_ out number,
                            doc_id_ out number,
                            p_kran1 in number,
                            p_status in number,
                            p_chrg in number,
                            p_kan in number,
                            p_wo_kpr in number, --отсутствие проживающих(1-да, 0, null - нет) (нулевые квартиры) по жел. Кис, 02.12.14!
                            p_lsk_tp_var in number,  --вариант перерасчета (0-только по основным лс., 1 - только по дополнит лс., 2 - по тем и другим)
                            p_tp in number -- тип, 0 - все остальные, 1 - корректировка сальдо
                            )
    is
    cnt_  number;
    cnt1_ number;
    cnt_gen_  number;
    mg2_ c_change.mgchange%type;
    id_   number;
    l_part number;
    l_uid t_user.id%type;
    l_mg params.period%type;
    l_kran1 v_kart.kran1%type;
    l_hbp number; --have back period (флаг) -есть прошлый период, для перерасч.
    l_hcp number; --have current period (флаг) -есть текущий период, для перерасч.
    l_h_usl number; --have especial services (флаг) -есть особые услуги, для перерасч.
    l_one_ls number; --флаг перерасчета только по одному л.с.
    l_wo_kpr number;
    -- кол-во домов для перерасчета
    l_cnt_house number;
    cursor cur_list_choices
    is
    select distinct h.id as house_id
          from list_choices_hs s, c_houses h, kart k
          where s.sel = 0 and s.kul=h.kul and s.nd=h.nd
          and k.house_id=h.id 
          and k.psch not in (8,9); --найти все дома, по которым есть хоть один открытый лиц.счет, 
                                   --соединить с таблицей выбора домов
    rec_list_ cur_list_choices%ROWTYPE;
    l_time date;
  begin
    
  logger.log_(l_time, 'Перерасчет : c_changes.gen_changes_proc: начат!');
  --установить глобальную переменную для использования в v_arch_kart, v_kart
  p_houses.set_g_lsk_tp(p_lsk_tp_var);
  
  l_time:=sysdate;
  --Необходимо перевести систему перерасчета на usl.fk_calc_tp  18.10.2010
  result_:=0;
  l_kran1:=nvl(p_kran1,0);
  l_wo_kpr:=nvl(p_wo_kpr,0);
  if mg_ is null then
    Raise_application_error(-20001, 'Внимание! Не указан период изменений!');
  end if;

  if p_mg2 is null then
    --провести соответствующим периодом
    mg2_:=mg_;
    else
    mg2_:=p_mg2;
  end if;

  --id пользователя
  select u.id into l_uid
         from t_user u
        where u.cd = user;
  --текущий период
  select period into l_mg from params p;

  if lsk_start_=lsk_end_ and lsk_start_ is not null then
   l_one_ls:=1;
  else
   l_one_ls:=0;
  end if;

  --добавляем связанные услуги (х.вода + х.вода св.с.н. +канализ)
  delete from list_choices_changes c where c.type=1;

  if usl_add_ = 1 then --добавлять ли связанные услуги по св.с.н.
    insert into list_choices_changes
      (usl_id, org1_id, proc1, org2_id, proc2, abs_set, mg, cnt_days, cnt_days2, type)
    select '012' as usl_id, org1_id, proc1, org2_id,
      proc2 , abs_set, cnt_days, cnt_days2, mg, 1 as type
      from list_choices_changes t
     where t.usl_id = '011'  --х.вода свыше с.н. (если есть);
    union all
    select '016' as usl_id, org1_id, proc1, org2_id,
      proc2, abs_set, cnt_days, cnt_days2, mg, 1 as type
      from list_choices_changes t
     where t.usl_id = '015' ; --г.вода св.с.н (если есть)
  end if;

  update list_choices_changes t set
   t.proc1 = round(t.cnt_days/to_char(last_day(to_date(mg_||'01', 'YYYYMMDD')),'DD')*100,2)
   where t.proc1 is null and t.cnt_days is not null;
  update list_choices_changes t set
   t.proc2 = round(t.cnt_days2/to_char(last_day(to_date(mg_||'01', 'YYYYMMDD')),'DD')*100,2)
   where t.proc2 is null and t.cnt_days2 is not null;
  update list_choices_changes t set t.mg = mg_;

  --изменения в процентах или абс величинах по Л.С. или домам
  if nvl(tst_,0) = 1 then
    --тестирование изменений на допустимость периода
    if lsk_start_ is not null and lsk_end_ is not null then
      select nvl(count(*),0) into cnt_ from v_kart k
        where mg_ between k.mg1 and k.mg2
        and k.lsk between lpad(lsk_start_, 8, '0') and lpad(lsk_end_, 8, '0');
    else
      select nvl(count(*),0) into cnt_ from v_kart k
        where mg_ between k.mg1 and k.mg2
        and exists (select * from v_kart r where
          exists (select *
            from list_choices_hs s
           where s.kul = r.kul --без РЭУ
             and s.nd = r.nd
             and s.sel = 0)
          and r.lsk=k.lsk);
    end if;

    if cnt_ = 0 then
      --ошибка, не найдены периоды по л.с.
      delete from list_choices_changes c where c.type=1;
      result_:= 2;
      return;
    else
      delete from list_choices_changes c where c.type=1;
      result_:=0;
    end if;

    if l_one_ls = 1 then
      --если перерасчет по 1 лс, выполнить проверку наличия организации в справочнике nabor
      --(иначе перерасчёт тупо не вполнится)
      select nvl(count(*),0) into cnt_ from
      (select 1 as cnt from list_choices_changes t, params p
        where not exists (select * from nabor n where n.lsk=lsk_start_
         and n.usl=t.usl_id)
         and p.period=t.mg
         and ((nvl(t.proc1,0)<>0 or nvl(t.cnt_days,0)<>0 or nvl(t.abs_set,0)<>0)
              and nvl(t.org1_id,0)=0 or
              (nvl(t.proc2,0)<>0 or nvl(t.cnt_days2,0)<>0)
              and nvl(t.org2_id,0)=0)
       union all
       select 1 as cnt from list_choices_changes t, params p
        where not exists (select * from a_nabor2 n where n.lsk=lsk_start_
         and n.usl=t.usl_id
         and t.mg between n.mgFrom and n.mgTo)
         and p.period<>t.mg
         and ((nvl(t.proc1,0)<>0 or nvl(t.cnt_days,0)<>0 or nvl(t.abs_set,0)<>0)
              and nvl(t.org1_id,0)=0 or
              (nvl(t.proc2,0)<>0 or nvl(t.cnt_days2,0)<>0)
              and nvl(t.org2_id,0)=0));

      if cnt_ <> 0 then
        --вернуть ошибку, что нужно проставить организации
        result_:=3;
        return;
      end if;
    end if;

  return;
  end if;

  --номер нового документа
  select changes_id.nextval into id_ from dual;

  insert into c_change_docs
     (id, mgchange, mg2, dtek, ts, user_id, text)
     values
      (id_, mg_, mg2_, init.get_date(), sysdate, (select u.id
           from t_user u
          where u.cd = user), text_);
  doc_id_:=id_;

    --узнать, есть ли прошлые периоды, для упрощения запросов
    select nvl(max(case when t.mg = l_mg then 1 else 0 end),0),
           nvl(max(case when t.mg <> l_mg then 1 else 0 end),0)
      into l_hcp, l_hbp
      from list_choices_changes t;

    select count(distinct lsk)
      into cnt_
      from c_change t
     where t.user_id =
           (select u.id from t_user u where u.cd = user)
       and t.doc_id = id_;

  -- генерация предварительного начисления (что бы было от чего считать скидки, может не быть начисления в c_charge)
  --имеет смысл, если указан текущий период для перерасчетов
  if l_hcp = 1 then
    if lsk_start_ is not null and lsk_end_ is not null then
   --генерим начисление по этим лицевым
      cnt_gen_:=c_charges.gen_charges(lsk_start_, lsk_end_, null, null, 0, 0);
    else
   --генерим начисление по этому дому
     open cur_list_choices;
     loop
       fetch cur_list_choices into rec_list_;
       exit when cur_list_choices%notfound;
        cnt_gen_:=c_charges.gen_charges(null, null, rec_list_.house_id, null, 0, 0);
     end loop;
     close cur_list_choices;
    end if;
  end if;

  logger.log_(l_time, 'Перерасчет : c_changes.gen_changes_proc: предварительное начисление');
  l_time:=sysdate;

--Temporary table!!!
delete from temp_c_change2;
--Raise_application_error(-20000, is_sch_);
if lsk_start_ is not null and lsk_end_ is not null then
  --по лицевым
  --две доли
  l_part:=0;
  loop
  if l_mg=mg_ then
  --текущий период
    insert into temp_c_change2
      (lsk, k_lsk_id, usl, org, proc, abs_set, mg, tp,
       cnt_days)
      select k.lsk, k.k_lsk_id, t.usl_id, decode(l_part,0,t.org1_id,t.org2_id) as org,
        decode(l_part,0,t.proc1,t.proc2) as proc, decode(l_part,0,t.abs_set, null),
        t.mg, t.type, t.cnt_days
        from v_kart k, list_choices_changes t, usl u
       where k.lsk between lpad(lsk_start_, 8, '0') and lpad(lsk_end_, 8, '0')
         and t.mg between k.mg1 and k.mg2
         and (l_psch = 0 or l_psch=1 and k.psch in (8,9)
         or l_psch=2 and k.psch not in (8,9))
         and t.usl_id=u.usl
         and (l_wo_kpr=1 and k.kpr=0 or l_wo_kpr=0) 
         and (l_kran1 = 1
                and exists (select * from v_kart s2 where s2.lsk=k.lsk and
                  k.kran1 <> 0)
                  or l_kran1 = 2
                  and exists (select * from v_kart s2 where s2.lsk=k.lsk and
                  nvl(k.kran1,0) = 0)
                  or l_kran1 = 0)
              -- ред.02.05.2019 - не брались корректно статусы счетчика по Основому лс - переделал    
              and exists (select * from v_lsk_priority s2 where s2.K_LSK_ID=k.K_LSK_ID and
                          (p_status = 0 or p_status = s2.status) and
                           case when is_sch_ in (2) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (1,2) then 1 --только сч.
                          when is_sch_ in (2) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (1,3) then 1
                          when is_sch_ in (2) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 1 then 1
                          when is_sch_ in (0) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (0,3) then 1 --без сч.
                          when is_sch_ in (0) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (0,2) then 1
                          when is_sch_ in (0) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 0 then 1
                          when is_sch_ in (1) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') then 1 --в т.ч. со сч.
                          when is_sch_ in (1) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch<> 1 and u.cd not in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег','эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch=1 then 1 --по закрытым л.с. производить по всем типам счетчиков
                          else 0 end = 1);
                  
/*              and exists (select * from v_kart s2 where s2.lsk=k.lsk and
                          (p_status = 0 or p_status = s2.status) and
                           case when is_sch_ in (2) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (1,2) then 1 --только сч.
                          when is_sch_ in (2) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (1,3) then 1
                          when is_sch_ in (2) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 1 then 1
                          when is_sch_ in (0) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (0,3) then 1 --без сч.
                          when is_sch_ in (0) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (0,2) then 1
                          when is_sch_ in (0) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 0 then 1
                          when is_sch_ in (1) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') then 1 --в т.ч. со сч.
                          when is_sch_ in (1) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch<> 1 and u.cd not in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег','эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch=1 then 1 --по закрытым л.с. производить по всем типам счетчиков
                          else 0 end = 1)*/
    else
      --архивный период
    insert into temp_c_change2
      (lsk, k_lsk_id, usl, org, proc, abs_set, mg, tp,
       cnt_days)
      select k.lsk, k.k_lsk_id, t.usl_id, decode(l_part,0,t.org1_id,t.org2_id) as org,
        decode(l_part,0,t.proc1,t.proc2) as proc, decode(l_part,0,t.abs_set, null),
        t.mg, t.type, t.cnt_days
        from v_arch_kart k, list_choices_changes t, usl u,
        (select s.uslm, s.counter from usl s where s.counter is not null) m
       where k.lsk between lpad(lsk_start_, 8, '0') and lpad(lsk_end_, 8, '0')
         and k.mg=mg_
         and t.mg between k.mg1 and k.mg2
         and (l_psch = 0 or l_psch=1 and k.psch in (8,9)
         or l_psch=2 and k.psch not in (8,9))
         and t.usl_id=u.usl
         and u.uslm=m.uslm(+)
         and (l_wo_kpr=1 and k.kpr=0 or l_wo_kpr=0) 
         and (l_kran1 = 1
                and exists (select * from v_arch_kart s2 where s2.lsk=k.lsk and s2.mg=mg_ and
                  k.kran1 <> 0)
                  or l_kran1 = 2
                  and exists (select * from v_arch_kart s2 where s2.lsk=k.lsk and s2.mg=mg_ and
                  nvl(k.kran1,0) = 0)
                  or l_kran1 = 0)
              -- ред.02.05.2019 - не брались корректно статусы счетчика по Основому лс - переделал    
              and exists (select * from v_lsk_priority s2 where s2.K_LSK_ID=k.K_LSK_ID and
                          (p_status = 0 or p_status = s2.status) and
                           case when is_sch_ in (2) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (1,2) then 1 --только сч.
                          when is_sch_ in (2) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (1,3) then 1
                          when is_sch_ in (2) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 1 then 1
                          when is_sch_ in (0) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (0,3) then 1 --без сч.
                          when is_sch_ in (0) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (0,2) then 1
                          when is_sch_ in (0) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 0 then 1
                          when is_sch_ in (1) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') then 1 --в т.ч. со сч.
                          when is_sch_ in (1) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch<> 1 and u.cd not in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег','эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch=1 then 1 --по закрытым л.с. производить по всем типам счетчиков
                          else 0 end = 1);
/*              and exists (select * from v_arch_kart s2 where s2.lsk=k.lsk and s2.mg=mg_ and
                          (p_status = 0 or p_status = s2.status) and
                           case when is_sch_ in (2) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (1,2) then 1 --только сч.
                          when is_sch_ in (2) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (1,3) then 1
                          when is_sch_ in (2) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 1 then 1
                          when is_sch_ in (0) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (0,3) then 1 --без сч.
                          when is_sch_ in (0) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (0,2) then 1
                          when is_sch_ in (0) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 0 then 1
                          when is_sch_ in (1) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') then 1 --в т.ч. со сч.
                          when is_sch_ in (1) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch<> 1 and u.cd not in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег','эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch=1 then 1 --по закрытым л.с. производить по всем типам счетчиков
                          else 0 end = 1);*/
    if sql%rowcount = 0 then                          
      Raise_application_error(-20000, 'Перерасчет не выполнен!');
    end if;
    end if;                      
                         
    exit when l_part=1;
    l_part:=l_part+1;

  end loop;
else
    --по домам
    --две доли
  l_part:=0;
  select count(*) into l_cnt_house from list_choices_hs;
  logger.log_(l_time, 'Всего домов для перерасчета='||l_cnt_house);
  
  loop
    for c in (select *
                from list_choices_hs s
                where s.sel = 0)
    loop
    logger.log_(l_time, 'Начат перерасчет по дому kul='||c.kul||' nd='||c.nd);

    if l_mg=mg_ then
    --текущий период
    insert into temp_c_change2
      (lsk, k_lsk_id, usl, org, proc, abs_set, mg, tp,
       cnt_days)
      select k.lsk, k.k_lsk_id, t.usl_id, decode(l_part,0,t.org1_id,t.org2_id) as org,
       decode(l_part,0,t.proc1,t.proc2) as proc,
             decode(l_part,0,t.abs_set, null), t.mg, t.type, t.cnt_days
        from v_kart k, list_choices_changes t, usl u
       where t.mg between k.mg1 and k.mg2
              and (l_psch = 0 or l_psch=1 and k.psch in (8,9)
              or l_psch=2 and k.psch not in (8,9))
              and t.usl_id=u.usl
              and k.kul = c.kul
              and k.nd = c.nd
              and (l_wo_kpr=1 and k.kpr=0 or l_wo_kpr=0) 
              and (l_kran1 = 1
              and exists (select * from v_kart s2 where s2.lsk=k.lsk and
                  k.kran1 <> 0)
                  or l_kran1 = 2
                  and exists (select * from v_kart s2 where s2.lsk=k.lsk and
                  nvl(k.kran1,0) = 0)
                  or l_kran1 = 0)
              -- ред.02.05.2019 - не брались корректно статусы счетчика по Основому лс - переделал    
              and exists (select * from v_lsk_priority s2 where s2.K_LSK_ID=k.K_LSK_ID and
                          (p_status = 0 or p_status = s2.status) and
                           case when is_sch_ in (2) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (1,2) then 1 --только сч.
                          when is_sch_ in (2) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (1,3) then 1
                          when is_sch_ in (2) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 1 then 1
                          when is_sch_ in (0) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (0,3) then 1 --без сч.
                          when is_sch_ in (0) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (0,2) then 1
                          when is_sch_ in (0) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 0 then 1
                          when is_sch_ in (1) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') then 1 --в т.ч. со сч.
                          when is_sch_ in (1) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch<> 1 and u.cd not in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег','эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch=1 then 1 --по закрытым л.с. производить по всем типам счетчиков
                          else 0 end = 1);
/*                and exists (select * from v_kart s2 where s2.lsk=k.lsk and
                          (p_status = 0 or p_status = s2.status) and
                           case when is_sch_ in (2) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег')and s2.psch in (1,2) then 1 --только сч.
                          when is_sch_ in (2) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (1,3) then 1
                          when is_sch_ in (2) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор')  and s2.sch_el = 1 then 1
                          when is_sch_ in (0) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (0,3) then 1 --без сч.
                          when is_sch_ in (0) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (0,2) then 1
                          when is_sch_ in (0) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 0 then 1
                          when is_sch_ in (1) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') then 1 --в т.ч. со сч.
                          when is_sch_ in (1) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch<> 1 and u.cd not in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег','эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch=1 then 1 --по закрытым л.с. производить по всем типам счетчиков
                          else 0 end = 1);*/
    else
      --архивный период
    insert into temp_c_change2
      (lsk, k_lsk_id, usl, org, proc, abs_set, mg, tp,
       cnt_days)
      select k.lsk, k.k_lsk_id, t.usl_id, decode(l_part,0,t.org1_id,t.org2_id) as org,
       decode(l_part,0,t.proc1,t.proc2) as proc,
             decode(l_part,0,t.abs_set, null), t.mg, t.type, t.cnt_days
        from v_arch_kart k, list_choices_changes t, usl u
       where k.mg=mg_ and t.mg between k.mg1 and k.mg2
              and (l_psch = 0 or l_psch=1 and k.psch in (8,9)
              or l_psch=2 and k.psch not in (8,9))
              and t.usl_id=u.usl
              and k.kul = c.kul
              and k.nd = c.nd
              and (l_wo_kpr=1 and k.kpr=0 or l_wo_kpr=0) 
              and (l_kran1 = 1
              and exists (select * from v_arch_kart s2 where s2.lsk=k.lsk and s2.mg=mg_ and
                  k.kran1 <> 0)
                  or l_kran1 = 2
                  and exists (select * from v_arch_kart s2 where s2.lsk=k.lsk and s2.mg=mg_ and
                  nvl(k.kran1,0) = 0)
                  or l_kran1 = 0)
              -- ред.02.05.2019 - не брались корректно статусы счетчика по Основому лс - переделал    
              and exists (select * from v_lsk_priority s2 where s2.K_LSK_ID=k.K_LSK_ID and
                          (p_status = 0 or p_status = s2.status) and
                           case when is_sch_ in (2) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (1,2) then 1 --только сч.
                          when is_sch_ in (2) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (1,3) then 1
                          when is_sch_ in (2) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 1 then 1
                          when is_sch_ in (0) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (0,3) then 1 --без сч.
                          when is_sch_ in (0) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (0,2) then 1
                          when is_sch_ in (0) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 0 then 1
                          when is_sch_ in (1) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 
                            'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') then 1 --в т.ч. со сч.
                          when is_sch_ in (1) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch<> 1 and u.cd not in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 
                            'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег','эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch=1 then 1 --по закрытым л.с. производить по всем типам счетчиков
                          else 0 end = 1);
/*                  
                and exists (select * from v_arch_kart s2 where s2.lsk=k.lsk and s2.mg=mg_ and
                          (p_status = 0 or p_status = s2.status) and
                           case when is_sch_ in (2) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег')and s2.psch in (1,2) then 1 --только сч.
                          when is_sch_ in (2) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег')  and s2.psch in (1,3) then 1
                          when is_sch_ in (2) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор')  and s2.sch_el = 1 then 1
                          when is_sch_ in (0) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег') and s2.psch in (0,3) then 1 --без сч.
                          when is_sch_ in (0) and u.cd in ('г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') and s2.psch in (0,2) then 1
                          when is_sch_ in (0) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s2.sch_el = 0 then 1
                          when is_sch_ in (1) and u.cd in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег') then 1 --в т.ч. со сч.
                          when is_sch_ in (1) and u.cd in ('эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch<> 1 and u.cd not in ('х.вода', 'х.вода/св.нор', 'х.вода.ОДН', 'х.в. ОДН, 0 зарег', 'г.вода', 'г.вода/св.нор','г.вода.ОДН','г.в. ОДН, 0 зарег','эл.энерг.2','эл.эн.2/св.нор') then 1
                          when l_psch=1 then 1 --по закрытым л.с. производить по всем типам счетчиков
                          else 0 end = 1);*/
    end if;      
    --по каждому дому коммит, да, да! (иначе тормозит глухо, когда много домов)
    commit;
    logger.log_(l_time, 'Окончен перерасчет по дому kul='||c.kul||' nd='||c.nd);
    end loop;
    exit when l_part=1;
    l_part:=l_part+1;
  end loop;
end if;

  logger.log_(l_time, 'Перерасчет : c_changes.gen_changes_proc: добавлено в temp_c_change2');
  l_time:=sysdate;

--установить uslm
update temp_c_change2 t set t.uslm = (select u.uslm from usl u where t.usl=u.usl);

--отправить текущее начисление по лицевым счетам в архив
--(чтобы запрос выполнялся только по a_charge , без union all)
delete from a_charge2 a
 where l_mg between a.mgFrom and a.mgTo
 and exists (select * from temp_c_change2 t where t.lsk=a.lsk);
insert into a_charge2
  (lsk,
   usl,
   summa,
   kart_pr_id,
   spk_id,
   type,
   test_opl,
   test_cena,
   test_tarkoef,
   test_spk_koef,
   main,
   lg_doc_id,
   npp,
   sch,
   mgFrom,
   mgTo)
  select c.lsk,
         c.usl,
         c.summa,
         c.kart_pr_id,
         c.spk_id,
         c.type,
         c.test_opl,
         c.test_cena,
         c.test_tarkoef,
         c.test_spk_koef,
         c.main,
         c.lg_doc_id,
         c.npp,
         c.sch,
         l_mg, -- одинаковые месяца, так как работаем в текущем периоде
         l_mg
    from c_charge c
   where exists (select * from temp_c_change2 t where t.lsk = c.lsk);

  select nvl(count(*),0) into l_h_usl from list_choices_changes s, usl u where
    s.usl_id=u.usl
    and u.cd in ('х.вода', 'х.вода/св.нор', 'г.вода', 'г.вода/св.нор',
    'х.вода.ОДН','г.вода.ОДН');
  --промежуточный коммит -чтоб не тормозило)
  commit;

  logger.log_(l_time, 'Перерасчет : c_changes.gen_changes_proc: промежуточный коммит');
  l_time:=sysdate;

--изменения начислений в % отношении
--блок ТОЛЬКО для перерасчета канализования по проведенному перерасчету по основной услуге
--Канализование пересчитается в случае, если был перерасчет в процентах по воде и
--если это затребовано на форме
if l_h_usl > 0 and p_kan=1 then
  l_part:=0;
  loop
    for c in (select /*+ USE_HASH(t,a,b,d) */ t.lsk, b.lsk as lsk_kan, t.org, t.proc, t.mg, d.usl, d.summa, d.vol,
       a.summa/b.summa as proc_kan, --доля услуги в канализовании (отношение объемов)
       round(t.proc * a.summa/b.summa,3) as proc_itg
         from temp_c_change2 t join usl m on t.usl = m.usl
      left join (select u.usl, t.mgFrom||t.mgTo, --нужно чтобы выборка периодов была правильной ред. 19.10.2017
      t.mgFrom, t.mgTo, t.lsk, sum(t.test_opl) as summa
      from a_charge2 t, usl u
      where t.type=1         --объем основной услуги
      and t.usl=u.usl
      and exists (select * from temp_c_change2 i where i.lsk=t.lsk and i.usl=t.usl)
      group by u.usl, t.mgFrom||t.mgTo, t.mgFrom, t.mgTo, t.lsk) a on t.lsk=a.lsk and t.mg between a.mgFrom and a.mgTo and t.usl=a.usl
      
      left join (select k.k_lsk_id, t.mgFrom, t.mgTo, t.mgFrom||t.mgTo, t.lsk, sum(t.test_opl) as summa
      from arch_kart k, a_charge2 t, usl u --объем канализ
      where t.type=1 and t.usl=u.usl and k.lsk=t.lsk
        and exists (select * from temp_c_change2 i where i.lsk=t.lsk)
        and k.mg between t.mgFrom and t.mgTo and k.psch not in (8,9) -- только открытые на тот период лиц.счета
        and (l_part=0 and u.cd in ('канализ', 'канализ/св.нор')
        or l_part=1 and u.cd in ('канализ.ОДН'))
      group by k.k_lsk_id, t.mgFrom, t.mgTo, t.mgFrom||t.mgTo, t.lsk) b on t.k_lsk_id=b.k_lsk_id and t.mg between b.mgFrom and b.mgTo
      
      left join (select k.k_lsk_id, t.usl, t.mgFrom, t.mgTo, t.mgFrom||t.mgTo, t.lsk, sum(t.summa) as summa, sum(t.test_opl) as vol
      from arch_kart k, a_charge2 t, usl u --начисление канализ, детализир и объем
      where t.type=1 and t.usl=u.usl and k.lsk=t.lsk
        and exists (select * from temp_c_change2 i where i.lsk=t.lsk)
        and k.mg between t.mgFrom and t.mgTo and k.psch not in (8,9) -- только открытые на тот период лиц.счета
        and (l_part=0 and u.cd in ('канализ', 'канализ/св.нор')
        or l_part=1 and u.cd in ('канализ.ОДН'))
      group by k.k_lsk_id, t.usl, t.mgFrom, t.mgTo, t.mgFrom||t.mgTo, t.lsk) d on t.k_lsk_id=d.k_lsk_id and t.mg between d.mgFrom and d.mgTo
      
      where 
      (l_mg=mg_ and exists (select * from v_kart k where k.lsk=t.lsk and k.status not in (9) and (l_wo_kpr=1 and k.kpr=0 or l_wo_kpr=0)) --кроме нежилых помещений, текущий или архивный период!
       or l_mg<>mg_ and exists (select * from v_arch_kart k where k.lsk=t.lsk and k.status not in (9) and (l_wo_kpr=1 and k.kpr=0 or l_wo_kpr=0) and k.mg=mg_))  --жесть вообще писать exists через OR ред 02.12.14
       --кроме нежилых помещений
      and (l_part=0 and m.cd in ('х.вода', 'х.вода/св.нор', 'г.вода', 'г.вода/св.нор')
      or l_part=1 and m.cd in ('х.вода.ОДН','г.вода.ОДН'))
      and t.proc <> 0 -- в % отношении
      and nvl(b.summa,0) <> 0 --где есть вообще объем по канализ
      and nvl(a.summa,0) <> 0 --где есть вообще объем по основной услуге
      )
    loop
      insert into c_change
              (lsk, mgchange, mg2, usl, proc, summa, org, type, dtek, ts, user_id, doc_id, vol)
      values (c.lsk_kan, mg2_, c.mg, c.usl, c.proc_itg, round(c.proc_itg/100 * c.summa,2),
       c.org, decode(p_tp, 1, 3, 0), init.get_date, sysdate, l_uid, id_, round(c.proc_itg/100 * c.vol,4));

    end loop;
    exit when l_part=1;
    l_part:=l_part+1;
  end loop;
  logger.log_(l_time, 'Перерасчет : c_changes.gen_changes_proc: добав. водоотведение');
  l_time:=sysdate;

end if;


--перерасчет по основным услугам, в % отношении
if l_hbp = 1 then
  --если есть прошлый период, для пересчета
  insert into c_change
          (lsk, mgchange, mg2, usl, proc, summa, org, type, dtek, ts, user_id, doc_id, vol, sch)
  select t.lsk, mg2_, t.mg, t.usl, t.proc, t.proc/100 * a.summa as summa,
    t.org, decode(p_tp, 1, 3, 0) as type, init.get_date, sysdate, l_uid, id_, t.proc/100 * a.vol as vol, a.sch
       from temp_c_change2 t join usl m on t.usl = m.usl
    left join (select t.usl, t.mgFrom, t.mgTo, t.mgFrom||t.mgTo,-- не удалять! нужно!
     t.lsk, t.sch, sum(t.summa) as summa, sum(t.test_opl) as vol
    from a_charge2 t --начисление услуги, детализир, объем
    where t.type=1
    and exists (select * from temp_c_change2 i where i.lsk=t.lsk)
    group by t.usl, t.mgFrom, t.mgTo, t.mgFrom||t.mgTo, t.lsk, t.sch) a on t.lsk=a.lsk and t.mg between a.mgFrom and a.mgTo and t.usl=a.usl
    where 
    t.proc <> 0 -- в % отношении
    and nvl(a.summa,0) <> 0;
end if;

if l_hcp = 1 then
  --если есть текущий период, для пересчета
  insert into c_change
          (lsk, mgchange, mg2, usl, proc, summa, org, type, dtek, ts, user_id, doc_id, vol, sch)
  select t.lsk, mg2_, t.mg, t.usl, t.proc, t.proc/100 * a.summa as summa,
    t.org, decode(p_tp, 1, 3, 0) as type, init.get_date, sysdate, l_uid, id_, t.proc/100 * a.vol as vol, a.sch
       from temp_c_change2 t, usl m,
    (select t.usl, t.lsk, t.sch, sum(t.summa) as summa, sum(t.test_opl) as vol
    from c_charge t --начисление услуги, детализир, объем
    where t.type=1
    group by t.usl, t.lsk, t.sch) a
    where t.usl = m.usl
    and t.lsk=a.lsk(+) and t.usl=a.usl(+)
    and t.proc <> 0 -- в % отношении
    and nvl(a.summa,0) <> 0--текущий период
    ; --где есть вообще объем по основной услуге
end if;

 --абсолютные значения изменений
insert into c_change
        (lsk, mgchange, mg2, usl, proc, summa, org, type, dtek, ts, user_id, doc_id)
        select n.lsk, mg2_, t.mg, t.usl, 0, nvl(abs_set, 0) as summa,
           nvl(t.org, n.org) as org,case
                 when p_tp =1 then 3     
                 when nvl(t.abs_set, 0) < 0 then
                  1
                 when nvl(t.abs_set, 0) > 0 then
                  2
                 else
                  0
               end as type, init.get_date, sysdate, l_uid, id_
          from temp_c_change2 t, nabor n, params p
         where t.mg >=p.period
         and t.usl = n.usl and t.org is null --если новые будущие периоды и не указана явно орг - ставим код орг из текущ.справочника
         and nvl(t.abs_set, 0) <> 0
         and t.lsk=n.lsk;

insert into c_change
        (lsk, mgchange, mg2, usl, proc, summa, org, type, dtek, ts, user_id, doc_id)
        select n.lsk, mg2_, t.mg, t.usl, 0, nvl(abs_set, 0) as summa,
           nvl(t.org, n.org) as org,case
                 when p_tp =1 then 3     
                 when nvl(t.abs_set, 0) < 0 then
                  1
                 when nvl(t.abs_set, 0) > 0 then
                  2
                 else
                  0
               end as type, init.get_date, sysdate, l_uid, id_
          from temp_c_change2 t, a_nabor2 n, params p
         where t.mg < p.period
         and t.mg between n.mgFrom and n.mgTo --если старые периоды и не указана явно орг - ставим код орг из арх.справочника
         and t.usl = n.usl and t.org is null
         and nvl(t.abs_set, 0) <> 0
         and t.lsk=n.lsk;

insert into c_change
        (lsk, mgchange, mg2, usl, proc, summa, org, type, dtek, ts, user_id, doc_id)
        select t.lsk, mg2_, t.mg, t.usl, 0, nvl(abs_set, 0) as summa,
           nvl(t.org, null) as org,case
                 when p_tp =1 then 3     
                 when nvl(t.abs_set, 0) < 0 then
                  1
                 when nvl(t.abs_set, 0) > 0 then
                  2
                 else
                  0
               end as type, init.get_date, sysdate, l_uid, id_
          from temp_c_change2 t, params p
         where t.org is not null --если любые периоды и указана явно орг - ставим какая указана
         and nvl(t.abs_set, 0) <> 0;

  select count(distinct lsk)
    into cnt1_
    from c_change t
   where t.user_id =
         (select u.id from t_user u where u.cd = user)
     and t.doc_id = id_;

  --промежуточный коммит -чтоб не тормозило)
  commit;

  logger.log_(l_time, 'Перерасчет : c_changes.gen_changes_proc: добав. c_changes');
  l_time:=sysdate;

  if p_chrg = 1 then
    --задано генерить финальное начисление
    if lsk_start_ is not null and lsk_end_ is not null then
   --генерим начисление по этим лицевым
      cnt_gen_:=c_charges.gen_charges(lsk_start_, lsk_end_, null, null, 0, 0);
    else
   --генерим начисление по этому дому
     open cur_list_choices;
     loop
       fetch cur_list_choices into rec_list_;
       exit when cur_list_choices%notfound;
        cnt_gen_:=c_charges.gen_charges(null, null, rec_list_.house_id, null, 0, 0);
     end loop;
     close cur_list_choices;

    end if;
  end if;

  delete from list_choices_changes c where c.type=1;
  result_:=nvl(cnt1_, 0) - nvl(cnt_, 0);
  --перерасчёт не был сделан
  if result_ = 0 then
    return;
  else
    commit;
  end if;
  logger.log_(l_time, 'Перерасчет выполнен: c_changes.gen_changes_proc id='||id_);
  return;
end;


--выполнение корректировки оплаты, пени
procedure gen_pay_corrects(src_usl_ in usl.usl%type,
    src_org_ in t_org.id%type,
    dst_usl_ in usl.usl%type,
    dst_org_ in t_org.id%type,
    reu_ in t_org.reu%type,
    p_tp in number) is
  l_dt1 date; l_dt2 date;    
begin
 l_dt1:=init.get_dt_start;
 l_dt2:=init.get_dt_end;
 update kwtp_day t set t.usl=nvl(dst_usl_, t.usl), t.org=decode(dst_org_, -1, t.org, dst_org_)
   where t.dtek between l_dt1 and l_dt2 and
   t.usl=src_usl_ and t.org=src_org_ and t.priznak=decode(p_tp,1,1,2,0) --оплата или пеня
   and exists (select * from kart k where 
     t.lsk=k.lsk and
     k.reu =nvl(reu_, k.reu)); 
 commit;
end;    


--выполнение корректировки сальдо
procedure gen_corrects(src_usl_ in usl.usl%type,
    src_org_ in t_org.id%type,
    dst_usl_ in usl.usl%type,
    dst_org_ in t_org.id%type,
    reu_ in t_org.reu%type,
    text_ in c_change_docs.text%type) is
id_ t_corrects_payments.id%type;
fk_doc_ c_change_docs.id%type;
mg_ c_change_docs.mgchange%type;
user_id_ c_change_docs.user_id%type;
begin
--текущий период
select p.period into mg_ from params p;
select u.id into user_id_
           from t_user u
          where u.cd = user;
select nvl(max(t.id),0)+1 into id_ from t_corrects_payments t
 where t.mg=mg_;

insert into c_change_docs
  (mgchange, dtek, ts, text)
  values (mg_, init.get_date, sysdate, text_)
  returning id into fk_doc_;

insert into t_corrects_payments
  (lsk, usl, org, summa, user_id, dat, mg, dopl, id, fk_doc)
 select s.lsk, s.usl, s.org, summa, user_id_, init.get_date, mg_, mg_, id_, fk_doc_
  from saldo_usl s, kart k, t_org o, params p
   where s.mg=p.period and
   s.usl=src_usl_ and s.org=src_org_ and
   s.lsk=k.lsk and k.reu=o.reu and
   (reu_ is null or o.reu=reu_ and reu_ is not null) ;

insert into t_corrects_payments
  (lsk, usl, org, summa, user_id, dat, mg, dopl, id, fk_doc)
 select s.lsk, nvl(dst_usl_, s.usl) as usl, decode(dst_org_, -1, s.org, dst_org_) as org, -1*summa, user_id_, init.get_date, mg_, mg_, id_, fk_doc_
  from saldo_usl s, kart k, t_org o, params p
   where s.mg=p.period and
   s.usl=src_usl_ and s.org=src_org_ and
   s.lsk=k.lsk and k.reu=o.reu and
   (reu_ is null or o.reu=reu_ and reu_ is not null) ;
commit;
end;

procedure del_chng_doc(id_ in c_change_docs.id%type) is
begin
--удаление разовых изменений (документа в целом)
  delete from c_change t where t.doc_id=id_;
  delete from c_change_docs t where t.id=id_;
commit;
end;

procedure del_chng(id_ in c_change.id%type) is
begin
--удаление разовых изменений (строки)
  delete from c_change t where t.id=id_;
commit;
end;

procedure del_corr(fk_doc_ in c_change_docs.id%type) is
begin
--удаление корректировок
delete from t_corrects_payments t
 where t.mg=(select p.period from params p)
  and t.fk_doc=fk_doc_;
  delete from c_change_docs t where t.id=fk_doc_;
commit;
end;


end C_CHANGES;
/


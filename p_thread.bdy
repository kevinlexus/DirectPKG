create or replace package body scott.P_THREAD is

  --создание списков объектов для формирования в потоках
  procedure prep_obj(p_var in number) is
  begin
    delete from temp_obj;
    if p_var = 1 then
      --выбрать все не закрытые дома 
      insert into temp_obj
        (id)
        select h.id from c_houses h where nvl(h.psch, 0) = 0; --не закрытые дома
    elsif p_var = 2 then
      --распределить ОДН во вводах, где нет ОДПУ
      insert into temp_obj
        (id)
        select d.id
          from c_vvod d, c_houses h
         where d.house_id = h.id
           and d.dist_tp in (4, 5) --дома без ОДПУ
           and nvl(h.psch, 0) = 0; --не закрытые дома
    elsif p_var = 3 then
      --дома с ОДПУ
      insert into temp_obj
        (id)
        select distinct d.id
          from c_vvod d, c_houses h
         where d.house_id = h.id
           and nvl(h.psch, 0) = 0 --не закрытые дома
           and d.dist_tp not in (4, 5, 2); --дома с ОДПУ и с услугой для распределения, например ОДН (dist_tp<>2)
    elsif p_var = 4 then
      --выбрать все дома, и закрытые и не закрытые 
      insert into temp_obj
        (id)
        select h.id from c_houses h;
    end if;
  end;

  -- УСТАРЕВАЕТ, УДАЛИТЬ ПОЗЖЕ ред.16.04.2019
  -- обертка для Java функции smpl_chk
  procedure smpl_chk(p_var in number, p_ret out number) is
  begin
    Raise_application_error(-20000, 'НЕ РАБОТАЕТ БЛОК!');
    p_ret := smpl_chk(p_var);
  end;

  -- УСТАРЕВАЕТ, УДАЛИТЬ ПОЗЖЕ ред.16.04.2019
  --аналог процедуры gen.smpl_chk
  --проверка перед формированием, с выводом л.с.
  --содержащих ошибки в таблицу prep_err
  function smpl_chk(p_var in number) return number is
  begin
    Raise_application_error(-20000, 'НЕ РАБОТАЕТ БЛОК!');
    delete from prep_err;
    if p_var = 1 then
      insert into prep_err
        (lsk, text)
        select k.lsk, 'Некорректные лицевые, содержащие услугу х.в.ОДН, но у прочих л.с. дома услуги ОДН нет' as text
          from kart k, nabor n, usl u
         where k.lsk = n.lsk
           and k.psch not in (8, 9)
           and n.usl = u.usl
           and u.cd = 'х.вода'
           and exists (select *
                  from nabor r, usl u2
                 where r.lsk = k.lsk
                   and r.usl = u2.usl --есть услуга ОДН
                   and u2.cd = 'х.вода.ОДН')
           and not exists --а у других л.с. нет этой услуги
         (select *
                  from kart t, nabor r, usl u2
                 where r.lsk <> k.lsk
                   and r.usl = u2.usl
                   and u2.cd = 'х.вода.ОДН'
                   and t.lsk = r.lsk
                   and t.house_id = k.house_id)
           and exists
         (select a.house_id
                  from kart a
                 where a.house_id = k.house_id having count(*) > 1
                 group by a.house_id);
    elsif p_var = 2 then
      insert into prep_err
        (lsk, text)
        select k.lsk, 'Некорректные лицевые, НЕ содержащие х.в.услугу ОДН, но у прочих л.с. дома услуга ОДН есть' as text
          from kart k, nabor n, usl u
         where k.lsk = n.lsk
           and k.psch not in (8, 9)
           and n.usl = u.usl
           and u.cd = 'х.вода'
           and exists (select *
                  from nabor r, usl u2
                 where r.lsk = k.lsk
                   and r.usl = u2.usl --есть услуга ОДН
                   and u2.cd = 'х.вода.ОДН')
           and not exists --а у других л.с. нет этой услуги
         (select *
                  from kart t, nabor r, usl u2
                 where r.lsk <> k.lsk
                   and r.usl = u2.usl
                   and u2.cd = 'х.вода.ОДН'
                   and t.lsk = r.lsk
                   and t.house_id = k.house_id)
           and exists
         (select a.house_id
                  from kart a
                 where a.house_id = k.house_id having count(*) > 1
                 group by a.house_id);
    elsif p_var = 3 then
      insert into prep_err
        (lsk, text)
        select k.lsk, 'Некорректные лицевые, содержащие услугу г.в.ОДН, но у прочих л.с. дома услуги ОДН нет' as text
          from kart k, nabor n, usl u
         where k.lsk = n.lsk
           and k.psch not in (8, 9)
           and n.usl = u.usl
           and u.cd = 'г.вода'
           and exists (select *
                  from nabor r, usl u2
                 where r.lsk = k.lsk
                   and r.usl = u2.usl --есть услуга ОДН
                   and u2.cd = 'г.вода.ОДН')
           and not exists --а у других л.с. нет этой услуги
         (select *
                  from kart t, nabor r, usl u2
                 where r.lsk <> k.lsk
                   and r.usl = u2.usl
                   and u2.cd = 'г.вода.ОДН'
                   and t.lsk = r.lsk
                   and t.house_id = k.house_id)
           and exists
         (select a.house_id
                  from kart a
                 where a.house_id = k.house_id having count(*) > 1
                 group by a.house_id);
    elsif p_var = 4 then
      insert into prep_err
        (lsk, text)
        select k.lsk, 'Некорректные лицевые, НЕ содержащие г.в.услугу ОДН, но у прочих л.с. дома услуга ОДН есть' as text
          from kart k, nabor n, usl u
         where k.lsk = n.lsk
           and k.psch not in (8, 9)
           and n.usl = u.usl
           and u.cd = 'г.вода'
           and exists (select *
                  from nabor r, usl u2
                 where r.lsk = k.lsk
                   and r.usl = u2.usl --есть услуга ОДН
                   and u2.cd = 'г.вода.ОДН')
           and not exists --а у других л.с. нет этой услуги
         (select *
                  from kart t, nabor r, usl u2
                 where r.lsk <> k.lsk
                   and r.usl = u2.usl
                   and u2.cd = 'г.вода.ОДН'
                   and t.lsk = r.lsk
                   and t.house_id = k.house_id)
           and exists
         (select a.house_id
                  from kart a
                 where a.house_id = k.house_id having count(*) > 1
                 group by a.house_id);
    elsif p_var = 5 then
      --список домов в разных УК, по которым обнаружены открытые лицевые счета - ред.19.02.2019 - отменил проверку, дом может быть в разных УК      
      /* insert into prep_err (lsk, text)           
      select null as lsk, 'kul='||t.kul||' nd='||t.nd||' cnt='||count(*)
      ||' Дом в разных УК, по которому обнаружены открытые лицевые счета' from (
      select k.reu, k.kul, k.nd from kart k, v_lsk_tp tp
       where k.psch not in (8,9) and k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN'
      group by k.reu, k.kul, k.nd
      ) t 
      group by t.kul,t.nd
      having count(*)>1
      union all
      select null as lsk, 'kul='||t.kul||' nd='||t.nd||' cnt='||count(*)
      ||' Дом в разных УК, по которому обнаружены открытые лицевые счета' from (
      select k.reu, k.kul, k.nd, tp.cd from kart k, v_lsk_tp tp
       where k.psch not in (8,9) and k.fk_tp=tp.id and tp.cd in ('LSK_TP_ADDIT','LSK_TP_RSO')
      group by k.reu, k.kul, k.nd, tp.cd
      ) t 
      group by t.kul,t.nd
      having count(*)>1
      ;*/
      null;
    end if;
    if sql%rowcount > 0 then
      return 1; --есть ошибки
    else
      return 0; --нет ошибок
    end if;
  end;

  --чистить инф, там где ВООБЩЕ нет счетчиков (нет записи в c_vvod)
  procedure gen_clear_vol is
  begin
    for c in (select u.usl, u.fk_usl_chld
                from usl u, usl odn
               where u.cd in ('х.вода',
                              'г.вода',
                              'х.в. для гвс',
                              'эл.энерг.2',
                              'эл.эн.учет УО',
                              'эл.эн.ОДН',
                              'отоп.гкал.')
                 and u.fk_usl_chld = odn.usl) loop
      for c2 in (select h.id
                   from c_houses h
                  where nvl(h.psch, 0) = 0 --не закрытые дома
                    and not exists
                  (select * from c_vvod d where d.usl = c.usl)
                  order by h.id) loop
        --почистить
        p_vvod.gen_clear_odn(p_usl      => c.usl,
                             p_usl_chld => c.fk_usl_chld,
                             p_house    => c2.id,
                             p_vvod     => null);
      end loop;
    end loop;
  
  end;

  --распределить объемы по домам с ОДПУ
  procedure gen_dist_odpu(p_vv in number) is
  begin
    for c in (select t.*
                from c_vvod t
               where t.id = p_vv
                 and t.usl is not null) loop
      p_vvod.gen_dist(p_klsk           => c.fk_k_lsk,
                      p_dist_tp        => c.dist_tp,
                      p_usl            => c.usl,
                      p_use_sch        => c.use_sch,
                      p_old_use_sch    => c.use_sch,
                      p_kub_nrm_fact   => c.kub_nrm_fact,
                      p_kub_sch_fact   => c.kub_sch_fact,
                      p_kub_ar_fact    => c.kub_ar_fact,
                      p_kub_ar         => c.kub_ar,
                      p_opl_ar         => c.opl_ar,
                      p_kub_sch        => c.kub_sch,
                      p_sch_cnt        => c.sch_cnt,
                      p_sch_kpr        => c.sch_kpr,
                      p_kpr            => c.kpr,
                      p_cnt_lsk        => c.cnt_lsk,
                      p_kub_norm       => c.kub_norm,
                      p_kub_fact       => c.kub_fact,
                      p_kub_man        => c.kub_man,
                      p_kub            => c.kub,
                      p_edt_norm       => c.edt_norm,
                      p_kub_dist       => c.kub_dist,
                      p_id             => c.id,
                      p_house_id       => c.house_id,
                      p_opl_add        => c.opl_add,
                      p_old_kub        => c.kub,
                      p_limit_proc     => c.limit_proc,
                      p_old_limit_proc => c.limit_proc,
                      p_gen_part_kpr   => 1,
                      p_wo_limit       => c.wo_limit);
    end loop;
  end;

  --переключить режимы при выборе пунктов меню (в триггере)
  procedure check_itms(p_itm in number, p_sel in number) is
    l_var_exp_lst number;
  begin
    l_var_exp_lst := scott.INIT.get_gen_exp_lst; --кроме списков, которые регулируются параметром
  
    --если выбрано итоговое, включить другие пункты меню, выкл перех.месяца
    update spr_gen_itm t
       set t.sel = decode(t.cd,
                           'GEN_MONTH_OVER',
                           0,
                           'GEN_COMPRESS_ARCH',
                           0,
                           p_sel)
     where t.cd not in ('GEN_ITG', 'GEN_ADVANCE') --кроме итогового и авансовых платежей
       and exists
     (select *
              from spr_gen_itm s
             where s.cd = 'GEN_ITG'
               and s.id = p_itm)
       and decode(t.cd, 'GEN_EXP_LISTS', l_var_exp_lst, 1) = 1;
  
    --если выбран переход, выключить другие пункты меню, включить сжатие
    update spr_gen_itm t
       set t.sel = 0
     where t.cd not in ('GEN_MONTH_OVER')
       and exists (select *
              from spr_gen_itm s
             where s.cd = 'GEN_MONTH_OVER'
               and s.id = p_itm
               and p_sel = 0);
  
    update spr_gen_itm t
       set t.sel = 1
     where t.cd in ('GEN_COMPRESS_ARCH')
       and exists (select *
              from spr_gen_itm s
             where s.cd = 'GEN_MONTH_OVER'
               and s.id = p_itm
               and p_sel = 1);
  end;

  -- расширенная проверка ошибок
  -- возвращает список объектов, содержащих ошибку
  -- p_var - вариант проверки
  procedure extended_chk(p_var          in number,
                         prep_refcursor IN OUT rep_refcursor) is
    l_cd_org t_org.cd%type;
    cursor cur_params is
      select * from params;
    rec_params cur_params%rowtype;
    l_mg1      params.period%type;
    l_cnt      number;
  begin
  
    select o.cd
      into l_cd_org
      from scott.t_org o, scott.t_org_tp tp
     where tp.id = o.fk_orgtp
       and tp.cd = 'РКЦ';
  
    open cur_params;
    fetch cur_params
      into rec_params;
    close cur_params;
    l_mg1 := utils.add_months_pr(rec_params.period, 1);
  
    -- Проверки до итог.формирования
    if p_var = 1 then
      -- дата последнего периода статуса прописки проживающего должна быть открытой
      OPEN prep_refcursor FOR
        select k.* from kart k where k.fk_err = 1;
    elsif p_var = 2 then
      -- период действия статуса проживающего пересекается с другим периодом
      OPEN prep_refcursor FOR
        select k.* from kart k where k.fk_err = 2;
    elsif p_var = 3 then
      -- код REU не найден в представлении s_reu_trest
      OPEN prep_refcursor FOR
        select rownum as id, k.reu as text
          from kart k
         where not exists (select * from s_reu_trest t where t.reu = k.reu);
    elsif p_var = 4 then
      -- проверяем кол-во проживающих в карточках (кроме дополнительных счетов, - там не проверять! ред. 03.11.2015) 
      OPEN prep_refcursor FOR
        select k.*
          from kart k, v_lsk_tp tp
         where k.fk_tp = tp.id
           and tp.cd = 'LSK_TP_MAIN'
           and k.psch not in (8, 9) -- ред 05.12.18
           and k.kpr <>
               (select nvl(count(*), 0)
                  from c_kart_pr t
                 where t.lsk = k.lsk
                   and t.status not in (3, 6, 7) --не берём 6 код (временно прожив) ред.24.05.12 -- не берем код 3 - временно зарег, ред. 14.12.17, код 7 не берем ред.01.10.2019
                   and (case
                         when nvl(rec_params.is_fullmonth, 0) = 0 and
                              t.status = 4 and --если выписан до 15 то не считать
                              nvl(t.dat_ub, to_date('19000101', 'YYYYMMDD')) <= --если нет даты выписки, то как будто бы выписан давно (в 1900 году)))
                              to_date((select period || '15' from params),
                                      'YYYYMMDD') then
                          0
                         when nvl(rec_params.is_fullmonth, 0) = 0 and
                              t.status in (1, 5) and --если прописан после 15 то не считать
                              nvl(t.dat_prop, to_date('19000101', 'YYYYMMDD')) >= --если нет даты прописки, то как будто бы прописан давно (в 1900 году)))
                              to_date((select period || '15' from params),
                                      'YYYYMMDD') then
                          0
                         when nvl(rec_params.is_fullmonth, 0) = 1 and
                              t.status = 4 then
                          0 --если выписан, то не считать (не глядя на дату выписки из за fullmonth=1)
                         when nvl(rec_params.is_fullmonth, 0) = 1 and
                              t.status in (1, 5) then
                          1 --если прописан, то считать (не глядя на дату прописки из за fullmonth=1)
                         else
                          1
                       end = 1));
    elsif p_var = 5 then
      -- проверка показаний счетчиков
      OPEN prep_refcursor FOR
        select k.*
          from kart k, meter t, v_lsk_tp tp
         where k.psch not in (8, 9)
           and k.k_lsk_id = t.FK_KLSK_OBJ
           and t.fk_usl = '011'
           and k.phw <> t.n1
           and t.dt2 > gdt(1, 0, 0)
           and k.fk_tp = tp.id
           and tp.cd = 'LSK_TP_MAIN'
        union
        select k.*
          from kart k, meter t, v_lsk_tp tp
         where k.psch not in (8, 9)
           and k.k_lsk_id = t.FK_KLSK_OBJ
           and t.fk_usl = '015'
           and k.pgw <> t.n1
           and t.dt2 > gdt(1, 0, 0)
           and k.fk_tp = tp.id
           and tp.cd = 'LSK_TP_MAIN'
        union
        select k.*
          from kart k, meter t, v_lsk_tp tp
         where k.psch not in (8, 9)
           and k.k_lsk_id = t.FK_KLSK_OBJ
           and t.fk_usl = '038'
           and k.pel <> t.n1
           and t.dt2 > gdt(1, 0, 0)
           and k.fk_tp = tp.id
           and tp.cd = 'LSK_TP_MAIN';
    elsif p_var = 6 then
      -- проверка общей суммы в c_kwtp и c_kwtp_mg
      OPEN prep_refcursor FOR
        select 1 as id, nvl(a.summa, 0) - nvl(b.summa, 0) as text
          from (select nvl(sum(summa), 0) + nvl(sum(penya), 0) as summa
                   from c_kwtp t
                  where t.dat_ink between init.g_dt_start and init.g_dt_end) a, (select nvl(sum(summa),
                             0) +
                         nvl(sum(penya),
                             0) as summa
                   from c_kwtp_mg t
                  where t.dat_ink between
                        init.g_dt_start and
                        init.g_dt_end) b
         where nvl(a.summa, 0) - nvl(b.summa, 0) <> 0;
    elsif p_var = 7 then
      -- проверка на наличие не проинкассированных компьютеров
      OPEN prep_refcursor FOR
        select rownum as id, nkom as text
          from (select distinct t.nkom
                   from c_kwtp t
                  where nvl(t.nink, 0) = 0);
    elsif p_var = 8 then
      -- проверка на кол-во полей в A_CHARGE_PREP2
      OPEN prep_refcursor FOR
        select 1 as id, count(*) as text
          from ALL_TAB_COLUMNS t
         where t.TABLE_NAME = 'A_CHARGE_PREP2'
           and lower(t.OWNER) = 'scott' having count(*) <> 18;
    elsif p_var = 9 then
      -- проверка на кол-во полей в A_CHARGE2
      OPEN prep_refcursor FOR
        select 1 as id, count(*) as text
          from ALL_TAB_COLUMNS t
         where t.TABLE_NAME = 'A_CHARGE2'
           and lower(t.OWNER) = 'scott' having count(*) <> 22;
    elsif p_var = 10 then
      -- проверка на кол-во полей в A_CHARGE2
      OPEN prep_refcursor FOR
        select 1 as id, count(*) as text
          from ALL_TAB_COLUMNS t
         where t.TABLE_NAME = 'A_NABOR2'
           and lower(t.OWNER) = 'scott' having count(*) <> 24;
    elsif p_var = 11 then
      -- проверка общей суммы в c_kwtp и kwtp_day
      OPEN prep_refcursor FOR
        select 1 as id, nvl(a.summa, 0) - nvl(b.summa, 0) as text
          from (select nvl(sum(summa), 0) + nvl(sum(penya), 0) as summa
                   from c_kwtp t
                  where t.dat_ink between init.g_dt_start and init.g_dt_end) a, (select sum(summa) as summa
                   from kwtp_day t
                  where t.nkom<>'999' and -- кроме корректировок ред. 05.08.2019
                        t.dat_ink between
                        init.g_dt_start and
                        init.g_dt_end) b
         where nvl(a.summa, 0) - nvl(b.summa, 0) <> 0;
    
    end if;
  
    -- Проверки после итог.формирования
    if p_var = 100 then
      -- проверка распределения пени, после формирования сальдо
      -- ВНИМАНИЕ! выполнять сразу после формирования распределения пени, так как 
      -- текущими действиями пользователи меняют состояние C_PEN_CUR! 
      OPEN prep_refcursor FOR
        select rownum as id, nvl(a.lsk, b.lsk) || ':' || to_char(nvl(a.summa, 0) -
                nvl(b.summa, 0)) as text
                   from (select t.lsk, sum(summa) as summa
                   from (select c.lsk, c.mg1, round(sum(penya), 2) as summa
                            from c_pen_cur c
                           group by c.lsk, c.mg1
                          union all
                          select c.lsk, c.dopl, c.penya -- прибавить корректировку пени за месяц
                            from c_pen_corr c) t
                  group by t.lsk) a
          full join (select c.lsk, sum(summa) as summa
                       from t_chpenya_for_saldo c
                      group by c.lsk) b
            on a.lsk = b.lsk
         where nvl(a.summa, 0) <> nvl(b.summa, 0);
    elsif p_var = 101 then
      -- проверка сальдо по пене
      OPEN prep_refcursor FOR
        select rownum as id, k.lsk as text
          from kart k
          left join (select t.lsk, sum(t.penya) as pen_in
                       from a_penya t, v_params p
                      where t.mg = p.period3
                      group by t.lsk) b
            on k.lsk = b.lsk
          left join (select a.lsk, sum(a.penya) as pen_cur
                       from (select t.lsk, t.mg1, round(sum(t.penya), 2) as penya
                                from a_pen_cur t, params p
                               where t.mg = p.period
                               group by t.lsk, t.mg1) a
                      group by a.lsk) d
            on k.lsk = d.lsk
          left join (select t.lsk, sum(t.penya) as pen_cor
                       from a_pen_corr t, params p
                      where t.mg = p.period
                      group by t.lsk) e
            on k.lsk = e.lsk
          left join (select t.lsk, sum(t.penya) as pen_pay
                       from a_kwtp_mg t, params p
                      where t.mg = p.period
                      group by t.lsk) f
            on k.lsk = f.lsk
          left join (select t.lsk, sum(t.penya) as pen_out
                       from a_penya t, params p
                      where t.mg = p.period
                      group by t.lsk) g
            on k.lsk = g.lsk
        
         where nvl(b.pen_in, 0) + nvl(d.pen_cur, 0) + nvl(e.pen_cor, 0) -
               nvl(f.pen_pay, 0) <> nvl(g.pen_out, 0);
    elsif p_var = 102 then
      -- проверка, что сальдо исх идёт (бывает, когда удалят платёж без переформирования)
      OPEN prep_refcursor FOR
        select rownum as id, nvl(t.lsk, s.lsk) as text
          from (select * from xitog3_lsk where mg = rec_params.period) t
          full join (select * from saldo_usl where mg = l_mg1) s
            on t.lsk = s.lsk
           and t.usl = s.usl
           and t.org = s.org
         where nvl(t.outdebet, 0) + nvl(t.outkredit, 0) <> nvl(s.summa, 0);
    elsif p_var = 103 then
      -- проверка, что идет долг в c_chargepay с a_penya  
      OPEN prep_refcursor FOR
        select rownum as id, nvl(a.lsk, b.lsk) as text
          from (select t.lsk, sum(summa) as summa
                   from a_PENYA t
                  where t.mg = rec_params.period
                  group by t.lsk) a
          full join (select t.lsk, sum(summa) as summa
                       from v_chargepay t
                      where t.period = rec_params.period
                      group by t.lsk) b
            on a.lsk = b.lsk
         where nvl(a.summa, 0) <> nvl(b.summa, 0);
    elsif p_var = 104 then
      -- проверка, что начисление идёт с начислением в оборотке (да, да, без учёта перерасчетов - не получилось с ними)
      OPEN prep_refcursor FOR
        select rownum as id, nvl(t.lsk, s.lsk) as text
          from (select * from xitog3_lsk where mg = rec_params.period) t
          full outer join (select r.lsk, r.usl, o.fk_org2 as org, sum(r.summa) as summa
                             from c_charge r, nabor n, t_org o
                            where r.lsk = n.lsk
                              and r.type = 1
                              and r.usl = n.usl
                              and n.org = o.id
                            group by r.lsk, r.usl, o.fk_org2) s
            on t.lsk = s.lsk
           and t.usl = s.usl
           and t.org = s.org
         where nvl(t.charges, 0) - nvl(t.changes, 0) - nvl(t.changes2, 0) -
               nvl(t.changes3, 0) <> nvl(s.summa, 0);
    elsif p_var = 105 then
      -- проверка, что перерасчеты идут с перерасчетами в оборотке 
      OPEN prep_refcursor FOR
        select rownum as id, nvl(t.lsk, s.lsk) as text
          from (select lsk, nvl(sum(changes), 0) + nvl(sum(changes2), 0) as summa
                   from xitog3_lsk
                  where mg = rec_params.period
                  group by lsk) t
          full join (select r.lsk, sum(r.summa) as summa
                       from c_change r
                      group by r.lsk) s
            on t.lsk = s.lsk
         where nvl(t.summa, 0) <> nvl(s.summa, 0);
    elsif p_var = 106 then
      -- проверка, что оплата идёт с оплатой в оборотке
      OPEN prep_refcursor FOR
        select rownum as id, nvl(t.lsk, s.lsk) as text
          from (select * from xitog3_lsk where mg = rec_params.period) t
          full join (select r.lsk, r.usl, r.org, sum(r.summa) as summa
                       from kwtp_day r
                      where r.priznak = 1
                        and r.dat_ink between init.g_dt_start and
                            init.g_dt_end
                      group by r.lsk, r.usl, r.org) s
            on t.lsk = s.lsk
           and t.usl = s.usl
           and t.org = s.org
         where nvl(t.payment, 0) <> nvl(s.summa, 0);
    elsif p_var = 107 then
      -- проверка сальдо с движением в совокупности
      OPEN prep_refcursor FOR
        select 1 as id, nvl(a.summa, 0) - nvl(b.summa, 0) as text
          from (select sum(decode(type, 1, -1 * summa, summa)) as summa
                   from c_chargepay t, params p
                  where t.period = p.period) a, (select sum(summa) as summa
                   from saldo_usl t, params p
                  where mg =
                        to_char(add_months(to_date(p.period || '01',
                                                   'YYYYMMDD'),
                                           1),
                                'YYYYMM')) b
         where nvl(a.summa, 0) - nvl(b.summa, 0) <> 0;
    elsif p_var = 108 then
      -- проверка сальдо с движением по лиц.сч.
      OPEN prep_refcursor FOR
        select c.*
          from kart c, (select t.lsk, sum(decode(type, 1, -1 * summa, summa)) as summa
                   from c_chargepay t, params p
                  where t.period = p.period
                  group by t.lsk) a, (select t.lsk, sum(summa) as summa
                   from saldo_usl t, params p
                  where mg = to_char(add_months(to_date(p.period || '01',
                                                        'YYYYMMDD'),
                                                1),
                                     'YYYYMM')
                  group by t.lsk) b
         where c.lsk = a.lsk(+)
           and c.lsk = b.lsk(+)
           and nvl(a.summa, 0) <> nvl(b.summa, 0);
    elsif p_var = 109 then
      -- проверка что в сальдо не присутствуют организации ниже уровня 1
      OPEN prep_refcursor FOR
        select rownum as id, a.name as text
          from (select level as lvl, t.id, t.name
                   from scott.t_org t
                 connect by prior t.id = t.parent_id2
                  start with t.parent_id2 is null
                  order by level) a
         where a.lvl > 1
           and exists (select *
                  from saldo_usl s, v_params p
                 where s.mg = p.period1
                   and s.org = a.id);
    elsif p_var = 110 then
      -- проверка после итогового формирования, на получение всех показаний счетчиков
      -- (при наличии ЛК)
      execute immediate 'select proc.check_is_acpt_sch@Apex(:l_cd_org) from dual'
        into l_cnt
        using l_cd_org;
      if l_cnt <> 0 then
        -- не все учтены
        OPEN prep_refcursor FOR
          select 1 as id, null as text from dual;
      else
        -- все учтены
        OPEN prep_refcursor FOR
          select 1 as id, null as text from dual where 1 = 2;
      end if;
    elsif p_var = 111 then
      -- проверка после итогового формирования, на соответствие периода в ЛК
      -- (при наличии ЛК)
      execute immediate 'select proc.check_period@Apex(:l_cd_org, p.period) from params p'
        into l_cnt
        using l_cd_org;
      if l_cnt <> 0 then
        -- несоответствует 
        OPEN prep_refcursor FOR
          select 1 as id, null as text from dual;
      else
        -- соответствует
        OPEN prep_refcursor FOR
          select 1 as id, null as text from dual where 1 = 2;
      end if;
    elsif p_var = 112 then
      -- проверка сальдо по пене в оборотке
      OPEN prep_refcursor FOR
        select rownum as id, a.lsk as text
          from (select t.lsk, t.usl, t.org, sum(t.pinsal) as pinsal, sum(t.pcur) as pcur, sum(t.pn) as pn, sum(t.poutsal) as poutsal
                   from xitog3_lsk t
                   join params p
                     on t.mg = p.period
                  group by t.lsk, t.usl, t.org) a
         where nvl(a.pinsal, 0) + nvl(a.pcur, 0) - nvl(a.pn, 0) <>
               nvl(a.poutsal, 0);
    elsif p_var = 113 then
      -- проверка что исх.сальдо по пене идёт в A_PENYA и XITOG3_LSK
      OPEN prep_refcursor FOR
        select rownum as id, nvl(a.lsk, b.lsk) as text
          from (select t.lsk, sum(t.penya) as summa
                   from A_PENYA t
                  where t.mg = rec_params.period
                  group by t.lsk) a
          full join (select t.lsk, sum(t.poutsal) as summa
                       from xitog3_lsk t
                      where t.mg = rec_params.period
                      group by t.lsk) b
            on a.lsk = b.lsk
         where nvl(a.summa, 0) <> nvl(b.summa, 0);
    elsif p_var = 114 then
      -- список лс. по которым не корректно распр.пеня
      OPEN prep_refcursor FOR
        select rownum as id, nvl(a.lsk, b.lsk) as text from 
        (select s.lsk, sum(s.summa) as summa from 
        (select t.lsk, round(sum(t.summa),2) as summa from 
        (select c.lsk, c.mg1, c.penya as summa from c_pen_cur c
         union all 
         select c.lsk, c.dopl, c.penya as summa from c_pen_corr c) t
         group by t.lsk, t.mg1) s group by s.lsk
        ) a full outer join
        (select c.lsk, sum(summa) as summa from t_chpenya_for_saldo c group by lsk) b
        on a.lsk=b.lsk
        where nvl(a.summa,0) - nvl(b.summa,0) <> 0;
    end if;
  
  end;

end P_THREAD;
/


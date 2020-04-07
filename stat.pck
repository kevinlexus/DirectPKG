CREATE OR REPLACE PACKAGE SCOTT.stat IS
  TYPE rep_refcursor IS REF CURSOR;
  PROCEDURE rep_stat(reu_           IN VARCHAR2,
                     p_for_reu      IN VARCHAR2, -- для статы, УК содержащая фонд
                     kul_           IN VARCHAR2,
                     nd_            IN VARCHAR2,
                     trest_         IN VARCHAR2,
                     mg_            IN VARCHAR2,
                     mg1_           IN VARCHAR2,
                     dat_           IN DATE,
                     dat1_          IN DATE,
                     var_           IN NUMBER,
                     det_           IN NUMBER,
                     org_           IN NUMBER,
                     oper_           IN VARCHAR2,
                     сd_            IN VARCHAR2,
                     spk_id_        IN NUMBER,
                     p_house        IN NUMBER,
                     p_out_tp       IN NUMBER,   --тип выгрузки (null- в рефкурсор, 1-в текстовый файл в дир по умолчанию)
                     prep_refcursor IN OUT rep_refcursor);
procedure rep_detail(p_cd in varchar2, p_mg in params.period%type, p_lsk in kart.lsk%type,
                       prep_refcursor in out rep_refcursor);


PROCEDURE SQLTofile(p_sql IN VARCHAR2,
                    p_dir IN VARCHAR2,
                    p_header_file IN VARCHAR2,
                    p_data_file IN VARCHAR2 := NULL,
                    p_dlmt IN Varchar2 :=';' --разделитель, по умолчанию - ';'
                    );

END stat;
/

CREATE OR REPLACE PACKAGE BODY SCOTT.stat IS
  PROCEDURE rep_stat(reu_           IN VARCHAR2,
                     p_for_reu      IN VARCHAR2, -- для статы, УК содержащая фонд
                     kul_           IN VARCHAR2,
                     nd_            IN VARCHAR2,
                     trest_         IN VARCHAR2,
                     mg_            IN VARCHAR2,
                     mg1_           IN VARCHAR2,
                     dat_           IN DATE,
                     dat1_          IN DATE,
                     var_           IN NUMBER, --уровень информации
                     det_           IN NUMBER, --детализация информации
                     org_           IN NUMBER,
                     oper_           IN VARCHAR2,
                     сd_            IN VARCHAR2, --CD отчета
                     spk_id_        IN NUMBER,
                     p_house        IN NUMBER,   --ID дома
                     p_out_tp       IN NUMBER,   --тип выгрузки (null- в реф-курсор, 1-в текстовый файл в дир по умолчанию)
                     prep_refcursor IN OUT rep_refcursor) IS

    sqlstr_ VARCHAR2(2000);
    sqlstr2_ VARCHAR2(2000);
    sqlstr3_ VARCHAR2(2000);
    l_sql VARCHAR2(2000); --для хранения полного текста запроса
    period_ varchar2(55);
    uslg_ usl.uslg%type;
    mg2_ params.period%type;
    l_mg_next params.period%type;
    dat2_ date;
    dat3_ date;
    n1_   NUMBER;
    n2_   NUMBER;
    kpr1_   NUMBER;
    kpr2_   NUMBER;
    show_sal_ number;
    cur_pay_ number;
    gndr_ number;
    prop_ number;
    show_fond_ number;
    fk_ses_ number;
    l_dt date;
    l_dt1 date;
    l_in_period number;
    l_out_period number;
    l_cur_period params.period%type;
    l_prev_period params.period%type;
    l_cnt number;
    l_sel varchar2(256);
    l_sel_id number;
    l_period_tp number;
    l_char_dat_mg varchar2(6);
    l_str_dat varchar2(10);
    l_str_dat1 varchar2(10);
--    TYPE l_cur_type IS REF CURSOR;
--    l_cur sys_refcursor;
/*    TYPE l_rec_type IS RECORD ( fld1 VARCHAR2(100),
                                fld2 VARCHAR2(100),
                                fld3 VARCHAR2(100),
                                fld4 VARCHAR2(100),
                                fld5 VARCHAR2(100),
                                fld6 VARCHAR2(100),
                                fld7 VARCHAR2(100),
                                fld8 VARCHAR2(100),
                                fld9 VARCHAR2(100),
                                fld10 VARCHAR2(100),
                                fld11 VARCHAR2(100),
                                fld12 VARCHAR2(100)
                                  );*/
--    l_rec l_cur%ROWTYPE;
    BEGIN
    select USERENV('sessionid') into fk_ses_ from dual;
    select period into l_cur_period from params;

    l_char_dat_mg:=to_char(dat_,'YYYYMM');
    
    --вычислить первую и последнюю даты заданных периодов, для оптимизации запросов.
    if mg_ is not null then
      l_dt:=to_date(mg_||'01','YYYYMMDD');
    end if;
    if mg1_ is not null then
      l_dt1:=last_day(to_date(mg1_||'01','YYYYMMDD'));
    end if;
    --Вычисляем передыдущ месяц
    if dat_ is not null then
      l_prev_period := to_char(add_months(dat_ , -1),
                      'YYYYMM');
    else  
      l_prev_period := to_char(add_months(to_date(mg_ || '01', 'YYYYMMDD'), -1),
                      'YYYYMM');
    end if;
    -- конвертировать в формат строки дату
    if dat_ is not null then
          l_str_dat:=to_char(dat_, 'DD.MM.YYYY');        
    end if;              
    if dat1_ is not null then
          l_str_dat1:=to_char(dat1_, 'DD.MM.YYYY');        
    end if;              

    --Вычисляем следующий месяц
    if mg_ is not null then
      l_mg_next := to_char(add_months(to_date(mg_ || '01', 'YYYYMMDD'), 1),
                      'YYYYMM');
    end if;
    --узнать находится ли заданные даты отчета в текущем периоде
    select case when not l_dt between to_date(p.period||'01','YYYYMMDD')
       and last_day(to_date(p.period||'01','YYYYMMDD'))
       or
       not l_dt1 between to_date(p.period||'01','YYYYMMDD')
         and last_day(to_date(p.period||'01','YYYYMMDD')) then 1
       else 0
       end,
       case when l_dt between to_date(p.period||'01','YYYYMMDD')
       and last_day(to_date(p.period||'01','YYYYMMDD'))
       or
         l_dt1 between to_date(p.period||'01','YYYYMMDD')
         and last_day(to_date(p.period||'01','YYYYMMDD')) then 1
       else 0
       end into l_out_period, l_in_period
     from params p;

    if dat_ is not null and dat1_ is not null then
      sqlstr_ := 's.dat between TO_DATE(''' || TO_CHAR(dat_, 'DDMMYYYY') ||
                 ''',''DDMMYYYY'') and TO_DATE(''' || TO_CHAR(dat1_, 'DDMMYYYY') ||
                 ''',''DDMMYYYY'')';
      period_:='с '||to_char(dat_,'DD.MM.YYYY')||' по '||to_char(dat1_,'DD.MM.YYYY');
      sqlstr3_ := 'd.dat between TO_DATE(''' || TO_CHAR(dat_, 'DDMMYYYY') ||
                 ''',''DDMMYYYY'') and TO_DATE(''' || TO_CHAR(dat1_, 'DDMMYYYY') ||
                 ''',''DDMMYYYY'')';
      sqlstr2_ := 's.period between ''' || to_char(dat_, 'YYYYMM') || ''' and ''' || to_char(dat_, 'YYYYMM')||'''';
      l_period_tp:=0;
    elsif dat_ is not null and dat1_ is null then
      sqlstr_ := 's.dat = TO_DATE('' ' || TO_CHAR(dat_, 'DDMMYYYY') ||
                 ' '',''DDMMYYYY'')';
      period_:='с '||to_char(dat_,'DD.MM.YYYY')||' по '||to_char(dat1_,'DD.MM.YYYY');
      sqlstr3_ := 'd.dat between TO_DATE(''' || TO_CHAR(dat_, 'DDMMYYYY') ||
                 ''',''DDMMYYYY'') and TO_DATE(''' || TO_CHAR(dat1_, 'DDMMYYYY') ||
                 ''',''DDMMYYYY'')';
      sqlstr2_ := 's.period between ''' || to_char(dat_, 'YYYYMM') || ''' and ''' || to_char(dat_, 'YYYYMM')||'''';
      l_period_tp:=1;
    else
      if mg_ = mg1_ then
        period_:=utils.month_name(substr(mg_, 5, 2))||' '||substr(mg_,1,4)||'г.';
      else
        period_:='с '||utils.month_name1(substr(mg_, 5, 2))||' '||substr(mg_,1,4)||'г.'||' по '||utils.month_name(substr(mg1_, 5, 2))||' '||substr(mg_,1,4)||'г.';
      end if;
      sqlstr_ := 's.mg between ''' || mg_ || ''' and ''' || mg1_||'''';
      sqlstr2_ := 's.period between ''' || mg_ || ''' and ''' || mg1_||'''';
      sqlstr3_ := 'd.mg between ''' || mg_ || ''' and ''' || mg1_||'''';
      l_period_tp:=2;
    end if;


    IF сd_ = '22' THEN
    --Статистика по долгам
     IF var_ = 3 THEN
        --По дому
        OPEN prep_refcursor FOR 'select t.trest||'' ''||t.name_tr as predp, d.reu,
     d.reu||d.kul||d.nd||'' ''||k.name||'', ''||NVL(LTRIM(d.nd,''0''),''0'') AS predpr_det,
     LTRIM(d.kw,''0'') AS kw, substr(d.mg, 1, 4)||''-''||substr(d.mg, 5, 2) AS mg, d.summa,d.dat,SUBSTR(''000''||d.kol_month,-3) AS kol_month
     FROM DEBITS_KW d, S_REU_TREST t, SPUL k
     WHERE d.reu=t.reu
     AND d.kul=k.id
     AND d.reu=:reu_
     AND d.kul=:kul_
     AND d.nd=:nd_
     AND  d.dat BETWEEN :dat_ AND :dat1_  ORDER BY d.mg DESC'
           USING reu_, kul_, nd_,dat_,dat1_;
       ELSIF var_ = 2 THEN
        --По РЭУ
        OPEN prep_refcursor FOR 'select t.trest||'' ''||t.name_tr as predp, d.reu,
     d.reu||d.kul||d.nd||'' ''||k.name||'', ''||NVL(LTRIM(d.nd,''0''),''0'') AS predpr_det,
     NULL AS kw, substr(d.mg, 1, 4)||''-''||substr(d.mg, 5, 2) AS mg, summa,d.dat,SUBSTR(''000''||d.kol_month,-3) AS kol_month
     FROM DEBITS_HOUSES d, S_REU_TREST t, SPUL k
     WHERE d.reu=t.reu
     AND d.kul=k.id
     AND t.reu=:reu_
     AND d.dat BETWEEN :dat_ AND :dat1_ ORDER BY d.mg DESC'
           USING reu_,dat_,dat1_;
       ELSIF var_ = 1 THEN
        --По ЖЭО
        OPEN prep_refcursor FOR 'select t.trest||'' ''||t.name_tr as predp, d.reu, null as predpr_det,
     NULL AS kw, substr(d.mg, 1, 4)||''-''||substr(d.mg, 5, 2) AS mg, d.summa,d.dat,SUBSTR(''000''||d.kol_month,-3) AS kol_month
     FROM DEBITS_TREST d, S_REU_TREST t
     WHERE d.reu=t.reu
     AND t.trest=:trest_
     AND d.dat BETWEEN :dat_ AND :dat1_ ORDER BY d.mg DESC'
          USING trest_,dat_,dat1_;
      ELSIF var_ = 0 THEN
        --По МП УЕЗЖКУ (все тресты)
        OPEN prep_refcursor FOR 'select t.trest||'' ''||t.name_tr as predp, d.reu, null as predpr_det,
     NULL AS kw,substr(d.mg, 1, 4)||''-''||substr(d.mg, 5, 2) AS mg,summa,d.dat,SUBSTR(''000''||d.kol_month,-3) AS kol_month
     FROM DEBITS_TREST d, S_REU_TREST t
     WHERE d.reu=t.reu
     AND d.dat BETWEEN :dat_ AND :dat1_ ORDER BY d.mg DESC'
     USING dat_,dat1_;
     END IF;

    ELSIF сd_ = '13' THEN
      --Статистика по услугам
      l_sel_id:=utils.getS_list_param('REP_TP_SCH_SEL');
   IF det_ = 3 then
     kpr1_:=utils.getS_int_param('REP_RNG_KPR1');
     kpr2_:=utils.getS_int_param('REP_RNG_KPR2');
--Raise_application_error(-20000, kpr1_||'-'||kpr2_);
   --детализация до квартир
        OPEN prep_refcursor FOR select s.lsk, s.org, coalesce(r.fk_org_dst,s.org) as fk_org2, u.uslm, s.usl, s.kul,
    t.trest, s.reu, k.name,
    k.name||', '||NVL(LTRIM(s.nd,'0'),'0')||'-'||NVL(LTRIM(s.kw,'0'),'0') AS predpr_det,
    --utils.f_order(s.nd,6) as ord1, utils.f_order2(s.nd) as ord3, utils.f_order(s.kw,7) as ord2,
    det.ord1,
    k1.fio,
    s.status, s.psch as psch,
    s.sch as sch, s.val_group, s.val_group2,
    s.cnt AS cnt, s.klsk AS klsk, s.kpr AS kpr, decode(s.is_empt,1,'да',0,'нет', null) as is_empt, s.kpr_ot AS kpr_ot,
    s.kpr_wr AS kpr_wr, s.cnt_lg AS cnt_lg, s.cnt_subs AS cnt_subs, s.cnt_room, s.uch,
    substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2) as mg1,
    u.npp,
    null as name_gr, null as odpu_ex, 0 as odpu_kub, 0 as kub_dist, 0 as kub_fact,0 as kub_fact_upnorm, 
    tp.name as lsk_tp, s.opl, s.is_vol, s.chng_vol,
    null as isHotPipe,
    null as isTowel,
    null as kr_soi,
    null as fact_cons
    FROM STATISTICS_LSK s
         join USL u on s.USL=u.USL
         join S_REU_TREST t on s.reu=t.reu
         join SPUL k on s.kul=k.id
         join kart k1 on s.lsk=k1.lsk
         join kart_detail det on k1.lsk=det.lsk
         left join v_lsk_tp tp on s.fk_tp=tp.id
         left join redir_pay r on s.org=r.fk_org_src and s.mg between r.mg1 and r.mg2
    WHERE
    exists
       (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
            and p.id=i.fk_par and p.cd='REP_USL'
            and i.sel_cd=s.usl
        and i.sel=1)
    and exists
       (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
            and p.id=i.fk_par and p.cd='REP_STATUS'
            and i.sel_id=s.status
        and i.sel=1)
    and ((var_=3 and
           s.reu = reu_ and case when s.for_reu is null then 1
                                             when p_for_reu is null then 1
                                             when s.for_reu = p_for_reu then 1
                                             else 0 end =1  
           and s.kul = kul_
           and s.nd = nd_)
          or (var_=2 and s.reu=reu_ and case when s.for_reu is null then 1
                                             when p_for_reu is null then 1
                                             when s.for_reu = p_for_reu then 1
                                             else 0 end =1  
           )                        
          or (var_=1 and t.trest=trest_)
          or var_=0)
    and exists
    (select * from statistics_lsk st, usl ut where st.lsk=s.lsk and st.mg=s.mg and
       st.usl=ut.usl and ut.uslm=u.uslm
       and (kpr1_ is not null and st.kpr >=kpr1_ or kpr1_ is null)
       and (kpr2_ is not null and st.kpr <=kpr2_ or kpr2_ is null)
      )
    and (l_sel_id = 0 or l_sel_id <> 0 and l_sel_id = s.fk_tp)
    and s.mg between  mg_  and mg1_
    union all
    select null as lsk, null as org, null as fk_org2, '000' as uslm, '000' as usl, s.kul,
    t.trest, s.reu, k.name,
    k.name||', '||NVL(LTRIM(s.nd,'0'),'0')||'-'||NVL(LTRIM(s.kw,'0'),'0') AS predpr_det,
    --utils.f_order(s.nd,6) as ord1, utils.f_order2(s.nd) as ord3, utils.f_order(s.kw,7) as ord2,
    det.ord1,
    k1.fio,
    s.status, s.psch as psch,
    s.sch as sch, s.val_group, s.val_group2,
    s.cnt AS cnt, s.klsk AS klsk, s.kpr AS kpr, decode(s.is_empt,1,'да',0,'нет', null) as is_empt, s.kpr_ot AS kpr_ot,
    s.kpr_wr AS kpr_wr, s.cnt_lg AS cnt_lg, s.cnt_subs AS cnt_subs, s.cnt_room, s.uch,
    substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2) as mg1,
    null as npp,
    null as name_gr, null as odpu_ex, 0 as odpu_kub, 0 as kub_dist, 0 as kub_fact, 0 as kub_fact_upnorm, 
    tp.name as lsk_tp, s.opl, s.is_vol, s.chng_vol,
    null as isHotPipe,
    null as isTowel,
    null as kr_soi,
    null as fact_cons
    FROM STATISTICS_LSK s 
    join S_REU_TREST t on s.reu=t.reu
    join SPUL k on s.kul=k.id
    left join v_lsk_tp tp on s.fk_tp=tp.id
    join kart_detail det on s.lsk=det.lsk
    join kart k1 on s.lsk=k1.lsk
    WHERE s.USL is null
    and exists
       (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
            and p.id=i.fk_par and p.cd='REP_USL'
            and i.sel_cd='0' --Включить ли ИТОГ?
        and i.sel=1)
    and exists
       (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
            and p.id=i.fk_par and p.cd='REP_STATUS'
            and i.sel_id=s.status
        and i.sel=1)
    and ((var_=3 and
           s.reu = reu_ 
           and s.kul = kul_
           and s.nd = nd_)
          or (var_=2 and s.reu=reu_)
          or (var_=1 and t.trest=trest_)
          or var_=0)
    --неоднозначность какая то... если по услугам то фильтр по кол-ву прожив один, а если по итогам - по другому принципу...
    and (kpr1_ is not null and s.kpr >=kpr1_ or kpr1_ is null)
    and (kpr2_ is not null and s.kpr <=kpr2_ or kpr2_ is null)
    and (l_sel_id = 0 or l_sel_id <> 0 and l_sel_id = s.fk_tp)
    AND s.mg between mg_ and mg1_ 
    order by ord1; --не убирай порядок сортировки!
    ELSIF det_ = 2 then
    -- -------------------------------------------------------------------------------------------------
    -- ВНИМАНИЕ! В КИС  A_NABOR2 - ПАРТИЦИРОВАННАЯ ТАБЛИЦА ПО MGFROM С ВЛОЖЕННОЙ СУБПАРТИЦИЕЙ ПО MGTO!!!
    -- -------------------------------------------------------------------------------------------------
    -- из за того, что тормозил внутренний запрос, пришлось вынести в temporary table ред.26.10.2017
    delete from temp_stat2;      
/*    insert into temp_stat2
      (kub, kub_dist, kub_fact_upnorm, kub_fact, usl, mg, reu, kul, nd, dist_tp, 
       odpu_ex, ishotpipeinsulated, istowelheatexist, kr_soi, fact_cons)
      select --для отображения объемов по ОДПУ
                        sum(d.kub), sum(d.kub_dist), sum(d.kub_fact_upnorm), 
                        sum(decode(d.dist_tp, 4, null, d.kub_fact)) as kub_fact, -- не показывать объем, если 4 (нет ОДПУ) ред.05.03.2017
                        d.usl, d.mg, h.reu, h.kul, h.nd, d.dist_tp as dist_tp,
                        case when d.dist_tp<>4 and nvl(d.kub,0) = 0 then 'есть, нет объема'
                        when d.dist_tp<>4 and nvl(d.kub,0) <> 0 then 'есть'
                        else 'нет' end as odpu_ex, nvl(d.ishotpipeinsulated,0) as ishotpipeinsulated, 
                        nvl(d.istowelheatexist,0) as istowelheatexist, 
                        sum(d.kub - (d.kub_norm + d.kub_sch + d.kub_ar)) as kr_soi, -- кр на сои
                        sum(d.kub_norm + d.kub_sch + d.kub_ar) as fact_cons -- факт.потребление
                        from a_vvod d, arch_kart h, a_nabor2 n, s_reu_trest s,
                        usl u
                  where h.house_id=d.house_id and h.mg=d.mg and d.mg between mg_ and mg1_
                        and d.usl=u.usl
                        and d.id=n.fk_vvod and d.usl=n.usl and h.lsk=n.lsk and d.mg between n.mgFrom and n.mgTo
                        and h.psch not in (8,9)
                        and h.reu=s.reu 
                        and case when var_=3 and h.reu = reu_
                           and h.kul = kul_
                           and h.nd = nd_ then 1
                           when var_=2 and h.reu=reu_ then 1
                           when var_=1 and s.trest=trest_ then 1
                           when var_=0 then 1
                           end = 1
                  group by 
                        d.usl, d.mg, h.reu, h.kul, h.nd, d.dist_tp,
                        case when d.dist_tp<>4 and nvl(d.kub,0) = 0 then 'есть, нет объема'
                        when d.dist_tp<>4 and nvl(d.kub,0) <> 0 then 'есть'
                        else 'нет' end, nvl(d.ishotpipeinsulated,0), 
                        nvl(d.istowelheatexist,0);*/
    insert into temp_stat2
      (kub, kub_dist, kub_fact_upnorm, kub_fact, usl, mg, reu, kul, nd, dist_tp, 
       odpu_ex, ishotpipeinsulated, istowelheatexist, kr_soi, fact_cons)
      select --для отображения объемов по ОДПУ
                        distinct d.kub, d.kub_dist, d.kub_fact_upnorm, 
                        decode(d.dist_tp, 4, null, d.kub_fact) as kub_fact, -- не показывать объем, если 4 (нет ОДПУ) ред.05.03.2017
                        d.usl, d.mg, h.reu, h.kul, h.nd, d.dist_tp as dist_tp,
                        case when d.dist_tp<>4 and nvl(d.kub,0) = 0 then 'есть, нет объема'
                        when d.dist_tp<>4 and nvl(d.kub,0) <> 0 then 'есть'
                        else 'нет' end as odpu_ex, nvl(d.ishotpipeinsulated,0) as ishotpipeinsulated, 
                        nvl(d.istowelheatexist,0) as istowelheatexist, 
                        case when d.usl not in ('053','054') then d.kub - (d.kub_norm + d.kub_sch + d.kub_ar)
                          else 0 end as kr_soi, -- кр на сои (только для первой строки) и не для 053 и 054 услуг
                        d.kub_norm + d.kub_sch + d.kub_ar as fact_cons  -- факт.потребление (только для первой строки)
                        from a_vvod d, arch_kart h, a_nabor2 n, s_reu_trest s,
                        usl u
                  where h.house_id=d.house_id and h.mg=d.mg and d.mg between mg_ and mg1_
                        and d.usl=u.usl
                        and d.id=n.fk_vvod and d.usl=n.usl and h.lsk=n.lsk and d.mg between n.mgFrom and n.mgTo
                        and h.psch not in (8,9)
                        and h.reu=s.reu 
                        and case when var_=3 and h.reu = reu_
                           and h.kul = kul_
                           and h.nd = nd_ then 1
                           when var_=2 and h.reu=reu_ then 1
                           when var_=1 and s.trest=trest_ then 1
                           when var_=0 then 1
                           end = 1;
                           
                           
   delete from temp_stat3;
   insert into temp_stat3
     (mg, reu, kul, nd, name)
   select distinct h.mg, h.reu, h.kul, h.nd, o.name
                        from arch_kart h, a_houses s, t_org o, s_reu_trest s
        where h.house_id=s.id and h.mg=s.mg and h.mg between mg_ and mg1_ and s.fk_other_org=o.id(+) 
                        and h.psch not in (8,9)
                        and case when var_=3 and h.reu = reu_
                           and h.kul = kul_
                           and h.nd = nd_ then 1
                           when var_=2 and h.reu=reu_ then 1
                           when var_=1 and s.trest=trest_ then 1
                           when var_=0 then 1
                           end = 1;
    
   --детализация до домов
        OPEN prep_refcursor FOR select null as lsk, s.org, coalesce(r.fk_org_dst,s.org) as fk_org2, u.uslm, s.usl,
        s.kul,
    t.trest, s.reu, k.name,
    k.name||', '||NVL(LTRIM(s.nd,'0'),'0') AS predpr_det,
    utils.f_order(s.nd,6) as ord1, utils.f_order2(s.nd) as ord3,
    null as fio,
    s.status, s.psch as psch,
    s.sch as sch, s.val_group, s.val_group2,
    s.cnt AS cnt, s.klsk AS klsk, s.kpr AS kpr, decode(s.is_empt,1,'да',0,'нет', null) as is_empt, s.kpr_ot AS kpr_ot,
    s.kpr_wr AS kpr_wr, s.cnt_lg AS cnt_lg, s.cnt_subs AS cnt_subs, s.cnt_room, s.uch,
    substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2) as mg1,
    u.npp, h3.name as name_gr, nvl(h4.odpu_ex, 'нет') as odpu_ex,
    decode(s.fr, 1, h2.kub, 0) as odpu_kub, 
    decode(s.fr, 1, h2.kub_dist, 0) as kub_dist, 
    decode(s.fr, 1, h2.kub_fact, 0) as kub_fact, 
    decode(s.fr, 1, h2.kub_fact_upnorm, 0) as kub_fact_upnorm, 
    tp.name as lsk_tp, s.opl, s.is_vol, s.chng_vol,
    decode(h5.ishotpipeinsulated,1,'да','нет') as isHotPipe,
    decode(h5.istowelheatexist,1,'да','нет') as isTowel,
    decode(s.fr, 1, h2.kr_soi, 0) as kr_soi, 
    decode(s.fr, 1, h2.fact_cons, 0) as fact_cons
    FROM 
          STATISTICS s
          join usl u on s.usl=u.usl
          join S_REU_TREST t on s.reu=t.reu
          join SPUL k on s.kul=k.id
          left join redir_pay r on s.org=r.fk_org_src and s.mg between r.mg1 and r.mg2

          left join temp_stat2 h2 on s.mg=h2.mg and s.reu=h2.reu and s.kul=h2.kul and s.nd=h2.nd 
                  --and s.parent_usl=h2.usl - убрал эксперементально 30.03.2017
                  and s.usl=h2.usl -- добавил эксперементально 30.03.2017 по просьбе кис. (проходили кубы по двум услугам)
          left join temp_stat2 h4 on s.mg=h4.mg and s.reu=h4.reu and s.kul=h4.kul and s.nd=h4.nd 
                  and nvl(u.parent_usl, s.usl)=h4.usl
          left join (select distinct u2.uslm, t.reu, t.kul, t.nd, t.mg, t.ishotpipeinsulated, t.istowelheatexist 
                      from temp_stat2 t, usl u2 where t.usl=u2.usl) h5 on s.mg=h5.mg and s.reu=h5.reu and s.kul=h5.kul and s.nd=h5.nd 
                  and u.uslm=h5.uslm
          left join temp_stat3 h3 on s.mg=h3.mg and s.reu=h3.reu and s.kul=h3.kul and s.nd=h3.nd
          left join v_lsk_tp tp on s.fk_tp=tp.id
    WHERE exists
   (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
        and p.id=i.fk_par and p.cd='REP_USL'
        and i.sel_cd=s.usl
        and i.sel=1)
    and exists
       (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
            and p.id=i.fk_par and p.cd='REP_STATUS'
            and i.sel_id=s.status
        and i.sel=1)
        and ((var_=3 and
           s.reu = reu_ and case when s.for_reu is null then 1
                                             when p_for_reu is null then 1
                                             when s.for_reu = p_for_reu then 1
                                             else 0 end =1  
           and s.kul = kul_
           and s.nd = nd_) or
         (var_=2 and s.reu=reu_ and case when s.for_reu is null then 1
                                             when p_for_reu is null then 1
                                             when s.for_reu = p_for_reu then 1
                                             else 0 end =1)
          or (var_=1 and t.trest=trest_)
          or var_=0)
    and (l_sel_id = 0 or l_sel_id <> 0 and l_sel_id = s.fk_tp)
    AND s.mg between mg_ and mg1_
    union all
    select null as lsk, null as org, null as fk_org2, '000' as uslm, '000' as usl, s.kul,
    t.trest, s.reu, k.name,
    k.name||', '||NVL(LTRIM(s.nd,'0'),'0') AS predpr_det,
    utils.f_order(s.nd,6) as ord1, utils.f_order2(s.nd) as ord3,
    null as fio,
    s.status, s.psch as psch,
    s.sch as sch, s.val_group, s.val_group2,
    s.cnt AS cnt, s.klsk AS klsk, s.kpr AS kpr, decode(s.is_empt,1,'да',0,'нет', null) as is_empt, s.kpr_ot AS kpr_ot,
    s.kpr_wr AS kpr_wr, s.cnt_lg AS cnt_lg, s.cnt_subs AS cnt_subs, s.cnt_room, s.uch,
    substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2) as mg1,
    null as npp, hl.name as name_gr, null as odpu_ex, 0 as odpu_kub, 0 as kub_dist, 
    0 as kub_fact, 0 as kub_fact_upnorm,
    tp.name as lsk_tp, s.opl, s.is_vol, s.chng_vol,
    null as isHotPipe,
    null as isTowel,
    null as kr_soi,
    null as fact_cons
    FROM STATISTICS s, S_REU_TREST t, SPUL k,
        (select t.reu, t.kul, t.nd, u.name from t_housexlist t, u_list u
         where t.fk_list=u.id) hl, v_lsk_tp tp
    WHERE s.reu=t.reu and s.fk_tp=tp.id(+)
    AND s.USL is null
    AND s.kul=k.id
    and exists
       (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
            and p.id=i.fk_par and p.cd='REP_USL'
            and i.sel_cd='0' --Включить ли ИТОГ?
        and i.sel=1)
    and exists
       (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
            and p.id=i.fk_par and p.cd='REP_STATUS'
            and i.sel_id=s.status
        and i.sel=1)

    and s.reu=hl.reu(+) and s.kul=hl.kul(+) and s.nd=hl.nd(+)
    and
         ((var_=3 and
           s.reu = reu_ and p_for_reu is null
           and s.kul = kul_
           and s.nd = nd_) or
         (var_=2 and s.reu=reu_  and p_for_reu is null)
          or (var_=1 and t.trest=trest_)
          or var_=0)
    and (l_sel_id = 0 or l_sel_id <> 0 and l_sel_id = s.fk_tp)
    AND s.mg between mg_ and mg1_ order by name, ord1;
    ELSIF det_ in (0, 1) THEN
   --детализация до ЖЭО
        OPEN prep_refcursor FOR 
    select null as lsk, s.org, coalesce(r.fk_org_dst,s.org) as fk_org2, u.uslm, s.usl,
    t.trest, s.reu, null as name,
    null as predpr_det,
    null as fio,
    s.status, s.psch as psch,
    s.sch as sch, s.val_group, s.val_group2,
    s.cnt AS cnt, s.klsk AS klsk, s.kpr AS kpr, decode(s.is_empt,1,'да',0,'нет', null) as is_empt, s.kpr_ot AS kpr_ot,
    s.kpr_wr AS kpr_wr, s.cnt_lg AS cnt_lg, s.cnt_subs AS cnt_subs, s.cnt_room, s.uch,
    substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2) as mg1,
    u.npp, null as name_gr, null as odpu_ex, 0 as odpu_kub, 0 as kub_dist, 0 as kub_fact, 0 as kub_fact_upnorm, 
    tp.name as lsk_tp, s.opl, s.is_vol, s.chng_vol,
    null as isHotPipe,
    null as isTowel,
    null as kr_soi,
    null as fact_cons
    FROM STATISTICS_TREST s
    join USL u on s.USL=u.USL
    join S_REU_TREST t on s.reu=t.reu
    join v_lsk_tp tp on s.fk_tp=tp.id
    left join redir_pay r on s.org=r.fk_org_src and s.mg between r.mg1 and r.mg2
    WHERE
    exists
   (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
        and p.id=i.fk_par and p.cd='REP_USL'
        and i.sel_cd=s.usl
        and i.sel=1)
    and exists
       (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
            and p.id=i.fk_par and p.cd='REP_STATUS'
            and i.sel_id=s.status
        and i.sel=1)

    and
         ((var_=2 and s.reu=reu_)
          or (var_=1 and t.trest=trest_)
          or var_=0)
    and (l_sel_id = 0 or l_sel_id <> 0 and l_sel_id = s.fk_tp)
    AND s.mg between mg_ and mg1_
    union all
    select null as lsk, null as org, null as fk_org2, '000' as uslm, '000' as usl,
    t.trest, s.reu, null as name,
    null as predpr_det,
    null as fio,
    s.status, s.psch as psch,
    s.sch as sch, s.val_group, s.val_group2,
    s.cnt AS cnt, s.klsk AS klsk, s.kpr AS kpr, decode(s.is_empt,1,'да',0,'нет', null) as is_empt, s.kpr_ot AS kpr_ot,
    s.kpr_wr AS kpr_wr, s.cnt_lg AS cnt_lg, s.cnt_subs AS cnt_subs, s.cnt_room, s.uch,
    substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2) as mg1,
    null as npp, null as name_gr, null as odpu_ex, 0 as odpu_kub, 0 as kub_dist, 0 as kub_fact, 0 as kub_fact_upnorm, 
    tp.name as lsk_tp, s.opl, s.is_vol, s.chng_vol,
    null as isHotPipe,
    null as isTowel,
    null as kr_soi,
    null as fact_cons
    FROM STATISTICS_TREST s, S_REU_TREST t, v_lsk_tp tp
    WHERE s.reu=t.reu and s.fk_tp=tp.id(+)
    AND s.USL is null
    and exists
   (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
        and p.id=i.fk_par and p.cd='REP_USL'
        and i.sel_cd='0' --Включить ли ИТОГ?
    and i.sel=1)
    and exists
       (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
            and p.id=i.fk_par and p.cd='REP_STATUS'
            and i.sel_id=s.status
        and i.sel=1)

    and
         ((var_=2 and s.reu=reu_)
          or (var_=1 and t.trest=trest_)
          or var_=0)
    and (l_sel_id = 0 or l_sel_id <> 0 and l_sel_id = s.fk_tp)
    AND s.mg between mg_ and mg1_ order by npp;
    END IF;
    ELSIF сd_ = '18' THEN
      --Статистика по льготникам
      IF var_ = 3 THEN
        -- по Дому
        OPEN prep_refcursor FOR 'select t.trest||'' ''||t.name_tr as predp, k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'') as predpr_det,
       NVL(LTRIM(s.kw,''0''),''0'') AS kw, g.name AS spk_name, DECODE(s.main,1,''Носитель'',''Пользующ'') AS main, u.nm AS usl_name, s.cnt
       FROM STATISTICS_LG_LSK s, S_REU_TREST t, SPUL k, SPRORG p, SPK g, USL u
       WHERE ' || sqlstr_ || ' AND s.reu=t.reu AND s.kul=k.id AND s.ORG=p.kod AND s.spk_id=g.id AND s.USL=u.USL AND
       s.reu=:reu_ AND s.kul=:kul_ AND s.nd=:nd_
       ORDER BY utils.f_order(s.kw,7)'
          USING reu_, kul_, nd_;
      ELSIF var_ = 2 THEN
        -- по РЭУ
        OPEN prep_refcursor FOR 'select t.trest||'' ''||t.name_tr as predp, s.reu,  k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'') as predpr_det,
       NULL AS kw, g.name AS spk_name, DECODE(s.main,1,''Носитель'',''Пользующ'') AS main, u.nm AS usl_name, s.cnt
       FROM STATISTICS_LG s, S_REU_TREST t, SPUL k, SPRORG p, SPK g, USL u
       WHERE ' || sqlstr_ || ' AND s.reu=t.reu AND s.kul=k.id AND s.ORG=p.kod AND s.spk_id=g.id AND s.USL=u.USL AND
       s.reu=:reu_
       ORDER BY k.name, utils.f_order(s.nd,6)'
          USING reu_;
      ELSIF var_ = 1 THEN
        -- по ЖЭО
        open prep_refcursor for 'select t.trest||'' ''||t.name_tr as predp, s.reu, null as predpr_det,
       null as kw, g.name as spk_name, decode(s.main,1,''Носитель'',''Пользующ'') as main, u.nm as usl_name, s.cnt
       from statistics_lg_trest s, s_reu_trest t, sprorg p, spk g, usl u
       where ' || sqlstr_ || ' and s.reu=t.reu and s.org=p.kod and s.spk_id=g.id and s.usl=u.usl and t.trest=:trest_
       order by s.reu'
          using trest_;
          NULL;
      ELSIF var_ = 0 THEN
        -- по МП УЕЗЖКУ
        OPEN prep_refcursor FOR 'select t.trest||'' ''||t.name_tr as predp, s.reu, null as predpr_det,
       NULL AS kw, p.name AS orgname, g.name AS spk_name, DECODE(s.main,1,''Носитель'',''Пользующ'') AS main, u.nm AS usl_name, s.cnt
       FROM STATISTICS_LG_TREST s, S_REU_TREST t, SPRORG p, SPK g, USL u
       WHERE ' || sqlstr_ || ' AND s.reu=t.reu AND s.ORG=p.kod AND s.spk_id=g.id AND s.USL=u.USL
       ORDER BY t.trest';
      END IF;
    ELSIF сd_ = '14' THEN
      show_sal_:=utils.getS_bool_param('REP_SHOW_SAL');
      show_fond_:=utils.getS_list_param('REP_FOND');
      l_sel_id:=utils.getS_list_param('REP_TP_SCH_SEL');

      kpr1_:=utils.getS_int_param('REP_RNG_KPR1');  --kpr1, kpr2 - используется в других ведомостях, но неправильно!!!
      kpr2_:=utils.getS_int_param('REP_RNG_KPR2');  --только в оборотке этой - корректно! исправить потом Lev, 29.10.2015
      if det_ <> 3 and (kpr1_ is not null or kpr2_ is not null) then
          Raise_application_error(-20000, 'Внимание! Попытка использовать не действующий на данном уровне детализации параметр - кол-во проживающих!');
      end if;
      
      --Оборотка
      IF det_ = 3 then
        --детализация до квартир
        OPEN prep_refcursor FOR select x.mg,
       substr(x.mg, 1, 4)||'-'||substr(x.mg, 5, 2) as mg1,
       h.lsk,
       h.name_tr as predpr,
       h.name_reu as reu,
       h.adr as predpr_det,
       decode(h.type,0,'Прочие','Основные') as type,
       decode(h.status, 2, 'Приват', 'Муницип') as status,
       d.kod as org, 
       c.usl,
       c.uslm,
       null as name_gr,
       case when show_sal_=0 and x.mg > mg_ and mg_ <> mg1_ then 0
        else i.indebet
        end as indebet,
       case when show_sal_=0 and x.mg > mg_ and mg_ <> mg1_ then 0
        else i.inkredit
        end as inkredit,
       case when show_sal_=0 and x.mg < mg1_ and mg_ <> mg1_ then 0
        else i.outdebet
        end as outdebet,
       case when show_sal_=0 and x.mg < mg1_ and mg_ <> mg1_ then 0
        else i.outkredit
        end as outkredit,
       i.charges as charges,
       case when show_sal_=0 and x.mg > mg_ and mg_ <> mg1_ then 0
        else i.pinsal
        end as pinsal,
       case when show_sal_=0 and x.mg < mg1_ and mg_ <> mg1_ then 0
        else i.poutsal
        end as poutsal,
       i.changes as changes,
       i.changes2 as changes2,
       i.changes3 as changes3,
       nvl(i.changes,0)+nvl(i.changes2,0)+nvl(i.changes3,0) as changeall,
       i.subsid as subsid,
       i.privs as privs,
       i.payment as payment,
       i.pcur as pcur,
       i.pn as pn,
       null as odpu_ex,
       null as other_name,
       null as val_group2,
       a.fk_tp as fk_lsk_tp,
       h.psch as psch,
       d.grp,
       null as isHotPipe,
       null as isTowel,
       a.fio
      from (select e.lsk, case when k.psch in (8) then 2 -- для отображения признаков открытого, старого, закрытого фонда
                               when k.psch in (9) then 1 
                               else 0 end as psch,  
       e.usl, e.org, k.nd, k.kw, k.status, k.house_id, u.uslm, g.type,
         s.name||', '||NVL(LTRIM(k.nd,'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') as adr,
         s.name as street1,
          s.name_reu, s.name_tr
          from t_saldo_lsk2 e, kart k, spul s, sprorg g, s_reu_trest s, usl u
         where e.lsk = k.lsk and k.reu=s.reu
           and e.org = g.kod
           and k.kul = s.id
           and e.usl = u.usl
           and exists
          (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
              and p.id=i.fk_par and p.cd='REP_USL2'
              and i.sel_cd=e.usl
              and i.sel=1)
           and (show_fond_ = 1 and k.psch not in (8,9)
            or show_fond_ = 2 and k.psch in (8,9)
            or show_fond_ = 0
            or show_fond_ is null)
         and decode(var_, 3, reu_, k.reu)=k.reu
         and decode(var_, 3, kul_, k.kul)=k.kul
         and decode(var_, 3, nd_, k.nd)=k.nd
         and decode(var_, 2, reu_, k.reu)=k.reu
         and decode(var_, 1, trest_, s.trest)=s.trest
           ) h join xitog3_lsk i on h.lsk = i.lsk(+) and h.org = i.org(+) and h.usl = i.usl(+)
           join arch_kart a on i.lsk=a.lsk and a.kpr>=coalesce(kpr1_, a.kpr) and a.kpr<=coalesce(kpr2_, a.kpr) and i.mg=a.mg 
       join (select * from period_reports t where id = 14) x on x.mg = i.mg
       join sprorg d on h.org = d.kod
       join usl c on h.usl = c.usl
       join kart_detail det on h.lsk=det.lsk
    where 
     (l_sel_id = 0 or l_sel_id <> 0 and l_sel_id = a.fk_tp)
     and x.mg between mg_ and mg1_
    order by det.ord1;
    
      ELSIF det_ = 2 THEN
        -- детализация до домов
        OPEN prep_refcursor FOR select /*+ USE_HASH(h, i, h3, h2, hl, st )*/ i.mg, substr(i.mg, 1, 4)||'-'||substr(i.mg, 5, 2) as mg1,
        null as lsk,
        t.name_tr as predpr, h.name_reu as reu, k.name||', '||nvl(ltrim(h.nd,'0'),'0')  as predpr_det,
        utils.f_order(h.nd,6) as ord1,
        decode(h.type,0,'прочие','основные') as type,
        decode(h.status,2,'Приват','Муницип') as status, d.kod as org, 
         c.usl,
         c.uslm,
        hl.name as name_gr,
       case when show_sal_=0 and i.mg > mg_ and mg_ <> mg1_ then 0
        else i.indebet
        end as indebet,
       case when show_sal_=0 and i.mg > mg_ and mg_ <> mg1_ then 0
        else i.inkredit
        end as inkredit,
       case when show_sal_=0 and i.mg < mg1_ and mg_ <> mg1_ then 0
        else i.outdebet
        end as outdebet,
       case when show_sal_=0 and i.mg < mg1_ and mg_ <> mg1_ then 0
        else i.outkredit
        end as outkredit,
        i.charges as charges,
       case when show_sal_=0 and i.mg > mg_ and mg_ <> mg1_ then 0
        else i.pinsal
        end as pinsal,
       case when show_sal_=0 and i.mg < mg1_ and mg_ <> mg1_ then 0
        else i.poutsal
        end as poutsal,
        i.changes as changes,
        i.changes2 as changes2,
        i.changes3 as changes3,
        nvl(i.changes,0)+nvl(i.changes2,0)+nvl(i.changes3,0) as changeall,
        i.subsid as subsid,
        i.privs as privs,
        i.payment as payment,
        i.pcur as pcur,
        i.pn as pn,
        h2.odpu_ex,
        h3.other_name,
        st.val_group2,
        h.fk_lsk_tp,
        null as psch,
        d.grp, 
        decode(h2.ishotpipeinsulated,1,'да','нет') as isHotPipe,
        decode(h2.istowelheatexist,1,'да','нет') as isTowel,
        null as fio
        from
        (select distinct e.reu, e.kul, e.nd, e.usl, e.org, e.status, e.fk_lsk_tp, u.type, s.trest, s.name_reu, nvl(u2.parent_usl, e.usl) as parent_usl
         from t_saldo_reu_kul_nd_st e, sprorg u, usl u2,
        s_reu_trest s where e.org=u.kod and e.reu=s.reu and e.usl=u2.usl
        and exists
        (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
          and p.id=i.fk_par and p.cd='REP_USL2'
          and i.sel_cd=e.usl
          and i.sel=1)
         and decode(var_, 3, reu_, e.reu)=e.reu
         and decode(var_, 3, kul_, e.kul)=e.kul
         and decode(var_, 3, nd_, e.nd)=e.nd
         and decode(var_, 2, reu_, e.reu)=e.reu
         and decode(var_, 1, trest_, s.trest)=s.trest
          ) h 
         join 
         xitog3 i
         on h.reu=i.reu and h.kul=i.kul and h.nd=i.nd and h.org=i.org and h.usl=i.usl and h.status=i.status and h.fk_lsk_tp=i.fk_lsk_tp
            and i.mg between mg_ and mg1_
         left join
         (select distinct --t.mg,  -- ред.06.11.2019 - перевел на c_houses
         --k.reu, 
         t.kul, t.nd, o.name as other_name from c_houses t, t_org o, -- ред.06.11.2019 - перевел на c_houses
         (select --max(t.reu) as reu, 
          t.house_id from kart t where t.psch not in (8,9) group by t.house_id) k --работает в полыс, не убирать!
          where t.fk_other_org=o.id and t.id=k.house_id
          --and t.mg between mg_ and mg1_  -- ред.06.11.2019 - перевел на c_houses
          ) h3
         /*left join
         (select distinct t.mg, k.reu, t.kul, t.nd, o.name as other_name from a_houses t, t_org o,
         (select max(t.reu) as reu, t.house_id from kart t where t.psch not in (8,9) group by t.house_id) k --работает в полыс, не убирать!
          where t.fk_other_org=o.id and t.id=k.house_id
          and t.mg between mg_ and mg1_
          ) h3*/
          on --i.reu=h3.reu and 
          i.kul=h3.kul and i.nd=h3.nd-- and i.mg=h3.mg -- ред.06.11.2019 - перевел на c_houses
         left join 
         (select max(case when d.dist_tp<>4 and nvl(d.kub,0) = 0 then 'есть, нет объема' --max нужен чтобы не удваивалась оборотка
                      when d.dist_tp<>4 and nvl(d.kub,0) <> 0 then 'есть'
                      else 'нет' end) as odpu_ex,
                      d.usl, d.mg, h.reu, h.kul, h.nd, nvl(d.ishotpipeinsulated,0) as ishotpipeinsulated, 
                        nvl(d.istowelheatexist,0) as istowelheatexist
                      from a_vvod d, arch_kart h --здесь не нужен архивный a_houses!
                where h.house_id=d.house_id and h.mg=d.mg and d.mg between mg_ and mg1_
                and h.psch not in (8,9)
                group by d.usl, d.mg, h.reu, h.kul, h.nd, nvl(d.ishotpipeinsulated,0), nvl(d.istowelheatexist,0)
                ) h2 
         on i.reu=h2.reu and i.kul=h2.kul and i.nd=h2.nd and i.mg=h2.mg and h.parent_usl=h2.usl
        join 
        sprorg d on h.org=d.kod
        join usl c on h.usl=c.usl
        join org l on l.id=1 
        join s_reu_trest t on h.reu=t.reu 
        join spul k on h.kul=k.id
        left join 
        (select t.reu, t.kul, t.nd, u.name from t_housexlist t, u_list u
         where t.fk_list=u.id) hl 
        on h.reu=hl.reu and h.kul=hl.kul and h.nd=hl.nd
        left join  
        (select t.reu, t.kul, t.nd, t.mg, t.usl, max(t.val_group2) as val_group2 from STATISTICS t --подключил стату здесь, чтобы были видны нормативы в оборотке...
        where t.mg between mg_ and mg1_
         group by t.reu, t.kul, t.nd, t.mg, t.usl) st
        on i.reu=st.reu and i.kul=st.kul and i.nd=st.nd and i.mg=st.mg and h.parent_usl=st.usl
        where (decode(l_sel_id, 0, h.fk_lsk_tp, l_sel_id) = h.fk_lsk_tp )

        order by i.mg, k.name||', '||nvl(ltrim(h.nd,'0'),'0'), utils.f_order(h.nd,6);
      ELSIF det_ in (0, 1) THEN
        -- до ЖЭО
        OPEN prep_refcursor FOR select /*+ USE_HASH(h,i,o,u,x,d,c,l,t,hl)*/ x.mg, substr(x.mg, 1, 4)||'-'||substr(x.mg, 5, 2) as mg1,
        null as lsk,
        t.trest||' '||t.name_tr as predpr,
        h.name_reu as reu, null as predpr_det, decode(h.type,0,'прочие','основные') as type,
        decode(h.status,2,'Приват','Муницип') as status, d.kod as org, 
        c.usl, 
        c.uslm,
        hl.name as name_gr,
       case when show_sal_=0 and x.mg > mg_ and mg_ <> mg1_ then 0
        else sum(i.indebet)
        end as indebet,
       case when show_sal_=0 and x.mg > mg_ and mg_ <> mg1_ then 0
        else sum(i.inkredit)
        end as inkredit,
       case when show_sal_=0 and x.mg < mg1_ and mg_ <> mg1_ then 0
        else sum(i.outdebet)
        end as outdebet,
       case when show_sal_=0 and x.mg < mg1_ and mg_ <> mg1_ then 0
        else sum(i.outkredit)
        end as outkredit,
        sum(o.charges) as charges,
       case when show_sal_=0 and x.mg > mg_ and mg_ <> mg1_ then 0
        else sum(o.pinsal)
        end as pinsal,
       case when show_sal_=0 and x.mg < mg1_ and mg_ <> mg1_ then 0
        else sum(o.poutsal)
        end as poutsal,
        sum(o.changes) as changes,
        sum(o.changes2) as changes2,
        sum(o.changes3) as changes3,
        sum(nvl(o.changes,0)+nvl(o.changes2,0)+nvl(o.changes3,0)) as changeall,
        sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.payment) as payment,
        sum(o.pcur) as pcur,
        sum(o.pn) as pn,
        null as odpu_ex,
        null as other_name,
        null as val_group2,
        h.fk_lsk_tp,
        null as psch,
        d.grp,
        null as isHotPipe,
        null as isTowel,
        null as fio
        from
        (select distinct e.reu, e.kul, e.nd, e.org, e.usl, u.uslm, e.status, o.type, s.trest, s.name_reu, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, usl u, sprorg o,
        s_reu_trest s where e.org=o.kod and e.reu=s.reu and e.usl=u.usl
        and exists
        (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
          and p.id=i.fk_par and p.cd='REP_USL2'
          and i.sel_cd=e.usl
          and i.sel=1)
         and decode(var_, 2, reu_, e.reu)=e.reu
         and decode(var_, 1, trest_, s.trest)=s.trest
         ) h,
        xitog3 i,
        (select reu,kul,nd,status,org,usl,mg,fk_lsk_tp, sum(charges) as charges, sum(pinsal) as pinsal, sum(poutsal) as poutsal,
        sum(changes) as changes, sum(changes2) as changes2, sum(changes3) as changes3, sum(subsid) as subsid, sum(privs) as privs,
        sum(payment) as payment, sum(pcur) as pcur, sum(pn) as pn from xitog3 t
                where t.mg between mg_ and mg1_
        group by reu,kul,nd,status,org,usl,mg,fk_lsk_tp) o,
        (select * from period_reports t where id=14) x,
        sprorg d, usl c, org l, s_reu_trest t,
        (select t.reu, t.kul, t.nd, u.name from t_housexlist t, u_list u
         where t.fk_list=u.id) hl
        where
        h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
        h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
        l.id=1 and h.org=d.kod and h.usl=c.usl and h.reu=t.reu
        and x.mg=i.mg and x.mg=o.mg 
        and x.mg between mg_ and mg1_
        and h.reu=hl.reu(+) and h.kul=hl.kul(+) and h.nd=hl.nd(+)
        and (decode(l_sel_id,0,h.fk_lsk_tp,l_sel_id)  = h.fk_lsk_tp)
        group by hl.name, decode(h.type,0,'прочие','основные'), x.mg, substr(x.mg, 1, 4)||'-'||substr(x.mg, 5, 2), t.trest||' '||t.name_tr, h.name_reu, h.status, h.type, d.kod, 
        c.usl, c.uslm, h.fk_lsk_tp, d.grp
        order by x.mg;
--        USING show_sal_, mg_, mg_, mg1_, show_sal_, mg_, mg_, mg1_, show_sal_, mg1_, mg_, mg1_, show_sal_,
--          mg1_, mg_, mg1_, fk_ses_, var_, reu_, var_, trest_, var_, mg_, mg1_;
      ELSE
        OPEN prep_refcursor FOR 'select null as predpr, null as reu, null as predpr_det, null as type,
          null as lsk,
          NULL AS STATUS, NULL AS ORG, NULL AS nm1, NULL AS name_gr, NULL AS indebet, NULL AS inkredit,
          NULL AS CHARGES, NULL AS POUTSAL, NULL AS CHANGES, NULL AS CHANGES2, NULL AS CHANGEALL, NULL AS subsid, NULL AS PRIVS, NULL AS payment,
          NULL AS pn, NULL AS outdebet, NULL AS outkredit, null fk_lsk_tp
          FROM dual';
      END IF;
   elsif сd_ = '35' then
     -- Оплата OLAP
      if det_ = 3 then
        --детализация до квартир
        open prep_refcursor for select null as predp,
             o.oper||' '||o.naim as opername, null as reu,
             'ЖЭО:'||k.reu||'-'||l.name||', '||NVL(LTRIM(k.nd,'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0')
             as predpr_det,
             null as kw, s.var, s.dopl,
             substr(s.dopl, 1, 4)||'-'||substr(s.dopl, 5, 2) as dopl_name,
             s.mg, substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2) as mg_name,
             s.dat, to_char(r.kod) || ' ' || r.name as org_name, v.name as var_name, u.nm, u.nm1, sum(s.summa) as summa,
             decode(s.cd_tp, 0, 'Пеня', 'Оплата') as cd_tp
             from kart k, xxito14_lsk s, s_reu_trest t, sprorg r, variant_xxito10 v, spul l, oper o, usl u
             where k.lsk=s.lsk and s.usl=u.usl and s.oper=o.oper
              and s.org=r.kod and s.var=v.id and k.kul=l.id
              and k.reu=t.reu

             and (dat_ is null and dat1_ is null and s.mg between mg_ and mg1_
             or dat_ is not null and dat1_ is null and s.dat = dat_
             or dat_ is not null and dat1_ is not null and s.dat between dat_ and dat1_)
             
             and decode(var_,3,reu_,k.reu)=k.reu
             and decode(var_,3,kul_,k.kul)=k.kul
             and decode(var_,3,nd_,k.nd)=k.nd
             and decode(var_,2,reu_,k.reu)=k.reu
             and decode(var_,1,trest_,t.trest)=t.trest
                 
             group by o.oper||' '||o.naim,
               'ЖЭО:'||k.reu||'-'||l.name||', '||NVL(LTRIM(k.nd,'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0'),
               s.var, s.dopl,
               substr(s.dopl, 1, 4)||'-'||substr(s.dopl, 5, 2),
               s.mg, substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2),
               s.dat, to_char(r.kod) || ' ' || r.name, v.name, u.nm, u.nm1,
             decode(s.cd_tp, 0, 'Пеня', 'Оплата')
              order by s.dopl desc;          
      elsif det_ in ( 2) then
        -- детализация до домов
         open prep_refcursor for select t.name_tr as predp,
         o.oper||' '||o.naim as opername, t.name_reu as reu,
         ' ЖЭО:'||s.forreu||'-'||k.name||', '||NVL(LTRIM(s.nd,'0'),'0')
         as predpr_det,
         null as kw, s.var, s.dopl,
         substr(s.dopl, 1, 4)||'-'||substr(s.dopl, 5, 2) as dopl_name,
         s.mg, substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2) as mg_name,
         s.dat, to_char(r.kod) || ' ' || r.name org_name, v.name as var_name, u.nm, u.nm1, sum(s.summa) as summa,
         decode(s.cd_tp, 0, 'Пеня', 'Оплата') as cd_tp
         from xxito14 s, s_reu_trest t, sprorg r, variant_xxito10 v, spul k, oper o, usl u
         where s.usl=u.usl and s.oper=o.oper and s.forreu=t.reu
         and s.org=r.kod and s.var=v.id and s.kul=k.id

         and (dat_ is null and dat1_ is null and s.mg between mg_ and mg1_
         or dat_ is not null and dat1_ is null and s.dat = dat_
         or dat_ is not null and dat1_ is not null and s.dat between dat_ and dat1_)

         and decode(var_,3,reu_,s.forreu)=s.forreu
         and decode(var_,2,reu_,s.forreu)=s.forreu
         and decode(var_,1,trest_,t.trest)=t.trest

         group by t.name_tr, o.oper||' '||o.naim, t.name_reu,
          ' ЖЭО:'||s.forreu||'-'||k.name||', '||NVL(LTRIM(s.nd,'0'),'0'),
          s.var, s.dopl,
          substr(s.dopl, 1, 4)||'-'||substr(s.dopl, 5, 2),
          s.mg, substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2), s.dat,
          to_char(r.kod) || ' ' || r.name, v.name, u.nm, u.nm1,
          decode(s.cd_tp, 0, 'Пеня', 'Оплата')
          order by s.dopl desc;
      elsif det_ in (0, 1) then
        -- детализация до ЖЭО
        open prep_refcursor for select t.name_tr as predp, o.oper||' '||o.naim as opername, t.name_reu as reu,
             null as predpr_det,null as kw, s.var, s.dopl,
             substr(s.dopl, 1, 4)||'-'||substr(s.dopl, 5, 2) as dopl_name,
             s.mg, substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2) as mg_name,
             s.dat, to_char(r.kod) || ' ' || r.name org_name, v.name as var_name, u.nm, u.nm1, sum(s.summa) as summa,
             decode(s.cd_tp, 0, 'Пеня', 'Оплата') as cd_tp

             from xxito14 s, s_reu_trest t, sprorg r, variant_xxito10 v, oper o, usl u
             where s.usl=u.usl and s.oper=o.oper and s.forreu=t.reu and s.org=r.kod and s.var=v.id

             and (dat_ is null and dat1_ is null and s.mg between mg_ and mg1_
             or dat_ is not null and dat1_ is null and s.dat = dat_
             or dat_ is not null and dat1_ is not null and s.dat between dat_ and dat1_)

             and decode(var_,3,reu_,s.forreu)=s.forreu
             and decode(var_,2,reu_,s.forreu)=s.forreu
             and decode(var_,1,trest_,t.trest)=t.trest
             
             group by t.name_tr, o.oper||' '||o.naim, t.name_reu, s.var, s.dopl,
              substr(s.dopl, 1, 4)||'-'||substr(s.dopl, 5, 2),
              s.mg, substr(s.mg, 1, 4)||'-'||substr(s.mg, 5, 2), s.dat,
              to_char(r.kod) || ' ' || r.name, v.name, u.nm, u.nm1,
              decode(s.cd_tp, 0, 'Пеня', 'Оплата')
              order by s.dopl desc;
      end if;  
 elsif сd_ = '36' then
     -- Сверка инкассаций
     if var_ = 3 then
        --По дому
        raise_application_error(-20001,'Не существует уровня детализации!');
      elsif var_ = 2 then
        --По РЭУ
        raise_application_error(-20001,'Не существует уровня детализации!');
      elsif var_ = 1 then
        --По ЖЭО
        raise_application_error(-20001,'Не существует уровня детализации!');
      elsif var_ = 0 then
        --(все тресты)
          open prep_refcursor for
          'select sum(summa) as summa, sum(penya) as penya, opername,
               nink, nkom, dat_ink from (
               select t.summa as summa, t.penya as penya, o.oper||'' ''||o.naim as opername,
               t.nink, t.nkom, t.dat_ink
                 from c_kwtp_mg t, oper o
               where t.oper=o.oper and t.dat_ink between :dt1 and :dt2
               and :l_in_period=1
               union all
               select t.summa as summa, t.penya as penya, o.oper||'' ''||o.naim as opername,
               t.nink, t.nkom, t.dat_ink
                 from a_kwtp_mg t, oper o, params p
               where t.oper=o.oper and t.dat_ink between :dt1 and :dt2
               and :l_out_period=1 and t.mg <> p.period
               union all
               select t.summa as summa, t.penya as penya, o.oper||'' ''||o.naim as opername,
               t.nink, t.nkom, t.dat_ink
                 from c_kwtp_mg t, oper o
               where t.oper=o.oper and t.dat_ink is null
               and :l_in_period=1
               union all
               select t.summa as summa, t.penya as penya, o.oper||'' ''||o.naim as opername,
               t.nink, t.nkom, t.dat_ink
                 from a_kwtp_mg t, oper o, params p
               where t.oper=o.oper and t.dat_ink is null
               and :l_out_period=1 and t.mg <> p.period
               union all
               select t.summa, null as penya, o.oper||'' ''||o.naim as opername, null as nink,
                null as nkom, t.dat as dat_ink
                from t_corrects_payments t, oper o where
                t.mg between :mg and :mg1 and o.oper=''99''
                ) a
               group by a.dat_ink, a.nkom, opername, a.nink
               order by a.dat_ink, a.nkom, opername, a.nink'
               using l_dt, l_dt1, l_in_period, l_dt, l_dt1, l_out_period, l_in_period,
                l_out_period, mg_, mg1_;
      end if;
 elsif сd_ = '37' then
     -- Сверка перерасчетов начисления
     if var_ = 3 then
        --По дому
        raise_application_error(-20001,'Не существует уровня детализации!');
      elsif var_ = 2 then
        --По РЭУ
        raise_application_error(-20001,'Не существует уровня детализации!');
      elsif var_ = 1 then
        --По ЖЭО
        raise_application_error(-20001,'Не существует уровня детализации!');
      elsif var_ = 0 then
        --По городу
        open prep_refcursor for
        'select d.id, s.name_reu, u.nm, t.name as type_ch,
           l.name||'', ''||NVL(LTRIM(k.nd,''0''),''0'')||''-''||NVL(LTRIM(k.kw,''0''),''0'') as adr,
           c.mgchange, substr(c.mgchange, 1, 4)||''-''||substr(c.mgchange, 5, 2) as mg1,
           c.dtek, u.name, sum(c.summa) as summa, max(c.proc) as proc
            from kart k, spul l, c_change_docs d, c_change c, s_reu_trest s, t_user u, usl u, c_change_tp t
            where k.lsk=c.lsk and k.kul=l.id and k.reu=s.reu and d.id=c.doc_id and c.type=t.id and d.user_id=u.id and c.usl=u.usl
           group by d.id,
           l.name||'', ''||NVL(LTRIM(k.nd,''0''),''0'')||''-''||NVL(LTRIM(k.kw,''0''),''0''),
           s.name_reu, u.nm, t.name, c.mgchange, c.dtek, u.name
           order by d.id';
      end if;
 elsif сd_ = '54' then
 --Задолжники OLAP
 --:cur_pay_=1 -- с учетом текущей оплаты, 0 - без учета

   cur_pay_:=utils.getS_bool_param('REP_CUR_PAY');
   kpr1_:=utils.getS_int_param('REP_RNG_KPR1');
   kpr2_:=utils.getS_int_param('REP_RNG_KPR2');
   n1_:=utils.getS_list_param('REP_DEB_VAR');
   l_sel_id:=utils.getS_list_param('REP_TP_SCH_SEL');
   
   if n1_=0 then
     n2_:=utils.getS_int_param('REP_DEB_MONTH');
     else
     n2_:=utils.getS_int_param('REP_DEB_SUMMA');
   end if;

   if var_ = 3 then
    --По дому ред.09.04.2019 Долги в совокупности! (debits_lsk_month.var=0)
   open prep_refcursor for
   select s.lsk, DECODE(k.psch,9,'Закрытые Л/С', 8,'Старый фонд', 'Открытые Л/С') AS psch,
    t.name_tr, t.name_reu,
    trim(s.name) as street,  ltrim(s.nd,'0') as nd, ltrim(s.kw,'0') as kw,
    trim(s.name)||', '||ltrim(s.nd,'0')||'-'||ltrim(s.kw,'0') as adr, s.fio,
    case when cur_pay_=1 then s.cnt_month
      else s.cnt_month2 end as cnt_month,
    case when cur_pay_=1 then s.dolg
      else s.dolg2 end as dolg, g.name as deb_org, s.penya, s.nachisl, s.payment, s.dat,
      a.name as st_name
    from kart k, debits_lsk_month s, s_reu_trest t, t_org g, status a
    where decode(l_sel_id,0,0,1)=s.var and decode(l_sel_id,0,k.fk_tp,l_sel_id)=k.fk_tp-- либо совокупно по помещению, либо по конкретному типу лс
    and k.lsk=s.lsk and s.status=a.id and s.reu=t.reu and s.reu=reu_ and s.kul=kul_ and s.nd=nd_ and s.mg between mg_ and mg1_
    and s.fk_deb_org=g.id(+)
    and ((cur_pay_=1 and s.cnt_month > 0) or
    (cur_pay_=0 and s.cnt_month2 > 0))
    and exists
    (select * from kart k where k.lsk=s.lsk
      and (kpr1_ is not null and k.kpr >=kpr1_ or kpr1_ is null)
    and (kpr2_ is not null and k.kpr <=kpr2_ or kpr2_ is null))
    and
    ((n1_=0 and s.cnt_month >= n2_) or
    (n1_=1 and s.dolg >= n2_))
    order by s.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
--    using cur_pay_, cur_pay_, reu_, kul_, nd_, cur_pay_, cur_pay_,
--    kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_;
   elsif var_ = 2 then
    --По ЖЭО ред.09.04.2019
   open prep_refcursor for
   select s.lsk, DECODE(k.psch,9,'Закрытые Л/С', 8,'Старый фонд', 'Открытые Л/С') AS psch,
    t.name_tr, t.name_reu,
    trim(s.name) as street,  ltrim(s.nd,'0') as nd, ltrim(s.kw,'0') as kw,
    trim(s.name)||', '||ltrim(s.nd,'0')||'-'||ltrim(s.kw,'0') as adr, s.fio,
    case when cur_pay_=1 then s.cnt_month
      else s.cnt_month2 end as cnt_month,
    case when cur_pay_=1 then s.dolg
      else s.dolg2 end as dolg, g.name as deb_org, s.penya, s.nachisl, s.payment, s.dat,
    a.name as st_name
    from kart k, debits_lsk_month s, s_reu_trest t, t_org g, status a
    where decode(l_sel_id,0,0,1)=s.var and decode(l_sel_id,0,k.fk_tp,l_sel_id)=k.fk_tp-- либо совокупно по помещению, либо по конкретному типу лс
    and k.lsk=s.lsk and s.status=a.id and s.reu=t.reu and s.reu=reu_ and s.mg between mg_ and mg1_
    and s.fk_deb_org=g.id(+)
    and ((cur_pay_=1 and s.cnt_month > 0) or
    (cur_pay_=0 and s.cnt_month2 > 0))
    and exists
    (select * from kart k where k.lsk=s.lsk
      and (kpr1_ is not null and k.kpr >=kpr1_ or kpr1_ is null)
    and (kpr2_ is not null and k.kpr <=kpr2_ or kpr2_ is null))
    and
    ((n1_=0 and s.cnt_month >= n2_) or
    (n1_=1 and s.dolg >= n2_))
    order by s.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
--    using cur_pay_, cur_pay_, reu_, cur_pay_, cur_pay_,
--    kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_;
   elsif var_ = 1 then
    --По фонду ред.09.04.2019
   open prep_refcursor for
   select s.lsk, DECODE(k.psch,9,'Закрытые Л/С', 8,'Старый фонд', 'Открытые Л/С') AS psch,
    t.name_tr, t.name_reu,
    trim(s.name) as street,  ltrim(s.nd,'0') as nd, ltrim(s.kw,'0') as kw,
    trim(s.name)||', '||ltrim(s.nd,'0')||'-'||ltrim(s.kw,'0') as adr, s.fio,
    case when cur_pay_=1 then s.cnt_month
      else s.cnt_month2 end as cnt_month,
    case when cur_pay_=1 then s.dolg
      else s.dolg2 end as dolg, g.name as deb_org, s.penya, s.nachisl, s.payment, s.dat,
    a.name as st_name
    from kart k, debits_lsk_month s, s_reu_trest t, t_org g, status a
    where decode(l_sel_id,0,0,1)=s.var and decode(l_sel_id,0,k.fk_tp,l_sel_id)=k.fk_tp-- либо совокупно по помещению, либо по конкретному типу лс
    and k.lsk=s.lsk and s.status=a.id and s.reu=t.reu and t.trest=trest_ and s.mg between mg_ and mg1_
    and s.fk_deb_org=g.id(+)
    and ((cur_pay_=1 and s.cnt_month > 0) or
    (cur_pay_=0 and s.cnt_month2 > 0))
    and exists
    (select * from kart k where k.lsk=s.lsk
      and (kpr1_ is not null and k.kpr >=kpr1_ or kpr1_ is null)
    and (kpr2_ is not null and k.kpr <=kpr2_ or kpr2_ is null))
    and
    ((n1_=0 and s.cnt_month >= n2_) or
    (n1_=1 and s.dolg >= n2_))
    order by s.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
--    using cur_pay_, cur_pay_, trest_, cur_pay_, cur_pay_,
--    kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_;
   elsif var_ = 0 then
   --По городу ред.09.04.2019
   open prep_refcursor for
   select s.lsk, DECODE(k.psch,9,'Закрытые Л/С', 8,'Старый фонд', 'Открытые Л/С') AS psch,
    t.name_tr, t.name_reu,
    trim(s.name) as street,  ltrim(s.nd,'0') as nd, ltrim(s.kw,'0') as kw,
    trim(s.name)||', '||ltrim(s.nd,'0')||'-'||ltrim(s.kw,'0') as adr, s.fio,
    case when cur_pay_=1 then s.cnt_month
      else s.cnt_month2 end as cnt_month,
    case when cur_pay_=1 then s.dolg
      else s.dolg2 end as dolg, g.name as deb_org, s.penya, s.nachisl, s.payment, s.dat,
    a.name as st_name
    from kart k, debits_lsk_month s, s_reu_trest t, t_org g, status a
    where decode(l_sel_id,0,0,1)=s.var and decode(l_sel_id,0,k.fk_tp,l_sel_id)=k.fk_tp-- либо совокупно по помещению, либо по конкретному типу лс
    and k.lsk=s.lsk and s.status=a.id and s.reu=t.reu and s.mg between mg_ and mg1_
    and s.fk_deb_org=g.id(+)
    and ((cur_pay_=1 and s.cnt_month > 0) or
    (cur_pay_=0 and s.cnt_month2 > 0))
    and exists
    (select * from kart k where k.lsk=s.lsk
      and (kpr1_ is not null and k.kpr >=kpr1_ or kpr1_ is null)
    and (kpr2_ is not null and k.kpr <=kpr2_ or kpr2_ is null))
    and
    ((n1_=0 and s.cnt_month >= n2_) or
    (n1_=1 and s.dolg >= n2_))
    order by s.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
--    using cur_pay_, cur_pay_, cur_pay_, cur_pay_,
--    kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_;
    end if;
 elsif сd_ = '56' then
 --Списки льготников
   if var_ = 3 then
    --По дому
   open prep_refcursor for
   'select substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg, s.lsk,
    initcap(trim(e.name) || '', '' || ltrim(s.nd, ''0'') || ''-'' || ltrim(s.kw, ''0'')) as adr,
       s.opl, s.kpr, c.kpr_cem, c1.kpr_s,
       decode(lag(s.lsk, 1) over (order by s.lsk), s.lsk, 0, c2.cnt) as cnt,
       decode(lag(s.lsk, 1) over (order by s.lsk), s.lsk, 0, c2.cnt_main) as cnt_main,
       p.fio, m.name as lg_name, u.nm2 as usl_name, b.summa, nvl(d.doc, '' '') as doc
  from arch_kart s, spul e, a_kart_pr p, spk m, a_lg_docs d,
       usl u, (select sum(s.summa) as summa, s.lg_doc_id, s.spk_id, s.usl, s.kart_pr_id
                 from a_charge s
                where '||sqlstr_||' and s.spk_id=:spk_id_ and s.type = 4 and s.summa <> 0
                group by s.lg_doc_id, s.spk_id, s.usl, s.kart_pr_id) b,
              (select lsk, sum(kpr_cem) as kpr_cem from
                (select distinct s.lsk, s.kart_pr_id, 1 as kpr_cem
                 from a_charge s, usl m
                where '||sqlstr_||' and s.usl=m.usl and s.spk_id=:spk_id_ and m.usl_type=1
                 and s.type = 4 and s.summa <> 0)
                 group by lsk
                ) c,
              (select lsk, sum(kpr_s) as kpr_s from
                (select distinct s.lsk, s.kart_pr_id, 1 as kpr_s
                 from a_charge s, usl m
                where '||sqlstr_||' and s.usl=m.usl and s.spk_id=:spk_id_ and m.usl_type=0
                 and s.type = 4 and s.summa <> 0)
                 group by lsk
                ) c1,
              (select lsk, count(*) as cnt, sum(cnt_main) as cnt_main from (
                select distinct lsk, kart_pr_id, main as cnt_main from a_charge s
                where '||sqlstr_||' and s.spk_id=:spk_id_
                and s.type=4 and s.summa <> 0  --кол-во носителей льг.
                )
                group by lsk
                ) c2
 where s.lsk = p.lsk and s.reu=:reu_ and s.kul=:kul_ and s.nd=:nd_
   and s.kul = e.id
   and '||sqlstr_||'
   and s.lsk = c.lsk(+)
   and s.lsk = c1.lsk(+)
   and s.lsk = c2.lsk(+)
   and p.mg=s.mg
   and d.mg=s.mg
   and b.spk_id=m.id
   and p.id = b.kart_pr_id
   and b.usl = u.usl
   and d.id=b.lg_doc_id
   order by s.lsk, p.id'
    using spk_id_, spk_id_, spk_id_, spk_id_, reu_, kul_, nd_;
   elsif var_ = 2 then
    --По ЖЭО
   open prep_refcursor for
   'select substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg, s.lsk,
    initcap(trim(e.name) || '', '' || ltrim(s.nd, ''0'') || ''-'' || ltrim(s.kw, ''0'')) as adr,
       s.opl, s.kpr, c.kpr_cem, c1.kpr_s,
       decode(lag(s.lsk, 1) over (order by s.lsk), s.lsk, 0, c2.cnt) as cnt,
       decode(lag(s.lsk, 1) over (order by s.lsk), s.lsk, 0, c2.cnt_main) as cnt_main,
       p.fio, m.name as lg_name, u.nm2 as usl_name, b.summa, nvl(d.doc, '' '') as doc
  from arch_kart s, spul e, a_kart_pr p, spk m, a_lg_docs d,
       usl u, (select sum(s.summa) as summa, s.lg_doc_id, s.spk_id, s.usl, s.kart_pr_id
                 from a_charge s
                where '||sqlstr_||' and s.spk_id=:spk_id_ and s.type = 4 and s.summa <> 0
                group by s.lg_doc_id, s.spk_id, s.usl, s.kart_pr_id) b,
              (select lsk, sum(kpr_cem) as kpr_cem from
                (select distinct s.lsk, s.kart_pr_id, 1 as kpr_cem
                 from a_charge s, usl m
                where '||sqlstr_||' and s.usl=m.usl and s.spk_id=:spk_id_ and m.usl_type=1
                 and s.type = 4 and s.summa <> 0)
                 group by lsk
                ) c,
              (select lsk, sum(kpr_s) as kpr_s from
                (select distinct s.lsk, s.kart_pr_id, 1 as kpr_s
                 from a_charge s, usl m
                where '||sqlstr_||' and s.usl=m.usl and s.spk_id=:spk_id_ and m.usl_type=0
                 and s.type = 4 and s.summa <> 0)
                 group by lsk
                ) c1,
              (select lsk, count(*) as cnt, sum(cnt_main) as cnt_main from (
                select distinct lsk, kart_pr_id, main as cnt_main from a_charge s
                where '||sqlstr_||' and s.spk_id=:spk_id_
                and s.type=4 and s.summa <> 0  --кол-во носителей льг.
                )
                group by lsk
                ) c2
 where s.lsk = p.lsk and s.reu=:reu_
   and s.kul = e.id
   and '||sqlstr_||'
   and s.lsk = c.lsk(+)
   and s.lsk = c1.lsk(+)
   and s.lsk = c2.lsk(+)
   and p.mg=s.mg
   and d.mg=s.mg
   and b.spk_id=m.id
   and p.id = b.kart_pr_id
   and b.usl = u.usl
   and d.id=b.lg_doc_id
   order by s.lsk, p.id'
   using spk_id_, spk_id_, spk_id_, spk_id_, reu_;
   elsif var_ = 1 then
    --По фонду
   open prep_refcursor for
   'select substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg, s.lsk,
    initcap(trim(e.name) || '', '' || ltrim(s.nd, ''0'') || ''-'' || ltrim(s.kw, ''0'')) as adr,
       s.opl, s.kpr, c.kpr_cem, c1.kpr_s,
       decode(lag(s.lsk, 1) over (order by s.lsk), s.lsk, 0, c2.cnt) as cnt,
       decode(lag(s.lsk, 1) over (order by s.lsk), s.lsk, 0, c2.cnt_main) as cnt_main,
       p.fio, m.name as lg_name, u.nm2 as usl_name, b.summa, nvl(d.doc, '' '') as doc
  from arch_kart s, spul e, a_kart_pr p, spk m, a_lg_docs d, s_reu_trest t,
       usl u, (select sum(s.summa) as summa, s.lg_doc_id, s.spk_id, s.usl, s.kart_pr_id
                 from a_charge s
                where '||sqlstr_||' and s.spk_id=:spk_id_ and s.type = 4 and s.summa <> 0
                group by s.lg_doc_id, s.spk_id, s.usl, s.kart_pr_id) b,
              (select lsk, sum(kpr_cem) as kpr_cem from
                (select distinct s.lsk, s.kart_pr_id, 1 as kpr_cem
                 from a_charge s, usl m
                where '||sqlstr_||' and s.usl=m.usl and s.spk_id=:spk_id_ and m.usl_type=1
                 and s.type = 4 and s.summa <> 0)
                 group by lsk
                ) c,
              (select lsk, sum(kpr_s) as kpr_s from
                (select distinct s.lsk, s.kart_pr_id, 1 as kpr_s
                 from a_charge s, usl m
                where '||sqlstr_||' and s.usl=m.usl and s.spk_id=:spk_id_ and m.usl_type=0
                 and s.type = 4 and s.summa <> 0)
                 group by lsk
                ) c1,
              (select lsk, count(*) as cnt, sum(cnt_main) as cnt_main from (
                select distinct lsk, kart_pr_id, main as cnt_main from a_charge s
                where '||sqlstr_||' and s.spk_id=:spk_id_
                and s.type=4 and s.summa <> 0  --кол-во носителей льг.
                )
                group by lsk
                ) c2
 where s.lsk = p.lsk and t.trest=:trest_
   and s.kul = e.id
   and '||sqlstr_||'
   and s.lsk = c.lsk(+)
   and s.lsk = c1.lsk(+)
   and s.lsk = c2.lsk(+)
   and p.mg=s.mg
   and d.mg=s.mg
   and b.spk_id=m.id
   and p.id = b.kart_pr_id
   and b.usl = u.usl
   and d.id=b.lg_doc_id
   order by s.lsk, p.id'
   using spk_id_, spk_id_, spk_id_, spk_id_, trest_;
   elsif var_ = 0 then
   --По городу
   open prep_refcursor for
   'select substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg, s.lsk,
    initcap(trim(e.name) || '', '' || ltrim(s.nd, ''0'') || ''-'' || ltrim(s.kw, ''0'')) as adr,
       s.opl, s.kpr, c.kpr_cem, c1.kpr_s,
       decode(lag(s.lsk, 1) over (order by s.lsk), s.lsk, 0, c2.cnt) as cnt,
       decode(lag(s.lsk, 1) over (order by s.lsk), s.lsk, 0, c2.cnt_main) as cnt_main,
       p.fio, m.name as lg_name, u.nm2 as usl_name, b.summa, nvl(d.doc, '' '') as doc
  from arch_kart s, spul e, a_kart_pr p, spk m, a_lg_docs d,
       usl u, (select sum(s.summa) as summa, s.lg_doc_id, s.spk_id, s.usl, s.kart_pr_id
                 from a_charge s --суммы возмещ по льготам
                where '||sqlstr_||' and s.spk_id=:spk_id_ and s.type = 4 and s.summa <> 0
                group by s.lg_doc_id, s.spk_id, s.usl, s.kart_pr_id) b,
              (select lsk, sum(kpr_cem) as kpr_cem from
                (select distinct s.lsk, s.kart_pr_id, 1 as kpr_cem
                 from a_charge s, usl m --кол-во польз. льг. по жилью
                where '||sqlstr_||' and s.usl=m.usl and s.spk_id=:spk_id_ and m.usl_type=1
                 and s.type = 4 and s.summa <> 0)
                 group by lsk
                ) c,
              (select lsk, sum(kpr_s) as kpr_s from
                (select distinct s.lsk, s.kart_pr_id, 1 as kpr_s
                 from a_charge s, usl m --кол-во польз. льг. по комун.усл.
                where '||sqlstr_||' and s.usl=m.usl and s.spk_id=:spk_id_ and m.usl_type=0
                 and s.type = 4 and s.summa <> 0)
                 group by lsk
                ) c1,
              (select lsk, count(*) as cnt, sum(cnt_main) as cnt_main from (
                select distinct lsk, kart_pr_id, main as cnt_main from a_charge s
                where '||sqlstr_||' and s.spk_id=:spk_id_
                and s.type=4 and s.summa <> 0  --кол-во носителей льг.
                )
                group by lsk
                ) c2
 where s.lsk = p.lsk
   and s.kul = e.id
   and '||sqlstr_||'
   and s.lsk = c.lsk(+)
   and s.lsk = c1.lsk(+)
   and s.lsk = c2.lsk(+)
   and p.mg=s.mg
   and d.mg=s.mg
   and b.spk_id=m.id
   and p.id = b.kart_pr_id
   and b.usl = u.usl
   and d.id=b.lg_doc_id
   order by s.lsk, p.id'
   using spk_id_, spk_id_, spk_id_, spk_id_;
   end if;

 elsif сd_ = '57' then
 --Список по объёмным показателям
   if var_ = 3 then
    --По дому
    OPEN prep_refcursor FOR '
select t.trest||'' ''||t.name_reu as predp,
    k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'') AS predpr_det,
    LTRIM(s.kw,''0'') AS kw,
    TRIM(u.nm)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')'') AS nm,
    TRIM(u.nm1)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')'') AS nm1,
    p.name AS orgname, m.name AS STATUS, DECODE(s.psch,1,''Закрытые Л/С'', 2,''Старый фонд'', ''Открытые Л/С'') AS psch,
    DECODE(s.sch,1,''Счетчик'',''Норматив'') AS sch, s.val_group2 as val_group,
    sum(s.cnt) AS cnt, sum(s.klsk) AS klsk, sum(s.kpr) AS kpr, sum(s.kpr_ot) AS kpr_ot,
    sum(s.kpr_wr) AS kpr_wr, sum(s.cnt_lg) AS cnt_lg, sum(s.cnt_subs) AS cnt_subs, s.uch,
    substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg1,
    to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')) as nd1,
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' '')) as kw1
    FROM STATISTICS_LSK s, USL u, S_REU_TREST t, SPRORG p, STATUS m, SPUL k
    WHERE s.reu=t.reu and s.psch not in (8,9)
    AND s.USL=u.USL
    AND s.ORG=p.kod
    and u.uslm in
     (''004'',''006'',''007'',''008'')
    AND s.kul=k.id
    AND s.STATUS=m.id
    AND s.reu=:reu_ and s.kul=:kul_ and s.nd=:nd_
    AND ' || sqlstr_||'
    group by u.npp, t.trest||'' ''||t.name_reu,
    k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0''),
    LTRIM(s.kw,''0''),
    TRIM(u.nm)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')''),
    TRIM(u.nm1)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')''),
    p.name, m.name, DECODE(s.psch,1,''Закрытые Л/С'', 2,''Старый фонд'', ''Открытые Л/С''),
    DECODE(s.sch,1,''Счетчик'',''Норматив''), s.val_group2, s.uch,
    substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2), k.name,
    to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')),
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' ''))
    order by u.npp, k.name, to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')),
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' ''))'
   using reu_, kul_, nd_;
   elsif var_ = 2 then
    --По ЖЭО
    OPEN prep_refcursor FOR '
select t.trest||'' ''||t.name_reu as predp,
    k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'') AS predpr_det,
    LTRIM(s.kw,''0'') AS kw,
    TRIM(u.nm)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')'') AS nm,
    TRIM(u.nm1)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')'') AS nm1,
    p.name AS orgname, m.name AS STATUS, DECODE(s.psch,1,''Закрытые Л/С'', 2,''Старый фонд'', ''Открытые Л/С'') AS psch,
    DECODE(s.sch,1,''Счетчик'',''Норматив'') AS sch, s.val_group2 as val_group,
    sum(s.cnt) AS cnt, sum(s.klsk) AS klsk, sum(s.kpr) AS kpr, sum(s.kpr_ot) AS kpr_ot,
    sum(s.kpr_wr) AS kpr_wr, sum(s.cnt_lg) AS cnt_lg, sum(s.cnt_subs) AS cnt_subs, s.uch,
    substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg1,
    to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')) as nd1,
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' '')) as kw1
    FROM STATISTICS_LSK s, USL u, S_REU_TREST t, SPRORG p, STATUS m, SPUL k
    WHERE s.reu=t.reu and s.psch not in (8,9)
    AND s.USL=u.USL
    AND s.ORG=p.kod
    and u.uslm in
     (''004'',''006'',''007'',''008'')
    AND s.kul=k.id
    AND s.STATUS=m.id
    AND s.reu=:reu_
    AND ' || sqlstr_||'
    group by u.npp, t.trest||'' ''||t.name_reu,
    k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0''),
    LTRIM(s.kw,''0''),
    TRIM(u.nm)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')''),
    TRIM(u.nm1)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')''),
    p.name, m.name, DECODE(s.psch,1,''Закрытые Л/С'', 2,''Старый фонд'', ''Открытые Л/С''),
    DECODE(s.sch,1,''Счетчик'',''Норматив''), s.val_group2, s.uch,
    substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2), k.name,
    to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')),
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' ''))
    order by u.npp, k.name, to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')),
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' ''))'
   using reu_;
   elsif var_ = 1 then
    --По фонду
    OPEN prep_refcursor FOR '
 select t.trest||'' ''||t.name_reu as predp,
    k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'') AS predpr_det,
    LTRIM(s.kw,''0'') AS kw,
    TRIM(u.nm)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')'') AS nm,
    TRIM(u.nm1)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')'') AS nm1,
    p.name AS orgname, m.name AS STATUS, DECODE(s.psch,1,''Закрытые Л/С'', 2,''Старый фонд'', ''Открытые Л/С'') AS psch,
    DECODE(s.sch,1,''Счетчик'',''Норматив'') AS sch, s.val_group2 as val_group,
    sum(s.cnt) AS cnt, sum(s.klsk) AS klsk, sum(s.kpr) AS kpr, sum(s.kpr_ot) AS kpr_ot,
    sum(s.kpr_wr) AS kpr_wr, sum(s.cnt_lg) AS cnt_lg, sum(s.cnt_subs) AS cnt_subs, s.uch,
    substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg1,
    to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')) as nd1,
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' '')) as kw1
    FROM STATISTICS_LSK s, USL u, S_REU_TREST t, SPRORG p, STATUS m, SPUL k
    WHERE s.reu=t.reu and s.psch not in (8,9)
    AND s.USL=u.USL
    AND s.ORG=p.kod
    and u.uslm in
     (''004'',''006'',''007'',''008'')
    AND s.kul=k.id
    AND s.STATUS=m.id
    AND t.trest=:trest_
    AND ' || sqlstr_||'
    group by u.npp, t.trest||'' ''||t.name_reu,
    k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0''),
    LTRIM(s.kw,''0''),
    TRIM(u.nm)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')''),
    TRIM(u.nm1)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')''),
    p.name, m.name, DECODE(s.psch,1,''Закрытые Л/С'', 2,''Старый фонд'', ''Открытые Л/С''),
    DECODE(s.sch,1,''Счетчик'',''Норматив''), s.val_group2, s.uch,
    substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2), k.name,
    to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')),
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' ''))
    order by u.npp, k.name, to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')),
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' ''))'
   using trest_;
   elsif var_ = 0 then
   --По городу
    OPEN prep_refcursor FOR '
   select t.trest||'' ''||t.name_reu as predp,
    k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'') AS predpr_det,
    LTRIM(s.kw,''0'') AS kw,
    TRIM(u.nm)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')'') AS nm,
    TRIM(u.nm1)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')'') AS nm1,
    p.name AS orgname, m.name AS STATUS, DECODE(s.psch,1,''Закрытые Л/С'', 2,''Старый фонд'', ''Открытые Л/С'') AS psch,
    DECODE(s.sch,1,''Счетчик'',''Норматив'') AS sch, s.val_group2 as val_group,
    sum(s.cnt) AS cnt, sum(s.klsk) AS klsk, sum(s.kpr) AS kpr, sum(s.kpr_ot) AS kpr_ot,
    sum(s.kpr_wr) AS kpr_wr, sum(s.cnt_lg) AS cnt_lg, sum(s.cnt_subs) AS cnt_subs, s.uch,
    substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg1,
    to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')) as nd1,
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' '')) as kw1
    FROM STATISTICS_LSK s, USL u, S_REU_TREST t, SPRORG p, STATUS m, SPUL k
    WHERE s.reu=t.reu and s.psch not in (8,9)
    AND s.USL=u.USL
    AND s.ORG=p.kod
    and u.uslm in
     (''004'',''006'',''007'',''008'')
    AND s.kul=k.id
    AND s.STATUS=m.id
    AND ' || sqlstr_||'
    group by u.npp, t.trest||'' ''||t.name_reu,
    k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0''),
    LTRIM(s.kw,''0''),
    TRIM(u.nm)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')''),
    TRIM(u.nm1)||DECODE(u.ed_izm,NULL,'''','' (''||TRIM(u.ed_izm)||'')''),
    p.name, m.name, DECODE(s.psch,1,''Закрытые Л/С'', 2,''Старый фонд'', ''Открытые Л/С''),
    DECODE(s.sch,1,''Счетчик'',''Норматив''), s.val_group2, s.uch,
    substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2), k.name,
    to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')),
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' ''))
    order by u.npp, k.name, to_number(translate(upper(s.nd),
    translate(upper(s.nd),''0123456789'','' ''), '' '')),
    to_number(translate(upper(s.kw),
    translate(upper(s.kw),''0123456789'','' ''), '' ''))';
   end if;
 elsif сd_ = '58' then
 --Список квартиросъемщиков, имеющих счетчики учета воды
   if var_ = 3 then
    --По дому
    OPEN prep_refcursor FOR '
      select s.lsk, k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'')||''-''||NVL(LTRIM(s.kw,''0''),''0'') as adr,
             case when s.psch in (1,2) then s.phw
               else null end as phw,
             case when s.psch in (1,3) then s.pgw
               else null end as pgw,
             case when s.sch_el in (1) then s.pel
               else null end as pel,
             case when nvl(s.pot,0) <> 0 then s.pot
               else null end as pot
        from arch_kart s, s_reu_trest t, spul k, v_lsk_tp tp
       where s.reu = t.reu and s.fk_tp=tp.id and tp.cd=''LSK_TP_MAIN''
         and s.reu=:reu_ and s.kul=:kul_ and s.nd=:nd_
         and (s.psch not in (8, 9, 0) or s.psch not in (8, 9) and nvl(s.pot, 0)<>0)
         and s.kul = k.id
         and (nvl(s.phw,0) <> 0 or nvl(s.pgw,0) <> 0 or nvl(s.pel,0) <> 0 or nvl(s.pot,0) <> 0)
         and ' || sqlstr_||'
       order by k.name, utils.f_order(s.nd,6), utils.f_order2(s.nd), utils.f_order(s.kw,7)'
   using reu_, kul_, nd_;
   elsif var_ = 2 then
    --По ЖЭО
    OPEN prep_refcursor FOR '
      select s.lsk, k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'')||''-''||NVL(LTRIM(s.kw,''0''),''0'') as adr,
             case when s.psch in (1,2) then s.phw
               else null end as phw,
             case when s.psch in (1,3) then s.pgw
               else null end as pgw,
             case when s.sch_el in (1) then s.pel
               else null end as pel,
             case when nvl(s.pot,0) <> 0 then s.pot
               else null end as pot
        from arch_kart s, s_reu_trest t, spul k, v_lsk_tp tp
       where s.reu = t.reu and s.fk_tp=tp.id and tp.cd=''LSK_TP_MAIN''
         and s.reu =:reu_
         and (s.psch not in (8, 9, 0) or s.psch not in (8, 9) and nvl(s.pot, 0)<>0)
         and s.kul = k.id
         and (nvl(s.phw,0) <> 0 or nvl(s.pgw,0) <> 0 or nvl(s.pel,0) <> 0 or nvl(s.pot,0) <> 0)
         and ' || sqlstr_||'
       order by k.name, utils.f_order(s.nd,6), utils.f_order2(s.nd), utils.f_order(s.kw,7)'
   using reu_;
   elsif var_ = 1 then
    --По фонду
    OPEN prep_refcursor FOR '
      select s.lsk, k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'')||''-''||NVL(LTRIM(s.kw,''0''),''0'') as adr,
             case when s.psch in (1,2) then s.phw
               else null end as phw,
             case when s.psch in (1,3) then s.pgw
               else null end as pgw,
             case when s.sch_el in (1) then s.pel
               else null end as pel,
             case when nvl(s.pot,0) <> 0 then s.pot
               else null end as pot
        from arch_kart s, s_reu_trest t, spul k, v_lsk_tp tp
       where s.reu = t.reu and s.fk_tp=tp.id and tp.cd=''LSK_TP_MAIN''
         and t.trest =:trest_
         and (s.psch not in (8, 9, 0) or s.psch not in (8, 9) and nvl(s.pot, 0)<>0)
         and s.kul = k.id
         and (nvl(s.phw,0) <> 0 or nvl(s.pgw,0) <> 0 or nvl(s.pel,0) <> 0 or nvl(s.pot,0) <> 0)
         and ' || sqlstr_||'
       order by k.name, utils.f_order(s.nd,6), utils.f_order2(s.nd), utils.f_order(s.kw,7)'
   using trest_;
   elsif var_ = 0 then
   --По городу
    OPEN prep_refcursor FOR '
      select s.lsk, k.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'')||''-''||NVL(LTRIM(s.kw,''0''),''0'') as adr,
             case when s.psch in (1,2) then s.phw
               else null end as phw,
             case when s.psch in (1,3) then s.pgw
               else null end as pgw,
             case when s.sch_el in (1) then s.pel
               else null end as pel,
             case when nvl(s.pot,0) <> 0 then s.pot
               else null end as pot
        from arch_kart s, s_reu_trest t, spul k, v_lsk_tp tp
       where s.reu = t.reu and s.fk_tp=tp.id and tp.cd=''LSK_TP_MAIN''
         and (s.psch not in (8, 9, 0) or s.psch not in (8, 9) and nvl(s.pot, 0)<>0)
         and s.kul = k.id
         and (nvl(s.phw,0) <> 0 or nvl(s.pgw,0) <> 0 or nvl(s.pel,0) <> 0 or nvl(s.pot,0) <> 0)
         and ' || sqlstr_||'
       order by k.name, utils.f_order(s.nd,6), utils.f_order2(s.nd), utils.f_order(s.kw,7)';
   end if;
 elsif сd_ = '59' then
 --Оплата для Э+
 OPEN prep_refcursor FOR 'select u.nm as name_usl, substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg1, t.name_tr,
   r.name as name_org,
   decode(t.ink, 0, ''самост'', 1, ''не самост'') as name_status, sum(s.summa) as summa
  from rmt_xxito15 s, rmt_s_reu_trest t, rmt_usl u, rmt_sprorg r
  where s.usl in (''020'',''021'') and s.forreu=t.reu and ' || sqlstr_||'
   and s.org=r.kod and s.priznak=1 and s.usl = u.usl
  group by u.nm, substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2), r.name,
   t.name_tr, decode(t.ink, 0, ''самост'', 1, ''не самост'')
  order by substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2),
   decode(t.ink, 0, ''самост'', 1, ''не самост''), r.name';

 elsif сd_ = '60' then
 --Статистика по Программам - Пакетам пользователя
   if det_ = 3 then
      --По дому
     open prep_refcursor for 'select t.trest||'' ''||t.name_tr as predp,
     k.name||'', ''||nvl(ltrim(r.nd,''0''),''0'')||''-''||ltrim(r.kw,''0'') as predpr_det,
      i.name as tarif_name, u.nm,
     substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg
      from kart r, a_nabor_progs s, spr_tarif i, s_reu_trest t, spul k, usl u
         where r.kul=k.id and r.reu=t.reu and r.lsk=s.lsk and s.usl=u.usl
         and s.fk_tarif=i.id
         and r.reu=:reu_ and r.kul=:kul_ and r.nd=:nd_ and ' || sqlstr_
     using reu_, kul_, nd_;
       elsif det_ = 2 then
        --По ЖЭО
        open prep_refcursor for 'select t.reu||'' ''||t.name_reu as predp,
     k.name||'', ''||nvl(ltrim(r.nd,''0''),''0'') as predpr_det,
     i.name as tarif_name, u.nm,
     substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg
      from kart r, a_nabor_progs s, spr_tarif i, s_reu_trest t, spul k, usl u
         where r.kul=k.id and r.reu=t.reu and r.lsk=s.lsk and s.usl=u.usl
         and s.fk_tarif=i.id
         and r.reu=:reu_ and ' || sqlstr_
     using reu_;
       elsif det_ = 1 then
        --По Фонду
        open prep_refcursor for 'select t.trest||'' ''||t.name_tr as predp,
     k.name||'', ''||nvl(ltrim(r.nd,''0''),''0'') as predpr_det,
     i.name as tarif_name, u.nm,
     substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg
      from kart r, a_nabor_progs s, spr_tarif i, s_reu_trest t, spul k, usl u
         where r.kul=k.id and r.reu=t.reu and r.lsk=s.lsk and s.usl=u.usl
         and s.fk_tarif=i.id
         and t.trest=:trest_ and ' || sqlstr_
     using trest_;
      elsif det_ = 0 then
        --По Городу
        open prep_refcursor for 'select t.trest||'' ''||t.name_tr as predp,
     k.name||'', ''||nvl(ltrim(r.nd,''0''),''0'') as predpr_det,
     i.name as tarif_name, u.nm,
     substr(s.mg, 1, 4)||''-''||substr(s.mg, 5, 2) as mg
      from kart r, a_nabor_progs s, spr_tarif i, s_reu_trest t, spul k, usl u
         where r.kul=k.id and r.reu=t.reu and r.lsk=s.lsk and s.usl=u.usl
         and s.fk_tarif=i.id
         and ' || sqlstr_;
     end if;
 elsif сd_ = '61' then
 --Оплата по Ф 2.4. ред. 10.03.20
  if dat_ is not null and dat1_ is not null then
   sqlstr_ := 'select * from xxito14 a where a.dat between to_date('''||l_str_dat||''',''DD.MM.YYYY'') and to_date('''||l_str_dat1||''',''DD.MM.YYYY'') and a.mg='''||l_char_dat_mg||'''';
  elsif dat_ is not null and dat1_ is null then
   sqlstr_ := 'select * from xxito14 a where a.dat = to_date('''||l_str_dat||''',''DD.MM.YYYY'') and a.mg='''||l_char_dat_mg||'''';
  elsif dat_ is null and dat1_ is null then
   sqlstr_ := 'select * from xxito14 a where a.mg between '''||mg_||''' and '''||mg1_||'''';
  end if;
   sqlstr_ := sqlstr_||' and exists
           (select * from list_c i, spr_params p where i.fk_ses='||fk_ses_||'
                and p.id=i.fk_par and p.cd=''REP_USL2'' 
                and i.sel_cd=a.usl
            and i.sel=1)
            and exists
           (select * from list_c i, spr_params p where i.fk_ses='||fk_ses_||'
                and p.id=i.fk_par and p.cd=''REP_ORG2'' 
                and i.sel_id=a.org
            and i.sel=1) ';
    if var_ = 2 then
    --по РЭУ
        OPEN prep_refcursor for 'select '''||period_||''' as period, s.trest, substr(t.name_tr, 1, 15) as name_tr, s.oper,
               to_char(o.kod) || '' '' || substr(o.name, 1, 20) as name,
               substr(u.nm1, 1, 20) as nm1, sum(summa) as summa,
               decode(s.cd_tp, 0, ''Пеня'', ''Оплата'') as cd_tp
         from 
         ('||sqlstr_||') s, s_reu_trest t, sprorg o, usl u
           where s.forreu = t.reu
             and s.org = o.kod
             and s.forreu = '||reu_||'
             and s.usl = u.usl 
           group by s.trest, substr(t.name_tr, 1, 15), s.oper,
          to_char(o.kod) || '' '' || substr(o.name, 1, 20),
          substr(u.nm1, 1, 20),
          decode(s.cd_tp, 0, ''Пеня'', ''Оплата'')';
    elsif var_ = 1 then
    --по ЖЭО
          
        OPEN prep_refcursor FOR 'select '''||period_||''' as period, s.trest, substr(t.name_tr, 1, 15) as name_tr, s.oper,
               to_char(o.kod) || '' '' || substr(o.name, 1, 20) as name,
               substr(u.nm1, 1, 20) as nm1, sum(summa) as summa,
               decode(s.cd_tp, 0, ''Пеня'', ''Оплата'') as cd_tp
         from ('||sqlstr_||') s, s_reu_trest t, sprorg o, usl u
           where s.forreu = t.reu
             and s.org = o.kod
             and s.trest = '||trest_||'
             and s.usl = u.usl 
           group by s.trest, substr(t.name_tr, 1, 15), s.oper,
          to_char(o.kod) || '' '' || substr(o.name, 1, 20),
          substr(u.nm1, 1, 20),
          decode(s.cd_tp, 0, ''Пеня'', ''Оплата'')';
    elsif var_ = 0 then
    --по Городу
        OPEN prep_refcursor FOR 'select '''||period_||''' as period, s.trest, substr(t.name_tr, 1, 15) as name_tr, s.oper,
               to_char(o.kod) || '' '' || substr(o.name, 1, 20) as name,
               substr(u.nm1, 1, 20) as nm1, sum(summa) as summa,
               decode(s.cd_tp, 0, ''Пеня'', ''Оплата'') as cd_tp
         from ('||sqlstr_||') s, s_reu_trest t, sprorg o, usl u
           where s.forreu = t.reu
             and s.org = o.kod
             and s.usl = u.usl 
           group by s.trest, substr(t.name_tr, 1, 15), s.oper,
          to_char(o.kod) || '' '' || substr(o.name, 1, 20),
          substr(u.nm1, 1, 20),
          decode(s.cd_tp, 0, ''Пеня'', ''Оплата'')';
    end if;

 elsif сd_ in  ('62','63') then
 --список-оборотка для субсидирования ТСЖ
    if сd_='62' then
      uslg_:='001';
    elsif сd_='63' then
      uslg_:='002';
    end if;
    --список для ТСЖ
    open prep_refcursor for
    'select l.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'') as adr,
    ltrim(s.kw,''0'') as kw,
    s.komn, s.opl, b.opl_n, b.opl_sv, s.fio, s.kpr, b.summa_n, b.summa_sv,
     decode(s.psch, 1, gw.gw_n, 3, gw.gw_n, 0) as gw_sch_n,
     decode(s.psch, 1, gw.gw_sv, 3, gw.gw_sv, 0) as gw_sch_sv,
     decode(s.psch, 0, gw.gw_n, 2, gw.gw_n, 0) as gw_n,
     decode(s.psch, 0, gw.gw_sv, 2, gw.gw_sv, 0) as gw_sv,
     decode(s.psch, 0, gw.summa_n, 2, gw.summa_n, 0) as gw_n_summa_n,
     decode(s.psch, 0, gw.summa_sv, 2, gw.summa_sv, 0) as gw_n_summa_sv,
     decode(s.psch, 1, gw.summa_n, 3, gw.summa_n, 0) as gw_sch_summa_n,
     decode(s.psch, 1, gw.summa_sv, 3, gw.summa_sv, 0) as gw_sch_summa_sv,
     decode(s.psch, 0, gw2.cnt, 2, gw2.cnt, 0) as gw_n_corr,
     decode(s.psch, 1, gw2.cnt, 3, gw2.cnt, 0) as gw_sch_corr,
     decode(s.psch, 0, gw2.summa, 2, gw2.summa, 0) as gw_n_corr_summa,
     decode(s.psch, 1, gw2.summa, 3, gw2.summa, 0) as gw_sch_corr_summa,
     d.chng,
    c.name, c.adr as org_adr, c.inn, c.kpp, c.head_name,
    upper(utils.MONTH_NAME(substr(s.mg,5,2)))||'' ''||substr(s.mg,1,4)||''г.'' as mg_name,
    upper(s.nm) as nm
    from (select s.*, u.uslg, u.nm from arch_kart s, uslg u  where '||sqlstr_||'
     and exists
      (select * from a_charge a, usl u where a.usl=u.usl and
        u.uslg in (:uslg_) and a.type = 1 and a.summa <> 0
        and a.lsk=s.lsk and a.mg=s.mg
      )
    and s.reu=:reu_ and u.uslg=:uslg_
     and s.psch not in (8,9)
     and s.status not in (7)--убрал нежилые по просьбе ТСЖ Клён, ред.09.01.13
     ) s, t_org c, params p, spul l,
    (select s.lsk, u.uslg,
     sum(decode(u.usl_norm, 0, decode(s.type, 1, s.summa, 0))) as summa_n,
     sum(decode(u.usl_norm, 1, decode(s.type, 1, s.summa, 0))) as summa_sv,
     sum(decode(u.usl_norm, 0, decode(s.type, 1, s.test_opl, 0), 0)) as opl_n,
     sum(decode(u.usl_norm, 1, decode(s.type, 1, s.test_opl, 0), 0)) as opl_sv
      from (
      select s.lsk, s.usl, s.type, s.test_opl, s.summa from a_charge s, usl u where '||sqlstr_||' and s.usl=u.usl and
      u.uslg=:uslg_ and s.type in (1, 2, 4)
      ) s, usl u
      where s.usl=u.usl
     group by s.lsk, u.uslg) b,
      (select s.lsk, u.uslg, sum(s.summa) as chng from a_change s, usl u where '||sqlstr_||' and s.usl=u.usl and
       u.uslg=:uslg_
       group by s.lsk, u.uslg) d,
    (select s.lsk,
     sum(decode(u.usl_norm, 0, decode(s.type, 1, s.summa, 0))) as summa_n,
     sum(decode(u.usl_norm, 1, decode(s.type, 1, s.summa, 0))) as summa_sv,
     sum(decode(u.usl_norm, 0, decode(s.type, 1, s.test_opl, 0), 0)) as gw_n,
     sum(decode(u.usl_norm, 1, decode(s.type, 1, s.test_opl, 0), 0)) as gw_sv
      from (
      select s.lsk, s.usl, s.type, s.test_opl, s.summa from a_charge s, usl u where '||sqlstr_||' and s.usl=u.usl and
      u.cd in (''г.вода'', ''г.вода/св.нор'') and s.type in (1, 2, 4)
      ) s, usl u
      where s.usl=u.usl
     group by s.lsk) gw,
    (select s.lsk,
      sum(s.cnt) as cnt,
      sum(s.summa) as summa
      from (
      select s.lsk, s.usl, s.test_opl as cnt, s.summa from a_charge s, usl u where '||sqlstr_||' and s.usl=u.usl and
      u.cd in (''г.вода.ОДН'') and s.type in (1)
      ) s
     group by s.lsk) gw2
    where s.lsk = b.lsk(+) and s.kul=l.id and s.lsk=gw.lsk(+) and s.uslg=b.uslg(+)
     and s.lsk = d.lsk(+) and s.uslg=d.uslg(+)
     and s.reu=c.reu and s.lsk=gw2.lsk(+)
    order by l.name, s.nd, s.kw'
    using uslg_, reu_, uslg_, uslg_, uslg_;
 elsif сd_ in  ('64') then
 dat2_:=utils.getS_date_param('REP_DT_BR1');
 dat3_:=utils.getS_date_param('REP_DT_BR2');
 gndr_:=utils.getS_list_param('REP_GENDER');
 --Отчет по проживающим, для паспортного стола
    --список для ТСЖ
    if var_ = 3 then
    --по РЭУ
    open prep_refcursor for
      select
      l.name||', '||NVL(LTRIM(s.nd,'0'),'0')||'-'||NVL(LTRIM(s.kw,'0'),'0') as adr,
      p.fio, p.dat_rog
      from arch_kart s, a_kart_pr p, spul l
      where s.mg=mg_ and s.lsk=p.lsk and s.kul=l.id and s.mg=p.mg
      and s.reu=reu_ and s.kul=kul_ and s.nd=nd_ and p.dat_rog between dat2_ and dat3_
      and s.psch<>8 and ((gndr_ <> 2 and p.pol=gndr_) or gndr_ = 2)
      and p.status<>4
      order by l.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
    elsif var_ = 2 then
    --по РЭУ
    open prep_refcursor for
      select
      l.name||', '||NVL(LTRIM(s.nd,'0'),'0')||'-'||NVL(LTRIM(s.kw,'0'),'0') as adr,
      p.fio, p.dat_rog
      from arch_kart s, a_kart_pr p, spul l
      where s.mg=mg_ and s.lsk=p.lsk and s.kul=l.id and s.mg=p.mg
      and s.reu=reu_ and p.dat_rog between dat2_ and dat3_
      and s.psch<>8 and ((gndr_ <> 2 and p.pol=gndr_) or gndr_ = 2)
      and p.status<>4
      order by l.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
    elsif var_ = 1 then
    --по ЖЭО
    open prep_refcursor for
      select
      l.name||', '||NVL(LTRIM(s.nd,'0'),'0')||'-'||NVL(LTRIM(s.kw,'0'),'0') as adr,
      p.fio, p.dat_rog
      from arch_kart s, a_kart_pr p, spul l, s_reu_trest t
      where s.mg=mg_ and s.lsk=p.lsk and s.kul=l.id and s.mg=p.mg
      and s.reu=t.reu and t.trest=trest_ and p.dat_rog between dat2_ and dat3_
      and s.psch<>8 and ((gndr_ <> 2 and p.pol=gndr_) or gndr_ = 2)
      and p.status<>4
      order by l.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
    elsif var_ = 0 then
    --по Городу
    open prep_refcursor for
      select
      l.name||', '||NVL(LTRIM(s.nd,'0'),'0')||'-'||NVL(LTRIM(s.kw,'0'),'0') as adr,
      p.fio, p.dat_rog
      from arch_kart s, a_kart_pr p, spul l
      where s.mg=mg_ and s.lsk=p.lsk and s.kul=l.id and s.mg=p.mg
      and p.dat_rog between dat2_ and dat3_
      and s.psch<>8 and ((gndr_ <> 2 and p.pol=gndr_) or gndr_ = 2)
      and p.status<>4
      order by l.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
    end if;
 elsif сd_ in  ('65') then
 --Отчет для сверки распределения оплаты
    --список для ТСЖ
    if var_ in (1,2,3) then
      raise_application_error(-20001,'Не существует уровня детализации!');
    elsif var_ = 0 then
      if dat1_ is not null and dat2_ is not null then
        mg2_:=mg_;
      else
        select period into mg2_ from params p;
      end if;
      --по Городу
      open prep_refcursor for
        'select s.fk_distr, decode(s.fk_distr,0,''деб.сальдо'',1,''кред.сальдо'',2,''тек.начисл.'',3,''на одну усл.'',4,
         ''ошибочн.оплата'') as type_distr, o.name as name_tr,
         u.nm as name_usl, o2.name as name_org,
         b.pay as pay_itg, s.pay, t.deb,
         decode(s.fk_distr, 0, decode(nvl(a.deb,0), 0, 0, round(t.deb/a.deb,2)*100), decode(nvl(d.chrg,0), 0, 0, round(r.chrg/d.chrg,2)*100)) as deb_proc, s.sum_distr,
         round(s.pay/b.pay,2)*100 as pay_proc, r.chrg, d.chrg as chrg1,
         decode(nvl(d.chrg,0), 0, 0, round(r.chrg/d.chrg,2)) as chrg_proc
         from
        (select s.forreu as reu, s.fk_distr, s.usl, s.org, sum(s.summa) as pay, sum(s.sum_distr) as sum_distr
         from xxito14 s where '||sqlstr_||' and s.oper <> ''99'' --кроме корректировок
         group by s.forreu, s.fk_distr, s.usl, s.org) s,
         (select c.reu, c.usl, c.org, sum(c.indebet) as deb
         from xitog3 c where mg='''||mg2_||'''
         group by c.reu, c.usl, c.org) t,
         (select c.reu, c.usl, c.org, sum(c.charges) as chrg --текущее начисление
         from xitog3 c where mg='''||mg2_||'''
         group by c.reu, c.usl, c.org) r,
         (select c.reu, sum(c.charges) as chrg --текущее начисление итогом по РЭУ
         from xitog3 c where mg='''||mg2_||'''
         group by c.reu) d,
        (select reu, sum(c.indebet) as deb
         from xitog3 c where mg='''||mg2_||'''
        group by reu) a,
        (select s.forreu as reu, s.fk_distr, sum(s.summa) as pay
         from xxito14 s where '||sqlstr_||' and s.oper <> ''99'' --кроме корректировок
        group by s.forreu, s.fk_distr) b,
         usl u, t_org o, t_org o2
        where s.reu=t.reu(+) and s.usl=t.usl(+) and s.org=t.org(+) and
         s.reu=r.reu(+) and s.usl=r.usl(+) and s.org=r.org(+) and s.reu=d.reu(+) and
         s.reu=a.reu(+) and s.reu=b.reu and s.fk_distr=b.fk_distr and s.usl=u.usl and s.org=o2.id
         and s.reu=o.reu
        order by s.fk_distr, o.name, u.nm, o2.name';
--0 -по дебетовому сальдо
--1 -по кредитовому сальдо
--2 -только для платежей где где отношение деб.сальдо/платеж < 1 (по текущему начислению + дебет сальдо вх)
--3 -как в Э+ (вся оплата на одну услугу)
--4 -неудачное распределение (не найдено ни в сальдо ни в начислении как распределять оплату)
--5 -корректировки оплаты
 end if;
 elsif сd_ in  ('66') then
  --Реестры по задолжникам, по тарифам, для Дениса (Э+)
  --Выполнять после итогового формирования (чтоб вошла вся текущая оплата)
  --Вычисляем следующий месяц
    mg2_ := to_char(add_months(to_date(mg_ || '01', 'YYYYMMDD'), 1),
                   'YYYYMM');
    open prep_refcursor for
    select k.lsk, substr(trim(k.fio),1,25) as fio,
       substr(l.name||', '||NVL(LTRIM(k.nd,'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') ,1,32)  as adr,
        1 as type, u.nm as type_name, f.name as tarif_name,
       mg2_ as period, nvl(s.summa,0) as summa
       from kart k , nabor n, saldo_usl s,
        spul l, usl u, spr_tarif f
        where k.lsk=s.lsk and k.lsk=n.lsk and n.usl=u.usl and n.fk_tarif=f.id
         and k.kul=l.id and k.lsk=s.lsk and s.mg=mg2_
        and s.usl=u.usl and u.cd='каб.тел.' and f.cdtp='ИНТ'
        order by f.name;

 elsif сd_ in  ('67') then
  --Долги для Сбербанка-2 (для кабельного)
  --Выполнять после итогового формирования (чтоб вошла вся текущая оплата)
  --Вычисляем следующий месяц
    mg2_ := to_char(add_months(to_date(mg_ || '01', 'YYYYMMDD'), 1),
                   'YYYYMM');
--для Сбера
    open prep_refcursor for
      select k.lsk,
      '' as fio,
       substr(o.name||','||l.name||', '||NVL(LTRIM(k.nd,'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') ,1,52)  as adr,
        1 as type, s.nm as type_name,
       mg_ as period, null as empty_field, nvl(sum(s.summa),0)*100 as summa
       from kart k, t_org o, t_org_tp tp,
        (select t.*, u.nm from saldo_usl t, usl u where
         t.mg=mg2_ and t.usl=u.usl and u.cd in ('каб.тел.', 'антен.д.нач.','антен.нач.')) s
        , spul l --лицевые по которым есть сальдо
        where k.psch not in (8,9) and k.lsk=s.lsk and k.kul=l.id
        and tp.cd='Город' and o.fk_orgtp=tp.id
        group by k.lsk, substr(trim(k.fio),1,25), s.nm,
        substr(o.name||','||l.name||', '||NVL(LTRIM(k.nd,'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') ,1,52)
        union all
      select k.lsk,
      '' as fio,
       substr(o.name||','||l.name||', '||NVL(LTRIM(k.nd,'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') ,1,52)  as adr,
        1 as type, u.nm as type_name,
       mg_ as period, null as empty_field, 0 as summa
       from kart k, t_org o, t_org_tp tp, nabor n, spul l, usl u --лицевые по которым нет сальдо
        where k.psch not in (8,9) and k.lsk=n.lsk and k.kul=l.id
        and nvl(decode(u.sptarn, 0, nvl(n.koeff,0), 1, nvl(n.norm,0), 2,
               nvl(n.koeff,0) * nvl(n.norm,0), 3, nvl(n.koeff,0) * nvl(n.norm,0)), 0) <> 0
        and n.usl=u.usl and u.cd in ('каб.тел.', 'антен.д.нач.','антен.нач.')
        and tp.cd='Город' and o.fk_orgtp=tp.id
        and not exists
        (select t.*, u.nm from saldo_usl t, usl u where
         t.mg=mg2_ and t.usl=u.usl and u.cd in ('каб.тел.', 'антен.д.нач.','антен.нач.')
         and t.lsk=k.lsk
         )
        group by k.lsk, substr(trim(k.fio),1,25), u.nm,
        substr(o.name||','||l.name||', '||NVL(LTRIM(k.nd,'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') ,1,52);
--       having sum(summa) > 0; ред 03.10.2011
 elsif сd_ in  ('68') then
    open prep_refcursor for
      select 'USL' as tp_cd, null as lsk, t.usl as s1, t.nm as s2, null as s3, null as n1
        from usl t
        union all
      select 'ORG' as tp_cd, null as lsk, t.cd as s1, t.name as s2, null as s3, null as n1
        from t_org t
        union all
      select 'STREET' as tp_cd, null as lsk, t.id as s1, t.name as s2, null as s3, null as n1
        from spul t
        union all
      select 'ADR' as tp_cd, t.lsk, t.kul as s1, t.nd as s2, t.kw as s3, null as n1
        from kart t
        union all
      select 'VOL' as tp_cd, n.lsk, n.usl as s1, o.cd as s2, null as s3,
                     round(nvl(decode(u.sptarn, 0, nvl(n.koeff,0), 1, nvl(n.norm,0), 2,
                     nvl(n.koeff,0) * nvl(n.norm,0), 3, nvl(n.koeff,0) * nvl(n.norm,0), 4, nvl(n.koeff,0) * nvl(n.norm,0)), 0), 8) as n1
        from nabor n, t_org o, usl u
        where n.org=o.id and n.usl=u.usl
        and round(nvl(decode(u.sptarn, 0, nvl(n.koeff,0), 1, nvl(n.norm,0), 2,
                     nvl(n.koeff,0) * nvl(n.norm,0), 3, nvl(n.koeff,0) * nvl(n.norm,0), 4, nvl(n.koeff,0) * nvl(n.norm,0)), 0), 8) <> 0
                      and u.usl in ('045', '046');
 elsif сd_ in  ('69') then
  --Задолжники FR, вне зависимости от организатора задолжника

  --(не смог сделать по другому, так как в одной квартире могут быть разные орг. а задолжность
  --по членам семьи - не делится)
   kpr1_:=utils.getS_int_param('REP_RNG_KPR1');
   kpr2_:=utils.getS_int_param('REP_RNG_KPR2');

   n1_:=utils.getS_list_param('REP_DEB_VAR');
   if n1_=0 then
     n2_:=utils.getS_int_param('REP_DEB_MONTH');
     else
     n2_:=utils.getS_int_param('REP_DEB_SUMMA');
   end if;

    if var_ = 3 then
    --по Дому
    open prep_refcursor for
    'select s.lsk, t.name_reu, trim(s.name) as street_name,
      ltrim(s.nd,''0'') as nd, ltrim(s.kw,''0'') as kw, s.fio, s.cnt_month, s.dolg, s.pen_in, s.pen_cur, s.penya,
      case when s.dat is null and s.mg is not null then last_day(to_date(s.mg||''01'',''YYYYMMDD''))
           else s.dat
           end as dat
      from debits_lsk_month s, s_reu_trest t
      where s.reu=t.reu
      and ' || sqlstr_ || '
      and s.reu=:reu_ AND s.kul=:kul_ AND s.nd=:nd_
      and exists
      (select * from kart k where k.lsk=s.lsk
      and (:kpr1_ is not null and k.kpr >=:kpr1_ or :kpr1_ is null)
      and (:kpr2_ is not null and k.kpr <=:kpr2_ or :kpr2_ is null))
      and
      ((:n1_=0 and s.cnt_month >= :n2_) or
      (:n1_=1 and s.dolg >= :n2_))
      order by t.name_reu, s.name, s.nd, s.kw'
      using reu_, kul_, nd_,
    kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_;

    elsif var_ = 2 then
    --по РЭУ
    open prep_refcursor for
    'select s.lsk, t.name_reu, trim(s.name) as street_name,
      ltrim(s.nd,''0'') as nd, ltrim(s.kw,''0'') as kw, s.fio, s.cnt_month, s.dolg, s.pen_in, s.pen_cur, s.penya,
      case when s.dat is null and s.mg is not null then last_day(to_date(s.mg||''01'',''YYYYMMDD''))
           else s.dat
           end as dat
      from debits_lsk_month s, s_reu_trest t
      where s.reu=t.reu
      and ' || sqlstr_ || '
      and s.reu=:reu_
      and exists
      (select * from kart k where k.lsk=s.lsk
      and (:kpr1_ is not null and k.kpr >=:kpr1_ or :kpr1_ is null)
      and (:kpr2_ is not null and k.kpr <=:kpr2_ or :kpr2_ is null))
      and
      ((:n1_=0 and s.cnt_month >= :n2_) or
      (:n1_=1 and s.dolg >= :n2_))
      order by t.name_reu, s.name, s.nd, s.kw'
      using reu_,
    kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_;

    elsif var_ = 1 then
    --по ЖЭО
    open prep_refcursor for
    'select s.lsk, t.name_reu, trim(s.name) as street_name,
      ltrim(s.nd,''0'') as nd, ltrim(s.kw,''0'') as kw, s.fio, s.cnt_month, s.dolg, s.pen_in, s.pen_cur, s.penya,
      case when s.dat is null and s.mg is not null then last_day(to_date(s.mg||''01'',''YYYYMMDD''))
           else s.dat
           end as dat
      from debits_lsk_month s, s_reu_trest t
      where s.reu=t.reu
      and ' || sqlstr_ || '
      and s.reu=:trest_
      and exists
      (select * from kart k where k.lsk=s.lsk
      and (:kpr1_ is not null and k.kpr >=:kpr1_ or :kpr1_ is null)
      and (:kpr2_ is not null and k.kpr <=:kpr2_ or :kpr2_ is null))
      and
      ((:n1_=0 and s.cnt_month >= :n2_) or
      (:n1_=1 and s.dolg >= :n2_))
      order by t.name_reu, s.name, s.nd, s.kw'
      using trest_,
    kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_;

    elsif var_ = 0 then
    --по Городу
    open prep_refcursor for
    'select s.lsk, t.name_reu, trim(s.name) as street_name,
      ltrim(s.nd,''0'') as nd, ltrim(s.kw,''0'') as kw, s.fio, s.cnt_month, s.dolg, s.pen_in, s.pen_cur, s.penya,
      case when s.dat is null and s.mg is not null then last_day(to_date(s.mg||''01'',''YYYYMMDD''))
           else s.dat
           end as dat
      from debits_lsk_month s, s_reu_trest t
      where s.reu=t.reu
      and ' || sqlstr_ || '
      and exists
      (select * from kart k where k.lsk=s.lsk
      and (:kpr1_ is not null and k.kpr >=:kpr1_ or :kpr1_ is null)
      and (:kpr2_ is not null and k.kpr <=:kpr2_ or :kpr2_ is null))
      and
      ((:n1_=0 and s.cnt_month >= :n2_) or
      (:n1_=1 and s.dolg >= :n2_))
      order by t.name_reu, s.name, s.nd, s.kw'
      using kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_;

    end if;

 elsif сd_ in  ('73','74') then
 dat2_:=nvl(utils.getS_date_param('REP_DT_PROP1'),to_date('19000101','YYYYMMDD'));
 dat3_:=nvl(utils.getS_date_param('REP_DT_PROP2'),to_date('29000101','YYYYMMDD'));
 prop_:=nvl(utils.getS_list_param('REP_PROP_VAR'),0);
 --Отчет по прописанным/выписанным, для паспортного стола
    --список для ТСЖ
    if var_ = 3 then
    --по Дому
    open prep_refcursor for
      select
      l.name||', '||NVL(LTRIM(s.nd,'0'),'0')||'-'||NVL(LTRIM(s.kw,'0'),'0') as adr,
      p.fio, r.name as rel, p.dat_prop as dt1, p.dat_ub as dt2
      from arch_kart s, a_kart_pr p, spul l, relations r
      where s.mg=mg_ and s.lsk=p.lsk and s.kul=l.id and s.mg=p.mg and p.relat_id=r.id(+)
      and s.reu=reu_ and s.kul=kul_ and s.nd=nd_
      and decode(prop_,0,p.dat_prop, p.dat_ub) between dat2_ and dat3_
      and s.psch<>8
      order by l.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
    elsif var_ = 2 then
    --по РЭУ
    open prep_refcursor for
      select
      l.name||', '||NVL(LTRIM(s.nd,'0'),'0')||'-'||NVL(LTRIM(s.kw,'0'),'0') as adr,
      p.fio, r.name as rel, p.dat_prop as dt1, p.dat_ub as dt2
      from arch_kart s, a_kart_pr p, spul l, relations r
      where s.mg=mg_ and s.lsk=p.lsk and s.kul=l.id and s.mg=p.mg and p.relat_id=r.id(+)
      and s.reu=reu_ and decode(prop_,0,p.dat_prop, p.dat_ub) between dat2_ and dat3_
      and s.psch<>8
      order by l.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
    elsif var_ = 1 then
    --по ЖЭО
    open prep_refcursor for
      select
      l.name||', '||NVL(LTRIM(s.nd,'0'),'0')||'-'||NVL(LTRIM(s.kw,'0'),'0') as adr,
      p.fio, r.name as rel, p.dat_prop as dt1, p.dat_ub as dt2
      from arch_kart s, a_kart_pr p, spul l, relations r, s_reu_trest t
      where s.mg=mg_ and s.lsk=p.lsk and s.kul=l.id and s.mg=p.mg and p.relat_id=r.id(+)
      and s.reu=t.reu and t.trest=trest_ and decode(prop_,0,p.dat_prop, p.dat_ub) between dat2_ and dat3_
      and s.psch<>8
      order by l.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
    elsif var_ = 0 then
    --по Городу
    open prep_refcursor for
      select
      l.name||', '||NVL(LTRIM(s.nd,'0'),'0')||'-'||NVL(LTRIM(s.kw,'0'),'0') as adr,
      p.fio, r.name as rel, p.dat_prop as dt1, p.dat_ub as dt2
      from arch_kart s, a_kart_pr p, spul l, relations r
      where s.mg=mg_ and s.lsk=p.lsk and s.kul=l.id and s.mg=p.mg and p.relat_id=r.id(+)
      and decode(prop_,0,p.dat_prop, p.dat_ub) between dat2_ and dat3_
      and s.psch<>8
      order by l.name, utils.f_order(s.nd,6), utils.f_order(s.kw,7);
    end if;
 elsif сd_ in  ('75') then
  --Долги для УК, ТСЖ (для кабельного)
  --Выполнять после итогового формирования (чтоб вошла вся текущая оплата)
  --Вычисляем следующий месяц
    mg2_ := to_char(add_months(to_date(mg_ || '01', 'YYYYMMDD'), 1),
                   'YYYYMM');
--для ТСЖ
    open prep_refcursor for
      select k.lsk,
       l.cd_kladr, l.name, k.nd, k.kw,
       s.nm as type_name,
       mg_ as period, nvl(sum(s.summa),0)*100 as summa
       from scott.kart k ,
        (select t.*, u.nm from scott.saldo_usl t, scott.usl u where
         t.mg=mg2_ and t.usl=u.usl and u.cd in ('каб.тел.', 'антен.д.нач.','антен.нач.')) s
        , scott.spul l
        where k.psch not in (8,9) and k.lsk=s.lsk and k.kul=l.id
        group by k.lsk, substr(trim(k.fio),1,25), s.nm,
        l.name, l.cd_kladr, k.nd, k.kw
     union all
      select k.lsk,
       l.cd_kladr, l.name, k.nd, k.kw,
       u.nm as type_name,
       mg_ as period, 0 as summa
       from kart k, nabor n, spul l, usl u --лицевые по которым нет сальдо
        where k.psch not in (8,9) and k.lsk=n.lsk and k.kul=l.id
        and nvl(decode(u.sptarn, 0, nvl(n.koeff,0), 1, nvl(n.norm,0), 2,
               nvl(n.koeff,0) * nvl(n.norm,0), 3, nvl(n.koeff,0) * nvl(n.norm,0), 
               4, nvl(n.koeff,0) * nvl(n.norm,0)
               ), 0) <> 0
        and n.usl=u.usl and u.cd in ('каб.тел.', 'антен.д.нач.','антен.нач.')
        and not exists
        (select t.*, u.nm from saldo_usl t, usl u where
         t.mg=mg2_ and t.usl=u.usl and u.cd in ('каб.тел.', 'антен.д.нач.','антен.нач.')
         and t.lsk=k.lsk
         )
        group by k.lsk, substr(trim(k.fio),1,25), u.nm,
        l.name, l.cd_kladr, k.nd, k.kw;
 elsif сd_ in  ('77') then
  --Долги для прочих банков (от ТСЖ)
  --Выполнять после итогового формирования (чтоб вошла вся текущая оплата)
  --Вычисляем следующий месяц
    mg2_ := to_char(add_months(to_date(mg_ || '01', 'YYYYMMDD'), 1),
                   'YYYYMM');
    if var_ = 3 then
    --по Дому
    open prep_refcursor for
     select k.fio||';'||t.name||','||l.name||','||ltrim(k.nd,'0')||','||ltrim(k.kw,'0')||';'||k.lsk||';'||to_char(sum(s.summa),'999990.99') as txt,
           sum(s.summa) as srv_sum --служебное поле, для подсчёта итоговой суммы по файлу
           from kart k, saldo_usl s, usl u, spul l, t_org t, t_org_tp tp
            where k.lsk=s.lsk(+) and k.kul=l.id and s.mg=mg2_
            and s.usl=u.usl and t.fk_orgtp=tp.id and tp.cd='Город'
            and k.reu=reu_ and k.kul=kul_ and k.nd=nd_
            group by k.fio, t.name, l.name, k.nd, k.kw, k.lsk
            order by l.name, k.nd, k.kw;
    elsif var_ = 2 then
    --по УК
    open prep_refcursor for
     select k.fio||';'||t.name||','||l.name||','||ltrim(k.nd,'0')||','||ltrim(k.kw,'0')||';'||k.lsk||';'||to_char(sum(s.summa),'999990.99') as txt,
           sum(s.summa) as srv_sum --служебное поле, для подсчёта итоговой суммы по файлу
           from kart k, saldo_usl s, usl u, spul l, t_org t, t_org_tp tp
            where k.lsk=s.lsk(+) and k.kul=l.id and s.mg=mg2_
            and s.usl=u.usl and t.fk_orgtp=tp.id and tp.cd='Город'
            and k.reu=reu_
            group by k.fio, t.name, l.name, k.nd, k.kw, k.lsk
            order by l.name, k.nd, k.kw;
    elsif var_ = 1 then
    --по Фонду
    open prep_refcursor for
     select k.fio||';'||t.name||','||l.name||','||ltrim(k.nd,'0')||','||ltrim(k.kw,'0')||';'||k.lsk||';'||to_char(sum(s.summa),'999990.99') as txt,
           sum(s.summa) as srv_sum --служебное поле, для подсчёта итоговой суммы по файлу
           from kart k, saldo_usl s, usl u, spul l, t_org t, t_org_tp tp
            where k.lsk=s.lsk(+) and k.kul=l.id and s.mg=mg2_
            and s.usl=u.usl and t.fk_orgtp=tp.id and tp.cd='Город'
            and exists (select * from s_reu_trest r where r.reu=k.reu and r.trest=trest_)
            group by k.fio, t.name, l.name, k.nd, k.kw, k.lsk
            order by l.name, k.nd, k.kw;
    elsif var_ = 0 then
    --по Городу
    open prep_refcursor for
     select k.fio||';'||t.name||','||l.name||','||ltrim(k.nd,'0')||','||ltrim(k.kw,'0')||';'||k.lsk||';'||to_char(sum(s.summa),'999990.99') as txt,
           sum(s.summa) as srv_sum --служебное поле, для подсчёта итоговой суммы по файлу
           from kart k, saldo_usl s, usl u, spul l, t_org t, t_org_tp tp
            where k.lsk=s.lsk(+) and k.kul=l.id and s.mg=mg2_
            and s.usl=u.usl and t.fk_orgtp=tp.id and tp.cd='Город'
            group by k.fio, t.name, l.name, k.nd, k.kw, k.lsk
            order by l.name, k.nd, k.kw;
    end if;
 elsif сd_ in  ('78') then
 --форма для контроля тарифов
--det_ - вариант (0-только по основным лс., 1 - только по дополнит лс.)
 l_sel:=utils.getScd_list_param('REP_TP_SCH_SEL');
--Raise_application_error(-20000, show_fond_);
 if l_cur_period=mg_ then
 --текущий период
    if var_ = 3 then
    --по Дому
    open prep_refcursor for
     select distinct null as btn, k.house_id, u.usl, u.npp, u.nm, t.org, g.id, g.id||' '||g.name as name, m.id||' '||m.name as name2,
       t.koeff, t.norm, u.sptarn
       from kart k, nabor t, usl u, t_org g, t_org m, v_lsk_tp tp
        where k.lsk=t.lsk and t.usl=u.usl
        and t.org=g.id and g.fk_org2=m.id
        and k.house_id=p_house
        and k.fk_tp=tp.id
        and tp.cd=l_sel
        and k.reu = reu_
        and k.psch not in (8,9)
       order by u.npp, g.id, t.koeff, t.norm;
    elsif var_ = 2 then
    --по УК
    open prep_refcursor for
     select distinct null as btn, null as house_id, u.usl, u.npp, u.nm, t.org, g.id, g.id||' '||g.name as name, m.id||' '||m.name as name2,
       t.koeff, t.norm, u.sptarn
       from kart k, nabor t, usl u, t_org g, t_org m, v_lsk_tp tp
        where k.lsk=t.lsk and t.usl=u.usl
        and t.org=g.id and g.fk_org2=m.id
        and k.reu = reu_
        and k.fk_tp=tp.id
        and tp.cd=l_sel
        and k.psch not in (8,9)
       order by u.npp, g.id, t.koeff, t.norm;
    elsif var_ = 1 then
    --по Фонду
    open prep_refcursor for
     select distinct null as btn, null as house_id, u.usl, u.npp, u.nm, t.org, g.id, g.id||' '||g.name as name, m.id||' '||m.name as name2,
       t.koeff, t.norm, u.sptarn
       from kart k, nabor t, usl u, t_org g, t_org m, v_lsk_tp tp
        where k.lsk=t.lsk and t.usl=u.usl
        and t.org=g.id and g.fk_org2=m.id
        and k.fk_tp=tp.id
        and exists (select * from s_reu_trest r where r.reu=k.reu and r.trest=trest_)
        and tp.cd=l_sel
        and k.psch not in (8,9)
       order by u.npp, g.id, t.koeff, t.norm;
    elsif var_ = 0 then
    --по Городу
    open prep_refcursor for
     select distinct null as btn, null as house_id, u.usl, u.npp, u.nm, t.org, g.id, g.id||' '||g.name as name, m.id||' '||m.name as name2,
       t.koeff, t.norm, u.sptarn
       from kart k, nabor t, usl u, t_org g, t_org m, v_lsk_tp tp
        where k.lsk=t.lsk and t.usl=u.usl
        and t.org=g.id and g.fk_org2=m.id
        and k.fk_tp=tp.id
        and tp.cd=l_sel
        and k.psch not in (8,9)
       order by u.npp, g.id, t.koeff, t.norm;
    end if;
   else
   --прошлый период
    if var_ = 3 then
    --по Дому
    open prep_refcursor for
     select distinct null as btn, k.house_id, u.usl, u.npp, u.nm, t.org, g.id, g.id||' '||g.name as name, m.id||' '||m.name as name2,
       t.koeff, t.norm, u.sptarn
       from arch_kart k, a_nabor2 t, usl u, t_org g, t_org m, v_lsk_tp tp
        where k.lsk=t.lsk and t.usl=u.usl
        and t.org=g.id and g.fk_org2=m.id
        and k.house_id=p_house
        and k.mg=mg_ and k.mg between t.mgFrom and t.mgTo
        and k.fk_tp=tp.id
        and tp.cd=l_sel
        and k.psch not in (8,9)
       order by u.npp, g.id, t.koeff, t.norm;
    elsif var_ = 2 then
    --по УК
    open prep_refcursor for
     select distinct null as btn, null as house_id, u.usl, u.npp, u.nm, t.org, g.id, g.id||' '||g.name as name, m.id||' '||m.name as name2,
       t.koeff, t.norm, u.sptarn
       from arch_kart k, a_nabor2 t, usl u, t_org g, t_org m, v_lsk_tp tp
        where k.lsk=t.lsk and t.usl=u.usl
        and t.org=g.id and g.fk_org2=m.id
        and k.reu = reu_
        and k.mg=mg_ and k.mg between t.mgFrom and t.mgTo
        and k.fk_tp=tp.id
        and tp.cd=l_sel
        and k.psch not in (8,9)
       order by u.npp, g.id, t.koeff, t.norm;
    elsif var_ = 1 then
    --по Фонду
    open prep_refcursor for
     select distinct null as btn, null as house_id, u.usl, u.npp, u.nm, t.org, g.id, g.id||' '||g.name as name, m.id||' '||m.name as name2,
       t.koeff, t.norm, u.sptarn
       from arch_kart k, a_nabor2 t, usl u, t_org g, t_org m, v_lsk_tp tp
        where k.lsk=t.lsk and t.usl=u.usl
        and t.org=g.id and g.fk_org2=m.id
        and exists (select * from s_reu_trest r where r.reu=k.reu and r.trest=trest_)
        and k.mg=mg_ and k.mg between t.mgFrom and t.mgTo
        and k.fk_tp=tp.id
        and tp.cd=l_sel
        and k.psch not in (8,9)
       order by u.npp, g.id, t.koeff, t.norm;
    elsif var_ = 0 then
    --по Городу
    open prep_refcursor for
     select distinct null as btn, null as house_id, u.usl, u.npp, u.nm, t.org, g.id, g.id||' '||g.name as name, m.id||' '||m.name as name2,
       t.koeff, t.norm, u.sptarn
       from arch_kart k, a_nabor2 t, usl u, t_org g, t_org m, v_lsk_tp tp
        where k.lsk=t.lsk and t.usl=u.usl
        and t.org=g.id and g.fk_org2=m.id
        and k.mg=mg_ and k.mg between t.mgFrom and t.mgTo
        and k.fk_tp=tp.id
        and tp.cd=l_sel
        and k.psch not in (8,9)
       order by u.npp, g.id, t.koeff, t.norm;
    end if;
   end if;

 elsif сd_ in  ('79') then
 --отчет (для Полыс) по льготникам, для УСЗН
     if var_ = 3 then
        --По дому
        raise_application_error(-20001,'Не существует уровня детализации!');
      elsif var_ = 2 then
        --По РЭУ
        raise_application_error(-20001,'Не существует уровня детализации!');
      elsif var_ = 1 then
        --По ЖЭО
        raise_application_error(-20001,'Не существует уровня детализации!');
      elsif var_ = 0 then
        --(все тресты)
         open prep_refcursor for
          select k.lsk, k.mg, s.name||', '||NVL(LTRIM(k.nd,'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') as adr,
           k.opl, decode(k.status,1,'-','+') as status,
           a.summa1,
           a.summa2,
           a.summa3,
           a.summa4,
           a.summa5,
           a.summa6,
           a.summa7,
           a.summa8,
           a.norm1, a.norm2, a.norm3, a.tp1, 
           a.limit1, a.limit2, a.limit3
           from arch_kart k, spul s,
           (select k.k_lsk_id,
               max(decode(t.usl,'003',t.test_cena,'004',t.test_cena,0)) as summa1, --тек.содержание
               max(decode(t.usl,'005',t.test_cena,0))+
               max(decode(t.usl,'006',t.test_cena,0))+
               max(decode(t.usl,'009',t.test_cena,0))+
               max(decode(t.usl,'010',t.test_cena,0)) as summa2, --лифт
               max(decode(t.usl,'031',t.test_cena,'046',t.summa,0)) as summa3,  --тбо
               max(decode(t.usl,'052',t.test_cena,0)) as summa4,  --ассенизация
               max(decode(t.usl,'054',t.test_cena,0)) as summa5,  --утилизация
               max(decode(t.usl,'033',t.test_cena,'034',test_cena,0)) as summa6, --расценка кап.рем.
               max(decode(t.usl,'026',test_cena,0)) as summa7, --расценка найм.
               max(decode(t.usl,'055',t.test_cena,0)) as summa8, --текущий ремонт
               max(decode(n.usl,'011',n.norm,0)) as norm1,  --норматив хвс
               max(decode(n.usl,'015',n.norm,0)) as norm2,  --норматив гвс
               max(decode(n.usl,'013',n.norm,0)) as norm3,  --норматив водоотвед
               case when nvl(max(decode(t.usl,'007',t.summa,'008',t.summa,0)),0) <> 0 then '+'
                 else '-' end as tp1, --признак наличия отопления
               max(decode(n.usl,'011',d.nrm,0)) as limit1,  --ограничение ОДН хвс
               max(decode(n.usl,'015',d.nrm,0)) as limit2,  --ограничение ОДН гвс
               max(decode(n.usl,'053',d.nrm,0)) as limit3  --ограничение ОДН Эл.эн.
               from a_nabor2 n 
                              join arch_kart k on n.lsk=k.lsk and k.mg=mg_ and k.psch not in (8,9)
                              left join a_charge2 t on n.usl=t.usl and n.lsk=t.lsk and t.type=1
                                   and mg_ between t.mgFrom and t.mgTo
                              left join scott.a_vvod d on d.mg=mg_ and n.fk_vvod=d.id
               where mg_ between n.mgFrom and n.mgTo
             group by k.k_lsk_id) a
           where k.kul=s.id and k.k_lsk_id=a.k_lsk_id(+)
           and k.mg=mg_ and k.psch not in (8,9)
           order by s.name, utils.f_order(k.nd,6), utils.f_order2(k.nd), utils.f_order(k.kw,7), k.lsk;
      end if;
 elsif сd_ = '80' then
 --Задолжники OLAP-2 - версия для тех, кто использует c_deb_usl (полыс.)

--   cur_pay_:=utils.getS_bool_param('REP_CUR_PAY');
   if dat_ is not null then
    Raise_application_error(-20000, 'Текущая дата не используется!');
   end if;

   kpr1_:=utils.getS_int_param('REP_RNG_KPR1');
   kpr2_:=utils.getS_int_param('REP_RNG_KPR2');
   n1_:=utils.getS_list_param('REP_DEB_VAR');
   if n1_=0 then
     n2_:=utils.getS_int_param('REP_DEB_MONTH');
     else
     n2_:=utils.getS_int_param('REP_DEB_SUMMA');
   end if;

   if var_ = 3 then
    --По дому
    Raise_application_error(-20000, 'не используется уровень!');
 elsif var_ = 2 then
    --По ЖЭО
    Raise_application_error(-20000, 'не используется уровень!');
 elsif var_ = 1 then
    --По фонду
    Raise_application_error(-20000, 'не используется уровень!');
   elsif var_ = 0 then
   --По городу
   open prep_refcursor for
   select null as lsk, -- 21.02.2018 договорились с Полыс. что будет выводиться только по адресу
       s.org,
       o.name as name_org,
       u.nm,
       u.nm1,
       /*decode(k.psch,
              9,
              'Закрытые Л/С',
              8,
              'Старый фонд',
              'Открытые Л/С')*/
              'Открытые Л/С' as psch,
       r.name_tr,
       r.name_reu,
       l.name as street,
       ltrim(k.nd, '0') as nd,
       ltrim(k.kw, '0') as kw,
       k.nd, k.kw,
       decode(det_, 3, trim(l.name) || ', ' || ltrim(k.nd, '0') || '-' || ltrim(k.kw, '0'),
               trim(l.name) || ', ' || ltrim(k.nd, '0')) --показать информацию по квартирам или по домам
       as adr,
       k.fio,
       sum(s.summa) as dolg,
       t.cnt_month as cnt,
       substr(s.mg,1,4)||'.'||substr(s.mg,5,2) as mg
         from kart k join
          (select k2.k_lsk_id, t.usl, t.org, t.mg, sum(t.summa) as summa 
             from kart k2 join c_deb_usl t on k2.lsk=t.lsk
             where t.period = mg_
               and t.mg<=l_prev_period -- не считать начисление текущего периода
             group by k2.k_lsk_id, t.usl, t.org, t.mg
             ) s 
               on k.k_lsk_id = s.k_lsk_id and s.summa > 0 
          join    
          (select k2.k_lsk_id, sum(t.cnt_month) as cnt_month
              from kart k2 join debits_lsk_month t on k2.lsk=t.lsk 
              where t.mg = mg_
              group by k2.k_lsk_id
              having 
              ((n1_=0 and sum(t.cnt_month) >= n2_) or
               (n1_=1 and sum(t.dolg) >= n2_))
              ) t on k.k_lsk_id = t.k_lsk_id
       join t_org o on s.org = o.id
       join spul l on k.kul = l.id 
       join s_reu_trest r on k.reu = r.reu
       join usl u on s.usl=u.usl 
       join v_lsk_tp tp on k.fk_tp = tp.id and tp.cd='LSK_TP_MAIN'
 where 
   (kpr1_ is not null and k.kpr >=kpr1_ or kpr1_ is null)
   and (kpr2_ is not null and k.kpr <=kpr2_ or kpr2_ is null)
   and k.psch not in (8)
 group by 
          s.org,
          u.nm,
          u.nm1,
          o.name,
          decode(k.psch,
                 9,
                 'Закрытые Л/С',
                 8,
                 'Старый фонд',
                 'Открытые Л/С'),
          r.name_tr,
          r.name_reu,
          l.name,
          ltrim(k.nd, '0'),
          ltrim(k.kw, '0'),
          k.nd, k.kw,
          trim(l.name) || ', ' || ltrim(k.nd, '0') || '-' ||
          ltrim(k.kw, '0'),
          k.fio,
          t.cnt_month,
          substr(s.mg,1,4)||'.'||substr(s.mg,5,2)
 order by trim(l.name), utils.f_order(k.nd, 6), utils.f_order(k.kw, 7);
--    using det_, l_prev_period, n1_, n2_, n1_, n2_, kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_;
    
/*open prep_refcursor for
   select s.lsk,
       s.org,
       o.name as name_org,
       u.nm,
       u.nm1,
       decode(k.psch,
              9,
              'Закрытые Л/С',
              8,
              'Старый фонд',
              'Открытые Л/С') as psch,
       r.name_tr,
       r.name_reu,
       l.name as street,
       ltrim(k.nd, '0') as nd,
       ltrim(k.kw, '0') as kw,
       k.nd, k.kw,
       decode(det_, 3, trim(l.name) || ', ' || ltrim(k.nd, '0') || '-' || ltrim(k.kw, '0'),
               trim(l.name) || ', ' || ltrim(k.nd, '0')) --показать информацию по квартирам или по домам
       as adr,
       k.fio,
       sum(s.summa) as dolg,
       t.cnt_month as cnt,
       substr(s.mg,1,4)||'.'||substr(s.mg,5,2) as mg
         from kart k, c_deb_usl s, (select d.lsk, max(d.cnt_month) as cnt_month
          from debits_lsk_month d where (l_period_tp<>3 and d.dat between dat_ and dat1_
                                              or l_period_tp=3 and d.mg between mg_ and mg1_)
                                           group by d.lsk) t, t_org o, spul l, s_reu_trest r, usl u
 where --s.summa > 0
   --and 
   s.usl=u.usl and --s.mg<=l_prev_period
   (n1_ <> 0 or n1_=0 and abs(months_between(
                  to_date(s.period||'01','YYYYMMDD'),
                  to_date(s.mg||'01','YYYYMMDD')
                  )) >= n2_)
   and exists (select *
          from debits_lsk_month d
         where d.k_lsk_id=k.k_lsk_id and (l_period_tp<>3 and d.dat between dat_ and dat1_
                                              or l_period_tp=3 and d.mg between mg_ and mg1_)
            and ((n1_=0 and d.cnt_month >= n2_) or
            (n1_=1 and d.dolg >= n2_))
           )
   and (kpr1_ is not null and k.kpr >=kpr1_ or kpr1_ is null)
   and (kpr2_ is not null and k.kpr <=kpr2_ or kpr2_ is null)
   and s.org = o.id
   and k.lsk = s.lsk
   and k.lsk = t.lsk
   and k.kul = l.id
   and k.reu = r.reu and (l_period_tp<>3 and s.period between to_char(dat_,'YYYYMM') and to_char(dat1_,'YYYYMM')
                                              or l_period_tp=3 and s.period between mg_ and mg1_)
 group by s.lsk,
          s.org,
          u.nm,
          u.nm1,
          o.name,
          decode(k.psch,
                 9,
                 'Закрытые Л/С',
                 8,
                 'Старый фонд',
                 'Открытые Л/С'),
          r.name_tr,
          r.name_reu,
          l.name,
          ltrim(k.nd, '0'),
          ltrim(k.kw, '0'),
          k.nd, k.kw,
          trim(l.name) || ', ' || ltrim(k.nd, '0') || '-' ||
          ltrim(k.kw, '0'),
          k.fio,
          t.cnt_month,
          substr(s.mg,1,4)||'.'||substr(s.mg,5,2)
 order by trim(l.name), utils.f_order(k.nd, 6), utils.f_order(k.kw, 7);
--    using det_, l_prev_period, n1_, n2_, n1_, n2_, kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_;
*/    end if;

 elsif сd_ = '81' then
 --Отчет для Э+ (для Дениса)
   l_sql:='select * from (select k.lsk, k.lsk_ext as lsk2, sp.name, ltrim(k.nd, ''0'') as nd,
      ltrim(k.kw, ''0'') as kw, t.cdtp, p.cena, -1*nvl(s.summa,0) as summa from kart k,
      nabor n, spr_tarif t, spr_tarif_prices p, spul sp,
      (select s.lsk, sum(summa) as summa from saldo_usl s where s.usl=''042''
       and s.mg='||l_mg_next||'
       group by s.lsk) s,
      (select t.lsk, sum(t.summa) as summa from c_charge t where t.usl=''042''
       and t.type=1
       group by t.lsk) a
       where k.lsk=n.lsk and k.lsk=s.lsk(+)and k.lsk=a.lsk(+) and t.cdtp=''ИНТ''
      and t.id=p.fk_tarif and '||mg_||'
      between p.mg1 and p.mg2
      and n.fk_tarif=t.id
      and sp.id=k.kul
      and nvl(n.norm,0) <> 0
      and nvl(n.koeff,0) <> 0
      union all
      select k.lsk, k.lsk_ext as lsk2, sp.name, ltrim(k.nd, ''0'') as nd,
      ltrim(k.kw, ''0'') as kw, t.cdtp, p.cena, -1*nvl(s.summa,0) as summa from kart k,
      nabor_progs n, spr_tarif t, spr_tarif_prices p, spul sp,
      (select s.lsk, sum(summa) as summa from saldo_usl s where s.usl=''056''
       and s.mg='||l_mg_next||'
       group by s.lsk) s
       where k.lsk=n.lsk and k.lsk=s.lsk(+)
      and t.id=p.fk_tarif and '||mg_||'
      between p.mg1 and p.mg2
      and t.usl=''056''
      and n.fk_tarif=t.id
      and sp.id=k.kul
--      and k.lsk=''00107244''
      ) d
      order by d.name, utils.f_order(d.nd,6), utils.f_order(d.kw,6)
      ';

   if nvl(p_out_tp,0) =1 then
   if utils.set_base_state_gen(1) = 0 then
     --если выполнили БЛОКИРОВКУ формирования,
     --в противном случае выгрузить пустой отчет
     --установить состояние базы - не выполнено итоговое формирование
     init.set_state(0);
     --выполнить формирование сальдо
     gen.gen_saldo(null);
     --выгрузить в файл,в директорию по умолчанию
     SQLTofile(l_sql, 'LOAD_FILE_DIR', 'OUT'||to_char(trunc(sysdate),'YYYYMMDD')||'.txt',
       'OUT'||to_char(trunc(sysdate),'YYYYMMDD')||'.txt', ';');
     --снимаем БЛОКИРОВКУ
     l_cnt:=utils.set_base_state_gen(0);
   else
     --пустой отчет
     SQLTofile('select null as lsk from dual', 'LOAD_FILE_DIR', 'OUT'||to_char(trunc(sysdate),'YYYYMMDD')||'.txt',
       'OUT'||to_char(trunc(sysdate),'YYYYMMDD')||'.txt', ';');
   end if;

   else
   --отправить как реф-курсор
     open prep_refcursor for l_sql/*
       using l_mg_next, mg_, mg_, mg_*/;
    end if;

 elsif сd_ in  ('82') then
  --Задолжники FR, в зависимости от организатора задолжника - для Полыс.
  --переделал, что можно вывести по нескольким орг.
   kpr1_:=utils.getS_int_param('REP_RNG_KPR1');
   kpr2_:=utils.getS_int_param('REP_RNG_KPR2');

   n1_:=utils.getS_list_param('REP_DEB_VAR');
   if n1_=0 then
     n2_:=utils.getS_int_param('REP_DEB_MONTH');
     else
     n2_:=utils.getS_int_param('REP_DEB_SUMMA');
   end if;

    if var_ = 3 then
    --по Дому
    open prep_refcursor for
    'select o.name as name_deb_org, s.lsk, t.name_reu, trim(s.name) as street_name,
      ltrim(s.nd,''0'') as nd, ltrim(s.kw,''0'') as kw, pr.fio, s.cnt_month, s.dolg, s.penya,
      case when s.dat is null and s.mg is not null then to_date(s.mg||''01'',''YYYYMMDD'')
           else s.dat
           end as dat
      from debits_lsk_month s, s_reu_trest t, t_org o, c_kart_pr pr
      where s.reu=t.reu and s.var=0
      and ' || sqlstr_ || '
      and s.reu=:reu_ AND s.kul=:kul_ AND s.nd=:nd_
      and exists
      (select * from kart k where k.lsk=s.lsk
      and (:kpr1_ is not null and k.kpr >=:kpr1_ or :kpr1_ is null)
      and (:kpr2_ is not null and k.kpr <=:kpr2_ or :kpr2_ is null))
      and
      ((:n1_=0 and s.cnt_month >= :n2_) or
      (:n1_=1 and s.dolg >= :n2_))
      and exists
      (select * from c_kart_pr r, list_c i, spr_params p where i.fk_ses=:fk_ses_
            and p.id=i.fk_par and p.cd=''REP_ORG''
            and r.fk_deb_org=i.sel_id
            and s.lsk=r.lsk
            and i.sel_id=o.id
            and r.id=pr.id
            and r.status<>4
            and i.sel=1)
      order by o.name, t.name_reu, s.name, s.nd, s.kw'
      using reu_, kul_, nd_,
    kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_, fk_ses_;

    elsif var_ = 2 then
    --по РЭУ
    open prep_refcursor for
    'select o.name as name_deb_org, s.lsk, t.name_reu, trim(s.name) as street_name,
      ltrim(s.nd,''0'') as nd, ltrim(s.kw,''0'') as kw, pr.fio, s.cnt_month, s.dolg, s.penya,
      case when s.dat is null and s.mg is not null then to_date(s.mg||''01'',''YYYYMMDD'')
           else s.dat
           end as dat
      from debits_lsk_month s, s_reu_trest t, t_org o, c_kart_pr pr
      where s.reu=t.reu and s.var=0
      and ' || sqlstr_ || '
      and s.reu=:reu_
      and exists
      (select * from kart k where k.lsk=s.lsk
      and (:kpr1_ is not null and k.kpr >=:kpr1_ or :kpr1_ is null)
      and (:kpr2_ is not null and k.kpr <=:kpr2_ or :kpr2_ is null))
      and
      ((:n1_=0 and s.cnt_month >= :n2_) or
      (:n1_=1 and s.dolg >= :n2_))
      and exists
      (select * from c_kart_pr r, list_c i, spr_params p where i.fk_ses=:fk_ses_
            and p.id=i.fk_par and p.cd=''REP_ORG''
            and r.fk_deb_org=i.sel_id
            and s.lsk=r.lsk
            and i.sel_id=o.id
            and r.id=pr.id
            and r.status<>4
            and i.sel=1)
      order by o.name, t.name_reu, s.name, s.nd, s.kw'
      using reu_,
    kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_, fk_ses_;

    elsif var_ = 1 then
    --по ЖЭО
    open prep_refcursor for
    'select o.name as name_deb_org, s.lsk, t.name_reu, trim(s.name) as street_name,
      ltrim(s.nd,''0'') as nd, ltrim(s.kw,''0'') as kw, pr.fio, s.cnt_month, s.dolg, s.penya,
      case when s.dat is null and s.mg is not null then to_date(s.mg||''01'',''YYYYMMDD'')
           else s.dat and s.var=0
           end as dat
      from debits_lsk_month s, s_reu_trest t, t_org o, c_kart_pr pr
      where s.reu=t.reu
      and ' || sqlstr_ || '
      and s.reu=:trest_
      and exists
      (select * from kart k where k.lsk=s.lsk
      and (:kpr1_ is not null and k.kpr >=:kpr1_ or :kpr1_ is null)
      and (:kpr2_ is not null and k.kpr <=:kpr2_ or :kpr2_ is null))
      and
      ((:n1_=0 and s.cnt_month >= :n2_) or
      (:n1_=1 and s.dolg >= :n2_))
      and exists
      (select * from c_kart_pr r, list_c i, spr_params p where i.fk_ses=:fk_ses_
            and p.id=i.fk_par and p.cd=''REP_ORG''
            and r.fk_deb_org=i.sel_id
            and s.lsk=r.lsk
            and i.sel_id=o.id
            and r.id=pr.id
            and r.status<>4
            and i.sel=1)
      order by o.name, t.name_reu, s.name, s.nd, s.kw'
      using trest_,
    kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_, fk_ses_;

    elsif var_ = 0 then
    --по Городу
    open prep_refcursor for
    'select o.name as name_deb_org, s.lsk, t.name_reu, trim(s.name) as street_name,
      ltrim(s.nd,''0'') as nd, ltrim(s.kw,''0'') as kw, pr.fio, s.cnt_month, s.dolg, s.penya,
      case when s.dat is null and s.mg is not null then to_date(s.mg||''01'',''YYYYMMDD'')
           else s.dat
           end as dat
      from debits_lsk_month s, s_reu_trest t, t_org o, c_kart_pr pr
      where s.reu=t.reu and s.var=0
      and ' || sqlstr_ || '
      and exists
      (select * from kart k where k.lsk=s.lsk
      and (:kpr1_ is not null and k.kpr >=:kpr1_ or :kpr1_ is null)
      and (:kpr2_ is not null and k.kpr <=:kpr2_ or :kpr2_ is null))
      and
      ((:n1_=0 and s.cnt_month >= :n2_) or
      (:n1_=1 and s.dolg >= :n2_))
      and exists
      (select * from c_kart_pr r, list_c i, spr_params p where i.fk_ses=:fk_ses_
            and p.id=i.fk_par and p.cd=''REP_ORG''
            and r.fk_deb_org=i.sel_id
            and s.lsk=r.lsk
            and i.sel_id=o.id
            and r.id=pr.id
            and r.status<>4
            and i.sel=1)
      order by o.name, t.name_reu, s.name, s.nd, s.kw'
      using kpr1_, kpr1_, kpr1_, kpr2_, kpr2_, kpr2_, n1_, n2_, n1_, n2_, fk_ses_;
   end if;
 elsif сd_ in  ('83') then
    --отчёт для администрации по тарифам, объемам, нормативам и прочее...
    --имеет дочерний датасет в rep_detail
    if var_ = 3 then
    --по Дому
     open prep_refcursor for
       'select s.lsk, st.name as name_st, s.kpr,
         sp.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'')||''-''||NVL(LTRIM(s.kw,''0''),''0'') as adr,
         s.mg
        from arch_kart s, spul sp, status st where s.mg=:p_mg
        and not exists (select * from a_nabor n, usl u where n.lsk=s.lsk and n.usl=u.usl and u.cd=''гараж'') --не гаражи
        and s.reu=:reu_ and s.kul=:kul_ and s.nd=:nd_
        and s.kul=sp.id
        and s.status=st.id
        order by s.lsk  --order by sp.name, f_ord_digit(s.nd), f_ord3(s.nd), f_ord_digit(s.kw)'
        using mg_, reu_, kul_, nd_;
    elsif var_ = 2 then
    --по РЭУ
     open prep_refcursor for
       'select s.lsk, st.name as name_st, s.kpr,
         sp.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'')||''-''||NVL(LTRIM(s.kw,''0''),''0'') as adr,
         s.mg
        from arch_kart s, spul sp, status st where s.mg=:p_mg
        and not exists (select * from a_nabor n, usl u where n.lsk=s.lsk and n.usl=u.usl and u.cd=''гараж'' and n.koeff<>0) --не гаражи
        and s.reu=:reu_
        and s.kul=sp.id
        and s.status=st.id
        order by s.lsk  -- order by sp.name, utils.f_ord_digit(s.nd), utils.f_ord3(s.nd), utils.f_ord_digit(s.kw)'
        using mg_, reu_;
    elsif var_ = 1 then
    --по ЖЭО
     open prep_refcursor for
       'select s.lsk, st.name as name_st, s.kpr,
         sp.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'')||''-''||NVL(LTRIM(s.kw,''0''),''0'') as adr,
         s.mg
        from arch_kart s, spul sp, status st, s_reu_trest t where s.mg=:p_mg
        and not exists (select * from a_nabor n, usl u where n.lsk=s.lsk and n.usl=u.usl and u.cd=''гараж'' and n.koeff<>0) --не гаражи
        and s.reu=t.reu
        and t.trest=:trest_
        and s.kul=sp.id
        and s.status=st.id
        order by s.lsk --order by sp.name, utils.f_ord_digit(s.nd), utils.f_ord3(s.nd), utils.f_ord_digit(s.kw)'
        using mg_, trest_;
    elsif var_ = 0 then
    --по Городу
     open prep_refcursor for
       'select s.lsk, st.name as name_st, s.kpr,
         sp.name||'', ''||NVL(LTRIM(s.nd,''0''),''0'')||''-''||NVL(LTRIM(s.kw,''0''),''0'') as adr,
         s.mg
        from arch_kart s, spul sp, status st where s.mg=:p_mg
        and not exists (select * from a_nabor n, usl u where n.lsk=s.lsk and n.usl=u.usl and u.cd=''гараж'' and n.koeff<>0) --не гаражи
        and s.kul=sp.id
        and s.status=st.id
        order by s.lsk --order by sp.name, utils.f_ord_digit(s.nd), utils.f_ord3(s.nd), utils.f_ord_digit(s.kw)'
        using mg_;
   end if;

 elsif сd_ in  ('84') then
 --Новый список-оборотка для субсидирования ТСЖ
    if var_ = 2 then
    --по УК
    open prep_refcursor for
    select l.name||', '||NVL(LTRIM(s.nd,'0'),'0') as adr,
     ltrim(s.kw,'0') as kw,
     s.komn, s.opl, s.fio,
     e.opl_n, e.opl_sv, e.opl_empt,
     nvl(e.opl_n,0)+nvl(e.opl_sv,0)+nvl(e.opl_empt,0) as opl_itg,
     e.summa_n, e.summa_sv, e.summa_empt,
     nvl(e.summa_n,0)+nvl(e.summa_sv,0)+nvl(e.summa_empt,0)+nvl(d.chng,0) as summa_itg,

     nvl(gw.summa_sch_n,0)+ nvl(gw.summa_norm_n,0) as gw_summa_norm,
     gw.summa_sch_sv as gw_summa_sch_sv,
     gw.summa_sch_empt as gw_summa_sch_empt,

     nvl(gw.summa_sch_n,0)+ nvl(gw.summa_norm_n,0)+
     nvl(gw.summa_sch_sv,0)+
     nvl(gw.summa_sch_empt,0)+nvl(gw2.summa,0) as gw_summa_itg,

     gw.vol_sch_n as gw_sch_n,
     gw.vol_sch_sv as gw_sch_sv,
     gw.vol_sch_empt as gw_sch_empt,

     gw.vol_norm_n as gw_vol_norm,
     gw2.vol_sch as odn_vol_sch,
     gw2.vol_norm as odn_vol_norm,

     nvl(gw.vol_sch_n,0)+
     nvl(gw.vol_sch_sv,0)+
     nvl(gw.vol_sch_empt,0)+
     nvl(gw2.vol_sch,0) as gw_vol_itg,

     gw2.summa as odn_summa,
     gw3.kpr_sch,
     gw3.kpr_norm,
     nvl(gw3.kpr_sch,0)+nvl(gw3.kpr_norm,0) as kpr_itg,
     d.chng,
     c.name, c.adr as org_adr, c.inn, c.kpp, c.head_name,
    upper(utils.MONTH_NAME(substr(s.mg,5,2)))||' '||substr(s.mg,1,4)||'г.' as mg_name,
    s.vvod_ot
    from (select s.* from arch_kart s, s_reu_trest e where s.mg between mg_ and mg1_
     and exists --ключевой запрос
      (select * from a_charge2 a, usl u where a.usl=u.usl and
        u.cd in ('отоп', 'отоп/св.нор', 'отоп/0 зарег.') and a.type = 1 and a.summa <> 0
        and a.lsk=s.lsk and s.mg between a.mgFrom and a.mgTo
      )
     and e.reu=reu_
     and s.reu=e.reu
     and s.psch not in (8,9)
     and s.status not in (7)--убрал нежилые по просьбе ТСЖ Клён, ред.09.01.13 В ЭТОМ ОТЧЕТЕ НЕТ НИКАКИХ MG1_ !!! только MG_!!!
     ) s, t_org c, params p, spul l,
    (select s.lsk, u.uslg,
     sum(case when u.usl_norm = 0 and s.kpr <> 0 then s.summa else 0 end) as summa_n,
     sum(case when u.usl_norm = 1 and s.kpr <> 0 then s.summa else 0 end) as summa_sv,
     sum(case when s.kpr = 0 then s.summa else 0 end) as summa_empt,
     sum(case when u.usl_norm = 0 and s.kpr <> 0 then s.test_opl else 0 end) as opl_n,
     sum(case when u.usl_norm = 1 and s.kpr <> 0 then s.test_opl else 0 end) as opl_sv,
     sum(case when s.kpr = 0 then s.test_opl else 0 end) as opl_empt
       from a_charge2 s, usl u where mg_ between s.mgFrom and s.mgTo and s.usl=u.usl and
      u.cd in ('отоп', 'отоп/св.нор', 'отоп/0 зарег.') and s.type=1 --отопление (начисление чистое, объёмы)
     group by s.lsk, u.uslg) e,
      (select s.lsk, u.uslg, sum(s.summa) as chng from a_change s, usl u where s.mg between mg_ and mg_ and s.usl=u.usl and
       u.cd in ('отоп', 'отоп/св.нор', 'отоп/0 зарег.') --перерасчёты по отоплению
       group by s.lsk, u.uslg) d,
    (select s.lsk,
     sum(case when s.sch <> 0 and u.usl_norm = 0 and nvl(s.kpr,0) <> 0 then s.summa else 0 end) as summa_sch_n,
     sum(case when s.sch <> 0 and u.usl_norm = 1 and nvl(s.kpr,0) <> 0 then s.summa else 0 end) as summa_sch_sv,
     sum(case when s.sch <> 0 and nvl(s.kpr,0) = 0 then s.summa else 0 end) as summa_sch_empt,
     sum(case when s.sch <> 0 and u.usl_norm = 0 and nvl(s.kpr,0) <> 0 then s.test_opl else 0 end) as vol_sch_n,
     sum(case when s.sch <> 0 and u.usl_norm = 1 and nvl(s.kpr,0) <> 0 then s.test_opl else 0 end) as vol_sch_sv,
     sum(case when s.sch <> 0 and nvl(s.kpr,0) = 0 then s.test_opl else 0 end) as vol_sch_empt,
     sum(case when s.sch = 0 and u.usl_norm = 0 then s.summa else 0 end) as summa_norm_n,

     sum(case when s.sch = 0 and u.usl_norm = 0 then s.test_opl else 0 end) as vol_norm_n
       from a_charge2 s, usl u where mg_ between s.mgFrom and s.mgTo and s.usl=u.usl and
      u.cd in ('г.вода', 'г.вода/св.нор', 'г.вода/0 зарег.') and s.type=1 --г.вода (начисление чистое, объёмы)
     group by s.lsk
     ) gw,
    (select s.lsk,
     sum(case when s.sch <> 0 then s.kpr else 0 end) as kpr_sch,
     sum(case when s.sch = 0 then s.kpr else 0 end) as kpr_norm
       from a_charge_prep2 s, usl u where  mg_ between s.mgFrom and s.mgTo and s.usl=u.usl and
      u.cd in ('г.вода') and s.tp=1 --г.вода (кол-во прожив по сч/нормативу)
     group by s.lsk
     ) gw3,
    (select s.lsk,
     sum(s.summa) as summa,
     sum(case when s.sch <> 0 and u.usl_norm = 0 /*and s.kpr <> 0 вот так странно. почему то исключались пустые квартиры (обсуждал с Ларисой 27.05.2016*/ 
      then s.test_opl else 0 end) as vol_sch,
     sum(case when s.sch = 0 and u.usl_norm = 0 then s.test_opl else 0 end) as vol_norm
       from a_charge2 s, usl u where mg_ between s.mgFrom and s.mgTo and s.usl=u.usl and
      u.cd in ('г.вода.ОДН') and s.type=1 --г.вода ОДН (начисление чистое, объёмы)
     group by s.lsk
     ) gw2
    where s.lsk = e.lsk(+)
     and s.kul=l.id
     and s.lsk=gw.lsk(+)
     and s.lsk=gw2.lsk(+)
     and s.lsk=gw3.lsk(+)
     and s.lsk = d.lsk(+)
     and s.reu=c.reu
    order by l.name, s.nd, s.vvod_ot, s.kw;
    else
      Raise_application_error(-20000, 'Нет уровня детализации!');
    end if;
elsif сd_ in  ('85') then
 --Справка по начислению квартплаты по отоплению (для кис.)

    if var_ = 2 then
    --по УК
    open prep_refcursor for
    'select
     c.name as name_uk,
     nvl(r.name2, r2.name2) as name_org,
     nvl(r.name, r2.name) as name_kot,

     sum(nvl(e.opl,0)+nvl(e2.opl,0)) as opl_itg,

     sum(e.opl) as opl,
     sum(e.opl_empt) as opl_empt,

     sum(e2.opl) as opl_sch,
     sum(e2.opl_empt) as opl_empt_sch,
     sum(e2.vol) as vol_sch,
     sum(e2.vol_empt) as vol_empt_sch,

     sum(nvl(e.summa,0)+nvl(e2.summa,0)+nvl(d.summa,0)+nvl(d2.summa,0)) as summa_itg,
     sum(nvl(e.summa,0)+nvl(d.summa,0)) as summa,
     sum(e.summa_empt) as summa_empt,
     sum(d.summa) as chng,
     sum(nvl(e2.summa,0)+nvl(d2.summa,0)) as summa_sch,
     sum(e2.summa_empt) as summa_sch_empt,
     sum(d.summa) as chng_sch,
     c.head_name,
     upper(utils.MONTH_NAME(substr(s.mg,5,2)))||'' ''||substr(s.mg,1,4)||''г.'' as mg_name
    from (select s.* from arch_kart s, s_reu_trest e where '||sqlstr_||' and exists --ключевой запрос
      (select * from a_charge a, usl u where a.usl=u.usl and
        u.cd in (''отоп'', ''отоп/0 зарег.'') and a.type = 1 and a.summa <> 0
        and a.lsk=s.lsk and a.mg=s.mg
      )
     and e.reu=:reu
     and s.reu=e.reu
     and s.psch not in (8,9)
     and s.status not in (7)--убрал нежилые --
     ) s, t_org c, params p,
    (select s.lsk,
     sum(s.summa) as summa,
     sum(case when s.kpr = 0 then s.summa else 0 end) as summa_empt,
     sum(s.test_opl) as opl,
     sum(case when s.kpr = 0 then s.test_opl else 0 end) as opl_empt
       from a_charge s, usl u where '||sqlstr_||' and s.usl=u.usl and
      u.cd in (''отоп'', ''отоп/0 зарег.'') and s.type=1 --отопление (начисление чистое, объёмы)
     group by s.lsk) e,
    (select s.lsk,
     sum(s.summa) as summa,
     sum(case when s.kpr = 0 then s.summa else 0 end) as summa_empt,
     sum(s.opl) as opl,
     sum(case when s.kpr = 0 then s.opl else 0 end) as opl_empt,
     sum(s.test_opl) as vol,
     sum(case when s.kpr = 0 then s.test_opl else 0 end) as vol_empt
       from a_charge s, usl u where '||sqlstr_||' and s.usl=u.usl and
      u.cd in (''отоп.гкал.'', ''отоп.гкал./0 зарег.'') and s.type=1 --отопление гКал.(начисление чистое, объёмы)
     group by s.lsk) e2,
      (select s.lsk, sum(s.summa) as summa from a_change s, usl u where '||sqlstr_||' and s.usl=u.usl and
       u.cd in (''отоп'', ''отоп/0 зарег.'') --перерасчёты по отоплению
       group by s.lsk) d,
      (select s.lsk, sum(s.summa) as summa from a_change s, usl u where '||sqlstr_||' and s.usl=u.usl and
       u.cd in (''отоп.гкал.'', ''отоп.гкал./0 зарег.'') --перерасчёты по отоплению (гКал)
       group by s.lsk) d2,
       (select n.lsk, o.name, o2.name as name2 from nabor n,
         t_org o, t_org o2, usl u where n.org=o.id and n.usl=u.usl and
         u.cd in (''отоп'') --организации, котельные (здесь по одной услуге иначе - удвоится)
         and n.org=o.id and o.fk_org2=o2.id(+)) r,
       (select n.lsk, o.name, o2.name as name2 from nabor n,
         t_org o, t_org o2, usl u where n.org=o.id and n.usl=u.usl and
         u.cd in (''отоп.гкал.'') --организации, котельные (здесь по одной услуге иначе - удвоится)
         and n.org=o.id and o.fk_org2=o2.id(+)) r2
    where s.lsk = e.lsk(+)
     and s.lsk = e2.lsk(+)
     and s.lsk = d.lsk(+)
     and s.lsk = d2.lsk(+)
     and s.lsk = r.lsk(+)
     and s.lsk = r2.lsk(+)
     and s.reu=c.reu
     group by
     c.name, nvl(r.name2, r2.name2), nvl(r.name, r2.name),
     c.head_name,
     upper(utils.MONTH_NAME(substr(s.mg,5,2)))||'' ''||substr(s.mg,1,4)||''г.''
     order by
     c.name, nvl(r.name2, r2.name2), nvl(r.name, r2.name)
    '
    using reu_;
    end if;

elsif сd_ in  ('86') then
    if var_ = 2 then
    --по УК
    open prep_refcursor for
    'select
     c.name as name_uk,
     nvl(r.name2, r2.name2) as name_org,
     nvl(r.name, r2.name) as name_kot,

     sum(nvl(s.opl,0)) as opl_itg,
     sum(case when s.status not in (7) then s.opl else 0 end) as opl,
     sum(case when s.status in (7) then s.opl else 0 end) as opl_ur,

     sum(e.vol) as vol_itg,
     sum(case when f.kub is null then e.vol end) as vol_nrm,
     sum(case when f.kub is null then e.vol_wo_odn end) as vol_wo_odn_nrm,
     sum(case when f.kub is null then e.vol_odn end) as vol_odn_nrm,
     sum(case when f.kub is null then e.vol_empt end) as vol_empt_nrm,
     sum(case when f.kub is null then e.vol_odn_empt end) as vol_odn_empt_nrm,

     sum(case when f.kub is not null then e.vol end) as vol_odpu,
     sum(case when f.kub is not null then e.vol_wo_odn end) as vol_wo_odn_odpu,
     sum(case when f.kub is not null then e.vol_odn end) as vol_odn_odpu,
     sum(case when f.kub is not null then e.vol_empt end) as vol_empt_odpu,
     sum(case when f.kub is not null then e.vol_odn_empt end) as vol_odn_empt_odpu,

     sum(e.summa) as summa_itg,
     sum(case when f.kub is null then e.summa end) as summa_nrm,
     sum(case when f.kub is null then e.summa_wo_odn end) as summa_wo_odn_nrm,
     sum(case when f.kub is null then e.summa_odn end) as summa_odn_nrm,
     sum(case when f.kub is null then e.summa_empt end) as summa_empt_nrm,
     sum(case when f.kub is null then e.summa_odn_empt end) as summa_odn_empt_nrm,
     sum(case when f.kub is null then e.summa_chng end) as summa_chng_nrm,
     sum(case when f.kub is null then e.summa_chng_empt end) as summa_chng_empt_nrm,

     sum(case when f.kub is not null then e.summa end) as summa_odpu,
     sum(case when f.kub is not null then e.summa_wo_odn end) as summa_wo_odn_odpu,
     sum(case when f.kub is not null then e.summa_odn end) as summa_odn_odpu,
     sum(case when f.kub is not null then e.summa_empt end) as summa_empt_odpu,
     sum(case when f.kub is not null then e.summa_odn_empt end) as summa_odn_empt_odpu,
     sum(case when f.kub is not null then e.summa_chng end) as summa_chng_odpu,
     sum(case when f.kub is not null then e.summa_chng_empt end) as summa_chng_empt_odpu,
     c.head_name,
     upper(utils.MONTH_NAME(substr(s.mg,5,2)))||'' ''||substr(s.mg,1,4)||''г.'' as mg_name
    from (select s.* from arch_kart s, s_reu_trest e where '||sqlstr_||' and exists --ключевой запрос
      (select * from a_charge a, usl u where a.usl=u.usl and
        u.cd in (''г.вода'', ''г.вода/0 зарег.'') and a.type = 1 and a.summa <> 0
        and a.lsk=s.lsk and a.mg=s.mg
      )
     and e.reu=:reu
     and s.reu=e.reu
     and s.psch not in (8,9)
     and s.status not in (7)--убрал нежилые
     ) s, t_org c, params p,
    (select a.lsk,
     sum(a.test_opl) as vol, --объем всего
     sum(case when a.cd in (''г.вода'', ''г.вода/0 зарег.'') then a.test_opl else 0 end) as vol_wo_odn, --объем общий без ОДН
     sum(case when a.cd in (''г.вода.ОДН'', ''Г.в. ОДН, 0 зарег'') then a.test_opl else 0 end) as vol_odn, --объем ОДН
     sum(case when a.cd in (''г.вода/0 зарег.'') then a.test_opl else 0 end) as vol_empt, --объем по пустым кв.
     sum(case when a.cd in (''Г.в. ОДН, 0 зарег'') then a.test_opl else 0 end) as vol_odn_empt, --объем ОДН по пустым кв.
     sum(a.summa) as summa, --начисление всего
     sum(case when a.cd in (''г.вода'', ''г.вода/0 зарег.'') then a.summa else 0 end) as summa_wo_odn, --начисление общее без ОДН
     sum(case when a.cd in (''г.вода.ОДН'', ''Г.в. ОДН, 0 зарег'') then a.summa else 0 end) as summa_odn, --начисление ОДН
     sum(case when a.cd in (''г.вода/0 зарег.'') then a.summa else 0 end) as summa_empt, --начисление по пустым кв.
     sum(case when a.cd in (''Г.в. ОДН, 0 зарег'') then a.summa else 0 end) as summa_odn_empt, --начисление ОДН по пустым кв.
     sum(a.summa_chng) as summa_chng,
     sum(a.summa_chng_empt) as summa_chng_empt
       from
       (select s.lsk, s.summa, null as summa_chng, null as summa_chng_empt, s.test_opl, u.cd
         from a_charge s, usl u where '||sqlstr_||' and s.usl=u.usl and
         u.cd in (''г.вода'', ''г.вода/0 зарег.'', ''г.вода.ОДН'', ''Г.в. ОДН, 0 зарег'') and s.type=1 --г.в.
        union all
        select s.lsk, s.summa, s.summa as summa_chng,
          case when u.cd in (''г.вода/0 зарег.'') then s.summa else 0 end as summa_chng_empt, null as test_opl, u.cd
         from a_change s, usl u where '||sqlstr_||' and s.usl=u.usl and
         u.cd in (''г.вода'', ''г.вода/0 зарег.'', ''г.вода.ОДН'', ''Г.в. ОДН, 0 зарег'')) a--г.в. в т.ч. перерасчеты
     group by a.lsk
     ) e,
     (select n.lsk, s.kub from a_nabor n, a_vvod s, usl u where '||sqlstr_||' and s.usl=u.usl and
         u.cd in (''г.вода'')
         and n.mg=s.mg
         and n.usl=s.usl
         and n.fk_vvod=s.id
         ) f,
      (select s.lsk, sum(s.summa) as summa from a_change s, usl u where '||sqlstr_||' and s.usl=u.usl and
       u.cd in (''отоп'', ''отоп/0 зарег.'') --перерасчёты по отоплению
       group by s.lsk) d,
      (select s.lsk, sum(s.summa) as summa from a_change s, usl u where '||sqlstr_||' and s.usl=u.usl and
       u.cd in (''отоп.гкал.'', ''отоп.гкал./0 зарег.'') --перерасчёты по отоплению (гКал)
       group by s.lsk) d2,
       (select n.lsk, o.name, o2.name as name2 from nabor n,
         t_org o, t_org o2, usl u where n.org=o.id and n.usl=u.usl and
         u.cd in (''отоп'') --организации, котельные (здесь по одной услуге иначе - удвоится)
         and n.org=o.id and o.fk_org2=o2.id(+)) r,
       (select n.lsk, o.name, o2.name as name2 from nabor n,
         t_org o, t_org o2, usl u where n.org=o.id and n.usl=u.usl and
         u.cd in (''отоп.гкал.'') --организации, котельные (здесь по одной услуге иначе - удвоится)
         and n.org=o.id and o.fk_org2=o2.id(+)) r2
    where s.lsk = e.lsk(+)
     and s.lsk = f.lsk(+)
     and s.lsk = d.lsk(+)
     and s.lsk = d2.lsk(+)
     and s.lsk = r.lsk(+)
     and s.lsk = r2.lsk(+)
     and s.reu=c.reu
     group by
     c.name, nvl(r.name2, r2.name2), nvl(r.name, r2.name),
     c.head_name,
     upper(utils.MONTH_NAME(substr(s.mg,5,2)))||'' ''||substr(s.mg,1,4)||''г.''
     order by
     c.name, nvl(r.name2, r2.name2), nvl(r.name, r2.name)'
    using reu_;
    end if;

elsif сd_ in  ('88') then
 --Реестр для фонда Капремонта

    if var_ = 0 then
    --по Городу
      if utils.get_int_param('CAP_VAR_REP1') = 0 then
          -- версия для остальных
          open prep_refcursor for
                    select * from 
                    (select 
                    rownum as rn1, xx1.* from 
                    (select /*+ USE_HASH(k, o2, tp, o, s, d, tp2, t, p1, p5, sl, sp, g)*/ 
                    scott.utils.month_name(substr(mg_, 5, 2)) as mon,
                 substr(mg_, 1, 4) as year, k.lsk as ls, o.name as np, s.name as ul,
                 ltrim(k.nd, '0') as dom, ltrim(k.kw, '0') as kv, d.name_kp as st,
                 d.tp as naz, k.k_fam as sur, k.k_im as nam, k.k_ot as mid,
                  -- сведения о льготах
                 g.name as lg,
                   -- площадь
                 k.opl as pl,
                  -- сальдо входящее
                 nvl(t.indebet, 0) + nvl(t.inkredit, 0) as sn,
                  -- проценты в сальдо начисленной пени
                 --nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p1.penya_in, 0),0) as pensn,
                  -- начислено
                 nvl(t.charges, 0) as bil,
                  -- начисленная пеня (текущая)
                 nvl(t.pcur,0) as pcur,
                  -- вх. сальдо по пене
                 nvl(t.pinsal,0) as pinsal,
                  -- исх сальдо по пене
                 nvl(t.poutsal,0) as poutsal,
                  -- оплачено
                 nvl(t.payment, 0) as pay,
                  -- оплачено пени
                 nvl(t.pn,0) as penpay,
                  -- сальдо исходящее
                 nvl(t.outdebet, 0) + nvl(t.outkredit, 0) as sk,
                  -- проценты в сальдо уплаченной пени
                 --nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p5.penya_out, 0),0) as pensk,
                  -- перерасчет
                 nvl(t.changes,0) as corr
            from scott.arch_kart k
            join scott.t_org o2 on o2.cd = 'Фонд Капремонта МКД'
            join scott.t_org_tp tp on tp.cd = 'Город'
            join scott.t_org o on o.fk_orgtp = tp.id
            join scott.spul s on k.kul = s.id
            join scott.status d on k.status = d.id
            join v_lsk_tp tp2 on k.fk_tp=tp2.id
            left join (select t.lsk, t.org,  sum(t.charges) as charges, sum(t.changes) as changes, 
                     sum(t.pinsal) as pinsal, sum(t.pcur) as pcur,
                     sum(t.poutsal) as poutsal, sum(t.indebet) as indebet, sum(t.inkredit) as inkredit, 
                     sum(t.outdebet) as outdebet, sum(t.outkredit) as outkredit, sum(t.payment) as payment, sum(t.pn) as pn from 
                     scott.xitog3_lsk t 
                     join usl us2 on us2.cd in ('кап.','кап/св.нор') and t.usl=us2.usl and t.mg=mg_
                     group by t.lsk, t.org) t on k.lsk = t.lsk and t.org = o2.id
            left join (select p.lsk, max(p.fk_spk) as fk_spk
                         from scott.a_charge_prep2 p
                        where mg_ between p.mgFrom and p.mgTo
                          and p.tp = 9
                        group by p.lsk) sl on k.lsk = sl.lsk
            left join scott.spk sp on sl.fk_spk = sp.id
            left join scott.spk_gr g on sp.gr_id = g.id
             where k.mg = mg_
             /*and (k.status not in (1,9) and k.psch not in (8,9) and tp2.cd='LSK_TP_ADDIT' or
             (
             nvl(t.indebet, 0) + nvl(t.inkredit, 0) <>0 or
                 nvl(t.charges, 0) <>0 or
                 nvl(t.pcur,0) <>0 or
                 nvl(t.pinsal,0) <>0 or
                 nvl(t.poutsal,0) <>0 or
                 nvl(t.payment, 0) <>0 or
                 nvl(t.pn,0) <>0 or
                 nvl(t.outdebet, 0) + nvl(t.outkredit, 0) <>0 or
                 nvl(t.changes,0) <>0
                 ))*/
           order by scott.utils.f_ord_digit(k.nd), scott.utils.f_ord3(k.nd),
                    scott.utils.f_ord_digit(k.kw), scott.utils.f_ord3(k.kw)
                    ) xx1 ) xx2 
                    where rn1 between 0 and 2000000; --сделал ограничение до 2 млн, чтоб можно было если что постранично выгружать
  else
    -- версия для Кис                    
    open prep_refcursor for
                        select * from 
                        (select 
                        rownum as rn1, xx1.* from 
                        (select 
                        scott.utils.month_name(substr(mg_, 5, 2)) as mon,
                     substr(mg_, 1, 4) as year, k.lsk as ls, o.name as np, s.name as ul,
                     ltrim(k.nd, '0') as dom, ltrim(k.kw, '0') as kv, d.name_kp as st,
                     d.tp as naz, k.k_fam as sur, k.k_im as nam, k.k_ot as mid,
                      --сведения о льготах
                     g.name as lg,
                       --площадь
                     k.opl as pl,
                      --сальдо начальное
                     nvl(t.indebet, 0) + nvl(t.inkredit, 0)+nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p1.penya_in, 0),0) as sn,
                      --проценты в сальдо начисленной пени
                     nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p1.penya_in, 0),0) as pensn,
                      --начислено, в т.ч. пеня
                     nvl(t.charges, 0) + nvl(t.poutsal, 0)
                       --+ nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p2.penya_chrg, 0),0)
                       --+ nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p3.penya_corr, 0),0)
                        as bil,
                      --начисленная пеня
                     nvl(t.poutsal,0)
                       --+ nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p2.penya_chrg, 0),0)
                       --+ nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p3.penya_corr, 0),0)
                        as penbil,
                      --платеж, в т.ч. пеня
                     nvl(t.payment, 0) + nvl(t.pn, 0) as pay,
                     --nvl(t.payment, 0) + nvl(t.pn, 0)+ nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p4.penya_pay, 0),0) as pay,
                      --оплаченная пеня
                     t.pn as penpay,
                     --nvl(t.pn,0)+ nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p4.penya_pay, 0),0) as penpay,
                      --сальдо конечное
                     nvl(t.outdebet, 0) + nvl(t.outkredit, 0)+nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p5.penya_out, 0),0) as sk,
                      --проценты в сальдо уплаченной пени
                     nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p5.penya_out, 0),0) as pensk,
                      --перерасчет
                     nvl(t.changes,0) as corr
                from scott.arch_kart k
                join scott.t_org o2 on o2.cd = 'Фонд Капремонта МКД'
                join scott.t_org_tp tp on tp.cd = 'Город'
                join scott.t_org o on o.fk_orgtp = tp.id
                join scott.spul s on k.kul = s.id
                join scott.status d on k.status = d.id
                join v_lsk_tp tp2 on k.fk_tp=tp2.id
                left join (select t.lsk, t.org,  sum(t.charges) as charges, sum(t.changes) as changes, sum(t.poutsal) as poutsal, sum(t.indebet) as indebet, sum(t.inkredit) as inkredit, 
                         sum(t.outdebet) as outdebet, sum(t.outkredit) as outkredit, sum(t.payment) as payment, sum(t.pn) as pn from 
                         scott.xitog3_lsk t 
                         join usl us2 on us2.cd in ('кап.','кап/св.нор') and t.usl=us2.usl and t.mg=mg_
                         group by t.lsk, t.org) t on k.lsk = t.lsk and t.org = o2.id
                left join (select l.lsk, sum(l.penya) as penya_in --сальдо по пене входящее
                      from scott.a_penya l
                     where l.mg=scott.utils.add_months_pr(mg_, -1)
                     group by l.lsk) p1 on k.lsk=p1.lsk
                left join (select l.lsk, sum(l.penya) as penya_out --сальдо по пене исходящее
                      from scott.a_penya l
                     where l.mg=mg_
                     group by l.lsk) p5 on k.lsk=p5.lsk 

                left join (select p.lsk, max(p.fk_spk) as fk_spk
                             from scott.a_charge_prep2 p
                            where mg_ between p.mgFrom and p.mgTo
                              and p.tp = 9
                            group by p.lsk) sl on k.lsk = sl.lsk
                left join scott.spk sp on sl.fk_spk = sp.id
                left join scott.spk_gr g on sp.gr_id = g.id
                 where k.mg = mg_
                 and (k.status not in (1,9) and k.psch not in (8,9) and tp2.cd='LSK_TP_ADDIT' or
                 (
                 nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p1.penya_in, 0),0) <> 0
                 or nvl(t.charges, 0) + nvl(t.poutsal, 0) <> 0
                 or nvl(t.poutsal,0) <> 0 
                 or nvl(t.payment, 0) + nvl(t.pn, 0) <> 0
                 or t.pn <> 0
                 or nvl(t.outdebet, 0) + nvl(t.outkredit, 0)+nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p5.penya_out, 0),0) <> 0
                 or nvl(decode(tp2.cd, 'LSK_TP_ADDIT', p5.penya_out, 0),0) <> 0
                 or nvl(t.changes,0)<>0
                     ))
               order by scott.utils.f_ord_digit(k.nd), scott.utils.f_ord3(k.nd),
                        scott.utils.f_ord_digit(k.kw), scott.utils.f_ord3(k.kw)
                        ) xx1 ) xx2 
                        where rn1 between 0 and 200000000;
    end if;                    
    end if;

 elsif сd_ in  ('89') then
    if var_ = 3 then
    --по Дому
      OPEN prep_refcursor FOR select d.npp, h.name_reu||' '||l.name||h.name||', '||ltrim(h.nd,'0') as predpr,
      null as type, to_char(d.id)||' '||d.name as org, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1,
      sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(nvl(o.changes,0)+nvl(o.changes2,0)) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (
      select u.uslm, e.reu, e.kul, e.nd, e.status, e.org, e.usl,  
             trim(t.name_reu) as name_reu, s.name, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest t, spul s, usl u
      where e.usl=u.usl and e.reu=t.reu and e.reu=reu_ and e.kul=kul_ and e.nd=nd_
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_USL2' 
                and i.sel_cd=e.usl
            and i.sel=1)
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_ORG2' 
                and i.sel_id=e.org
            and i.sel=1)
      and e.kul=s.id) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp,sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      t_org d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=4 and h.org=d.id and h.usl=m.usl
      group by d.npp, h.name_reu||' '||l.name||h.name||', '||ltrim(h.nd,'0'),
      to_char(d.id)||' '||d.name, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1)
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by  h.name_reu||' '||l.name||h.name||', '||ltrim(h.nd,'0'), d.npp;
      
    elsif var_ = 2 then
    --по РЭУ
      OPEN prep_refcursor FOR select d.npp, l.name||h.name_reu as predpr,null as type, to_char(d.id)||' '||d.name as org, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(nvl(o.changes,0)+nvl(o.changes2,0)) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select u.uslm, e.reu, e.kul, e.nd, e.status, e.org, e.usl, s.name_reu, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest s, usl u
      where e.usl=u.usl and e.reu=reu_ and e.reu=s.reu 
          and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_USL2'
                and i.sel_cd=e.usl
            and i.sel=1)
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_ORG2' 
                and i.sel_id=e.org
            and i.sel=1)
      ) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp,sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(nvl(t.changes,0)+nvl(changes2,0)) as changesall,
       sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      t_org d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=3 and h.org=d.id and h.usl=m.usl
      group by d.npp, l.name||h.name_reu, to_char(d.id)||' '||d.name, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1)
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by d.npp;
--        USING reu_, fk_ses_, fk_ses_, mg_, mg_, mg1_, mg1_;
    elsif var_ = 1 then
    --по ЖЭО
      OPEN prep_refcursor FOR select d.npp,l.name||h.name_tr as predpr, null as type, to_char(d.id)||' '||d.name as org, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(nvl(o.changes,0)+nvl(o.changes2,0)) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select u.uslm, e.reu, e.kul, e.nd, e.status, e.org, e.usl, s.trest, s.name_tr, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest s, usl u
        where e.usl=u.usl and s.trest=trest_ and e.reu=s.reu
          and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_USL2'
                and i.sel_cd=e.usl
            and i.sel=1)
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_ORG2' 
                and i.sel_id=e.org
            and i.sel=1)
        ) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp,sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      t_org d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=2 and h.org=d.id and h.usl=m.usl
      group by d.npp, l.name||h.name_tr, to_char(d.id)||' '||d.name, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1)
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by d.npp;
--        USING trest_, fk_ses_, fk_ses_, mg_, mg_, mg1_, mg1_;
    elsif var_ = 0 then
    --по Городу
      OPEN prep_refcursor FOR select d.npp, l.name as predpr, null as type, to_char(d.id)||' '||d.name as org, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1) as nm1, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(nvl(o.changes,0)+nvl(o.changes2,0)) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select u.uslm, e.reu, e.kul, e.nd, e.status, e.org, e.usl, s.trest, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, s_reu_trest s, usl u where e.usl=u.usl and e.reu=s.reu
          and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_USL2'
                and i.sel_cd=e.usl
            and i.sel=1)
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_ORG2' 
                and i.sel_id=e.org
            and i.sel=1)
      ) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp,sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status,fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      t_org d, usl m, org l
      where
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and 
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=1 and h.org=d.id and h.usl=m.usl
      group by d.npp, l.name, to_char(d.id)||' '||d.name, to_char(h.uslm)||' '||decode(m.frc_get_price,1,m.nm,m.nm1)
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by d.npp;
--        USING fk_ses_, fk_ses_, mg_, mg_, mg1_, mg1_;
  end if;      
  elsif сd_ in ('90') then
 --Оборотная ведомость по домам
    IF var_ = 3 THEN
      --по дому
      OPEN prep_refcursor FOR select null as predpr, h.name_reu||' '||p.name||', '||ltrim(h.nd,'0') as adr, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(nvl(o.changes,0)+nvl(o.changes2,0)) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (
      select distinct e.reu, e.kul, e.nd, e.org, e.usl, e.status, u2.uslm, trim(t.name_reu) as name_reu, s.name, e.fk_lsk_tp from t_saldo_reu_kul_nd_st e, usl u2, s_reu_trest t, spul s
      where e.usl=u2.usl and e.reu=t.reu and e.reu=reu_ and e.kul=kul_ and e.nd=nd_
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_USL2' 
                and i.sel_cd=e.usl
            and i.sel=1)
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_ORG2' 
                and i.sel_id=e.org
            and i.sel=1)
      and e.kul=s.id) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp, sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status, fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, uslm m, org l, spul p
      where h.kul=p.id and
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and 
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=3 and h.org=d.kod and h.uslm=m.uslm
      group by h.name_reu||' '||p.name||', '||ltrim(h.nd,'0')
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by h.name_reu||' '||p.name||', '||ltrim(h.nd,'0');
--          USING reu_, kul_, nd_, fk_ses_, fk_ses_, mg_, mg_, mg1_, mg1_;
    ELSIF var_ = 2 THEN
      --по ЖЭО
      OPEN prep_refcursor FOR select l.name||h.name_reu as predpr, p.name||', '||ltrim(h.nd,'0') as adr, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(nvl(o.changes,0)+nvl(o.changes2,0)) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select distinct u.reu, u.kul, u.nd, u.org, u.usl, u.status, u2.uslm, trim(s.name_reu) as name_reu, fk_lsk_tp from t_saldo_reu_kul_nd_st u, usl u2, s_reu_trest s
      where u.usl=u2.usl and u.reu=reu_ and u.reu=s.reu
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_USL2' 
                and i.sel_cd=u.usl
            and i.sel=1)
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_ORG2' 
                and i.sel_id=u.org
            and i.sel=1)
      ) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status, fk_lsk_tp,sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status, fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, uslm m, org l, spul p
      where h.kul=p.id and
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and 
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=3 and h.org=d.kod and h.uslm=m.uslm
      group by l.name||h.name_reu, p.name||', '||ltrim(h.nd,'0')
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by  l.name||h.name_reu, p.name||', '||ltrim(h.nd,'0');
          --USING reu_, fk_ses_, fk_ses_, mg_, mg_, mg1_, mg1_;
    ELSIF var_ = 1  THEN
      --по Фонду
      OPEN prep_refcursor FOR select l.name||t.name_tr as predpr, p.name||', '||ltrim(h.nd,'0') as adr, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(nvl(o.changes,0)+nvl(o.changes2,0)) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select distinct u.reu, u.kul, u.nd, u.org, u.usl, u.status, u2.uslm, u.fk_lsk_tp from t_saldo_reu_kul_nd_st u, usl u2, s_reu_trest s
      where u.usl=u2.usl and u.reu=s.reu and s.trest=trest_
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_USL2' 
                and i.sel_cd=u.usl
            and i.sel=1)
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_ORG2' 
                and i.sel_id=u.org
            and i.sel=1)
       ) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status,fk_lsk_tp,sum(charges) as charges,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status, fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, uslm m, org l, spul p, s_reu_trest t
      where h.kul=p.id and h.reu=t.reu and
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and 
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=2 and h.org=d.kod and h.uslm=m.uslm
      group by l.name||t.name_tr, p.name||', '||ltrim(h.nd,'0')
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by l.name||t.name_tr, p.name||', '||ltrim(h.nd,'0');
--          USING trest_, fk_ses_, fk_ses_, mg_, mg_, mg1_, mg1_;
    ELSIF var_ = 0 THEN
      --по Городу
      OPEN prep_refcursor FOR select l.name as predpr, p.name||', '||ltrim(h.nd,'0') as adr, sum(i.indebet) as indebet, sum(i.inkredit) as inkredit,
      sum(o.charges) as charges, sum(o.poutsal) as poutsal, sum(o.changes) as changes, sum(o.subsid) as subsid, sum(o.privs) as privs, sum(o.privs_city) as privs_city, sum(o.payment) as payment,
      sum(o.ch_full) as ch_full, sum(o.changes2) as changes2, sum(nvl(o.changes,0)+nvl(o.changes2,0)) as changesall,
      sum(o.pn) as pn, sum(u.outdebet) as outdebet, sum(u.outkredit) as outkredit
      from
      (select distinct u.reu, u.kul, u.nd, u.org, u.usl, u.status, u2.uslm, u.fk_lsk_tp from t_saldo_reu_kul_nd_st u, usl u2
      where u.usl=u2.usl and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_USL2' 
                and i.sel_cd=u.usl
            and i.sel=1)
            and exists
           (select * from list_c i, spr_params p where i.fk_ses=fk_ses_
                and p.id=i.fk_par and p.cd='REP_ORG2' 
                and i.sel_id=u.org
            and i.sel=1)
      ) h,
      (select * from xitog3 e where e.mg=mg_) i,
      (select reu,kul,nd,org,usl,status, fk_lsk_tp, sum(charges) as charges, sum(poutsal) as poutsal,
      sum(changes) as changes, sum(subsid) as subsid, sum(privs) as privs, sum(privs_city) as privs_city,
      sum(ch_full) as ch_full, sum(changes2) as changes2, sum(payment) as payment, sum(pn) as pn from xitog3 t
      where t.mg between mg_ and mg1_
      group by reu,kul,nd,org,usl,status, fk_lsk_tp) o,
      (select * from xitog3 e where e.mg=mg1_) u,
      sprorg d, uslm m, org l, spul p
      where h.kul=p.id and
      h.reu=i.reu(+) and h.kul=i.kul(+) and h.nd=i.nd(+) and h.org=i.org(+) and h.usl=i.usl(+) and h.status=i.status(+) and h.fk_lsk_tp=i.fk_lsk_tp(+) and 
      h.reu=o.reu(+) and h.kul=o.kul(+) and h.nd=o.nd(+) and h.org=o.org(+) and h.usl=o.usl(+) and h.status=o.status(+) and h.fk_lsk_tp=o.fk_lsk_tp(+) and
      h.reu=u.reu(+) and h.kul=u.kul(+) and h.nd=u.nd(+) and h.org=u.org(+) and h.usl=u.usl(+) and h.status=u.status(+) and h.fk_lsk_tp=u.fk_lsk_tp(+) and
      l.id=1 and h.org=d.kod and h.uslm=m.uslm
      group by l.name, p.name||', '||ltrim(h.nd,'0')
      having sum(i.indebet) <>0 or sum(i.inkredit) <>0 or
      sum(o.charges) <>0 or sum(o.changes) <>0 or sum(o.subsid) <>0 or
      sum(o.privs) <>0 or sum(o.privs_city) <>0 or sum(o.payment) <>0 or
      sum(o.pn) <>0 or sum(u.outdebet) <>0 or sum(u.outkredit) <>0
      order by l.name, p.name||', '||ltrim(h.nd,'0');
          --USING fk_ses_, fk_ses_, mg_, mg_, mg1_, mg1_;
     END IF;
 elsif сd_ in ('91') then
    --реестр пользующихся льготой по капремонту >=70 лет ТОЛЬКО ДЛЯ ПОЛЫС, ТАК КАК У НИХ НЕТ ДОП СЧЕТОВ, - РАБОТАЕТ ПО ДРУГОМУ
    OPEN prep_refcursor for select scott.utils.month_name(substr(k.mg, 5, 2)) as mon,
                 substr(k.mg, 1, 4) as year, k.lsk as ls, s.name as ul, ltrim(k.nd,'0') as dom, ltrim(k.kw,'0') as kv,
     a.name as st, k.opl, k.k_fam as sur, k.k_im as nam, k.k_ot as mid, k.kpr, t.dat_rog
     from arch_kart k, a_kart_pr t, spul s, status a
    where k.psch not in (8,9)
      and k.lsk=t.lsk and k.mg=t.mg and k.mg=mg_
      and k.kul=s.id and k.status=a.id and a.cd='PRV'
      and exists (select min(p.id) from a_kart_pr p, relations r where
       months_between(to_date(p.mg||'01','YYYYMMDD'), p.dat_rog) /12 >= 70
       and p.dat_rog is not null
       and p.id=t.id and p.mg=mg_
       and p.relat_id=r.id and r.cd in ('Квартиросъемщик', 'Собственник')
       and p.status=1
       having min(p.id)=t.id
       )
     and exists (select * from a_charge_prep2 a, arch_kart d, v_lsk_tp tp
       where a.lsk=d.lsk and a.tp=9 and mg_ between a.mgFrom and a.mgTo and d.mg = mg_
       and d.k_lsk_id=k.k_lsk_id and d.fk_tp=tp.id
       and tp.cd='LSK_TP_ADDIT'
       ) --доп счета, только льготники
      order by k.reu, s.name, ltrim(k.nd,'0'), ltrim(k.kw,'0');
      
 elsif сd_ in ('92') then
    --реестр для УСЗН,-длинный, бессмысленный и беспощадный (для ТСЖ)
    OPEN prep_refcursor FOR select c.name as org1, c.reu, s.kul, null as st_code, 
     c2.name as nasp, l.cd_uszn as nylic,
     scott.utils.f_ord_digit(s.nd) as ndom,
     lower(scott.utils.f_ord3(s.nd)) as nkorp,
     ltrim(s.kw,'0') as nkw,
     null as nkomn, 
     s.lsk as lchet,
     s.kpr,
     s.kpr_wr,
     s.kpr_ot,
     s.opl,
     s.opl as pl_ot,
     'Содержание и ремонт жилого помещения' as gu1,
     c1.tf1 as tf_ng1,
     c1.tf2 as tf_svg1,
     e2.summa_itg as sum_g1,
     'Капитальный ремонт' as gu2,
     c2.tf1 as tf_ng2,
     c2.tf2 as tf_svg2,
     e3.summa_itg as sum_g2,
     'Найм коммерческий' as gu3,
     null as tf_ng3,
     null as tf_svg3,
     null as sum_g3,
     'Найм помещения' as gu4,
     c4.tf1 as tf_ng4,
     null as tf_svg4,
     e4.summa_itg as sum_g4,
     'Электроснабжение в домах со стационарными эл.плит.' as gku1,
     s.lsk as lchet1,
     'квт.' as ed_izm1,
     c5.tf1 as tf_n1,
     c5.tf2 as tf_sv1,
     e5.test_opl as fakt1,
     case when s.kpr = 1 THEN
          130
        when s.kpr IN (2, 3) THEN
          100
        when s.kpr = 4 THEN
          87.5
        when s.kpr = 5 THEN
          80
        when s.kpr >= 6 THEN
          75 END as norm1,
     e5.summa_itg as sum_f1,
     'Электроснабжение, ОДН' as gku2,
     s.lsk as lchet2,
     'квт.' as ed_izm2,
     e6.nrm as norm2,
     c6.tf1 as tf_n2,
     null as tf_sv2,
     null as fakt2,
     e6.summa_itg as sum_f2,
     null as gku3,
     null as lchet3,
     null as ed_izm3,
     null as tf_n3,
     null as tf_sv3,
     null as norm3,
     null as fakt3,
     null as sum_f3,
     'ХВС' as gku4,
     s.lsk as lchet4,
     'м3' as ed_izm4,
     c7.tf1 as tf_n4,
     c7.tf2 as tf_sv4,
     e7.norm as norm4,
     e7.test_opl as fakt4,
     e7.summa_itg as sum_f4,
     'Холодная вода, ОДН' as gku5,
     s.lsk as lchet5,
     'м3' as ed_izm5,
     c8.tf1 as tf_n5,
     c8.tf2 as tf_sv5,
     e8.nrm as norm5,
     e9.test_opl as fakt5,
     e8.summa_itg as sum_f5,
     'ГВС' as gku6,
     s.lsk as lchet6,
     'м3' as ed_izm6,
     c9.tf1 as tf_n6,
     c9.tf2 as tf_sv6,
     e9.norm as norm6,
     e9.test_opl as fakt6,
     e9.summa_itg as sum_f6,
     'Горячая вода, ОДН' as gku7,
     s.lsk as lchet7,
     'м3' as ed_izm7,
     c10.tf1 as tf_n7,
     c10.tf2 as tf_sv7,
     e10.nrm as norm7,
     null as fakt7,
     e10.summa_itg as sum_f7,
     'Канализация' as gku8,
     s.lsk as lchet8,
     'м3' as ed_izm8,
     e11.test_opl as fakt8,
     c11.tf1 as tf_n8,
     c11.tf2 as tf_sv8,
     e11.norm as norm8,
     null as fakt8,
     e11.summa_itg as sum_f8,
     'Отопление' as gku9,
     s.lsk as lchet9,
     'м2' as ed_izm9,
     c12.tf1 as tf_n9,
     c12.tf2 as tf_sv9,
     case when s.kpr = 1 THEN
          33
        when s.kpr IN (2) THEN
          21
        when s.kpr >= 3 THEN
          18 END as norm9,
     case when to_number(s.lsk) between 1 and 157 then 0.0204 --жестко привязал по отоплению Гкал
          else 0.019678 end as fakt9,
     e12.summa_itg as sum_f9,
     'Газ в баллонах' as gku10,
     null as lchet10,
     null as ed_izm10,
     null as fakt10,
     null as sum_f10,
     'Канализование на ОДН' as gku11,
     s.lsk as lchet11,
     'м3' as ed_izm11,
     c13.tf1 as tf_n11,
     c13.tf2 as tf_sv11,
     e13.nrm as norm11,
     null as fakt11,
     e13.summa_itg as sum_f11,
     
     'Вывоз ТКО' as gku13,
     s.lsk as lchet13,
     'м3' as ed_izm13,
     c14.tf1 as tf_n13,
     c14.tf1 as tf_sv13,
     0.17275 as norm13,
     round(e14.test_opl*0.17275,4) as fakt13, -- кол-во людей * норматив
     e14.summa_itg as sum_f13,
     
     null as lchet12,
     null as ed_izm12,
     null as fakt12,
     null as sum_f12,
     null as gku12,
     null as tf_n12,
     null as tf_sv12,
     null as norm12
    from (select s.* from kart k, arch_kart s, s_reu_trest e where s.mg=mg_
     and k.lsk=s.lsk
     and k.sel1=1
     /*and e.reu='01'
     and s.lsk='00000001'*/
     and s.reu=e.reu
     and s.psch not in (8,9) --только открытые
     and s.status not in (7)--убрал нежилые
     ) s join t_org c on s.reu=c.reu
         join t_org c2 on 1=1
         join t_org_tp tp on c2.fk_orgtp=tp.id and tp.cd='Город'
         join params p on p.period=p.period
         join spul l on s.kul=l.id
         left join 
    (select s.lsk, 
     sum(s.summa) as summa_itg
       from a_charge2 s, usl u 
        where s.usl=u.usl and
       mg_ between s.mgFrom and s.mgTo and
       u.cd in ('т/сод', 'т/сод/св.нор', 'лифт', 'лифт/св.нор', 'дерат.', 'дерат/св.нор', 'мус.площ.', 'мус.площ./св.нор'/*,
       'выв.мус.', 'выв.мус./св.нор'*/)
       and s.type=1 --текущее содержание, вместе с под-услугами
     group by s.lsk) e2 on s.lsk = e2.lsk
         left join 
    (select s.lsk,
     sum(s.summa) as summa_itg
       from a_charge2 s, usl u where s.usl=u.usl and
       mg_ between s.mgFrom and s.mgTo and
      u.cd in ('кап.', 'кап/св.нор') and s.type=1 --капремонт
     group by s.lsk) e3 on s.lsk = e3.lsk
         left join 
    (select s.lsk,
     sum(s.summa) as summa_itg
       from a_charge2 s, usl u where s.usl=u.usl and
      mg_ between s.mgFrom and s.mgTo and
      u.cd in ('найм') and s.type=1 --найм
     group by s.lsk) e4 on s.lsk = e4.lsk
         left join 
    (select s.lsk,
     sum(s.test_opl) as test_opl,
     sum(s.summa) as summa_itg
       from a_charge2 s, usl u where s.usl=u.usl and
       mg_ between s.mgFrom and s.mgTo and
      u.cd in ('эл.энерг.2','эл.эн.2/св.нор') and s.type=1 --эл.энерг
     group by s.lsk) e5 on s.lsk = e5.lsk
         left join 
    (select s.lsk,
     sum(s.test_opl) as test_opl,
     sum(s.summa) as summa_itg,
     --max(d.nrm) as nrm
     4.1 as nrm --вбил жёстко
       from a_charge2 s
       join a_nabor2 n on s.lsk=n.lsk and 
       mg_ between s.mgFrom and s.mgTo and mg_ between n.mgFrom and n.mgTo
       join a_vvod d on n.fk_vvod=d.id and n.usl=d.usl
       and d.mg between s.mgFrom and s.mgTo
       join usl u2 on n.usl=u2.usl and u2.cd in ('эл.энерг.2')
       join usl u on s.usl=u.usl and u.cd in ('эл.эн.ОДН', 'EL_SOD') and s.type=1 --эл.энерг
     group by s.lsk) e6 on s.lsk = e6.lsk
         left join 
    (select s.lsk,
     sum(s.test_opl) as test_opl,
     sum(s.summa) as summa_itg,
     max(n.norm) as norm
       from a_charge2 s, a_nabor2 n, usl u where 
       s.usl=u.usl and s.lsk=n.lsk
       and mg_ between s.mgFrom and s.mgTo and mg_ between n.mgFrom and n.mgTo
       and s.usl=n.usl and
       u.cd in ('х.вода', 'х.вода/св.нор') and s.type=1
     group by s.lsk) e7 on s.lsk = e7.lsk
         left join 
    (select s.lsk,
     sum(s.test_opl) as test_opl,
     sum(s.summa) as summa_itg,
     max(d.nrm) as nrm
       from a_charge2 s
       join a_nabor2 n on s.lsk=n.lsk
       and mg_ between s.mgFrom and s.mgTo and mg_ between n.mgFrom and n.mgTo
       join a_vvod d on n.fk_vvod=d.id and n.usl=d.usl
       and d.mg between s.mgFrom and s.mgTo
       join usl u2 on n.usl=u2.usl and u2.cd in ('х.вода')
       join usl u on s.usl=u.usl and u.cd in ('х.вода.ОДН', 'HW_SOD') and s.type=1
     group by s.lsk) e8 on s.lsk = e8.lsk
         left join 
    (select s.lsk,
     sum(s.test_opl) as test_opl,
     sum(s.summa) as summa_itg,
     max(n.norm) as norm
       from a_charge2 s, a_nabor2 n, usl u where 
       s.usl=u.usl and s.lsk=n.lsk
       and mg_ between s.mgFrom and s.mgTo and mg_ between n.mgFrom and n.mgTo
       and s.usl=n.usl and
       u.cd in ('г.вода', 'г.вода/св.нор') and s.type=1
     group by s.lsk) e9 on s.lsk = e9.lsk
         left join 
    (select s.lsk,
     sum(s.test_opl) as test_opl,
     sum(s.summa) as summa_itg,
     max(d.nrm) as nrm
       from a_charge2 s
       join a_nabor2 n on s.lsk=n.lsk
       and mg_ between s.mgFrom and s.mgTo and mg_ between n.mgFrom and n.mgTo
       join a_vvod d on n.fk_vvod=d.id and n.usl=d.usl
       and d.mg between s.mgFrom and s.mgTo
       join usl u2 on n.usl=u2.usl and u2.cd in ('г.вода')
       join usl u on s.usl=u.usl and u.cd in ('г.вода.ОДН', 'GW_SOD') and s.type=1 --эл.энерг
     group by s.lsk) e10 on s.lsk = e10.lsk
         left join 
    (select s.lsk,
     sum(s.test_opl) as test_opl,
     sum(s.summa) as summa_itg,
     max(n.norm) as norm
       from a_charge2 s, a_nabor2 n, usl u where 
       s.usl=u.usl and s.lsk=n.lsk
       and mg_ between s.mgFrom and s.mgTo and mg_ between n.mgFrom and n.mgTo
       and s.usl=n.usl and
       u.cd in ('канализ', 'канализ/св.нор') and s.type=1
     group by s.lsk) e11 on s.lsk = e11.lsk
         left join 
    (select s.lsk,
     sum(s.test_opl) as test_opl,
     sum(s.summa) as summa_itg,
     null as norm
       from a_charge2 s, a_nabor2 n, usl u where 
       s.usl=u.usl and s.lsk=n.lsk
       and mg_ between s.mgFrom and s.mgTo and mg_ between n.mgFrom and n.mgTo
       and s.usl=n.usl and
       u.cd in ('отоп', 'отоп/св.нор') and s.type=1
     group by s.lsk) e12 on s.lsk = e12.lsk

    left join 
    (select s.lsk,
     sum(s.test_opl) as test_opl,
     sum(s.summa) as summa_itg
       from a_charge2 s, usl u where s.usl=u.usl and
       mg_ between s.mgFrom and s.mgTo and
      u.cd in ('выв.мус.') and s.type=1 -- вывоз ТКО
     group by s.lsk) e14 on s.lsk = e14.lsk

     left join
     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('т/сод', 'т/сод/св.нор', 'лифт', 'лифт/св.нор', 'дерат.', 'дерат/св.нор', 'мус.площ.', 'мус.площ./св.нор')
      group by n.lsk       
       ) c1
       on s.lsk=c1.lsk
     left join
     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('кап.', 'кап/св.нор')
      group by n.lsk       
       ) c2
       on s.lsk=c2.lsk
       
       
     left join
     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('найм')
      group by n.lsk       
       ) c4
       on s.lsk=c4.lsk
     left join
     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('эл.энерг.2','эл.эн.2/св.нор')
      group by n.lsk       
       ) c5
       on s.lsk=c5.lsk
       
     left join
     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('EL_SOD')
      group by n.lsk       
       ) c6
       on s.lsk=c6.lsk
       
     left join
     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('х.вода', 'х.вода/св.нор')
      group by n.lsk       
       ) c7
       on s.lsk=c7.lsk       
       
     left join
     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('х.вода.ОДН', 'HW_SOD')
      group by n.lsk       
       ) c8
       on s.lsk=c8.lsk       

     left join
     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('г.вода', 'г.вода/св.нор')
      group by n.lsk       
       ) c9
       on s.lsk=c9.lsk       

     left join
     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('г.вода.ОДН', 'GW_SOD')
      group by n.lsk       
       ) c10
       on s.lsk=c10.lsk       

     left join
     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('канализ', 'канализ/св.нор')
      group by n.lsk       
       ) c11
       on s.lsk=c11.lsk       

     left join
     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('отоп', 'отоп/св.нор')
      group by n.lsk       
       ) c12
       on s.lsk=c12.lsk       

    left join 

    (select s.lsk,
     sum(s.test_opl) as test_opl,
     sum(s.summa) as summa_itg,
     null as nrm
       from a_charge2 s
       join a_nabor2 n on s.lsk=n.lsk and 
        mg_ between n.mgfrom and n.mgto and
        mg_ between s.mgfrom and s.mgto
       join usl u2 on n.usl=u2.usl and u2.cd in ('канализ')
       join usl u on s.usl=u.usl and u.cd in ('KAN_SOD') and s.type=1 --канализ МКД
     group by s.lsk) e13 on s.lsk = e13.lsk

     left join

     (select n.lsk, round(sum(case when u.usl_norm = 0 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf1,
             round(sum(case when u.usl_norm = 1 then 
        case when n.koeff is not null and u.sptarn in (0,2,3,4) then n.koeff else 1 end * r.summa else 0 end),2) as tf2
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg=mg_
      where 
      mg_ between n.mgfrom and n.mgto
      and u.cd in ('KAN_SOD') --канализ МКД
      group by n.lsk       
       ) c13
       on s.lsk=c13.lsk       

     left join
     (select n.lsk, max(round(n.koeff * r.summa ,2)) as tf1
       from 
         a_nabor2 n join usl u on n.usl=u.usl 
         join a_prices r on n.usl=r.usl and r.mg between n.mgFrom and n.mgTo
      where r.mg=mg_ 
      and u.cd in ('выв.мус.') -- вывоз ТКО
      group by n.lsk       
       ) c14
       on s.lsk=c14.lsk

    order by l.name, s.nd, s.kw;
      
 elsif сd_ in ('94') then -- следующий номер CD смотреть так же в REP_LSK!
    --ГИС ЖКХ
    --Шаблон импорта ЛС
    l_dt1:=gdt(0,0,0);
    OPEN prep_refcursor FOR select k.house_id, k.reu, 
       ltrim(k.kw,'0') as kw, decode(s.cd, 'MUN', 'Да', 'PRV', 'Нет', 'Да') as status,
       k.lsk,
       k2.elsk,
       tp.cd as tp,
       k2.lsk as lsk2,
       k2.elsk as elsk2,
       decode(tp2.cd, 'LSK_TP_MAIN', 'ЛС УО', 'ЛС КР') as tp2,
       s.cd as stat_cd,
       k.k_fam, k.k_im, k.k_ot, 
       to_char(k.opl, '999999.99') as opl, 
       k.opl,
       k.kpr, 
       'Нет' as cad_no, --Кадастр.номера пока нет
       k.entr, --подъезд
       'Да' as comm_use,--Помещение, составляющее общее имущество в многоквартирном доме
       'Отдельная квартира' as charact, --Характеристика помещения
       x8.d1 as ent_date, --дата постройки подъезда
       b.shortname||'.'||b.offname||', '||a.shortname||'.'||a.offname||', '||h.housenum||', '||h.buildnum as adr,
       100 as part, --доля
       h.houseguid, o.oktmo,
       x6.s1 as cond, x.n1 as house_opl, x3.n1 as house_opl_pasp, x4.n1 as house_year, x2.n1 as house_et, 0 as house_unet, 'Новокузнецк' as clk_zone,
       'Нет' as house_cult, 'Нет' as house_cad_no,  -- НЕ выгружать кадастровый номер пока, система пишет: INT004072 Сведения в ГКН не найдены.
       x7.n1 as ent_et, x8.d1 as ent_dt, e.serviceId, e.guid as premiseGUID
       from kart k
       join bs.addr_tp atp on atp.cd='Квартира'
       left join exs.eolink e on k.lsk=e.lsk -- лиц.счет
       left join exs.eolink e2 on e2.id=e.parent_id and e2.fk_objtp=atp.id -- помещение
       join u_list tp on k.fk_tp=tp.id and k.psch not in (8,9) --тип лиц.счета, не закрытый
       join u_list tp2 on tp2.cd='LSK_TP_MAIN' --для счета по капремонту
       left join kart k2 on k.k_lsk_id=k2.k_lsk_id and k2.fk_tp=tp2.id and k2.psch not in (8,9) -- счет по капремонту
       join status s on k.status=s.id
       join prep_house_fias p on k.house_id=p.fk_house
       join fias_house h on lower(p.houseguid)=lower(h.houseguid) --дом
       join fias_addr a on lower(h.aoguid)=lower(a.aoguid) --улица
       join fias_addr b on lower(a.parentguid)=lower(b.aoguid) --город
       join c_houses h2 on p.fk_house=h2.id
       join u_list u on u.cd='Общая площадь здания'
       left join t_objxpar x on h2.k_lsk_id=x.fk_k_lsk and x.fk_list=u.id
       join u_list u2 on u2.cd='Этажность'
       left join t_objxpar x2 on h2.k_lsk_id=x2.fk_k_lsk and x2.fk_list=u2.id
       join u_list u3 on u3.cd='Общ.пл.жил.пом.по пасп.'
       left join t_objxpar x3 on h2.k_lsk_id=x3.fk_k_lsk and x3.fk_list=u3.id
       join u_list u4 on u4.cd='Год ввода в экспл.'
       left join t_objxpar x4 on h2.k_lsk_id=x4.fk_k_lsk and x4.fk_list=u4.id
       join u_list u5 on u5.cd='Кадаст.номер'
       left join t_objxpar x5 on h2.k_lsk_id=x5.fk_k_lsk and x5.fk_list=u5.id
       join u_list u6 on u6.cd='Состояние'
       left join t_objxpar x6 on h2.k_lsk_id=x6.fk_k_lsk and x6.fk_list=u6.id
       
       left join c_vvod d on k.house_id=d.house_id and k.entr=d.vvod_num and d.usl is null --подъезд
       left join t_objxpar x7 on d.fk_k_lsk=x7.fk_k_lsk and x7.fk_list=u2.id
       join u_list u8 on u8.cd='Дата постройки'
       left join t_objxpar x8 on d.fk_k_lsk=x8.fk_k_lsk and x8.fk_list=u8.id
       
       join t_org o on b.aoguid=o.aoguid
        where 
       --даты установить корректные! в пределах тек периода!!!
       l_dt1 between h.startdate and h.enddate 
       and l_dt1 between b.startdate and b.enddate
       and k.reu=reu_
       --and utils.f_ord3(k.kw) is null --только не квартиры с индексом!!! ред.18.11.2016 Убрал ограничение, так как в ГИС-е оно тоже снято
       order by k.reu, k.house_id, nvl(k.entr,1), k.kw, b.offname, a.offname, h.housenum -- строго порядок по k.reu, k.house_id, k.entr иначе будет выгружаться некорректно!
       ;
       
       
/*1 Этажность
2 Дата постройки
3 Кадаст.номер
4 Статус культ.насл
5 Кол-во подземных этажей
6 Кол-во этажей
7 Площадь застройки
8 Общий износ здания
9 Год ввода в экспл.
10  Год постройки
11  Общ.пл.нежил.пом.по пасп.
12  Общ.пл.жил.пом.по пасп.
13  Общая площадь здания
14  Состояние
15  Ветхий
16  Исправный
17  Аварийный*/
       
 end if;


 END rep_stat;

procedure rep_detail(p_cd in varchar2, p_mg in params.period%type, p_lsk in kart.lsk%type,
                       prep_refcursor in out rep_refcursor) is
begin
--дочерний датасет в мастер-детали на форме Form_olap
if p_cd='83' then
 --1-ый датасет для отчета по нормативам, расценкам, поквартирно
 open prep_refcursor for
'select t.lsk, t.mg, u.usl, u.npp, u.nm2, t.cnt, u.ed_izm,
  case when t.limit is not null then to_char(t.limit)
    else to_char(t.val_group2) end as val_group2, t.cena
  from STATISTICS_LSK t, usl u, usl u2 where t.mg=:p_mg and t.lsk=:p_lsk
  /*and t.usl(+)=u.usl and t.usl=u2.fk_usl_chld(+)*/
  and t.usl=u.usl and u.fk_usl_chld=u2.usl(+)
  and u.cd in (''кап.'', ''г.вода'', ''х.вода'', ''х.вода.ОДН'',
   ''г.вода.ОДН'', ''эл.энерг.2'', ''эл.эн.ОДН'', ''найм'', ''канализ'')
--  and t.cnt is not null
--  group by t.lsk, u.usl, u.nm2, u.ed_izm, u.npp
  order by t.lsk, u.npp'
  using p_mg, p_lsk;
end if;

end;


PROCEDURE SQLTofile(p_sql IN VARCHAR2,
                    p_dir IN VARCHAR2,
                    p_header_file IN VARCHAR2,
                    p_data_file IN VARCHAR2 := NULL,
                    p_dlmt IN Varchar2 :=';' --разделитель, по умолчанию - ';'
                    ) IS
  v_finaltxt  VARCHAR2(4000);
  v_v_val     VARCHAR2(4000);
  v_n_val     NUMBER;
  v_d_val     DATE;
  v_ret       NUMBER;
  c           NUMBER;
  d           NUMBER;
  col_cnt     INTEGER;
  f           BOOLEAN;
  rec_tab     DBMS_SQL.DESC_TAB;
  col_num     NUMBER;
  v_fh        UTL_FILE.FILE_TYPE;
  v_samefile  BOOLEAN := (NVL(p_data_file,p_header_file) = p_header_file);
BEGIN
  --выгружает результат SQL в файл
  c := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(c, p_sql, DBMS_SQL.NATIVE);
  d := DBMS_SQL.EXECUTE(c);
  DBMS_SQL.DESCRIBE_COLUMNS(c, col_cnt, rec_tab);
  FOR j in 1..col_cnt
  LOOP
    CASE rec_tab(j).col_type
      WHEN 1 THEN DBMS_SQL.DEFINE_COLUMN(c,j,v_v_val,2000);
      WHEN 2 THEN DBMS_SQL.DEFINE_COLUMN(c,j,v_n_val);
      WHEN 12 THEN DBMS_SQL.DEFINE_COLUMN(c,j,v_d_val);
    ELSE
      DBMS_SQL.DEFINE_COLUMN(c,j,v_v_val,2000);
    END CASE;
  END LOOP;
  -- This part outputs the HEADER
  v_fh := UTL_FILE.FOPEN(upper(p_dir),p_header_file,'w',32767);
  FOR j in 1..col_cnt
  LOOP
    v_finaltxt := ltrim(v_finaltxt||p_dlmt||lower(rec_tab(j).col_name),p_dlmt);
  END LOOP;
  --  DBMS_OUTPUT.PUT_LINE(v_finaltxt);
  UTL_FILE.PUT_LINE(v_fh, v_finaltxt);
  IF NOT v_samefile THEN
    UTL_FILE.FCLOSE(v_fh);
  END IF;
  --
  -- This part outputs the DATA
  IF NOT v_samefile THEN
    v_fh := UTL_FILE.FOPEN(upper(p_dir),p_data_file,'w',32767);
  END IF;
  LOOP
    v_ret := DBMS_SQL.FETCH_ROWS(c);
    EXIT WHEN v_ret = 0;
    v_finaltxt := NULL;
    FOR j in 1..col_cnt
    LOOP
      CASE rec_tab(j).col_type
        WHEN 1 THEN DBMS_SQL.COLUMN_VALUE(c,j,v_v_val);
                    v_finaltxt := ltrim(v_finaltxt||p_dlmt||''||v_v_val||'',p_dlmt);
        WHEN 2 THEN DBMS_SQL.COLUMN_VALUE(c,j,v_n_val);
                    v_finaltxt := ltrim(v_finaltxt||p_dlmt||v_n_val,p_dlmt);
        WHEN 12 THEN DBMS_SQL.COLUMN_VALUE(c,j,v_d_val);
                    v_finaltxt := ltrim(v_finaltxt||p_dlmt||to_char(v_d_val,'DD/MM/YYYY HH24:MI:SS'), p_dlmt);
      ELSE
        DBMS_SQL.COLUMN_VALUE(c,j,v_v_val);
        v_finaltxt := ltrim(v_finaltxt||p_dlmt||''||v_v_val||'',p_dlmt);
      END CASE;
    END LOOP;
    UTL_FILE.PUT_LINE(v_fh, v_finaltxt);
  END LOOP;
  UTL_FILE.FCLOSE(v_fh);
  DBMS_SQL.CLOSE_CURSOR(c);
END;
END stat;
/


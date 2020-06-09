create or replace package scott.scripts3 is
  TYPE type_saldo_usl IS table of saldo_usl%rowtype;
  t_tab_corr type_saldo_usl;
  procedure dist_saldo_polis;
  procedure dist_saldo_PEN_polis;
  procedure swap_chrg_pay_by_one_org;
end scripts3;
/

create or replace package body scott.scripts3 is

  -- рабочий скрипт равномерного распределени€ кредита по дебету в сальдо
  -- использу€ коэффициент и корректировку ошибки
  -- ред.25.12.18
  procedure dist_saldo_polis is
    l_mg           params.period%type;
    l_mg3          params.period%type;
    l_user         number;
    l_id           number;
    l_cd           c_change_docs.text%type;
    l_mgchange     c_change_docs.mgchange%type;
    l_dt           date;
    l_kr           number;
    l_kr2          number;
    l_deb          number;
    l_coeff        number;
    l_coeff2       number;
    l_itg_kr       number;
    l_itg_db       number;
    l_corr_kr      number;
    l_corr_deb     number;
    l_diff         number;
    l_flag_dist    boolean;
    i              number;
    l_last_kr_usl  usl.usl%type;
    l_last_kr_org  number;
    l_last_deb_usl usl.usl%type;
    l_last_deb_org number;
  
    l_last_kr_usl_zero  usl.usl%type;
    l_last_kr_org_zero  number;
    l_last_deb_usl_zero usl.usl%type;
    l_last_deb_org_zero number;
    l_last_kr_max       number;
    l_last_deb_max      number;
  begin
    l_mg       := '202005'; --тек.период
    l_cd       := 'dist_saldo_polis_202005';
    l_mgchange := l_mg;
    l_dt       := to_date('20200526', 'YYYYMMDD');
    l_mg3      := utils.add_months_pr(l_mg, 1); --мес€ц вперед, если надо по исх сальдо
  
    --l_mg3 := l_mg; -- сальдо - вх.на текущий мес€ц
  
    dbms_output.enable(2000000);
  
    select t.id into l_user from t_user t where t.cd = 'SCOTT';
    select changes_id.nextval into l_id from dual;
  
    delete from t_corrects_payments t
     where mg = l_mg
       and exists (select *
              from c_change_docs d
             where d.cd_tp = l_cd
               and d.id = t.fk_doc);
  
    delete from c_change_docs t
     where t.user_id = l_user
       and t.cd_tp = l_cd;
  
    insert into c_change_docs
      (id, mgchange, dtek, ts, user_id, cd_tp)
      select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd from dual;
  
    for c in (select distinct s.lsk, s.mg
                from saldo_usl_script s
                join usl u2
                  on s.mg = l_mg3
                 and s.usl = u2.usl
                 and s.summa < 0 --есть кредит
                    --and s.lsk='06005556'
                 and exists (select t.*
                        from saldo_usl_script t -- где есть дебет.сальдо по другим услугам
                       where t.mg = s.mg
                         and t.lsk = s.lsk
                         and t.summa > 0)
              /*and exists ( -- условие (ѕолыс), только по основным лс, где есть –—ќ счет
              select k.lsk from kart k where k.lsk=s.lsk and
                  k.psch not in (8,9) and k.fk_tp=673012
                  and exists (select * from kart k2 where k2.k_lsk_id=k.k_lsk_id
                  and k2.fk_tp=3861849)
              
                  and not exists (select * from c_penya p 
                  where p.lsk=k.lsk and p.mg1<'201812' and p.summa > 0)
                  and exists (select * from saldo_usl t where t.mg='201901'
                  and t.lsk=k.lsk and t.usl in ('007','056','015','058'))
                  )*/
              ) loop
    
      --найти абс кред и деб сальдо
      select abs(nvl(sum(case
                           when t.summa < 0 then
                            t.summa
                           else
                            0
                         end),
                     0)),nvl(sum(case
                       when t.summa > 0 then
                        t.summa
                       else
                        0
                     end),
                 0)
        into l_kr, l_deb
        from saldo_usl_script t
       where t.mg = c.mg
         and t.lsk = c.lsk;
    
      --ограничить кредит сумму по дебет.сальдо
      if l_kr > l_deb then
        l_kr2 := l_deb;
      else
        l_kr2 := l_kr;
      end if;
    
      -- найти коэфф ограничени€ сн€ти€ с кредита
      l_coeff2 := l_kr2 / l_kr;
    
      -- найти коэфф установки на дебет
      l_coeff := l_kr2 / l_deb;
    
      l_last_kr_usl  := null;
      l_last_kr_org  := null;
      l_last_deb_usl := null;
      l_last_deb_org := null;
    
      l_last_kr_usl_zero  := null;
      l_last_kr_org_zero  := null;
      l_last_deb_usl_zero := null;
      l_last_deb_org_zero := null;
    
      l_last_kr_max  := 0;
      l_last_deb_max := 0;
      --сн€ть с кредита
      l_corr_kr := 0;
      for c2 in (select t.lsk, t.usl, t.org, abs(t.summa) as sal, round(abs(t.summa) *
                               l_coeff2,
                               2) as summa
                   from saldo_usl_script t
                  where t.mg = c.mg
                    and t.summa < 0
                    and t.lsk = c.lsk
                    and t.summa * l_coeff2 <> 0) loop
      
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lsk, c2.usl, c2.org, -1 * c2.summa, uid, l_dt, l_mg, l_mg, l_id, 1 as var
            from dual;
        l_corr_kr := l_corr_kr + c2.summa;
        if c2.sal - 1 * c2.summa > 0 and
           l_last_kr_max < c2.sal - 1 * c2.summa then
          l_last_kr_max := c2.sal - 1 * c2.summa;
          l_last_kr_usl := c2.usl;
          l_last_kr_org := c2.org;
        end if;
        if c2.sal - 1 * c2.summa = 0 then
          l_last_kr_usl_zero := c2.usl;
          l_last_kr_org_zero := c2.org;
        end if;
      end loop;
    
      --сн€ть с дебета
      l_corr_deb := 0;
      for c2 in (select t.lsk, t.usl, t.org, t.summa as sal, round(t.summa *
                               l_coeff,
                               2) as summa
                   from saldo_usl_script t
                  where t.mg = c.mg
                    and t.summa > 0
                    and t.lsk = c.lsk
                    and t.summa * l_coeff <> 0) loop
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
          select c.lsk, c2.usl, c2.org, -1 * c2.summa, uid, l_dt, l_mg, l_mg, l_id, 2 as var
            from dual;
        l_corr_deb := l_corr_deb + c2.summa;
        if c2.sal - 1 * c2.summa > 0 and
           l_last_deb_max < c2.sal - 1 * c2.summa then
          l_last_deb_max := c2.sal - 1 * c2.summa;
          l_last_deb_usl := c2.usl;
          l_last_deb_org := c2.org;
        end if;
        if c2.sal - 1 * c2.summa = 0 then
          l_last_deb_usl_zero := c2.usl;
          l_last_deb_org_zero := c2.org;
        end if;
      end loop;
    
      if l_kr < l_deb then
        if l_corr_kr <> l_kr then
          -- некорректны корректировки по кредиту
          l_diff := l_kr - l_corr_kr;
          if l_last_kr_usl is null then
            --Raise_application_error(-20000, 'usl is null lsk='||c.lsk);
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_kr_usl_zero, l_last_kr_org_zero, -1 *
                      l_diff, uid, l_dt, l_mg, l_mg, l_id, 1 as var, 1 as iter
                from dual;
          else
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_kr_usl, l_last_kr_org, -1 * l_diff, uid, l_dt, l_mg, l_mg, l_id, 1 as var, 1 as iter
                from dual;
          end if;
        end if;
      
        if l_corr_deb <> l_kr then
          -- некорректны корректировки по дебету
          l_diff := l_kr - l_corr_deb;
          if l_last_deb_usl is null then
            --Raise_application_error(-20000, 'usl is null lsk='||c.lsk);
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_deb_usl_zero, l_last_deb_org_zero, -1 *
                      l_diff, uid, l_dt, l_mg, l_mg, l_id, 2 as var, 1 as iter
                from dual;
          else
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_deb_usl, l_last_deb_org, -1 * l_diff, uid, l_dt, l_mg, l_mg, l_id, 2 as var, 1 as iter
                from dual;
          end if;
        end if;
      
      else
      
        if l_corr_kr <> l_deb then
          -- некорректны корректировки по кредиту
          l_diff := l_deb - l_corr_kr;
          if l_last_kr_usl is null then
            --Raise_application_error(-20000, 'usl is null lsk='||c.lsk);
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_kr_usl_zero, l_last_kr_org_zero, -1 *
                      l_diff, uid, l_dt, l_mg, l_mg, l_id, 1 as var, 1 as iter
                from dual;
          else
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_kr_usl, l_last_kr_org, -1 * l_diff, uid, l_dt, l_mg, l_mg, l_id, 1 as var, 1 as iter
                from dual;
          end if;
        end if;
      
        if l_corr_deb <> l_deb then
          -- некорректны корректировки по дебету
          l_diff := l_deb - l_corr_deb;
          if l_last_deb_usl is null then
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_deb_usl_zero, l_last_deb_org_zero, -1 *
                      l_diff, uid, l_dt, l_mg, l_mg, l_id, 2 as var, 1 as iter
                from dual;
          else
            --Raise_application_error(-20000, 'usl is null lsk='||c.lsk);
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, l_last_deb_usl, l_last_deb_org, -1 * l_diff, uid, l_dt, l_mg, l_mg, l_id, 2 as var, 1 as iter
                from dual;
          end if;
        end if;
      
      end if;
    
    -- проверить, сн€лось ли нужное с дебета
    /*  l_diff:=l_corr_deb - l_corr_kr;
      i:=0;
      l_flag_dist:=true;  
      while l_diff<>0 and l_flag_dist=true loop
          l_flag_dist:=false;  
          for c2 in (select usl, org, sum(summa) as summa from
            (select t.usl, t.org, abs(t.summa) as summa
                from saldo_usl_script t where t.mg=c.mg and
                 t.lsk=c.lsk and t.summa > 0
            union all
            select t.usl, t.org, t.summa
                from t_corrects_payments t where t.fk_doc=l_id
                and t.lsk=c.lsk and t.var=2)
            group by usl, org
            having sum(summa)<>0) loop
            if c2.summa<>0 then
              null;
            end if;
            l_flag_dist:=true;  
            -- сн€ть/поставить разницу
            insert into t_corrects_payments
              (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var, iter)
              select c.lsk, c2.usl, c2.org, sign(l_diff)*0.01, uid, l_dt, l_mg, l_mg, l_id, 2 as var, 2 as iter
                 from dual;
            l_diff:=l_diff - sign(l_diff)*0.01;
            if l_diff=0 then
              exit;
            end if;
          end loop;
        i:=i+1;
        if i> 1000 then
          Raise_application_error(-20000, 'ќшибка #1 распределени€ в лс='||c.lsk);
        end if;
      end loop;*/
    
    -- не распределилось, так как весь дебет = 0, поставить на последнюю запись
    end loop;
  
    update t_corrects_payments t
       set t.summa = -1 * t.summa
     where t.fk_doc = l_id
       and t.var = 2;
    commit;
  
  end dist_saldo_polis;


  -- рабочий скрипт равномерного распределени€ кредита по дебету по ѕ≈Ќ≈
  -- использу€ коэффициент и корректировку ошибки
  -- ред.21.11.2019
  procedure dist_saldo_PEN_polis is
    l_mg           params.period%type;
    l_mg3          params.period%type;
    l_user         number;
    l_id           number;
    l_cd           c_change_docs.text%type;
    l_mgchange     c_change_docs.mgchange%type;
    l_dt           date;
    l_kr           number;
    l_kr2          number;
    l_deb          number;
    l_coeff        number;
    l_coeff2       number;
    l_itg_kr       number;
    l_itg_db       number;
    l_corr_kr      number;
    l_corr_deb     number;
    l_diff         number;
    l_flag_dist    boolean;
    i              number;
    l_last_kr_usl  usl.usl%type;
    l_last_kr_org  number;
    l_last_deb_usl usl.usl%type;
    l_last_deb_org number;
  
    l_last_kr_usl_zero  usl.usl%type;
    l_last_kr_org_zero  number;
    l_last_deb_usl_zero usl.usl%type;
    l_last_deb_org_zero number;
    l_last_kr_max       number;
    l_last_deb_max      number;
  begin
    l_mg       := '202005'; --тек.период
    l_cd       := 'dist_pen_polis_202005';
    l_mgchange := l_mg;
    l_dt       := to_date('20200526', 'YYYYMMDD');
    l_mg3      := '202005';
  
    --l_mg3 := l_mg; -- сальдо - вх.на текущий мес€ц
  
    dbms_output.enable(2000000);
  
    select t.id into l_user from t_user t where t.cd = 'SCOTT';
    select changes_id.nextval into l_id from dual;
  
    delete from c_pen_corr t
     where exists (select *
              from c_change_docs d
             where d.cd_tp = l_cd
               and d.id = t.fk_doc);
  
    delete from c_change_docs t
     where t.user_id = l_user
       and t.cd_tp = l_cd;
  
    insert into c_change_docs
      (id, mgchange, dtek, ts, user_id, cd_tp)
      select l_id as id, l_mgchange, l_dt, sysdate, l_user, l_cd from dual;
  
    for c in (select distinct s.lsk, s.mg
                from xitog3_lsk_script s
                join usl u2
                  on s.mg = l_mg3
                 and s.usl = u2.usl
                 and s.poutsal < 0 --есть кредит по пене
                 and exists (select t.*
                        from xitog3_lsk_script t -- где есть дебет.пени по другим услугам
                       where t.mg = s.mg
                         and t.lsk = s.lsk
                         and t.poutsal > 0)
              ) loop
    
      --найти абс кред и деб сальдо по пене
      select abs(nvl(sum(case
                           when t.poutsal < 0 then
                            t.poutsal
                           else
                            0
                         end),
                     0)),nvl(sum(case
                       when t.poutsal > 0 then
                        t.poutsal
                       else
                        0
                     end),
                 0)
        into l_kr, l_deb
        from xitog3_lsk_script t
       where t.mg = c.mg
         and t.lsk = c.lsk;
    
      --ограничить кредит сумму по дебет.сальдо
      if l_kr > l_deb then
        l_kr2 := l_deb;
      else
        l_kr2 := l_kr;
      end if;
    
      -- найти коэфф ограничени€ сн€ти€ с кредита
      l_coeff2 := l_kr2 / l_kr;
    
      -- найти коэфф установки на дебет
      l_coeff := l_kr2 / l_deb;
    
      l_last_kr_usl  := null;
      l_last_kr_org  := null;
      l_last_deb_usl := null;
      l_last_deb_org := null;
    
      l_last_kr_usl_zero  := null;
      l_last_kr_org_zero  := null;
      l_last_deb_usl_zero := null;
      l_last_deb_org_zero := null;
    
      l_last_kr_max  := 0;
      l_last_deb_max := 0;
      --сн€ть с кредита
      l_corr_kr := 0;
      for c2 in (select t.lsk, t.usl, t.org, abs(t.poutsal) as sal, round(abs(t.poutsal) *
                               l_coeff2,
                               2) as poutsal
                   from xitog3_lsk_script t
                  where t.mg = c.mg
                    and t.poutsal < 0
                    and t.lsk = c.lsk
                    and t.poutsal * l_coeff2 <> 0) loop
      
        insert into c_pen_corr
          (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
          select c.lsk, c2.usl, c2.org, -1 * c2.poutsal, l_user, l_dt, l_mg, l_id, 1 as var
            from dual;
        l_corr_kr := l_corr_kr + c2.poutsal;
        if c2.sal - 1 * c2.poutsal > 0 and
           l_last_kr_max < c2.sal - 1 * c2.poutsal then
          l_last_kr_max := c2.sal - 1 * c2.poutsal;
          l_last_kr_usl := c2.usl;
          l_last_kr_org := c2.org;
        end if;
        if c2.sal - 1 * c2.poutsal = 0 then
          l_last_kr_usl_zero := c2.usl;
          l_last_kr_org_zero := c2.org;
        end if;
      end loop;
    
      --сн€ть с дебета
      l_corr_deb := 0;
      for c2 in (select t.lsk, t.usl, t.org, t.poutsal as sal, round(t.poutsal *
                               l_coeff,
                               2) as poutsal
                   from xitog3_lsk_script t
                  where t.mg = c.mg
                    and t.poutsal > 0
                    and t.lsk = c.lsk
                    and t.poutsal * l_coeff <> 0) loop
        insert into c_pen_corr
          (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
          select c.lsk, c2.usl, c2.org, -1 * c2.poutsal, l_user, l_dt, l_mg, l_id, 2 as var
            from dual;
        l_corr_deb := l_corr_deb + c2.poutsal;
        if c2.sal - 1 * c2.poutsal > 0 and
           l_last_deb_max < c2.sal - 1 * c2.poutsal then
          l_last_deb_max := c2.sal - 1 * c2.poutsal;
          l_last_deb_usl := c2.usl;
          l_last_deb_org := c2.org;
        end if;
        if c2.sal - 1 * c2.poutsal = 0 then
          l_last_deb_usl_zero := c2.usl;
          l_last_deb_org_zero := c2.org;
        end if;
      end loop;
    
      if l_kr < l_deb then
        if l_corr_kr <> l_kr then
          -- некорректны корректировки по кредиту
          l_diff := l_kr - l_corr_kr;
          if l_last_kr_usl is null then
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_kr_usl_zero, l_last_kr_org_zero, -1 *
                      l_diff, l_user, l_dt, l_mg, l_id, 1 as var
                from dual;
          else
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_kr_usl, l_last_kr_org, -1 * l_diff, l_user, l_dt, l_mg, l_id, 1 as var
                from dual;
          end if;
        end if;
      
        if l_corr_deb <> l_kr then
          -- некорректны корректировки по дебету
          l_diff := l_kr - l_corr_deb;
          if l_last_deb_usl is null then
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_deb_usl_zero, l_last_deb_org_zero, -1 *
                      l_diff, l_user, l_dt, l_mg, l_id, 2 as var
                from dual;
          else
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_deb_usl, l_last_deb_org, -1 * l_diff, l_user, l_dt, l_mg, l_id, 2 as var
                from dual;
          end if;
        end if;
      
      else
      
        if l_corr_kr <> l_deb then
          -- некорректны корректировки по кредиту
          l_diff := l_deb - l_corr_kr;
          if l_last_kr_usl is null then
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_kr_usl_zero, l_last_kr_org_zero, -1 *
                      l_diff, l_user, l_dt, l_mg, l_id, 1 as var
                from dual;
          else
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_kr_usl, l_last_kr_org, -1 * l_diff, l_user, l_dt, l_mg, l_id, 1 as var
                from dual;
          end if;
        end if;
      
        if l_corr_deb <> l_deb then
          -- некорректны корректировки по дебету
          l_diff := l_deb - l_corr_deb;
          if l_last_deb_usl is null then
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_deb_usl_zero, l_last_deb_org_zero, -1 *
                      l_diff, l_user, l_dt, l_mg, l_id, 2 as var
                from dual;
          else
            insert into c_pen_corr
              (lsk, usl, org, penya, fk_user, dtek, dopl, fk_doc, var)
              select c.lsk, l_last_deb_usl, l_last_deb_org, -1 * l_diff, l_user, l_dt, l_mg, l_id, 2 as var
                from dual;
          end if;
        end if;
      end if;
    end loop;
  
    update c_pen_corr t
       set t.penya = -1 * t.penya
     where t.fk_doc = l_id
       and t.var = 2;
       
    -- перевернуть знак в конце   
    update c_pen_corr t
       set t.penya = -1 * t.penya
     where t.fk_doc = l_id;

    commit;
  
  end dist_saldo_PEN_polis;

  -- перенести начисление и оплату по одной орг
  procedure swap_chrg_pay_by_one_org is
    l_cd   varchar2(50);
    l_mg   varchar2(6);
    l_dt   date;
    l_user number;
    l_id   number;
  begin
    l_mg := '201908'; --тек.период
    l_cd := 'swap_chrg_pay_by_one_org_20190827';
    l_dt := to_date('20190827', 'YYYYMMDD');
  
    select t.id into l_user from t_user t where t.cd = 'SCOTT';
    select changes_id.nextval into l_id from dual;
  
    delete from t_corrects_payments t
     where mg = l_mg
       and exists (select *
              from c_change_docs d
             where d.cd_tp = l_cd
               and d.id = t.fk_doc);
  
    delete from c_change t
     where exists (select *
              from c_change_docs d
             where d.cd_tp = l_cd
               and d.id = t.doc_id);
  
    delete from c_change_docs t
     where t.user_id = l_user
       and t.cd_tp = l_cd;
  
    insert into c_change_docs
      (id, mgchange, dtek, ts, user_id, cd_tp)
      select l_id as id, l_mg, l_dt, sysdate, l_user, l_cd from dual;
  
    for c in (select t.lsk as lsk_src, t.usl, t.org, k2.lsk as lsk_dst, t.mg, t.charges, t.payment
                from xitog3_lsk t
                join kart k
                  on k.lsk = t.lsk
                 and k.reu = '002'
                join kart k2
                  on k.k_lsk_id = k2.k_lsk_id
                 and k2.reu = '016'
                 and k2.lsk <> k.lsk
               where t.mg between '201905' and '201907'
                 and t.usl = '092'
                 and exists (select *
                        from kart k
                       where k.lsk = t.lsk
                         and k.house_id in( 36950,36949,36934,36935,36943,37134,37136,36951,36945,36987,36988,40106,40126,36952,36940,36946,36941,36948,37505,36947,36942,39305,39325,38798)
                         --and k.k_lsk_id = 395744
                         )
               order by t.mg) loop
    
      if nvl(c.charges, 0) <> 0 then
        -- начисление
        -- сн€ть
        insert into c_change
          (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id, doc_id)
        values
          (c.lsk_src, c.usl, c.org, -1 * c.charges, c.mg, '999', 0, l_dt, sysdate, l_user, l_id);
        -- поставить
        insert into c_change
          (lsk, usl, org, summa, mgchange, nkom, type, dtek, ts, user_id, doc_id)
        values
          (c.lsk_dst, c.usl, 11, c.charges, c.mg, '999', 0, l_dt, sysdate, l_user, l_id);
      end if;
    
      if nvl(c.payment, 0) <> 0 then
        -- оплата
        -- сн€ть
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        values
          (c.lsk_src, c.usl, c.org, -1 * c.payment, l_user, l_dt, l_mg, c.mg, l_id, 0);
      
        -- поставить
        insert into t_corrects_payments
          (lsk, usl, org, summa, user_id, dat, mg, dopl, fk_doc, var)
        values
          (c.lsk_dst, c.usl, 11, c.payment, l_user, l_dt, l_mg, c.mg, l_id, 0);
      end if;
    end loop;
  
    commit;
  
  end;

end scripts3;
/


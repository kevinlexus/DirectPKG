create or replace package body scott.c_prep is

  procedure dist_summa is
    l_summa        number;
    l_summa2       number;
    l_summa_r      number;
    l_summa_kr     number;
    l_summa_kr_tst number;
    l_summa_itg_dt number;
    l_proc         number;
    l_flag_r       number;
    --l_id number;
    --l_id2 number;
    l_id3   number;
    l_id4   number;
    l_round number;
  begin
    --Процедура - сложить все отрицательные значения
    --с положительными (пропорционально)
    --формирование исходящей таблицы корректировок
    --а так же исходящей таблицы значений закрытия сумм
    --На вход - отправить значения в TEMP_PREP!
    delete from temp_prep t where t.tp_cd not in (0);
    --формируем сразу исх.значения
    /*insert into temp_prep
      (usl, org, summa, tp_cd)
    select usl, org, summa, 1 from
    temp_prep;*/
  
    select nvl(sum(case
                     when t.summa > 0 then
                      0
                     else
                      t.summa
                   end),
               0),
           nvl(sum(case
                     when t.summa < 0 then
                      0
                     else
                      t.summa
                   end),
               0)
      into l_summa, l_summa2
      from temp_prep t
     where t.tp_cd = 0;
    if l_summa = 0 or l_summa2 = 0 then
      --распределять нечего или не куда
      --просто переписываем исх данные
      insert into temp_prep
        (usl, org, summa, tp_cd)
        select usl, org, summa, 1 as tp_cd
          from temp_prep t
         where t.tp_cd = 0;
      return;
    end if;
  
    select case
             when sum(t.summa) / abs(l_summa) > 1 then
              1
             else
              sum(t.summa) / abs(l_summa)
           end
      into l_proc --% отношения кр/деб
      from temp_prep t
     where t.tp_cd = 0
       and t.summa > 0;
  
    --l_id:=null;
    --l_id2:=null;
    l_id3 := null;
    l_id4 := null;
  
    for c_kr in (select round(t.summa * l_proc, 7) as summa, t.org, t.usl
                   from temp_prep t
                  where t.tp_cd = 0
                    and round(t.summa * l_proc, 7) < 0
                  order by t.usl, t.org) loop
      l_summa_kr     := c_kr.summa;
      l_summa_kr_tst := 0;
      select nvl(sum(t.summa), 0)
        into l_summa_itg_dt
        from temp_prep t
       where t.tp_cd = 0
         and t.summa > 0;
    
      if l_summa_itg_dt > 0 then
        for c_deb in (select t.summa as dddd,
                             case
                               when round(abs(l_summa_kr) * t.summa /
                                          l_summa_itg_dt,
                                          7) >= t.summa then
                                t.summa
                               else
                                round(abs(l_summa_kr) * t.summa /
                                      l_summa_itg_dt,
                                      7)
                             end as summa, t.usl, t.org
                        from temp_prep t
                       where t.tp_cd = 0
                         and t.summa > 0
                       order by t.usl, t.org) loop
          if c_deb.summa > 0 then
            insert into temp_prep
              (usl, org, summa, tp_cd)
            values --снимаем с кредита
              (c_kr.usl, c_kr.org, c_deb.summa, 2);
            --          return id into l_id;
            insert into temp_prep
              (usl, org, summa, tp_cd)
            values --ставим на дебет
              (c_deb.usl, c_deb.org, -1 * c_deb.summa, 2);
            --          return id into l_id2;
            /*          if abs(c_deb.summa) > 0.01 then
                --запомнить id для округления
                  l_id3:=l_id;
                  l_id4:=l_id2;
            end if;  */
            l_summa_kr_tst := l_summa_kr_tst - c_deb.summa;
            --         l_summa_r:=l_summa_r-c_deb.summa;
            if l_summa_kr_tst <= l_summa_kr then
              --выход из цикла, когда сумма распределилась
              exit;
            end if;
          end if;
        end loop;
      end if;
    
    end loop;
  
    --корректировки округленные
    insert into temp_prep
      (usl, org, summa, tp_cd)
      select usl, org, round(sum(summa), 2), 3 as tp_cd
        from temp_prep t
       where t.tp_cd = 2
       group by usl, org, mg;
  
    -- исх. суммы
    insert into temp_prep
      (usl, org, summa, tp_cd)
      select usl, org, sum(summa), 1 as tp_cd
        from (select usl, org, summa
                 from temp_prep t
                where t.tp_cd = 0
               union all
               select usl, org, summa
                 from temp_prep t
                where t.tp_cd = 3)
       group by usl, org
      having sum(summa) <> 0;
  
    --округление
    select a.summa - b.summa
      into l_summa_r
      from (select nvl(sum(t.summa), 0) as summa
               from temp_prep t
              where t.tp_cd = 0) a,
           (select nvl(sum(t.summa), 0) as summa
               from temp_prep t
              where t.tp_cd = 1) b;
  
    --COMMIT;
  
    --попытаться округлить по отриц.значению
    l_flag_r := 0;
    if l_summa_r <> 0 then
      l_flag_r := 1;
      for c in (select t.usl, t.org, abs(t.summa) as summa
                  from temp_prep t
                 where t.tp_cd = 1
                   and t.summa < 0
                --                and exists (select * from temp_prep p where p.tp_cd=3 and p.usl=t.usl and p.org=t.org and p.summa<>0) --и чтоб была корректировка!
                ) loop
        if abs(l_summa_r) > c.summa then
          insert into temp_prep
            (usl, org, summa, tp_cd)
          values
            (c.usl, c.org, sign(l_summa_r) * c.summa, 4);
          l_summa_r := l_summa_r - sign(l_summa_r) * c.summa;
        else
          insert into temp_prep
            (usl, org, summa, tp_cd)
          values
            (c.usl, c.org, l_summa_r, 4);
          l_summa_r := 0;
          exit;
        end if;
      end loop;
    
      --не нашли отрицательные, попытаться округлить по положит.значению
      if l_summa_r <> 0 then
        for c in (select t.usl, t.org, abs(t.summa) as summa
                    from temp_prep t
                   where t.tp_cd = 1
                     and t.summa > 0
                  --                and exists (select * from temp_prep p where p.tp_cd=3 and p.usl=t.usl and p.org=t.org and p.summa<>0) --и чтоб была корректировка!
                  ) loop
          if abs(l_summa_r) > c.summa then
            insert into temp_prep
              (usl, org, summa, tp_cd)
            values
              (c.usl, c.org, sign(l_summa_r) * c.summa, 4);
            l_summa_r := l_summa_r - (sign(l_summa_r) * c.summa);
          else
            insert into temp_prep
              (usl, org, summa, tp_cd)
            values
              (c.usl, c.org, l_summa_r, 4);
            l_summa_r := 0;
            exit;
          end if;
        end loop;
      end if;
    
      if l_summa_r > 0 then
        --если нет записей после округления
        --(бывает когда значения близки к 0.01)
        --и сумма > 0
        insert into temp_prep
          (usl, org, summa, tp_cd)
          select t.usl, t.org, l_summa_r as summa, 4
            from temp_prep t
           where t.rowid = (select max(rowid)
                              from temp_prep r
                             where r.summa > 0
                               and r.tp_cd = 0);
      elsif l_summa_r < 0 then
        --если нет записей после округления
        --(бывает когда значения близки к 0.01)
        --и сумма < 0
        insert into temp_prep
          (usl, org, summa, tp_cd)
          select t.usl, t.org, l_summa_r as summa, 4
            from temp_prep t
           where rowid = (select max(rowid)
                            from temp_prep r
                           where r.summa < 0
                             and r.tp_cd = 0);
      end if;
    
    end if;
  
    if l_flag_r = 1 then
      -- еще раз, исх. суммы, если было округление
      delete from temp_prep t where t.tp_cd = 1;
      insert into temp_prep
        (usl, org, summa, tp_cd)
        select usl, org, sum(summa), 1
          from (select usl, org, summa
                   from temp_prep t
                  where t.tp_cd = 0
                 union all
                 select usl, org, summa
                   from temp_prep t
                  where t.tp_cd = 3
                 union all
                 select usl, org, summa
                   from temp_prep t
                  where t.tp_cd = 4)
         group by usl, org
        having sum(summa) <> 0;
    end if;
  end;

  --Процедура - сложить все отрицательные значения
  --с положительными (пропорционально)
  --специализированна для распределения сальдо по месяцам задолжности!!!
  procedure dist_summa2 is
    l_summa        number;
    l_summa2       number;
    l_summa_r      number;
    l_summa_kr     number;
    l_summa_kr_tst number;
    l_summa_itg_dt number;
    l_proc         number;
    l_flag_r       number;
    --l_id number;
    --l_id2 number;
    l_id3   number;
    l_id4   number;
    l_round number;
  begin
    --формирование исходящей таблицы корректировок
    --а так же исходящей таблицы значений закрытия сумм
    --На вход - отправить значения в TEMP_PREP!
    delete from temp_prep t where t.tp_cd not in (0);
    --формируем сразу исх.значения
    /*insert into temp_prep
      (usl, org, summa, tp_cd)
    select usl, org, summa, 1 from
    temp_prep;*/
  
    select nvl(sum(case
                     when t.summa > 0 then
                      0
                     else
                      t.summa
                   end),
               0),
           nvl(sum(case
                     when t.summa < 0 then
                      0
                     else
                      t.summa
                   end),
               0)
      into l_summa, l_summa2
      from temp_prep t
     where t.tp_cd = 0;
    if l_summa = 0 or l_summa2 = 0 then
      --распределять нечего или не куда
      --просто переписываем исх данные
      insert into temp_prep
        (usl, org, summa, tp_cd, mg)
        select usl, org, summa, 1 as tp_cd, mg
          from temp_prep t
         where t.tp_cd = 0;
      return;
    end if;
  
    select case
             when sum(t.summa) / abs(l_summa) > 1 then
              1
             else
              sum(t.summa) / abs(l_summa)
           end
      into l_proc --% отношения кр/деб
      from temp_prep t
     where t.tp_cd = 0
       and t.summa > 0;
  
    --l_id:=null;
    --l_id2:=null;
    l_id3 := null;
    l_id4 := null;
  
    for c_kr in (select round(t.summa * l_proc, 7) as summa, t.org, t.usl
                   from temp_prep t
                  where t.tp_cd = 0
                    and round(t.summa * l_proc, 7) < 0
                  order by t.usl, t.org) loop
      l_summa_kr     := c_kr.summa;
      l_summa_kr_tst := 0;
      select nvl(sum(t.summa), 0)
        into l_summa_itg_dt
        from temp_prep t
       where t.tp_cd = 0
         and t.summa > 0;
    
      if l_summa_itg_dt > 0 then
        for c_deb in (select t.summa as dddd,
                             case
                               when round(abs(l_summa_kr) * t.summa /
                                          l_summa_itg_dt,
                                          7) >= t.summa then
                                t.summa
                               else
                                round(abs(l_summa_kr) * t.summa /
                                      l_summa_itg_dt,
                                      7)
                             end as summa, t.usl, t.org, t.mg
                        from temp_prep t
                       where t.tp_cd = 0
                         and t.summa > 0
                       order by t.usl, t.org) loop
          if c_deb.summa > 0 then
            insert into temp_prep
              (usl, org, summa, tp_cd)
            values --снимаем с кредита
              (c_kr.usl, c_kr.org, c_deb.summa, 2);
            insert into temp_prep
              (usl, org, summa, tp_cd, mg)
            values --ставим на дебет
              (c_kr.usl, c_kr.org, -1 * c_deb.summa, 2, c_deb.mg);
            /*          if abs(c_deb.summa) > 0.01 then
                --запомнить id для округления
                  l_id3:=l_id;
                  l_id4:=l_id2;
            end if;  */
            l_summa_kr_tst := l_summa_kr_tst - c_deb.summa;
            --         l_summa_r:=l_summa_r-c_deb.summa;
            if l_summa_kr_tst <= l_summa_kr then
              --выход из цикла, когда сумма распределилась
              exit;
            end if;
          end if;
        end loop;
      end if;
    
    end loop;
  
    --корректировки округленные
    insert into temp_prep
      (usl, org, summa, tp_cd, mg)
      select usl, org, round(sum(summa), 2), 3 as tp_cd, t.mg
        from temp_prep t
       where t.tp_cd = 2
       group by usl, org, mg;
  
    -- исх. суммы
    insert into temp_prep
      (usl, org, summa, tp_cd, mg)
      select usl, org, sum(summa), 1 as tp_cd, mg
        from (select usl, org, summa, mg
                 from temp_prep t
                where t.tp_cd = 0
               union all
               select usl, org, summa, mg
                 from temp_prep t
                where t.tp_cd = 3)
       group by usl, org, mg
      having sum(summa) <> 0;
  
    --округление
    select a.summa - b.summa
      into l_summa_r
      from (select nvl(sum(t.summa), 0) as summa
               from temp_prep t
              where t.tp_cd = 0) a,
           (select nvl(sum(t.summa), 0) as summa
               from temp_prep t
              where t.tp_cd = 1) b;
  
    --COMMIT;
  
    --попытаться округлить по отриц.значению
    l_flag_r := 0;
    if l_summa_r <> 0 then
      l_flag_r := 1;
      for c in (select t.usl, t.org, t.mg, abs(t.summa) as summa
                  from temp_prep t
                 where t.tp_cd = 1
                   and t.summa < 0) loop
        if abs(l_summa_r) > c.summa then
          insert into temp_prep
            (usl, org, summa, tp_cd, mg)
          values
            (c.usl, c.org, sign(l_summa_r) * c.summa, 4, c.mg);
          l_summa_r := l_summa_r - sign(l_summa_r) * c.summa;
        else
          insert into temp_prep
            (usl, org, summa, tp_cd, mg)
          values
            (c.usl, c.org, l_summa_r, 4, c.mg);
          l_summa_r := 0;
          exit;
        end if;
      end loop;
    
      --не нашли отрицательные, попытаться округлить по положит.значению
      if l_summa_r <> 0 then
        for c in (select t.usl, t.org, abs(t.summa) as summa, t.mg
                    from temp_prep t
                   where t.tp_cd = 1
                     and t.summa > 0) loop
          if abs(l_summa_r) > c.summa then
            insert into temp_prep
              (usl, org, summa, tp_cd, mg)
            values
              (c.usl, c.org, sign(l_summa_r) * c.summa, 4, c.mg);
            l_summa_r := l_summa_r - (sign(l_summa_r) * c.summa);
          else
            insert into temp_prep
              (usl, org, summa, tp_cd, mg)
            values
              (c.usl, c.org, l_summa_r, 4, c.mg);
            l_summa_r := 0;
            exit;
          end if;
        end loop;
      end if;
    
      if l_summa_r > 0 then
        --если нет записей после округления
        --(бывает когда значения близки к 0.01)
        --и сумма > 0
        insert into temp_prep
          (usl, org, summa, tp_cd, mg)
          select t.usl, t.org, l_summa_r as summa, 4, t.mg
            from temp_prep t
           where t.rowid = (select max(r.rowid)
                              from temp_prep r
                             where r.summa > 0
                               and r.tp_cd = 0);
      elsif l_summa_r < 0 then
        --если нет записей после округления
        --(бывает когда значения близки к 0.01)
        --и сумма < 0
        insert into temp_prep
          (usl, org, summa, tp_cd, mg)
          select t.usl, t.org, l_summa_r as summa, 4, t.mg
            from temp_prep t
           where t.rowid = (select max(r.rowid)
                              from temp_prep r
                             where r.summa < 0
                               and r.tp_cd = 0);
      end if;
    
    end if;
  
    if l_flag_r = 1 then
      -- еще раз, исх. суммы, если было округление
      delete from temp_prep t where t.tp_cd = 1;
      insert into temp_prep
        (usl, org, summa, tp_cd, mg)
        select usl, org, sum(summa), 1, mg
          from (select usl, org, summa, mg
                   from temp_prep t
                  where t.tp_cd = 0
                 union all
                 select usl, org, summa, mg
                   from temp_prep t
                  where t.tp_cd = 3
                 union all
                 select usl, org, summa, mg
                   from temp_prep t
                  where t.tp_cd = 4)
         group by usl, org, mg
        having sum(summa) <> 0;
    end if;
  end;

  --распределить сумму полностью (любой знак), пропорционально, по другим значениям
  function dist_summa_full(p_sum in number, t_summ in out tab_summ)
    return number is
    l_sum        number;
    l_max_sum    number;
    l_max_sum_id number;
    l_id         number;
    l_sum_itg    number;
    l_lst_fk_cd  varchar2(3);
    l_lst_fk_id  number;
    r_summ       rec_summ;
    l_sign       number;
  begin
    --на вход - массив значений >0  в temp_prep, параметр p_num
  
    l_sum := abs(nvl(p_sum, 0));
    if p_sum < 0 then
      l_sign := -1;
    else
      l_sign := 1;
    end if;
  
    l_sum_itg := 0;
    l_max_sum := 0;
    for c in (select t.fk_cd, t.fk_id, t.summa,
                     sum(t.summa) over(partition by 0) as summ_itg,
                     round(l_sum * t.summa / sum(t.summa)
                            over(partition by 0),
                            2) as summ_out
                from table(t_summ) t
               where t.tp = 0) loop
      if c.summ_out <> 0 then
      
        t_summ.extend;
        r_summ := rec_summ(fk_cd => c.fk_cd,
                           fk_id => c.fk_id,
                           summa => l_sign * c.summ_out,
                           tp    => 1);
        t_summ(t_summ.last) := r_summ;
        l_id := t_summ.last;
      
        --найти макс сумму, чтобы округлить на неё
        if c.summ_out >= l_max_sum then
          l_max_sum    := c.summ_out;
          l_max_sum_id := l_id;
        end if;
        l_sum_itg := l_sum_itg + /*l_sign**/
                     c.summ_out;
      end if;
      l_lst_fk_cd := c.fk_cd;
      l_lst_fk_id := c.fk_id;
    end loop;
  
    if l_sum between 0.01 and 0.06 and l_id is null and
       l_lst_fk_cd is not null then
      --входящяя сумма такая маленькая, чтобы распределить, то попытаться её добавить с последней услугой+орг
      t_summ.extend;
      r_summ := rec_summ(fk_cd => l_lst_fk_cd,
                         fk_id => l_lst_fk_id,
                         summa => p_sum,
                         tp    => 1);
      t_summ(t_summ.last) := r_summ;
    
    elsif l_sum not between 0.01 and 0.06 and l_id is null then
      --Нет записей для распределения суммы!
      raise_application_error(-20000, 'Ошибка c_prep #1');
      --  return 1;
    elsif abs(l_sum - l_sum_itg) > 0.50 then --было 0.07, сделал 0.50, так как бывают округления прям большие (по большому массиву чисел - набегает больше 7 копеек)
      --Слишком большое округление;
      raise_application_error(-20000, 'Ошибка c_prep #3');
      --  return 3;
    elsif abs(l_sum - l_sum_itg) <= 0.50 and l_max_sum_id is not null then
      --округлить
      t_summ(l_max_sum_id).summa := t_summ(l_max_sum_id)
                                    .summa + l_sign * (l_sum - l_sum_itg);
    else
      --бывает при p_sum=0.01
      --Нет записей для распределения суммы!
      raise_application_error(-20000, 'Ошибка c_prep #4');
      --  return 1;
    end if;
  
    --проверить
    select nvl(p_sum, 0) - nvl(sum(t.summa), 0)
      into l_sum_itg
      from table(t_summ) t
     where t.tp = 1;
    if l_sum_itg <> 0 then
      --Сумма распределена не корректно!
      raise_application_error(-20000, 'Ошибка c_prep #5');
      --  return 2;
    end if;
  
    return 0;
  
  end;

  --распределить сальдо по периодам задолжности (для переноса движения по лиц.счету)
procedure dist_summa3(p_lsk     in kart.lsk%type, --л.с.
                      p_mg      in params.period%type, --тек.период
                      p_mg_back in params.period%type --период на месяц назад
                      ) is
  l_summ      number;
  l_cnt       number;
  l_diff      number;
  l_diff_tmp  number;
  l_c_mg      params.period%type;
  l_check_mg  params.period%type;
  l_check_usl usl.usl%type;
  l_check_org number;
  l_flag      number;
  l_flag2     number;
begin

  select nvl(sum(t.summa), 0)
    into l_summ
    from v_chargepay t
   where t.lsk = p_lsk
     and t.period = p_mg_back;
  --обязательно почистить, так как при отсутствии распределения таблица должна быть пустая   
  delete from temp_prep t;

  if l_summ = 0 then
    --выйти, если нечего распределять
    return;
  end if;

  --распределение
  for c in (select t.summa / sum(t.summa) over(partition by 0) as proc,
                   sum(t.summa) over(partition by 0) as sum_itg, t.*
              from v_chargepay t
             where t.lsk = p_lsk
               and t.period = p_mg_back
               and summa <> 0) loop
  
    insert into temp_prep
      (usl, org, summa, mg)
      select s.usl, s.org, round(sum(s.summa) * c.proc, 2) as summa, c.mg
        from saldo_usl s
       where s.lsk = p_lsk
         and s.mg = p_mg
       group by s.usl, s.org;
  
  end loop;

  --округление    
  for d in 1 .. 1000 loop
    l_flag := 0;
    for c in (select a.usl, a.org, a.mg, a.summa, a.summ_part_mg,
                     a.summ_part_usl, b.summa as chr, d.summa as sal,
                     nvl(a.summ_part_mg, 0) - nvl(b.summa, 0) as diff_mg,
                     nvl(a.summ_part_usl, 0) - nvl(d.summa, 0) as diff_usl
                from (select t.usl, t.org, t.mg, t.summa,
                              sum(t.summa) over(partition by t.mg) as summ_part_mg,
                              sum(t.summa) over(partition by t.usl, t.org) as summ_part_usl
                         from temp_prep t) a
                left join (select t.mg, t.summa
                            from v_chargepay t
                           where t.lsk = p_lsk
                             and t.period = p_mg_back
                             and summa <> 0) b
                  on a.mg = b.mg
                left join (select s.usl, s.org, sum(s.summa) as summa
                            from saldo_usl s
                           where s.lsk = p_lsk
                             and s.mg = p_mg
                           group by s.usl, s.org) d
                  on a.usl = d.usl
                 and a.org = d.org
               where nvl(a.summ_part_mg, 0) - nvl(b.summa, 0) <> 0
                  or nvl(a.summ_part_usl, 0) - nvl(d.summa, 0) <> 0
               order by case
                          when sign(nvl(a.summ_part_mg, 0) - nvl(b.summa, 0)) =
                               sign(nvl(a.summ_part_usl, 0) - nvl(d.summa, 0)) and
                               nvl(a.summ_part_mg, 0) - nvl(b.summa, 0) <> 0 and
                               nvl(a.summ_part_usl, 0) - nvl(d.summa, 0) <> 0 then
                           0
                          else
                           1
                        end --сортировать чтобы были одинаковые знаками - первыми
              ) loop
      l_flag := 1; --распределяется
              
      if sign(c.diff_mg) = sign(c.diff_usl) and c.diff_mg <> 0 and
         c.diff_usl <> 0 then
        --с одним знаком и оба не идут - взаимо исключить
        l_diff := -1 * 0.01 * sign(c.diff_mg);
        insert into temp_prep
          (usl, org, mg, summa)
        values
          (c.usl, c.org, c.mg, l_diff);
      elsif c.diff_mg <> 0 and c.diff_usl = 0 then
        --не идёт только по mg
        --поправить сразу mg
        l_diff := -1 * 0.01 * sign(c.diff_mg);
        insert into temp_prep
          (usl, org, mg, summa)
        values
          (c.usl, c.org, c.mg, l_diff);
        -- найти с таким же usl и org другой период и поправить  
        insert into temp_prep
          (usl, org, mg, summa)
          select *
            from (select t.usl, t.org, t.mg, -1 * l_diff_tmp
                     from temp_prep t
                    where t.mg <> c.mg
                      and t.usl = c.usl
                      and t.org = c.org)
           where rownum = 1;
      elsif c.diff_usl <> 0 and c.diff_mg = 0 then
        --не идёт только по usl, org
        --поправить сразу usl
        l_diff := -1 * 0.01 * sign(c.diff_usl);
        insert into temp_prep
          (usl, org, mg, summa)
        values
          (c.usl, c.org, c.mg, l_diff);
        -- найти с таким же mg другой usl и org и поправить  
        insert into temp_prep
          (usl, org, mg, summa)
          select *
            from (select t.usl, t.org, t.mg, -1 * l_diff_tmp
                     from temp_prep t
                    where t.mg = c.mg
                      and t.usl <> c.usl
                      and t.org <> c.org)
           where rownum = 1;
      end if;
    
      exit;
    
    end loop;
  if l_flag = 0 then
    exit; --нечего распределять, выход
  end if;
  end loop;

  --проверка
  select count(*)
    into l_cnt
    from (select t.mg, t.summa
             from v_chargepay t
            where t.lsk = p_lsk
              and t.period = p_mg_back
              and summa <> 0) a
    full join (select t.mg, sum(t.summa) as summa
                 from temp_prep t
                group by t.mg) b
      on a.mg = b.mg
   where nvl(a.summa, 0) <> nvl(b.summa, 0);
  if l_cnt > 0 then
    raise_application_error(-20000,
                            'Ошибка распределения по периодам!');
  end if;

  select count(*)
    into l_cnt
    from (select t.usl, t.org, sum(t.summa) as summa
             from temp_prep t
            group by t.org, t.usl) a
    full join (select s.usl, s.org, sum(s.summa) as summa
                 from saldo_usl s
                where s.lsk = p_lsk
                  and s.mg = p_mg
                group by s.usl, s.org) b
      on a.usl = b.usl
     and a.org = b.org
   where nvl(a.summa, 0) <> nvl(b.summa, 0);
  if l_cnt > 0 then
    raise_application_error(-20000,
                            'Ошибка распределения по услугам!');
  end if;

end;

end c_prep;
/


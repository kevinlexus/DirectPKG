create or replace package body scott.gen is
  procedure gen_check (err_ out number, err_str_ out varchar2,
    var_ in number) is
  cnt_ number;
  l_cd_org t_org.cd%type;
  l_str varchar2(1000);
  cursor cur_params is
    select * from params;
  l_mg1 params.period%type;
  rec_params cur_params%rowtype;
  begin
  --нет ошибок
  err_:=0;

  select o.cd into l_cd_org
   from scott.t_org o, scott.t_org_tp tp
   where tp.id=o.fk_orgtp and tp.cd='РКЦ';
  
  
  open cur_params;
  fetch cur_params
    into rec_params;
  close cur_params;
  
  
  l_mg1:=utils.add_months_pr(rec_params.period, 1);

  --проверка до и во время формирования
  if var_ = 1 then --проверка всех ошибок до формирования
    if rec_params.period <> init.get_period then
       err_str_:='Стоп, заданная дата не соответствующая текущему периоду!';
       err_:=6;
       return;
    end if;

   select nvl(count(*),0) into cnt_
     from kart k
     where not exists
      (select * from s_reu_trest t where t.reu=k.reu);

   if cnt_ <> 0 then
     err_str_:='Стоп, код REU не найден в представлении s_reu_trest!';
     err_:=11;
     return;
   end if;

    --проверяем кол-во проживающих в карточках (кроме дополнительных счетов, - там не проверять! ред. 03.11.2015) 
   cnt_:=0;
    select nvl(count(*),0) into cnt_ from kart k, v_lsk_tp tp where
        k.fk_tp=tp.id and tp.cd='LSK_TP_MAIN' 
        and k.psch not in (8,9) -- ред 05.12.18
        and k.kpr <>(select nvl(count(*),0)
                       from c_kart_pr t
                      where t.lsk = k.lsk
                       and t.status not in (3,6) --не берём 6 код (временно прожив) ред.24.05.12 -- не берем код 3 - временно зарег, ред. 14.12.17
                       and (case when nvl(rec_params.is_fullmonth,0)=0 and t.status = 4 and --если выписан до 15 то не считать
                           nvl(t.dat_ub, to_date('19000101', 'YYYYMMDD')) <= --если нет даты выписки, то как будто бы выписан давно (в 1900 году)))
                           to_date((select period || '15' from params), 'YYYYMMDD') then
                           0
                                 when nvl(rec_params.is_fullmonth,0)=0 and t.status in (1,5) and --если прописан после 15 то не считать
                           nvl(t.dat_prop, to_date('19000101', 'YYYYMMDD')) >= --если нет даты прописки, то как будто бы прописан давно (в 1900 году)))
                           to_date((select period || '15' from params), 'YYYYMMDD') then
                           0
                                 when nvl(rec_params.is_fullmonth,0)=1 and t.status = 4 then
                                 0  --если выписан, то не считать (не глядя на дату выписки из за fullmonth=1)
                                 when nvl(rec_params.is_fullmonth,0)=1 and t.status in (1,5) then
                                 1  --если прописан, то считать (не глядя на дату прописки из за fullmonth=1)
                           else
                           1
                           end = 1)
                        );
    if cnt_ <> 0 then
      err_str_:='Стоп, кол-во проживающих в л.с. не соответствует прописке-выписке, продолжение не возможно!';
      err_:=1;
      return;
    end if;

  if utils.get_int_param('CONTROL_METER') = 1 then
     select count(*) into cnt_ from (
     select k.fk_tp, k.k_lsk_id, k.lsk, k.phw as cnt, t.n1 from kart k, meter t, v_lsk_tp tp
          where k.psch not in (8,9)
          and k.k_lsk_id=t.FK_KLSK_OBJ
          and t.fk_usl='011'
          and k.phw<>t.n1
          and t.dt2 > gdt(1,0,0)
          and k.fk_tp=tp.id
          and tp.cd='LSK_TP_MAIN'
     union all
     select k.fk_tp, k.k_lsk_id, k.lsk, k.pgw, t.n1 from kart k, meter t, v_lsk_tp tp
          where k.psch not in (8,9)
          and k.k_lsk_id=t.FK_KLSK_OBJ
          and t.fk_usl='015'
          and k.pgw<>t.n1
          and t.dt2 > gdt(1,0,0)
          and k.fk_tp=tp.id
          and tp.cd='LSK_TP_MAIN'
     union all
     select k.fk_tp, k.k_lsk_id, k.lsk, k.pel, t.n1 from kart k, meter t, v_lsk_tp tp
          where k.psch not in (8,9)
          and k.k_lsk_id=t.FK_KLSK_OBJ
          and t.fk_usl='038'
          and k.pel<>t.n1
          and t.dt2 > gdt(1,0,0)
          and k.fk_tp=tp.id
          and tp.cd='LSK_TP_MAIN');
     if cnt_ <> 0 then
       err_str_:='Стоп, некорректны показания по счетчикам!';
       err_:=1;
       return;
     end if;
   end if;
   

   select nvl(a.summa,0)-nvl(b.summa,0) into cnt_
     from (select nvl(sum(summa),0)+nvl(sum(penya),0) as summa from c_kwtp t
       where t.dat_ink between init.g_dt_start and init.g_dt_end
     ) a,
     (select nvl(sum(summa),0)+nvl(sum(penya),0) as summa from c_kwtp_mg t
       where t.dat_ink between init.g_dt_start and init.g_dt_end
     ) b;
   if cnt_ <> 0 then
     err_str_:='Стоп, общая сумма в c_kwtp<>c_kwtp_mg!';
     err_:=6;
     return;
   end if;
   
  select count(*), 
    rtrim(xmlagg(xmlelement(e, a.nkom,',').extract('//text()')),',')
     into cnt_, l_str
   from (select distinct t.nkom from c_kwtp t where nvl(t.nink, 0) = 0) a; 
--если раскомментировать, то будет мешать при формировании (не проверит, что выполнена инкассация)
--     and c.dat_ink between init.g_dt_start and init.g_dt_end;
   if cnt_ <> 0 then
     err_str_:='Стоп, не проинкассированы деньги на компьютерах: '||l_str;
     err_:=4;
     return;
   end if;
   
  select count(*) into cnt_ from ALL_TAB_COLUMNS t
   where t.TABLE_NAME='A_CHARGE_PREP2' and lower(t.OWNER)='scott';
   if cnt_ <> 18 then
     err_str_:='Стоп, изменилось кол-во полей! Необходимо исправить модель в Java: A_CHARGE_PREP2 ';
     err_:=4;
     return;
   end if;

  select count(*) into cnt_ from ALL_TAB_COLUMNS t
   where t.TABLE_NAME='A_CHARGE2' and lower(t.OWNER)='scott';
   if cnt_ <> 22 then
     err_str_:='Стоп, изменилось кол-во полей! Необходимо исправить модель в Java: A_CHARGE2 ';
     err_:=4;
     return;
   end if;

  select count(*) into cnt_ from ALL_TAB_COLUMNS t
   where t.TABLE_NAME='A_NABOR2' and lower(t.OWNER)='scott';
   if cnt_ <> 24 then
     err_str_:='Стоп, изменилось кол-во полей! Необходимо исправить модель в Java: A_NABOR2 ';
     err_:=4;
     return;
   end if;
      
 elsif var_ =2 then
  select count(*), 
    rtrim(xmlagg(xmlelement(e, a.nkom,',').extract('//text()')),',')
     into cnt_, l_str
   from (select distinct t.nkom from c_kwtp t where nvl(t.nink, 0) = 0) a; 
--если раскомментировать, то будет мешать при формировании (не проверит, что выполнена инкассация)
--     and c.dat_ink between init.g_dt_start and init.g_dt_end;
   if cnt_ <> 0 then
     err_str_:='Стоп, не проинкассированы деньги на компьютерах: '||l_str;
     err_:=4;
     return;
   end if;
 elsif var_ =3 then
  select count(*), 
    rtrim(xmlagg(xmlelement(e, a.nkom,',').extract('//text()')),',')
     into cnt_, l_str
   from (select distinct t.nkom from c_kwtp t where nvl(t.nink, 0) = 0) a; 
--если раскомментировать, то будет мешать при формировании (не проверит, что выполнена инкассация)
--     and c.dat_ink between init.g_dt_start and init.g_dt_end;
   if cnt_ <> 0 then
     err_str_:='Стоп, не проинкассированы деньги на компьютерах: '||l_str;
     err_:=4;
     return;
   end if;

  select nvl(a.summa,0)-nvl(b.summa,0) into cnt_
   from (select nvl(sum(summa),0)+nvl(sum(penya),0) as summa from c_kwtp t
    where t.dat_ink between init.g_dt_start and init.g_dt_end) a,
   (select sum(summa) as summa from kwtp_day t
    where t.dat_ink between init.g_dt_start and init.g_dt_end) b;
   if cnt_ <> 0 then
     err_str_:='Стоп, SUMMA c_kwtp<>kwtp_day!';
     err_:=8;
     return;
   end if;

 if init.get_state = 0 then
    err_str_:='Стоп, не выполнено итоговое формирование за месяц, переход не возможен!';
    err_:=5;
    return;
  end if;
 elsif var_ =4 then
  --проверки до ПЕРЕХОДА!
  --проверка, что сальдо исх идёт (бывает, когда удалят платёж без переформирования)
   select nvl(count(*),0) into cnt_
    from (select * from xitog3_lsk where mg=rec_params.period) t 
     full outer join 
         (select * from saldo_usl where mg=l_mg1) s
    on t.lsk=s.lsk and t.usl=s.usl and t.org=s.org
    where nvl(t.outdebet,0)+nvl(t.outkredit,0) <> nvl(s.summa,0);
    if cnt_ <> 0 then
      err_str_:='Не идёт исх.сальдо., возможно требуется итоговое формирование, продолжение не возможно!';
      err_:=13;
      return;
    end if;
    

  --проверка, что начисление идёт с начислением в оборотке (да, да, без учёта перерасчетов - не получилось с ними)
   select nvl(count(*),0) into cnt_
    from (select * from xitog3_lsk where mg=rec_params.period) t 
     full outer join 
         (select r.lsk, r.usl, o.fk_org2 as org, sum(r.summa) as summa
           from c_charge r, nabor n, t_org o 
           where r.lsk=n.lsk and r.type=1 and r.usl=n.usl 
           and n.org=o.id
           group by r.lsk, r.usl, o.fk_org2
           ) s
    on t.lsk=s.lsk and t.usl=s.usl and t.org=s.org
    where nvl(t.charges,0)-nvl(t.changes,0)-nvl(t.changes2,0)-nvl(t.changes3,0) <> nvl(s.summa,0);
    if cnt_ <> 0 then
      err_str_:='Не идёт начисление с обороткой, возможно требуется итоговое формирование, продолжение не возможно!';
      err_:=13;
      return;
    end if;

  --проверка, что перерасчет идёт в совокупности с начислением в оборотке 
   select nvl(count(*),0) into cnt_
    from (select lsk, nvl(sum(changes),0)+nvl(sum(changes2),0) as summa from xitog3_lsk where mg=rec_params.period group by lsk) t 
     full outer join 
         (select r.lsk, sum(r.summa) as summa
           from c_change r
           group by r.lsk
           ) s
    on t.lsk=s.lsk
    where nvl(t.summa,0) <> nvl(s.summa,0);
    if cnt_ <> 0 then
      err_str_:='Не идут перерасчеты с обороткой, возможно требуется итоговое формирование, продолжение не возможно!';
      err_:=13;
      return;
    end if;

  --проверка, что оплата идёт с оплатой в оборотке
   select nvl(count(*),0) into cnt_
    from (select * from xitog3_lsk where mg=rec_params.period) t 
     full outer join 
         (select r.lsk, r.usl, r.org, sum(r.summa) as summa
           from kwtp_day r where r.priznak=1
           and r.dat_ink between init.g_dt_start and init.g_dt_end
           group by r.lsk, r.usl, r.org
           ) s
    on t.lsk=s.lsk and t.usl=s.usl and t.org=s.org
    where nvl(t.payment,0) <> nvl(s.summa,0);
    if cnt_ <> 0 then
      err_str_:='Не идёт оплата с обороткой, возможно требуется итоговое формирование, продолжение не возможно!';
      err_:=13;
      return;
    end if;

    if utils.get_int_param('GEN_CHK_C_DEB_USL') = 1 then
     --по-периодный способ распределения оплаты
     --сравниваем сальдо с задолжностью по периодам,
     --по л/c
      select nvl(count(*),0)
        into cnt_
        from kart c, (select t.lsk, sum(summa) as summa
                from c_deb_usl t, params p
               where t.period = p.period
               group by t.lsk) a,
             (select t.lsk, sum(summa) as summa
                from saldo_usl t, params p
               where mg =
                     to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'),
                                        1),
                             'YYYYMM')
              group by t.lsk) b
              where c.lsk=a.lsk(+) and c.lsk=b.lsk(+)
              and nvl(a.summa,0) <> nvl(b.summa,0);
      if cnt_ <> 0 then
        err_str_:='Стоп, сумма Сальдо <> Сумма в c_deb_usl, продолжение не возможно!';
        err_:=13;
        return;
      end if;
    end if;

    --сравниваем сальдо с движением в совокупности
    select nvl(a.summa, 0) - nvl(b.summa, 0)
      into cnt_
      from (select sum(decode(type, 1, -1 * summa, summa)) as summa
              from c_chargepay t, params p
             where t.period = p.period) a,
           (select sum(summa) as summa
              from saldo_usl t, params p
             where mg =
                   to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'),
                                      1),
                           'YYYYMM')) b;
    if cnt_ <> 0 then
      err_str_:='Стоп, сумма Сальдо <> Сумма в движении в совокупности, продолжение не возможно!';
      err_:=2;
      return;
    end if;

    --сравниваем сальдо с движением по c_lsk_id
    select nvl(count(*),0)
      into cnt_
      from kart c, (select t.lsk, sum(decode(type, 1, -1 * summa, summa)) as summa
              from c_chargepay t, params p
             where t.period = p.period
             group by t.lsk) a,
           (select t.lsk, sum(summa) as summa
              from saldo_usl t, params p
             where mg =
                   to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'),
                                      1),
                           'YYYYMM')
            group by t.lsk) b
            where c.lsk=a.lsk(+) and c.lsk=b.lsk(+)
            and nvl(a.summa,0) <> nvl(b.summa,0);
/* --для запроса:
select c.lsk, a.*, b.*, a.summa-b.summa as diff
      from kart c, (select t.lsk, sum(decode(type, 1, -1 * summa, summa)) as summa
              from c_chargepay t, params p
             where t.period = p.period
             group by t.lsk) a,
           (select t.lsk, sum(summa) as summa
              from saldo_usl t, params p
             where mg =
                   to_char(add_months(to_date(p.period || '01', 'YYYYMMDD'),
                                      1),
                           'YYYYMM')
            group by t.lsk) b
            where c.lsk=a.lsk(+) and c.lsk=b.lsk(+)
            and nvl(a.summa,0) <> nvl(b.summa,0)
            order by c.lsk
*/

    if cnt_ <> 0 then
      err_str_:='Стоп, сумма Сальдо <> Сумма в движении по c_lsk_id, возможно произошли изменения в карточках. продолжение не возможно!';
      err_:=3;
      return;
    end if;

  --проверка что в сальдо не присутствуют организации ниже уровня 1
    select count(*) into cnt_ from (
      select level as lvl, t.id, t.name from scott.t_org t
      connect by prior t.id=t.parent_id2
      start with t.parent_id2 is null
      order by level
    ) a where a.lvl > 1
    and exists
    (select * from saldo_usl s, v_params p where
    s.mg=p.period1 and s.org = a.id);
   if cnt_ <> 0 then
      err_str_:='Стоп, в сальдо присутствуют организации > 1 уровня!';
      err_:=10;
      return;
   end if;
   
   
 elsif var_ =5 then
  --проверка перед формированием корректности л.с.
   select nvl(count(*),0) into cnt_ from kart k where nvl(k.fk_err,0)<>0;
   if cnt_ <> 0 then
      err_:=9;
   end if;
   return;

 elsif var_ =6 then
  --проверка распределения пени, после формирования сальдо
  select nvl(a.summa,0) - nvl(b.summa,0) into cnt_ from
    (select sum(summa) as summa from (
      select c.lsk, c.mg1, round(sum(penya),2) as summa from c_pen_cur c
        group by c.lsk, c.mg1
      union all
     select c.lsk, c.dopl, c.penya  -- прибавить корректировку пени за месяц
          from c_pen_corr c            
      )) a,
    (select sum(summa) as summa from t_chpenya_for_saldo c) b;
   
   if cnt_ <> 0 then
    err_:=12;
   end if;
   
 elsif var_ =7 then
  --проверка до итогового формирования, перехода, на получение всех показаний счетчиков
  --(при наличии ЛК)
  if utils.get_int_param('HAVE_LK') = 1 then

    execute immediate
     'select proc.check_is_acpt_sch@Apex(:l_cd_org) from dual'
    into cnt_
    using l_cd_org;
    if cnt_ <> 0 then
      err_:=14;
      err_str_:='Не все показания счетчиков из личного кабинета были учтены в базе!';
    end if;
  end if;

 elsif var_ =8 then
  --проверка до итогового формирования, на корректность периода в личном кабинете

  if utils.get_int_param('HAVE_LK') = 1 then

    execute immediate
     'select proc.check_period@Apex(:l_cd_org, p.period) from params p'
    into cnt_
    using l_cd_org;
    if cnt_ <> 0 then
      err_:=15;
      err_str_:='Не соответствующий период в личном кабинете!';
    end if;
  end if;


 elsif var_=9 then
   --проверка распределения пени, после формирования сальдо
   --проверка сальдо по пене
   select nvl(count(*),0) into cnt_ from (
    select k.lsk, b.pen_in, d.pen_cur, e.pen_cor, f.pen_pay, g.pen_out,
           nvl(b.pen_in, 0) + nvl(d.pen_cur, 0) + nvl(e.pen_cor, 0) -
            nvl(f.pen_pay, 0) as pen_calc
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
           nvl(f.pen_pay, 0) <> nvl(g.pen_out, 0)
    );
   if cnt_ <> 0 then
    err_:=12;
   end if;
 
   -- проверка сальдо по пене в оборотке
  select count(*) into cnt_ from 
   (select t.lsk, t.usl, t.org, sum(t.pinsal) as pinsal, sum(t.pcur) as pcur, sum(t.pn) as pn,
     sum(t.poutsal) as poutsal
    from xitog3_lsk t join params p on t.mg=p.period
    group by t.lsk, t.usl, t.org) a
    where nvl(a.pinsal,0) + nvl(a.pcur,0) - nvl(a.pn,0) <> nvl(a.poutsal,0);
   if cnt_ <> 0 then
    err_:=12;
   end if;
    
 end if;
 end;

  procedure gen_check_lst (var_ in number,
                           prep_refcursor IN OUT rep_refcursor) is
  begin
  --проверка перед формированием, с выводом л.с.
  --содержащих ошибки
  if var_=12 then
    --список лс. по которым не корректно распр.пеня
      OPEN prep_refcursor FOR
        select nvl(a.lsk,b.lsk) as lsk from --либо тот лск либо другой
        (select c.lsk, sum(penya) as summa from c_penya c group by lsk) a full outer join
        (select c.lsk, sum(summa) as summa from t_chpenya_for_saldo c group by lsk) b
        on a.lsk=b.lsk
        where nvl(a.summa,0) - nvl(b.summa,0) <> 0;
    else
        OPEN prep_refcursor FOR
          select lsk from kart k where nvl(k.fk_err,0)<>0;
  end if;
  end;

  procedure smpl_chk (p_var in number,
                           prep_refcursor IN OUT rep_refcursor) is
  begin
    
 -- Raise_application_error(-20000, 'TST');
  --проверка перед формированием, с выводом л.с.
  --содержащих ошибки
  if p_var=1 then
    --список лс. по которым не корректно распр.пеня
      OPEN prep_refcursor FOR
        select 'Некорректные лицевые, содержащие услугу х.в.ОДН, но у прочих л.с. дома услуги ОДН нет' as lsk
        from dual
        union all
        select k.lsk from kart k, nabor n, usl u where
        k.lsk=n.lsk and k.psch not in (8,9)
        and n.usl=u.usl
        and u.cd='х.вода'
        and exists
        (select * from nabor r, usl u2 where r.lsk=k.lsk
          and r.usl=u2.usl --есть услуга ОДН
          and u2.cd='х.вода.ОДН')
        and not exists --а у других л.с. нет этой услуги
        (select * from kart t, nabor r, usl u2 where r.lsk<>k.lsk
          and r.usl=u2.usl
          and u2.cd='х.вода.ОДН'
          and t.lsk=r.lsk
          and t.house_id=k.house_id)
        and exists
        (select a.house_id from kart a where a.house_id=k.house_id
         having count(*)>1
         group by a.house_id);
  elsif p_var=2 then
    --список лс. по которым не корректно распр.пеня
      OPEN prep_refcursor FOR
        select 'Некорректные лицевые, НЕ содержащие х.в.услугу ОДН, но у прочих л.с. дома услуга ОДН есть' as lsk
        from dual
        union all
        select k.lsk from kart k, nabor n, usl u where
        k.lsk=n.lsk and k.psch not in (8,9)
        and n.usl=u.usl
        and u.cd='х.вода'
        and exists
        (select * from nabor r, usl u2 where r.lsk=k.lsk
          and r.usl=u2.usl --есть услуга ОДН
          and u2.cd='х.вода.ОДН')
        and not exists --а у других л.с. нет этой услуги
        (select * from kart t, nabor r, usl u2 where r.lsk<>k.lsk
          and r.usl=u2.usl
          and u2.cd='х.вода.ОДН'
          and t.lsk=r.lsk
          and t.house_id=k.house_id)
        and exists
        (select a.house_id from kart a where a.house_id=k.house_id
         having count(*)>1
         group by a.house_id);
  elsif p_var=3 then
    --список лс. по которым не корректно распр.пеня
      OPEN prep_refcursor FOR
        select 'Некорректные лицевые, содержащие услугу г.в.ОДН, но у прочих л.с. дома услуги ОДН нет' as lsk
        from dual
        union all
        select k.lsk from kart k, nabor n, usl u where
        k.lsk=n.lsk and k.psch not in (8,9)
        and n.usl=u.usl
        and u.cd='г.вода'
        and exists
        (select * from nabor r, usl u2 where r.lsk=k.lsk
          and r.usl=u2.usl --есть услуга ОДН
          and u2.cd='г.вода.ОДН')
        and not exists --а у других л.с. нет этой услуги
        (select * from kart t, nabor r, usl u2 where r.lsk<>k.lsk
          and r.usl=u2.usl
          and u2.cd='г.вода.ОДН'
          and t.lsk=r.lsk
          and t.house_id=k.house_id)
        and exists
        (select a.house_id from kart a where a.house_id=k.house_id
         having count(*)>1
         group by a.house_id);
  elsif p_var=4 then
    --список лс. по которым не корректно распр.пеня
      OPEN prep_refcursor FOR
        select 'Некорректные лицевые, НЕ содержащие г.в.услугу ОДН, но у прочих л.с. дома услуга ОДН есть' as lsk
        from dual
        union all
        select k.lsk from kart k, nabor n, usl u where
        k.lsk=n.lsk and k.psch not in (8,9)
        and n.usl=u.usl
        and u.cd='г.вода'
        and exists
        (select * from nabor r, usl u2 where r.lsk=k.lsk
          and r.usl=u2.usl --есть услуга ОДН
          and u2.cd='г.вода.ОДН')
        and not exists --а у других л.с. нет этой услуги
        (select * from kart t, nabor r, usl u2 where r.lsk<>k.lsk
          and r.usl=u2.usl
          and u2.cd='г.вода.ОДН'
          and t.lsk=r.lsk
          and t.house_id=k.house_id)
        and exists
        (select a.house_id from kart a where a.house_id=k.house_id
         having count(*)>1
         group by a.house_id);
  end if;
  end;

  procedure prep_kart_pr is
  time_ date;
  --Подготовка льготников для статистики
  begin
    /*  time_ := SYSDATE;
    EXECUTE IMMEDIATE 'TRUNCATE TABLE lg_pr';
    UPDATE KART_PR SET id = kart_pr_id.NEXTVAL;
    INSERT INTO LG_PR
      (kart_pr_id, lg_id, main, TYPE)
      SELECT id,
             SUBSTR(lp, 1, 3) AS lg_id,
             DECODE(trim(k.osno_lp1), NULL, 0, 1) AS main,
             1 AS TYPE
        FROM KART_PR k
       WHERE SUBSTR(lp, 1, 3) NOT IN ('   ', '001')
      UNION ALL
      SELECT id,
             SUBSTR(lp, 5, 3) AS lg_id,
             DECODE(trim(k.osno_lp2), NULL, 0, 1) AS main,
             1 AS TYPE
        FROM KART_PR k
       WHERE SUBSTR(lp, 5, 3) NOT IN ('   ', '001')
      UNION ALL
      SELECT id,
             SUBSTR(lp, 9, 3) AS lg_id,
             DECODE(trim(k.osno_lp3), NULL, 0, 1) AS main,
             1 AS TYPE
        FROM KART_PR k
       WHERE SUBSTR(lp, 9, 3) NOT IN ('   ', '001')
      UNION ALL
      SELECT id,
             SUBSTR(lp, 13, 3) AS lg_id,
             DECODE(trim(k.osno_lp4), NULL, 0, 1) AS main,
             1 AS TYPE
        FROM KART_PR k
       WHERE SUBSTR(lp, 13, 3) NOT IN ('   ', '001')
      UNION ALL
      SELECT id,
             SUBSTR(lpk, 1, 3) AS lg_id,
             DECODE(trim(k.osno_lp1), NULL, 0, 1) AS main,
             0 AS TYPE
        FROM KART_PR k
       WHERE SUBSTR(lpk, 1, 3) NOT IN ('   ', '001')
      UNION ALL
      SELECT id,
             SUBSTR(lpk, 5, 3) AS lg_id,
             DECODE(trim(k.osno_lp2), NULL, 0, 1) AS main,
             0 AS TYPE
        FROM KART_PR k
       WHERE SUBSTR(lpk, 5, 3) NOT IN ('   ', '001')
      UNION ALL
      SELECT id,
             SUBSTR(lpk, 9, 3) AS lg_id,
             DECODE(trim(k.osno_lp3), NULL, 0, 1) AS main,
             0 AS TYPE
        FROM KART_PR k
       WHERE SUBSTR(lpk, 9, 3) NOT IN ('   ', '001')
      UNION ALL
      SELECT id,
             SUBSTR(lpk, 13, 3) AS lg_id,
             DECODE(trim(k.osno_lp4), NULL, 0, 1) AS main,
             0 AS TYPE
        FROM KART_PR k
       WHERE SUBSTR(lpk, 13, 3) NOT IN ('   ', '001');
    COMMIT;
    ADMIN.ANALYZE('lg_pr');*/
    logger.log_(time_, 'gen.prep_kart_pr');
  end prep_kart_pr;

  procedure gen_opl_xito3 is
    stmt varchar2(2500);
    type_otchet constant number := 3; --тип отчета - оплата по пункатм (XITO3)
    time_ date;
    mg_ params.period%type;
  begin
    select period into mg_ from params p;
    time_ := sysdate;
    --ЗА МЕСЯЦ
    --Оплата по пунктам начисления
    delete from xxito3 where mg = mg_;
    insert into xxito3
      (trest, reu, usl, dopl, summa, mg)
      select s.trest,
             s.reu,
             u.usl,
             t.dopl,
             sum(summa) summa,
             mg_ as mg
        from kwtp_day t, usl u, kart k, s_reu_trest s, oper o
       where t.usl = u.usl
         and t.lsk = k.lsk
         and k.reu = s.reu
         and t.oper = o.oper
         and substr(o.oigu, 1, 1) = '1'
         and to_char(t.dat_ink, 'YYYYMM') = mg_
         and t.priznak = 1
         and t.dat_ink between init.g_dt_start and init.g_dt_end
       group by u.usl, s.trest, s.reu, t.dopl;
    delete from period_reports p
     where p.id = type_otchet
       and p.mg = mg_; --обновляем период для отчета
    stmt := 'insert into period_reports (id, mg) values(:id, :mg)';
    execute immediate stmt
      using type_otchet, mg_;
    commit;
    logger.log_(time_, 'gen.gen_opl_xito3 ' || mg_);
  end;

  procedure gen_opl_xito5_ is
    stmt varchar2(2500);
    type_otchet constant number := 5; --тип отчета - оплата по операциям (XITO10)
    time_ date;
    mg_ params.period%type;
  begin
    select period into mg_ from params p;
    time_ := sysdate;
    --ЗА МЕСЯЦ
    --Оплата по операциям (для оборотной ведомости)
    delete from xito5_ where mg = mg_;
    insert into xito5_
      (ska, pn, trest, reu, from_reu, other, nal, ink, oper, mg)
      select sum(ska) ska,
             sum(pn) pn,
             trest,
             reu,
             from_reu,
             other,
             nal,
             ink,
             oper,
             mg_ as mg
        from v_xito5_all_ v
       group by trest,
                reu,
                from_reu,
                other,
                nal,
                ink,
                oper,
                mg_,
                to_char(sysdate, 'DD/MM/YYYY HH24:MI');
    delete from period_reports p
     where p.id = type_otchet
       and p.mg = mg_; --обновляем период для отчета
    stmt := 'insert into period_reports (id, mg) values(:id, :mg)';
    execute immediate stmt
      using type_otchet, mg_;
    commit;
    logger.log_(time_, 'gen.gen_opl_xito5_ ' || mg_);
  end;

  procedure gen_opl_xito5 is
    stmt varchar2(2500);
    type_otchet  constant number := 4; --тип отчета - оплата по операциям (XITO5)
    type_otchet2 constant number := 10; --тип отчета - пеня (Ф.8.1)
    time_ date;
    mg_ params.period%type;
  begin
    select period into mg_ from params p;
    time_ := sysdate;
    --ЗА МЕСЯЦ
    --Оплата по операциям (по инкассациям)
    delete from xito5 where mg = mg_;
    insert into xito5
      (ska, pn, trest, reu, other, nal, ink, oper, mg)
      select sum(ska) ska,
             sum(pn) pn,
             trest,
             reu,
             other,
             nal,
             ink,
             oper,
             mg_ as mg
        from v_xito5_all v
       group by trest,
                reu,
                other,
                nal,
                ink,
                oper,
                mg_,
                to_char(sysdate, 'DD/MM/YYYY HH24:MI');
    delete from period_reports p
     where p.id = type_otchet
       and p.mg = mg_; --обновляем период для отчета
    stmt := 'insert into period_reports (id, mg) values(:id, :mg)';
    execute immediate stmt
      using type_otchet, mg_;
    delete from period_reports p
     where p.id = type_otchet2
       and p.mg = mg_; --обновляем период для отчета
    stmt := 'insert into period_reports (id, mg) values(:id, :mg)';
    execute immediate stmt
      using type_otchet2, mg_;
    commit;
    logger.log_(time_, 'gen.gen_opl_xito5 ' || mg_);
  end;

  procedure gen_opl_xito5day(dat1_ in xito5.dat%type,
                             dat2_ in xito5.dat%type) is
    stmt varchar2(2500);
    type_otchet  constant number := 4; --тип отчета - оплата по операциям (XITO10)
    type_otchet2 constant number := 10; --тип отчета - пеня (Ф.8.1)
    time_ date;
  begin
    time_ := sysdate;
    --ЗА ДЕНЬ
    --Оплата по операциям (для оборотки)
    for a in to_char(dat1_, 'YYYYMMDD') .. to_char(dat2_, 'YYYYMMDD') loop
      delete from xito5 where to_char(dat, 'YYYYMMDD') = a;
      insert into xito5
        (ska, pn, trest, reu, other, nal, ink, oper, nkom, nink, dat)
        select sum(ska) ska,
               sum(pn) pn,
               trest,
               reu,
               other,
               nal,
               ink,
               oper,
               nkom,
               nink,
               to_date(a, 'YYYYMMDD') as dat
          from v_xito5_allday v
         where v.md = to_date(a, 'YYYYMMDD')
         group by trest,
                  reu,
                  other,
                  nal,
                  ink,
                  oper,
                  nkom,
                  nink,
                  to_date(a, 'YYYYMMDD'),
                  to_char(sysdate, 'DD/MM/YYYY HH24:MI');
      delete from period_reports p
       where p.id = type_otchet
         and to_char(dat, 'YYYYMMDD') = a; --обновляем период для отчета
      stmt := 'insert into period_reports (id, dat) values(:id, :dat)';
      execute immediate stmt
        using type_otchet, to_date(a, 'YYYYMMDD');
      stmt := 'insert into period_reports (id, dat) values(:id, :dat)';

      delete from period_reports p
       where p.id = type_otchet2
         and to_char(dat, 'YYYYMMDD') = a; --обновляем период для отчета
      execute immediate stmt
        using type_otchet2, to_date(a, 'YYYYMMDD');
      commit;
    end loop;
    logger.log_(time_,
                'gen.gen_opl_xito5day ' || to_char(dat1_) || ' ' ||
                to_char(dat2_));
  end;

  procedure gen_opl_xito5day_(dat1_ in xito5_.dat%type,
                              dat2_ in xito5_.dat%type) is
    stmt varchar2(2500);
    type_otchet constant number := 5; --тип отчета - оплата по операциям (XITO10)
    time_ date;
  begin
    --ЗА ДЕНЬ
    --Оплата по операциям (по инкассациям)
    time_ := sysdate;
    for a in to_char(dat1_, 'YYYYMMDD') .. to_char(dat2_, 'YYYYMMDD') loop
      delete from xito5_ where to_char(dat, 'YYYYMMDD') = a;
      insert into xito5_
        (ska, pn, trest, reu, from_reu, other, nal, ink, oper, dat)
        select sum(ska) ska,
               sum(pn) pn,
               trest,
               reu,
               from_reu,
               other,
               nal,
               ink,
               oper,
               to_date(a, 'YYYYMMDD') as dat
          from v_xito5_allday_ v
         where v.md = to_date(a, 'YYYYMMDD')
         group by trest,
                  reu,
                  from_reu,
                  other,
                  nal,
                  ink,
                  oper,
                  to_date(a, 'YYYYMMDD'),
                  to_char(sysdate, 'DD/MM/YYYY HH24:MI');
      delete from period_reports p
       where p.id = type_otchet
         and to_char(dat, 'YYYYMMDD') = a; --обновляем период для отчета
      stmt := 'insert into period_reports (id, dat) values(:id, :dat)';
      execute immediate stmt
        using type_otchet, to_date(a, 'YYYYMMDD');
      commit;
    end loop;
    admin.send_message('Сформирована оплата Ф.3.1. за текущий период, c ' ||
                       to_char(dat1_, 'DD/MM/YYYY') || ' по ' ||
                       to_char(dat2_, 'DD/MM/YYYY'));
    logger.log_(time_,
                'gen.gen_opl_xito5day_ ' || to_char(dat1_) || ' ' ||
                to_char(dat2_));
  end;

  procedure gen_opl_xito10day(dat1_ in xxito10.dat%type,
                              dat2_ in xxito10.dat%type) is
    time_ date;
    mg_ params.period%type;
  begin
    --За день
    --Оплата по предприятиям/трестам/услугам
    time_ := sysdate;
    select p.period into mg_ from params p;
    for a in to_char(dat1_, 'YYYYMMDD') .. to_char(dat2_, 'YYYYMMDD') loop
      -- xxito11 детализация до кода операции
      delete from xxito11 t where t.dat = to_date(a, 'YYYYMMDD')
       and t.mg=mg_;
      insert into xxito11
        (usl,
         oper,
         org,
         summa,
         trest,
         reu,
         dat,
         var,
         forreu,
         oborot,
         dopl,
         mg)
        select v.usl,
               v.oper,
               v.org,
               sum(v.summar) as summar,
               v.trest,
               v.reu,
               to_date(a, 'YYYYMMDD') as dat,
               v.var,
               v.forreu,
               v.oborot,
               v.dopl,
               mg_
          from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.oper, t.dat_ink as dat, t.usl as usl_b, t.org as org_b, t.dopl
             from kwtp_day t, kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper and t.priznak = 1
         and t.dat_ink between init.g_dt_start and init.g_dt_end) v
         where v.dat = to_date(a, 'YYYYMMDD')
         group by usl,
                  oper,
                  org,
                  trest,
                  reu,
                  to_date(a, 'YYYYMMDD'),
                  to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                  var,
                  forreu,
                  oborot,
                  dopl;

      -- xxito12 детализация до статуса жилья, адреса
      delete from xxito12 t where t.dat = to_date(a, 'YYYYMMDD')
       and t.mg=mg_;
      insert into xxito12
        (usl,
         org,
         summa,
         trest,
         reu,
         dat,
         var,
         forreu,
         kul,
         nd,
         status,
         dopl,
         mg)
        select v.usl,
               v.org,
               sum(v.summar) as summar,
               v.trest,
               v.reu,
               to_date(a, 'YYYYMMDD') as dat,
               v.var,
               v.forreu,
               k.kul,
               k.nd,
               decode(k.status, 1, 0, 1),
               v.dopl,
               mg_
          from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.oper, t.dat_ink as dat, t.usl as usl_b, t.org as org_b, t.dopl
             from kwtp_day t, kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper and t.priznak = 1
           and t.dat_ink between init.g_dt_start and init.g_dt_end) v, kart k
         where v.dat = to_date(a, 'YYYYMMDD')
           and k.lsk = v.lsk
           and v.oborot = 1
         group by v.usl,
                  v.org,
                  v.trest,
                  v.reu,
                  to_date(a, 'YYYYMMDD'),
                  to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                  v.var,
                  v.forreu,
                  k.kul,
                  k.nd,
                  decode(k.status, 1, 0, 1),
                  v.dopl;
      -- xxito14
      delete from xxito14_lsk t where t.dat = to_date(a, 'YYYYMMDD')
       and t.mg=mg_;
      insert into xxito14_lsk
        (lsk, usl, org, summa, dat, var, status, dopl, oper, cd_tp, mg)
        select v.lsk,
               v.usl,
               v.org,
               sum(v.summar) as summar,
               to_date(a, 'YYYYMMDD') as dat,
               v.var,
               decode(k.status, 1, 0, 1),
               v.dopl,
               v.oper,
               v.cd_tp,
               mg_
          from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.sum_distr, t.fk_distr,
            t.oper, t.dat_ink as dat, t.usl as usl_b, t.org as org_b, t.dopl,
            t.priznak as cd_tp
             from kwtp_day t, kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper/* ред.21.06.11 and t.priznak = 1*/
           and t.dat_ink between init.g_dt_start and init.g_dt_end) v, kart k
         where v.dat = to_date(a, 'YYYYMMDD')
           and k.lsk = v.lsk
           and v.oborot = 1
         group by v.lsk,
                  v.usl,
                  v.org,
                  v.fk_distr,
                  to_date(a, 'YYYYMMDD'),
                  v.var,
                  decode(k.status, 1, 0, 1),
                  v.dopl,
                  v.oper,
                  v.cd_tp;

      delete from xxito14 t where t.dat = to_date(a, 'YYYYMMDD')
       and t.mg=mg_;
      insert into xxito14
        (usl,
         org,
         summa,
         sum_distr,
         fk_distr,
         trest,
         reu,
         dat,
         var,
         forreu,
         kul,
         nd,
         status,
         dopl,
         oper,
         cd_tp,
         mg)
        select v.usl,
               v.org,
               sum(v.summar) as summar,
               sum(v.sum_distr) as sum_distr,
               v.fk_distr,
               v.trest,
               v.reu,
               to_date(a, 'YYYYMMDD') as dat,
               v.var,
               v.forreu,
               k.kul,
               k.nd,
               decode(k.status, 1, 0, 1),
               v.dopl,
               v.oper,
               v.cd_tp,
               mg_
          from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.sum_distr,
               t.fk_distr, t.oper, t.dat_ink as dat, t.usl as usl_b, t.org as org_b, t.dopl,
               t.priznak as cd_tp
             from kwtp_day t, kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper/* ред.21.06.11 and t.priznak = 1*/
           and t.dat_ink between init.g_dt_start and init.g_dt_end) v, kart k
         where v.dat = to_date(a, 'YYYYMMDD')
           and k.lsk = v.lsk
           and v.oborot = 1
         group by v.usl,
                  v.org,
                  v.trest,
                  v.reu,
                  v.fk_distr,
                  to_date(a, 'YYYYMMDD'),
                  to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                  v.var,
                  v.forreu,
                  k.kul,
                  k.nd,
                  decode(k.status, 1, 0, 1),
                  v.dopl,
                  v.oper,
                  v.cd_tp;
      -- xxito10 детализация до кода организации
      delete from xxito10 t where t.dat = to_date(a, 'YYYYMMDD')
       and t.mg=mg_;
      insert into xxito10
        (usl, org, summa, trest, reu, dat, var, forreu, oborot, dopl, mg)
        select v.usl,
               v.org,
               sum(v.summa),
               v.trest,
               v.reu,
               to_date(a, 'YYYYMMDD') as dat,
               v.var,
               v.forreu,
               v.oborot,
               dopl,
               mg_
          from xxito11 v
         where v.dat = to_date(a, 'YYYYMMDD') and
               v.mg=mg_
         group by v.usl,
                  v.org,
                  v.trest,
                  v.reu,
                  to_date(a, 'YYYYMMDD'),
                  to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                  v.var,
                  v.forreu,
                  v.oborot,
                  dopl;

    logger.ins_period_rep('7', null, to_date(a, 'YYYYMMDD'), 0);
    logger.ins_period_rep('2', null, to_date(a, 'YYYYMMDD'), 0);
    logger.ins_period_rep('15', null, to_date(a, 'YYYYMMDD'), 0);
    logger.ins_period_rep('17', null, to_date(a, 'YYYYMMDD'), 0);
    logger.ins_period_rep('23', null, to_date(a, 'YYYYMMDD'), 0);
    logger.ins_period_rep('35', null, to_date(a, 'YYYYMMDD'), 0);
    logger.ins_period_rep('61', null, to_date(a, 'YYYYMMDD'), 0);
    logger.ins_period_rep('65', null, to_date(a, 'YYYYMMDD'), 0);
    commit;
    end loop;

    logger.log_(time_,
                'gen_opl_xito10day ' || to_char(dat1_) || ' ' ||
                to_char(dat2_));
    admin.send_message('Сформирована оплата Ф.2.1.Ф.2.2.Ф.2.3. за текущий период, c ' ||
                       to_char(dat1_, 'DD/MM/YYYY') || ' по ' ||
                       to_char(dat2_, 'DD/MM/YYYY'));
  end;

  procedure gen_opl_xito10 is
    time_ date;
    mg_ params.period%type;
  begin
    select period into mg_ from params p;

    --ЗА МЕСЯЦ
    --Оплата по предприятиям/трестам/услугам
    time_ := sysdate;
    delete from xxito11 t where t.mg = mg_;
    insert into xxito11
      (usl,
       oper,
       org,
       summa,
       trest,
       reu,
       mg,
       var,
       forreu,
       oborot,
       dopl,
       dat)
      select v.usl,
             v.oper,
             v.org,
             sum(v.summar) as summar,
             v.trest,
             v.reu,
             mg_,
             v.var,
             v.forreu,
             v.oborot,
             v.dopl,
             v.dat
        from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.oper, t.dat_ink as dat, t.usl as usl_b, t.org as org_b, t.dopl
             from kwtp_day t, kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper and t.priznak = 1
           and t.dat_ink between init.g_dt_start and init.g_dt_end) v
       group by usl,
                oper,
                org,
                trest,
                reu,
                mg_,
                to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                var,
                forreu,
                oborot,
                dopl,
                dat;

    delete from xxito12 t where t.mg = mg_;
    insert into xxito12
      (usl,
       org,
       summa,
       trest,
       reu,
       mg,
       var,
       forreu,
       kul,
       nd,
       status,
       dopl,
       dat)
      select v.usl,
             v.org,
             sum(v.summar) as summar,
             v.trest,
             v.reu,
             mg_,
             v.var,
             k.reu,
             k.kul,
             k.nd,
             decode(k.status, 1, 0, 1),
             v.dopl,
             v.dat
        from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.oper, t.dat_ink as dat, t.usl as usl_b, t.org as org_b, t.dopl
             from kwtp_day t, kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper and t.priznak = 1
           and t.dat_ink between init.g_dt_start and init.g_dt_end) v, kart k
       where k.lsk = v.lsk
         and v.oborot = 1
       group by v.usl,
                v.org,
                v.trest,
                v.reu,
                mg_,
                to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                v.var,
                k.reu,
                k.kul,
                k.nd,
                decode(k.status, 1, 0, 1),
                v.dopl,
                v.dat;

    delete from xxito14_lsk t where t.mg = mg_;
    insert into xxito14_lsk
      (lsk, usl, org, summa, mg, var, status, dopl, oper, cd_tp, dat)
      select k.lsk,
             v.usl,
             v.org,
             sum(v.summar) as summar,
             mg_ as mg,
             v.var,
             decode(k.status, 1, 0, 1),
             v.dopl,
             v.oper,
             v.cd_tp,
             v.dat
        from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.oper, t.dat_ink as dat, t.usl as usl_b, t.org as org_b, t.dopl,
            t.priznak as cd_tp
             from kwtp_day t, kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper
           and t.dat_ink between init.g_dt_start and init.g_dt_end) v, kart k
       where k.lsk = v.lsk
         and v.oborot = 1
       group by k.lsk,
                v.usl,
                v.org,
                v.var,
                decode(k.status, 1, 0, 1),
                v.dopl,
                v.oper,
                v.cd_tp,
                v.dat;

    delete from xxito14 t where t.mg = mg_;
    insert into xxito14
      (usl,
       org,
       summa,
       sum_distr,
       fk_distr,
       trest,
       reu,
       mg,
       var,
       forreu,
       kul,
       nd,
       status,
       dopl,
       oper,
       cd_tp,
       dat)
      select v.usl,
             v.org,
             sum(v.summar) as summar,
             sum(v.sum_distr) as sum_distr,
             v.fk_distr as fk_distr,
             v.trest,
             v.reu,
             mg_,
             v.var,
             k.reu,
             k.kul,
             k.nd,
             decode(k.status, 1, 0, 1),
             v.dopl,
             v.oper,
             v.cd_tp,
             v.dat
        from (select t.lsk, t.usl, t.org, substr(t.nkom, 1, 2) AS reu, s.trest, 0 as var,
            s.reu as forreu, to_number(substr(op.oigu, 1, 1)) AS oborot,
            t.summa as summar, t.sum_distr, t.fk_distr, t.oper, t.dat_ink as dat,
            t.usl as usl_b, t.org as org_b, t.dopl, t.priznak as cd_tp
             from kwtp_day t, kart k, s_reu_trest s, oper op
           where t.lsk=k.lsk and k.reu=s.reu and t.oper=op.oper
           and t.dat_ink between init.g_dt_start and init.g_dt_end) v, kart k
       where k.lsk = v.lsk
         and v.oborot = 1
       group by v.usl,
                v.org,
                v.trest,
                v.reu,
                v.fk_distr,
                mg_,
                to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                v.var,
                k.reu,
                k.kul,
                k.nd,
                decode(k.status, 1, 0, 1),
                v.dopl,
                v.oper,
                v.cd_tp,
                v.dat;

    delete from xxito10 t where t.mg = mg_;
    insert into xxito10
      (usl, org, summa, trest, reu, mg, var, forreu, oborot, dopl, dat)
      select v.usl,
             v.org,
             sum(v.summa),
             v.trest,
             v.reu,
             mg_,
             v.var,
             v.forreu,
             v.oborot,
             v.dopl,
             v.dat
        from xxito11 v
       where v.mg = mg_
       group by v.usl,
                v.org,
                v.trest,
                v.reu,
                mg_,
                to_char(sysdate, 'DD/MM/YYYY HH24:MI'),
                v.var,
                v.forreu,
                v.oborot,
                v.dopl,
                v.dat;
    logger.log_(time_, 'gen.gen_opl_xito10 ' || mg_);

    logger.ins_period_rep('7', mg_, null, 0);
    logger.ins_period_rep('2', mg_, null, 0);
    logger.ins_period_rep('15', mg_, null, 0);
    logger.ins_period_rep('17', mg_, null, 0);
    logger.ins_period_rep('23', mg_, null, 0);
    logger.ins_period_rep('35', mg_, null, 0);
    logger.ins_period_rep('59', mg_, null, 0);
    logger.ins_period_rep('61', mg_, null, 0);
    logger.ins_period_rep('65', mg_, null, 0);
    commit;
  end;

  procedure gen_c_charges(lsk_ in kart.lsk%type) is
    cnt_ number;
    time_ date;
  begin
    time_ := sysdate;
    --формирование начисления за месяц.
    if lsk_ is null then
      --все лицевые с промежуточным коммитом, по каждому лицевому...
--      cnt_ := c_charges.gen_charges(null, null, null, null, 2, 1);
      c_charges.gen_chrg_all(0, null, null, null);
      --Загрузка субсидии по электроэнергии
      agent.load_subs_el;
    else
      --по одному лицевому, без коммита
      cnt_ := c_charges.gen_charges(lsk_, lsk_, null, null, 0, 0);
    end if;

    --льготы
    if lsk_ is null then
      execute immediate 'truncate table privs';
      insert into privs
        (lsk, summa, nomer, usl_id, lg_id, main)
        select c.lsk,
               sum(c.summa) as summa,
               c.kart_pr_id,
               c.usl,
               c.spk_id,
               c.main
          from c_charge c
         where c.type = 4
           and c.summa <> 0
         group by c.lsk, c.kart_pr_id, c.usl, c.spk_id, c.main;
    else
      delete from privs c
       where c.lsk=lsk_;
      insert into privs
        (lsk, summa, nomer, usl_id, lg_id, main)
        select c.lsk,
               sum(c.summa) as summa,
               c.kart_pr_id,
               c.usl,
               c.spk_id,
               c.main
          from c_charge c
         where c.type = 4
           and c.summa <> 0
           and c.lsk=lsk_
         group by c.lsk, c.kart_pr_id, c.usl, c.spk_id, c.main;
    end if;
    commit;
    if lsk_ is null then
    logger.log_(time_,
                'gen.gen_c_charges (Начисление по Л/C)');
    end if;
  end;

  procedure gen_lg
  -- Формирование льготников
   is
    type_otchet  constant number := 8; --тип возмещение по льготникам (Ф.8.1.)
    type_otchet2 constant number := 11; --тип льготники для статистики (Ф.9.1.)
    type_otchet3 constant number := 20; --тип возмещение по льготникам (Ф.7.5.)
    time_ date;
    mg_ params.period%type;
  begin
    select period into mg_ from params p;
    time_ := sysdate;

    --льготники для списка льготников
    delete from xito_lg4 x where x.mg = mg_;
    insert into xito_lg4
      (lsk,
       reu,
       kul,
       nd,
       kw,
       trest,
       usl,
       lg_id,
       org,
       nomer,
       cnt_main,
       cnt,
       summa,
       mg)
      select lsk,
             reu,
             kul,
             nd,
             kw,
             trest,
             usl,
             lg_id,
             org,
             nomer,
             cnt_main,
             cnt,
             summa,
             period
        from v_gen_lg4;

    delete from xito_lg3 x where x.mg = mg_;
    --    /*+ INDEX (t PRIVS_I) */
    insert into xito_lg3
      (reu,
       trest,
       kul,
       nd,
       usl_id,
       lg_id,
       org_id,
       summa,
       cnt_main,
       cnt,
       mg)
      select a.reu,
             a.trest,
             a.kul,
             a.nd,
             a.usl,
             a.lg_id,
             a.org,
             sum(a.summa) summa,
             sum(a.cnt_main) cnt_main,
             sum(a.cnt) cnt,
             a.period
        from (select *
                from v_gen_lg3
              union all
              select * from v_gen_lg3_c) a
       group by a.reu,
                a.trest,
                a.kul,
                a.nd,
                a.usl,
                a.lg_id,
                a.org,
                a.period;

    delete from xito_lg2 x where x.mg = mg_;
    /*+ INDEX (t PRIVS_I) */
    insert into xito_lg2
      (reu,
       trest,
       kul,
       nd,
       uslm_id,
       lg_id,
       org_id,
       summa,
       cnt_main,
       cnt,
       mg)
      select a.reu,
             a.trest,
             a.kul,
             a.nd,
             a.uslm,
             a.lg_id,
             a.org,
             sum(summa),
             sum(cnt_main),
             sum(cnt),
             a.period
        from (select *
                from v_gen_lg2
              union all
              select * from v_gen_lg2_c) a
       group by a.reu,
                a.trest,
                a.kul,
                a.nd,
                a.uslm,
                a.lg_id,
                a.org,
                a.period;

    delete from xito_lg1 x where x.mg = mg_;
    insert into xito_lg1
      (reu, trest, kul, nd, lg_id, summa, cnt_main, cnt, mg)
      select reu,
             trest,
             kul,
             nd,
             lg_id,
             sum(summa) as summa,
             sum(cnt_main),
             sum(cnt),
             period
        from (select s.reu,
                     s.trest,
                     k.kul,
                     k.nd,
                     x.lg_id,
                     sum(x.summa) as summa,
                     sum(x.cnt_main) as cnt_main,
                     count(*) as cnt,
                     p.period
                from (select lsk, lg_id, nomer, cnt_main, sum(summa) as summa
                        from (select t.lsk,
                                     t.lg_id,
                                     t.nomer,
                                     t.main as cnt_main,
                                     t.summa
                                from privs t
                               where t.main not in (2)
                              union all
                              select t.lsk,
                                     t.lg_id,
                                     0 as nomer,
                                     t.main as cnt_main,
                                     t.summa
                                from t_corrects_lg t,
                                     kart          e,
                                     usl           u,
                                     s_reu_trest   s,
                                     params        p
                               where e.lsk = t.lsk
                                 and t.usl = u.usl
                                 and e.reu = s.reu
                                 and t.mg = p.period)
                       group by lsk, lg_id, nomer, cnt_main) x,
                     kart k,
                     s_reu_trest s,
                     params p
               where x.lsk = k.lsk
                 and k.reu = s.reu
               group by s.reu, s.trest, k.kul, k.nd, x.lg_id, p.period

              union all

              select s.reu,
                     s.trest,
                     k.kul,
                     k.nd,
                     x.lg_id,
                     sum(x.summa) as summa,
                     0 as cnt_main,
                     0 as cnt,
                     p.period
                from (select lsk, lg_id, nomer, cnt_main, sum(summa) as summa
                        from (select t.lsk,
                                     t.lg_id,
                                     t.nomer,
                                     t.main as cnt_main,
                                     t.summa
                                from privs t
                               where t.main in (2))
                       group by lsk, lg_id, nomer, cnt_main) x,
                     kart k,
                     s_reu_trest s,
                     params p
               where x.lsk = k.lsk
                 and k.reu = s.reu
               group by s.reu, s.trest, k.kul, k.nd, x.lg_id, p.period)
       group by reu, trest, kul, nd, lg_id, period;

    delete from period_reports p
     where p.id = type_otchet
       and p.mg = mg_; --обновляем период для отчета
    insert into period_reports (id, mg) values (type_otchet, mg_);

    delete from period_reports p
     where p.id = type_otchet2
       and p.mg = mg_; --обновляем период для отчета
    insert into period_reports (id, mg) values (type_otchet2, mg_);

    delete from period_reports p
     where p.id = type_otchet3
       and p.mg = mg_; --обновляем период для отчета
    insert into period_reports (id, mg) values (type_otchet3, mg_);
    commit;
    logger.log_(time_, 'gen.gen_lg ' || mg_);
  end gen_lg;

  procedure gen_saldo(lsk_ in kart.lsk%type)
  --Формирование исходящего сальдо по концу месца mg_ - текущий месяц, по Л/С
    --Внимание! следующий код при выполнении формирования за месяц может вести к нестабильности
    --получения счетов пользователями из за выполнения truncate-ов
   is
    stmt   varchar2(2000);
    mg_    params.period%type;
    mg1_   params.period%type;
    init_mg_   params.period%type;
    old_mg_   params.period%type;
    cnt_ number;
    time1_ date;
    time_ date;
  begin
    
    -- вначале провести корректировки в kwtp_day
    c_gen_pay.dist_pay_del_corr(lsk_);
    c_gen_pay.dist_pay_add_corr(var_ => 0, p_lsk=>lsk_);    
  
    select period into mg_ from params p;
    
    --Вычисляем следующий месяц
    mg1_ := to_char(add_months(to_date(mg_ || '01', 'YYYYMMDD'), 1),
                    'YYYYMM');
    --Вычисляем пердыдущий месяц
    old_mg_ := to_char(add_months(to_date(mg_ || '01', 'YYYYMMDD'), -1),
                    'YYYYMM');

    if lsk_ is null then
      time1_ := sysdate;
      --Вычисляем после-следующий месяц, для partitions
      trunc_part('saldo_usl', mg1_);
      --Подготовка временных таблиц...
      execute immediate 'TRUNCATE TABLE t_charges_for_saldo';
      execute immediate 'TRUNCATE TABLE t_changes_for_saldo';
      execute immediate 'TRUNCATE TABLE t_payment_for_saldo';
      execute immediate 'TRUNCATE TABLE t_privs_for_saldo';
      execute immediate 'TRUNCATE TABLE t_penya_for_saldo';
      execute immediate 'TRUNCATE TABLE t_subsidii_for_saldo';

    else
      delete from saldo_usl c
       where mg = mg1_
         and c.lsk=lsk_;
      delete from t_charges_for_saldo c
       where c.lsk=lsk_;
      delete from t_changes_for_saldo c
       where c.lsk=lsk_;
      delete from t_payment_for_saldo c
       where c.lsk=lsk_;
      delete from t_privs_for_saldo c
       where c.lsk=lsk_;
      delete from t_penya_for_saldo c
       where c.lsk=lsk_;
      delete from t_subsidii_for_saldo c
       where c.lsk=lsk_;
    end if;

    --Текущее начисление
    if lsk_ is null then
      time_ := sysdate;
      insert into t_charges_for_saldo
        (lsk, summa, org, usl)
        select
         p.lsk, sum(p.summa) as summa, t.fk_org2, p.usl
          from c_charge p, nabor k, t_org t, params m
         where p.type = 1
           and k.usl = p.usl
           and k.lsk=p.lsk
           and k.org=t.id
         group by p.lsk, p.usl, t.fk_org2;
      commit;
      logger.log_(time_, 'INSERT INTO t_charges_for_saldo (USL)');
    else
        insert into t_charges_for_saldo
          (lsk, summa, org, usl)
          select
           p.lsk, sum(p.summa) as summa, t.fk_org2, p.usl
            from c_charge p, nabor k, t_org t, params m
           where p.type = 1
             and k.usl = p.usl
             and k.lsk=p.lsk
             and p.lsk=lsk_
             and k.org=t.id
           group by p.lsk, p.usl, t.fk_org2;
    end if;

  --## надо быть готовым к отсуствию орг в c_change при выполнении перерасчетов суммами
  --
  --перерасчеты
    if lsk_ is null then
      time_ := sysdate;
      --1 часть - для формирования сальдо
      insert into t_changes_for_saldo
        (lsk, summa, org, usl, type)
      select t.lsk, t.summa, t.org, t.usl, t.type  
        from v_changes_for_saldo t;
      --2 часть - для формирования задолжности по периодам
      commit;
      logger.log_(time_, 'INSERT INTO t_changes_for_saldo (USL)');
    else
      insert into t_changes_for_saldo
        (lsk, summa, org, usl, type)
      select lsk, sum(summa) as summa, org, usl, type
        from (
          select /*+ INDEX (k A_NABOR2_I)*/
          p.lsk, p.summa, p.usl, t.fk_org2 as org, decode(p.type,1,1,2,1,3,3,0) as type
           from a_nabor2 k, c_change p, t_org t, params m
          where k.lsk = p.lsk and k.lsk=lsk_
            and p.mg2 between k.mgFrom and k.mgTo
            and k.usl = p.usl
            and k.org=t.id
            and p.org is null  -- где не указан код орг и старые периоды
            and exists             --и где найдена услуга в архивном справочнике
            (select /*+ INDEX (n A_NABOR2_I)*/* from a_nabor2 n where n.lsk=k.lsk and p.mg2 between n.mgFrom and n.mgTo
             and n.usl=k.usl)
            and p.mg2 < m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
          select
          p.lsk, p.summa, p.usl, t.fk_org2, decode(p.type,1,1,2,1,3,3,0) as type
           from nabor k, c_change p, t_org t, params m
          where k.lsk = p.lsk and k.lsk=lsk_
            and k.usl = p.usl
            and k.org=t.id     --не должно быть такого, так как не понятно где брать орг
            and p.org is null  -- где не указан код орг и старые периоды
            and not exists             --и где НЕ найдена услуга в архивном справочнике
            (select /*+ INDEX (n A_NABOR2_I)*/* from a_nabor2 n where n.lsk=k.lsk and p.mg2 between n.mgFrom and n.mgTo and n.usl=k.usl)
            and p.mg2 < m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
         select
          p.lsk, p.summa, p.usl, t.fk_org2, decode(p.type,1,1,2,1,3,3,0) as type
           from nabor k, c_change p, t_org t, params m
          where k.lsk = p.lsk and k.lsk=lsk_
            and k.usl = p.usl
            and k.org=t.id
            and p.org is null  -- где не указан код орг и новые периоды
            and p.mg2 >= m.period
            and to_char(p.dtek, 'YYYYMM') = m.period
         union all
         select
          p.lsk, p.summa, p.usl, nvl(t.fk_org2, 0) as org, decode(p.type,1,1,2,1,3,3,0) as type
           from kart r, c_change p, t_org t, params m
          where r.lsk = p.lsk and r.lsk=lsk_
            and p.org=t.id
            and p.org is not null  -- где указан код орг и не важно какой период
            and to_char(p.dtek, 'YYYYMM') = m.period)
             group by lsk, org, usl, type;
    end if;

   --оплата
    if lsk_ is null then
      time_ := sysdate;
      insert into t_payment_for_saldo
        (lsk, summa, org, usl)
        select t.lsk, sum(t.summa) as summa, t.org, t.usl
          from kwtp_day t
         where t.priznak=1 and t.dat_ink between init.g_dt_start and init.g_dt_end
         group by t.lsk, t.org, t.usl;
      commit;
      logger.log_(time_, 'INSERT INTO t_payment_for_saldo (USL)');
    else
      insert into t_payment_for_saldo
        (lsk, summa, org, usl)
        select t.lsk, sum(t.summa) as summa, t.org, t.usl
          from kwtp_day t
         where t.priznak=1 and t.lsk=lsk_ and t.dat_ink between init.g_dt_start and init.g_dt_end
         group by t.lsk, t.org, t.usl;
    end if;

    --льготы
    if lsk_ is null then
      time_ := sysdate;
      insert into t_privs_for_saldo
        (lsk, summa, org, usl)
        select lsk, summa, org, usl from v_privs_for_saldo;
      commit;
      logger.log_(time_, 'INSERT INTO t_privs_for_saldo (USL)');
    else
      insert into t_privs_for_saldo
        (lsk, summa, org, usl)
        select lsk, summa, org, usl
          from v_privs_for_saldo c
         where c.lsk=lsk_;
    end if;

    --пеня
    if lsk_ is null then
      time_ := sysdate;
      insert into t_penya_for_saldo
        (lsk, summa, org, usl)
      select p.lsk, sum(p.summa) as summa, p.org, p.usl
        from kwtp_day p
       where p.priznak=0 and p.dat_ink between init.g_dt_start and init.g_dt_end
       group by p.lsk, p.usl, p.org;
      commit;
      logger.log_(time_, 'INSERT INTO t_penya_for_saldo (USL)');
    else
      insert into t_penya_for_saldo
        (lsk, summa, org, usl)
      select p.lsk, sum(p.summa) as summa, p.org, p.usl
        from kwtp_day p
       where p.priznak=0 and p.lsk=lsk_
       and p.dat_ink between init.g_dt_start and init.g_dt_end
       group by p.lsk, p.usl, p.org;
    end if;

    --субсидии - не работают уже нигде они!!!
/*    if lsk_ is null then
      time_ := sysdate;
      insert into t_subsidii_for_saldo
        (lsk, summa, org, usl)
        select p.lsk, sum(p.summa) as summa, k.org, p.usl
          from nabor k, c_charge p, params m
         where p.type = 2
           and k.usl = p.usl
         group by p.lsk, p.usl, k.org;
      commit;
      logger.log_(time_, 'INSERT INTO t_subsidii_for_saldo (USL)');
    else
      insert into t_subsidii_for_saldo
        (lsk, summa, org, usl)
        select p.lsk, sum(p.summa) as summa, k.org, p.usl
          from nabor k, c_charge p, params m
         where k.lsk = lsk_
           and p.type = 2
           and k.usl = p.usl
         group by p.lsk, p.usl, k.org;
    end if;*/

    if lsk_ is null then
      time_ := sysdate;
      --Формирование исходящего сальдо USL
      --учитываем субсидию в оборотах
      insert into saldo_usl
        (lsk, org, usl, uslm, summa, mg)
        select t.lsk,
               t.org,
               t.usl,
               u.uslm,
               sum(t.summa) as summa,
               mg1_ as mg
          from (select lsk, org, usl, summa
                  from saldo_usl
                 where mg = mg_
                union all
                select c.lsk, c.org, c.usl, c.summa
                  from t_charges_for_saldo c
                union all
                select c.lsk, c.org, c.usl, c.summa
                  from t_changes_for_saldo c
                union all
                select c.lsk, c.org, c.usl, c.summa * -1
                  from t_privs_for_saldo c
                union all
                select c.lsk, c.org, c.usl, c.summa * -1
                  from t_subsidii_for_saldo c
                 where c.usl <> '024' --эл.эн.субс не отображается на сальдо
                union all
                select c.lsk, c.org, c.usl, c.summa * -1
                  from t_payment_for_saldo c) t,
               kart k,
               usl u
         where k.lsk = t.lsk
           and t.usl = u.usl
         group by t.lsk, t.org, t.usl, u.uslm
         having sum(t.summa)<>0; --исключить нулевое сальдо

      if utils.get_int_param('GEN_CHK_C_DEB_USL') = 1 then
       --по-периодный способ распределения оплаты
       --(сформировать задолжность)
       c_dist_pay.gen_deb_usl_all;
      end if;
      logger.log_(time1_, 'gen_saldo');
    else
      insert into saldo_usl
        (lsk, org, usl, uslm, summa, mg)
        select t.lsk,
               t.org,
               t.usl,
               u.uslm,
               sum(t.summa) as summa,
               mg1_ as mg
          from (select lsk, org, usl, summa
                  from saldo_usl
                 where mg = mg_
                union all
                select c.lsk, c.org, c.usl, c.summa
                  from t_charges_for_saldo c
                union all
                select c.lsk, c.org, c.usl, c.summa
                  from t_changes_for_saldo c
                union all
                select c.lsk, c.org, c.usl, c.summa * -1
                  from t_privs_for_saldo c
                union all
                select c.lsk, c.org, c.usl, c.summa * -1
                  from t_subsidii_for_saldo c
                 where c.usl <> '024' --эл.эн.субс не отображается на сальдо
                union all
                select c.lsk, c.org, c.usl, c.summa * -1
                  from t_payment_for_saldo c) t,
               usl u
         where t.usl = u.usl
           and t.lsk = lsk_
         group by t.lsk, t.org, t.usl, u.uslm
         having sum(t.summa)<>0; --исключить нулевое сальдо
    end if;
    commit;
  end gen_saldo;

  procedure gen_saldo_houses
  -- Формирование сальдо по домам mg_ - текущий месяц
    -- ВЫПОЛНЯТЬ ПОСЛЕ ФОРМИРОВАНИЯ GEN_PREP_OPL!!!
   is
    stmt varchar2(5000);
    mg1_ varchar2(6);
    time_ date;
    mg_ params.period%type;
  begin
    select period into mg_ from params p;
    time_ := sysdate;
    --Вычисляем следующий месяц
    mg1_ := to_char(add_months(to_date(mg_ || '01', 'YYYYMMDD'), 1),
                    'YYYYMM');

    --Добавляем во временную таблицу
    execute immediate 'TRUNCATE TABLE t_saldo_lsk';
    insert into t_saldo_lsk
      (lsk, org, usl, uslm, status)
      select distinct k.lsk, a.org, a.usl, u.uslm, k.status
        from (select a.lsk, a.org, a.usl
                from saldo_usl a, v_params v
               where a.mg = v.period1
              union all
              select t.lsk, t.org, t.usl
                from t_charges_for_saldo t
              union all
              select t.lsk, t.org, t.usl
                from t_chpenya_for_saldo t -- текущая пеня, по услугам, готовится в пакете C_PENYA
              union all
              select t.lsk, t.org, t.usl
                from t_changes_for_saldo t
              union all
              select t.lsk, t.org, t.usl
                from t_subsidii_for_saldo t
              union all
              select t.lsk, t.org, t.usl
                from t_payment_for_saldo t
              union all
              select t.lsk, t.org, t.usl
                from t_privs_for_saldo t
              union all
              select t.lsk, t.org, t.usl from t_penya_for_saldo t
              union all
              select t.lsk, t.org, t.usl from xitog3_lsk t, v_params v
                where t.mg = v.period3 -- предыдущий период
              ) a,
             kart k,
             usl u
       where k.lsk = a.lsk
         and a.usl = u.usl;
    commit;

    delete from xitog3_lsk t where t.mg = mg_;
    insert into xitog3_lsk
      (lsk,
       org,
       usl,
       uslm,
       status,
       indebet,
       inkredit,
       charges,
       pinsal,   -- входящее сальдо по пене 
       poutsal, -- исходящее сальдо по пене
       pcur,     -- текущее начисление пени
       changes,
       ch_full,
       changes2,
       changes3,
       subsid,
       privs,
       payment,
       pn,
       outdebet,
       outkredit,
       mg)
      select t.lsk,
             t.org,
             t.usl,
             t.uslm,
             nvl(t.status, 0),
             sum(a.summa) as indebet, -- вх.дебет
             sum(b.summa) as inkredit,-- вх.кредит
             sum(nvl(e.summa, 0) + nvl(f.summa, 0) + nvl(w.summa, 0)  + nvl(w2.summa, 0)-
                 nvl(o.summa, 0) - nvl(g.summa, 0)) as charges, -- начисление
             sum(m.summa) as pinsal, -- входящее сальдо по пене
             sum(nvl(m.summa, 0) + nvl(p.summa, 0) - nvl(j.summa, 0)) as poutsal, -- исходящее сальдо по пене
             sum(p.summa) as pcur, -- текущее начисление пени
             sum(f.summa) as changes,  -- скидки
             sum(e.summa) as ch_full, -- полное начисление
             sum(w.summa) as changes2, -- доборы, возвраты
             sum(w2.summa) as changes3, -- корректировки сальдо перерасчетами
             sum(g.summa) as subsid, -- субсидии
             sum(o.summa) as privs, -- льготы
             sum(h.summa) as payment, -- оплата
             sum(j.summa) as pn, -- оплаченная пеня
             sum(k.summa) as outdebet, -- исх.дебет
             sum(l.summa) as outkredit, -- исх.кредит
             mg_ as mg
        from t_saldo_lsk t,
             (select t.lsk, t.org, t.usl, t.uslm, sum(summa) as summa
                from saldo_usl t
               where sign(summa) >= 0
                 and mg = mg_
               group by t.lsk, t.org, t.usl, t.uslm) a,
             (select t.lsk, t.org, t.usl, t.uslm, sum(summa) as summa
                from saldo_usl t
               where sign(summa) < 0
                 and mg = mg_
               group by t.lsk, t.org, t.usl, t.uslm) b,
             (select t.lsk, t.org, t.usl, t.uslm, sum(summa) as summa
                from saldo_usl t
               where sign(summa) >= 0
                 and mg = mg1_
               group by t.lsk, t.org, t.usl, t.uslm) k,
             (select t.lsk, t.org, t.usl, t.uslm, sum(summa) as summa
                from saldo_usl t
               where sign(summa) < 0
                 and mg = mg1_
               group by t.lsk, t.org, t.usl, t.uslm) l,
             t_charges_for_saldo e,
             t_privs_for_saldo o,
             (select t.lsk, t.org, t.usl, t.summa
                from t_changes_for_saldo t
               where t.type in (0)) f, -- скидки
             (select t.lsk, t.org, t.usl, t.summa
                from t_changes_for_saldo t
               where t.type in (1)) w, -- доборы, возвраты
             (select t.lsk, t.org, t.usl, t.summa
                from t_changes_for_saldo t
               where t.type in (3)) w2, -- корректировки сальдо перерасчетами
             t_subsidii_for_saldo g,
             t_payment_for_saldo h,
             t_penya_for_saldo j, -- оплаченная пеня
             (select t.lsk, t.org, t.usl, 
                 sum(t.poutsal) as summa from xitog3_lsk t, v_params v
                where t.mg = v.period3
                group by t.lsk, t.org, t.usl) m, --вх.сальдо по пене
             t_chpenya_for_saldo p -- текушая пеня
       where t.lsk = a.lsk(+)
         and t.org = a.org(+)
         and t.usl = a.usl(+)

         and t.lsk = b.lsk(+)
         and t.org = b.org(+)
         and t.usl = b.usl(+)

         and t.lsk = k.lsk(+)
         and t.org = k.org(+)
         and t.usl = k.usl(+)

         and t.lsk = l.lsk(+)
         and t.org = l.org(+)
         and t.usl = l.usl(+)

         and t.lsk = e.lsk(+)
         and t.org = e.org(+)
         and t.usl = e.usl(+)

         and t.lsk = o.lsk(+)
         and t.org = o.org(+)
         and t.usl = o.usl(+)

         and t.lsk = f.lsk(+)
         and t.org = f.org(+)
         and t.usl = f.usl(+)

         and t.lsk = w.lsk(+)
         and t.org = w.org(+)
         and t.usl = w.usl(+)

         and t.lsk = w2.lsk(+)
         and t.org = w2.org(+)
         and t.usl = w2.usl(+)

         and t.lsk = g.lsk(+)
         and t.org = g.org(+)
         and t.usl = g.usl(+)

         and t.lsk = h.lsk(+)
         and t.org = h.org(+)
         and t.usl = h.usl(+)

         and t.lsk = j.lsk(+)
         and t.org = j.org(+)
         and t.usl = j.usl(+)

         and t.lsk = p.lsk(+)
         and t.org = p.org(+)
         and t.usl = p.usl(+)

         and t.lsk = m.lsk(+)
         and t.org = m.org(+)
         and t.usl = m.usl(+)

       group by t.lsk, t.org, t.usl, t.uslm, nvl(t.status, 0)
       having
       nvl(sum(a.summa), 0) <> 0 or
       nvl(sum(b.summa), 0) <> 0 or
       sum(nvl(e.summa, 0) + nvl(f.summa, 0) + nvl(w.summa, 0)  + nvl(w2.summa, 0)-
           nvl(o.summa, 0) - nvl(g.summa, 0)) <> 0 or
       sum(nvl(p.summa, 0)) <> 0 or
       sum(nvl(f.summa, 0)) <> 0 or
       sum(nvl(e.summa, 0)) <> 0 or
       sum(nvl(w.summa, 0)) <> 0 or
       sum(nvl(w2.summa, 0)) <> 0 or
       nvl(sum(g.summa), 0) <> 0 or
       nvl(sum(o.summa), 0) <> 0 or
       nvl(sum(h.summa), 0) <> 0 or
       nvl(sum(j.summa), 0) <> 0 or
       nvl(sum(k.summa), 0) <> 0 or
       nvl(sum(l.summa), 0) <> 0 or
       nvl(sum(m.summa), 0) <> 0;


    -- выбираем уникальные дома + орг. + усл. для формирования отчетности по сальдо
    delete from t_saldo_lsk2;
    insert into t_saldo_lsk2
      (lsk, org, usl)
      select distinct t.lsk, t.org, t.usl from xitog3_lsk t;

    commit;

    delete from xitog3 where mg = mg_;
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
       pinsal,
       poutsal,
       pcur,
       changes,
       ch_full,
       changes2,
       changes3,
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
             sum(x.pinsal),
             sum(x.poutsal),
             sum(x.pcur),
             sum(x.changes),
             sum(x.ch_full),
             sum(x.changes2),
             sum(x.changes3),
             sum(x.subsid),
             sum(x.privs),
             sum(x.payment),
             sum(x.pn),
             sum(x.outdebet),
             sum(x.outkredit),
             k.fk_tp,
             x.mg
        from xitog3_lsk x, kart k, s_reu_trest s
       where x.mg = mg_
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

    -- выбираем уникальные дома + орг. + усл. для формирования отчетности по сальдо
    delete from t_saldo_reu_kul_nd_st;
    insert into t_saldo_reu_kul_nd_st
      (reu, kul, nd, status, org, usl, fk_lsk_tp)
      select distinct t.reu, t.kul, t.nd, t.status, t.org, t.usl, nvl(t.fk_lsk_tp,0) as fk_lsk_tp
        from xitog3 t;

    logger.ins_period_rep('1', mg_, null, 0);
    logger.ins_period_rep('14', mg_, null, 0);
    logger.ins_period_rep('81', mg_, null, 0);
    logger.ins_period_rep('89', mg_, null, 0);
    logger.ins_period_rep('90', mg_, null, 0);

    commit;
    logger.log_(time_, 'gen_saldo_houses');
  end gen_saldo_houses;

  procedure gen_xito13 is
    type_otchet constant number := 19; --начисление по услугам
    time_ date;
  begin
    time_ := sysdate;
    --ЗА МЕСЯЦ
    --Начисление по услугам
    delete from xito13 x where x.mg = (select p.period from params p);
    insert into xito13
      (usl, uslm, reu, kul, nd, trest, mg, summa)
      select c.usl,
             u.uslm,
             k.reu,
             k.kul,
             k.nd,
             s.trest,
             p.period,
             sum(c.summa)
        from c_charge c, kart k, s_reu_trest s, params p, usl u
       where c.lsk = k.lsk
         and c.type = 1
         and k.reu = s.reu
         and c.usl = u.usl
       group by c.usl, u.uslm, k.reu, k.kul, k.nd, s.trest, p.period;

    delete from period_reports p
     where p.id = type_otchet
       and p.mg = (select p.period from params p); --обновляем период для отчета
    insert into period_reports
      (id, mg)
    values
      (type_otchet, (select p.period from params p));
    commit;
    logger.log_(time_, 'gen.gen_xito13');
  end;

  procedure gen_debits_lsk_month(dat_ in date) is
    mg_  params.period%type;
    mg1_ params.period%type;
    mg3_ params.period%type;
    var_ params.kan_var%type;
    time_ date;
  begin
    time_ := sysdate;
    --задолжники по лицевым
    --формировать после архивных карточек
    --выполнять ДО перехода, выгружать, - когда угодно
    select period into mg_ from params;
    --Вычисляем следующий месяц
    mg1_ := to_char(add_months(to_date(mg_ || '01', 'YYYYMMDD'), 1),
                    'YYYYMM');
    --Вычисляем передыдущ месяц
    mg3_ := to_char(add_months(to_date(mg_ || '01', 'YYYYMMDD'), -1),
                    'YYYYMM');
    select nvl(p.kan_var, 0) into var_ from params p;
    if dat_ is not null then
      delete from debits_lsk_month d where d.dat = dat_;
    else
      delete from debits_lsk_month d where d.mg = mg_;
    end if;
    if var_ = 0 then
      --Киселевск - не работает ветка скорее всего))
      insert into debits_lsk_month
        (lsk, reu, kul, name, nd, kw, fio, status, opl, cnt_month, dolg,
         nachisl, penya, payment, pay_pen, mg, dat)
        select a.lsk, a.reu, a.kul, s.name, a.nd, a.kw, a.fio, a.status,
               a.opl,
               round(decode(b.summa, 0, 0, a.dolg / b.summa), 0) as cnt_month,
               a.dolg, b.summa as nachisl, a.penya, c.summa, a.pay_pen, case when dat_ is null then mg_
                                                             else null end,
               dat_ --1 - часть - долги по текущему фонду
          from (select t.k_lsk_id, t.lsk, t.reu, t.kul, t.nd,
                        t.kw, t.fio, t.status, t.opl, s.dolg as dolg,
                        e.penya as penya, f.pay_pen
                   from arch_kart t,
                        (select lsk, sum(summa) as dolg
                            from saldo_usl
                           where usl not in (select u.usl_id from usl_excl u)
                             and mg = mg1_
                           group by lsk) s,
                        (select lsk, sum(penya) as penya
                            from a_penya
                           where mg = mg_
                           group by lsk) e,
                        (select lsk, sum(t.penya) as pay_pen
                            from a_kwtp_mg t
                           where mg = mg_
                           group by lsk) f, v_lsk_tp tp
                  where t.mg = mg_
                    and t.lsk = s.lsk(+)
                    and t.lsk = e.lsk(+)
                    and t.lsk = f.lsk(+)
                    and t.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')--Кис.просили исключить счета капрем 30.07.2015
                    and t.psch <> 8) a,
               (select k.k_lsk_id, sum(d.summa_it) as summa
                   from arch_kart k, arch_charges d, usl u, v_lsk_tp tp
                  where d.mg = mg_
                    and k.mg = mg_
                    and k.lsk = d.lsk
                    and d.usl_id=u.usl
                    and d.usl_id not in (select u.usl_id from usl_excl u)
                    and k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')--Кис.просили исключить счета капрем 30.07.2015
                    --and u.cd not in ('кап.' , 'кап/св.нор') --Кис.просили исключить капрем 30.07.2015
                    and k.psch <> 8
                  group by k.k_lsk_id) b,
               (select k.lsk, sum(d.summa) as summa
                   from arch_kart k, a_kwtp_mg d, v_lsk_tp tp
                  where d.mg = mg_
                    and k.mg = mg_
                    and k.lsk = d.lsk
                    and k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')--Кис.просили исключить счета капрем 30.07.2015
                  group by k.lsk) c, spul s
         where a.k_lsk_id = b.k_lsk_id(+)
           and a.kul = s.id
           and a.lsk = c.lsk(+)
           and round(decode(b.summa, 0, 0, a.dolg / b.summa), 0) > 0
        union all
        select a.lsk, a.reu, a.kul, s.name, a.nd, a.kw, a.fio, a.status,
               a.opl,
               case when a.dolg > 0 then 2 else 0 end as cnt_month,
               a.dolg, b.summa as nachisl, a.penya, c.summa, a.pay_pen, case when dat_ is null then mg_
                                                             else null end,
               dat_--2 - часть - долги по закрытому фонду
          from (select t.lsk, t.k_lsk_id, t.reu, t.kul, t.nd,
                        t.kw, t.fio, t.status, t.opl, s.dolg as dolg,
                        e.penya as penya, f.pay_pen
                   from arch_kart t,
                        (select lsk, sum(summa) as dolg
                            from saldo_usl
                           where usl not in (select u.usl_id from usl_excl u)
                             and mg = mg1_
                           group by lsk) s,
                        (select lsk, sum(penya) as penya
                            from a_penya
                           where mg = mg_
                           group by lsk) e,
                        (select lsk, sum(t.penya) as pay_pen
                            from a_kwtp_mg t
                           where mg = mg_
                           group by lsk) f, v_lsk_tp tp
                  where t.mg = mg_
                    and t.lsk = s.lsk(+)
                    and t.lsk = e.lsk(+)
                    and t.lsk = f.lsk(+)
                    and t.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                    and t.psch = 8) a,
               (select k.k_lsk_id, sum(d.summa_it) as summa
                   from arch_kart k, arch_charges d, usl u, v_lsk_tp tp
                  where d.mg = mg_
                    and k.mg = mg_
                    and k.lsk = d.lsk
                    and d.usl_id=u.usl
                    and d.usl_id not in (select u.usl_id from usl_excl u)
                    and k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')--Кис.просили исключить счета капрем 30.07.2015
                    --and u.cd not in ('кап.' , 'кап/св.нор') --Кис.просили исключить капрем 30.07.2015
                    and k.psch <> 8
                  group by k.k_lsk_id) b,
               (select k.lsk, sum(d.summa) as summa
                   from arch_kart k, a_kwtp_mg d, v_lsk_tp tp
                  where d.mg = mg_
                    and k.mg = mg_
                    and k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                    and k.lsk = d.lsk
                  group by k.lsk) c, spul s
         where a.k_lsk_id = b.k_lsk_id(+)
           and a.kul = s.id
           and a.lsk = c.lsk(+)
           and a.dolg > 0;
    elsif var_=1 then
      --ТСЖ
      insert into debits_lsk_month
        (lsk, reu, kul, name, nd, kw, fk_deb_org, fio, status, opl,
         cnt_month, dolg, cnt_month2, dolg2, nachisl, penya, payment, mg, dat)
        select a.lsk, a.reu, a.kul, s.name, a.nd, a.kw, a.fk_deb_org, a.fio,
               a.status, a.opl,
                 case when a.psch not in (8,9) and nvl(b.summa,0) <> 0 then
                      a.cnt_month
                     when a.psch in (8,9) and nvl(b.summa,0) = 0 and nvl(a.dolg,0)  > 0 --по закрытым например
                     then 2 --ставим 2 мес.задолжности  (поправил 2 мес. для кис 07.08.2015) 
                     else 0
                     end 
                     as cnt_month,
                     nvl(a.dolg,0) /* долг же уже с учетом оплаты и изменений ред 22.03.12 - nvl(c.summa, 0) + nvl(e.summa, 0)*/
                     as dolg, --долг с учетом оплаты
               case when nvl(b.summa,0) <> 0 and (nvl(a.dolg,0)+ nvl(c.summa, 0)) / nvl(b.summa,0) >= 1
                    then a.cnt_month --(nvl(a.dolg,0)+ nvl(c.summa, 0)) / nvl(b.summa,0) ред.19.09.14
                    when nvl(b.summa,0) <> 0 and (nvl(a.dolg,0)+ nvl(c.summa, 0)) / nvl(b.summa,0) < 1
                    then 0
                    when nvl(b.summa,0) = 0 and nvl(a.dolg,0)+ nvl(c.summa, 0) > 0 --по закрытым например
                    then 1 --ставим 1 мес.задолжности
                    else 0
                    end as cnt_month2, nvl(a.dolg,0) + nvl(c.summa, 0) as dolg2,--долг без учета оплаты
               b.summa as nachisl, a.penya, c.summa, case when dat_ is null then mg_
                                                             else null end,
                                                               dat_
          from (select t.psch, t.k_lsk_id, t.lsk, t.fk_deb_org, t.reu, t.kul, t.nd, t.kw,
                        t.fio, t.status, t.opl, e.dolg as dolg,
                        e.penya as penya, e.cnt_month
                   from arch_kart t,
                        (select k.k_lsk_id, sum(a.summa) as dolg, sum(penya) as penya, 
                            sum(case when a.penya >0 then 1 else 0 end) as cnt_month
                            from kart k, a_penya a, v_lsk_tp tp
                           where k.lsk=a.lsk and a.mg = mg_
                                 and k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                           group by k.k_lsk_id) e, v_lsk_tp tp
                  where t.mg = mg_
                    and t.k_lsk_id = e.k_lsk_id(+)
                    and t.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                    and t.psch <> 8
                    ) a,
               (select k.k_lsk_id, sum(d.summa_it) as summa
                   from kart k, arch_charges d, v_lsk_tp tp --начисление
                  where k.lsk=d.lsk and d.mg = mg_
                        and k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                  group by k.k_lsk_id) b,
               (select k.k_lsk_id, sum(d.summa) as summa
                   from kart k, a_kwtp_mg d, v_lsk_tp tp --оплата
                  where k.lsk=d.lsk and d.mg = mg_
                        and k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                  group by k.k_lsk_id) c,
               (select k.k_lsk_id, sum(d.summa) as summa
                   from kart k, a_change d, v_lsk_tp tp  --изменения
                  where k.lsk=d.lsk and d.mg = mg_
                        and k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                  group by k.k_lsk_id) e,
                  spul s
         where a.k_lsk_id = b.k_lsk_id(+)
           and a.kul = s.id
           and a.k_lsk_id = c.k_lsk_id(+)
           and a.k_lsk_id = e.k_lsk_id(+)
           and nvl(a.dolg,0) > 0;
    elsif var_ in (2,4) then
    --для ТСЖ, задолжность по л.с. (реально кол-во мес)
    --и задолжностью считается не текущий период, а период по которому начислена пеня
      insert into debits_lsk_month
        (lsk, reu, kul, name, nd, kw, fk_deb_org, fio, status, opl,
         cnt_month, dolg, cnt_month2, dolg2, nachisl, pen_in, pen_cur, penya, payment, pay_pen, mg, dat)
        select a.lsk, a.reu, a.kul, s.name, a.nd, a.kw, a.fk_deb_org, a.fio,
               a.status, a.opl, a.cnt_month
                      as cnt_month,
                     nvl(a.dolg,0) /* долг же уже с учетом оплаты и изменений ред 22.03.12 - nvl(c.summa, 0) + nvl(e.summa, 0)*/
                     as dolg, --долг с учетом оплаты
               a.cnt_month as cnt_month2, nvl(a.dolg,0) + nvl(c.summa, 0) as dolg2,--долг без учета оплаты
               nvl(b.summa,0)+nvl(e.summa,0) as nachisl, a.pen_in, nvl(a.pen_cur,0)+nvl(a.pen_cor,0) as pen_cur, a.penya, c.summa, c.penya, case when dat_ is null then mg_
                                                             else null end,
                                                               dat_
          from (select t.psch, t.lsk, t.fk_deb_org, t.reu, t.kul, t.nd, t.kw,
                        t.fio, t.status, t.opl, e.dolg,
                        b.pen_in, d.pen_cur, f.pen_cor, e.penya, e.cnt_month
                   from arch_kart t left join 
                        (select k.lsk, count(*) as cnt_month,  --исх.сальдо по пене
                        sum(a.summa) as dolg, sum(penya) as penya
                            from kart k, a_penya a
                           where k.lsk=a.lsk and a.mg = mg_
                           and (var_=4 and nvl(a.summa,0) > 0  and a.mg1<>mg_ --кроме текущего --and nvl(a.penya,0) <> 0 
                           or var_<>4) --поправил по просьбе Своб., 14.04.2016
                           group by k.lsk) e on t.lsk = e.lsk
                        left join 
                        (select a.lsk,  --вх.сальдо по пене
                             sum(penya) as pen_in
                            from a_penya a
                           where a.mg = mg3_ --период -1 мес
                           group by a.lsk) b on t.lsk = b.lsk   
                        left join 
                        (select a.lsk,  --тек.начисл. пеня
                             round(sum(penya),2) as pen_cur
                            from a_pen_cur a
                           where a.mg = mg_
                           group by a.lsk) d on t.lsk = d.lsk   
                        left join 
                        (select a.lsk,  --тек.коррект. пени
                             sum(penya) as pen_cor
                            from a_pen_corr a
                           where a.mg = mg_
                           group by a.lsk) f on t.lsk = f.lsk   
                        join v_lsk_tp tp on t.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                  where t.mg = mg_
                    ) a,
               (select k.lsk, sum(d.summa_it) as summa
                   from kart k, arch_charges d, v_lsk_tp tp --начисление
                  where k.lsk=d.lsk and d.mg = mg_
                    and k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                  group by k.lsk) b,
               (select k.lsk, sum(d.summa) as summa, sum(d.penya) as penya
                   from kart k, a_kwtp_mg d, v_lsk_tp tp --оплата
                  where k.lsk=d.lsk and d.mg = mg_
                    and k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                  group by k.lsk) c,
               (select k.lsk, sum(d.summa) as summa
                   from kart k, a_change d, v_lsk_tp tp  --изменения
                  where k.lsk=d.lsk and d.mg = mg_
                    and k.fk_tp=tp.id and tp.cd in ('LSK_TP_MAIN')
                  group by k.lsk) e,
                  spul s
         where a.lsk = b.lsk(+)
           and a.kul = s.id
           and a.lsk = c.lsk(+)
           and a.lsk = e.lsk(+)
           and nvl(a.dolg,0) > 0;
    elsif var_=3 then
    --для ПОЛЫС ВРЕМЕННЫЙ ВАРИАНТ!!! (задолжностью считается всё что -1 месяц назад глядя на пеню), задолжность по л.с. (реально кол-во мес)
    --и задолжностью считается не текущий период, а период по которому начислена пеня
    insert into debits_lsk_month
        (lsk, k_lsk_id, reu, kul, name, nd, kw, fk_deb_org, fio, status, opl,
         cnt_month, dolg, cnt_month2, dolg2, nachisl, penya, payment, mg, dat)
        select a.lsk, a.k_lsk_id, a.reu, a.kul, s.name, a.nd, a.kw, a.fk_deb_org, a.fio,
               a.status, a.opl,
               a.cnt_month as cnt_month,
                     nvl(a.dolg,0) /* долг же уже с учетом оплаты и изменений ред 22.03.12 - nvl(c.summa, 0) + nvl(e.summa, 0)*/
                     as dolg, --долг с учетом оплаты
               a.cnt_month as cnt_month2, nvl(a.dolg,0) + nvl(c.summa, 0) as dolg2,--долг без учета оплаты
               b.summa as nachisl, a.penya, c.summa, case when dat_ is null then mg_
                                                             else null end,
                                                               dat_
          from (select t.psch, t.k_lsk_id, t.lsk, t.fk_deb_org, t.reu, t.kul, t.nd, t.kw,
                        t.fio, t.status, t.opl, e.dolg as dolg,
                        e.penya as penya, e.cnt_month
                   from arch_kart t, v_lsk_tp tp,
                        (select k.k_lsk_id, count(distinct a.mg1) as cnt_month,
                        sum(a.summa) as dolg, sum(penya) as penya
                            from kart k, a_penya a
                           where k.lsk=a.lsk and a.mg = mg_
                           and nvl(a.summa,0) <> 0
                           and a.mg1 <= mg3_ --бред
                           group by k.k_lsk_id) e
                  where t.mg = mg_
                    and t.k_lsk_id = e.k_lsk_id(+)
                    and t.psch <> 8  --закомментировал 22.11.2017 убрал коммент 29.11.2017
                    and t.fk_tp=tp.id
                    and tp.cd='LSK_TP_MAIN' --долг показать по основному лиц.счету
                    ) a,
               (select k.k_lsk_id, sum(d.summa_it) as summa
                   from kart k, arch_charges d --начисление
                  where k.lsk=d.lsk and d.mg = mg_
                  group by k.k_lsk_id) b,
               (select k.k_lsk_id, sum(d.summa) as summa
                   from kart k, a_kwtp_mg d --оплата
                  where k.lsk=d.lsk and d.mg = mg_
                  group by k.k_lsk_id) c,
               (select k.k_lsk_id, sum(d.summa) as summa
                   from kart k, a_change d  --изменения
                  where k.lsk=d.lsk and d.mg = mg_
                  group by k.k_lsk_id) e,
                  spul s
         where a.k_lsk_id = b.k_lsk_id(+)
           and a.kul = s.id
           and a.k_lsk_id = c.k_lsk_id(+)
           and a.k_lsk_id = e.k_lsk_id(+)
           and nvl(a.dolg,0) > 0;
    end if;


    if dat_ is not null then
      logger.ins_period_rep('54', null, dat_, 0);
      logger.ins_period_rep('69', null, dat_, 0);
      logger.ins_period_rep('82', null, dat_, 0);
      logger.ins_period_rep('80', null, dat_, 0);
    else
      logger.ins_period_rep('54', mg_, null, 0);
      logger.ins_period_rep('69', mg_, null, 0);
      logger.ins_period_rep('82', mg_, null, 0);
      logger.ins_period_rep('80', mg_, null, 0);
    end if;
    commit;
    logger.log_(time_, 'gen.gen_debits_lsk_month');
  end;

  procedure load_saldo(mg_ in varchar2)
  --Первоначальная загрузка сальдо mg_ - текущий месяц
   is
    stmt varchar2(2000);
    time_ date;
  begin
    time_ := sysdate;
    stmt  := 'TRUNCATE TABLE saldo';
    execute immediate stmt;
    stmt := 'INSERT INTO saldo (lsk, org, uslm, summa, mg)
               SELECT lsk, kod, USLM, SUM(SWX) summa, :mg1
               FROM SWX t
               GROUP BY lsk, kod, USLM';
    execute immediate stmt
      using mg_;
    commit;
    logger.log_(time_, 'gen.load_saldo');
  end load_saldo;

/*  procedure distrib_vols
  --Распределение кубов по домам, в конце месяца
   is
    time_ date;
  begin
  --устарело - закрыто!!!!
  --ред.06.11.12

    time_ := sysdate;
    --Чтоб сработал триггер, где и произойдёт распределение
    update c_vvod t set t.kub = t.kub, t.vol_add = t.vol_add
       where kub <> 0;
    commit;
    logger.log_(time_, 'gen.distrib_vols');
  end distrib_vols;
*/
/*  procedure prepare_arch_lsk(lsk_     in kart.lsk%type,
                             lsk_end_ in kart.lsk%type) is
  bill_pen_ number;
  begin
    --подготовка счета индивидуально по c_lsk_id
    for c in (select distinct c_lsk_id
                from kart k
               where k.lsk between lsk_ and lsk_end_) loop
      --начисление
      gen_c_charges(c.c_lsk_id);
      --сальдо
      gen_saldo(c.c_lsk_id);
      --архив
      prepare_arch(c.c_lsk_id);
      select nvl(p.bill_pen,0) into bill_pen_ from params p;
      if bill_pen_ = 1 then
        --пеня по тек. дате
        c_cpenya.gen_penya(c.c_lsk_id, 0);
      else
        --пеня по конечной дате месяца
        c_cpenya.gen_penya(c.c_lsk_id, 1);
      end if;
    end loop;
  end;
*/
  procedure prepare_arch_lsk(lsk_     in kart.lsk%type,
                             var_     in number) is
  bill_pen_ number;
  begin
    --подготовка счета индивидуально по lsk
    if var_ = 0 then
      --начисление
      gen_c_charges(lsk_);
      --сальдо
      gen_saldo(lsk_);
      --архив
      prepare_arch(lsk_);
    end if;
    --движение
    c_cpenya.gen_charge_pay(lsk_, 0);
    --пеня в любом случае
    select nvl(p.bill_pen,0) into bill_pen_ from params p;
    if bill_pen_ = 1 then
      --пеня по тек. дате
      c_cpenya.gen_penya(lsk_, 0, 0);
    else
      --пеня по конечной дате месяца
      c_cpenya.gen_penya(lsk_, 1, 0);
    end if;
    commit;
  end;

  procedure prepare_arch_k_lsk(k_lsk_id_     in kart.k_lsk_id%type,
                             pen_last_month_ in number,
                             var_     in number) is
  begin
    --подготовка счета индивидуально k_lsk
    for c in (select distinct c_lsk_id, k.lsk
                from kart k
               where k.k_lsk_id = k_lsk_id_) loop
      if var_ = 0 then
      --включить еще формирование архива
        --начисление
        gen_c_charges(c.lsk);
        --сальдо
        gen_saldo(c.lsk);
        --архив
        prepare_arch(c.lsk);
      end if;
      --движение
      c_cpenya.gen_charge_pay(c.lsk, 1);
      --пеня
      c_cpenya.gen_penya(c.lsk, nvl(pen_last_month_,0), 0);
      --порядок листов в счете
      upd_arch_kart2(k_lsk_id_, null);
      
    end loop;
    commit;
  end;

  procedure prepare_arch_adr(kul_ in kart.kul%type,
                             nd_  in kart.nd%type,
                             kw_  in kart.kw%type,
                             var_ in number) is
  begin
    --подготовка счета индивидуально по адресу
    for c in (select distinct c_lsk_id
                from kart k
               where k.kul = kul_
                 and k.nd = nd_
                 and k.kw = kw_) loop
      if var_ = 0 then
        --начисление
        gen_c_charges(c.c_lsk_id);
        --сальдо
        gen_saldo(c.c_lsk_id);
        --архив
        prepare_arch(c.c_lsk_id);
        --пеня
        c_cpenya.gen_charge_pay(c.c_lsk_id, 1);
        c_cpenya.gen_penya(c.c_lsk_id, 1, 0);
      elsif var_ = 1 then
        --только пеня
        c_cpenya.gen_charge_pay(c.c_lsk_id, 1);
        c_cpenya.gen_penya(c.c_lsk_id, 0, 0);
      end if;
    end loop;
    commit;
  end;

  procedure prepare_arch_all is
  begin
  Raise_application_error(-20000, 'Процедура prepare_arch_all не работает!');
    --подготовка всех счетов (по окончанию месяца)
    for c in (select k.lsk from kart k
      where not exists (--только те л/c, где нужен перерасчет
           select *
                  from t_objxpar x, u_list s, u_listtp tp where
                  s.fk_listtp=tp.id and tp.cd='Параметры лиц.счета'
                  and x.fk_list=s.id and s.cd='gen_bill'
                  and x.fk_lsk=k.lsk
                  and x.n1=0)
                  )
    loop
      prepare_arch(c.lsk);
    end loop;
  end;

  procedure prepare_arch(lsk_ in kart.lsk%type) is
    cnt_ number;
    mg_  varchar2(6);
    mg1_  varchar2(6);
    old_mg_  varchar2(6);
    -- Архив
    time_ date;
  begin
    time_ := sysdate;
    -- Создаем архивы
    --текущий месяц
    select p.period into mg_ from params p;
    --месяц вперед
    mg1_:=to_char(add_months(to_date(mg_, 'YYYYMM'), 1), 'YYYYMM');
    --месяц назад
    old_mg_:=to_char(add_months(to_date(mg_||'01','YYYYMMDD'),-1), 'YYYYMM');
    --архив расценок
    if lsk_ is null then
      trunc_part('a_prices', mg_);
      insert into a_prices
        (usl, summa, summa2, summa3, fk_org, mg)
        select usl, summa, summa2, summa3, fk_org, p.period from prices c, params p;
    end if;

    --архив платежей
    if lsk_ is null then
      trunc_part('a_kwtp', mg_);
      insert into a_kwtp
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
         iscorrect,
         num_doc,
         dat_doc,
         mg)
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
               c.iscorrect,
               c.num_doc,
               c.dat_doc,
               p.period
          from c_kwtp c, params p
         where 
         c.dat_ink between init.g_dt_start and init.g_dt_end;
    else
      delete from a_kwtp a
       where a.lsk=lsk_ and a.mg = mg_;
      insert into a_kwtp
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
         iscorrect,
         num_doc,
         dat_doc,
         mg)
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
               c.iscorrect,
               c.num_doc,
               c.dat_doc,
               p.period
          from c_kwtp c, params p
         where c.dat_ink between init.g_dt_start and init.g_dt_end
         and c.lsk = lsk_; --по дате (здесь dtek!!!)
    end if;

    if lsk_ is null then
      trunc_part('a_kwtp_mg', mg_);
      insert into a_kwtp_mg
        (id,
         lsk,
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
         mg)
        select c.id,
               c.lsk,
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
               c.c_kwtp_id,
               p.period
          from c_kwtp_mg c, params p
          where c.dat_ink between init.g_dt_start and init.g_dt_end;
    else
      delete from a_kwtp_mg a
       where a.lsk=lsk_ and a.mg = mg_;
      insert into a_kwtp_mg
        (id,
         lsk,
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
         mg)
        select c.id,
               c.lsk,
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
               c.c_kwtp_id,
               p.period
          from c_kwtp_mg c, params p
         where c.lsk = lsk_
               and c.dat_ink between init.g_dt_start and init.g_dt_end;
    end if;

--архив распределённой оплаты
    if lsk_ is null then
        trunc_part('a_kwtp_day', mg_);
        insert into a_kwtp_day
          (kwtp_id, summa, lsk, oper, dopl, nkom, nink, dat_ink, priznak, usl, org, fk_distr, sum_distr, id, mg, dtek)
        select
          t.kwtp_id, t.summa, t.lsk, t.oper, t.dopl, t.nkom, t.nink, t.dat_ink, t.priznak,
          t.usl, t.org, t.fk_distr, t.sum_distr, t.id,
          p.period, t.dtek
        from kwtp_day t, params p
        where t.dat_ink between init.g_dt_start and init.g_dt_end;
    else
        delete from a_kwtp_day a
          where a.lsk=lsk_ and a.mg = mg_;
        insert into a_kwtp_day
          (kwtp_id, summa, lsk, oper, dopl, nkom, nink, dat_ink, priznak, usl, org, fk_distr, sum_distr, id, mg, dtek)
        select
          t.kwtp_id, t.summa, t.lsk, t.oper, t.dopl, t.nkom, t.nink, t.dat_ink, t.priznak,
          t.usl, t.org, t.fk_distr, t.sum_distr, t.id,
          p.period, t.dtek
        from kwtp_day t, params p
        where t.lsk=lsk_
        and t.dat_ink between init.g_dt_start and init.g_dt_end;
    end if;

    --архив начисления
    if lsk_ is null then
      --trunc_part('a_charge', mg_);
      delete from a_charge2 a
       where mg_ between a.mgFrom and a.mgTo;
      insert into a_charge2
        (id,
         lsk,
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
         mgTo,
         kpr, kprz, kpro, kpr2, opl
         )
        select a_charge_id.nextval,
               c.lsk,
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
               p.period, -- одинаковые периоды!
               p.period,
         c.kpr, c.kprz, c.kpro, c.kpr2, c.opl
          from c_charge c, params p;
    else
      delete /*+ INDEX (a A_CHARGE2_I)*/ from a_charge2 a
       where a.lsk=lsk_ and mg_ between a.mgFrom and a.mgTo;
      insert into a_charge2
        (id,
         lsk,
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
         mgTo,
         kpr, kprz, kpro, kpr2, opl)
        select a_charge_id.nextval,
               c.lsk,
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
               p.period, --одинак. период!
               p.period,
         c.kpr, c.kprz, c.kpro, c.kpr2, c.opl
          from c_charge c, params p
         where c.lsk = lsk_;
    end if;

    --архив изменения начисления
    if lsk_ is null then
      trunc_part('a_change', mg_);
      insert into a_change
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
         show_bill,
         id,
         mg,
         mg2,
         vol)
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
               c.show_bill,
               c.id,
               p.period,
               c.mg2,
               c.vol
          from c_change c, params p
         where to_char(c.dtek, 'YYYYMM') = p.period; --по дате
    else
      delete from a_change a
       where a.lsk=lsk_ and a.mg = mg_;
      insert into a_change
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
         show_bill,
         id,
         mg,
         mg2,
         vol)
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
               c.show_bill,
               c.id,
               p.period,
               c.mg2,
               c.vol
          from c_change c, params p
         where to_char(c.dtek, 'YYYYMM') = p.period
           and c.lsk = lsk_; --по дате
    end if;

    --архив документов по изменению начисления
    if lsk_ is null then
      trunc_part('a_change_docs', mg_);
      insert into a_change_docs
        (id, mgchange, dtek, ts, user_id, text, mg)
        select c.id, c.mgchange, c.dtek, c.ts, c.user_id, c.text, p.period
          from c_change_docs c, params p
         where to_char(c.dtek, 'YYYYMM') = p.period; --по дате
    end if;

    if lsk_ is null then
      --архив домов
      trunc_part('a_houses', mg_);
      insert into a_houses
        (id, kul, nd, uch, house_type, fk_pasp_org, psch, mg, fk_other_org,
         fk_typespay)
        select c.id, c.kul, c.nd, c.uch, c.house_type, c.fk_pasp_org, c.psch,
               p.period, c.fk_other_org, c.fk_typespay
          from c_houses c, params p;

      --архив вводов
      trunc_part('a_vvod', mg_);
      insert into a_vvod
        (house_id,
         id,
         kub,
         edt_norm,
         usl,
         kub_man,
         kpr,
         kub_sch,
         sch_cnt,
         sch_kpr,
         cnt_lsk,
         vvod_num,
         vol_add,
         sch_add,
         kub_fact,
         kub_norm,
         kub_nrm_fact,
         kub_sch_fact,
         vol_add_fact,
         itg_fact,
         opl_add,
         use_sch,
         dist_tp,
         opl_ar,
         kub_ar,
         kub_ar_fact,
         kub_dist,
         nrm,
         kub_fact_upnorm,
         ishotpipeinsulated,
         istowelheatexist,
         mg)
        select c.house_id,
               c.id,
               c.kub,
               c.edt_norm,
               c.usl,
               c.kub_man,
               c.kpr,
               c.kub_sch,
               c.sch_cnt,
               c.sch_kpr,
               c.cnt_lsk,
               c.vvod_num,
               c.vol_add,
               c.sch_add,
               c.kub_fact,
               c.kub_norm,
               c.kub_nrm_fact,
               c.kub_sch_fact,
               c.vol_add_fact,
               c.itg_fact,
               c.opl_add,
               c.use_sch,
               c.dist_tp,
               c.opl_ar,
               c.kub_ar,
               c.kub_ar_fact,
               c.kub_dist,
               c.nrm,
               c.kub_fact_upnorm,
               c.ishotpipeinsulated,
               c.istowelheatexist,
               p.period
          from c_vvod c, params p;
    elsif lsk_ is not null then
      --архив домов
      delete from a_houses c where c.mg=mg_ and
        exists (select * from kart k where k.house_id=c.id
            and k.lsk=lsk_);
      insert into a_houses
        (id, kul, nd, uch, house_type, fk_pasp_org, psch, mg, fk_other_org)
        select c.id, c.kul, c.nd, c.uch, c.house_type, c.fk_pasp_org, c.psch, p.period, c.fk_other_org
          from c_houses c, params p
           where exists (select * from kart k where k.house_id=c.id
            and k.lsk=lsk_);

      --архив вводов
      delete from a_vvod c where c.mg=mg_ and
        exists (select * from kart k where k.house_id=c.house_id
            and k.lsk=lsk_);
      insert into a_vvod
        (house_id,
         id,
         kub,
         edt_norm,
         usl,
         kub_man,
         kpr,
         kub_sch,
         sch_cnt,
         sch_kpr,
         cnt_lsk,
         vvod_num,
         vol_add,
         sch_add,
         kub_fact,
         kub_norm,
         kub_nrm_fact,
         kub_sch_fact,
         vol_add_fact,
         itg_fact,
         opl_add,
         use_sch,
         dist_tp,
         opl_ar,
         kub_ar,
         kub_ar_fact,
         nrm,
         kub_fact_upnorm,
         ishotpipeinsulated,
         istowelheatexist,
         mg)
        select c.house_id,
               c.id,
               c.kub,
               c.edt_norm,
               c.usl,
               c.kub_man,
               c.kpr,
               c.kub_sch,
               c.sch_cnt,
               c.sch_kpr,
               c.cnt_lsk,
               c.vvod_num,
               c.vol_add,
               c.sch_add,
               c.kub_fact,
               c.kub_norm,
               c.kub_nrm_fact,
               c.kub_sch_fact,
               c.vol_add_fact,
               c.itg_fact,
               c.opl_add,
               c.use_sch,
               c.dist_tp,
               c.opl_ar,
               c.kub_ar,
               c.kub_ar_fact,
               c.nrm,
               c.kub_fact_upnorm,
               c.ishotpipeinsulated,
               c.istowelheatexist,
               p.period
          from c_vvod c, params p
           where exists (select * from kart k where k.house_id=c.house_id
              and k.lsk=lsk_);
    end if;

    if lsk_ is null then
      --справочник льгот
      trunc_part('a_spk_usl', mg_);
      insert into a_spk_usl
        (spk_id, usl_id, koef, mg)
        select c.spk_id, c.usl_id, c.koef, p.period
          from c_spk_usl c, params p;

    end if;

    --карточки проживающих
    if lsk_ is null then
      trunc_part('a_kart_pr', mg_);
      insert into a_kart_pr
        (id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n,
        dok_d, dok_v, dat_prop, dat_ub, relat_id,
        status_datb, status_dat, status_chng, k_fam, k_im, k_ot,
        fk_doc_tp, fk_nac, b_place, fk_frm_cntr, fk_frm_regn,
        fk_frm_distr, frm_town, frm_dat, fk_frm_kul, frm_nd,
        frm_kw, w_place, fk_ub, fk_to_cntr, fk_to_regn,
        fk_to_distr, to_town, fk_to_kul, to_nd, to_kw,
        fk_citiz, fk_milit, fk_milit_regn, priv_proc, mg)
        select c.id, c.lsk, c.fio, c.status, c.dat_rog, c.pol, c.dok, c.dok_c, c.dok_n,
          c.dok_d, c.dok_v, c.dat_prop, c.dat_ub, c.relat_id,
          c.status_datb, c.status_dat, c.status_chng, c.k_fam, c.k_im, c.k_ot,
          c.fk_doc_tp, c.fk_nac, c.b_place, c.fk_frm_cntr, c.fk_frm_regn,
          c.fk_frm_distr, c.frm_town, c.frm_dat, c.fk_frm_kul, c.frm_nd,
          c.frm_kw, c.w_place, c.fk_ub, c.fk_to_cntr, c.fk_to_regn,
          c.fk_to_distr, c.to_town, c.fk_to_kul, c.to_nd, c.to_kw,
          c.fk_citiz, c.fk_milit, c.fk_milit_regn, c.priv_proc, p.period
        from c_kart_pr c, params p;
    else
      delete from a_kart_pr a
       where a.lsk=lsk_ and a.mg = mg_;
      insert into a_kart_pr
        (id, lsk, fio, status, dat_rog, pol, dok, dok_c, dok_n,
        dok_d, dok_v, dat_prop, dat_ub, relat_id,
        status_datb, status_dat, status_chng, k_fam, k_im, k_ot,
        fk_doc_tp, fk_nac, b_place, fk_frm_cntr, fk_frm_regn,
        fk_frm_distr, frm_town, frm_dat, fk_frm_kul, frm_nd,
        frm_kw, w_place, fk_ub, fk_to_cntr, fk_to_regn,
        fk_to_distr, to_town, fk_to_kul, to_nd, to_kw,
        fk_citiz, fk_milit, fk_milit_regn, priv_proc, mg)
        select c.id, c.lsk, c.fio, c.status, c.dat_rog, c.pol, c.dok, c.dok_c, c.dok_n,
          c.dok_d, c.dok_v, c.dat_prop, c.dat_ub, c.relat_id,
          c.status_datb, c.status_dat, c.status_chng, c.k_fam, c.k_im, c.k_ot,
          c.fk_doc_tp, c.fk_nac, c.b_place, c.fk_frm_cntr, c.fk_frm_regn,
          c.fk_frm_distr, c.frm_town, c.frm_dat, c.fk_frm_kul, c.frm_nd,
          c.frm_kw, c.w_place, c.fk_ub, c.fk_to_cntr, c.fk_to_regn,
          c.fk_to_distr, c.to_town, c.fk_to_kul, c.to_nd, c.to_kw,
          c.fk_citiz, c.fk_milit, c.fk_milit_regn, c.priv_proc, p.period
        from c_kart_pr c, params p
         where c.lsk = lsk_;
    end if;

    if lsk_ is null then
      --документы по льготам проживающих
      trunc_part('a_lg_docs', mg_);
      insert into a_lg_docs
        (id, c_kart_pr_id, doc, dat_begin, dat_end, main, mg)
        select c.id,
               c.c_kart_pr_id,
               c.doc,
               c.dat_begin,
               c.dat_end,
               c.main,
               p.period
          from c_lg_docs c, params p;

      --льготы проживающих
      trunc_part('a_lg_pr', mg_);
      insert into a_lg_pr
        (c_lg_docs_id, spk_id, type, mg)
        select c.c_lg_docs_id, c.spk_id, c.type, p.period
          from c_lg_pr c, params p;
    else
      --документы по льготам проживающих
      delete from a_lg_docs c where
       c.mg = mg_ and
       exists (select * from c_kart_pr p
             where p.lsk=lsk_
              and p.id=c.c_kart_pr_id);
      insert into a_lg_docs
        (id, c_kart_pr_id, doc, dat_begin, dat_end, main, mg)
        select c.id,
               c.c_kart_pr_id,
               c.doc,
               c.dat_begin,
               c.dat_end,
               c.main,
               p.period
          from c_lg_docs c, params p
           where exists (select * from c_kart_pr p
             where p.lsk=lsk_
              and p.id=c.c_kart_pr_id);

      --льготы проживающих
      delete from a_lg_pr c where
       c.mg = mg_ and
       exists (select * from c_lg_docs d, c_kart_pr p
             where p.lsk=lsk_
              and p.id=d.c_kart_pr_id and d.id=c.c_lg_docs_id);
      insert into a_lg_pr
        (c_lg_docs_id, spk_id, type, mg)
        select c.c_lg_docs_id, c.spk_id, c.type, p.period
          from c_lg_pr c, params p where
         exists (select * from c_lg_docs d, c_kart_pr p
             where p.lsk=lsk_
              and p.id=d.c_kart_pr_id and d.id=c.c_lg_docs_id);
    end if;

    --пеня
    if lsk_ is null then
      trunc_part('a_penya', mg_);
      insert into a_penya
        (summa, penya, mg1, mg, lsk, days)
        select c.summa, c.penya, c.mg1, p.period, c.lsk, c.days
          from c_penya c, params p;
    else
      delete from a_penya a
       where a.lsk = lsk_
         and a.mg = mg_;
      insert into a_penya
        (summa, penya, mg1, mg, lsk, days)
        select c.summa, c.penya, c.mg1, p.period, c.lsk, c.days
          from c_penya c, params p
          where c.lsk = lsk_;
    end if;
    --корректировки пени
    if lsk_ is null then
      delete from a_pen_corr a where a.mg=mg_;
      insert into a_pen_corr
        (id, lsk, penya, dopl, dtek, ts, fk_user, mg, fk_doc)
        select c.id, c.lsk, c.penya, c.dopl, c.dtek, c.ts, c.fk_user, p.period, c.fk_doc
          from c_pen_corr c, params p;
    else
      delete from a_pen_corr a
       where a.lsk = lsk_
         and a.mg = mg_;
      insert into a_pen_corr
        (id, lsk, penya, dopl, dtek, ts, fk_user, mg, fk_doc)
        select c.id, c.lsk, c.penya, c.dopl, c.dtek, c.ts, c.fk_user, p.period, c.fk_doc
          from c_pen_corr c, params p
          where c.lsk = lsk_;
    end if;
    --текущее начисление пени
    if lsk_ is null then
      trunc_part('a_pen_cur', mg_);
      insert into a_pen_cur
        (lsk, mg1, curdays, summa2, penya, fk_stav, dt1, dt2, mg)
      select c.lsk, c.mg1, c.curdays, c.summa2, c.penya, c.fk_stav, c.dt1, c.dt2, p.period as mg
        from c_pen_cur c, params p;
    else
      delete from a_pen_cur a
       where a.lsk = lsk_
         and a.mg = mg_;
      insert into a_pen_cur
        (lsk, mg1, curdays, summa2, penya, fk_stav, dt1, dt2, mg)
        select c.lsk, c.mg1, c.curdays, c.summa2, c.penya, c.fk_stav, c.dt1, c.dt2, p.period as mg
          from c_pen_cur c, params p
          where c.lsk = lsk_;
    end if;

    --наборы услуг
    if lsk_ is null then
      --trunc_part('a_nabor', mg_);
      delete /*+ INDEX (a A_NABOR2_I)*/ from a_nabor2 a
       where mg_ between a.mgFrom and a.mgTo;
      insert into a_nabor2
        (id, 
         lsk,
         usl,
         org,
         koeff,
         norm,
         fk_vvod,
         vol,
         vol_add,
         mgFrom,
         mgTo,
         fk_tarif,
         kf_kpr,
         nrm_kpr,
         nrm_kpr2,
         kf_kpr_wrz,
         kf_kpr_wro,
         kf_kpr_wrz_sch,
         kf_kpr_wro_sch,
         limit)
        select a_nabor_id.nextval, 
               c.lsk,
               c.usl,
               c.org,
               c.koeff,
               c.norm,
               c.fk_vvod,
               c.vol,
               c.vol_add,
               p.period, --одинак.период
               p.period,
               c.fk_tarif,
               c.kf_kpr,
               c.nrm_kpr,
               c.nrm_kpr2,
               c.kf_kpr_wrz,
               c.kf_kpr_wro,
               c.kf_kpr_wrz_sch,
               c.kf_kpr_wro_sch,
               c.limit
          from nabor c, params p;
    --сжать наборы
--    compress_nabor(null); -пока убрал 07.07.2015
    else
      delete /*+ INDEX (a A_NABOR2_I)*/ from a_nabor2 a
       where a.lsk = lsk_
         and mg_ between a.mgFrom and a.mgTo;
      insert into a_nabor2
        (id,
         lsk,
         usl,
         org,
         koeff,
         norm,
         fk_vvod,
         vol,
         vol_add,
         mgFrom,
         mgTo,
         fk_tarif,
         kf_kpr,
         nrm_kpr,
         nrm_kpr2,
         kf_kpr_wrz,
         kf_kpr_wro,
         kf_kpr_wrz_sch,
         kf_kpr_wro_sch,
         limit)
        select a_nabor_id.nextval, 
               c.lsk,
               c.usl,
               c.org,
               c.koeff,
               c.norm,
               c.fk_vvod,
               c.vol,
               c.vol_add,
               p.period,
               p.period,
               c.fk_tarif,
               c.kf_kpr,
               c.nrm_kpr,
               c.nrm_kpr2,
               c.kf_kpr_wrz,
               c.kf_kpr_wro,
               c.kf_kpr_wrz_sch,
               c.kf_kpr_wro_sch,
               c.limit
          from nabor c, params p
         where c.lsk = lsk_;
    --сжать наборы
--    compress_nabor(lsk_); пока убрал 07.07.2015
    end if;

    if lsk_ is null then
      delete from a_nabor_progs a where a.mg=mg_;
      insert into a_nabor_progs
        (id, lsk, usl, fk_tarif, mg)
      select t.id, t.lsk, t.usl, t.fk_tarif, p.period
       from nabor_progs t, params p;
    else
      delete from a_nabor_progs a
       where a.lsk = lsk_
         and a.mg = mg_;
      insert into a_nabor_progs
        (id, lsk, usl, fk_tarif, mg)
      select c.id, c.lsk, c.usl, c.fk_tarif, p.period
       from nabor_progs c, params p
       where c.lsk=lsk_;
    end if;

    -- Создаём архив начисления (без льгот и субсидий) по Л/C
    if lsk_ is null then
      trunc_part('arch_charges', mg_);
      insert into arch_charges
        (lsk, usl_id, summa, summa_it, mg)
        select n.lsk, n.usl, b.summa, a.summa, p.period
          from nabor n,
               params p,
               (select lsk, usl, sum(summa) as summa
                  from c_charge c
                 where c.type = 1
                 group by lsk, usl) a,
               (select lsk, usl, sum(summa) as summa
                  from (select lsk, usl, summa as summa
                          from c_charge c
                         where c.type = 1
                        union all
                        select lsk, usl, -1 * summa
                          from c_charge c
                         where c.type = 2
                        union all
                        select lsk, usl, -1 * summa
                          from c_charge c
                         where c.type = 4)
                 group by lsk, usl) b
         where n.lsk = a.lsk(+)
           and n.usl = a.usl(+)
           and n.lsk = b.lsk(+)
           and n.usl = b.usl(+)
           and (a.summa <> 0 or b.summa <> 0);
    else
      delete from arch_charges a
       where a.lsk = lsk_
         and a.mg = mg_;
      insert into arch_charges
        (lsk, usl_id, summa, summa_it, mg)
        select n.lsk, n.usl, b.summa, a.summa, p.period
          from nabor n,
               params p,
               (select lsk, usl, sum(summa) as summa
                  from c_charge c
                 where c.lsk=lsk_
                   and c.type = 1
                 group by lsk, usl) a,
               (select lsk, usl, sum(summa) as summa
                  from (select lsk, usl, summa as summa
                          from c_charge c
                         where c.lsk=lsk_
                           and c.type = 1
                        union all
                        select lsk, usl, -1 * summa
                          from c_charge c
                         where c.lsk=lsk_
                           and c.type = 2
                        union all
                        select lsk, usl, -1 * summa
                          from c_charge c
                         where c.lsk=lsk_
                           and c.type = 4)
                 group by lsk, usl) b
         where n.lsk = a.lsk(+)
           and n.usl = a.usl(+)
           and n.lsk = b.lsk(+)
           and n.usl = b.usl(+)
           and (a.summa <> 0 or b.summa <> 0)
           and n.lsk=lsk_;
    end if;

    --Добавляем закрытые лицевые и лицевые с пустым начисл. (чтоб тоже печатались в счетах)
    if lsk_ is null then
      insert into arch_charges
        (lsk, usl_id, summa, mg, summa_it)
        select lsk, '003', 0, p.period, 0
          from kart t, params p
         where not exists (select *
                  from arch_charges a
                 where a.mg = p.period
                   and a.lsk = t.lsk);
    end if;

    -- Создаём архивные карточки лицевых
    if lsk_ is null then
      trunc_part('arch_kart', mg_);
    insert into arch_kart --данный sql выполняется строго после insert into arch_charges!
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
      law_doc, law_doc_dt, prvt_doc, prvt_doc_dt,
      fk_pasp_org, fk_err, mg, dolg, cpn, penya,
      kpr_wrp, pn_dt, fk_tp, for_bill, sel1, vvod_ot, entr, pot, mot)
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
      k.law_doc, k.law_doc_dt, k.prvt_doc, k.prvt_doc_dt,
      k.fk_pasp_org, k.fk_err, p.period, a.dolg, k.cpn,
      nvl(d.penya,0)-nvl(b.penya,0) as penya,
      k.kpr_wrp, pn_dt, k.fk_tp,
      case when nvl(e.summa,0) <> 0 or nvl(b.penya,0) <> 0 or nvl(b.dolg/*b.penya*/,0) <> 0 then 1 --добавил пеню 09.03.2016, счет будет выбираться для печати если есть долг или текущ начисление))
        else 0 end as for_bill, k.sel1, k.vvod_ot, k.entr, k.pot, k.mot
      from kart k, params p,
      (select t.k_lsk_id, nvl(sum(summa),0) as dolg from saldo_usl s, kart t where
        t.lsk=s.lsk and s.mg=mg1_
        group by t.k_lsk_id) a,
      (select c.lsk, sum(c.penya) as penya, sum(c.summa) as dolg
          from c_penya c
          group by c.lsk) b,
      (select c.lsk, sum(c.penya) as penya
          from a_penya c
          where c.mg=old_mg_
          group by c.lsk) d,
      (select a.lsk, sum(a.summa) as summa
       from scott.c_charge a where 
       nvl(a.summa,0) <>0
       and a.type=1
       group by a.lsk) e --полное начисление (по тарифу)
      where k.k_lsk_id=a.k_lsk_id(+)
      and k.lsk=b.lsk(+)
      and k.lsk=d.lsk(+)
      and k.lsk=e.lsk(+);
      --обновление № листов (важен порядок вызова процедур!)              
      upd_arch_kart2(null, p_mg => mg_);
    else
      upd_acrh_kart(p_lsk => lsk_,
                    p_mg => mg_,
                    p_mg1 => mg1_,
                    p_old_mg => old_mg_);
    end if;

    -- Создаём архив изменений начисления по Л/C
    if lsk_ is null then
      trunc_part('arch_changes', mg_);
      insert into arch_changes
        (lsk, usl_id, summa, mg, id, show_bill, proc)
        select c.lsk, c.usl, sum(c.summa), p.period, c.type, c.show_bill, sum(proc) as proc
          from kart k, c_change c, params p --раз.изм.текущие
         where k.lsk = c.lsk
           and to_char(c.dtek, 'YYYYMM') = p.period --по дате
         group by c.lsk, c.usl, p.period, c.type, c.show_bill;
    else
      delete from arch_changes a
       where a.lsk=lsk_ and a.mg = mg_;
      insert into arch_changes
        (lsk, usl_id, summa, mg, id, show_bill, proc)
        select c.lsk, c.usl, sum(c.summa), p.period, c.type, c.show_bill, sum(proc) as proc --раз.изм.текущие
          from kart k, c_change c, params p
         where k.lsk = c.lsk
           and to_char(c.dtek, 'YYYYMM') = p.period --по дате
           and k.lsk=lsk_
         group by c.lsk, c.usl, p.period, c.type, c.show_bill;
    end if;

    -- Создаём архив субсидий по Л/C
    if lsk_ is null then
      trunc_part('arch_subsidii', mg_);
      insert into arch_subsidii
        (lsk, usl_id, summa, mg)
        select lsk, usl, sum(summa), p.period
          from c_charge c, params p
         where c.type = 2
         group by lsk, usl, p.period;
    else
      delete from arch_subsidii a
       where a.lsk=lsk_ and a.mg = mg_;
      insert into arch_subsidii
        (lsk, usl_id, summa, mg)
        select lsk, usl, sum(summa), p.period
          from c_charge c, params p
         where c.type = 2
           and c.lsk=lsk_
         group by lsk, usl, p.period;
    end if;

    -- Создаём архив льгот по Л/C
    if lsk_ is null then
      trunc_part('arch_privs', mg_);
      insert into arch_privs
        (lsk, summa, usl_id, lg_id, mg, cnt_main, cnt)
        select lsk,
               sum(summa),
               usl_id,
               lg_id,
               p.period,
               sum(c.main),
               count(*)
          from privs c, params p
         group by c.lsk, c.usl_id, p.period, lg_id;
    else
      delete from arch_privs a
       where a.lsk=lsk_ and a.mg = mg_;
      insert into arch_privs
        (lsk, summa, usl_id, lg_id, mg, cnt_main, cnt)
        select lsk,
               sum(summa),
               usl_id,
               lg_id,
               p.period,
               sum(c.main),
               count(*)
          from privs c, params p
         where c.lsk=lsk_
         group by c.lsk, c.usl_id, p.period, lg_id;
    end if;

    -- Создаём архив подготовительных объемов для начисления
    if lsk_ is null then
      --trunc_part('a_charge_prep', mg_);
      delete from a_charge_prep2 a
       where mg_ between a.mgFrom and a.mgTo;
       insert into a_charge_prep2
         (lsk, usl, vol, kpr, kprz, kpro, sch, dt1, dt2, tp, vol_nrm, vol_sv_nrm, kpr2, opl, fk_spk, mgFrom, mgTo)
       select
         lsk, usl, vol, kpr, kprz, kpro, sch, dt1, dt2, tp, vol_nrm, vol_sv_nrm, kpr2, opl, fk_spk, mg_ as mgFrom, mg_ as mgTo
       from c_charge_prep t;
    else
      delete from a_charge_prep2 a
       where a.lsk=lsk_ and mg_ between a.mgFrom and a.mgTo;
       insert into a_charge_prep2
         (lsk, usl, vol, kpr, kprz, kpro, sch, dt1, dt2, tp, vol_nrm, vol_sv_nrm, kpr2, opl, fk_spk, mgFrom, mgTo)
       select
         lsk, usl, vol, kpr, kprz, kpro, sch, dt1, dt2, tp, vol_nrm, vol_sv_nrm, kpr2, opl, fk_spk, mg_ as mgFrom, mg_ as mgTo
       from c_charge_prep t
       where t.lsk=lsk_;
    end if;

    -- Создаём архив оплаты по Л/C
    --ARCH_KWTP больше не обслуживаем .....мляяяяя используется в архивной справке

    --обновляем период для отчета
    if lsk_ is null then
    logger.ins_period_rep('12', mg_, null, 0); --тип отчета (архивы)
    logger.ins_period_rep('52', mg_, null, 0); --списки по субсидии
    logger.ins_period_rep('56', mg_, null, 0); --Список льготников
    logger.ins_period_rep('58', mg_, null, 0); --Список квартиросъемщиков, имеющих счетчики учета воды
    logger.ins_period_rep('60', mg_, null, 0); --тип статистика по программам/пакетам (Э+)
    logger.ins_period_rep('62', mg_, null, 0);
    logger.ins_period_rep('63', mg_, null, 0);
    logger.ins_period_rep('64', mg_, null, 0);

    logger.ins_period_rep('66', mg_, null, 0);
    logger.ins_period_rep('67', mg_, null, 0);
    logger.ins_period_rep('68', mg_, null, 0);
    logger.ins_period_rep('73', mg_, null, 0);
    logger.ins_period_rep('74', mg_, null, 0);
    logger.ins_period_rep('75', mg_, null, 0);
    logger.ins_period_rep('77', mg_, null, 0);
    logger.ins_period_rep('79', mg_, null, 0);
    logger.ins_period_rep('80', mg_, null, 0);

    logger.ins_period_rep('84', mg_, null, 0);
    logger.ins_period_rep('85', mg_, null, 0);
    logger.ins_period_rep('86', mg_, null, 0);
    logger.ins_period_rep('88', mg_, null, 0);
    logger.ins_period_rep('91', mg_, null, 0);
    logger.ins_period_rep('92', mg_, null, 0);
    logger.ins_period_rep('93', mg_, null, 0);
    logger.ins_period_rep('94', mg_, null, 0);
    
    logger.log_(time_, 'gen.prepare_arch');
    end if;
/*    if lsk_ is not null then
      --установить статус "пересчитано"
      c_valid.set_valid_lsk(lsk_, 0, 'gen_bill');
    end if;*/
    commit;
  end prepare_arch;

  procedure upd_acrh_kart(p_lsk in kart.lsk%type,
     p_mg in params.period%type,
     p_mg1 in params.period%type,
     p_old_mg in params.period%type
     ) is
  p_rec arch_kart%rowtype;
  begin
    begin
    select a.* into p_rec
     from arch_kart a
      where a.lsk = p_lsk
         and a.mg = p_mg and rownum=1; --rownum=1 - потому что по каким то причинам, (у П. бывают по две записи в arch_kart!!!)
    exception
    --обработка ситуации, когда еще не было записей в архиве
      when no_data_found then
        null;
    end;
    delete from arch_kart a
      where a.lsk = p_lsk
         and a.mg = p_mg;
    insert into arch_kart --данный sql выполняется строго после insert into arch_charges!
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
      law_doc, law_doc_dt, prvt_doc, prvt_doc_dt,
      fk_pasp_org, fk_err, mg, dolg, cpn, penya,
      kpr_wrp, pn_dt, fk_tp, for_bill, prn_num, prn_new, sel1, vvod_ot, entr, pot, mot)
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
      k.law_doc, k.law_doc_dt, k.prvt_doc, k.prvt_doc_dt,
      k.fk_pasp_org, k.fk_err, p.period, a.dolg, k.cpn,
      nvl(d.penya,0)-nvl(b.penya,0) as penya,
      k.kpr_wrp, pn_dt, k.fk_tp,
      --case when nvl(e.summa,0) <> 0 or nvl(b.dolg/*b.penya*/,0) <> 0 then 1 --счет будет выбираться для печати если есть долг или текущ начисление))
      case when nvl(e.summa,0) <> 0 or nvl(b.penya,0) <> 0 or nvl(b.dolg/*b.penya*/,0) <> 0 then 1 --добавил пеню 09.03.2016, счет будет выбираться для печати если есть долг или текущ начисление))
        else 0 end as for_bill, p_rec.prn_num, p_rec.prn_new, k.sel1, k.vvod_ot, k.entr, k.pot, k.mot
      from kart k, params p,
      (select t.k_lsk_id, nvl(sum(summa),0) as dolg from saldo_usl s, kart t where
        t.lsk=s.lsk and s.mg=p_mg1
        group by t.k_lsk_id) a,
      (select sum(c.penya) as penya, sum(c.summa) as dolg
          from c_penya c
          where c.lsk = p_lsk) b,
      (select sum(c.penya) as penya
          from a_penya c
          where c.mg=p_old_mg
          and c.lsk = p_lsk) d,
      (select a.lsk, sum(a.summa) as summa
       from scott.c_charge a where 
       nvl(a.summa,0) <>0
       and a.type=1
       group by a.lsk) e --полное начисление (по тарифу)
      where k.k_lsk_id=a.k_lsk_id(+)
      and k.lsk = p_lsk
      and k.lsk=e.lsk(+);
  end;

procedure upd_arch_kart2(p_klsk in number, p_mg in params.period%type) is
 i number;
 k_lsk_old number;
 l_mg params.period%type;
begin
--обновление порядк номера листа для печати 
--выполняется только для всех счетов!!! (для лиц. счета - не имеет смысла)

if p_mg is null then
  select p.period into l_mg from params p;
  else
    l_mg:=p_mg;
end if;

if p_klsk is null then
  update arch_kart t set t.prn_num=null, t.prn_new=null
    where t.mg=l_mg;
else
  update arch_kart t set t.prn_num=null, t.prn_new=null
    where t.mg=l_mg and t.k_lsk_id=p_klsk;
end if;  

for c2 in (select distinct t.reu from s_reu_trest t)
loop
  i:=0;
  k_lsk_old:=-1;
  for c in (select t.rowid as rd, t.k_lsk_id, tp.cd as lsk_tp
      from arch_kart t, spul s, v_lsk_tp tp where t.mg=l_mg 
      and t.reu=c2.reu and t.fk_tp=tp.id and t.for_bill=1
      and t.kul=s.id and nvl(p_klsk, t.k_lsk_id)=t.k_lsk_id
      order by s.name, scott.utils.f_ord_digit(t.nd), --Внимание! порядок точно такой как и в Form_print_bills.OD_main!!!
       scott.utils.f_ord3(t.nd) desc, 
       scott.utils.f_ord_digit(t.kw),
       scott.utils.f_ord3(t.kw) desc, 
        t.k_lsk_id, tp.npp
    ) 
  loop
    
    if k_lsk_old<>c.k_lsk_id then
      --новый лист
      i:=i+1;
      k_lsk_old:=c.k_lsk_id;
      update arch_kart t set t.prn_num=i, t.prn_new=1
        where t.rowid=c.rd;
    else
      --тот же лист, другой счет
      update arch_kart t set t.prn_num=i, t.prn_new=0
        where t.rowid=c.rd;
    end if;
  end loop;
end loop;
  
end;
  
  procedure gen_stat_debits is
    stmt varchar2(2500);
    type_otchet constant number := 22; --тип отчета
    dat_   date;
    time1_ date;
  begin
    time1_ := sysdate;
    select period_debits into dat_ from params;
    delete from debits_kw where dat = (select period_debits from params);
    delete from debits_houses
     where dat = (select period_debits from params);
    delete from debits_trest
     where dat = (select period_debits from params);

    insert into debits_kw
      (reu, kul, nd, kw, lsk, summa, mg, dat, kol_month)
      select k.reu, kul, nd, kw, d.lsk, summa, mg, period_debits, kol
        from kart k,
             params p,
             debits d,
             (select lsk, count(*) kol
                from debits
               where summap <> 0
               group by lsk) u
       where d.lsk = u.lsk(+)
         and d.lsk = k.lsk;

    insert into debits_houses
      (reu, kul, nd, summa, mg, dat, kol_month)
      select reu, kul, nd, sum(summa), mg, period_debits, kol_month
        from debits_kw, params
       where dat = period_debits
       group by reu, kul, nd, mg, period_debits, kol_month;

    insert into debits_trest
      (reu, summa, mg, dat, kol_month)
      select reu, sum(summa), mg, period_debits, kol_month
        from debits_houses, params
       where dat = period_debits
       group by reu, mg, period_debits, kol_month;

    delete from period_reports p
     where p.id = type_otchet
       and to_char(dat, 'YYYYMMDD') = to_char(dat_, 'YYYYMMDD'); --обновляем период для отчета

    stmt := 'insert into period_reports (id, dat,signed) values(:id, :dat,1)';
    execute immediate stmt
      using type_otchet, dat_;
    logger.log_(time1_, 'gen.oraparser stat_debits');
    commit;
  end;

  procedure go_next_month_year is
  begin
    --Переход на следующий месяц - год
    c_charges.trg_proc_next_month:=1;
    go_nye_phase1;
    go_nye_phase2;
    go_nye_phase3;
    c_charges.trg_proc_next_month:=0;
  end go_next_month_year;

  procedure go_nye_phase1 is
    type_otchet_  constant number := 50; --для таблицы long_table
    type_otchet2_ constant number := 51; --новые архивы
    summa_ number;
    cnt_ number;
    part_  number;
    mg_ params.period%type;
    l_cd_org t_org.cd%type;
  begin
    -- 1 - этап (сам переход)
    logger.log_(null, 'Начало I фазы перехода...');
    select period into mg_ from params;
    --Проверка
    --наличие оплаты не проинкассированной
      select nvl(count(*),0)
        into cnt_
        from c_kwtp c
       where to_char(c.dtek, 'YYYYMM') = mg_
         and nvl(c.nink, 0) = 0;
      if cnt_ <> 0 then
        raise_application_error(-20001,
                                'Стоп, есть не проинкассированные средства, в сумме:' ||
                                to_char(cnt_));
        return;
      end if;

    if init.get_state = 0 then
      raise_application_error(-20001,
                              'Стоп, не выполнено итоговое формирование за месяц, переход не возможен!');
      return;
    end if;

    --повторное формирование движения нужно, так как некоторые РКЦ принимают оплату уже будущим периодом
    --(до очистки итоговых таблиц!)
    logger.log_(null, 'Повторное формирование движения, начало');
    c_cpenya.gen_charge_pay_pen;
    logger.log_(null, 'Повторное формирование движения, окончание');
    ---
    
    select p.part into part_ from params p;
    -- чистим итоговые таблицы
    logger.log_(null, 'Очистка итоговых таблиц, начало');
    gen.gen_clear_tables;
    logger.log_(null, 'Очистка итоговых таблиц, окончание');

    --периоды пени (добавляем, в случае их отсутствия)
    insert into c_spr_pen
      (mg, dat, fk_lsk_tp, reu)
      select t.period1, add_months(p.dat,1), p.fk_lsk_tp, p.reu
       from c_spr_pen p, v_params t
       where p.mg=t.period and not exists
       (select * from c_spr_pen p1,
         v_params m where p1.mg=m.period1
         and p1.fk_lsk_tp=p.fk_lsk_tp
         );

    --периоды новых архивов фиксируем здесь
    delete from period_reports p
     where p.id in (type_otchet2_)
       and p.mg = mg_; --обновляем период для отчета
    insert into period_reports
      (id, mg, signed)
      select type_otchet2_, mg_, 1 from dual;

    --узнаем, будет ли переход года
    --если будет, сбрасывам номера квитанций и инкассаций
    select case when substr(mg_,1,4) <>
       substr(to_char(add_months(
         to_date(mg_ || '01', 'YYYYMMDD'), 1), 'YYYYMM'),1,4) then 1
         else 0 end into cnt_
        from dual;
    if cnt_ = 1 then
      update c_comps t set t.nink=1, t.nkvit=1;
    end if;
    -- меняем отчетный период
    update params
       set period    = to_char(add_months(to_date(period || '01', 'YYYYMMDD'),
                                          1),
                               'YYYYMM'),
           period_pl = to_char(add_months(to_date(period || '01', 'YYYYMMDD'),
                                          1),
                               'YYYYMM');
    select period into mg_ from params;
    --обязательно меняем отчетный период глобальных переменных (чтоб их!)
    init.g_dt_start:=to_date(mg_||'01', 'YYYYMMDD');
    init.g_dt_end:=last_day(init.g_dt_start);

    --нулим текущий период компьютеров
    update c_comps t set t.period=null 
      where t.period is not null;
    delete from period_reports p
     where p.id in (type_otchet_)
       and p.mg = (select period from params); --обновляем период для таблицы long_table

    --в форму по тарифам добавить период
    logger.ins_period_rep('78', mg_, null, 0);
    --новый период для сверки инкассаций
    logger.ins_period_rep('36', mg_, null, 0);
    commit;  --здесь коммит перехода, I - фазы
    logger.log_(null, 'Окончание I - фазы перехода...');
  end;

  procedure go_nye_phase2 is
    part_  number;
    type_otchet_  constant number := 50; --для таблицы long_table
    l_cnt number;
  begin
    logger.log_(null, 'Начало II - фазы перехода...');
    select p.part into part_ from params p;
    -- добавляем, удаляем партиции
    if nvl(part_, 0) = 1 then
      gen.gen_del_add_partitions;
    end if;

    --обновляем последний период оплаты, раз изменений
    --на 12 мес.вперёд
    update params p set p.period_forwrd=
      (select to_char(add_months(to_date(p.period||'01','YYYYMMDD'),12),'YYYYMM') as mg
         from params p);

    insert into period_reports
      (id, mg)
    values
      (type_otchet_,
       (select to_char(add_months(to_date(period || '01', 'YYYYMMDD'), 60),
                       'YYYYMM')
          from params)); -- +60 месяцев
    --установить новые месяцы в long_table, чтобы каждый раз не вычислять
    insert into long_table
    select "MG" from (
    select to_char(add_months(to_date(p.period||'01','YYYYMMDD'),-1*a.lvl+1),'YYYYMM')  as mg
                            from (select level as lvl
                                    from dual
                                  connect by level < 1200) a, params p
    ) a
    where to_char(mg) >= utils.get_str_param('FIRST_MONTH')
    and not exists
    (select * from long_table s where s.mg=a.mg);


    logger.log_(null, 'Переход-распределение оплаты, принятой будущим периодом, начало');
     if utils.get_int_param('DIST_PAY_TP') = 0 then
     --по-сальдовый способ распределения оплаты
       c_gen_pay.dist_pay_lsk_force; 
     else
     --по-периодный способ распределения оплаты
       null; --пока не написал
     end if;
    logger.log_(null, 'Переход-распределение оплаты, принятой будущим периодом, окончание');
     
    logger.log_(null, 'Переход-установка признаков закрытых домов начало');
    update c_houses t set t.psch=1
     where nvl(t.psch,0)=0 and
    not exists (select * from kart k where k.house_id=t.id
    and k.psch not in (8,9));
    commit;
    logger.log_(null, 'Переход-установка признаков закрытых домов окончание');
    --обнуляем vol_add по услуге с fk_calc=23 (Эл.энерг.МОП), ред.26.03.13
    logger.log_(null, 'Переход-начало обнуления расхода по fc_calc=23 услуге');
    update nabor n set n.vol_add=null where exists
      (select * from usl u where u.usl=n.usl and u.fk_calc_tp=23);
    commit;
    logger.log_(null, 'Переход-Окончание обнуления расхода по fc_calc=23 услуге');

    --устанавливаем кол-во прожив, с учетом выбывших и зарегистрированных
    --(например человек прописался в конце прошлого месяца)

--перенес в расчет начисления 11.04.14
--    logger.log_(null, 'Переход-utils.set_kpr начало');
--    utils.set_kpr(null);
--    logger.log_(null, 'Переход-utils.set_kpr окончание');

    --изменяем признаки счетчиков, в л.с. где они должны поменяться по срокам
    logger.log_(null, 'Переход-utils.upd_krt_sch_state начало');
    utils.upd_krt_sch_state(null);
    logger.log_(null, 'Переход-utils.upd_krt_sch_state окончание');
    --изменяем признаки проживающих, в л.с. где они должны поменяться по срокам
    logger.log_(null, 'Переход-utils.upd_c_kart_pr_state начало');
    utils.upd_c_kart_pr_state(null);
    logger.log_(null, 'Переход-utils.upd_c_kart_pr_state окончание');
    --обновляем доли проживающих, для долевого расчета начисления
    --только по тем, где существуют даты окончания (ред. 20.02.2012)
    --не обязательно, выполняется в процедуре начисление (ред.21.05.2012)

    --ОБЯЗАТЕЛЬНО, вынес из c_charge, надо выполнять здесь,
    --в c_charge приводит к DEADLOCK!!!
    --временно отменил, так как поставил в c_charge COMMIT ред.29.11.12
    --logger.log_(null, 'Переход-gen.c_kart.set_part_kpr_all_lsk начало');
    --c_kart.set_part_kpr_all_lsk;
    -- logger.log_(null, 'Переход-gen.c_kart.set_part_kpr_all_lsk окончание');

    --сброс признака итогового формирования отчетов
    init.set_state(0);
    commit; --коммит по окончанию I фазы

    --очистить таблицу оплаты, иначе влияет на сальдо...
    --её не надо уже чистить, сама почистится выше, в триггере, ред.10.01.13
    --execute immediate 'truncate table kwtp_day';

    --после I фазы, открываем базу
    admin.set_state_base(0);
    --выполнение автоначисление счетчиков
    logger.log_(null, 'Переход-gen.auto_charge начало');
    auto_charge;
    logger.log_(null, 'Переход-gen.auto_charge окончание');
    --подготовка сальдо, для возможности распределения начисленной пени по услугам
    gen_saldo(null);
    --подготовка послепереходной информации
    l_cnt:=c_charges.gen_charges(null, null, null, null, 1, 0);
    
    --сформировать оборотную ведомость обязательно!
    --иначе будут некорректно распределяться платежи в c_dist_pay (xitog3_lsk нужен текущего периода)
    gen_saldo(null);
    gen_saldo_houses;
    
    --ЗАЧЕМ здесь выполнять формирование движения и пени??
    --если при вызове л.с, и прочем они всё равно рассчитываются
    --(тем более что помечены как для пересчета выше)
    --ред.22.11.12

    --движение по лицевым за новый период
    --c_cpenya.gen_charge_pay(null, 1);
    --пеня за новый период
    --for c in (select distinct lsk from kart) loop
    --  c_cpenya.gen_penya(c.lsk, 0, 0);
    --end loop;
    commit;
    logger.log_(null, 'Окончание II - фазы перехода...');
  end;

  procedure go_nye_phase3 is
  l_p_mg1 params.period%type;
  l_p_mg2 params.period%type;
  l_cd_org t_org.cd%type;
  begin
  --Фаза III перехода
    logger.log_(null, 'Начало III - фазы перехода...');
    if utils.get_int_param('HAVE_LK') = 1 then
       --Если присутствует функция личного кабинета
       --то выполнение перехода в нём
        logger.log_(null, 'Начало выполнения перехода в ЛК...');
        select o.cd into l_cd_org
         from scott.t_org o, scott.t_org_tp tp
        where tp.id=o.fk_orgtp and tp.cd='РКЦ';
       execute immediate 'begin proc.go_next_month_year@apex(:cd_org_); end;'
        using l_cd_org;
        logger.log_(null, 'Окончание выполнения перехода в ЛК...');
        logger.log_(null, 'Начало выгрузки архивов в ЛК...');
        --отправляем архивы
        execute immediate
          'select min(t.mg), max(t.mg) from t_mg@Apex t, t_org@Apex o, scott.params p
             where t.mg<>p.period and t.fk_org=o.id
             and o.cd=:cd_org_'
          into l_p_mg1, l_p_mg2 using l_cd_org;
        ext_pkg.exp_base(1, l_p_mg1, l_p_mg2);
        logger.log_(null, 'Окончание выгрузки архивов в ЛК...');
    end if;
    logger.log_(null, 'Окончание III - фазы перехода...');
  end;

  procedure gen_clear_dates is
  begin
  --Выполняется после смены периода в params (во время перехода)
  --отменить не возможно!
  --чистка статусов вр.зарегистр c просроченной датой
   null;
  end;

  procedure gen_clear_tables is
  begin
    --Выполнять после сброса таблиц в архив!!!!

    --чистка кубов и корректировки субс по л/счетам и по домам
    p_vvod.g_tp:=3;--установить глобальную переменную - признак очистки по переходу
    update kart k set k.mhw = 0, k.mgw = 0, k.mel = 0, k.mot = 0, k.subs_cor = 0;
    p_vvod.g_tp:=0;
    --ред.12.11.12 зачем update nabor? если ниже через c_vvod он по сути выполняется...
    --update nabor n set n.vol=null, n.vol_add=null;

    --чистить поле edt_norm - не надо (переходит из месяца в месяц)
    update c_vvod c
       set c.kub     = 0,
           c.kub_man = 0,
           c.kpr     = 0,
           c.kub_sch = 0,
           c.sch_cnt = 0,
           c.sch_kpr = 0,
           c.cnt_lsk = 0,
           c.vol_add = 0,
           c.vol_add_fact = 0,
           c.kub_fact = 0,
           c.itg_fact = 0,
           c.opl_add = 0,
           c.kub_norm = 0,
           c.kub_nrm_fact = 0,
           c.kub_sch_fact = 0,
           c.opl_ar = 0,
           c.kub_ar = 0,
           c.kub_ar_fact = 0,
           c.nrm = null
           where (nvl(c.kub, 0) <> 0 or nvl(c.vol_add, 0) <> 0);

    --чистка таблиц от информации текущего месяца
/*    execute immediate 'truncate table c_change';
    execute immediate 'truncate table c_change_docs';
    execute immediate 'truncate table c_kwtp_mg';
    execute immediate 'truncate table c_kwtp';*/
    --переделал delete, очень медленно работает, ред.10.01.13

    -- сначала c_change, затем c_change_docs, иначе блокируется! и индекс на c_change.doc_id нужен!!!
    delete from c_change t where t.dtek between init.g_dt_start and init.g_dt_end;
    delete from c_change_docs t where t.dtek between init.g_dt_start and init.g_dt_end;
    delete from c_kwtp t where t.dat_ink between init.g_dt_start and init.g_dt_end;
    --корректировки пени
    delete from c_pen_corr t;
--    delete from c_kwtp_mg c; - не надо - удалится в триггере

/*    delete from c_change_docs c
     where to_char(c.dtek, 'YYYYMM') = (select period from params);
    delete from c_change c
     where to_char(c.dtek, 'YYYYMM') = (select period from params);

    delete from c_kwtp_mg c
     where to_char(c.dat_ink, 'YYYYMM') = (select period from params);
    delete from c_kwtp c
     where to_char(c.dat_ink, 'YYYYMM') = (select period from params);
  */
    --чистка периодов в сальдо
    --ЧИСТИТЬ САЛЬДО НЕЛЬЗЯ (Удаляется сальдо в счетах)
--    delete from saldo_usl t where t.mg < (select period from params p);
-- запрещенны комиты!... хотя может не хватить UNDO....
--    commit;

    -- чистка прошлых периодов
    delete from xxito10 t
     where dat <
           (select add_months(to_date(period, 'YYYYMM'), -1) from params)
           and t.mg is null;
    delete from xito5 t
     where dat <
           (select add_months(to_date(period, 'YYYYMM'), -1) from params)
           and t.mg is null;
    delete from xito5_ t
     where dat <
           (select add_months(to_date(period, 'YYYYMM'), -1) from params)
           and t.mg is null;
    delete from xxito11 t
     where dat <
           (select add_months(to_date(period, 'YYYYMM'), -1) from params)
           and t.mg is null;
    delete from xxito12 t
     where dat <
           (select add_months(to_date(period, 'YYYYMM'), -1) from params)
           and t.mg is null;

    /*delete from xxito14 t --не надо чистить эту таблицу, так как mg is not null и dat is not null!
     where dat <
           (select add_months(to_date(period, 'YYYYMM'), -1) from params)
           and t.mg is null;*/
           
    delete from debits_kw
     where dat <
           (select add_months(to_date(period, 'YYYYMM'), -1) from params);
    delete from debits_houses
     where dat <
           (select add_months(to_date(period, 'YYYYMM'), -1) from params);
    delete from debits_trest
     where dat <
           (select add_months(to_date(period, 'YYYYMM'), -1) from params);
    --удалить даты их периодов отчёта, ранее -1 мес
    delete from period_reports s
     where dat <
           (select add_months(to_date(period, 'YYYYMM'), -1) from params)
       and not exists (select * from reports r where r.id=s.id 
       and r.cd in ('2', '3', '4', '5', '7', '14', '15', '17', '35', '61'));
    -- удалить определенные типы из t_objxpar, позднее 3 лет
    delete from t_objxpar t where exists
       (select * from u_list u, params p where u.id=t.fk_list
         and t.mg < to_char(add_months(to_date(p.period, 'YYYYMM'), -24),'YYYYMM')
         and u.cd in ('ins_vol_sch','ins_sch'));
  --поставил коммит, ред.10.01.13
  commit;
  end gen_clear_tables;

  procedure gen_del_add_partitions is
    l_period1 char(6); -- след период
    l_period2 char(6); -- след период +1 месяц
  begin
    select t.period1, utils.add_months_pr(t.period1,1)
      into l_period1, l_period2
      from v_params t;

    make_part('c_chargepay', 'arch', 'MG' || l_period1, l_period1);

    make_part('saldo_usl',
              'data',
              'MG' || l_period2, l_period2);
 make_part('arch_changes', 'arch', 'MG' || l_period1, l_period1);
 make_part('arch_charges', 'arch', 'MG' || l_period1, l_period1);
 make_part('arch_kart', 'arch', 'MG' || l_period1, l_period1);
 make_part('arch_kwtp', 'arch', 'MG' || l_period1, l_period1);
 make_part('arch_privs', 'arch', 'MG' || l_period1, l_period1);
 make_part('arch_subsidii', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_prices', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_change', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_change_docs', 'arch', 'MG' || l_period1, l_period1);
 --a_charge теперь партицировано по LSK!
 --make_part('a_charge', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_houses', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_kart_pr', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_kwtp', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_kwtp_mg', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_lg_docs', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_lg_pr', 'arch', 'MG' || l_period1, l_period1);
 
 --a_nabor теперь партицирован по LSK!
 --make_part('a_nabor', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_penya', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_spk_usl', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_vvod', 'arch', 'MG' || l_period1, l_period1);
 make_part('xitog3', 'arch', 'MG' || l_period1, l_period1);
 make_part('statistics', 'arch', 'MG' || l_period1, l_period1);
 make_part('statistics_lsk', 'arch', 'MG' || l_period1, l_period1);
 make_part('xitog3_lsk', 'arch', 'MG' || l_period1, l_period1);
 make_part('xito_lg4', 'arch', 'MG' || l_period1, l_period1);
 make_part('t_corrects_payments', 'arch', 'MG' || l_period1, l_period1);
 make_part('expkartw', 'arch', 'MG' || l_period1, l_period1);
 make_part('expprivs', 'arch', 'MG' || l_period1, l_period1);
 make_part('xxito10', 'arch', 'MG' || l_period1, l_period1);
 make_part('xxito11', 'arch', 'MG' || l_period1, l_period1);
 make_part('xxito12', 'arch', 'MG' || l_period1, l_period1);
 make_part('xxito14', 'arch', 'MG' || l_period1, l_period1);
 make_part('xxito14_lsk', 'arch', 'MG' || l_period1, l_period1);
 
 --a_charge_prep теперь партицирован по LSK!
 --make_part('a_charge_prep', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_kwtp_day', 'arch', 'MG' || l_period1, l_period1);
 make_part('a_pen_cur', 'arch', 'MG' || l_period1, l_period1);
 make_part('log_actions', 'arch', 'MG' || l_period2, l_period2);
end;

  procedure make_part(tablename_ in varchar2,
                      tabspc_    in varchar2,
                      partname_  in varchar2,
                      mg_        in varchar2) is
    stmt varchar2(500);
    i    number;
  begin
    --удаляем партиции начиная от +12 месяцев вперёд и до текущего периода
   -- dbms_output.enable;
--    i := 12;
--    loop
--      exit when i = -1;
      --begin
      /*  stmt := 'alter table ' || tablename_ || '
              drop partition MG' ||
                to_char(add_months(to_date(mg_, 'YYYYMM'), i), 'YYYYMM') || '' ||
                ' update global indexes';*/
   -- dbms_output.put_line(stmt);
      --  execute immediate stmt;
      --exception
      --  when others then
      --    null;
      --end;
--      i := i - 1;
--    end loop;
    --создаем партицию
    stmt := 'alter table ' || tablename_ || '
          add partition ' || partname_ || '
          values less than(''' || mg_ || ''')
          tablespace ' || tabspc_ || '' || '';
    begin
      execute immediate stmt;
    exception
      when others then
        logger.log_(null, 'ВНИМАНИЕ! ОШИБКА СОЗДАНИЯ ПАРТИЦИИ tablename='||tablename_||' partname='||partname_);
        logger.log_(null, 'ВНИМАНИЕ! ОШИБКА СОЗДАНИЯ ПАРТИЦИИ ErrorCode='||sqlcode||' ErrorMessage='||SQLERRM);
    end;

  end;

  -- создание партиции расширенное
  procedure make_part2(tablename_ in varchar2,
                      tabspc_    in varchar2,
                      mg_        in varchar2,
                      p_drop in number) is
    stmt varchar2(500);
  begin
    --удаляем партицию
    if p_drop=1 then
      begin
        stmt := ' alter table ' || tablename_ || '
              drop partition MG' ||mg_||' update global indexes';
        execute immediate stmt;
      exception
        when others then
          null;
      end;
    end if;
    --создаем партицию
    stmt := 'alter table ' || tablename_ || '
          add partition MG'||mg_||'
          values less than(''' || mg_ || ''')
          tablespace ' || tabspc_ || '' || '';
    execute immediate stmt;
  end;

  procedure drop_part(tablename_ in varchar2, mg_ in varchar2) is
    stmt varchar2(500);
  begin
    --удаляем партицию
    begin
      stmt := ' alter table ' || tablename_ || '
              drop partition MG' || mg_;
      execute immediate stmt;
    exception
      when others then
        null;
    end;
  end;

  procedure trunc_part(tablename_ in varchar2, mg_ in varchar2) is
    stmt  varchar2(500);
    mg1_  varchar2(6);
    part_ number;
  begin
    select p.part into part_ from params p;
    --чистим партицию
    --особенность -  месяц партиции +1 от текущего
    if nvl(part_, 0) = 1 then
      mg1_ := to_char(add_months(to_date(mg_, 'YYYYMM'), 1), 'YYYYMM');
      stmt := ' alter table ' || tablename_ || '
            truncate partition MG' || mg1_ ||
              ' update global indexes';
      execute immediate stmt;
    elsif tablename_='c_chargepay' then
      stmt := ' delete from ' || tablename_ || ' where period=' || mg_;
      execute immediate stmt;
      commit;
    else
      stmt := ' delete from ' || tablename_ || ' where mg=' || mg_;
      execute immediate stmt;
      commit;
    end if;
  end;






  procedure auto_charge is
    cnt_sch_ number;
    part_ number;
  begin
  --автоначисление счетчиков
  --средний расход за прошлые 3 месяца начислить, у кого не начислено
  --выполнять сразу после перехода!

  --вначале заполняем аудит
  part_:=0;
  loop
    insert into log_actions
      (text, ts, fk_user_id, lsk, fk_type_act)
      select 'Автоначисление индивидуального прибора учета г.в., по-среднему за последние 3 месяца' as text,
       sysdate as ts, t.id, k.lsk as lsk, 2 as fk_type_act
      from kart k, t_user t where t.cd=user
        and
         nvl(decode(part_,0, k.mgw, k.mhw),0) = 0 and
         exists
         (select * from nabor n, usl u where k.lsk=n.lsk and n.sch_auto = 1
           and n.usl=u.usl and case when part_=0 and u.fk_calc_tp in (4, 18) then 1
                                              when part_=1 and u.fk_calc_tp in (3, 17) then 1
                                              else 0
                                              end =1)
           and
           case when part_=0 and k.psch in (1,3) then 1
                when part_=1 and k.psch in (1,2) then 1
                else 0
                end =1;

    exit when part_=1;
    part_:=part_+1;
  end loop;

  select nvl(p.cnt_sch,0) into cnt_sch_ from params p;
  if cnt_sch_ = 0 then
    --х.в.
    update kart k set k.mhw=
      (select round(avg(t.mhw),3) from arch_kart t, params p where t.k_lsk_id=k.k_lsk_id
             and t.mg between utils.add_months2(p.period,-3) and utils.add_months2(p.period,-1)
       and t.psch in (1,2))
       where
       nvl(k.mhw,0) = 0 and
       exists
       (select * from nabor n, usl u where k.lsk=n.lsk and n.sch_auto = 1
         and n.usl=u.usl and u.fk_calc_tp in (3, 17)
         )
         and k.psch in (1,2);
    --г.в.
    update kart k set k.mgw=
      (select round(avg(t.mgw),3) from arch_kart t, params p where t.k_lsk_id=k.k_lsk_id
             and t.mg between utils.add_months2(p.period,-3) and utils.add_months2(p.period,-1)
      and t.psch in (1,3))
       where
       nvl(k.mgw,0) = 0 and
       exists
       (select * from nabor n, usl u where k.lsk=n.lsk and n.sch_auto = 1
         and n.usl=u.usl and u.fk_calc_tp in (4, 18)
         )
         and k.psch in (1,3);
    else
    --х.в.
    --mhw посчитается само
    update kart k set k.phw=
      nvl(k.phw,0)+(select nvl(round(avg(t.mhw),3),0) from arch_kart t, params p where t.k_lsk_id=k.k_lsk_id
             and t.mg between utils.add_months2(p.period,-3) and utils.add_months2(p.period,-1)
      and t.psch in (1,2))
       where
       nvl(k.mhw,0) = 0 and
       exists
       (select * from nabor n, usl u where k.lsk=n.lsk and n.sch_auto = 1
         and n.usl=u.usl and u.fk_calc_tp in (3, 17)
         )
         and k.psch in (1,2);
    --г.в.
    --mgw посчитается само
    update kart k set k.pgw=
      nvl(k.pgw,0)+(select nvl(round(avg(t.mgw),3),0) from arch_kart t, params p where t.k_lsk_id=k.k_lsk_id
      and t.mg between utils.add_months2(p.period,-3) and utils.add_months2(p.period,-1)
      and t.psch in (1,3))
      where
       nvl(k.mgw,0) = 0 and
       exists
       (select * from nabor n, usl u where k.lsk=n.lsk and n.sch_auto = 1
         and n.usl=u.usl and u.fk_calc_tp in (4, 18)
         )
         and k.psch in (1,3);
  end if;


  logger.log_(null, 'gen.auto_charge (автоначисление счетчиков)');
  commit;
  end;




end gen;
/


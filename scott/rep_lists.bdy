create or replace package body scott.rep_lists is
  procedure report(rep_id_ in number,
                          mg_            in params.period%type,
                          org_ in number,
                          var_ in number,
                          cnt_ in number,
                          proc_ in number,
                          fname_ in varchar2,
                          prep_refcursor in out rep_refcursor) is
  uslg_ uslg.uslg%type;
  str_ varchar2(15);
  mg1_ params.period%type;
  begin
  --rep_id_ - ID отчета
  if rep_id_=1 then
  --Субсидии по л/с
    open prep_refcursor for
    select * from
    scott.v_kart_subs t where t.mg=mg_
    order by t.lsk;
  elsif rep_id_=2 then
  --Субсидии по л/с по обща
    open prep_refcursor for
      select * from
      scott.v_kart_subs2 t where t.mg=mg_
      order by t.lsk;
  elsif rep_id_=3 then
  --Скидки по домам
    open prep_refcursor for
      select t.* from scott.expkwni t
       where t.mg=mg_
       and exists
      (select * from scott.list_choices_reu l where l.reu=t.reu and l.sel=0);
  elsif rep_id_=4 then
  --Списки по льготникам
    open prep_refcursor for
    select t.* from scott.v_exporter3 t
     where t.mg=mg_;

  elsif rep_id_=5 then
  --Задолжники - устаревает, в новой версии использовать в report_to_dbf: rep_id_=24
    open prep_refcursor for
    select lsk, reu, kul, name, nd, kw, fio, status, opl, cnt_month, dolg, nachisl, penya, v.mg,
     v.payment, v.pay_pen, v.pen_in, v.pen_cur
    from scott.debits_lsk_month v
     where exists
    (select * from scott.list_choices_reu l where l.reu=v.reu and l.sel=0)
    and v.mg=mg_;

  elsif rep_id_=6 then
  --Выгрузка произвольного файла
    open prep_refcursor for
     'select * from scott.'||fname_;

  elsif rep_id_=7 then
  --Списки по льготникам
    open prep_refcursor for
    select u.nm2 as nm, s.name as org_name, t.summa,
        'РЭУ-'||t.reu||' '||substr(l.name,1,17)||','||ltrim(t.nd,'0')||'-'||ltrim(t.kw,'0')||', '||t.lsk as adr,
        initcap(rtrim(a.fio)) ||', '||to_char(a.dat_rog,'DD/MM/YYYY')||', '||trim(d.doc)||', '||decode(t.cnt_main, 0, 'польз.', 'носит.') as fio,
        null as other1,
        rtrim(p.name) as lg_name
       from xito_lg4 t, a_kart_pr2 a, (select /* ЧЁПОПАЛО НАПИСАЛ, РЕАЛЬНО */ c_kart_pr_id, mg, max(doc) as doc
          from a_lg_docs group by c_kart_pr_id, mg) d, usl u, sprorg s, spk p, spul l
       where t.mg=mg_ and t.org=org_
         and t.nomer=a.id and a.id=d.c_kart_pr_id and t.kul=l.id and t.usl = u.usl and t.lg_id=p.id
         and t.org = s.kod  and mg_ between a.mgFrom and a.mgTo and d.mg=mg_
          and exists
          (select * from scott.list_choices_reu l where l.reu=t.reu and l.sel=0);

  elsif rep_id_=8 then
  --Списки по начислению
    open prep_refcursor for
    select t.* from scott.expkartw t
       where t.mg=mg_
      and exists
      (select * from scott.list_choices_reu l where l.reu=t.reu and l.sel=0);

  elsif rep_id_=9 then
  --Выгрузка оборотки для УК в DBF
    open prep_refcursor for
    select u.uslm, u.nm1, a.*, b.opl, b.kpr from
    (select * from scott.xitog3 t where t.mg=mg_
      ) a,
    (select reu, kul, nd, sum(opl) as opl, sum(kpr) as kpr
      from scott.arch_kart t where t.mg=mg_ and psch <> 8
      group by reu, kul, nd) b, scott.uslm u
    where a.uslm=u.uslm and a.reu=b.reu(+) and a.kul=b.kul(+) and a.nd=b.nd(+)
    and exists
    (select * from scott.list_choices_reu l where l.reu=a.reu and l.sel=0);

  elsif rep_id_=10 then
  Raise_application_error(-20000, 'не работает отчет, перенесён в stat');
  --Задолжники где есть услуга, определенная в scott.list_choices_usl
    open prep_refcursor for
    select d.lsk, s.name_reu, trim(d.name) as street_name,
      ltrim(d.nd,'0') as nd, ltrim(d.kw,'0') as kw, d.fio, d.cnt_month, d.dolg, d.dat
      from scott.debits_lsk_month d, scott.s_reu_trest s
      where d.reu=s.reu
       and exists
      (select * from scott.list_choices_reu l where l.reu=d.reu and l.sel=0)
      and exists
      (select * from scott.nabor n, scott.list_choices_usl l, scott.usl u
        where n.lsk=d.lsk and n.usl=u.usl and decode(u.sptarn, 0, n.koeff, 1, n.norm, 2,
        nvl(n.koeff,0)*nvl(n.norm,0)) <> 0 and l.uslm=u.uslm and l.sel=0
        )
      and d.mg=mg_
      and
      ((var_=0 and d.cnt_month > cnt_) or
      (var_=1 and d.dolg > cnt_) )
      order by s.name_reu, d.name, d.nd, d.kw;


  elsif rep_id_ in (19) then
  --Долги для Сбербанка, (для Кис) Вар-1
  open prep_refcursor for
        select * from (
        select k.lsk, substr(trim(k.fio),1,25) as fio,
         o2.dolg_name||','||substr(l.name||', '||NVL(LTRIM(k.nd,'0'),'0')||','||NVL(LTRIM(k.kw,'0'),'0') ,1,64)  as adr,
          nvl(o.code_deb,1) as type,
          case when o.code_deb is not null then 'Квартплата'||' '||trim(o.name)
          else 'Квартплата'
          end as type_name,
         substr(mg_,5,2)||substr(mg_,1,4) as period, nvl(sum(s.summa),0)*proc_ as summa, sum(s.cur_chrg) as cur_chrg, k.psch, tp.cd as tp_cd --(nvl(s.summa,0) > 0 or k.psch <> 8)
         from scott.kart k, scott.v_lsk_tp tp,
          scott.spul l, scott.t_org o, scott.t_org o2, scott.t_org_tp tp2,
           (select lsk, sum(nvl(c.summa,0)+nvl(c.penya,0)) as summa, sum(decode(c.mg1, mg_, c.summa, 0)) as cur_chrg from  --пеня вместе с 24.10.13
            scott.a_penya c where c.mg=mg_
            group by lsk
           ) s  --ниже - для л.с. с долгами и новых л.с. ( в т.ч. без долгов)
          where k.kul=l.id and k.lsk=s.lsk(+) -- ред.10.07.20 попросили добавить активные лиц. без долга
          and k.fk_tp=tp.id and k.reu=o.reu
          and k.status not in (9) -- кроме арендаторов
          and o2.fk_orgtp=tp2.id and tp2.cd='Город'
          and exists
         (select * from scott.list_choices_reu l where l.reu=k.reu and l.sel=0)
          group by k.lsk, k.psch, nvl(o.code_deb,1), case when o.code_deb is not null then 'Квартплата'||' '||trim(o.name)
          else 'Квартплата'
          end, substr(trim(k.fio),1,25),
         o2.dolg_name||','||substr(l.name||', '||NVL(LTRIM(k.nd,'0'),'0')||','||NVL(LTRIM(k.kw,'0'),'0') ,1,64),
         tp.cd
         ) a
         where a.tp_cd in ('LSK_TP_MAIN','LSK_TP_RSO') and (nvl(a.summa,0) <> 0 or a.psch not in (8,9))
         order by lsk, period, type;
  elsif rep_id_ in (11,20,22) then
  --Долги для Сбербанка, Почты (для Кис)
  open prep_refcursor for
        select * from (
        select e.reu, k.lsk, substr(trim(k.fio),1,25) as fio,
         o2.dolg_name||','||substr(l.name||', '||NVL(LTRIM(k.nd,'0'),'0')||','||NVL(LTRIM(k.kw,'0'),'0') ,1,64)  as adr,
          1 as type, 'Квартплата' as type_name,
         substr(mg_,5,2)||substr(mg_,1,4) as period, nvl(sum(s.summa),0)*proc_ as summa, sum(s.cur_chrg) as cur_chrg, k.psch, tp.cd as tp_cd --(nvl(s.summa,0) > 0 or k.psch <> 8)
         from scott.kart k , scott.v_lsk_tp tp, scott.t_org o2, scott.t_org_tp tp2,
          scott.spul l, scott.list_choices_reu e,
           (select lsk, sum(nvl(c.summa,0)+nvl(c.penya,0)) as summa, sum(decode(c.mg1, mg_, c.summa, 0)) as cur_chrg from  --пеня вместе с 24.10.13
            scott.a_penya c where c.mg=mg_
            group by lsk
           ) s  --ниже - для л.с. с долгами и новых л.с. ( в т.ч. без долгов)
          where k.kul=l.id and k.lsk=s.lsk(+) -- ред.10.07.20 попросили добавить активные лиц. без долга
          and k.fk_tp=tp.id
          and k.status not in (9) -- кроме арендаторов
          and o2.fk_orgtp=tp2.id and tp2.cd='Город'
          and e.reu=k.reu and e.sel=0
          group by k.lsk, k.psch, substr(trim(k.fio),1,25),
         o2.dolg_name||','||substr(l.name||', '||NVL(LTRIM(k.nd,'0'),'0')||','||NVL(LTRIM(k.kw,'0'),'0') ,1,64),
         tp.cd, e.reu
         ) a
         where rep_id_=20 and a.tp_cd='LSK_TP_MAIN' and (nvl(a.summa,0) <> 0 or a.psch not in (8,9)) or
               rep_id_=22 and a.tp_cd in ('LSK_TP_ADDIT','LSK_TP_RSO')
               and (nvl(a.summa,0) <> 0 or a.psch not in (8,9))
         order by lsk, period, type;
   elsif rep_id_=15 then
   --Долги для Уралсиба
    open prep_refcursor for
     select k.fio||';'||t.name||',#'||k.kul||','||k.nd||','||k.kw||';'||
       k.lsk||';'||to_char(s.summa) as txt, s.summa
        from
       scott.kart k,
       (select lsk, sum(summa) as summa from scott.c_penya group by lsk) s, scott.t_org t, scott.t_org_tp tp
       where k.lsk=s.lsk and nvl(s.summa,0) <> 0
       and t.fk_orgtp=tp.id and tp.cd='Город'
       and  exists
       (select * from scott.list_choices_reu l where l.reu=k.reu and l.sel=0)
        order by k.kul, k.nd, k.kw;
  elsif rep_id_ in (16,17) then
  --Долги для Сбербанка, для Полыс, разбитые по периодам
  if rep_id_ = 16  then
    str_:='\';
    else
    str_:='корп.';
  end if;
    open prep_refcursor for
      select * from (
      select k.lsk, substr(trim(k.fio),1,25) as fio,
       substr(l.name||', '||NVL(LTRIM( replace(k.nd, '\', str_) ,'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') ,1,32)  as adr,
        1 as type, 'Квартплата' as type_name,
       substr(s.mg,5,2)||substr(s.mg,1,4) as period, sum(s.summa)*100 as summa
       from scott.kart k ,
        scott.spul l,
         (select lsk, mg1 as mg, c.summa as summa from
          scott.c_penya c
         ) s
        where k.lsk=s.lsk and k.kul=l.id and k.lsk=s.lsk
        and exists
       (select * from scott.list_choices_reu l where l.reu=k.reu and l.sel=0)
        group by k.lsk, substr(trim(k.fio),1,25), s.mg,
       substr(l.name||', '||NVL(LTRIM(replace(k.nd, '\', str_),'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') ,1,32)
       union all
      select k.lsk, substr(trim(k.fio),1,25) as fio,
       substr(l.name||', '||NVL(LTRIM(replace(k.nd, '\', str_),'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') ,1,32)  as adr,
        2 as type, 'Пеня' as type_name,
       substr(s.mg,5,2)||substr(s.mg,1,4) as period, sum(s.summa)*100 as summa
       from scott.kart k ,
        scott.spul l,
         (select lsk, mg1 as mg, c.penya as summa from
          scott.c_penya c
         ) s
        where nvl(s.summa,0) <> 0 and k.lsk=s.lsk and k.kul=l.id and k.lsk=s.lsk
        and exists
       (select * from scott.list_choices_reu l where l.reu=k.reu and l.sel=0)
        group by k.lsk, substr(trim(k.fio),1,25), s.mg,
       substr(l.name||', '||NVL(LTRIM(replace(k.nd, '\', str_),'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') ,1,32))
       order by lsk, period, type;
  elsif rep_id_ in (21) then
  --Долги для Сбербанка, для Полыс, совокупные (НЕ разбитые по периодам, и НЕ разбитые на пеню)
    str_:='корп.';
    --Переделал, в тысячный раз
    open prep_refcursor for
      select k.lsk, substr(trim(k.fio),1,25) as fio,
       substr(o.name||', '||l.name||', '||NVL(LTRIM( replace(k.nd, '\', str_) ,'0'),'0')||'-'||NVL(LTRIM(k.kw,'0'),'0') ,1,45)  as adr,
        '01' as type, 'Квартплата' as type_name, substr(mg_,5,2)||substr(mg_,1,4) as period,
        s.summa*100 as summa --если только текущий период, то поставить ноль
       from scott.kart k , scott.t_org o, scott.t_org_tp tp,
        scott.spul l,
         (select c.lsk, sum(nvl(c.summa,0)+nvl(c.penya,0)) as summa from
          scott.c_penya c where c.mg1 <= mg_ --задолжность+пеня (в т.ч. текущий период)
          group by c.lsk) s
        where k.lsk=s.lsk and k.kul=l.id and k.lsk=s.lsk and o.fk_orgtp=tp.id and tp.cd='Город'
        and exists
       (select * from scott.list_choices_reu l where l.reu=k.reu and l.sel=0)
       order by k.lsk;
  elsif rep_id_ in (23) then
  --Долги для Сбербанка, для Свободы, совокупные (НЕ разбитые по периодам, и НЕ разбитые на пеню)
    str_:='корп.';
    open prep_refcursor for
      select e.reu, k.lsk, substr(trim(k.fio),1,25) as fio,
       substr(o.name||','||l.name||','||NVL(LTRIM( replace(k.nd, '\', str_) ,'0'),'0')||','||NVL(LTRIM(k.kw,'0'),'0') ,1,45)  as adr,
        '01' as type, 'Квартплата' as type_name, substr(mg_,5,2)||substr(mg_,1,4) as period,
        s.summa as summa --если только текущий период, то поставить ноль
       from scott.kart k , scott.t_org o, scott.t_org_tp tp,
        scott.spul l, scott.list_choices_reu e,
         (select c.lsk, sum(nvl(c.summa,0)+nvl(c.penya,0)) as summa from
          scott.c_penya c where c.mg1 < mg_ --задолжность+пеня (без текущего периода)
          group by c.lsk) s
        where k.lsk=s.lsk and k.kul=l.id and k.lsk=s.lsk and o.fk_orgtp=tp.id and tp.cd='Город'
        and k.reu=e.reu and e.sel=0
        and s.summa>0
       order by e.reu, k.lsk;
  end if;
  end;


  procedure report_to_dbf(rep_id_ in number,
                          p_mg            in params.period%type,
                          p_org in number,
                          p_var in number,
                          p_cnt in number,
                          p_proc in number,
                          p_fname in varchar2) is
  ret varchar2(100);                        
  begin

  if rep_id_=24 then
  --Задолжники - выгрузка через Java
    delete from temp_debits_lsk_month;

    insert into temp_debits_lsk_month (lsk, reu, kul, name, nd, kw, fio, status, opl, cnt_month, dolg, nachisl, penya, mg,
     payment, pay_pen, pen_in, pen_cur)
    select lsk, reu, kul, name, nd, kw, fio, status, opl, cnt_month, dolg, nachisl, penya, v.mg,
     v.payment, v.pay_pen, v.pen_in, v.pen_cur
    from scott.debits_lsk_month v
     where exists
    (select * from scott.list_choices_reu l where l.reu=v.reu and l.sel=0)
    and v.mg=p_mg;
    ret:=p_java.saveDBF(p_table_in_name => 'temp_debits_lsk_month', p_table_out_name => p_fname);
  end if; 
  end; 

end rep_lists;
/


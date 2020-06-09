create or replace package scott.rep_bills is
  type ccur is ref cursor;
  type rec_bills is record(
    mg1         char(6),
    mg          char(6),
    k_lsk_id    number,
    lsk         char(8),
    streetname  varchar2(42), --
    fio         varchar2(50),
    monthyear   varchar2(30), --
    status      number(1),
    psch        number(1),
    phw         number,
    pgw         number,
    pel         number,
    kul         char(4),
    opl         number(7, 2),
    pldop       number(7, 2),
    kpr         number(3),
    kpr_ot      number(3),
    kpr_wr      number(3),
    kpr_wrp     number(3),
    name_org    t_org.name%type, --
    phone       t_org.phone%type, --
    phone2      t_org.phone2%type, --
    ki          number(2),
    subs_inf    number,
    npp         number,
    usl         char(3),
    nm          varchar2(38),
    lg_mains    number,
    lg_ids      varchar2(300), --
    itg_pen     number,
    itg_pay     number,
    itg_pen_pay number,
    tarif       number,
    pl_svnorm   number,
    vol         number, --
    charges     number, --
    privs       number, --
    changes0    number, --
    ch_proc0    number, --
    changes1    number, --
    changes2    number, --
    sl          number, --сальдо исх.ред.01.10.12
    subs        number, --
    sub_el      number, --
    itog        number, --
    itog_uszn   number, --
    lgname      char(25), --
    lg_id       number,
    cnt         number,
    lg_koef     number,
    fname_sch   varchar2(25), --вынести в параметры
    prev_chrg   number,
    prev_pay    number,
    payment     number,
    penya       number,
    monthpenya  number,
    monthpenya2 number,
    dolg        number,
    old_dolg    number,
    itog_dolg   number,
    ovrpaymnt   number,
    sal_in      number,
    dolg2       number,
    org         number,
    bill_brake  number
    );
  type tbl_bills is table of rec_bills;


  procedure get_breaks(p_reu in kart.reu%type,
                       p_cnt number,
                       p_mg in params.period%type,
                       p_recset OUT SYS_REFCURSOR);

  function pipe_bills(lsk_  in kart.lsk%type,
                      lsk1_ in kart.lsk%type,
                      var_  in number,
                      var2_ in number,
                      kul_  in kart.kul%type,
                      nd_   in kart.nd%type,
                      kw_   in kart.kw%type,
                      mg1_  in params.period%type,
                      mg2_  in params.period%type) return tbl_bills
    pipelined;

procedure main(p_sel_obj in number,
               p_reu in kart.reu%type,
               p_kul in kart.kul%type,
               p_nd in kart.nd%type,
               p_kw in kart.kw%type,
               p_lsk in kart.lsk%type,
               p_lsk1 in kart.lsk%type,
               p_firstrec in number,
               p_lastrec in number,
               p_var2 in number,
               p_var3 in number,
               p_cntrec in number,
               p_mg in params.period%type,
               p_rfcur out ccur
  );
--детализация счета
procedure detail(p_lsk  IN KART.lsk%TYPE,
                 p_mg   IN PARAMS.period%type,
                 p_rfcur out ccur);  
procedure detail2(p_lsk IN KART.lsk%TYPE,
                 p_mg   IN PARAMS.period%type,
                 p_bill_var in number,
                 p_tp in number, --признак услуги, подлежащей расшифровке
                 p_rfcur out ccur
  );        
procedure org(p_mg   IN PARAMS.period%type,
              p_var in number, --тип счета
              p_rfcur out ccur
  );           
procedure deb(p_k_lsk_id in number,
              p_lsk in kart.lsk%type,
              p_rfcur out ccur
  );  
--архивная справка, основной запрос
procedure arch(p_k_lsk in number, p_sel_obj in number, p_lsk in kart.lsk%type, 
               p_mg1 in params.period%type, p_mg2 in params.period%type,
               p_sel_uk    in varchar2, -- список УК
               p_tp in number default 0, -- 0- старая арх.спр., 1- новая
               p_rfcur out ccur);
--архивная справка, вспомогательный запрос
procedure arch_supp(p_k_lsk in number, 
               p_sel_obj in number, -- вариант выборки: 0 - по лиц.счету, 1 - по адресу, 2 - по УК
               p_lsk in kart.lsk%type, 
               p_mg1 in params.period%type, p_mg2 in params.period%type,
               p_sel_uk    in varchar2, -- список УК
               p_rfcur out ccur);               
end rep_bills;
/

create or replace package body scott.rep_bills is

procedure get_breaks(p_reu in kart.reu%type,
                     p_cnt number,
                     p_mg in params.period%type,
                     p_recset OUT SYS_REFCURSOR) is
begin
--получить разбиение счетов на партии
 if nvl(p_cnt,0) = 0 then
  OPEN p_recset FOR
    select 0 as first_rec, 1000000000 as last_rec, 'Все' as name
      from dual;
 else

  OPEN p_recset FOR
    select min(a.prn_num) as first_rec, max(a.prn_num) as last_rec, a.ths as name
    from (select k.prn_num, round(rownum/p_cnt) as ths from
    (select t.prn_num from arch_kart t where t.reu=p_reu and t.mg=p_mg
             order by t.prn_num) k
    ) a
    group by a.ths
    order by a.ths
    ;

/* способ обработки до 23.11.18
  OPEN p_recset FOR
    select min(a.k_lsk_id) as first_rec, max(a.k_lsk_id) as last_rec, a.ths as name
    from (select k.k_lsk_id, round(rownum/p_cnt) as ths from
    (select distinct t.k_lsk_id from kart t where t.reu=p_reu order by t.k_lsk_id) k
    ) a
    group by a.ths
    order by a.ths
    ;
*/
/*    select 0 as first_rec, 0 as last_rec, 'Все' as name
      from dual
    union all
    select distinct a.fst as first_rec,
     max(k.prn_num) over (partition by a.fst) as last_rec,
     'с ' || a.fst || ' по ' || max(k.prn_num) over (partition by a.fst) as name
     from (select nvl(lag(r.rn,1) over (order by 0),0)+1 as fst,
      r.rn as lst  from
       (select level*p_cnt as rn
      from dual connect by level <= 1000000) r) a,
     arch_kart k
     where k.mg=p_mg and k.reu=p_reu
     and k.prn_num between a.fst and a.lst
     order by first_rec;
*/
 end if;
end;

function pipe_bills(lsk_           IN KART.lsk%TYPE,
                         lsk1_          IN KART.lsk%TYPE,
                         var_           IN number,
                         var2_          IN number,
                         kul_           IN KART.kul%TYPE,
                         nd_            IN KART.nd%TYPE,
                         kw_            IN KART.kw%TYPE,
                         mg1_ IN PARAMS.period%TYPE,
                         mg2_ IN PARAMS.period%TYPE)
 return tbl_bills pipelined as
 l_bill_var number; --вариант формирования счета
 cur ccur;
 rec_ rec_bills;
 mg_ varchar(6);
 mg3_ varchar(6);
 fname_sch_ VARCHAR2(25);
 sqlstr_ VARCHAR2(200);
 sqlstr2_ VARCHAR2(200);
 sqlstr3_ VARCHAR2(350);
 sqlstr4_ VARCHAR2(500);
 sqlstr5_ VARCHAR2(300);
 sqlstr6_ VARCHAR2(100);
 sqlstr7_ VARCHAR2(650);
 sqlstr8_ VARCHAR2(50);
 sqlstr9_ VARCHAR2(300);
 sqlstr10_ VARCHAR2(300);
 sqlstr11_ VARCHAR2(300);
 sqlstr12_ VARCHAR2(300);
 sqlstr13_ VARCHAR2(2000);
 sqlstr14_ VARCHAR2(800);
 sqlstr15_ VARCHAR2(800);
 l_supress_sal number;

 mg_nolg_ VARCHAR2(6);

-- компилируется неустойчиво на oracle 9.xx
begin
-- logger_tst;
 mg_:=mg1_;
 --на месяц вперед
 mg3_:=to_char(add_months(to_date(mg_||'01','YYYYMMDD'),1),'YYYYMM');

 --период отмены льгот
  mg_nolg_:=utils.get_str_param('MG_NOLG');

  --подавлять строки с нулевым сальдо в счетах
  l_supress_sal:=utils.get_int_param('BILL_SUPRESS_SAL');
  if l_supress_sal = 1 then
    sqlstr15_:='';
  else
    sqlstr15_:='sum(sl.summa) <> 0 or';
  end if;
loop
  exit when to_number(mg_) > to_number(mg2_);
  --ред. оптимизация под 1 л.с.
  sqlstr_:= 'and l.lsk = '''||lsk1_||'''';
--  sqlstrlsk_:= 'and lsk = '''||lsk1_||'''';
/*    if lsk_ is not null and lsk1_ is not null then
      sqlstr_:= 'AND l.lsk BETWEEN '''||lsk_||''' AND '''||lsk1_||'''';
    else
      if kul_ is not null then
         sqlstr_:= ' and '||'l.kul='''||kul_||'''';
      end if;
      if nd_ is not null then
         sqlstr_:= sqlstr_||' and '||'l.nd='''||nd_||'''';
      end if;
      if kw_ is not null then
         sqlstr_:= sqlstr_||' and '||'l.kw='''||kw_||'''';
      end if;
    end if;*/

   --печатать ли по старому фонду счета?
   if nvl(var2_,0) = 0 then
     sqlstr8_:='and k.psch <> 8';
   else
     sqlstr8_:='';
   end if;

  select o.fk_bill_var into l_bill_var
    from kart k, t_org o
    where k.reu=o.reu
    and k.lsk=lsk1_;
  if l_bill_var is null then
    Raise_application_error(-20000, 'Должен быть заполнен fk_bill_var в справочнике t_org!');
  end if;

  if nvl(var_,0) in (0,4) then --счёт, счёт для УСЗН
   sqlstr2_:='s.usl';
   sqlstr3_:='substr(trim(s.nm),1,28)||'',''||trim(s.ed_izm)';
   if mg_ > 200710 and mg_ >= mg_nolg_ then
     --новые счета
     sqlstr4_:='max(psch) in (8,9) and k.for_bill=1 and ((sum(y.summa) <> 0 or
         sum(r.summa) <> 0 or
         sum(x.summa) <> 0 or
         sum(sl.summa) <> 0 or
         sum(nvl(a.summa, 0) - nvl(c.summa, 0) +
             nvl(y.summa, 0)+nvl(r.summa, 0)+nvl(x.summa, 0))  <> 0)
             or max(s.usl)=''003'')
             ';
/*
     sqlstr4_:='max(psch) in (8,9) and max(h2.dolg) <> 0 and ((sum(y.summa) <> 0 or
         sum(r.summa) <> 0 or
         sum(x.summa) <> 0 or
         sum(sl.summa) <> 0 or
         sum(nvl(a.summa, 0) - nvl(c.summa, 0) +
             nvl(y.summa, 0)+nvl(r.summa, 0)+nvl(x.summa, 0))  <> 0)
             or max(s.usl)=''003'')
             ';*/
    else
     sqlstr4_:='max(psch) in (8,9) and max(h2.dolg) <> 0 and ((sum(y.summa) <> 0 or
         sum(r.summa) <> 0 or
         sum(x.summa) <> 0 or
         sum(nvl(a.summa, 0) - nvl(c.summa, 0) +
             nvl(y.summa, 0)+nvl(r.summa, 0)+nvl(x.summa, 0))  <> 0)
             or max(s.usl)=''003'')
             ';
    end if;

   sqlstr5_:='round(sum(e.cena), 2)';
   sqlstr6_:='substr(k.fio, 1, 40)';
   sqlstr7_:='(select nvl(tp.cd,''LSK_TP_MAIN'') as lsk_tp, u.usl, l.*, substr(t.name,1,32) as name_org, t.phone, t.phone2
    from arch_kart l, t_org t, usl u, v_lsk_tp tp
      where l.fk_tp=tp.id(+) and (l.psch in (8,9) or l.psch not in (8,9)) and l.reu=t.reu and l.mg='''||mg_||''' '||sqlstr_||'
      )';
   sqlstr9_:='(select l.lsk, nvl(sum(l.penya),0) as penya
          from a_penya l where l.mg='''||mg_||''' '||sqlstr_||'
          group by l.lsk)';
   sqlstr11_:='(select l.lsk, nvl(sum(l.penya),0) as penya
          from scott.a_penya l where l.mg='''||mg_||''' '||sqlstr_||'
          group by l.lsk)';

--   if mg_ > 200710 and mg_ >= mg_nolg_ then
     sqlstr12_:='(select lsk, sum(summa) AS summa, sum(penya) as penya
                    from a_kwtp_mg l
                   where mg between '''||mg1_||''' and '''||mg2_||''' '||sqlstr_||'
                   group by lsk)';
--   else
--     sqlstr12_:='(select lsk, sum(summa) AS summa, null as penya
--                    from arch_kwtp l
--                   where mg between '''||mg1_||''' and '''||mg2_||''' '||sqlstr_||'
--                   group by lsk)';
--   end if;

  end if;




--оплата в разные периоды распределялась по разным таблицам
if to_number(mg_) > 200803 then
   sqlstr10_:='select l.lsk, sum(l.summa) as prev_pay
          from a_kwtp_mg l where l.mg='''||mg_||''' '||sqlstr_||'
         group by l.lsk';
else
   sqlstr10_:='select l.lsk, sum(l.summa) as prev_pay
          from arch_kwtp l where l.mg='''||mg_||''' '||sqlstr_||'
         group by l.lsk';
end if;

if mg_ >= utils.get_str_param('COLLAPSE_USL') then
/* Сворачивать ли расценку по услуге с.н.+св.н*/

/*sqlstr13_:='select cc2.lsk, cc2.usl, max(cc2.org) as org, sum(cc2.cena) as cena from (
       select aa1.lsk, aa1.org,
         su.id as usl, su.frc_get_price,
         case when nvl(lag(su.id,1) over (order by su.id, su.usl_id),''XXX'')
           <> su.id or su.frc_get_price=1 then aa1.cena
           else 0
           end as cena
           from
          (select cc.lsk,
                 cc.usl,
                 n.org,
                 max(round(cc.test_cena, 2)) as cena
            from a_charge cc, arch_kart l, a_nabor n
           where cc.type = 0
             and cc.lsk=l.lsk and l.mg='''||mg_||''' '||sqlstr_||' and l.psch <> 8
             and cc.mg=l.mg
             and cc.lsk=n.lsk(+)
             and cc.usl=n.usl(+)
             and cc.mg=n.mg(+)
           group by cc.lsk, cc.usl, n.org) aa1, scott.usl_bills su, scott.usl su2
           where aa1.usl=su.usl_id and aa1.usl=su2.usl and su.fk_bill_var='||l_bill_var||'
           and  '''||mg_||''' between su.mg1 and su.mg2
           ) cc2 group by cc2.lsk, cc2.usl'; */ --было до 21.10.2015


/*sqlstr13_:='select cc2.lsk, cc2.usl, max(cc2.org) as org, sum(cc2.cena) as cena from (
       select aa1.lsk, aa1.org,
         su.id as usl, su.frc_get_price,
         case when nvl(lag(su2.uslm,1) over (order by su2.uslm, su2.usl),''XXX'')
           <> su2.uslm or su.frc_get_price=1 then aa1.cena
           else 0
           end as cena
           from
          (select cc.lsk,
                 cc.usl,
                 n.org,
                 max(round(cc.test_cena, 2)) as cena
            from a_charge2 cc arch_kart l, a_nabor2 n
           where cc.type = 0
             and cc.lsk=l.lsk and l.mg='''||mg_||''' '||sqlstr_||' and l.psch <> 8
             and l.mg between cc.mgFrom and cc.mgTo
             and l.mg between n.mgFrom and n.mgTo
             and cc.lsk=n.lsk(+)
             and cc.usl=n.usl(+)
             and cc.mg=n.mg(+)
           group by cc.lsk, cc.usl, n.org) aa1, scott.usl_bills su, scott.usl su2
           where aa1.usl=su.usl_id and aa1.usl=su2.usl and su.fk_bill_var='||l_bill_var||'
           and  '''||mg_||''' between su.mg1 and su.mg2
           ) cc2 group by cc2.lsk, cc2.usl';*/


sqlstr13_:='select cc2.lsk, cc2.usl, max(cc2.org) as org, sum(cc2.cena) as cena from (
       select aa1.lsk, aa1.org,/* Сворачивать ли расценку по услуге с.н.+св.н*/
         su.id as usl, su.frc_get_price,
         case when nvl(lag(su2.uslm,1) over (order by su2.uslm, su2.usl),''XXX'')
           <> su2.uslm or su.frc_get_price=1 then aa1.cena
           else 0
           end as cena
           from
          (select /*+ INDEX (n A_NABOR2_I)*/ cc.lsk,
                 cc.usl,
                 n.org,
                 max(round(cc.test_cena, 2)) as cena
            from a_charge2 cc
            join arch_kart l on cc.lsk=l.lsk and l.mg='''||mg_||''' '||sqlstr_||' and l.psch <> 8
               and cc.type = 0
               and l.mg between cc.mgFrom and cc.mgTo
            left join a_nabor2 n on cc.lsk=n.lsk and cc.usl=n.usl
               and l.mg between cc.mgFrom and cc.mgTo
               and l.mg between n.mgFrom and n.mgTo
           group by cc.lsk, cc.usl, n.org) aa1, scott.usl_bills su, scott.usl su2
           where aa1.usl=su.usl_id and aa1.usl=su2.usl and su.fk_bill_var='||l_bill_var||'
           and  '''||mg_||''' between su.mg1 and su.mg2
           ) cc2 group by cc2.lsk, cc2.usl';

else
  sqlstr13_:='select /*+ INDEX (n A_NABOR2_I)*/cc.lsk,
                 cc.usl,
                 n.org,
                 max(round(cc.test_cena, 2)) as cena
            from a_charge2 cc
             join arch_kart l on l.mg between cc.mgFrom and cc.mgTo
             and cc.lsk=l.lsk
             left join a_nabor2 n on l.mg between n.mgFrom and n.mgTo
                  and cc.lsk=n.lsk and cc.usl=n.usl
           where cc.type = 0 and l.mg='''||mg_||''' '||sqlstr_||' and l.psch <> 8
           group by cc.lsk, cc.usl, n.org';
end if;

  sqlstr14_:='(select l.lsk, nvl(sum(l.summa),0) as dolg
          from saldo_usl l where l.mg =to_char(add_months(to_date('''||mg_||''', ''YYYYMM''), 1), ''YYYYMM'')
            '||sqlstr_||'
         group by l.lsk)';

if mg_ > 200710 and mg_ < mg_nolg_ then
  OPEN cur FOR
   'select k.mg1, k.mg, k.k_lsk_id, k.lsk, g.name || '' д.'' || ltrim(k.nd, ''0'') || ''-'' || ltrim(k.kw, ''0'') as streetname,
       '||sqlstr6_||' as fio,
       utils.month_name(SUBSTR('''||mg_||''', 5, 2)) || '' '' ||
       SUBSTR('''||mg_||''', 1, 4) || '' г.'' AS monthyear,
       k.status,
       k.psch,
       k.phw,
       k.pgw,
       k.pel,
       k.kul,
       k.opl,
       k.pldop,
       k.kpr,
       k.kpr_ot,
       k.kpr_wr,
       k.kpr_wrp,
       k.name_org,
       k.phone,
       k.phone2,
       k.ki,
       k.subs_inf,
       s.npp,
       '||sqlstr2_||' as usl,
       '||sqlstr3_||' as nm,
       max((select count(distinct tt.id)
        from a_kart_pr tt, a_lg_docs d, a_lg_pr p
        where tt.id=d.c_kart_pr_id and d.id=p.c_lg_docs_id
        and tt.lsk=k.lsk
        and tt.mg=k.mg and tt.mg=d.mg and tt.mg=p.mg and p.spk_id<>1
        and p.type=1 and d.main=1)) as lg_mains,
       max((select max(utils.concatenate(ROWNUM, p.spk_id, '','')) as nm
        from a_kart_pr tt, a_lg_docs d, a_lg_pr p
        where tt.id=d.c_kart_pr_id and d.id=p.c_lg_docs_id
        and tt.lsk=k.lsk
        and tt.mg=k.mg and tt.mg=d.mg and tt.mg=p.mg and p.spk_id<>1
        and p.type=1 and d.main=1)) as lg_ids,
       max(h5.penya) as itg_pen,
       max(h6.summa) as itg_pay,
       max(h6.penya) as itg_pen_pay,
        '||sqlstr5_||' as tarif,
       sum(decode('||sqlstr2_||', ''004'', a.vol, 0)) as pl_svnorm,
       max(a.vol) as vol, /*было max(a.vol) as vol, ред от 29.12.2010*/
       sum(a.summa) as charges,
       sum(f.summa) as privs,
       sum(y.summa) AS changes0,
       null AS ch_proc0,
       sum(r.summa) AS changes1,
       sum(x.summa) AS changes2,
       null as sl,
       sum(c.summa) as subs,
       max(j.summa) AS sub_el,
       sum(nvl(a.summa, 0) - nvl(f.summa, 0) - nvl(c.summa, 0) +
           nvl(y.summa, 0)+nvl(r.summa, 0)+nvl(x.summa, 0)) as itog,
       sum(nvl(a.summa, 0) - nvl(f.summa, 0) - nvl(c.summa, 0)) as itog_uszn,
       f.lgname,
       f.lg_id,
       f.cnt,
       f.lg_koef,
       '''||fname_sch_||''' as fname_sch,
       max(h.prev_chrg) as prev_chrg,
       max(o.prev_pay) as prev_pay,
       max(o.prev_pay) as payment,  --оч странно
       max(h3.penya) as penya,
       max(h3.penya) as monthpenya,
       max(h3.penya) as monthpenya2,
       max(h2.dolg)  as dolg,
       null as old_dolg,
       max(nvl(h2.dolg,0)) as itog_dolg,
       max(
       case when h4.sal_in < 0 then
        h4.sal_in
        else
        0 end) as ovrpaymnt,
       max(h4.sal_in) as sal_in,
       k.dolg as dolg2,
       null as org,
       null as bill_brake
  from spul g,
       '||sqlstr7_||' k,
       (select a.lsk, a.usl, sum(a.summa) as summa, sum(a.test_opl) as vol
          from scott.a_charge2 a, scott.arch_kart l
         where a.type = 1 and a.lsk=l.lsk and l.mg='''||mg_||''' '||sqlstr_||'
         and l.mg between a.mgFrom and a.mgTo
         group by a.lsk, a.usl) a,
       (select a.lsk, a.usl, sum(a.summa) as summa
          from scott.a_charge2 a, scott.arch_kart l
         where type = 2 and a.lsk=l.lsk and l.mg='''||mg_||''' '||sqlstr_||'
         and l.mg between a.mgFrom and a.mgTo
         group by a.lsk, a.usl) c,
       ( '||sqlstr13_||') e,
         (select l.lsk, l.usl_id, sum(l.summa) as summa from
          arch_changes l where l.mg='''||mg_||'''
          '||sqlstr_||'
          and l.id=0 and nvl(l.show_bill,0)<>1
          group by l.lsk, l.usl_id) y,
         (select l.lsk, l.usl_id, sum(l.summa) as summa from
          arch_changes l where l.mg='''||mg_||''' and nvl(l.show_bill,0)<>1
          '||sqlstr_||'
          and l.id=1
          group by l.lsk, l.usl_id) r,
         (select l.lsk, l.usl_id, sum(l.summa) as summa from
          arch_changes l where l.mg='''||mg_||''' and nvl(l.show_bill,0)<>1
          '||sqlstr_||'
          and l.id=2
          group by l.lsk, l.usl_id) x,
       (select l.lsk,
               l.usl_id,
               max(sp.id) as lg_id,
               max(sp.name) as lgname,
               max(sk.koef) as lg_koef,
               sum(l.summa) as summa,
               sum(l.cnt_main) as cnt_main,
               sum(l.cnt) as cnt
          from arch_privs l, spk sp, a_spk_usl sk
         where l.mg = sk.mg and l.mg='''||mg_||''' '||sqlstr_||'
           and l.lg_id = sp.id
           and l.lg_id = sk.spk_id
           and l.usl_id = sk.usl_id
         group by l.lsk, l.usl_id) f,
       (select l.lsk, nvl(sum(l.summa),0) as prev_chrg,
          sum(null) as prev_pen
          from saldo_usl l where l.mg = '''||mg_||''' '||sqlstr_||'
         group by l.lsk) h,
       '||sqlstr14_||' h2,
       '||sqlstr9_||' h3,
       '||sqlstr11_||' h5,
       '||sqlstr12_||' h6,
       (select l.lsk, nvl(sum(l.summa),0) as sal_in
          from saldo_usl l where l.mg = '''||mg_||''' '||sqlstr_||'
         group by l.lsk) h4,
       ('||sqlstr10_||') o,
       (select l.lsk, sum(l.summa) as summa
                  from arch_subsidii l
                  where l.usl_id = ''024'' and l.mg='''||mg_||''' '||sqlstr_||'
                  and l.mg=l.mg
                  group by l.lsk) j,
       scott.usl s,
       scott.usl_bills m
 where k.kul = g.id '||sqlstr8_||'
   and k.usl = m.usl_id and k.usl not in (select ex.usl_id from usl_excl ex)
   and m.id = s.usl and m.fk_bill_var=1 --жёстко 1 вариант, так как тогда еще не было никаких вариантов...
   and k.lsk = a.lsk(+)
   and k.usl = a.usl(+)
   and k.lsk = c.lsk(+)
   and k.usl = c.usl(+)
   and k.lsk = e.lsk(+)
   and k.usl = e.usl(+)

   and k.lsk = y.lsk(+)
   and k.usl = y.usl_id(+)
   and k.lsk = r.lsk(+)
   and k.usl = r.usl_id(+)
   and k.lsk = x.lsk(+)
   and k.usl = x.usl_id(+)

   and k.lsk = f.lsk(+)
   and k.usl = f.usl_id(+)
   and k.lsk = h.lsk(+)
   and k.lsk = h2.lsk(+)
   and k.lsk = h3.lsk(+)
   and k.lsk = h4.lsk(+)
   and k.lsk = h5.lsk(+)
   and k.lsk = h6.lsk(+)
   and k.lsk = o.lsk(+)
   and k.lsk = j.lsk(+)
   and k.mg between m.mg1 and m.mg2

  group by k.mg1, k.mg, k.k_lsk_id, k.lsk,
          g.name || '' д.'' || ltrim(k.nd, ''0'') || ''-'' || ltrim(k.kw, ''0''),
          '||sqlstr6_||',
          k.status,
          k.psch,
          k.phw,
          k.pgw,
          k.pel,
          k.kul,
          k.opl,
          k.pldop,
          k.kpr,
          k.kpr_wr,
          k.kpr_wrp,
          k.name_org,
          k.phone,
          k.phone2,
          k.ki,
          k.subs_inf,
          s.npp,
          '||sqlstr2_||',
          '||sqlstr3_||',
          k.kpr_ot,
          k.psch,
          k.gt,
          f.lgname,
          f.lg_id,
          f.cnt,
          f.lg_koef,
          k.dolg
 /* закрытые лицевые - берем */
having '||sqlstr4_||' or
       max(psch) not in (8,9) and (sum(y.summa) <> 0 or
       sum(r.summa) <> 0 or
       sum(x.summa) <> 0 or
       sum(nvl(a.summa, 0) - nvl(c.summa, 0) +
           nvl(y.summa, 0)+nvl(r.summa, 0)+nvl(x.summa, 0))  <> 0)
         -- order by s.bill_brake, s.usl НЕ ЗНАЧИТ НИЧЕГО ЗДЕСЬ ORDER, СОРТИРУЕТСЯ В DATASET1!!!
           ';
elsif mg_ > 200710 and mg_ >= mg_nolg_ then
--счета новые, без льгот
--оптимизированные под работу с 1 л.с.
OPEN cur FOR
   'select k.mg1, k.mg, k.k_lsk_id, k.lsk, g.name || '' д.'' || ltrim(k.nd, ''0'') || ''-'' || ltrim(k.kw, ''0'') as streetname,
       '||sqlstr6_||' as fio,
       utils.month_name(SUBSTR('''||mg_||''', 5, 2)) || '' '' ||
       SUBSTR('''||mg_||''', 1, 4) || '' г.'' AS monthyear,
       k.status,
       k.psch,
       k.phw,
       k.pgw,
       k.pel,
       k.kul,
       k.opl,
       k.pldop,
       k.kpr,
       k.kpr_ot,
       k.kpr_wr,
       k.kpr_wrp,
       k.name_org,
       k.phone,
       k.phone2,
       k.ki,
       k.subs_inf,
       s.npp,
       '||sqlstr2_||' as usl,
       '||sqlstr3_||' as nm,
       0 as lg_mains,
       0 as lg_ids,
       max(h5.penya) as itg_pen,
       max(h6.summa) as itg_pay,
       max(h6.penya) as itg_pen_pay,
        '||sqlstr5_||' as tarif,
       sum(decode('||sqlstr2_||', ''004'', a.vol, 0)) as pl_svnorm,
       sum(a.vol) as vol, /*было max(a.vol) as vol, ред от 29.12.2010*/
       sum(a.summa) as charges,
       null as privs,
       sum(y.summa) AS changes0,
       sum(y2.proc) AS ch_proc0,
       sum(r.summa) AS changes1,
       sum(x.summa) AS changes2,
       sum(sl.summa) AS sl, --сальдо исх. ред.01.10.12
       sum(c.summa) as subs,
       0 AS sub_el,
       sum(nvl(a.summa, 0) - nvl(c.summa, 0) +
           nvl(y.summa, 0)+nvl(r.summa, 0)+nvl(x.summa, 0)) as itog,
       sum(nvl(a.summa, 0) - nvl(c.summa, 0)) as itog_uszn,
       null as lgname,
       null as lg_id,
       null as cnt,
       null as lg_koef,
       '''||fname_sch_||''' as fname_sch,
       max(h.prev_chrg) as prev_chrg,
       max(o.prev_pay) as prev_pay,
       max(o.prev_pay) as payment,  --оч странно
       max(h3.penya) as penya,
       max(h3.penya) as monthpenya,
       max(h3.penya) as monthpenya2,
       max(h2.dolg) as dolg,
       null as old_dolg,
       max(nvl(h2.dolg,0)) as itog_dolg,
       max(
       case when h4.sal_in < 0 then
        h4.sal_in
        else
        0 end) as ovrpaymnt,
       max(h4.sal_in) as sal_in,
       k.dolg as dolg2,
       e.org as org,
       s.bill_brake
  from spul g,
       '||sqlstr7_||' k,
       (select l.lsk, u.id as usl, sum(l.summa) as summa, sum(decode(u.is_vol, 1, l.test_opl, 0)) as vol
          from a_charge2 l, usl_bills u
         where l.type = 1  '||sqlstr_||' and u.fk_bill_var='||l_bill_var||'
         and '''||mg_||''' between l.mgFrom and l.mgTo and l.usl=u.usl_id and '''||mg_||''' between u.mg1 and u.mg2
         group by l.lsk, u.id) a,
       (select l.lsk, u.id as usl, sum(l.summa) as summa, sum(decode(u.is_vol, 1, l.test_opl, 0)) as vol
          from a_charge2 l, usl_bills u
         where l.type = 2  '||sqlstr_||' and u.fk_bill_var='||l_bill_var||'
         and '''||mg_||''' between l.mgFrom and l.mgTo and l.usl=u.usl_id and '''||mg_||''' between u.mg1 and u.mg2

         group by l.lsk, u.id) c,
       (select l.lsk, u.id as usl, sum(l.summa) as summa
          from saldo_usl l, arch_kart k2, usl_bills u --сальдо по услугам
         where l.lsk=k2.lsk '||sqlstr_||'
         and l.mg='''||mg_||''' and k2.mg='''||mg_||'''
         and l.usl=u.usl_id and u.fk_bill_var='||l_bill_var||'
         and '''||mg_||''' between u.mg1 and u.mg2
         group by l.lsk, u.id) sl,
       ('||sqlstr13_||'
         ) e,
         (select l.lsk, l.usl_id , sum(l.summa) as summa from
          arch_changes l where l.mg='''||mg_||''' '||sqlstr_||'
            and l.id=0 and nvl(l.show_bill,0)<>1
            group by l.lsk, l.usl_id) y,
        (select lsk, usl_id,
            case when sum(norm_proc) <> 0 then sum(norm_proc)
                 else sum(sv_proc) end as proc
            from (
            select l.lsk, l.doc_id, b.id as usl_id,
            sum(case when l.proc <> 0 and u.usl_norm=0 then l.proc else 0 end) as norm_proc, --ред.28.06.13
            sum(case when l.proc <> 0 and u.usl_norm=1 then l.proc else 0 end) as sv_proc
            from a_change l, usl_bills b, usl u where
            l.mg='''||mg_||''' '||sqlstr_||' and l.usl=b.usl_id and l.usl=u.usl
            and b.fk_bill_var='||l_bill_var||'
            and l.mg between b.mg1 and b.mg2
            group by l.lsk, l.doc_id, b.id) a
            group by lsk, usl_id) y2,
         (select l.lsk, l.usl_id, sum(l.summa) as summa from
          arch_changes l where l.mg='''||mg_||''' and nvl(l.show_bill,0)<>1 '||sqlstr_||'
          and l.id=1
          group by l.lsk, l.usl_id) r,
         (select l.lsk, l.usl_id, sum(l.summa) as summa from
          arch_changes l where l.mg='''||mg_||''' and nvl(l.show_bill,0)<>1 '||sqlstr_||'
          and l.id=2
          group by l.lsk, l.usl_id) x,
       (select l.lsk, nvl(sum(l.summa),0) as prev_chrg,
          sum(null) as prev_pen
          from saldo_usl l where l.mg = '''||mg_||''' '||sqlstr_||'
         group by l.lsk) h,
       '||sqlstr14_||' h2,
       '||sqlstr9_||' h3,
       '||sqlstr11_||' h5,
       '||sqlstr12_||' h6,
       (select l.lsk, nvl(sum(l.summa),0) as sal_in
          from saldo_usl l where l.mg = '''||mg_||'''  '||sqlstr_||'
         group by l.lsk) h4,
       ('||sqlstr10_||') o,
       scott.usl s,
       scott.usl_bills m,
       (select l.lsk, l.mg1, sum(l.summa) as summa from scott.a_penya l where l.mg = '''||mg_||'''
         '||sqlstr_||'
        group by l.lsk, l.mg1) z
 where
   k.kul = g.id '||sqlstr8_||'
   and k.usl = m.usl_id and k.usl not in (select ex.usl_id from usl_excl ex)
   and m.id = s.usl
   and m.fk_bill_var='||l_bill_var||'

   and k.lsk = a.lsk(+)
   and k.usl = a.usl(+)
   and k.lsk = c.lsk(+)
   and k.usl = c.usl(+)

   and k.lsk = sl.lsk(+)
   and k.usl = sl.usl(+)

   and k.lsk = e.lsk(+)
   and k.usl = e.usl(+)

   and k.lsk=z.lsk(+)
   and k.mg=z.mg1(+)

   and k.lsk = y.lsk(+)
   and k.usl = y.usl_id(+)

   and k.lsk = y2.lsk(+)
   and k.usl = y2.usl_id(+)

   and k.lsk = r.lsk(+)
   and k.usl = r.usl_id(+)
   and k.lsk = x.lsk(+)
   and k.usl = x.usl_id(+)

   and k.lsk = h.lsk(+)
   and k.lsk = h2.lsk(+)
   and k.lsk = h3.lsk(+)
   and k.lsk = h4.lsk(+)
   and k.lsk = h5.lsk(+)
   and k.lsk = h6.lsk(+)
   and k.lsk = o.lsk(+)
   and k.mg between m.mg1 and m.mg2

  group by k.mg1, k.mg, k.k_lsk_id, k.lsk, k.for_bill,
          g.name || '' д.'' || ltrim(k.nd, ''0'') || ''-'' || ltrim(k.kw, ''0''),
          '||sqlstr6_||',
          k.status,
          k.psch,
          k.phw,
          k.pgw,
          k.pel,
          k.kul,
          k.opl,
          k.pldop,
          k.kpr,
          k.kpr_wr,
          k.kpr_wrp,
          k.name_org,
          k.phone,
          k.phone2,
          k.ki,
          k.subs_inf,
          s.npp,
          '||sqlstr2_||',
          '||sqlstr3_||',
          k.kpr_ot,
          k.psch,
          k.gt,
          k.dolg,
          e.org,
          s.bill_brake
 /* закрытые лицевые - берем */
   having '||sqlstr4_||' or
       max(psch) not in (8,9) and (sum(y.summa) <> 0 or
       sum(r.summa) <> 0 or
       sum(x.summa) <> 0 or
       '||sqlstr15_||'
       sum(nvl(a.summa, 0) - nvl(c.summa, 0) +
           nvl(y.summa, 0)+nvl(r.summa, 0)+nvl(x.summa, 0))  <> 0)
         -- order by s.npp сортируется потом в датасете
           ';



else
    --Счета старые
  if nvl(var_,0) = 0 then --счета
   sqlstr2_:='case
                  when u.usl in (''011'', ''012'', ''013'', ''014'', ''015'', ''016'') then
               trim(u.nm)||'',м3''
               else
               trim(u.nm)
               end';
   sqlstr7_:='arch_kart';
  else  --справка из архива
   sqlstr2_:='u.nm2';
   sqlstr7_:='(select ll.mg1, l.k_lsk_id, l.lsk, l.nd, l.kw, ll.fio, ll.status, l.psch, l.phw,
               l.pgw, l.pel, l.kul, l.opl,
     l.pldop, l.kpr, l.kpr_ot, l.kpr_wr, l.kpr_wrp, l.ki, l.gt, l.dolg, l.old_dolg, l.ovrpaymnt, l.penya, l.old_pen, l.subs_inf, l.mg
      from scott.arch_kart l, scott.kart ll
          where l.lsk=ll.lsk)';
  end if;
OPEN cur FOR
         'SELECT l.mg1, l.mg, l.k_lsk_id, l.lsk,
               s.name || '' д.'' || LTRIM(l.nd, ''0'') || ''-'' ||
               LTRIM(l.kw, ''0'') AS streetname,
               substr(l.fio, 1, 40) as fio,
               utils.month_name(SUBSTR('''||mg_||''', 5, 2)) || '' '' ||
               SUBSTR('''||mg_||''', 1, 4) || '' г.'' AS monthyear,
               l.status,
               l.psch,
               l.phw,
               l.pgw,
               l.pel,
               l.kul,
               l.opl,
               l.pldop,
               l.kpr,
               l.kpr_ot,
               null as kpr_wr,
               null as kpr_wrp,
               null as name_org,
               null as phone,
               null as phone2,
               l.ki,
               l.subs_inf,
               u.npp,
               bi.id as usl,
               '||sqlstr2_||' as nm,
               null as lg_mains,
               null as lg_ids,
               null as itg_pen,
               null as itg_pay,
               null as itg_pen_pay,
               round(CASE
                 WHEN l.kpr <> 0 and u.uslm in (''002'', ''004'',''009'') THEN --расценка по тек ремонту, отоплению всегда на уровне расценки по соц норме
                 (SELECT pr.summa*decode(u.sptarn, 0, NVL(w.koeff, 0), 1, 1, 2, NVL(w.koeff, 0), 3, NVL(w.koeff, 0), 4, NVL(w.koeff, 0))
                     FROM USL um, a_prices pr, spt w
                    WHERE u.USLM = um.USLM
                      AND um.usl_norm = 0 AND u.usl=w.usl_id and w.gtr=l.gt and w.mg=l.mg
                      AND um.USL = pr.USL
                      AND pr.mg = m.mg)
                 WHEN l.kpr = 0 and u.uslm in (''002'', ''004'',''009'') THEN --расценка по тек ремонту, отоплению всегда на уровне расценки по соц норме
                 (SELECT pr.summa*decode(u.sptarn, 0, NVL(w.koeff, 0), 1, 1, 2, NVL(w.koeff, 0), 3, NVL(w.koeff, 0), 4, NVL(w.koeff, 0))
                     FROM USL um, a_prices pr, spt w
                    WHERE u.USLM = um.USLM
                      AND um.usl_norm = 1 AND u.usl=w.usl_id and w.gtr=l.gt and w.mg=l.mg
                      AND um.USL = pr.USL
                      AND pr.mg = m.mg)
                 WHEN l.kpr <> 0 and l.psch = 0 and u.uslm in (''006'', ''008'', ''007'') THEN --нет счетчиков
                  (SELECT pr.summa
                     FROM USL um, a_prices pr
                    WHERE u.USLM = um.USLM
                      AND um.usl_norm = 0
                      AND um.USL = pr.USL
                      AND pr.mg = m.mg) * NVL(c.koeff, 0)
                 WHEN l.kpr <> 0 and l.psch = 1 and u.uslm in (''006'', ''008'', ''007'') THEN --счетчики хол.в. и г.в. и канализ.
                  (SELECT pr.summa
                     FROM USL um, a_prices pr
                    WHERE u.USLM = um.USLM
                      AND um.usl_norm = 0
                      AND um.USL = pr.USL
                      AND pr.mg = m.mg)
                 WHEN l.kpr <> 0 and l.psch = 3 and u.uslm in (''006'', ''007'') THEN --счетчики только гор.в. и канализ.
                  (SELECT pr.summa
                     FROM USL um, a_prices pr
                    WHERE u.USLM = um.USLM
                      AND um.usl_norm = 0
                      AND um.USL = pr.USL
                      AND pr.mg = m.mg)
                 WHEN l.kpr <> 0 and l.psch = 2 and u.uslm in (''008'', ''007'') THEN --счетчики только хол.в. и канализ.
                  (SELECT pr.summa --psch специально перепутан
                     FROM USL um, a_prices pr
                    WHERE u.USLM = um.USLM
                      AND um.usl_norm = 0
                      AND um.USL = pr.USL
                      AND pr.mg = m.mg)
                 WHEN l.kpr = 0 THEN
                  m.summa
                 WHEN l.kpr <> 0 THEN --остальные варианты
                  (SELECT pr.summa
                     FROM USL um, a_prices pr
                    WHERE u.USLM = um.USLM
                      AND um.usl_norm = 0
                      AND um.USL = pr.USL
                      AND pr.mg = m.mg)
                 ELSE m.summa
               END, 2) AS tarif,
               null as pl_svnorm,
               null as vol,
               NVL(b.summa_it, 0) AS CHARGES,
               f.summa AS PRIVS,
               g.summa AS changes0,
               null AS ch_proc0,
               h.summa AS changes1,
               k.summa AS changes2,
               null as sl,
               e.summa AS subs,
               j.summa AS sub_el,
               NVL(b.summa_it, 0) + NVL(g.summa, 0) + NVL(h.summa, 0)+
               NVL(k.summa, 0) - NVL(e.summa, 0)- NVL(f.summa, 0)  AS itog,
               NVL(b.summa_it, 0) - NVL(e.summa, 0)- NVL(f.summa, 0) AS itog_uszn,
               f.lgname,
               f.lg_id,
               f.cnt,
               f.lg_koef,
               '''||fname_sch_||''' as fname_sch,
               n.prev_chrg,
               o.prev_pay,
               d.summa AS payment,
               nvl(l.penya,0)+nvl(l.old_pen,0) as penya,
               nvl(l.penya,0)+nvl(l.old_pen,0)-n.prev_pen as monthpenya,
               nvl(z.penya,0) as monthpenya2,
               l.dolg as dolg,
               null as old_dolg,
               l.dolg as itog_dolg,
               null as ovrpayment,
               l.dolg as sal_in,
               null as dolg2,
               null as org,
               null as bill_brake
          FROM '||sqlstr7_||' l,
               SPT c,
               USL u,
               USL_BILLS bi,
               a_prices m,
               (SELECT DISTINCT lsk, usl_id
                  FROM (SELECT lsk, usl_id
                          FROM ARCH_KWTP
                         WHERE mg = '''||mg_||'''
                        UNION ALL
                        SELECT lsk, usl_id
                          FROM ARCH_CHARGES
                         WHERE mg = '''||mg_||'''
                        UNION ALL
                        SELECT lsk, usl_id
                          FROM ARCH_CHANGES
                         WHERE mg = '''||mg_||'''
                        UNION ALL
                        SELECT lsk, usl_id
                          FROM ARCH_SUBSIDII
                         WHERE mg = '''||mg_||'''
                        UNION ALL
                        SELECT lsk, usl_id FROM ARCH_PRIVS WHERE mg = '''||mg_||''')) a,
               ARCH_CHARGES b,
               (select lsk, mg, sum(summa) as summa from arch_kwtp
                 where mg='''||mg_||'''
                 group by lsk, mg) d,
               ARCH_SUBSIDII e,
               (SELECT lsk, SUM(summa) AS summa
                  FROM ARCH_SUBSIDII su
                 WHERE mg = '''||mg_||'''
                   AND su.usl_id = ''024''
                 GROUP BY lsk) j,
               (SELECT ap.lsk,
                       ap.usl_id,
                       MAX(sp.id) AS lg_id,
                       MAX(sp.name) AS lgname,
                       MAX(sk.koef) AS lg_koef,
                       SUM(ap.summa) AS summa,
                       SUM(ap.cnt_main) as cnt_main,
                       SUM(ap.cnt) as cnt
                  FROM ARCH_PRIVS ap, SPK sp, c_spk_usl sk
                 WHERE ap.lg_id = sp.id and ap.lg_id=sk.spk_id and ap.usl_id=sk.usl_id
                   AND mg = '''||mg_||'''
                 GROUP BY ap.lsk, ap.usl_id) f,
               ARCH_CHANGES g,
               ARCH_CHANGES h,
               ARCH_CHANGES k,
               (SELECT lsk, sum(nvl(dolg,0)+nvl(penya,0)) AS prev_chrg,
                  sum(nvl(penya,0)) as prev_pen
                  FROM ARCH_KART
                 WHERE mg = TO_CHAR(ADD_MONTHS(TO_DATE('''||mg_||''', ''YYYYMM''), -1),
                                    ''YYYYMM'')
                 GROUP BY lsk) n,
               (SELECT lsk, SUM(summa) AS prev_pay
                  FROM ARCH_KWTP
                 WHERE mg = '''||mg_||'''
                 GROUP BY lsk) o,
               SPUL s,
               c_penya z
         WHERE l.lsk = a.lsk
           '||sqlstr_||' and l.psch <> 8
           AND l.gt = c.gtr(+)
           AND m.USL = c.usl_id
           AND u.usl <> ''024''
           AND bi.usl_id=u.usl
           and bi.fk_bill_var='||l_bill_var||'
           AND l.mg = '''||mg_||'''

           AND l.lsk = n.lsk(+)
           AND l.lsk = o.lsk(+)
           AND l.kul = s.id
           AND a.usl_id = u.USL
           AND a.usl_id = m.USL
           AND m.mg = '''||mg_||'''
           AND c.mg = '''||mg_||'''
           AND a.lsk = b.lsk(+)
           AND a.usl_id = b.usl_id(+)
           AND b.mg(+) = '''||mg_||'''
           AND a.lsk = d.lsk(+)
         /*  AND a.usl_id = d.usl_id(+) */
           AND d.mg(+) = '''||mg_||'''
           AND a.lsk = e.lsk(+)
           AND a.usl_id = e.usl_id(+)
           AND e.mg(+) = '''||mg_||'''
           AND a.lsk = f.lsk(+)
           AND a.usl_id = f.usl_id(+)
           AND a.lsk = g.lsk(+)
           AND a.usl_id = g.usl_id(+)
           AND g.mg(+) = '''||mg_||'''
           AND g.id(+) = 0
           AND a.lsk = h.lsk(+)
           AND a.usl_id = h.usl_id(+)
           AND h.mg(+) = '''||mg_||'''
           AND h.id(+) = 1
           AND a.lsk = k.lsk(+)
           AND a.usl_id = k.usl_id(+)
           AND k.mg(+) = '''||mg_||'''
           AND k.id(+) = 2
           AND a.lsk = j.lsk(+)
           and l.lsk=z.lsk(+)
           and l.mg=z.mg1(+)
           ORDER BY a.lsk, bi.id';
end if;
 loop
  fetch cur into rec_;
  exit when cur%NOTFOUND;
   pipe row (rec_);

 end loop;
 close cur;
 mg_:=to_char(add_months(to_date(mg_,'YYYYMM'), 1),'YYYYMM');
end loop;

 return;
end;


procedure main(p_sel_obj  in number,
               p_reu      in kart.reu%type,
               p_kul      in kart.kul%type,
               p_nd       in kart.nd%type,
               p_kw       in kart.kw%type,
               p_lsk      in kart.lsk%type,
               p_lsk1     in kart.lsk%type,
               p_firstrec in number,
               p_lastrec  in number,
               p_var2     in number, -- печатать ли закрытый фонд
               p_var3     in number, -- печатать ли доп.счета
               p_cntrec   in number,
               p_mg       in params.period%type,
               p_rfcur    out ccur) is
  -- версия счета (0-старая (Полыс), 1 - новая - (Кис.))
  l_bill_version_compound number;

begin

  delete from temp_lsk;

  l_bill_version_compound := utils.get_int_param('BILL_VERSION_COMPOUND');

  if l_bill_version_compound = 0 then
    -- старая версия счета (Полыс)
    insert into temp_lsk
      (lsk)
      select k.lsk
        from arch_kart k
       where k.mg = p_mg
         and exists
       (select *
                from arch_kart k2
               where k2.mg = k.mg
                 and (decode(p_sel_obj, 0, 1, 1, 1, nvl(k2.for_bill, 0)) = 1) -- ред.14.05.19 фильтр по просьбе Полыс (некорректно выводились РСО счета) - эксперементально поставил, не знаю, заденет ли Кис
                 and decode(p_sel_obj, 0, p_lsk, k2.lsk) >= k2.lsk
                 and decode(p_sel_obj, 0, p_lsk1, k2.lsk) <= k2.lsk
                 and decode(p_sel_obj, 1, nvl(p_kul, k2.kul), k2.kul) =
                     k2.kul
                 and decode(p_sel_obj, 1, nvl(p_nd, k2.nd), k2.nd) = k2.nd
                 and decode(p_sel_obj, 1, nvl(p_kw, k2.kw), k2.kw) = k2.kw
                 and decode(p_sel_obj, 2, p_reu, k2.reu) = k2.reu
                 and k2.k_lsk_id = k.k_lsk_id);

    open p_rfcur for
      select *
        from ( --пока убрал RULE если не делать хинт RULE то возникает ошибка в CBO, которая препятствует выводу записей в датасете...
               select a.*, 'ST00012' || '|Name=' || a.full_name ||
                        '|PersonalAcc=' || a.raschet_schet || '|BankName=' ||
                        a.bank || '|BIC=' || a.bik || '|CorrespAcc=' ||
                        a.k_schet || '|Sum=' ||
                        trim(to_char(a.sal_out * 100, 9999999999)) ||
                        '|Purpose=Квартплата' || '|PayeeINN=' || a.inn ||
                        '|lastName=' || a.k_fam || '|firstName=' || a.k_im ||
                        '|middleName=' || a.k_ot || '|payerAddress=' ||
                        a.adr2 || '|persAcc=' || a.lsk || '|PaymPeriod=' || p_mg ||
                        '|serviceName=000' || '|category=' ||
                        decode(a.psch, 8, '43301', 9, '43301', '43302') as QR
                 from (select /*+ USE_HASH(k, sl, p1, p2, p3, p4, p5, p6  )*/
                          k.lsk, k.k_lsk_id, k.opl, utils.month_name(SUBSTR(p_mg,
                                                   5,
                                                   2)) || ' ' ||
                           SUBSTR(p_mg, 1, 4) || ' г.' as mg2,case
                            when stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO') and
                                 k3.lsk is not null then
                             k3.kpr
                            else
                             k.kpr
                          end as kpr,case
                            when stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO') and
                                 k3.lsk is not null then
                             k3.kpr_wr
                            else
                             k.kpr_wr
                          end as kpr_wr,case
                            when stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO') and
                                 k3.lsk is not null then
                             k3.kpr_wrp
                            else
                             k.kpr_wrp
                          end as kpr_wrp,case
                            when stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO') and
                                 k3.lsk is not null then
                             k3.kpr_ot
                            else
                             k.kpr_ot
                          end as kpr_ot, t.name as st_name, decode(t.cd,
                                  'MUN',
                                  'Наниматель',
                                  'Собственник') as pers_tp, s.name || ', ' ||
                           nvl(ltrim(k.nd, '0'),
                               '0') || '-' ||
                           nvl(ltrim(k.kw, '0'),
                               '0') as adr, o2.name || ', ул.' || s.name ||
                           ', д. ' || nvl(ltrim(k.nd, '0'), '0') ||
                           ', кв.' || nvl(ltrim(k.kw, '0'), '0') as adr2, k.phw, k.pgw, k.pel, k2.phw as phw_back, k2.pgw as pgw_back, k2.pel as pel_back, k.mel, k.mhw, k.mgw, scott.init.get_fio as fio_kass, p_mg as mg, scott.utils.month_name(substr(p_mg,
                                                         5,
                                                         2)) || ' ' ||
                           substr(p_mg,
                                  1,
                                  4) || 'г.' as mg_str, to_date(p_mg || '01',
                                   'YYYYMMDD') as dt1, to_date(scott.utils.add_months_pr(p_mg,
                                                             1) || '01',
                                   'YYYYMMDD') as dt2, k.house_id, k.reu,case
                            when stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO') then
                             o.r_sch_addit
                          --                    when b.cnt = 1 then o.raschet_schet2
                            when o3.code_deb is not null then
                             o3.raschet_schet
                            else
                             o.raschet_schet
                          end as raschet_schet, sl.summa as sal_out, k.k_fam, k.k_im, k.k_ot, k.fio, o.inn, o.k_schet, o.bik, o.bank, o.full_name, o.phone, o.adr as adr_org, k.psch, stp.cd as lsk_tp, stp.npp as lsk_tp_npp, k.prn_num, k.prn_new, p1.penya_in, p2.penya_chrg, p3.penya_corr, nvl(p2.penya_chrg,
                               0) +
                           nvl(p3.penya_corr,
                               0) as penya_chrg_itg, p4.penya_pay, p5.penya_out, p4.pay, p4.last_dtek
                           from scott.arch_kart k
                           left join scott.arch_kart k2
                             on k.lsk = k2.lsk
                            and k2.mg = scott.utils.add_months_pr(p_mg, -1)
                           left join scott.spul s
                             on k.kul = s.id
                           left join scott.status t
                             on k.status = t.id
                           left join scott.t_org_tp tp
                             on tp.cd = 'РКЦ'
                           left join scott.t_org o
                             on tp.id = o.fk_orgtp
                           left join scott.t_org_tp tp2
                             on tp2.cd = 'Город'
                           left join scott.t_org o2
                             on tp2.id = o2.fk_orgtp
                           left join scott.t_org o3
                             on k.reu = o3.reu
                           left join scott.v_lsk_tp stp
                             on k.fk_tp = stp.id
                           left join scott.v_lsk_tp stp2
                             on stp2.cd = 'LSK_TP_MAIN'
                           left join scott.arch_kart k3
                             on k.k_lsk_id = k3.k_lsk_id
                            and k.mg = k3.mg
                            and k.lsk <> k3.lsk
                            and k3.psch not in (8, 9)
                            and stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO')
                            and k3.fk_tp <> k.fk_tp
                            and k3.fk_tp = stp2.id -- присоединить основной ЛС, чтоб получить кол-во прож.
                           left join (select l.lsk, sum(l.summa) as summa --сальдо исходящее
                                       from scott.saldo_usl l, temp_lsk tmp
                                      where l.mg =
                                            scott.utils.add_months_pr(p_mg, 1)
                                        and l.lsk = tmp.lsk
                                      group by l.lsk) sl
                             on k.lsk = sl.lsk
                           left join (select l.lsk, sum(l.penya) as penya_in --сальдо по пене входящее
                                       from scott.a_penya l, temp_lsk tmp
                                      where l.mg =
                                            scott.utils.add_months_pr(p_mg, -1)
                                        and l.lsk = tmp.lsk
                                      group by l.lsk) p1
                             on k.lsk = p1.lsk
                           left join (select l.lsk, sum(penya_chrg) as penya_chrg
                                       from ( --ред. 21.11.2016
                                              select t.lsk, t.mg1, round(sum(t.penya),
                                                             2) as penya_chrg --начисление по пене текущее
                                                from scott.a_pen_cur t, temp_lsk tmp
                                               where t.mg = p_mg
                                                 and t.lsk = tmp.lsk
                                               group by t.lsk, t.mg1) l
                                      group by l.lsk) p2
                             on k.lsk = p2.lsk
                           left join (select l.lsk, sum(l.penya) as penya_corr --корректировки по пене текущие
                                       from scott.a_pen_corr l, temp_lsk tmp
                                      where l.mg = p_mg
                                        and l.lsk = tmp.lsk
                                      group by l.lsk) p3
                             on k.lsk = p3.lsk
                           left join (select l.lsk, max(l.dtek) as last_dtek, -- дата платежа, последняя
                                            sum(l.summa) as pay, -- оплата текущая
                                            sum(l.penya) as penya_pay --оплата по пене текущая
                                       from scott.a_kwtp_mg l, temp_lsk tmp
                                      where l.mg = p_mg
                                        and l.lsk = tmp.lsk
                                      group by l.lsk) p4
                             on k.lsk = p4.lsk
                           left join (select l.lsk, sum(l.penya) as penya_out --сальдо по пене исходящее
                                       from scott.a_penya l, temp_lsk tmp
                                      where l.mg = p_mg
                                        and l.lsk = tmp.lsk
                                      group by l.lsk) p5
                             on k.lsk = p5.lsk
                           join (select distinct k2.k_lsk_id
                                  from arch_kart k2
                                 where k2.mg = p_mg
                                   and (decode(p_sel_obj,
                                               0,
                                               1,
                                               1,
                                               1,
                                               nvl(k2.for_bill, 0)) = 1) -- ред.14.05.19 фильтр по просьбе Полыс (некорректно выводились РСО счета) - эксперементально поставил, не знаю, заденет ли Кис
                                   and (decode(p_sel_obj, 0, p_lsk, k2.lsk) >=
                                       k2.lsk and
                                       decode(p_sel_obj, 0, p_lsk1, k2.lsk) <=
                                       k2.lsk and
                                       decode(p_sel_obj,
                                               1,
                                               nvl(p_kul, k2.kul),
                                               k2.kul) = k2.kul and
                                       decode(p_sel_obj,
                                               1,
                                               nvl(p_nd, k2.nd),
                                               k2.nd) = k2.nd and
                                       decode(p_sel_obj,
                                               1,
                                               nvl(p_kw, k2.kw),
                                               k2.kw) = k2.kw and
                                       decode(p_sel_obj, 2, p_reu, k2.reu) =
                                       k2.reu)) k4
                             on k4.k_lsk_id = k.k_lsk_id
                          where k.mg = p_mg
                            and (p_var2 = 1 and k.psch in (8, 9) and
                                (nvl(sl.summa, 0) <> 0 or
                                nvl(p5.penya_out, 0) <> 0) or
                                k.psch not in (8, 9) and
                                (stp.cd = 'LSK_TP_MAIN' or
                                stp.cd <> 'LSK_TP_MAIN'))
                            and (p_var3 = 0 or
                                p_var3 = 1 and stp.cd = 'LSK_TP_MAIN')
                          order by s.name, scott.utils.f_ord_digit(k.nd), --Внимание! порядок точно такой как и в GEN.upd_arch_kart2
                                   scott.utils.f_ord3(k.nd) desc, scott.utils.f_ord_digit(k.kw), scott.utils.f_ord3(k.kw) desc, k.k_lsk_id, stp.npp) a) b
       where p_cntrec = 0
          or p_cntrec <> 0
         and b.prn_num between nvl(p_firstrec, 0) and nvl(p_lastrec, 0);
  else
    -- новая версия счета (Кис.)
    insert into temp_lsk
      (lsk)
      select k.lsk
        from arch_kart k
       where k.mg = p_mg
         and (decode(p_sel_obj, 0, 1, 1, 1, nvl(k.for_bill, 0)) = 1) /* либо по 1 квартире, лс либо чтобы был промарк.for_bill*/ --)
         and (decode(p_sel_obj, 0, p_lsk, k.lsk) >= k.lsk and
             decode(p_sel_obj, 0, p_lsk1, k.lsk) <= k.lsk and
             decode(p_sel_obj, 1, nvl(p_reu, k.reu), k.reu) = k.reu and -- ред.16.10.19 добавил - просили чтобы спр.квартирос. выводился только по УК (может исказить счета где нить?)
             decode(p_sel_obj, 1, nvl(p_kul, k.kul), k.kul) = k.kul and
             decode(p_sel_obj, 1, nvl(p_nd, k.nd), k.nd) = k.nd and
             decode(p_sel_obj, 1, nvl(p_kw, k.kw), k.kw) = k.kw and
             decode(p_sel_obj, 2, p_reu, k.reu) = k.reu);

    open p_rfcur for
      select *
        from ( --пока убрал RULE если не делать хинт RULE то возникает ошибка в CBO, которая препятствует выводу записей в датасете...
               select a.*, 'ST00012' || '|Name=' || a.full_name ||
                        '|PersonalAcc=' || a.raschet_schet || '|BankName=' ||
                        a.bank || '|BIC=' || a.bik || '|CorrespAcc=' ||
                        a.k_schet || '|Sum=' ||
                        trim(to_char(a.sal_out * 100, 9999999999)) ||
                        '|Purpose=Квартплата' || '|PayeeINN=' || a.inn ||
                        '|lastName=' || a.k_fam || '|firstName=' || a.k_im ||
                        '|middleName=' || a.k_ot || '|payerAddress=' ||
                        a.adr2 || '|persAcc=' || a.lsk || '|PaymPeriod=' || p_mg ||
                        '|serviceName=000' || '|category=' ||
                        decode(a.psch, 8, '43301', 9, '43301', '43302') as QR
                 from (select /*+ USE_HASH(k, sl, p1, p2, p3, p4, p5, p6  )*/
                          k.lsk, k.k_lsk_id, k.opl, utils.month_name(SUBSTR(p_mg,
                                                   5,
                                                   2)) || ' ' ||
                           SUBSTR(p_mg, 1, 4) || ' г.' as mg2,case
                            when stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO') and
                                 k3.lsk is not null then
                             k3.kpr
                            else
                             k.kpr
                          end as kpr,case
                            when stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO') and
                                 k3.lsk is not null then
                             k3.kpr_wr
                            else
                             k.kpr_wr
                          end as kpr_wr,case
                            when stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO') and
                                 k3.lsk is not null then
                             k3.kpr_wrp
                            else
                             k.kpr_wrp
                          end as kpr_wrp,case
                            when stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO') and
                                 k3.lsk is not null then
                             k3.kpr_ot
                            else
                             k.kpr_ot
                          end as kpr_ot, t.name as st_name, decode(t.cd,
                                  'MUN',
                                  'Наниматель',
                                  'Собственник') as pers_tp, s.name || ', ' ||
                           nvl(ltrim(k.nd, '0'),
                               '0') || '-' ||
                           nvl(ltrim(k.kw, '0'),
                               '0') as adr, o2.name || ', ул.' || s.name ||
                           ', д. ' || nvl(ltrim(k.nd, '0'), '0') ||
                           ', кв.' || nvl(ltrim(k.kw, '0'), '0') as adr2, k.phw, k.pgw, k.pel, k2.phw as phw_back, k2.pgw as pgw_back, k2.pel as pel_back, k.mel, k.mhw, k.mgw, scott.init.get_fio as fio_kass, p_mg as mg, scott.utils.month_name(substr(p_mg,
                                                         5,
                                                         2)) || ' ' ||
                           substr(p_mg,
                                  1,
                                  4) || 'г.' as mg_str, to_date(p_mg || '01',
                                   'YYYYMMDD') as dt1, to_date(scott.utils.add_months_pr(p_mg,
                                                             1) || '01',
                                   'YYYYMMDD') as dt2, k.house_id, k.reu,case
                            when stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO') then
                             o.r_sch_addit
                            when o3.code_deb is not null then
                             o3.raschet_schet
                            else
                             o.raschet_schet
                          end as raschet_schet, sl.summa as sal_out, k.k_fam, k.k_im, k.k_ot, k.fio, o.inn, o.k_schet, o.bik, o.bank, o.full_name, o.phone, o.adr as adr_org, k.psch, stp.cd as lsk_tp, stp.npp as lsk_tp_npp, k.prn_num, k.prn_new, p1.penya_in, p2.penya_chrg, p3.penya_corr, nvl(p2.penya_chrg,
                               0) +
                           nvl(p3.penya_corr,
                               0) as penya_chrg_itg, p4.penya_pay, p5.penya_out, p4.pay, p4.last_dtek
                           from scott.arch_kart k
                           left join scott.arch_kart k2
                             on k.lsk = k2.lsk
                            and k2.mg = scott.utils.add_months_pr(p_mg, -1)
                           left join scott.spul s
                             on k.kul = s.id
                           left join scott.status t
                             on k.status = t.id
                           left join scott.t_org_tp tp
                             on tp.cd = 'РКЦ'
                           left join scott.t_org o
                             on tp.id = o.fk_orgtp
                           left join scott.t_org_tp tp2
                             on tp2.cd = 'Город'
                           left join scott.t_org o2
                             on tp2.id = o2.fk_orgtp
                           left join scott.t_org o3
                             on k.reu = o3.reu
                           left join scott.v_lsk_tp stp
                             on k.fk_tp = stp.id
                           left join scott.v_lsk_tp stp2
                             on stp2.cd = 'LSK_TP_MAIN'
                           left join scott.arch_kart k3
                             on k.k_lsk_id = k3.k_lsk_id
                            and k.mg = k3.mg
                            and k.lsk <> k3.lsk
                            and k3.psch not in (8, 9)
                            and stp.cd in ('LSK_TP_ADDIT', 'LSK_TP_RSO')
                            and k3.fk_tp <> k.fk_tp
                            and k3.fk_tp = stp2.id -- присоединить основной ЛС, чтоб получить кол-во прож.
                           left join (select l.lsk, sum(l.summa) as summa --сальдо исходящее
                                       from scott.saldo_usl l, temp_lsk tmp
                                      where l.mg =
                                            scott.utils.add_months_pr(p_mg, 1)
                                        and l.lsk = tmp.lsk
                                      group by l.lsk) sl
                             on k.lsk = sl.lsk
                           left join (select l.lsk, sum(l.penya) as penya_in --сальдо по пене входящее
                                       from scott.a_penya l, temp_lsk tmp
                                      where l.mg =
                                            scott.utils.add_months_pr(p_mg, -1)
                                        and l.lsk = tmp.lsk
                                      group by l.lsk) p1
                             on k.lsk = p1.lsk
                           left join (select l.lsk, sum(penya_chrg) as penya_chrg
                                       from ( --ред. 21.11.2016
                                              select t.lsk, t.mg1, round(sum(t.penya),
                                                             2) as penya_chrg --начисление по пене текущее
                                                from scott.a_pen_cur t, temp_lsk tmp
                                               where t.mg = p_mg
                                                 and t.lsk = tmp.lsk
                                               group by t.lsk, t.mg1) l
                                      group by l.lsk) p2
                             on k.lsk = p2.lsk
                           left join (select l.lsk, sum(l.penya) as penya_corr --корректировки по пене текущие
                                       from scott.a_pen_corr l, temp_lsk tmp
                                      where l.mg = p_mg
                                        and l.lsk = tmp.lsk
                                      group by l.lsk) p3
                             on k.lsk = p3.lsk
                           left join (select l.lsk, max(l.dtek) as last_dtek, -- дата платежа, последняя
                                            sum(l.summa) as pay, -- оплата текущая
                                            sum(l.penya) as penya_pay --оплата по пене текущая
                                       from scott.a_kwtp_mg l, temp_lsk tmp
                                      where l.mg = p_mg
                                        and l.lsk = tmp.lsk
                                      group by l.lsk) p4
                             on k.lsk = p4.lsk
                           left join (select l.lsk, sum(l.penya) as penya_out --сальдо по пене исходящее
                                       from scott.a_penya l, temp_lsk tmp
                                      where l.mg = p_mg
                                        and l.lsk = tmp.lsk
                                      group by l.lsk) p5
                             on k.lsk = p5.lsk
                          where k.mg = p_mg
                            and (decode(p_sel_obj, 0, 1, 1, 1, nvl(k.for_bill, 0)) = 1) /* либо по 1 квартире, лс либо чтобы был промарк.for_bill*/ --)
                            and (decode(p_sel_obj, 0, p_lsk, k.lsk) >= k.lsk and
                                decode(p_sel_obj, 0, p_lsk1, k.lsk) <= k.lsk and
                                decode(p_sel_obj, 1, nvl(p_reu, k.reu), k.reu) = k.reu and -- ред.16.10.19 добавил - просили чтобы спр.квартирос. выводился только по УК (может исказить счета где нить?)
                                decode(p_sel_obj, 1, nvl(p_kul, k.kul), k.kul) = k.kul and
                                decode(p_sel_obj, 1, nvl(p_nd, k.nd), k.nd) = k.nd and
                                decode(p_sel_obj, 1, nvl(p_kw, k.kw), k.kw) = k.kw and
                                decode(p_sel_obj, 2, p_reu, k.reu) = k.reu)
                            and (p_var2 = 1 and k.psch in (8, 9) and
                                (nvl(sl.summa, 0) <> 0 or
                                nvl(p5.penya_out, 0) <> 0) or
                                k.psch not in (8, 9) and
                                (stp.cd = 'LSK_TP_MAIN' or
                                stp.cd <> 'LSK_TP_MAIN' --and (nvl(sl.summa,0) <> 0 or nvl(p5.penya_out,0) <> 0) ред.10.01.18 закоммент. по просьбе Полыс - не выводил расшифровку(счет) по РСО лс
                                ))
                            and (p_var3 = 0 or
                                p_var3 = 1 and stp.cd = 'LSK_TP_MAIN')
                          order by s.name, scott.utils.f_ord_digit(k.nd), --Внимание! порядок точно такой как и в GEN.upd_arch_kart2
                                   scott.utils.f_ord3(k.nd) desc, scott.utils.f_ord_digit(k.kw), scott.utils.f_ord3(k.kw) desc, k.k_lsk_id, stp.npp) a) b
       where p_cntrec = 0
          or p_cntrec <> 0
         and b.prn_num between nvl(p_firstrec, 0) and nvl(p_lastrec, 0);

  end if;

end;

--детализация счета
procedure detail(p_lsk  IN KART.lsk%TYPE,
                 p_mg   IN PARAMS.period%type,
                 p_rfcur out ccur
  ) is
l_lsk_tp v_lsk_tp.cd%type;
l_bill_var number;
begin
  select tp.cd, o.fk_bill_var into l_lsk_tp, l_bill_var
      from arch_kart k
      join v_lsk_tp tp on k.fk_tp=tp.id
      join t_org o on k.reu=o.reu
        and k.lsk=p_lsk
        and k.mg=p_mg;

  open p_rfcur for
  select /*+ USE_HASH(k, a, sl, d, r  )*/  k.lsk, bs.id as usl,
     case when u.cd='т/сод' /*and k.psch not in (8,9)*/ then trim(u.nm)||' в том числе:' else u.nm end as nm, u.ed_izm, sum(a.summa) as chrg,
     case when g.isvol is null then sum(decode(bs.is_vol,1,a.vol,0))
          when nvl(g.isvol,0) = 2 then 0 --занулить
          when nvl(g.isvol,0) = 1 then max(a.vol) --максимум объема
          when nvl(g.isvol,0) = 0 then sum(a.vol) --сумма объема
             end as vol,
     --sum(case when u.cd='т/сод' and nvl(g.isvol,0)=1 then a.maxvol else a.vol end) as vol,
     sum(case when u.cd='т/сод' and nvl(d.cnt,0)<>0 then 0 else a.cena end) as cena,
     sum(sl.summa) as sal_in,
     sum(r.changes0) as chng0, sum(r.changes1) as chng1, sum(r.changes2) as chng2, sum(r.proc) as chng_proc,
     nvl(sum(a.summa),0)+nvl(sum(r.changes),0) as itog, nvl(u.bill_brake,0) as bill_brake, u.npp, l_bill_var as bill_var,
     case when u.cd='т/сод' /*and k.psch not in (8,9)*/ then 1 else 0 end as tp, -- тип, для выборки детализац.строк из курсора в detail2
     p_mg as mg
     from
      arch_kart k
      join usl_bills bs on k.mg between bs.mg1 and bs.mg2
        and bs.fk_bill_var=l_bill_var
      left join usl_bills_house g on k.house_id=g.fk_house and bs.id=g.fk_bill_id and k.mg between g.mg1 and g.mg2
      join usl u on bs.id=u.usl
      left join
           (select t.lsk, t.mgFrom, t.mgTo, min(t.usl) as usl, b.bill_agg, --поле нужно, чтобы разделить расценку по норме и свыше, или просуммировать расценку
             sum(t.summa) as summa,
             sum(t.test_opl) as vol,
             max(t.test_cena) as cena --расценка
            from a_charge2 t, usl u, usl_bills b --сальдо по услугам
             where t.type = 1 and p_mg between t.mgFrom and t.mgTo
              and t.usl=b.usl_id and t.lsk=p_lsk
              and t.usl=u.usl
              and p_mg between b.mg1 and b.mg2
              and b.fk_bill_var = l_bill_var
             group by t.lsk, t.mgFrom, t.mgTo, u.uslm, b.bill_agg) a on bs.usl_id=a.usl and k.lsk=a.lsk and k.mg between a.mgFrom and a.mgTo
      left join
      (select t.lsk, t.mg,t.usl, sum(t.summa) as summa
            from saldo_usl t
            where t.mg = p_mg and t.lsk=p_lsk
           group by t.lsk, t.mg, t.usl) sl on bs.usl_id=sl.usl and k.lsk=sl.lsk and k.mg=sl.mg
      left join (select /*+ INDEX (n A_NABOR2_I)*/ count(*) as cnt from a_nabor2 n, usl u -- проверка наличия определённых услуг, чтобы в услуге тек.содерж. вкл/выкл расценку
                        where n.usl=u.usl and n.lsk = p_lsk and p_mg between n.mgFrom and n.mgTo
                        and u.cd in ('HW_ODN2', 'GW_ODN2', 'EL_ODN2')
                        and nvl(n.koeff,0)<>0 and nvl(n.norm,0)<>0) d on 1=1
      left join
      (select t.lsk, t.mg, t.usl as usl, sum(t.summa) as changes,
              sum(decode(t.type,0,t.summa)) as changes0,
              sum(decode(t.type,1,t.summa)) as changes1,
              sum(decode(t.type,2,t.summa)) as changes2,
              sum(t.proc) as proc
            from
            a_change t where nvl(t.show_bill,0)<>1 and t.mg = p_mg
            and t.lsk=p_lsk
            group by t.lsk, t.mg, t.usl) r on bs.usl_id=r.usl and k.lsk=r.lsk and k.mg=r.mg
  where k.lsk=p_lsk and k.mg = p_mg
  group by g.isvol, nvl(u.bill_brake,0), u.npp, k.lsk, u.ed_izm, bs.id,
    case when u.cd='т/сод' /*and k.psch not in (8,9) сделал коммент, так как просили чтобы были включены перерасчеты, смотри переписку 04.12.2017 в 14:30*/ then 1 else 0 end,
   case when u.cd='т/сод' /*and k.psch not in (8,9)*/ then trim(u.nm)||' в том числе:' else u.nm end
  having (sum(a.summa) <> 0 or sum(sl.summa)<>0
  or sum(r.changes)<>0) or (l_lsk_tp='LSK_TP_MAIN' and bs.id='003' or l_lsk_tp='LSK_TP_ADDIT' and bs.id='033') --временно закоментировал, может на пользу 31.01.2017 -зачем? пришлось восстановить 27.02.2017
  order by nvl(u.bill_brake,0), u.npp;


end;


--расшифровка услуг в дочернем бэнде по услугам МКД
procedure detail2(p_lsk IN KART.lsk%TYPE,
                 p_mg   IN PARAMS.period%type,
                 p_bill_var in number,
                 p_tp in number, --признак услуги, подлежащей расшифровке
                 p_rfcur out ccur
  ) is
begin
  open p_rfcur for
  select /*+ USE_HASH(k, a, sl, r  )*/ k.lsk, bs.usl_id as usl,
     '   '||u2.nm as nm,
     u.ed_izm, sum(a.summa) as chrg,
     sum(a.vol) as vol,
     sum(a.cena) as cena,
     sum(sl.summa) as sal_in,
     sum(r.changes0) as chng0, sum(r.changes1) as chng1, sum(r.changes2) as chng2, max(r.proc) as chng_proc,
     nvl(sum(a.summa),0)+nvl(sum(r.changes),0) as itog, nvl(u.bill_brake,0) as bill_brake,
     u2.npp
     from
      arch_kart k
      join usl_bills bs on k.mg between bs.mg1 and bs.mg2
        and bs.fk_bill_var=p_bill_var and p_tp=1
      join usl u on bs.id=u.usl and u.cd='т/сод'
      join usl u2 on bs.usl_id=u2.usl and u2.cd in ('HW_SOD','GW_SOD','EL_SOD','KAN_SOD','TR_SOD','TR_SOD3', 'HW_ODN2', 'HW_ODN3', 'GW_ODN2', 'GW_ODN3', 'EL_ODN2')
      left join
           (select t.lsk, t.mgFrom, t.mgTo, min(t.usl) as usl, b.bill_agg, --поле нужно, чтобы разделить расценку по норме и свыше, или просуммировать расценку
             sum(t.summa) as summa,
             sum(t.test_opl) as vol, max(t.test_cena) as cena --расценка
            from a_charge2 t, usl u, usl_bills b --сальдо по услугам
             where t.type = 1 and p_mg between t.mgFrom and t.mgTo
              and t.usl=b.usl_id and t.lsk=p_lsk
              and t.usl=u.usl
              and p_mg between b.mg1 and b.mg2
              and b.fk_bill_var = p_bill_var
             group by t.lsk, t.mgFrom, t.mgTo, u.uslm, b.bill_agg) a on bs.usl_id=a.usl and k.lsk=a.lsk and k.mg between a.mgFrom and a.mgTo
      left join
      (select t.lsk, t.mg,t.usl, sum(t.summa) as summa
            from saldo_usl t
            where t.mg = p_mg
           group by t.lsk, t.mg, t.usl) sl on bs.usl_id=sl.usl and k.lsk=sl.lsk and k.mg=sl.mg
      left join
           (select t.lsk, t.mg, t.usl as usl, sum(t.summa) as changes,
              sum(decode(t.type,0,t.summa, 0)) as changes0,
              sum(decode(t.type,1,t.summa, 0)) as changes1,
              sum(decode(t.type,2,t.summa,3,t.summa, 0)) as changes2,
              max(t.proc) as proc
            from
            a_change t where nvl(t.show_bill,0)<>1 and t.mg = p_mg
            group by t.lsk, t.mg, t.usl) r on bs.usl_id=r.usl and k.lsk=r.lsk and k.mg=r.mg
            where k.lsk=p_lsk and k.mg = p_mg
  group by nvl(u.bill_brake,0), u2.npp, k.lsk,
  --decode(u2.cd,'т/сод', 'в т.ч:'||u2.nm, '   '||u2.nm),
  '   '||u2.nm,
  u.ed_izm, bs.usl_id
  having (sum(a.summa) <> 0 or sum(sl.summa)<>0
  or sum(r.changes)<>0)
  order by u2.npp;


/*         select * from
            select t.usl, u.nm,
             sum(t.summa) as summa,
             sum(t.test_opl) as vol, max(t.test_cena) as cena --расценка
            from a_charge t
            join usl u on t.usl=u.usl
            join usl_bills b on t.usl=b.usl_id and p_mg between b.mg1 and b.mg2 and b.fk_bill_var = p_bill_var and b.id = '003' --сальдо по услугам
             where t.type = 1 and t.mg = p_mg
              and t.lsk = p_lsk and p_tp=1
             group by t.usl, u.nm;*/
end;

--для датасета в счете, описывающего организацию
procedure org(p_mg   IN PARAMS.period%type,
              p_var in number, --тип счета
              p_rfcur out ccur
  ) is
begin
  open p_rfcur for
    select t.id, t.cd, t.fk_orgtp, t.name, t.npp, t.v, t.parent_id, t.reu, t.trest, t.uch, t.adr, t.inn,
    t.manager, t.buh, t.raschet_schet, t.k_schet, t.kod_okonh, t.kod_ogrn, t.bik, t.phone, t.kpp, t.bank,
    t.id_exp, t.adr_recip, t.authorized_dir, t.authorized_buh, t.auth_dir_doc, t.auth_buh_doc, t.okpo,
    t.ver_cd, t.full_name, t.phone2, t.parent_id2, t.fk_org2, t.bank_cd, t.adr_www,
    email, t.head_name, t.raschet_schet2, t.post_indx, t.r_sch_addit, t.fk_bill_var, t.aoguid, t.oktmo, t.code_deb,
    sv.fname_sch, nvl(sv.tp,0) as bill_tp
    from scott.t_org t, scott.t_org_tp tp, scott.spr_services sv
    where tp.id=t.fk_orgtp and tp.cd='РКЦ'
    and p_mg between sv.mg and sv.mg1 and sv.fk_sch_type=p_var;
end;

--справка о задолжности
procedure deb(p_k_lsk_id in number,
              p_lsk in kart.lsk%type,
              p_rfcur out ccur
  ) is
  l_lsk kart.lsk%type;
begin
  if utils.get_int_param('SPR_DEB_VAR') = 1 then
    --новый вариант (для ТСЖ), здесь по p_lsk
    select max(k.lsk) into l_lsk from kart k where k.k_lsk_id=p_k_lsk_id;
    open p_rfcur for
      select b.summa as charge, c.summa as payment, nvl(b.summa,0) - nvl(c.summa,0) as dolg,
      nvl(d.penya,0) as penya,
      nvl(d.dolg_pen,0)+nvl(d.penya,0) as itog,
      utils.MONTH_NAME(substr(a.mg,5,2))||' '||substr(a.mg,1,4) as mg, d.days, d.dolg_pen,
       sum(nvl(b.summa,0) - nvl(c.summa,0)) OVER (order by a.mg) as prev_sum,
      e.summa as sal
       from
       scott.long_table a ,
      (select mg, sum(summa) as summa from scott.c_chargepay where period=(select period from scott.params) and
         lsk=l_lsk and type=0 group by mg) b,
      (select mg, sum(summa) as summa from scott.c_chargepay where period=(select period from scott.params) and
         lsk=l_lsk and type=1 group by mg) c,
      (select t.mg, sum(t.dolg) as summa from scott.arch_kart t where
         lsk=l_lsk group by mg) e,

      (select summa as dolg_pen,penya, days, mg1 from scott.c_penya c where lsk=l_lsk) d
      where a.mg=b.mg(+) and a.mg=c.mg(+)
      and a.mg=e.mg(+)
      and a.mg=d.mg1(+)  and (nvl(b.summa,0) <>0 or nvl(c.summa,0) <>0 or nvl(e.summa,0) <>0)
      and (d.dolg_pen > 0 or d.penya<>0) --ред. 05.03.2020 - сделал, иначе не идёт с движением по лиц.сч.
      order by a.mg
      ;
  elsif  utils.get_int_param('SPR_DEB_VAR') = 0 then
    --старый вариант, для Полыс
    open p_rfcur for
      select * from (
      select k.usl_name_short||'-'||k.lsk as lsk, k.psch, s.name||', '||ltrim(k.nd,'0')||', '||ltrim(k.kw,'0') as adr, k.fio, s.name, k.mg,
       substr(k.mg,1,4)||'-'||substr(k.mg,5,2) as mg2,
       scott.utils.MONTH_NAME(substr(k.mg,5,2))||' '||substr(k.mg,1,4)||' г.' as mg_name, --substr(tp.name,1,3)
               b.summa as charge,
               nvl(d.penya,0) as penya,
               case when /*p.period=k.mg and */d.summa <0 then
                  'Переплата'
               else
                  'Долг'
               end
      as dolg_name,
               case when /*p.period=k.mg and */d.summa <0 then
                  d.summa
               else
                  d.summa
               end as dolg,
               d.days,
               p.period,
        scott.init.get_fio as fio_kass
          from (select k1.psch, k1.fk_tp, k1.lsk, k1.c_lsk_id, k1.k_lsk_id, k1.kul, k1.nd, k1.kw, first_value(k1.fio)
             over (order by decode(psch,8,0,1) desc) as fio, a.mg, k1.usl_name_short
                from scott.kart k1, scott.long_table a
                where decode(p_k_lsk_id,0,p_lsk,k1.lsk)=k1.lsk
                and decode(p_k_lsk_id,0,k1.k_lsk_id, p_k_lsk_id)=k1.k_lsk_id) k, scott.spul s, scott.params p,
               (select c.lsk, c.mg, sum(c.summa) as summa
                  from scott.c_chargepay c, scott.kart k2
                 where period = (select period from scott.params)
                   and type = 0 and k2.lsk=c.lsk and decode(p_k_lsk_id,0,p_lsk,k2.lsk)=k2.lsk
                and decode(p_k_lsk_id,0,k2.k_lsk_id, p_k_lsk_id)=k2.k_lsk_id
                 group by c.lsk, c.mg) b,
                 v_lsk_tp tp,
                 c_penya d
         where k.lsk=d.lsk(+) and k.mg=d.mg1(+)
            and k.lsk=b.lsk(+) and k.mg=b.mg(+)
        and k.kul=s.id
        and k.fk_tp=tp.id
      ) t where t.dolg <> 0 or t.penya >0 or (t.mg = t.period and t.dolg <>0 and t.psch <> 8)
      order by t.mg;
  end if;
end;

--архивная справка, основной запрос
procedure arch(p_k_lsk in number, p_sel_obj in number, p_lsk in kart.lsk%type,
               p_mg1 in params.period%type, p_mg2 in params.period%type,
               p_sel_uk    in varchar2, -- список УК
               p_tp in number default 0,-- 0- старая арх.спр., 1- новая
               p_rfcur out ccur
               ) is
l_mg params.period%type;
l_mg_prev params.period%type;
begin

select p.period, p.period3 into l_mg, l_mg_prev from v_params p;
if p_tp=0 then
  -- арх.спр.-2

  open p_rfcur for
    select substr(m.mg,1,4)||'-'||substr(m.mg,5,2) as mg,
     m.mg_new, m.lsk|| chr(10) ||o.name as lsk, -- добавил перенос строки. ред.16.10.19
     nvl(a.nm,u2.nm2) as nm, case when a.summa=0 then null else a.summa end as summa,
    case when s.sal=0 then null else s.sal end as sal,

    case when m.mg < '200804' then
       case when e.pay=0 then null else e.pay end
         when m.mg >= '200804' then
       case when e2.pay=0 then null else e2.pay end
         end as pay, --оплата

    case when m.mg < '200804' then
       case when e.pay_pen=0 then null else e.pay_pen end
         when m.mg >= '200804' then
       case when e2.pay_pen=0 then null else e2.pay_pen end
         end as pay_pen, --оплата пени

    case when f.pen=0 then null else f.pen end as pen
     from
     (select k.reu, k.lsk, t.mg, t.mg_new, k.mg1, k.mg2 from scott.kart k,
     (select to_char(add_months(to_date(p.period||'01', 'YYYYMMDD'), -1*level),'YYYYMM') as mg,
     to_char(add_months(to_date(p.period||'01', 'YYYYMMDD'), -1*level+1),'YYYYMM') as mg_new
      from scott.params p connect by level <= 1000) t
      where (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and decode(p_sel_uk,
                  '0',
                  1,
                  instr(p_sel_uk, '''' || k.reu || ''';', 1)) > 0

      ) m
      join
      scott.usl u2 on u2.usl='003'
      join t_org o on m.reu=o.reu
      left join
      (select lsk, mg, nm, sum(summa) as summa from (
        select t.lsk, t.mg, decode(u.for_arch, 1, u.nm, u.nm2) as nm, t.summa as summa
        from scott.kart k, scott.arch_charges t, scott.usl u
       where u.usl=t.usl_id and k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
        union all
        select t.lsk, t.mg, decode(u.for_arch, 1, u.nm, u.nm2) as nm, t.summa as summa
          from scott.kart k, scott.arch_changes t, scott.usl u
         where u.usl=t.usl_id and k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
        )
        group by lsk, mg, nm) a on m.mg=a.mg and m.lsk=a.lsk
      left join
     (select t.mg, t.lsk, sum(t.summa) as sal from scott.kart k, scott.saldo_usl t
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      group by t.mg, t.lsk) s on m.mg_new=s.mg and m.lsk=s.lsk
      left join
     (select t.mg1, t.lsk, sum(t.penya) as pen from scott.kart k, scott.a_penya t, v_params p
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and t.mg1 between p_mg1 and p_mg2
      and t.mg=p.period3
      group by t.mg1, t.lsk) f on m.mg=f.mg1 and m.lsk=f.lsk
      left join
     (select t.mg, t.lsk, sum(t.summa) as pay, sum(t.penya) as pay_pen from scott.kart k, scott.a_kwtp t --запрос для оплаты до 200804
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and t.mg between p_mg1 and p_mg2
      group by t.mg, t.lsk) e on m.mg < '200804' and m.mg=e.mg and m.lsk=e.lsk
      left join
     (select t.mg, t.lsk, sum(t.summa) as pay, sum(t.penya) as pay_pen from scott.kart k, scott.a_kwtp_mg t --запрос для оплаты после 200804, включительно
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and t.mg between p_mg1 and p_mg2
      group by t.mg, t.lsk) e2 on m.mg >= '200804' and m.mg=e2.mg and m.lsk=e2.lsk
    where m.mg between p_mg1 and p_mg2
          and (nvl(a.summa,0) <> 0 or nvl(s.sal,0) <> 0
           or nvl(e.pay,0) <> 0 or nvl(e.pay_pen,0) <> 0
           or nvl(e2.pay,0) <> 0 or nvl(e2.pay_pen,0) <> 0
          ) order by m.mg, m.mg1, u2.npp;
else
  -- арх.спр.-3
  open p_rfcur for

    select substr(m.mg,1,4)||'-'||substr(m.mg,5,2) as mg,
      m.mg_new, m.lsk|| chr(10) ||o.name as lsk,
      case when s.sal=0 then null else s.sal end as sal_in,    -- вх.сальдо на период
      case when s2.sal=0 then null else s2.sal end as sal_out,  -- исх.сальдо за период
      case when nvl(s3.summa,0)+nvl(s4.summa,0)=0 then null else nvl(s3.summa,0)+nvl(s4.summa,0) end as sum_chrg,  -- начислено, в т.ч. перерасчеты
      case when m.mg < '200804' then
         case when e.pay=0 then null else e.pay end
           when m.mg >= '200804' then
         case when e2.pay=0 then null else e2.pay end
           end as pay, --оплата
      case when m.mg < '200804' then
         case when e.pay_pen=0 then null else e.pay_pen end
           when m.mg >= '200804' then
         case when e2.pay_pen=0 then null else e2.pay_pen end
           end as pay_pen, --оплата пени
      case when f.pen=0 then null else f.pen end as pen_in, -- вх.сальдо по пене
      case when f2.pen=0 then null else f2.pen end as pen_out, -- исх.сальдо по пене
      case when f3.pen=0 then null else f3.pen end as pen_cur -- текущая пеня

     from
     (select k.reu, k.lsk, t.mg, t.mg_new, k.mg1, k.mg2 from scott.kart k,
     (select to_char(add_months(to_date(p.period||'01', 'YYYYMMDD'), -1*level+1),'YYYYMM') as mg,
     to_char(add_months(to_date(p.period||'01', 'YYYYMMDD'), -1*level+2),'YYYYMM') as mg_new
      from scott.params p connect by level <= 1000) t
      where (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and decode(p_sel_uk,
                  '0',
                  1,
                  instr(p_sel_uk, '''' || k.reu || ''';', 1)) > 0
      ) m
      join t_org o on m.reu=o.reu
      left join
     (select t.mg, t.lsk, sum(t.summa) as sal from scott.kart k, scott.saldo_usl t
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      group by t.mg, t.lsk) s on m.mg=s.mg and m.lsk=s.lsk -- вх.сальдо на период
      left join
     (select t.mg, t.lsk, sum(t.summa) as sal from scott.kart k, scott.saldo_usl t
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      group by t.mg, t.lsk) s2 on m.mg_new=s2.mg and m.lsk=s2.lsk -- исх.сальдо за период
      left join
     (select o.mg, t.lsk, sum(t.summa) as summa from scott.kart k, long_table o, scott.a_charge2 t
      where k.lsk=t.lsk and t.type=1 and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and o.mg between p_mg1 and p_mg2
      and o.mg between t.mgFrom and t.mgTo
      group by o.mg, t.lsk) s3 on m.mg=s3.mg and m.lsk=s3.lsk -- начислено
      left join
     (select t.mg, t.lsk, sum(t.summa) as summa from scott.kart k, scott.a_change t
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and t.mg between p_mg1 and p_mg2
      group by t.mg, t.lsk) s4 on m.mg=s4.mg and m.lsk=s4.lsk -- перерасчеты
      left join
     (select t.mg1, t.lsk, sum(t.penya) as pen from scott.kart k, scott.a_penya t
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and t.mg1 between p_mg1 and p_mg2
      and t.mg=l_mg_prev
      group by t.mg1, t.lsk) f on m.mg=f.mg1 and m.lsk=f.lsk -- вх.сальдо по пене
      left join
     (select t.mg1, t.lsk, sum(t.penya) as pen from scott.kart k, scott.a_penya t
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and t.mg1 between p_mg1 and p_mg2
      and t.mg=l_mg
      group by t.mg1, t.lsk) f2 on m.mg=f2.mg1 and m.lsk=f2.lsk -- исх.сальдо по пене
      left join
     (select t.mg1, t.lsk, sum(t.penya) as pen from scott.kart k, scott.a_pen_cur t
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and t.mg1 between p_mg1 and p_mg2
      and t.mg=l_mg
      group by t.mg1, t.lsk) f3 on m.mg=f3.mg1 and m.lsk=f3.lsk -- текущая пеня
      left join
     (select t.mg, t.lsk, sum(t.summa) as pay, sum(t.penya) as pay_pen from scott.kart k, scott.a_kwtp t
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and t.mg between p_mg1 and p_mg2
      group by t.mg, t.lsk) e on m.mg < '200804' and m.mg=e.mg and m.lsk=e.lsk -- оплата до 04.2008
      left join
     (select t.mg, t.lsk, sum(t.summa) as pay, sum(t.penya) as pay_pen from scott.kart k, scott.a_kwtp_mg t
      where k.lsk=t.lsk and (p_sel_obj=1 and k.k_lsk_id=p_k_lsk or p_sel_obj=0 and k.lsk=p_lsk)
      and t.mg between p_mg1 and p_mg2
      group by t.mg, t.lsk) e2 on m.mg >= '200804' and m.mg=e2.mg and m.lsk=e2.lsk -- оплата после 04.2008, включительно
    where m.mg between p_mg1 and p_mg2
          and (
          nvl(s.sal,0) <> 0 or 
          nvl(s2.sal,0) <> 0 or 
          nvl(s3.summa,0)+nvl(s4.summa,0) <> 0 or 
          nvl(f.pen,0) <> 0 or 
          nvl(f2.pen,0) <> 0 or 
          nvl(f3.pen,0) <> 0 or 
          nvl(e.pay,0) <> 0 or 
          nvl(e.pay_pen,0) <> 0 or 
          nvl(e2.pay,0) <> 0 or 
          nvl(e2.pay_pen,0) <> 0
          )
          order by m.mg, m.mg1;

end if;

end;

--архивная справка, вспомогательный запрос
procedure arch_supp(p_k_lsk in number,
               p_sel_obj in number, -- вариант выборки: 0 - по лиц.счету, 1 - по адресу
               p_lsk in kart.lsk%type,
               p_mg1 in params.period%type, p_mg2 in params.period%type,
               p_sel_uk    in varchar2, -- список УК
               p_rfcur out ccur) is
begin

open p_rfcur for
  select nvl(e.pay,0)+nvl(e2.pay,0) as pay,
         nvl(e.pay_pen,0)+nvl(e2.pay_pen,0) as pay_pen,
         b.dolg, b.penya
    from (select sum(t.summa) as pay, sum(t.penya) as pay_pen
             from scott.a_kwtp t, scott.kart k
            where k.lsk = t.lsk
              and (decode(p_sel_obj,1, p_k_lsk, k.k_lsk_id)=k.k_lsk_id
                   and decode(p_sel_obj,0,p_lsk, k.lsk)=k.lsk)
              and t.mg between p_mg1 and p_mg2 --запрос для оплаты до 200804
              and t.mg < '200804'
              and decode(p_sel_obj,0,111,decode(p_sel_uk, -- либо лс без ограничений, либо адрес, но по списку УК
                              '0',
                              1,
                              instr(p_sel_uk, '''' || k.reu || ''';', 1))) > 0
              ) e
         join
         (select sum(t.summa) as pay, sum(t.penya) as pay_pen
             from scott.a_kwtp_mg t, scott.kart k
            where k.lsk = t.lsk
              and (decode(p_sel_obj,1,p_k_lsk, k.k_lsk_id)=k.k_lsk_id
                   and decode(p_sel_obj,0,p_lsk, k.lsk)=k.lsk)
              and t.mg between p_mg1 and p_mg2 --запрос для оплаты после 200804, включительно
              and t.mg >= '200804'
              and decode(p_sel_obj,0,111,decode(p_sel_uk,
                              '0',
                              1,
                              instr(p_sel_uk, '''' || k.reu || ''';', 1))) > 0
                              ) e2
              on 1=1
         join
         (select nvl(sum(t.summa),0) + nvl(sum(t.penya),0) as dolg, sum(t.penya) as penya
             from scott.a_penya t, scott.kart k, scott.v_params p
            where k.lsk = t.lsk
              and (decode(p_sel_obj,1,p_k_lsk, k.k_lsk_id)=k.k_lsk_id
                   and decode(p_sel_obj,0,p_lsk, k.lsk)=k.lsk)
              and t.mg1 between p_mg1 and p_mg2
              and t.mg=p.period3--был ошибочно указан не тот период? 28.11.2018--and t.mg = p_mg2
              and decode(p_sel_obj,0,111,decode(p_sel_uk,
                              '0',
                              1,
                              instr(p_sel_uk, '''' || k.reu || ''';', 1))) > 0
              ) b
              on 1=1;

end;


end rep_bills;
/


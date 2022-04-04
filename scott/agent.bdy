CREATE OR REPLACE PACKAGE BODY SCOTT.agent IS

  PROCEDURE uptime IS
    stmt VARCHAR2(2000);
  BEGIN
    stmt := 'UPDATE params SET agent_uptime=sysdate';
    EXECUTE IMMEDIATE stmt;
    COMMIT;
  END uptime;

  PROCEDURE load_proc_plan
  --Загрузка выполнения процентов по плану
   IS
    stmt VARCHAR2(2000);
  BEGIN
    stmt := 'DELETE FROM proc_plan_loaded';
    EXECUTE IMMEDIATE stmt;
    stmt := 'INSERT INTO proc_plan_loaded
               SELECT * FROM PROC_PLAN_LOAD';
    EXECUTE IMMEDIATE stmt;
    agent.uptime;
    COMMIT;
  END load_proc_plan;

procedure load_subs_el is
 cnt_ number;
begin
--Загрузка субсидии по электроэнергии
if utils.get_int_param('LD_SUBS_EL') = 1 then
 select count(*) into cnt_ from load_el e where not exists
   (select * from kart k where k.lsk = e.lchet);
 if cnt_ <> 0 then
   Raise_application_error(-20001,
     'Попытка загрузить не существующие лицевые счета в таблице LOAD_EL!');
 end if;
 delete from c_charge where var = 1;
 insert into c_charge (lsk, usl, summa, var, type)
  select e.lchet, '024', e.sum_sv, 1, 2 from load_el e;
 commit;
end if;
end;

procedure load_subs_cor is
 cnt_ number;
begin
--Загрузка корректировок по субсидии
 select count(*) into cnt_ from load_cor e where not exists
   (select * from kart k where k.lsk = e.lchet);
 if cnt_ <> 0 then
   Raise_application_error(-20001,
     'Попытка загрузить не существующие лицевые счета в таблице LOAD_COR!');
 end if;
 update kart k set k.subs_cor = null where
  substr(k.lsk, 1, 4) in (select distinct substr(e.lchet, 1, 4) from load_cor e);

 update kart k set k.subs_cor =
   (select sum(e.sum_sub)  from load_cor e where e.lchet=k.lsk),
   k.subs_cur=1
   where exists (select * from load_cor e where e.lchet=k.lsk);
 commit;
end;

procedure load_subs_inf is
 cnt_ number;
begin
--Загрузка субсидии для информации в карточке
 select count(*) into cnt_ from load_inf e where not exists
   (select * from kart k where k.lsk = e.lchet);
 if cnt_ <> 0 then
   Raise_application_error(-20001,
     'Попытка загрузить не существующие лицевые счета в таблице LOAD_INF!');
 end if;
 update kart k set k.subs_inf = null where
  substr(k.lsk, 1, 4) in (select distinct substr(e.lchet, 1, 4) from load_inf e);

 update kart k set k.subs_inf =
   (select sum(e.sum_sub)  from load_inf e where e.lchet=k.lsk)
   where exists (select * from load_inf e where e.lchet=k.lsk);
 commit;
end;

procedure recv_payment_for_en (dat1_ in date,
                                   dat2_ in date)
is
oper_ char(2);
dat_ink_ date;
cnt_ number;
cd_ varchar2(100);
l_mg params.period%type;
type prep_refcursor is REF CURSOR;
cur1 prep_refcursor;
begin
cd_:='МП УЕЗЖКУ';
dat_ink_:=gdt(0,0,0);
--оплата для Энергии+ от УЕЗЖКУ, ежедневная и за месяц
--код операции - Оплата Уезжку
 select fk_oper into oper_
   from c_comps c where c.cd=cd_;
 select nvl(count(*),0) into cnt_ from load_en_pay l, params p where
   to_char(l.dtek,'YYYYMM')<>p.period;
--   to_char(l.dat_ink,'YYYYMM')<>p.period; --заменил эксперементально, 17.04.2017 так как иногда не бывает инкассаций в dat_ink
if cnt_ <> 0 then
  Raise_application_error(-20001,
  'Период платежей не соответствует периоду в базе Энергии+!');
end if;

 for c in (select l.* from load_en_pay l where
  not exists (select * from kart k where k.lsk=
   lpad(trim(replace(to_char(l.tel_sch,'9999999.99'),'.','')),8, '0'))) loop
--if cnt_ <> 0 then
  Raise_application_error(-20001,
  'Отправленная оплата содержит лицевые счета
  не соответствующие счетам поставщика услуги Энергии+, например:
  kul='||c.kul||' nd='||c.nd||' kw='||c.kw);
 end loop;

if dat1_ is null and dat2_ is null then
  delete from c_kwtp_mg t where
--   exists (select * from params p where p.period=to_char(t.dat_ink,'YYYYMM'))--заменил эксперементально, 17.04.2017 так как иногда не бывает инкассаций в dat_ink
   exists (select * from params p where p.period=to_char(t.dtek,'YYYYMM'))
   and t.oper=oper_;
  delete from c_kwtp t where
--   exists (select * from params p where p.period=to_char(t.dat_ink,'YYYYMM'))--заменил эксперементально, 17.04.2017 так как иногда не бывает инкассаций в dat_ink
   exists (select * from params p where p.period=to_char(t.dtek,'YYYYMM'))
   and t.oper=oper_;
else
  delete from c_kwtp_mg t where
   --t.dat_ink between dat1_ and dat2_  --заменил эксперементально, 17.04.2017 так как иногда не бывает инкассаций в dat_ink
   t.dtek between dat1_ and dat2_
   and t.oper=oper_;
  delete from c_kwtp t where
   --t.dat_ink between dat1_ and dat2_  --заменил эксперементально, 17.04.2017 так как иногда не бывает инкассаций в dat_ink
   t.dtek between dat1_ and dat2_
   and t.oper=oper_;
end if;
commit;

if dat1_ is not null and dat2_ is not null then
  admin.send_message(
    'info:Получена оплата от '||cd_||' за период c '||to_char(dat1_)||' по '||to_char(dat2_));
end if;

update c_comps c set c.nink=nvl(c.nink,0)+1 where c.cd=cd_;

if dat1_ is null and dat2_ is null then
  insert into c_kwtp (id, lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, iscorrect)
   select c_kwtp_id.nextval, k.lsk, l.ska, oper_, l.dopl, --substr(l.dopl,3,4)||substr(l.dopl,1,2),
   c.nink, c.nkom, l.dtek, l.nomz, dat_ink_, sysdate, 0 --выполняю подстановку dat_ink!
   from load_en_pay l, kart k, c_comps c
     where k.lsk=lpad(trim(replace(to_char(l.tel_sch,'9999999.99'),'.','')),8, '0') and c.cd=cd_ and
     exists (select * from params p where p.period=to_char(l.dtek,'YYYYMM')); --заменил эксперементально, 17.04.2017 так как иногда не бывает инкассаций в dat_ink
          --p.period=to_char(l.dat_ink,'YYYYMM'));
  insert into c_kwtp_mg (c_kwtp_id, lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts)
   select l.id, l.lsk, l.summa, oper_, l.dopl,
   l.nink, l.nkom, l.dtek, l.nkvit, dat_ink_, sysdate --выполняю подстановку dat_ink!
   from c_kwtp l, c_comps c
     where c.cd=cd_ and l.nkom=c.nkom and
     exists (select * from params p where --p.period=to_char(l.dat_ink,'YYYYMM')
                 p.period=to_char(l.dtek,'YYYYMM')--заменил эксперементально, 17.04.2017
     );
else
  insert into c_kwtp (id, lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts, iscorrect)
   select c_kwtp_id.nextval, k.lsk, l.ska, oper_, l.dopl, --substr(l.dopl,3,4)||substr(l.dopl,1,2),
   c.nink, c.nkom, l.dtek, l.nomz, dat_ink_, sysdate, 0
   from load_en_pay l, kart k, c_comps c
     where k.lsk=lpad(trim(replace(to_char(l.tel_sch,'9999999.99'),'.','')),8, '0') and c.cd=cd_
     --and l.dat_ink between dat1_ and dat2_--заменил эксперементально, 17.04.2017
     and l.dtek between dat1_ and dat2_
     ;
  insert into c_kwtp_mg (c_kwtp_id, lsk, summa, oper, dopl, nink, nkom, dtek, nkvit, dat_ink, ts)
   select l.id, l.lsk, l.summa, oper_, l.dopl,
   l.nink, l.nkom, l.dtek, l.nkvit, dat_ink_, sysdate
   from c_kwtp l, c_comps c
     where c.cd=cd_ and l.nkom=c.nkom and
     --l.dat_ink between dat1_ and dat2_;--заменил эксперементально, 17.04.2017
     l.dtek between dat1_ and dat2_;
end if;
commit;

/*
--сформировать реестр для базы Дениса

select p.period into l_mg from params p;
stat.rep_stat(reu_ => null,
              kul_ => null,
              nd_ => null,
              trest_ => null,
              mg_ => l_mg,
              mg1_ => null,
              dat_ => null,
              dat1_ => null,
              var_ => null,
              det_ => null,
              org_ => null,
              oper_ => null,
              сd_ => '81',
              spk_id_ => null,
              p_house => null,
              p_out_tp => 1,
              prep_refcursor => cur1)
              ;
*/
end;

procedure unload_en is
begin
  --выгрузка долгов энергии +
  --формирование долгов
  --долги кабельного телевидения
  c_cpenya.gen_charge_pay_full;
  delete from load_en;
  insert into load_en
  (lsk, polis, kul, nyl, nd, kw, fio, ndog, ska)
  select k.lsk,
         k.polis,
         k.kul,
         s.name,
         k.nd,
         k.kw,
         substr(k.fio, 1, 25),
         substr(k.dog_num, 1, 10),
         sum(decode(c.type, 0, c.summa, 1, -1 * c.summa))
    from kart k, c_chargepay2 c, spul s, params p
   where k.lsk = c.lsk
     and k.kul = s.id
     and p.period between c.mgFrom and c.mgTo --ред.26.03.2012
     and exists --и существует в объеме необх. услуга
     (select * from nabor n, usl u where n.lsk=k.lsk and
         nvl(decode(u.sptarn, 0, nvl(n.koeff,0), 1, nvl(n.norm,0), 2,
               nvl(n.koeff,0) * nvl(n.norm,0), 3, nvl(n.koeff,0) * nvl(n.norm,0)), 0) <> 0
        and n.usl=u.usl and u.cd in ('каб.тел.')
     )
     and k.psch in (8,9) --закрытые л.с.
     and exists --и существует задолжность по л.с.
     (select e.lsk from c_penya e where
       e.lsk=k.lsk
       group by e.lsk
       having sum(e.summa) <> 0)
   group by k.lsk,
            k.polis,
            k.kul,
            s.name,
            k.nd,
            k.kw,
            substr(k.fio, 1, 25),
            substr(k.dog_num, 1, 10)
   union all
  select k.lsk,
         k.polis,
         k.kul,
         s.name,
         k.nd,
         k.kw,
         substr(k.fio, 1, 25),
         substr(k.dog_num, 1, 10),
         sum(decode(c.type, 0, c.summa, 1, -1 * c.summa))
    from kart k, c_chargepay2 c, spul s, params p
   where k.lsk = c.lsk
     and k.kul = s.id
     and p.period between c.mgFrom and c.mgTo --ред.26.03.2012
     and k.psch not in (8,9) --не закрытые л.с.
     and exists --и существует в объеме необх. услуга
     (select * from nabor n, usl u where n.lsk=k.lsk and
         nvl(decode(u.sptarn, 0, nvl(n.koeff,0), 1, nvl(n.norm,0), 2,
               nvl(n.koeff,0) * nvl(n.norm,0), 3, nvl(n.koeff,0) * nvl(n.norm,0)), 0) <> 0
        and n.usl=u.usl and u.cd in ('каб.тел.')
     )--и существует задолжность по л.с.
   group by k.lsk,
            k.polis,
            k.kul,
            s.name,
            k.nd,
            k.kw,
            substr(k.fio, 1, 25),
            substr(k.dog_num, 1, 10);

     /*and k.psch not in (8, 9) and nvl(k.schel_dt, to_date('19000101','YYYYMMDD')) <=
     to_date(p.period||'15','YYYYMMDD') and
     nvl(k.schel_end, to_date('29000101','YYYYMMDD')) >
     to_date(p.period||'15','YYYYMMDD')*/


  --признаки антенны по договору
  delete from load_en_d;
  insert into load_en_d
  (lsk, polis, kul, nyl, nd, kw, fio, ndog, ska)
  select k.lsk,
         k.polis,
         k.kul,
         s.name,
         k.nd,
         k.kw,
         substr(k.fio, 1, 25),
         substr(k.dog_num, 1, 10),
         case when nvl(k.schel_dt, to_date('19000101','YYYYMMDD')) <=
     to_date(p.period||'15','YYYYMMDD') and
     nvl(k.schel_end, to_date('29000101','YYYYMMDD')) >
     to_date(p.period||'15','YYYYMMDD') then
         f.cena*c.norm
         else
         0 end
    from kart k, nabor c, spul s, spr_tarif_prices f, params p
   where k.lsk = c.lsk
     and k.kul = s.id
     and c.usl='043'
     and c.fk_tarif=f.fk_tarif and p.period between f.mg1 and f.mg2
     and k.c_lsk_id in (select first_value(t.c_lsk_id) over (order by
      case when nvl(t.schel_dt, to_date('19000101','YYYYMMDD')) <=
        to_date(p.period||'15','YYYYMMDD') and
        nvl(t.schel_end, to_date('29000101','YYYYMMDD')) >
        to_date(p.period||'15','YYYYMMDD') and
        decode(u.sptarn, 0, nvl(n.koeff,0), 1, nvl(n.norm,0), 2,
               nvl(n.koeff,0) * nvl(n.norm,0), 3, nvl(n.koeff,0) * nvl(n.norm,0)) <> 0
        then
         0
         else --последний открытый договор по адресу имеет приоритет если все закрыты то и зашибись,
         1 end)--выйдет последний закрытый
        from kart t, nabor n, params p, usl u where
        t.lsk=n.lsk and n.usl=u.usl and n.usl=c.usl and
        ((t.polis is null and t.kul=k.kul and t.nd=k.nd and t.kw=k.kw)
        or (t.polis is not null and t.polis=k.polis)));
  --признаки антенны коллективной
  delete from load_en_ant;
  insert into load_en_ant
  (lsk, polis, kul, nyl, nd, kw, fio, ndog, ska)
  select k.lsk,
         k.polis,
         k.kul,
         s.name,
         k.nd,
         k.kw,
         substr(k.fio, 1, 25),
         substr(k.dog_num, 1, 10),
         case when nvl(k.schel_dt, to_date('19000101','YYYYMMDD')) <=
     to_date(p.period||'15','YYYYMMDD') and
     nvl(k.schel_end, to_date('29000101','YYYYMMDD')) >
     to_date(p.period||'15','YYYYMMDD') then
         c.koeff*c.norm
         else
         0 end
    from kart k, nabor c, spul s, params p
   where k.lsk = c.lsk
     and k.kul = s.id
     and c.usl='044'
     and k.c_lsk_id in (select first_value(t.c_lsk_id) over (order by
      case when nvl(t.schel_dt, to_date('19000101','YYYYMMDD')) <=
        to_date(p.period||'15','YYYYMMDD') and
        nvl(t.schel_end, to_date('29000101','YYYYMMDD')) >
        to_date(p.period||'15','YYYYMMDD') and
        decode(u.sptarn, 0, nvl(n.koeff,0), 1, nvl(n.norm,0), 2,
               nvl(n.koeff,0) * nvl(n.norm,0), 3, nvl(n.koeff,0) * nvl(n.norm,0)) <> 0
        then
         0
         else --последний открытый договор по адресу имеет приоритет если все закрыты то и зашибись,
         1 end)--выйдет последний закрытый
        from kart t, nabor n, params p, usl u where
        t.lsk=n.lsk and n.usl=u.usl and n.usl=c.usl and
        ((t.polis is null and t.kul=k.kul and t.nd=k.nd and t.kw=k.kw)
        or (t.polis is not null and t.polis=k.polis)));
  commit;
end;

procedure list_lsk(kul_           in kart.kul%type,
                      nd_            in kart.nd%type,
                      kw_            in kart.kw%type,
                      prep_refcursor in out rep_refcursor) is
begin
  --Выборка лицевых соотв. адресу в МУПе
  open prep_refcursor for 'select k.lsk, k.fio from scott.kart@hotora k
  where k.kul=:kul_ and k.nd=:nd_ and k.kw=:kw_
   and k.psch <> 9'
    using kul_, nd_, kw_;
end;

END agent;
/

